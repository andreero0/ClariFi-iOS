# ClariFi iOS Authentication Setup Guide

**Status:** Files created and moved to correct locations
**Next Steps:** Add to Xcode project + Install Supabase package + Configure credentials

---

## Quick Start (15 minutes)

### Step 1: Add Files to Xcode Project (5 minutes)

The authentication files have been created in the correct locations, but need to be added to the Xcode project:

1. Open `ClariFi iOS.xcodeproj` in Xcode
2. Add the following folders to the project (Right-click project → Add Files to "ClariFi iOS"):

#### Files to Add:

**Security:**
- `ClariFi iOS/Utilities/Security/KeychainHelper.swift`

**Authentication Services:**
- `ClariFi iOS/Services/Authentication/AuthenticationServiceProtocol.swift`
- `ClariFi iOS/Services/Authentication/AuthenticationService.swift`
- `ClariFi iOS/Services/Authentication/SessionManager.swift`

**ViewModels:**
- `ClariFi iOS/ViewModels/Authentication/RegistrationViewModel.swift`
- `ClariFi iOS/ViewModels/Authentication/LoginViewModel.swift`

**Views:**
- `ClariFi iOS/Views/Authentication/WelcomeView.swift`
- `ClariFi iOS/Views/Authentication/RegistrationView.swift`
- `ClariFi iOS/Views/Authentication/LoginView.swift`
- `ClariFi iOS/Views/Authentication/PasswordStrengthView.swift`

**Configuration:**
- `ClariFi iOS/Configuration/SupabaseConfiguration.swift`

**IMPORTANT:** When adding files:
- ✅ Check "Copy items if needed"
- ✅ Make sure "ClariFi iOS" target is selected
- ✅ Create groups (not folder references)

---

### Step 2: Add Supabase Swift Package (3 minutes)

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter package URL:
   ```
   https://github.com/supabase/supabase-swift.git
   ```
3. Select version: **"Up to Next Major Version"** (2.0.0)
4. Click **Add Package**
5. Select **Supabase** library for "ClariFi iOS" target
6. Click **Add Package**

**Packages to add:**
- ✅ Supabase

---

### Step 3: Create Supabase Project (5 minutes)

1. Go to https://supabase.com
2. Click "Start your project" or "New Project"
3. Sign in with GitHub (or create account)
4. Create new organization (if first time)
5. Create new project:
   - **Project Name:** ClariFi (or your choice)
   - **Database Password:** Generate strong password (save it!)
   - **Region:** Choose closest to your users
   - **Pricing Plan:** Free tier is fine for development
6. Wait ~2 minutes for project to initialize

---

### Step 4: Configure Supabase Database (2 minutes)

1. Once project is ready, go to **SQL Editor** (left sidebar)
2. Click **New Query**
3. Paste the following SQL:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create user_profiles table
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT,
    first_name TEXT,
    last_name TEXT,
    phone_number TEXT,
    profile_image_url TEXT,
    preferred_currency TEXT DEFAULT 'USD',
    timezone TEXT,
    locale TEXT,
    biometric_enabled BOOLEAN DEFAULT false,
    processing_mode TEXT DEFAULT 'on-device',
    subscription_tier TEXT DEFAULT 'free',
    subscription_expires_at TIMESTAMPTZ,
    is_email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own profile"
    ON user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON user_profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

4. Click **Run** or press Cmd+Enter
5. Verify: You should see "Success. No rows returned"

---

### Step 5: Get Supabase Credentials

1. In Supabase dashboard, go to **Project Settings** (gear icon, bottom left)
2. Click **API** in left sidebar
3. Copy the following values:

   - **Project URL** (looks like: `https://xxxyyyzz.supabase.co`)
   - **anon public** key (the `anon` `public` key under "Project API keys")

---

### Step 6: Configure App with Supabase Credentials

**Option A: Using Info.plist (Recommended for Production)**

1. Open `ClariFi iOS/Info.plist` in Xcode
2. Add two new rows:
   - Key: `SUPABASE_URL`, Type: String, Value: Your project URL
   - Key: `SUPABASE_ANON_KEY`, Type: String, Value: Your anon key

**Option B: Using Environment Variables (Good for Development)**

1. In Xcode, select your scheme (top bar, next to device selector)
2. Click **Edit Scheme** → **Run** → **Arguments**
3. Add two Environment Variables:
   - Name: `SUPABASE_URL`, Value: Your project URL
   - Name: `SUPABASE_ANON_KEY`, Value: Your anon key

**⚠️ Security Note:** Never commit these credentials to git!
- If using Info.plist: Add `Info.plist` to `.gitignore` or use a separate config file
- If using environment variables: They're automatically not committed

---

### Step 7: Build and Test (5 minutes)

1. Clean build folder: **Product → Clean Build Folder** (Cmd+Shift+K)
2. Build project: **Product → Build** (Cmd+B)
3. If build succeeds, run on simulator: **Product → Run** (Cmd+R)

**Expected Flow:**
```
App Launches
    ↓
Loading screen (checking session)
    ↓
Welcome screen (no user signed in)
    ↓
Click "Get Started"
    ↓
Registration form appears
    ↓
Fill in: Display name, email, password
    ↓
Click "Create Account"
    ↓
Success! → Onboarding flow
```

---

## Troubleshooting

### Build Error: "Cannot find 'SupabaseClient' in scope"

**Cause:** Supabase package not added

**Fix:**
1. Go to Project Settings → Package Dependencies
2. Add https://github.com/supabase/supabase-swift.git
3. Clean build folder and rebuild

---

### Build Error: "Cannot find 'SessionManager' in scope"

**Cause:** Authentication files not added to Xcode project target

**Fix:**
1. In Xcode, select each auth file
2. Open File Inspector (right sidebar)
3. Ensure "ClariFi iOS" is checked under Target Membership
4. Clean and rebuild

---

### Runtime Error: "Supabase configuration not found"

**Cause:** Credentials not configured

**Fix:**
1. Add SUPABASE_URL and SUPABASE_ANON_KEY to Info.plist or environment variables
2. Check console for exact error message with instructions

---

### Registration Fails: "Email already in use"

**Cause:** Email was previously registered

**Fix:**
1. Go to Supabase Dashboard → Authentication → Users
2. Delete the test user
3. Or use a different email address

---

### Login Fails: "Invalid credentials"

**Cause:** Password doesn't meet requirements OR email/password mismatch

**Fix:**
1. Ensure password has:
   - At least 8 characters
   - 1 uppercase letter
   - 1 lowercase letter
   - 1 number
   - 1 special character
2. Check for typos in email/password

---

## Optional Configuration

### Email Templates

Customize the emails sent by Supabase:

1. Go to **Authentication → Email Templates**
2. Customize templates:
   - Confirm signup
   - Reset password
   - Magic link

### Auth Settings

Configure authentication options:

1. Go to **Authentication → Providers**
2. Enable/disable providers:
   - Email (enabled by default)
   - Google, Apple, GitHub, etc. (optional)

3. Go to **Authentication → Settings**
4. Configure:
   - **Site URL:** `clarifi://` (for deep linking)
   - **Redirect URLs:** Add `clarifi://auth/callback`
   - **Email auth:** Keep enabled
   - **Confirm email:** Toggle based on preference

---

## Testing Checklist

Once setup is complete, test the following:

### Registration Flow
- [ ] Can access registration screen
- [ ] Email validation shows error for invalid emails
- [ ] Password strength indicator updates in real-time
- [ ] Weak passwords are rejected
- [ ] Terms checkbox must be checked to proceed
- [ ] Registration creates user in Supabase
- [ ] User is redirected to onboarding after registration

### Login Flow
- [ ] Can access login screen
- [ ] Can sign in with registered credentials
- [ ] Invalid credentials show error
- [ ] "Remember me" persists email
- [ ] User is redirected to main app after login

### Session Management
- [ ] Session persists after app restart
- [ ] Can sign out successfully
- [ ] Biometric auth works (if enabled)
- [ ] App requires login after sign out

### Password Reset
- [ ] Can trigger password reset email
- [ ] Receives reset email (check spam folder)
- [ ] Can click link in email (if deep linking configured)

---

## What's Been Implemented

✅ **Core Data Schema**
- User entity with relationships to all existing entities
- Data isolation per user
- Cascade delete support

✅ **Security Infrastructure**
- KeychainHelper for secure token storage
- SessionManager with automatic token refresh
- SupabaseConfiguration for flexible config

✅ **Authentication Service**
- Email/password registration
- Email/password login
- Magic link (passwordless) support
- Password strength validation
- Password reset
- Email verification
- Profile management
- Account deletion

✅ **User Interface**
- WelcomeView with branding
- RegistrationView with validation
- LoginView with multiple auth methods
- PasswordStrengthView visual indicator
- Integrated into ContentView app flow

✅ **Dependency Injection**
- All services registered in DI container
- Production and preview container support

---

## What's Next (Optional Enhancements)

### Phase 1: User Profile Management
- ProfileView to display user info
- EditProfileView to update profile
- Account settings screen
- Profile image upload

### Phase 2: Cloud Backup
- Sync transactions to Supabase
- Sync accounts, budgets, statements
- Conflict resolution
- Background sync

### Phase 3: Multi-Device Support
- Same user can access from multiple devices
- Real-time sync across devices
- Device management UI

### Phase 4: Advanced Auth
- Social sign-in (Apple, Google)
- Two-factor authentication
- Biometric enrollment during registration
- Session management (view/revoke devices)

---

## File Locations

All authentication files are in:
```
ClariFi iOS/
├── Utilities/Security/
│   └── KeychainHelper.swift
├── Services/Authentication/
│   ├── AuthenticationServiceProtocol.swift
│   ├── AuthenticationService.swift
│   └── SessionManager.swift
├── ViewModels/Authentication/
│   ├── RegistrationViewModel.swift
│   └── LoginViewModel.swift
├── Views/Authentication/
│   ├── WelcomeView.swift
│   ├── RegistrationView.swift
│   ├── LoginView.swift
│   └── PasswordStrengthView.swift
├── Configuration/
│   └── SupabaseConfiguration.swift
├── Core/DependencyInjection/
│   └── AppDIContainer+Registration.swift (MODIFIED)
└── ContentView.swift (MODIFIED)
```

---

## Support & Documentation

- **Implementation Summary:** `USER_AUTHENTICATION_IMPLEMENTATION_SUMMARY.md`
- **Architecture Design:** `USER_AUTHENTICATION_ARCHITECTURE.md`
- **Analysis Report:** `USER_PROFILE_ANALYSIS_REPORT.md`
- **Supabase Docs:** https://supabase.com/docs
- **Supabase Swift:** https://github.com/supabase/supabase-swift

---

## Contact

**Implementation Date:** 2025-11-05
**Implementation by:** Claude (Anthropic)
**Framework:** SwiftUI + Supabase
**iOS Target:** iOS 15.0+

**Need Help?**
1. Check troubleshooting section above
2. Review implementation summary document
3. Check Supabase logs in dashboard
4. Verify all files are added to Xcode target

---

**You're almost there! Just add the files to Xcode and install the Supabase package. 🚀**
