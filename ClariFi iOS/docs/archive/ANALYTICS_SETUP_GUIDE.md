# Analytics Setup Guide - PostHog Integration

## Quick Start (5 minutes)

### Step 1: Get PostHog API Key

1. Go to [posthog.com](https://posthog.com) and sign up (free tier available)
2. Create a new project or use existing one
3. Navigate to **Project Settings** → **Project API Key**
4. Copy your API key (starts with `phc_`)

### Step 2: Configure Environment

Create or update `.env` file in project root:

```bash
POSTHOG_API_KEY=phc_your_api_key_here
POSTHOG_HOST=https://app.posthog.com
```

**For Xcode:**
1. Open your scheme: **Product** → **Scheme** → **Edit Scheme**
2. Select **Run** → **Arguments** tab
3. Add environment variables:
   - `POSTHOG_API_KEY` = `phc_your_api_key_here`
   - `POSTHOG_HOST` = `https://app.posthog.com`

### Step 3: Test Integration

1. Run the app in simulator or device
2. Navigate through the app (onboarding, upload statement, create budget)
3. Check PostHog dashboard for events (may take 1-2 minutes)

### Step 4: Enable Analytics in App

1. Open app → **Settings** → **Security** → **Analytics & Crash Reporting**
2. Toggle **Usage Analytics** ON
3. Toggle **Crash Reporting** ON (optional)
4. Perform some actions in the app
5. Verify events appear in PostHog dashboard

## Verification Checklist

- [ ] PostHog account created
- [ ] API key configured in environment
- [ ] App builds without errors
- [ ] Analytics settings visible in app
- [ ] Events appear in PostHog dashboard
- [ ] Consent flow shows on first launch
- [ ] Toggle works to enable/disable tracking

## Testing Events

### Test Onboarding Flow
1. Delete app and reinstall (or reset simulator)
2. Launch app
3. Complete onboarding
4. Check PostHog for:
   - `onboarding_started`
   - `onboarding_completed`
   - `privacy_mode_selected`

### Test Statement Upload
1. Go to **Upload Statement**
2. Select a document or take photo
3. Wait for processing
4. Check PostHog for:
   - `statement_upload_started`
   - `ocr_processing_completed`
   - `statement_upload_completed`

### Test Budget Creation
1. Go to **Budget** tab
2. Create new budget
3. Select a template
4. Save budget
5. Check PostHog for:
   - `budget_template_selected`
   - `budget_created`

### Test Premium Features
1. Try to access premium feature
2. View paywall
3. Check PostHog for:
   - `paywall_viewed`
   - `premium_feature_accessed`

## PostHog Dashboard Setup

### Recommended Dashboards

#### 1. User Engagement
- Daily Active Users
- Session Duration
- Screen Views by Type
- Feature Usage Frequency

#### 2. Conversion Funnel
- Onboarding Completion Rate
- Statement Upload Success Rate
- Budget Creation Rate
- Premium Conversion Rate

#### 3. Quality Metrics
- Error Rate by Type
- OCR Confidence Distribution
- Upload Failure Reasons
- Crash Rate

#### 4. Feature Adoption
- Feature Discovery Rate
- Time to First Upload
- Time to First Budget
- Premium Feature Usage

### Creating Insights

**Example: Onboarding Completion Rate**
1. Go to **Insights** → **New Insight**
2. Select **Funnel**
3. Add steps:
   - `onboarding_started`
   - `onboarding_completed`
4. Save as "Onboarding Completion"

**Example: Upload Success Rate**
1. Create new Funnel
2. Add steps:
   - `statement_upload_started`
   - `statement_upload_completed`
3. Add breakdown by `file_type`
4. Save as "Upload Success by Type"

## Privacy Configuration

### App Store Privacy Nutrition Label

When submitting to App Store, declare:

**Data Used to Track You**: None (if analytics is opt-in)

**Data Linked to You**: None

**Data Not Linked to You**:
- Usage Data (if analytics enabled)
  - Product Interaction
  - Crash Data
  - Performance Data

### Privacy Policy Updates

Add to your privacy policy:

```
Analytics and Crash Reporting

ClariFi uses PostHog for optional analytics and crash reporting. 
This is completely opt-in and disabled by default.

When enabled, we collect:
- App usage patterns (which features you use)
- Technical errors and crashes
- Device information (model, OS version)
- Session duration

We DO NOT collect:
- Financial data (transactions, amounts, merchants)
- Personal information (names, emails, addresses)
- Location data
- Statement file contents

You can disable analytics at any time in Settings.
```

## Troubleshooting

### Events Not Appearing

**Check API Key**
```swift
// Add temporary logging in AnalyticsService.swift
print("PostHog API Key: \(apiKey.prefix(10))...")
```

**Verify Network**
- Check device/simulator has internet
- Check PostHog status page
- Try different network

**Check Console Logs**
Look for:
- `✅ PostHog Analytics initialized`
- `✅ PostHog event sent successfully`
- `❌ PostHog event failed: ...`

### Analytics Not Initializing

**Check Environment Variables**
```swift
// Add to ClariFi_iOSApp.swift init()
print("POSTHOG_API_KEY: \(ProcessInfo.processInfo.environment["POSTHOG_API_KEY"] ?? "not set")")
```

**Verify @AppStorage**
```swift
// Check analytics_enabled value
@AppStorage("analytics_enabled") var analyticsEnabled = false
print("Analytics enabled: \(analyticsEnabled)")
```

### Consent Not Showing

**Reset Consent Flag**
```swift
// In AnalyticsSettingsView or debug menu
@AppStorage("analytics_consent_shown") private var consentShown = false
// Set to false to show again
```

**Check View Hierarchy**
- Ensure AnalyticsSettingsView is accessible
- Verify navigation path is correct
- Check sheet presentation logic

## Advanced Configuration

### Custom Event Properties

Add app-specific properties to all events:

```swift
// In AnalyticsService.swift sendEvent()
var allProperties = userProperties
allProperties["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
allProperties["build_number"] = Bundle.main.infoDictionary?["CFBundleVersion"]
allProperties["device_model"] = UIDevice.current.model
allProperties["os_version"] = UIDevice.current.systemVersion
```

### Session Replay (Optional)

PostHog supports session replay. To enable:

1. Add to PostHog project settings
2. Update privacy policy
3. Add explicit user consent
4. Consider privacy implications

**Note**: Session replay may capture sensitive financial data. Use with extreme caution or disable entirely for ClariFi.

### Feature Flags

Use PostHog feature flags for A/B testing:

```swift
// Check feature flag
if PostHog.isFeatureEnabled("new_budget_ui") {
    // Show new UI
} else {
    // Show old UI
}
```

### Cohort Analysis

Create user cohorts in PostHog:
- New users (first session < 7 days ago)
- Active users (sessions > 10)
- Premium users (subscription_completed event)
- Power users (budget_created > 3)

## Monitoring Best Practices

### Key Metrics to Watch

**Daily**
- Crash rate
- Error rate
- Upload success rate

**Weekly**
- Active users
- Feature adoption
- Onboarding completion

**Monthly**
- Retention rates
- Premium conversion
- Feature usage trends

### Alert Setup

Create alerts in PostHog for:
- Crash rate > 1%
- Upload failure rate > 10%
- Onboarding drop-off > 50%
- Error spike (2x normal)

### Data Retention

PostHog free tier:
- 1 million events/month
- 1 year data retention

Consider:
- Sampling for high-volume events
- Archiving old data
- Upgrading plan if needed

## Support Resources

### PostHog Documentation
- [Getting Started](https://posthog.com/docs/getting-started)
- [Event Tracking](https://posthog.com/docs/integrate/client/ios)
- [Privacy Controls](https://posthog.com/docs/privacy)

### ClariFi Analytics
- See `ANALYTICS_IMPLEMENTATION.md` for technical details
- Check `Services/AnalyticsService.swift` for implementation
- Review `Views/AnalyticsSettingsView.swift` for UI

### Getting Help
- PostHog Community: [posthog.com/questions](https://posthog.com/questions)
- PostHog Slack: [posthog.com/slack](https://posthog.com/slack)
- ClariFi Issues: Create GitHub issue with `analytics` label

## Next Steps

1. ✅ Complete setup steps above
2. ✅ Test event tracking
3. ✅ Create PostHog dashboards
4. ✅ Set up alerts
5. ✅ Update privacy policy
6. ✅ Submit to App Store with correct privacy labels
7. ✅ Monitor metrics regularly

---

**Setup Time**: ~5 minutes
**Testing Time**: ~10 minutes
**Dashboard Setup**: ~15 minutes
**Total**: ~30 minutes

**Status**: Ready for production ✅
