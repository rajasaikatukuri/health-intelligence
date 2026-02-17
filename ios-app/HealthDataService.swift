import Foundation
import HealthKit

final class HealthDataService {

    private let healthStore = HKHealthStore()
    private let apiEndpoint: String
    private let jwtToken: String
    private let tenantId: String

    private let batchSize = 500
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0

    // ✅ Only types your Lambda allows (matches ALLOWED_DATA_TYPES)
    private lazy var readTypes: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []

        let quantityIds: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .distanceWalkingRunning,
            .heartRate,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .flightsClimbed,
            .bodyMass,
            .bloodPressureSystolic,
            .bloodPressureDiastolic,
            .bloodGlucose,
            .oxygenSaturation,
            .respiratoryRate
        ]

        for id in quantityIds {
            if let t = HKObjectType.quantityType(forIdentifier: id) {
                types.insert(t)
            }
        }

        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindful)
        }

        // ✅ Workouts (you were missing this)
        types.insert(HKObjectType.workoutType())

        return types
    }()

    init(apiEndpoint: String, jwtToken: String, tenantId: String) {
        self.apiEndpoint = apiEndpoint
        self.jwtToken = jwtToken
        self.tenantId = tenantId
    }

    func requestAuthorization(completion: @escaping (Result<Bool, HealthDataError>) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async { completion(.failure(.healthKitNotAvailable)) }
            return
        }

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            if let error {
                DispatchQueue.main.async { completion(.failure(.authorizationError(error.localizedDescription))) }
                return
            }
            DispatchQueue.main.async { completion(.success(success)) }
        }
    }

    func syncHealthData(from startDate: Date, to endDate: Date, completion: @escaping (Result<SyncResult, HealthDataError>) -> Void) {
        fetchAllHealthData(from: startDate, to: endDate) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let points):
                self.uploadDataPoints(points, completion: completion)
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }

    private func fetchAllHealthData(from startDate: Date, to endDate: Date, completion: @escaping (Result<[HealthDataPoint], HealthDataError>) -> Void) {
        let group = DispatchGroup()
        var all: [HealthDataPoint] = []
        var lastError: HealthDataError?
        let lock = NSLock()

        let quantityTypes: [(HKQuantityTypeIdentifier, String)] = [
            (.stepCount, "stepCount"),
            (.distanceWalkingRunning, "distanceWalkingRunning"),
            (.heartRate, "heartRate"),
            (.activeEnergyBurned, "activeEnergyBurned"),
            (.basalEnergyBurned, "basalEnergyBurned"),
            (.flightsClimbed, "flightsClimbed"),
            (.bodyMass, "bodyMass"),
            (.bloodPressureSystolic, "bloodPressureSystolic"),
            (.bloodPressureDiastolic, "bloodPressureDiastolic"),
            (.bloodGlucose, "bloodGlucose"),
            (.oxygenSaturation, "oxygenSaturation"),
            (.respiratoryRate, "respiratoryRate")
        ]

        for (identifier, name) in quantityTypes {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }
            group.enter()
            fetchQuantitySamples(type: type, dataType: name, startDate: startDate, endDate: endDate) { res in
                lock.lock()
                switch res {
                case .success(let pts): all.append(contentsOf: pts)
                case .failure(let e): lastError = e
                }
                lock.unlock()
                group.leave()
            }
        }

        if let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            group.enter()
            fetchCategorySamples(type: sleepType, dataType: "sleepAnalysis", startDate: startDate, endDate: endDate) { res in
                lock.lock()
                switch res {
                case .success(let pts): all.append(contentsOf: pts)
                case .failure(let e): lastError = e
                }
                lock.unlock()
                group.leave()
            }
        }

        if let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
            group.enter()
            fetchCategorySamples(type: mindfulType, dataType: "mindfulSession", startDate: startDate, endDate: endDate) { res in
                lock.lock()
                switch res {
                case .success(let pts): all.append(contentsOf: pts)
                case .failure(let e): lastError = e
                }
                lock.unlock()
                group.leave()
            }
        }

        // ✅ Workouts
        group.enter()
        fetchWorkouts(startDate: startDate, endDate: endDate) { res in
            lock.lock()
            switch res {
            case .success(let pts): all.append(contentsOf: pts)
            case .failure(let e): lastError = e
            }
            lock.unlock()
            group.leave()
        }

        group.notify(queue: .main) {
            if let err = lastError, all.isEmpty {
                completion(.failure(err))
                return
            }
            all.sort { $0.timestamp < $1.timestamp }
            completion(.success(all))
        }
    }

    private func fetchQuantitySamples(type: HKQuantityType, dataType: String, startDate: Date, endDate: Date, completion: @escaping (Result<[HealthDataPoint], HealthDataError>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { [weak self] _, samples, error in
            if let error {
                completion(.failure(.healthKitQueryError(error.localizedDescription)))
                return
            }

            guard let self, let samples = samples as? [HKQuantitySample] else {
                completion(.success([]))
                return
            }

            let points = samples.map { self.convertQuantitySample($0, dataType: dataType) }
            completion(.success(points))
        }

        healthStore.execute(query)
    }

    private func fetchCategorySamples(type: HKCategoryType, dataType: String, startDate: Date, endDate: Date, completion: @escaping (Result<[HealthDataPoint], HealthDataError>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { [weak self] _, samples, error in
            if let error {
                completion(.failure(.healthKitQueryError(error.localizedDescription)))
                return
            }

            guard let self, let samples = samples as? [HKCategorySample] else {
                completion(.success([]))
                return
            }

            let points = samples.map { self.convertCategorySample($0, dataType: dataType) }
            completion(.success(points))
        }

        healthStore.execute(query)
    }

    private func fetchWorkouts(startDate: Date, endDate: Date, completion: @escaping (Result<[HealthDataPoint], HealthDataError>) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(
            sampleType: HKObjectType.workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sort]
        ) { _, samples, error in
            if let error {
                completion(.failure(.healthKitQueryError(error.localizedDescription)))
                return
            }

            guard let workouts = samples as? [HKWorkout] else {
                completion(.success([]))
                return
            }

            let pts: [HealthDataPoint] = workouts.map { w in
                HealthDataPoint(
                    dataType: "workoutType",
                    value: Double(w.workoutActivityType.rawValue),
                    timestamp: w.startDate,
                    unit: "activityType",
                    sourceName: w.sourceRevision.source.name,
                    sourceVersion: w.sourceRevision.version ?? "",
                    device: w.device?.name ?? "",
                    metadata: [
                        "duration_seconds": w.duration,
                        "total_energy_kcal": w.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        "total_distance_km": w.totalDistance?.doubleValue(for: HKUnit.meterUnit(with: .kilo)) ?? 0
                    ]
                )
            }

            completion(.success(pts))
        }

        healthStore.execute(query)
    }

    private func convertQuantitySample(_ sample: HKQuantitySample, dataType: String) -> HealthDataPoint {
        let unit = unitFor(dataType)
        let value = sample.quantity.doubleValue(for: unit)

        return HealthDataPoint(
            dataType: dataType,
            value: value,
            timestamp: sample.startDate,
            unit: unit.unitString,
            sourceName: sample.sourceRevision.source.name,
            sourceVersion: sample.sourceRevision.version ?? "",
            device: sample.device?.name ?? "",
            metadata: sample.metadata ?? [:]
        )
    }

    private func convertCategorySample(_ sample: HKCategorySample, dataType: String) -> HealthDataPoint {
        return HealthDataPoint(
            dataType: dataType,
            value: Double(sample.value),
            timestamp: sample.startDate,
            unit: "",
            sourceName: sample.sourceRevision.source.name,
            sourceVersion: sample.sourceRevision.version ?? "",
            device: sample.device?.name ?? "",
            metadata: sample.metadata ?? [:]
        )
    }

    private func unitFor(_ dataType: String) -> HKUnit {
        switch dataType {
        case "stepCount", "flightsClimbed": return .count()
        case "distanceWalkingRunning": return HKUnit.meterUnit(with: .kilo)
        case "heartRate", "respiratoryRate": return HKUnit(from: "count/min")
        case "activeEnergyBurned", "basalEnergyBurned": return .kilocalorie()
        case "bodyMass": return HKUnit.gramUnit(with: .kilo)
        case "bloodPressureSystolic", "bloodPressureDiastolic": return .millimeterOfMercury()
        case "bloodGlucose": return HKUnit(from: "mg/dL")
        case "oxygenSaturation": return .percent()
        default: return .count()
        }
    }

    private func uploadDataPoints(_ points: [HealthDataPoint], completion: @escaping (Result<SyncResult, HealthDataError>) -> Void) {
        let batches = points.chunked(into: batchSize)

        var ok = 0
        var bad = 0
        var lastErr: HealthDataError?

        let group = DispatchGroup()
        let lock = NSLock()

        for b in batches {
            group.enter()
            uploadBatch(b, retry: 0) { res in
                lock.lock()
                switch res {
                case .success: ok += 1
                case .failure(let e): bad += 1; lastErr = e
                }
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let r = SyncResult(totalBatches: batches.count, successfulBatches: ok, failedBatches: bad, totalRecords: points.count)
            if bad == 0 { completion(.success(r)); return }
            if ok > 0 { completion(.success(r)); return }
            completion(.failure(lastErr ?? .uploadFailed("All batches failed")))
        }
    }

    private func uploadBatch(_ points: [HealthDataPoint], retry: Int, completion: @escaping (Result<Void, HealthDataError>) -> Void) {
        guard let url = URL(string: "\(apiEndpoint)/ingest") else {
            completion(.failure(.invalidURL))
            return
        }

        let requestId = UUID().uuidString

        let payload: [String: Any] = [
            "tenant_id": tenantId,
            "data_points": points.map { $0.toAPIDict() }
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        req.setValue(requestId, forHTTPHeaderField: "X-Request-ID")
        req.timeoutInterval = 30

        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(.serializationError(error.localizedDescription)))
            return
        }

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let error {
                if retry < self.maxRetries {
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.retryDelay) {
                        self.uploadBatch(points, retry: retry + 1, completion: completion)
                    }
                } else {
                    completion(.failure(.networkError(error.localizedDescription)))
                }
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }

            print("⬅️ INGEST STATUS:", http.statusCode)
            if let data, let body = String(data: data, encoding: .utf8) {
                print("⬅️ INGEST BODY:", body)
            }

            if (200...299).contains(http.statusCode) {
                completion(.success(()))
                return
            }

            if http.statusCode == 401 { completion(.failure(.authenticationError)); return }
            if http.statusCode == 403 { completion(.failure(.forbiddenError("Forbidden"))); return }

            if (500...599).contains(http.statusCode), retry < self.maxRetries {
                DispatchQueue.main.asyncAfter(deadline: .now() + self.retryDelay) {
                    self.uploadBatch(points, retry: retry + 1, completion: completion)
                }
                return
            }

            let msg = self.parseErrorMessage(from: data) ?? "HTTP \(http.statusCode)"
            completion(.failure(.unknownError(msg)))
        }.resume()
    }

    private func parseErrorMessage(from data: Data?) -> String? {
        guard let data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return (json["message"] as? String) ?? (json["detail"] as? String)
    }
}

struct HealthDataPoint {
    let dataType: String
    let value: Double
    let timestamp: Date
    let unit: String
    let sourceName: String
    let sourceVersion: String
    let device: String
    let metadata: [String: Any]

    func toAPIDict() -> [String: Any] {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var d: [String: Any] = [
            "data_type": dataType,
            "value": value,
            "timestamp": f.string(from: timestamp),
            "unit": unit,
            "source_name": sourceName,
            "source_version": sourceVersion,
            "device": device
        ]
        if !metadata.isEmpty { d["metadata"] = metadata }
        return d
    }
}

struct SyncResult {
    let totalBatches: Int
    let successfulBatches: Int
    let failedBatches: Int
    let totalRecords: Int
}

enum HealthDataError: Error {
    case healthKitNotAvailable
    case authorizationDenied
    case authorizationError(String)
    case healthKitQueryError(String)
    case networkError(String)
    case authenticationError
    case forbiddenError(String)
    case uploadFailed(String)
    case invalidURL
    case invalidResponse
    case serializationError(String)
    case unknownError(String)

    var localizedDescription: String {
        switch self {
        case .healthKitNotAvailable: return "HealthKit not available on this device."
        case .authorizationDenied: return "HealthKit permission denied."
        case .authorizationError(let s): return "Authorization error: \(s)"
        case .healthKitQueryError(let s): return "HealthKit query error: \(s)"
        case .networkError(let s): return "Network error: \(s)"
        case .authenticationError: return "Auth failed (JWT invalid/expired)."
        case .forbiddenError(let s): return "Forbidden: \(s)"
        case .uploadFailed(let s): return "Upload failed: \(s)"
        case .invalidURL: return "Invalid URL."
        case .invalidResponse: return "Invalid response."
        case .serializationError(let s): return "Serialization error: \(s)"
        case .unknownError(let s): return "Error: \(s)"
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}


