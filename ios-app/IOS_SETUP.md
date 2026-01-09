# iOS App (Xcode + HealthKit) — Complete Setup Guide

This section explains exactly how the iOS app was built and configured so anyone can clone the repo and run it without guesswork.

## Prerequisites

- **macOS** with Xcode installed
- **iPhone** (HealthKit does NOT work on simulator)
- **Apple Developer Account** (free account works for development)
- **Backend running** (local or deployed)

---

## 1. Xcode Project Creation

1. **Open Xcode**
2. **Create a new project**:
   - File → New → Project
   - Choose: **App**
   - Click **Next**
3. **Project settings**:
   - **Product Name**: `health_data` (or your preferred name)
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Lifecycle**: **SwiftUI App**
   - **Use Core Data**: ❌ No
   - **Include Tests**: Optional
4. **Choose location** and click **Create**
5. **Bundle Identifier**: Must be unique (e.g., `com.yourname.healthdata`)

---

## 2. Enable Capabilities

In Xcode → **Project** → **Target** → **Signing & Capabilities**:

### Add HealthKit Capability

1. Click **"+ Capability"**
2. Search for **"HealthKit"**
3. Double-click to add
4. ✅ HealthKit capability added

### Add Background Modes (Optional but Recommended)

1. Click **"+ Capability"**
2. Search for **"Background Modes"**
3. Double-click to add
4. Check: **Background fetch**

---

## 3. Info.plist Configuration

Open `Info.plist` (or use Info tab in Xcode) and add:

### HealthKit Permissions

```xml
<key>NSHealthShareUsageDescription</key>
<string>This app reads your health data to generate analytics and insights.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>This app processes your health data securely.</string>
```

### Local Network Permission (for local backend testing)

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Used to connect to local backend services during development.</string>
```

### App Transport Security (DEV ONLY - Remove in Production!)

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

⚠️ **IMPORTANT**: `NSAllowsArbitraryLoads` is **ONLY for local development**. Must be removed or restricted in production.

---

## 4. Real Device Requirement

**HealthKit DOES NOT work on iOS Simulator.**

### Steps to Run on Real Device:

1. **Connect iPhone via USB**
2. **Enable Developer Mode on iPhone**:
   - Settings → Privacy & Security → Developer Mode → **ON**
   - Restart iPhone if prompted
3. **Trust developer certificate** when prompted on iPhone
4. **Select your iPhone** as the run destination in Xcode (top toolbar)
5. **Run the app** (⌘R)

---

## 5. Add Swift Files to Project

Copy these files from `ios-app/` directory to your Xcode project:

1. **health_dataApp.swift** - Main app entry point
2. **HealthDataService.swift** - HealthKit data fetching and upload
3. **HealthSyncManager.swift** - Sync manager and token fetching
4. **HealthSyncView.swift** - SwiftUI view
5. **LocalNetworkPermission.swift** - Local network permission helper

### How to Add Files:

1. In Xcode, right-click on your project folder
2. Select **"Add Files to [Project Name]"**
3. Navigate to `ios-app/` directory
4. Select all `.swift` files
5. Check **"Copy items if needed"**
6. Check **"Create groups"**
7. Click **"Add"**

---

## 6. Configure API Endpoints

### Update HealthSyncManager.swift

Find these lines and update with your backend URLs:

```swift
// For production (AWS API Gateway)
private let apiEndpoint = "https://your-api-id.execute-api.us-east-2.amazonaws.com/prod"

// For local development (your Mac's LAN IP)
private let backendTokenURL = "http://YOUR_MAC_IP:5001/api/auth/health-token"
```

**To find your Mac's LAN IP:**
```bash
# On your Mac, run:
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Use the IP address shown (e.g., `192.168.1.204`)

---

## 7. App Bootstrap (Tenant + Auth)

The app uses local UserDefaults for development:

### In health_dataApp.swift:

```swift
init() {
    UserDefaults.standard.set("rajasaikatukuri", forKey: "userTenantId")
    UserDefaults.standard.set("test-token", forKey: "appAuthToken")
}
```

**For production**, replace with:
- Real authentication flow
- Secure token storage (Keychain)
- User login/signup

---

## 8. HealthSyncManager Responsibilities

### On App Launch:

1. Reads `tenant_id` from UserDefaults
2. Calls local backend: `POST http://<mac-lan-ip>:5001/api/auth/health-token`
3. Receives JWT token
4. Initializes `HealthDataService`
5. Requests HealthKit authorization

### User Actions:

- **"Authorize HealthKit"** → Shows HealthKit permission dialog
- **"Sync Health Data"** → Fetches last 30 days and uploads to AWS

---

## 9. HealthKit Authorization

The app requests authorization for:

### Quantity Types:
- Step count
- Distance walking/running
- Heart rate
- Active & basal energy burned
- Flights climbed
- Body mass
- Blood pressure (systolic/diastolic)
- Blood glucose
- Oxygen saturation
- Respiratory rate

### Category Types:
- Sleep analysis
- Mindful sessions

### Workout Types:
- All workout types

**Note**: Authorization is requested **ONCE** and persisted by iOS. Users can revoke in Settings → Health → Data Access & Devices.

---

## 10. Data Sync Logic

### When Sync is Triggered:

1. **Fetch last 30 days** of health data
2. **Fetch ALL HealthKit sample types** concurrently (using DispatchGroup)
3. **Normalize data** into common schema (`HealthDataPoint`)
4. **Batch records** (500 per batch)
5. **Upload to AWS API Gateway**:
   - `POST https://<api-id>.execute-api.<region>.amazonaws.com/prod/ingest`
   - Headers:
     - `Authorization: Bearer <JWT>`
     - `Content-Type: application/json`
     - `X-Request-ID: <UUID>`

### Retry Logic:

- **Max retries**: 3
- **Retry delay**: 2 seconds
- **Automatic retry** on network errors or 5xx server errors

---

## 11. Network & Permissions Notes

### Local Network Permission:

- **iOS shows popup** ONLY after first LAN request
- **If denied**:
  1. Delete app from iPhone
  2. Re-run from Xcode
  3. Allow Local Network when prompted

### HealthKit Permissions:

- Managed in: **Settings → Health → Data Access & Devices**
- Can be reset by deleting the app
- Permissions persist across app updates

---

## 12. Common Errors & Fixes

### Error: "Service not initialized"

**Cause**: Token fetch has not completed yet  
**Fix**: Wait for backend response, or tap "Sync" button again

### Error: "authorizationDenied"

**Cause**: HealthKit permission not granted  
**Fix**: 
1. Open Health app on iPhone
2. Go to: Health → Sharing → Apps
3. Find your app and allow permissions

### Error: Local network offline (-1009)

**Cause**: Local Network permission not allowed  
**Fix**: 
1. Delete app from iPhone
2. Re-run from Xcode
3. Allow Local Network when prompted

### Error: "Cannot connect to backend"

**Cause**: Backend not running or wrong IP address  
**Fix**:
1. Verify backend is running: `curl http://YOUR_IP:5001/health`
2. Check iPhone and Mac are on same WiFi network
3. Update `backendTokenURL` in `HealthSyncManager.swift`

### Error: "Token fetch failed"

**Cause**: Backend endpoint not accessible  
**Fix**:
1. Check backend is running
2. Verify endpoint: `/api/auth/health-token` exists
3. Check CORS settings if using web backend

---

## 13. Production Notes

### Before Releasing to App Store:

1. **Remove `NSAllowsArbitraryLoads`** from Info.plist
2. **Use HTTPS backend** (not HTTP)
3. **Replace dev tenant injection** with real authentication
4. **Use Keychain** for token storage (not UserDefaults)
5. **Replace local FastAPI** with deployed backend URL
6. **Add proper error handling** and user feedback
7. **Test on multiple devices** and iOS versions
8. **Add App Store screenshots** and descriptions

### Security Checklist:

- [ ] No hardcoded credentials
- [ ] Tokens stored in Keychain
- [ ] HTTPS only (no HTTP)
- [ ] Proper error handling
- [ ] User privacy respected
- [ ] HealthKit permissions clearly explained

---

## 14. Testing

### Test HealthKit Authorization:

1. Run app on iPhone
2. Tap "Authorize HealthKit"
3. Verify permission dialog appears
4. Grant permissions
5. Verify "✅ Authorized" message

### Test Data Sync:

1. Ensure HealthKit has data (use Health app to add sample data)
2. Tap "Sync Health Data"
3. Watch console logs for progress
4. Verify data appears in S3/Athena

### Test Backend Connection:

1. Start local backend: `cd backend && python3 main.py`
2. Run iOS app
3. Check backend logs for token request
4. Verify token is returned

---

## 15. File Structure

```
ios-app/
├── health_dataApp.swift          # Main app entry point
├── HealthDataService.swift        # HealthKit data service
├── HealthSyncManager.swift        # Sync manager
├── HealthSyncView.swift           # SwiftUI view
├── LocalNetworkPermission.swift   # Network permission helper
└── IOS_SETUP.md                   # This file
```

---

## 16. Integration with Backend

### Backend Endpoint Required:

The iOS app expects a backend endpoint:

```
POST /api/auth/health-token
Headers:
  Authorization: Bearer <appAuthToken>
Body:
  { "expires_in_hours": 24 }
Response:
  { "token": "<jwt-token>" }
```

### Add to Backend (FastAPI):

```python
@app.post("/api/auth/health-token")
def get_health_token(request: TokenRequest, authorization: str = Header(None)):
    """Generate JWT token for iOS HealthKit sync."""
    # Verify appAuthToken
    # Generate JWT with tenant_id
    # Return token
    return {"token": jwt_token}
```

---

## 17. Troubleshooting Checklist

- [ ] iPhone connected via USB
- [ ] Developer Mode enabled on iPhone
- [ ] HealthKit capability added in Xcode
- [ ] Info.plist has HealthKit usage descriptions
- [ ] Backend is running and accessible
- [ ] Mac and iPhone on same WiFi network
- [ ] Local Network permission granted
- [ ] HealthKit permissions granted in Settings
- [ ] API endpoints configured correctly
- [ ] Tenant ID set in UserDefaults

---

## 18. Next Steps

1. ✅ Set up Xcode project
2. ✅ Add Swift files
3. ✅ Configure capabilities
4. ✅ Update API endpoints
5. ✅ Test on real iPhone
6. ✅ Verify HealthKit authorization
7. ✅ Test data sync
8. ✅ Deploy to TestFlight (optional)
9. ✅ Submit to App Store (when ready)

---

**For questions or issues, check the main README.md or backend documentation.**

