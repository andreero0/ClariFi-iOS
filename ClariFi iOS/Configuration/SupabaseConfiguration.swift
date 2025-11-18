//
//  SupabaseConfiguration.swift
//  ClariFi iOS
//
//  Created by Claude on 2025-11-05.
//  Configuration for Supabase connection
//

import Foundation

/// Configuration for Supabase backend services
struct SupabaseConfiguration {

    // MARK: - Properties

    /// Supabase project URL
    let url: URL

    /// Supabase anonymous API key
    let anonKey: String

    // MARK: - Initialization

    /// Initialize configuration from environment variables or Info.plist
    init() {
        // Try to load from environment variables first (for development)
        if let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"],
           let url = URL(string: urlString),
           let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            self.url = url
            self.anonKey = anonKey
        }
        // Fallback to Info.plist configuration
        else if let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
                let url = URL(string: urlString),
                let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String {
            self.url = url
            self.anonKey = anonKey
        }
        // Default placeholder values (should be replaced with actual values)
        else {
            print("⚠️ WARNING: Supabase configuration not found in environment or Info.plist")
            print("⚠️ Please set SUPABASE_URL and SUPABASE_ANON_KEY in your environment or Info.plist")
            self.url = URL(string: "https://your-project.supabase.co")!
            self.anonKey = "your-anon-key-here"
        }
    }

    /// Initialize with explicit values (for testing)
    init(url: URL, anonKey: String) {
        self.url = url
        self.anonKey = anonKey
    }

    // MARK: - Validation

    /// Check if configuration is valid
    var isValid: Bool {
        return url.absoluteString != "https://your-project.supabase.co" &&
               anonKey != "your-anon-key-here"
    }

    /// Get validation error message if configuration is invalid
    var validationError: String? {
        guard isValid else {
            return """
            Supabase configuration is not set up.

            To configure Supabase:
            1. Create a Supabase project at https://supabase.com
            2. Get your project URL and anon key from project settings
            3. Add to Info.plist:
               - SUPABASE_URL: Your project URL
               - SUPABASE_ANON_KEY: Your anonymous key

            Or set environment variables:
               - SUPABASE_URL
               - SUPABASE_ANON_KEY
            """
        }
        return nil
    }
}

// MARK: - Shared Instance

extension SupabaseConfiguration {

    /// Shared configuration instance
    static let shared = SupabaseConfiguration()
}
