#!/usr/bin/env python3
"""
Script to remove test files from the main app target in Xcode project.
This fixes the "No such module XCTest" and @testable import warnings.
"""

import os
import re
import shutil
from pathlib import Path

def backup_project_file():
    """Create a backup of the project.pbxproj file"""
    project_file = "../ClariFi iOS.xcodeproj/project.pbxproj"
    backup_file = "../ClariFi iOS.xcodeproj/project.pbxproj.backup"
    
    if os.path.exists(project_file):
        shutil.copy2(project_file, backup_file)
        print(f"✅ Created backup: {backup_file}")
        return True
    else:
        print(f"❌ Project file not found: {project_file}")
        return False

def read_project_file():
    """Read the project.pbxproj file"""
    project_file = "../ClariFi iOS.xcodeproj/project.pbxproj"
    try:
        with open(project_file, 'r', encoding='utf-8') as f:
            return f.read()
    except Exception as e:
        print(f"❌ Error reading project file: {e}")
        return None

def write_project_file(content):
    """Write the modified content back to project.pbxproj"""
    project_file = "../ClariFi iOS.xcodeproj/project.pbxproj"
    try:
        with open(project_file, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✅ Updated project file: {project_file}")
        return True
    except Exception as e:
        print(f"❌ Error writing project file: {e}")
        return False

def remove_test_files_from_main_target():
    """Remove test files from the main app target"""
    
    # List of test files that should NOT be in the main target
    test_files = [
        "ClariFi iOSTests/Integration/EndToEndFlowTests.swift",
        "ClariFi iOSTests/Concurrency/MainActorIsolationTests.swift", 
        "ClariFi iOSTests/Performance/PerformanceBenchmarks.swift",
        "ClariFi iOSTests/DependencyInjection/DIContainerTests.swift",
        "ClariFi iOSTests/Services/LLMCacheThreadSafetyTests.swift",
        "ClariFi iOSTests/Models/CurrencyFormatterTests.swift",
        "ClariFi iOSTests/Services/ParserConcurrencyTests.swift",
        "ClariFi iOSTests/Services/AnalyticsTests.swift",
        "ClariFi iOSTests/Repositories/RepositoryThreadSafetyTests.swift"
    ]
    
    print("🔧 Removing test files from main app target...")
    
    # Read the project file
    content = read_project_file()
    if not content:
        return False
    
    # Find the main app target section
    main_target_pattern = r'(ClariFi_iOS.*?=.*?\{.*?buildPhases.*?=.*?\(.*?)(.*?)(.*?files.*?=.*?\(.*?)(.*?)(.*?);.*?buildRules.*?=.*?\(.*?)(.*?)(.*?);.*?buildSettings.*?=.*?\{.*?)(.*?)(.*?\};.*?dependencies.*?=.*?\(.*?)(.*?)(.*?\};.*?\};)'
    
    # This is a complex regex, let's use a simpler approach
    # Find all file references and their target memberships
    
    modified = False
    
    for test_file in test_files:
        # Look for the file reference in the project
        file_ref_pattern = rf'(\s+)([A-F0-9]{{24}})\s*/\* {re.escape(test_file)} \*/.*?files = \(([^)]*)\);'
        
        match = re.search(file_ref_pattern, content, re.DOTALL)
        if match:
            indent = match.group(1)
            file_ref = match.group(2)
            files_section = match.group(3)
            
            print(f"📁 Found test file: {test_file}")
            
            # Remove this file from the main target's buildPhases
            # Look for the file reference in buildPhases
            build_phase_pattern = rf'(\s+)([A-F0-9]{{24}})\s*/\* {re.escape(test_file)} \*/ in Sources'
            
            if re.search(build_phase_pattern, content):
                # Remove the file from buildPhases
                content = re.sub(build_phase_pattern, '', content)
                print(f"   ✅ Removed from buildPhases")
                modified = True
            else:
                print(f"   ℹ️  Not found in buildPhases (may already be correct)")
    
    if modified:
        return write_project_file(content)
    else:
        print("ℹ️  No changes needed - test files may already be correctly configured")
        return True

def main():
    """Main function"""
    print("🔧 Xcode Test Target Membership Fix")
    print("===================================")
    
    # Check if we're in the right directory
    if not os.path.exists("../ClariFi iOS.xcodeproj/project.pbxproj"):
        print("❌ Please run this script from the ClariFi iOS directory")
        return False
    
    # Create backup
    if not backup_project_file():
        return False
    
    # Remove test files from main target
    if remove_test_files_from_main_target():
        print("\n✅ Test target membership fix completed!")
        print("📝 Next steps:")
        print("   1. Open Xcode project")
        print("   2. Clean Build Folder (Product > Clean Build Folder)")
        print("   3. Build project (Product > Build)")
        print("   4. Verify that XCTest errors are gone")
        return True
    else:
        print("\n❌ Failed to fix test target membership")
        return False

if __name__ == "__main__":
    main()
