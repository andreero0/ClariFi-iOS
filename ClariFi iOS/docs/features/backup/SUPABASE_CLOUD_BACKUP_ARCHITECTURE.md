# Supabase Cloud Backup Architecture for ClariFi iOS

## Executive Summary

This document outlines the architecture for integrating Supabase cloud backup into ClariFi iOS to address data loss issues and enable cross-device synchronization while maintaining the app's privacy-first principles.

## Problem Statement

**Current State:**
- Core Data persistence works correctly (SQLite with WAL mode)
- Data deleted on app uninstall (iOS standard behavior)
- No cloud backup capability
- No data export/import functionality
- User experienced data loss after app reinstall

**User Requirement:**
"I put in some data and you did a reset, and everything I put in here has gone. Does this thing is hooked to a database? And if it's not hooked to a database, why can't we connect it to something like Supabase? Make that available."

## Core Data Schema Analysis

### Entities to Sync (8 entities)

1. **Transaction** - Primary financial data
   - id (UUID), date, merchant, amount, currency, category, confidence, isManual, notes, tags
   - Relations: account, statement

2. **Account** - Financial accounts
   - id (UUID), name, type, lastFourDigits, isActive, isDefault

3. **Statement** - Uploaded statements
   - id (UUID), fileName, uploadDate, fileHash, processingStatus, fileSize, documentType

4. **Budget** - Budget definitions
   - id (UUID), name, period, startDate, isActive, rolloverEnabled

5. **BudgetCategory** - Budget category breakdown
   - id (UUID), name, budgetedAmount, spentAmount, rolloverEnabled, alertThreshold, color

6. **RecurringTransaction** - Recurring payment definitions
   - id (UUID), merchant, amount, currency, category, frequency, startDate, endDate, nextOccurrence

7. **CategorizationRule** - User-defined categorization rules
   - id (UUID), name, merchantPattern, category, priority, isActive, matchType, minAmount, maxAmount

8. **MerchantPattern** - Learned merchant normalization patterns
   - id (UUID), merchantName, normalizedName, category, confidence, occurrenceCount, lastUsed

## Supabase Project

**Selected Project:** NestSyncV1.2
- ID: huhkefkuamkeoxekzkuf
- Region: us-east-2
- Status: ACTIVE_HEALTHY
- Database: PostgreSQL 17.4.1

## Architecture Design

### 1. Sync Strategy: Hybrid Approach

**Recommendation: Manual Backup with Automatic Sync Option**

```swift
enum SyncStrategy {
    case manual          // User triggers backup/restore manually
    case automatic       // Auto-sync on changes (requires user opt-in)
    case wifiOnly        // Auto-sync only on WiFi
}
```

**Rationale:**
- Privacy-first: User controls when data leaves device
- Bandwidth-conscious: Avoid cellular data usage by default
- Progressive enhancement: Start with manual, add automatic later

### 2. Privacy & Encryption

**End-to-End Encryption Required**

```
Device                              Supabase Cloud
------                              --------------
Core Data                           PostgreSQL
   ↓                                    ↑
Encrypt with                            |
user's key                              |
   ↓                                    |
Supabase SDK  ──────────────────────→  Encrypted
(HTTPS)                                 Backup
```

**Encryption Strategy:**
1. Generate user-specific encryption key (stored in Keychain)
2. Encrypt sensitive fields before sending to Supabase
3. Store encrypted JSON in Supabase
4. Decrypt on device after retrieval

**Fields to Encrypt:**
- Transaction: merchant, notes, tags
- Account: name, lastFourDigits
- RecurringTransaction: merchant, notes
- Budget: name
- BudgetCategory: name
- CategorizationRule: merchantPattern

**Fields NOT Encrypted (for query capability):**
- UUIDs, dates, amounts (for filtering/sorting)
- createdAt, updatedAt (for sync logic)
- isActive, isDefault (for state management)

### 3. Supabase Schema Design

**SQL Schema (PostgreSQL):**

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Device registration for multi-device support
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_name TEXT,
    device_model TEXT,
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Accounts
CREATE TABLE accounts (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id),

    -- Encrypted fields (stored as JSONB)
    encrypted_data JSONB NOT NULL,

    -- Queryable fields (not encrypted)
    type TEXT,
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,

    -- Sync metadata
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    version INTEGER DEFAULT 1,

    -- For conflict resolution
    device_updated_at TIMESTAMPTZ NOT NULL
);

-- Transactions
CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id),
    account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
    statement_id UUID REFERENCES statements(id) ON DELETE SET NULL,

    -- Encrypted fields
    encrypted_data JSONB NOT NULL,

    -- Queryable fields
    date DATE NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    category TEXT,
    confidence REAL,
    is_manual BOOLEAN DEFAULT false,

    -- Sync metadata
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    device_updated_at TIMESTAMPTZ NOT NULL,

    -- Indexes for performance
    INDEX idx_transactions_date (user_id, date DESC),
    INDEX idx_transactions_category (user_id, category)
);

-- Statements
CREATE TABLE statements (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id),

    encrypted_data JSONB NOT NULL,

    file_hash TEXT UNIQUE,
    upload_date TIMESTAMPTZ,
    processing_status TEXT,
    file_size BIGINT,
    document_type TEXT,

    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    device_updated_at TIMESTAMPTZ NOT NULL,

    INDEX idx_statements_hash (user_id, file_hash)
);

-- Budgets
CREATE TABLE budgets (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id),

    encrypted_data JSONB NOT NULL,

    period TEXT,
    start_date DATE,
    is_active BOOLEAN DEFAULT true,
    rollover_enabled BOOLEAN DEFAULT false,

    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    device_updated_at TIMESTAMPTZ NOT NULL
);

-- Budget Categories
CREATE TABLE budget_categories (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id),
    budget_id UUID REFERENCES budgets(id) ON DELETE CASCADE,

    encrypted_data JSONB NOT NULL,

    budgeted_amount DECIMAL(15, 2),
    spent_amount DECIMAL(15, 2) DEFAULT 0,
    rollover_enabled BOOLEAN DEFAULT false,
    alert_threshold REAL,
    color TEXT,

    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    device_updated_at TIMESTAMPTZ NOT NULL
);

-- Recurring Transactions
CREATE TABLE recurring_transactions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id),
    account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,

    encrypted_data JSONB NOT NULL,

    amount DECIMAL(15, 2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    category TEXT,
    frequency TEXT,
    start_date DATE,
    end_date DATE,
    next_occurrence DATE,
    is_active BOOLEAN DEFAULT true,

    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    device_updated_at TIMESTAMPTZ NOT NULL
);

-- Categorization Rules
CREATE TABLE categorization_rules (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id),

    encrypted_data JSONB NOT NULL,

    category TEXT,
    priority INTEGER,
    is_active BOOLEAN DEFAULT true,
    match_type TEXT,
    min_amount DECIMAL(15, 2),
    max_amount DECIMAL(15, 2),
    is_user_created BOOLEAN DEFAULT false,
    application_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    device_updated_at TIMESTAMPTZ NOT NULL
);

-- Merchant Patterns
CREATE TABLE merchant_patterns (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id),

    encrypted_data JSONB NOT NULL,

    category TEXT,
    confidence REAL,
    occurrence_count INTEGER DEFAULT 1,
    last_used TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    synced_at TIMESTAMPTZ DEFAULT NOW(),
    version INTEGER DEFAULT 1,
    device_updated_at TIMESTAMPTZ NOT NULL
);

-- Sync Log (for debugging and monitoring)
CREATE TABLE sync_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id),

    sync_type TEXT NOT NULL, -- 'backup', 'restore', 'sync'
    entity_type TEXT NOT NULL,
    entity_count INTEGER,
    status TEXT NOT NULL, -- 'success', 'partial', 'failed'
    error_message TEXT,

    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    duration_ms INTEGER
);

-- Row Level Security (RLS) Policies
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE statements ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE categorization_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchant_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_log ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (users can only access their own data)
CREATE POLICY "Users can access own devices"
    ON devices FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can access own accounts"
    ON accounts FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can access own transactions"
    ON transactions FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can access own statements"
    ON statements FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can access own budgets"
    ON budgets FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can access own budget categories"
    ON budget_categories FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can access own recurring transactions"
    ON recurring_transactions FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can access own categorization rules"
    ON categorization_rules FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can access own merchant patterns"
    ON merchant_patterns FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Users can access own sync log"
    ON sync_log FOR ALL
    USING (auth.uid() = user_id);
```

### 4. Conflict Resolution Strategy

**Last-Write-Wins with Version Tracking**

```swift
struct SyncMetadata {
    var version: Int
    var updatedAt: Date
    var deviceUpdatedAt: Date
    var syncedAt: Date?
}

enum ConflictResolution {
    case useLocal      // Keep device version
    case useRemote     // Use cloud version
    case merge         // Attempt to merge (not implemented initially)
    case askUser       // Prompt user to choose
}

func resolveConflict<T>(
    local: T,
    remote: T,
    strategy: ConflictResolution
) -> T where T: SyncableEntity {
    switch strategy {
    case .useLocal:
        return local
    case .useRemote:
        return remote
    case .merge:
        // Complex merge logic (future enhancement)
        return local.deviceUpdatedAt > remote.deviceUpdatedAt ? local : remote
    case .askUser:
        // Show UI for user decision (future enhancement)
        return local
    }
}
```

### 5. Swift Implementation Architecture

**Directory Structure:**
```
Services/
  Sync/
    SupabaseService.swift              // Main Supabase client
    CloudBackupService.swift           // High-level backup/restore
    EncryptionService.swift            // E2E encryption (already exists)
    SyncCoordinator.swift              // Orchestrates sync operations
    ConflictResolver.swift             // Handles conflicts
    SyncableEntity.swift               // Protocol for syncable entities

Models/
  Sync/
    SyncMetadata.swift                 // Sync tracking
    SyncOperation.swift                // Operation definitions

ViewModels/
  CloudBackupViewModel.swift           // UI for backup/restore

Views/
  Settings/
    CloudBackupView.swift              // Backup settings UI
```

**Core Protocols:**

```swift
// Protocol for entities that can be synced
protocol SyncableEntity {
    var id: UUID { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var version: Int { get set }
    var deviceUpdatedAt: Date { get set }

    func toEncryptedPayload(using encryptionService: EncryptionService) throws -> EncryptedPayload
    static func fromEncryptedPayload(_ payload: EncryptedPayload, using encryptionService: EncryptionService) throws -> Self
}

struct EncryptedPayload: Codable {
    let encryptedData: String  // Base64-encoded encrypted JSON
    let queryableFields: [String: AnyCodable]  // Non-sensitive fields
}

// Supabase Service
protocol SupabaseServiceProtocol {
    func authenticate(anonymously: Bool) async throws -> String  // Returns user_id
    func backup<T: SyncableEntity>(_ entities: [T], table: String) async throws -> Int
    func restore<T: SyncableEntity>(from table: String, since: Date?) async throws -> [T]
    func sync<T: SyncableEntity>(_ entities: [T], table: String) async throws -> SyncResult<T>
}

struct SyncResult<T> {
    let uploaded: Int
    let downloaded: Int
    let conflicts: [(local: T, remote: T)]
}

// Cloud Backup Service
protocol CloudBackupServiceProtocol {
    func backupAllData(strategy: SyncStrategy) async throws -> BackupResult
    func restoreAllData(overwriteLocal: Bool) async throws -> RestoreResult
    func enableAutomaticSync(strategy: SyncStrategy) async throws
    func disableAutomaticSync() async throws
    func getLastBackupDate() async -> Date?
}

struct BackupResult {
    let totalEntities: Int
    let successfulBackups: Int
    let failedBackups: [(entity: String, error: Error)]
    let duration: TimeInterval
}

struct RestoreResult {
    let totalEntities: Int
    let successfulRestores: Int
    let conflicts: Int
    let duration: TimeInterval
}
```

### 6. Authentication Strategy

**Anonymous Authentication with Device Binding**

```swift
class SupabaseAuthManager {
    func getOrCreateUser() async throws -> String {
        // Check for existing user_id in Keychain
        if let existingUserId = KeychainHelper.retrieveUserId() {
            return existingUserId
        }

        // Create anonymous user in Supabase
        let response = try await supabase.auth.signInAnonymously()
        let userId = response.user.id

        // Store in Keychain
        KeychainHelper.storeUserId(userId)

        // Register device
        try await registerDevice(userId: userId)

        return userId
    }

    private func registerDevice(userId: String) async throws {
        let device = [
            "user_id": userId,
            "device_name": UIDevice.current.name,
            "device_model": UIDevice.current.model
        ]

        try await supabase
            .from("devices")
            .insert(device)
            .execute()
    }
}
```

### 7. UI/UX Design

**Privacy Settings > Cloud Backup Section:**

```
┌─────────────────────────────────┐
│ Cloud Backup & Sync             │
├─────────────────────────────────┤
│                                 │
│ ☁️  Cloud Backup               │
│                                 │
│ Last backup: 2 hours ago        │
│ 1,247 transactions backed up    │
│                                 │
│ [Backup Now]                    │
│                                 │
│ ├─ Automatic Backup        [○] │
│ ├─ Sync Strategy                │
│ │   • Manual Only         [●]   │
│ │   • Automatic           [ ]   │
│ │   • WiFi Only           [ ]   │
│ │                                │
│ ├─ End-to-End Encryption   [●] │
│ │   Your data is encrypted      │
│ │   before leaving your device  │
│ │                                │
│ ├─ Restore from Backup...       │
│ │                                │
│ └─ Export Data...                │
│                                 │
└─────────────────────────────────┘
```

**Restore Flow:**

```
Step 1: Confirmation
┌─────────────────────────────────┐
│ Restore from Cloud Backup       │
├─────────────────────────────────┤
│                                 │
│ Last backup: 2 hours ago        │
│ Contains:                       │
│   • 1,247 transactions          │
│   • 3 accounts                  │
│   • 2 budgets                   │
│   • 15 recurring transactions   │
│                                 │
│ Warning: This will merge cloud  │
│ data with your local data.      │
│                                 │
│ [Cancel]  [Restore]             │
└─────────────────────────────────┘

Step 2: Progress
┌─────────────────────────────────┐
│ Restoring from Cloud...         │
├─────────────────────────────────┤
│                                 │
│ Downloading data...             │
│ ████████████░░░░░░░░ 67%        │
│                                 │
│ 834 / 1,247 transactions        │
│                                 │
└─────────────────────────────────┘

Step 3: Completion
┌─────────────────────────────────┐
│ Restore Complete                │
├─────────────────────────────────┤
│                                 │
│ ✓ Successfully restored:        │
│   • 1,247 transactions          │
│   • 3 accounts                  │
│   • 2 budgets                   │
│                                 │
│ ⚠ 3 conflicts resolved          │
│   (Local data was newer)        │
│                                 │
│ [Done]                          │
└─────────────────────────────────┘
```

### 8. Implementation Phases

**Phase 1: Foundation (Week 1)**
- [ ] Create Supabase database schema
- [ ] Implement SupabaseService with basic CRUD
- [ ] Implement authentication with anonymous users
- [ ] Create encryption layer for sensitive data
- [ ] Unit tests for sync logic

**Phase 2: Backup/Restore (Week 2)**
- [ ] Implement CloudBackupService
- [ ] Create backup workflow (all entities)
- [ ] Create restore workflow with conflict resolution
- [ ] Add CloudBackupViewModel
- [ ] Create CloudBackupView UI

**Phase 3: Testing & Polish (Week 3)**
- [ ] Integration testing (backup → uninstall → restore)
- [ ] Test conflict resolution scenarios
- [ ] Performance testing (large datasets)
- [ ] Add progress indicators
- [ ] Error handling and user feedback

**Phase 4: Automatic Sync (Week 4 - Future)**
- [ ] Implement SyncCoordinator
- [ ] Add background sync capability
- [ ] Implement delta sync (only changed records)
- [ ] Add sync status indicators in UI
- [ ] Network reachability monitoring

### 9. Security Considerations

**Encryption Keys:**
```swift
class EncryptionKeyManager {
    static func getOrCreateUserKey() throws -> Data {
        // Check Keychain for existing key
        if let existingKey = KeychainHelper.retrieveEncryptionKey() {
            return existingKey
        }

        // Generate new 256-bit key
        var keyData = Data(count: 32)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }

        guard result == errSecSuccess else {
            throw EncryptionError.keyGenerationFailed
        }

        // Store in Keychain with kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        try KeychainHelper.storeEncryptionKey(keyData)

        return keyData
    }
}
```

**Data Flow Security:**
1. Device generates encryption key (stored in Keychain)
2. Sensitive data encrypted with AES-256-GCM before network transmission
3. HTTPS transport layer (TLS 1.3)
4. Supabase Row-Level Security (RLS) policies enforce user isolation
5. Anonymous auth prevents email/password vulnerabilities

### 10. Performance Optimization

**Batch Operations:**
```swift
// Instead of syncing one-by-one
for transaction in transactions {
    try await supabase.from("transactions").insert(transaction)
}

// Batch insert (up to 100 at a time)
let batches = transactions.chunked(into: 100)
for batch in batches {
    try await supabase.from("transactions").insert(batch)
}
```

**Delta Sync:**
```swift
func syncTransactions(since lastSyncDate: Date?) async throws {
    // Only fetch records updated after last sync
    let remoteChanges = try await supabase
        .from("transactions")
        .select()
        .gte("updated_at", value: lastSyncDate?.iso8601String ?? "1970-01-01")
        .execute()

    // Only upload local changes since last sync
    let localChanges = try await transactionRepository
        .fetchTransactionsUpdatedSince(lastSyncDate)

    // Sync only deltas
    try await uploadChanges(localChanges)
    try await applyRemoteChanges(remoteChanges)
}
```

### 11. Cost Estimation

**Supabase Pricing (Free Tier):**
- Database: 500 MB storage
- Bandwidth: 5 GB egress/month
- Row-level security: Included
- Authentication: 50,000 monthly active users

**Typical User Data:**
- 1,000 transactions × 500 bytes = 500 KB
- 10 accounts × 200 bytes = 2 KB
- 5 budgets × 300 bytes = 1.5 KB
- Total: ~500 KB per user

**Free tier supports:** ~1,000 active users

### 12. Testing Strategy

**Unit Tests:**
```swift
class CloudBackupServiceTests: XCTestCase {
    func testBackupTransactions() async throws {
        // Given
        let transactions = createMockTransactions(count: 100)

        // When
        let result = try await cloudBackupService.backup(transactions)

        // Then
        XCTAssertEqual(result.successfulBackups, 100)
        XCTAssertTrue(result.failedBackups.isEmpty)
    }

    func testRestoreWithConflict() async throws {
        // Given
        let localTransaction = createTransaction(updatedAt: Date())
        let remoteTransaction = createTransaction(updatedAt: Date().addingTimeInterval(-3600))

        // When
        let result = try await cloudBackupService.resolveConflict(
            local: localTransaction,
            remote: remoteTransaction,
            strategy: .useLocal
        )

        // Then
        XCTAssertEqual(result.id, localTransaction.id)
    }
}
```

**Integration Tests:**
```swift
class CloudBackupIntegrationTests: XCTestCase {
    func testFullBackupRestoreCycle() async throws {
        // 1. Create local data
        let transactions = try await createTestTransactions(count: 50)

        // 2. Backup to Supabase
        let backupResult = try await cloudBackupService.backupAllData(strategy: .manual)
        XCTAssertEqual(backupResult.totalEntities, 50)

        // 3. Clear local data
        try await clearAllLocalData()

        // 4. Restore from Supabase
        let restoreResult = try await cloudBackupService.restoreAllData(overwriteLocal: true)
        XCTAssertEqual(restoreResult.totalEntities, 50)

        // 5. Verify data integrity
        let restoredTransactions = try await transactionRepository.fetchAll()
        XCTAssertEqual(restoredTransactions.count, 50)
    }
}
```

## Next Steps

1. **Review & Approve**: User reviews this architecture
2. **Create Supabase Schema**: Apply SQL migration to NestSyncV1.2
3. **Implement Core Services**: SupabaseService, CloudBackupService
4. **Build UI**: CloudBackupView in Privacy Settings
5. **Test**: Full backup/restore cycle
6. **Deploy**: Enable for production use

## References

- Supabase Docs: https://supabase.com/docs
- Swift Crypto: https://github.com/apple/swift-crypto
- Core Data Sync Patterns: https://developer.apple.com/documentation/coredata/synchronizing_a_local_store_to_the_cloud
