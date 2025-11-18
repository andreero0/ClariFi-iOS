# ClariFi Troubleshooting Guide

## Common Issues and Solutions

This guide helps you resolve common issues you might encounter while using ClariFi.

---

## Transaction Editing Issues

### Issue: Cannot Save Transaction Edits

**Symptoms**:
- Save button is grayed out/disabled
- Error messages appear under fields
- Changes don't persist after tapping Save

**Possible Causes & Solutions**:

#### 1. Validation Errors

**Check for these common validation issues**:

- **Empty merchant name**
  - Error: "Merchant name is required"
  - Solution: Enter a merchant name (at least one character)

- **Zero or negative amount**
  - Error: "Amount must be greater than 0"
  - Solution: Enter a positive amount

- **No category selected**
  - Error: "Please select a category"
  - Solution: Tap the category field and choose a category

#### 2. Network/Connectivity Issues

**Symptoms**: Error alert appears after tapping Save

**Solutions**:
1. Check your internet connection
2. Try again when connection is restored
3. Tap "Retry" in the error alert
4. If offline, wait until you're back online

#### 3. Data Corruption

**Symptoms**: Transaction appears but won't save changes

**Solutions**:
1. Force quit the app (swipe up from bottom)
2. Reopen the app
3. Try editing again
4. If problem persists, contact support

---

## Navigation Issues

### Issue: "See All" Button Doesn't Work

**Symptoms**:
- Tapping "See All" does nothing
- Wrong tab opens
- App freezes when tapping button

**Solutions**:

1. **Force quit and restart the app**
   - Swipe up from bottom of screen
   - Swipe up on ClariFi to close it
   - Reopen from home screen

2. **Update to latest version**
   - Open App Store
   - Go to Updates
   - Update ClariFi if available

3. **Check for iOS updates**
   - Settings → General → Software Update
   - Install any available updates

### Issue: Tab Bar Not Responding

**Symptoms**:
- Cannot switch between tabs
- Taps on tab bar don't register
- Wrong tab highlights

**Solutions**:

1. **Restart the app**
2. **Check for gestures interfering**
   - Disable any accessibility gestures temporarily
   - Test tab switching again
3. **Reinstall the app** (last resort)
   - Delete ClariFi
   - Reinstall from App Store
   - Your data should sync back from iCloud

---

## Premium Feature Issues

### Issue: Premium Features Not Available After Purchase

**Symptoms**:
- Still seeing "Upgrade to Premium" prompts
- Premium features are locked
- Subscription shows as active in App Store

**Solutions**:

#### 1. Restore Purchases

1. Open ClariFi
2. Go to Settings
3. Tap "Restore Purchases"
4. Wait for confirmation

#### 2. Verify Subscription Status

1. Open Settings app
2. Tap your name at top
3. Tap "Subscriptions"
4. Find ClariFi
5. Verify subscription is active

#### 3. Check Apple ID

- Ensure you're signed in with the same Apple ID used for purchase
- Settings → [Your Name] → View Apple ID

#### 4. Restart App

1. Force quit ClariFi
2. Reopen the app
3. Premium status should update

#### 5. Wait for Sync

- Sometimes takes a few minutes for subscription to sync
- Wait 5-10 minutes and check again

### Issue: Cannot Manage Subscription

**Symptoms**:
- "Manage Subscription" button doesn't work
- App Store doesn't open
- Can't find subscription in App Store

**Solutions**:

1. **Open App Store directly**
   - Open App Store app
   - Tap your profile icon (top right)
   - Tap "Subscriptions"
   - Find ClariFi

2. **Use Settings app**
   - Settings → [Your Name] → Subscriptions
   - Find ClariFi
   - Manage from there

3. **Check restrictions**
   - Settings → Screen Time → Content & Privacy Restrictions
   - Ensure "Installing Apps" is allowed

---

## Empty State Issues

### Issue: Empty State Shows When Data Exists

**Symptoms**:
- "No Transactions" message appears but you have transactions
- Empty state doesn't go away after adding data
- Data appears in one view but not another

**Solutions**:

#### 1. Refresh the View

- Pull down on the screen to refresh
- Wait for loading indicator to complete

#### 2. Check Filters

- Ensure no filters are hiding your data
- Reset any date range filters
- Clear search queries

#### 3. Verify Data Sync

1. Check internet connection
2. Wait a few moments for iCloud sync
3. Force quit and reopen app

#### 4. Check Core Data

- Data might not have saved properly
- Try adding a new transaction
- If new transactions appear, old data may be corrupted

---

## Loading and Performance Issues

### Issue: App Stuck on Loading Screen

**Symptoms**:
- Loading indicator spins indefinitely
- App doesn't respond
- Cannot interact with UI

**Solutions**:

#### 1. Wait Patiently

- Large datasets may take time to load
- Wait up to 30 seconds

#### 2. Check Internet Connection

- Ensure you have stable connection
- Try switching between WiFi and cellular

#### 3. Force Quit

1. Swipe up from bottom
2. Close ClariFi
3. Reopen app

#### 4. Clear Cache (Advanced)

1. Delete and reinstall app
2. Data will sync back from iCloud
3. Cache will be cleared

### Issue: App is Slow or Laggy

**Symptoms**:
- Scrolling is choppy
- Buttons respond slowly
- Animations stutter

**Solutions**:

#### 1. Close Other Apps

- Double-tap home button (or swipe up)
- Close unused apps
- Free up memory

#### 2. Restart Device

- Hold power button
- Slide to power off
- Turn back on after 30 seconds

#### 3. Check Storage

- Settings → General → iPhone Storage
- Ensure you have at least 1GB free
- Delete unused apps/photos if needed

#### 4. Update iOS

- Settings → General → Software Update
- Install any available updates

#### 5. Reduce Data

- Archive old transactions
- Delete unnecessary data
- Export and remove old records

---

## Accessibility Issues

### Issue: VoiceOver Not Working Properly

**Symptoms**:
- Elements not announced
- Incorrect labels
- Cannot navigate with VoiceOver

**Solutions**:

1. **Verify VoiceOver is enabled**
   - Settings → Accessibility → VoiceOver
   - Toggle on

2. **Restart VoiceOver**
   - Triple-click side button to toggle off/on

3. **Update app**
   - Ensure you have latest version
   - Accessibility improvements in each update

4. **Report specific issues**
   - Note which screen/element has issues
   - Contact support with details

### Issue: Text Too Small or Too Large

**Symptoms**:
- Cannot read text
- Text is cut off
- Layout is broken

**Solutions**:

1. **Adjust text size**
   - Settings → Display & Brightness → Text Size
   - Adjust slider to comfortable size

2. **Check Dynamic Type**
   - Ensure Dynamic Type is enabled
   - ClariFi should respect system text size

3. **Report layout issues**
   - If text is cut off at certain sizes
   - Contact support with screenshot

---

## Data and Sync Issues

### Issue: Changes Not Syncing Across Devices

**Symptoms**:
- Edit on iPhone doesn't appear on iPad
- New transactions missing on other device
- Data out of sync

**Solutions**:

#### 1. Check iCloud Settings

1. Settings → [Your Name] → iCloud
2. Ensure iCloud Drive is on
3. Scroll down to ClariFi
4. Ensure toggle is on

#### 2. Check Internet Connection

- Both devices need internet
- Wait for sync to complete
- Can take a few minutes

#### 3. Force Sync

1. Pull down to refresh on both devices
2. Force quit and reopen app
3. Wait 5 minutes for sync

#### 4. Check iCloud Storage

- Settings → [Your Name] → iCloud
- Ensure you have available storage
- Upgrade if needed

### Issue: Data Lost After Update

**Symptoms**:
- Transactions disappeared after app update
- Settings reset
- Accounts missing

**Solutions**:

#### 1. Check iCloud Backup

1. Settings → [Your Name] → iCloud → Manage Storage
2. Find ClariFi backup
3. Restore from backup if available

#### 2. Wait for Sync

- Data might still be syncing
- Wait 10-15 minutes
- Pull down to refresh

#### 3. Contact Support

- If data is truly lost
- Provide details about when it happened
- We may be able to help recover

---

## Error Messages

### "Failed to Save Transaction"

**Cause**: Network error or database issue

**Solutions**:
1. Check internet connection
2. Tap "Retry" in error alert
3. Force quit and try again
4. Contact support if persists

### "Transaction Not Found"

**Cause**: Transaction was deleted or data corruption

**Solutions**:
1. Refresh the transaction list
2. Check if transaction appears elsewhere
3. Restore from backup if needed

### "Subscription Verification Failed"

**Cause**: Cannot verify premium subscription

**Solutions**:
1. Check internet connection
2. Verify subscription in App Store
3. Tap "Restore Purchases"
4. Wait a few minutes and try again

### "Unable to Load Data"

**Cause**: Core Data or iCloud sync issue

**Solutions**:
1. Check internet connection
2. Restart the app
3. Check iCloud settings
4. Contact support if persists

---

## When to Contact Support

Contact our support team if:

- Issue persists after trying all solutions
- You experience data loss
- App crashes repeatedly
- You find a bug or unexpected behavior
- You need help with premium features

### How to Contact Support

1. **Email**: support@clarifi.app
2. **In-App**: Settings → Help & Support
3. **Premium Support**: Priority response for subscribers

### Information to Include

When contacting support, please provide:

- iOS version (Settings → General → About)
- ClariFi version (Settings → About ClariFi)
- Device model (iPhone 12, iPad Pro, etc.)
- Detailed description of issue
- Steps to reproduce the problem
- Screenshots if applicable
- Whether you're a premium subscriber

---

## Preventing Issues

### Best Practices

1. **Keep app updated**
   - Enable automatic updates in App Store
   - Check for updates regularly

2. **Keep iOS updated**
   - Install iOS updates when available
   - Backup before major updates

3. **Maintain good internet connection**
   - Use WiFi when possible
   - Ensure stable connection for syncing

4. **Regular backups**
   - Enable iCloud backup
   - Verify backups are working

5. **Don't force quit unnecessarily**
   - Let app complete operations
   - Only force quit when truly frozen

6. **Monitor storage**
   - Keep at least 1GB free
   - Archive old data periodically

---

## Known Issues

### Current Known Issues

Check our website for current known issues and workarounds:
- [ClariFi Known Issues](https://clarifi.app/known-issues)

### Reporting New Issues

Help us improve ClariFi:
1. Check if issue is already known
2. Try troubleshooting steps first
3. Report new issues to support
4. Include detailed information

---

**Last Updated**: October 2025  
**Version**: 1.0

For the latest troubleshooting information, visit: https://clarifi.app/support
