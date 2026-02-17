import SwiftUI

struct HealthSyncView: View {
    @StateObject private var manager = HealthSyncManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("Health Sync")
                .font(.title2)
                .padding(.top, 20)

            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("Health Data Sync")
                .font(.largeTitle)
                .bold()

            VStack(spacing: 12) {
                if manager.isAuthorized {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("HealthKit Authorized")
                            .foregroundStyle(.green)
                            .bold()
                    }

                    Button {
                        manager.syncData()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync Health Data (30 days)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                } else {
                    Button {
                        manager.authorizeOnly()
                    } label: {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text("Authorize HealthKit")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(manager.syncStatus)
                .font(.footnote)
                .foregroundStyle(manager.isError ? .red : .secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
        .onAppear { manager.setup() }
    }
}


