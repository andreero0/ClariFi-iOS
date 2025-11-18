-- ============================================================================
-- ClariFi iOS - Supabase Database Setup Script
-- ============================================================================
-- This script sets up the required database schema for ClariFi iOS user authentication
-- Run this script in your Supabase SQL Editor (Dashboard → SQL Editor → New Query)
-- ============================================================================

-- Enable UUID extension for generating unique identifiers
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- Create user_profiles table
-- ============================================================================
-- This table stores additional user profile information that complements
-- Supabase Auth's built-in user table (auth.users)
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_profiles (
    -- Primary key linked to auth.users
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

    -- User Identity
    display_name TEXT,
    first_name TEXT,
    last_name TEXT,
    phone_number TEXT,
    profile_image_url TEXT,

    -- User Preferences
    preferred_currency TEXT DEFAULT 'USD',
    timezone TEXT,
    locale TEXT,

    -- Security Settings
    biometric_enabled BOOLEAN DEFAULT false,

    -- Privacy & Processing
    processing_mode TEXT DEFAULT 'on-device' CHECK (processing_mode IN ('on-device', 'cloud')),

    -- Subscription
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'enterprise')),
    subscription_expires_at TIMESTAMPTZ,

    -- Verification Status
    is_email_verified BOOLEAN DEFAULT false,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment to table
COMMENT ON TABLE user_profiles IS 'Extended user profile information for ClariFi iOS users';

-- Add comments to columns
COMMENT ON COLUMN user_profiles.id IS 'UUID from auth.users, links to Supabase Auth user';
COMMENT ON COLUMN user_profiles.display_name IS 'User friendly display name shown in app';
COMMENT ON COLUMN user_profiles.preferred_currency IS 'User preferred currency code (ISO 4217)';
COMMENT ON COLUMN user_profiles.processing_mode IS 'Data processing preference: on-device (default) or cloud';
COMMENT ON COLUMN user_profiles.subscription_tier IS 'User subscription level';


-- Create indexes for performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_user_profiles_email_verified
    ON user_profiles(is_email_verified);

CREATE INDEX IF NOT EXISTS idx_user_profiles_subscription_tier
    ON user_profiles(subscription_tier);

CREATE INDEX IF NOT EXISTS idx_user_profiles_created_at
    ON user_profiles(created_at);


-- Enable Row Level Security (RLS)
-- ============================================================================
-- RLS ensures users can only access their own data
-- ============================================================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;


-- Drop existing policies if they exist (for idempotency)
-- ============================================================================
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON user_profiles;


-- Create RLS Policies
-- ============================================================================

-- SELECT Policy: Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON user_profiles
    FOR SELECT
    USING (auth.uid() = id);

-- UPDATE Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON user_profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- INSERT Policy: Users can insert their own profile during registration
CREATE POLICY "Users can insert own profile"
    ON user_profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- DELETE Policy: Users can delete their own profile
CREATE POLICY "Users can delete own profile"
    ON user_profiles
    FOR DELETE
    USING (auth.uid() = id);


-- Create automatic timestamp update function
-- ============================================================================
-- This function automatically updates the updated_at column when a row is modified
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add comment to function
COMMENT ON FUNCTION update_updated_at_column() IS 'Automatically updates updated_at timestamp on row modification';


-- Create trigger for automatic timestamp updates
-- ============================================================================
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- Create function to automatically create user profile on signup
-- ============================================================================
-- This function is triggered when a new user signs up via Supabase Auth
-- It automatically creates a corresponding user_profiles entry
-- ============================================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, display_name, is_email_verified)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'display_name', SPLIT_PART(NEW.email, '@', 1)),
        NEW.email_confirmed_at IS NOT NULL
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment to function
COMMENT ON FUNCTION handle_new_user() IS 'Automatically creates user_profiles entry when a new user signs up';


-- Create trigger for automatic profile creation
-- ============================================================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();


-- Grant necessary permissions
-- ============================================================================
-- Grant authenticated users permission to access user_profiles table
-- (RLS policies will further restrict access to own data only)
-- ============================================================================
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.user_profiles TO authenticated;


-- Verification Query
-- ============================================================================
-- Run this query to verify the setup was successful
-- You should see the user_profiles table with 0 rows
-- ============================================================================
-- SELECT
--     table_name,
--     column_name,
--     data_type
-- FROM information_schema.columns
-- WHERE table_name = 'user_profiles'
-- ORDER BY ordinal_position;

-- SELECT * FROM user_profiles;


-- ============================================================================
-- Setup Complete!
-- ============================================================================
-- ✅ user_profiles table created
-- ✅ Row Level Security (RLS) enabled
-- ✅ RLS policies configured for secure data access
-- ✅ Indexes created for performance
-- ✅ Automatic timestamp updates configured
-- ✅ Automatic profile creation on signup configured
-- ✅ Permissions granted
--
-- Next Steps:
-- 1. Test user registration in your iOS app
-- 2. Verify user_profiles entry is created automatically
-- 3. Check that RLS policies are working (users can only see their own data)
-- 4. Monitor the Auth → Users section in Supabase Dashboard
--
-- Troubleshooting:
-- - If you get "permission denied" errors, check that RLS policies are enabled
-- - If profile is not created automatically, check trigger logs
-- - For any issues, check Supabase Dashboard → Database → Logs
-- ============================================================================
