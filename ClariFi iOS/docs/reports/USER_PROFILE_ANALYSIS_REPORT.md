# User Profile & Authentication Analysis

## Critical Finding: NO USER REGISTRATION SYSTEM EXISTS

### User's Question

**"I noticed that there are no profiles, so how do you save profiles? How do you put users? Do people just download the app and start using it?"**

### Answer: YES - Download and Start Using (Single-Device, Local-Only)

## Current State

### Architecture: Single-Device, No User Accounts

**ClariFi iOS is currently designed as a single-device, local-only app with NO user registration or profile system.**

**Evidence:**

1. **No User Entity in Core Data**
   - Searched for User/Profile entities: NONE found
   - Core Data schema has: Transaction, Account, Budget, Statement, etc.
   - NO user identification in database

2. **No Registration/Login Flow**
   - No registration screens
   - No login screens
   - No email/password system
   - No OAuth integration

3. **Onboarding Flow** (OnboardingViewModel.swift:1-179)
   ```swift
   // Onboarding just saves preferences to UserDefaults
   static func hasCompletedOnboarding() -> Bool {
       return UserDefaults.standard.bool(forKey: "com.clarifi.onboarding.completed")
   }

   func completeOnboarding(...) async {
       // Saves:
       // - Processing mode preference
       // - Biometric auth preference
       // - Created accounts
       // - First action preference

       userDefaults.set(true, forKey: onboardingCompletedKey)
       userDefaults.synchronize()
   }
   ```

4. **App Launch Flow** (ContentView.swift:16-77)
   ```swift
   @State private var showOnboarding = !OnboardingViewModel.hasCompletedOnboarding()

   var body: some View {
       Group {
           if showOnboarding {
               OnboardingView(...)  // Show onboarding once
           } else if showAuthenticationView {
               AuthenticationView(...)  // Biometric auth (if enabled)
           } else if isAuthenticated {
               MainTabView()  // Main app
           }
       }
   }
   ```

### How Users Are Identified: THEY AREN'T

**Current Approach:**
- Each device = one anonymous user
- No user ID, no username, no email
- Data stored locally in Core Data (SQLite)
- Preferences stored in UserDefaults
- Biometric auth tied to device (not user)

**What Gets "Saved":**
- ✅ Transactions → Core Data (local database)
- ✅ Accounts → Core Data
- ✅ Budgets → Core Data
- ✅ Statements → Core Data
- ✅ Preferences → UserDefaults (local key-value storage)
- ❌ NO user profile
- ❌ NO cloud sync
- ❌ NO multi-device support

## Critical Implications for Cloud Backup

### Problem: How Do We Identify Users in Supabase?

**Current Supabase Architecture Assumption:** Each user has a `user_id` for data isolation

**Reality:** App has no concept of users!

**This breaks the cloud backup architecture designed earlier:**

```sql
-- From SUPABASE_CLOUD_BACKUP_ARCHITECTURE.md
CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,  -- ❌ NO user_id!
    ...
);
```

### Three Solutions

#### Solution 1: Anonymous Users with Device ID (Recommended)

**Approach:** Generate stable device identifier, use as Supabase anonymous user

```swift
class DeviceIdentityManager {
    private let keychainKey = "com.clarifi.deviceIdentifier"

    func getOrCreateDeviceID() -> String {
        // Check Keychain for existing device ID
        if let existingID = KeychainHelper.retrieve(key: keychainKey) {
            return existingID
        }

        // Generate new device ID (survives app reinstall if stored in Keychain)
        let deviceID = UUID().uuidString
        KeychainHelper.store(key: keychainKey, value: deviceID)
        return deviceID
    }

    func authenticateWithSupabase() async throws -> String {
        let deviceID = getOrCreateDeviceID()

        // Use Supabase anonymous auth with device ID as metadata
        let session = try await supabase.auth.signInAnonymously()
        let userID = session.user.id

        // Store association
        try await supabase
            .from("devices")
            .insert([
                "user_id": userID,
                "device_identifier": deviceID,
                "device_name": UIDevice.current.name,
                "device_model": UIDevice.current.model
            ])
            .execute()

        return userID
    }
}
```

**Pros:**
- ✅ No user registration required
- ✅ Maintains privacy-first approach
- ✅ Device ID survives app reinstall (if in Keychain)
- ✅ Each device can backup independently
- ✅ Ready for multi-device support later

**Cons:**
- ⚠️ New device = new backup (can't access old device's data)
- ⚠️ Factory reset = lose access to backup (unless we add recovery codes)

#### Solution 2: Add Optional User Registration

**Approach:** Add optional email/password registration for cloud backup

**Flow:**
```
App Launch
    ↓
Onboarding (current flow)
    ↓
Main App
    ↓
Settings > Cloud Backup
    ↓
"To enable cloud backup, create an account"
    ↓
Registration Screen (email + password)
    ↓
Supabase Auth (email/password)
    ↓
Backup enabled with user_id
```

**Pros:**
- ✅ Multi-device sync possible
- ✅ User can access data from any device
- ✅ Industry standard approach
- ✅ Easier data recovery

**Cons:**
- ❌ Requires email (privacy concern)
- ❌ Adds complexity to onboarding
- ❌ Goes against "no registration" philosophy
- ❌ More development work

#### Solution 3: iCloud Keychain + Anonymous Auth

**Approach:** Use iCloud Keychain to sync device ID across user's devices

```swift
class iCloudDeviceIdentityManager {
    func getOrCreateDeviceID() -> String {
        // Store in iCloud Keychain (syncs across user's devices)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "clarifi.deviceIdentifier",
            kSecAttrSynchronizable as String: true,  // ✅ Syncs via iCloud
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data, let deviceID = String(data: data, encoding: .utf8) {
            return deviceID
        }

        // Generate and store new device ID
        let deviceID = UUID().uuidString
        let data = deviceID.data(using: .utf8)!

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "clarifi.deviceIdentifier",
            kSecAttrSynchronizable as String: true,  // ✅ Syncs via iCloud
            kSecValueData as String: data
        ]

        SecItemAdd(attributes as CFDictionary, nil)
        return deviceID
    }
}
```

**Pros:**
- ✅ No user registration required
- ✅ Device ID syncs across user's Apple devices
- ✅ Maintains privacy (Apple handles sync)
- ✅ User can access backup from multiple devices
- ✅ No email/password needed

**Cons:**
- ⚠️ Requires iCloud enabled (most users have it)
- ⚠️ Only works for Apple ecosystem
- ⚠️ Slight complexity in Keychain API

## Recommended Solution: Hybrid Approach

### Phase 1: Anonymous Auth with Device ID

**For MVP (first 2 weeks):**

```swift
// 1. Generate stable device ID (stored in Keychain)
let deviceID = DeviceIdentityManager.shared.getOrCreateDeviceID()

// 2. Authenticate anonymously with Supabase
let session = try await supabase.auth.signInAnonymously()
let userID = session.user.id

// 3. Associate device ID with Supabase user_id
try await registerDevice(userID: userID, deviceID: deviceID)

// 4. Use user_id for all data operations
```

**User Experience:**
- User downloads app → Onboarding → Enable cloud backup
- No registration required
- Data backed up to cloud
- Accessible from same device after reinstall (via device ID in Keychain)

### Phase 2: Optional iCloud Keychain Sync

**For v1.1 (after MVP):**

```swift
// Store device ID in iCloud Keychain
let deviceID = iCloudDeviceIdentityManager.shared.getOrCreateDeviceID()

// User's multiple devices will share same device ID
// → Access same Supabase backup from iPhone, iPad, Mac
```

**User Experience:**
- Same as Phase 1
- Bonus: Works across user's Apple devices automatically
- No registration still

### Phase 3: Optional User Registration

**For v2.0 (future):**

```swift
// Add optional registration for users who want it
Settings > Cloud Backup > Advanced > "Create Account for Multi-Device Sync"
```

**User Experience:**
- Most users: Anonymous auth (current flow)
- Power users: Optional registration for explicit multi-device sync

## Updated Supabase Schema

### Option 1: Device-Based (Recommended for MVP)

```sql
-- Device identity table
CREATE TABLE device_identities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_identifier TEXT UNIQUE NOT NULL,  -- From Keychain
    supabase_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_name TEXT,
    device_model TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transactions table (device-based)
CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    device_identity_id UUID NOT NULL REFERENCES device_identities(id) ON DELETE CASCADE,

    -- Encrypted fields
    encrypted_data JSONB NOT NULL,

    -- Queryable fields
    date DATE NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    category TEXT,

    -- Sync metadata
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    version INTEGER DEFAULT 1
);

-- RLS policies (device-based isolation)
CREATE POLICY "Users can access own device data"
    ON transactions FOR ALL
    USING (
        device_identity_id IN (
            SELECT id FROM device_identities
            WHERE supabase_user_id = auth.uid()
        )
    );
```

### Option 2: Direct Anonymous Auth (Simpler for MVP)

```sql
-- No device_identities table needed
-- Just use auth.users(id) directly

CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,  -- Anonymous user

    encrypted_data JSONB NOT NULL,
    date DATE NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,

    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

-- RLS policies (user-based isolation)
CREATE POLICY "Users can access own data"
    ON transactions FOR ALL
    USING (auth.uid() = user_id);
```

**Store device ID separately:**
```swift
// In app, associate device ID with Supabase user_id
UserDefaults.standard.set(deviceID, forKey: "clarifi.deviceIdentifier")
UserDefaults.standard.set(supabaseUserID, forKey: "clarifi.supabaseUserID")

// On subsequent launches, check if we already have a Supabase user_id
if let existingUserID = UserDefaults.standard.string(forKey: "clarifi.supabaseUserID") {
    // Reconnect to existing session
    try await supabase.auth.signInWithRefreshToken(...)
} else {
    // Create new anonymous user
    let session = try await supabase.auth.signInAnonymously()
    UserDefaults.standard.set(session.user.id, forKey: "clarifi.supabaseUserID")
}
```

## Implementation Plan

### Week 1: Device Identity System

**Day 1-2: Device ID Management**
- Create DeviceIdentityManager
- Implement Keychain storage
- Add device ID generation
- Unit tests

**Day 3-4: Supabase Anonymous Auth**
- Implement Supabase auth service
- Anonymous sign-in flow
- Token management
- Session persistence

**Day 5: Device Registration**
- Associate device ID with Supabase user_id
- Store in UserDefaults + Keychain
- Handle session refresh

### Week 2: Cloud Backup Integration

**Day 1-2: Update Backup Service**
- Modify CloudBackupService to use device-based auth
- Update all Supabase queries to use user_id
- Test backup/restore flow

**Day 3-4: UI Integration**
- Add "Enable Cloud Backup" in Settings
- Show backup status
- Handle first-time setup

**Day 5: Testing**
- Test app reinstall flow
- Test backup/restore
- Test device ID persistence

### Future Enhancements

**v1.1 (iCloud Keychain Sync):**
- Implement iCloudDeviceIdentityManager
- Test multi-device scenarios
- Add device management UI

**v2.0 (Optional Registration):**
- Add registration UI
- Implement email/password auth
- Migration from anonymous → registered
- Device linking UI

## Key Design Decisions

### Decision 1: No Forced Registration

**Rationale:**
- Privacy-first approach
- Lower friction (more users)
- Follows "download and start using" philosophy
- Can add registration later as optional feature

**Trade-off:**
- Single device per backup (initially)
- No cross-device sync (initially)

### Decision 2: Device ID in Keychain (Not iCloud Initially)

**Rationale:**
- Simpler for MVP
- No dependency on iCloud
- Works for 90% of users (single device)
- Can add iCloud sync in v1.1

**Trade-off:**
- New device = can't access old backup
- Need recovery mechanism for device replacement

### Decision 3: Supabase Anonymous Auth

**Rationale:**
- No email/password required
- Built-in RLS (security)
- Proper user isolation
- Can migrate to email auth later

**Trade-off:**
- Session management required
- Refresh token handling

## Recovery Strategy

### Problem: User Gets New Device

**Scenario:**
1. User has iPhone 13 with cloud backup
2. User upgrades to iPhone 15
3. User installs ClariFi on iPhone 15
4. New device ID generated
5. Can't access old backup!

### Solution: Recovery Codes

**Implementation:**
```swift
class CloudBackupRecoveryManager {
    func generateRecoveryCode() -> String {
        // Generate human-readable code
        let code = generateRandomCode(length: 6)  // e.g., "ABCD-1234"

        // Store in Supabase linked to user_id
        try await supabase
            .from("recovery_codes")
            .insert([
                "user_id": currentUserID,
                "code": code,
                "device_identifier": deviceID,
                "created_at": Date()
            ])
            .execute()

        return code
    }

    func restoreFromRecoveryCode(_ code: String) async throws {
        // Look up user_id from recovery code
        let result = try await supabase
            .from("recovery_codes")
            .select("user_id, device_identifier")
            .eq("code", value: code)
            .single()
            .execute()

        let userID = result["user_id"]
        let originalDeviceID = result["device_identifier"]

        // Create new device identity linked to same user_id
        let newDeviceID = UUID().uuidString
        KeychainHelper.store(key: "clarifi.deviceIdentifier", value: newDeviceID)
        UserDefaults.standard.set(userID, forKey: "clarifi.supabaseUserID")

        // Restore data from cloud
        try await cloudBackupService.restoreAllData()
    }
}
```

**User Flow:**
```
Settings > Cloud Backup > "Generate Recovery Code"
  ↓
Display: "ABCD-1234"
Message: "Save this code! You'll need it if you get a new device."
  ↓
User writes down code or saves to password manager
  ↓
[User gets new device]
  ↓
Install ClariFi → Onboarding → "I have a backup"
  ↓
Enter recovery code: "ABCD-1234"
  ↓
Restore data from cloud ✅
```

## Summary & Recommendation

### Current State: Single-Device, Local-Only

- ✅ No user registration (privacy-first)
- ✅ Download and start using
- ✅ Data stored locally (Core Data)
- ❌ No cloud backup
- ❌ No multi-device support
- ❌ Data lost on app uninstall

### Recommended Approach: Device-Based Anonymous Auth

**Phase 1 (MVP - 2 weeks):**
1. Generate device ID (Keychain)
2. Supabase anonymous authentication
3. Device-based cloud backup
4. Recovery code system

**Phase 2 (v1.1 - Future):**
1. iCloud Keychain sync (cross-device)
2. Device management UI

**Phase 3 (v2.0 - Future):**
1. Optional user registration
2. Email/password auth
3. Explicit multi-device sync

### Implementation Priority

**Critical (Do First):**
- ✅ DeviceIdentityManager
- ✅ Supabase anonymous auth
- ✅ Basic cloud backup (device-based)

**Important (Do Soon):**
- ✅ Recovery code system
- ✅ Session management
- ✅ Backup status UI

**Nice to Have (Future):**
- ⚠️ iCloud Keychain sync
- ⚠️ Optional registration
- ⚠️ Device management

---

**Report Date:** 2025-11-05
**Status:** Architecture updated for device-based anonymous authentication
**Next Step:** Implement DeviceIdentityManager and anonymous auth flow
