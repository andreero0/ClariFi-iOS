# Where to Find the Currency Setting

## Quick Answer

The Currency setting is located in:

**Planning Tab → App Settings Section → Currency (First Option)**

## Step-by-Step Visual Guide

```
┌─────────────────────────────────────┐
│         ClariFi App                 │
│                                     │
│  Bottom Navigation:                 │
│  [Home] [Activity] [Planning] ←TAP  │
└─────────────────────────────────────┘
                ↓
┌─────────────────────────────────────┐
│         Planning                    │
├─────────────────────────────────────┤
│  Budget Management                  │
│  ┌─────────────────────────────┐   │
│  │ Current Budget              │   │
│  │ Create New Budget           │   │
│  └─────────────────────────────┘   │
│                                     │
│  Premium Features                   │
│  ┌─────────────────────────────┐   │
│  │ Premium Insights            │   │
│  │ Scenario Planning           │   │
│  │ Upgrade to Premium          │   │
│  └─────────────────────────────┘   │
│                                     │
│  App Settings                       │
│  ┌─────────────────────────────┐   │
│  │ 💰 Currency         USD ➤   │ ← TAP HERE!
│  │ 🔒 Privacy              ➤   │   │
│  │ 📊 Analytics            ➤   │   │
│  │ 🔐 Security             ➤   │   │
│  └─────────────────────────────┘   │
│                                     │
│  Support                            │
│  ┌─────────────────────────────┐   │
│  │ Help & Support              │   │
│  │ About                       │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Exact Location in Code

The Currency option is in `Views/PlanningView.swift` at **lines 169-184**:

```swift
NavigationLink(destination: CurrencySettingsView()) {
    HStack {
        Label("Currency", systemImage: "dollarsign.circle")
        Spacer()
        HStack(spacing: 4) {
            Text(CurrencyPreferenceManager.shared.preferredCurrency.rawValue)
                .foregroundColor(.secondary)
                .font(.subheadline)
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }
    .padding()
}
```

## What You'll See

When you tap on **Currency**, you'll see:

```
┌─────────────────────────────────────┐
│    ← Currency                       │
├─────────────────────────────────────┤
│  Current Selection                  │
│  Current Currency: USD              │
│  Example Amount: $1,234.56          │
├─────────────────────────────────────┤
│  🔍 Search currencies               │
├─────────────────────────────────────┤
│  Available Currencies               │
│                                     │
│  🇺🇸 USD - US Dollar                │
│     $100.00                    ✓    │
│                                     │
│  🇨🇦 CAD - Canadian Dollar          │
│     CA$100.00                       │
│                                     │
│  🇪🇺 EUR - Euro                     │
│     €100.00                         │
│                                     │
│  🇬🇧 GBP - British Pound            │
│     £100.00                         │
│                                     │
│  ... (11 more currencies)           │
└─────────────────────────────────────┘
```

## Files That Were Created

1. ✅ `Models/Currency.swift` - Currency model and managers
2. ✅ `Views/CurrencySettingsView.swift` - Currency selection UI
3. ✅ `Models/Transaction+Currency.swift` - Transaction currency support
4. ✅ `Core/Extensions/Decimal+Currency.swift` - Formatting helpers

## Files That Were Modified

1. ✅ `Views/PlanningView.swift` - Added Currency option (line 169)

## How to Test It's Working

1. **Build and run the app** in Xcode
2. **Navigate to Planning tab** (bottom navigation, third tab)
3. **Scroll to "App Settings" section**
4. **Look for "Currency"** - it should be the FIRST option
5. **You should see**: 💰 Currency with "USD" on the right
6. **Tap it** to open currency selection

## If You Don't See It

### Possible Reasons:

1. **App not rebuilt**: You need to build and run the app again
   - Press Cmd+R in Xcode to rebuild and run

2. **Simulator/Device cache**: Try cleaning build folder
   - In Xcode: Product → Clean Build Folder (Cmd+Shift+K)
   - Then rebuild: Product → Run (Cmd+R)

3. **File not included in target**: Check that files are in the target
   - Select `Models/Currency.swift` in Xcode
   - Check "Target Membership" in File Inspector
   - Ensure "ClariFi_iOS" is checked

## Verification Commands

Run these to verify files exist:

```bash
# Check if Currency model exists
ls -la Models/Currency.swift

# Check if CurrencySettingsView exists
ls -la Views/CurrencySettingsView.swift

# Check if PlanningView was modified
grep -n "CurrencySettingsView" Views/PlanningView.swift
```

Expected output:
```
Models/Currency.swift exists
Views/CurrencySettingsView.swift exists
Line 169: NavigationLink(destination: CurrencySettingsView()) {
```

## What the Currency Feature Does

Once you access it:

1. **Shows current currency** (e.g., USD)
2. **Shows example amount** in that currency
3. **Lists 15 currencies** with flags and symbols
4. **Search functionality** to find currencies quickly
5. **Tap to select** any currency
6. **Confirmation message** when changed
7. **Persists your choice** across app restarts

## Need More Help?

If you still can't see the Currency option:

1. Check that you're looking in the **Planning tab** (not Home or Activity)
2. Scroll down to the **"App Settings"** section
3. It should be the **first option** above Privacy
4. Make sure you've **rebuilt the app** after the changes

The code is definitely there (verified at line 169 of PlanningView.swift), so if you rebuild the app, you should see it!

---

**Status**: ✅ Code is in place and error-free  
**Location**: Planning → App Settings → Currency (first option)  
**Action Needed**: Rebuild and run the app to see it
