import Foundation
import Combine

@MainActor
final class HealthSyncManager: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var syncStatus: String = "Ready"
    @Published var lastSyncDate: Date?
    @Published var isError: Bool = false

    private var healthService: HealthDataService?

    private let apiEndpoint = "https://q79ilygtee.execute-api.us-east-2.amazonaws.com/prod"
    private let backendTokenURL = "http://192.168.1.204:5001/api/auth/health-token"

    func setup() {
        isError = false

        guard let tenantId = UserDefaults.standard.string(forKey: "userTenantId"),
              !tenantId.isEmpty else {
            syncStatus = "Error: Tenant ID not found (userTenantId)."
            isError = true
            return
        }

        syncStatus = "Fetching token from backend..."
        fetchHealthToken { [weak self] token in
            guard let self else { return }

            guard let token else {
                self.syncStatus = "Error: Failed to get token from backend"
                self.isError = true
                return
            }

            self.healthService = HealthDataService(
                apiEndpoint: self.apiEndpoint,
                jwtToken: token,
                tenantId: tenantId
            )

            self.authorizeOnly()
        }
    }

    func authorizeOnly() {
        guard let service = healthService else {
            syncStatus = "Service not initialized. Wait for token fetch (or tap Sync once)."
            isError = true
            return
        }

        syncStatus = "Requesting HealthKit permission..."
        isError = false

        service.requestAuthorization { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let ok):
                self.isAuthorized = ok
                self.syncStatus = ok ? "✅ Authorized" : "❌ Authorization denied"
                self.isError = !ok
            case .failure(let err):
                self.isAuthorized = false
                self.syncStatus = "❌ Authorization failed: \(err.localizedDescription)"
                self.isError = true
            }
        }
    }

    func syncData() {
        print("✅ syncData() button pressed")

        guard let service = healthService else {
            syncStatus = "Starting setup (fetching token)..."
            isError = false
            setup()
            return
        }

        guard isAuthorized else {
            syncStatus = "Not authorized. Tap Authorize first."
            isError = true
            return
        }

        syncStatus = "Syncing..."
        isError = false

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)! // ✅ 30 days

        print("✅ starting HealthKit fetch (last 30 days)")

        service.syncHealthData(from: startDate, to: endDate) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let r):
                self.lastSyncDate = Date()
                self.syncStatus = "✅ Sync Complete! Records: \(r.totalRecords) | Batches: \(r.successfulBatches)/\(r.totalBatches)"
                if r.failedBatches > 0 {
                    self.syncStatus += " | ⚠️ Failed: \(r.failedBatches)"
                }
                self.isError = false
            case .failure(let err):
                self.syncStatus = "❌ Sync Failed: \(err.localizedDescription)"
                self.isError = true
            }
        }
    }

    private func fetchHealthToken(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: backendTokenURL) else {
            print("❌ Invalid backend token URL:", backendTokenURL)
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let appAuthToken = UserDefaults.standard.string(forKey: "appAuthToken") ?? ""
        request.setValue("Bearer \(appAuthToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["expires_in_hours": 24])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print("❌ Token fetch error:", error.localizedDescription)
                DispatchQueue.main.async { completion(nil) }
                return
            }

            if let http = response as? HTTPURLResponse {
                print("⬅️ TOKEN STATUS:", http.statusCode)
            }

            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["token"] as? String else {
                print("❌ Token parse failed. Raw:", String(data: data ?? Data(), encoding: .utf8) ?? "nil")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            print("✅ Token fetched successfully")
            DispatchQueue.main.async { completion(token) }
        }.resume()
    }
}

