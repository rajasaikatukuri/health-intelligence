# iOS App - Health Data Sync

iOS app for syncing Apple HealthKit data to the Health Intelligence Platform.

## Quick Start

1. **Open Xcode**
2. **Create new project** (SwiftUI App)
3. **Add HealthKit capability**
4. **Copy Swift files** from this directory to your Xcode project
5. **Configure API endpoints** in `HealthSyncManager.swift`
6. **Run on real iPhone** (HealthKit doesn't work on simulator)

## Files

- `health_dataApp.swift` - Main app entry point
- `HealthDataService.swift` - HealthKit data fetching and upload
- `HealthSyncManager.swift` - Sync manager and token fetching
- `HealthSyncView.swift` - SwiftUI user interface
- `LocalNetworkPermission.swift` - Local network permission helper
- `IOS_SETUP.md` - Complete setup guide

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Real iPhone (HealthKit doesn't work on simulator)
- Backend running (local or deployed)

## Setup

See **[IOS_SETUP.md](./IOS_SETUP.md)** for complete step-by-step instructions.

## Features

- ✅ HealthKit data reading
- ✅ Automatic batching (500 records per batch)
- ✅ Retry logic with exponential backoff
- ✅ Progress tracking
- ✅ Error handling
- ✅ JWT token authentication
- ✅ Tenant isolation

## Data Types Supported

- Step count
- Distance walking/running
- Heart rate
- Active & basal energy burned
- Flights climbed
- Body mass
- Blood pressure
- Blood glucose
- Oxygen saturation
- Respiratory rate
- Sleep analysis
- Mindful sessions
- Workouts

## Configuration

Update these in `HealthSyncManager.swift`:

```swift
// AWS API Gateway endpoint
private let apiEndpoint = "https://your-api-id.execute-api.us-east-2.amazonaws.com/prod"

// Local backend endpoint (for development)
private let backendTokenURL = "http://YOUR_MAC_IP:5001/api/auth/health-token"
```

## Testing

1. Run on real iPhone
2. Grant HealthKit permissions
3. Tap "Sync Health Data"
4. Check backend logs for incoming data
5. Verify data in S3/Athena

---

For detailed setup instructions, see **[IOS_SETUP.md](./IOS_SETUP.md)**


