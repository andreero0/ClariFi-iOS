# Analytics Quick Reference

## 🚀 Quick Start

```swift
// Initialize (done automatically in ClariFi_iOSApp.swift)
Analytics.initialize()

// Track event
Analytics.track(.budgetCreated)

// Track event with properties
Analytics.track(.statementUploadCompleted, properties: [
    "transaction_count": 25,
    "processing_time": 3.5
])

// Track screen
Analytics.screen("dashboard")

// Track error
error.track(context: ["component": "upload"])
```

## 📊 Common Events

### Onboarding
```swift
.onboardingStarted
.onboardingCompleted
.privacyModeSelected
```

### Uploads
```swift
.statementUploadStarted
.statementUploadCompleted
.statementUploadFailed
```

### Budgets
```swift
.budgetCreated
.budgetTemplateSelected
.budgetExceeded
```

### Transactions
```swift
.transactionAdded
.transactionEdited
.transactionCategorized
```

### Premium
```swift
.paywallViewed
.subscriptionStarted
.subscriptionCompleted
```

### Privacy
```swift
.dataExported
.dataDeleted
.processingModeChanged
```

## 🎨 View Modifiers

```swift
// Track screen view
.trackScreen("settings")

// Track screen with properties
.trackScreen("dashboard", properties: ["user_type": "premium"])
```

## 🔧 Configuration

### Environment Variables
```bash
POSTHOG_API_KEY=phc_your_key_here
POSTHOG_HOST=https://app.posthog.com
```

### Enable/Disable
```swift
@AppStorage("analytics_enabled") var analyticsEnabled = false
```

## 🧪 Testing

```swift
// Use mock service
Analytics.service = MockAnalyticsService()

// Verify events
let mock = Analytics.service as! MockAnalyticsService
XCTAssertEqual(mock.trackedEvents.count, 1)
```

## 📱 User Settings

**Path**: Settings → Security → Analytics & Crash Reporting

**Controls**:
- Usage Analytics toggle
- Crash Reporting toggle
- Data collection info
- Reset analytics data

## 🔒 Privacy Rules

### ✅ DO Track
- Feature usage
- Screen views
- Error messages
- Session duration
- Device model/OS

### ❌ DON'T Track
- Transaction amounts
- Merchant names
- Categories
- Statement contents
- Personal info
- Location

## 📈 Key Metrics

### Engagement
- Daily Active Users
- Session duration
- Feature usage

### Conversion
- Onboarding completion
- Upload success rate
- Premium conversion

### Quality
- Crash rate
- Error frequency
- OCR confidence

## 🆘 Troubleshooting

### Events not appearing?
1. Check API key is set
2. Verify analytics is enabled
3. Check network connection
4. Review console logs

### Analytics not initializing?
1. Check environment variables
2. Verify `.env` file exists
3. Check Xcode scheme settings

## 📚 Documentation

- **Full Docs**: `ANALYTICS_IMPLEMENTATION.md`
- **Setup Guide**: `ANALYTICS_SETUP_GUIDE.md`
- **Completion**: `ANALYTICS_TASK_COMPLETION.md`

## 🔗 Links

- PostHog: [posthog.com](https://posthog.com)
- Docs: [posthog.com/docs](https://posthog.com/docs)
- Dashboard: [app.posthog.com](https://app.posthog.com)

---

**Quick Reference v1.0** | Last Updated: 2025-10-11
