import SwiftUI

@main
struct health_dataApp: App {

    init() {
        UserDefaults.standard.set("rajasaikatukuri", forKey: "userTenantId")
        UserDefaults.standard.set("test-token", forKey: "appAuthToken")

        print("✅ tenant_id set:", UserDefaults.standard.string(forKey: "userTenantId") ?? "nil")
        print("✅ appAuthToken set:", UserDefaults.standard.string(forKey: "appAuthToken") ?? "nil")
    }

    var body: some Scene {
        WindowGroup {
            HealthSyncView()
        }
    }
}

