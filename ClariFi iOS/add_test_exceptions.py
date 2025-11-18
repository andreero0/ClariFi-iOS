#!/usr/bin/env python3
"""
Add all test files to the PBXFileSystemSynchronizedBuildFileExceptionSet
"""

import re
import os
import glob

project_file = '../ClariFi iOS.xcodeproj/project.pbxproj'

# Find all test files (they should be in test targets, not main target)
test_files = []

# Get all Swift files in test directories
for test_dir in ['ClariFi iOSTests', 'ClariFi iOSUITests']:
    test_dir_path = f'../{test_dir}'
    if os.path.exists(test_dir_path):
        for root, dirs, files in os.walk(test_dir_path):
            for file in files:
                if file.endswith('.swift'):
                    # Get relative path from workspace root
                    full_path = os.path.join(root, file)
                    rel_path = os.path.relpath(full_path, '..')
                    test_files.append(rel_path)

print(f"Found {len(test_files)} test files to exclude from main target")

# Read project file
with open(project_file, 'r') as f:
    content = f.read()

# Find the membershipExceptions section
pattern = r'(membershipExceptions = \(\s*)(.*?)(\s*\);)'
match = re.search(pattern, content, re.DOTALL)

if not match:
    print("Error: Could not find membershipExceptions section")
    exit(1)

prefix = match.group(1)
existing_exceptions = match.group(2)
suffix = match.group(3)

# Parse existing exceptions
existing_list = []
for line in existing_exceptions.strip().split('\n'):
    line = line.strip().rstrip(',')
    if line and not line.startswith('//'):
        # Remove quotes if present
        line = line.strip('"')
        existing_list.append(line)

print(f"Found {len(existing_list)} existing exceptions")

# Add new exceptions
all_exceptions = set(existing_list)
for test_file in test_files:
    all_exceptions.add(test_file)

# Sort for consistency
sorted_exceptions = sorted(all_exceptions)

# Format as Xcode expects
formatted_exceptions = []
for exc in sorted_exceptions:
    # Quote if it has spaces
    if ' ' in exc:
        formatted_exceptions.append(f'\t\t\t\t"{exc}",')
    else:
        formatted_exceptions.append(f'\t\t\t\t{exc},')

new_exceptions = '\n'.join(formatted_exceptions)

# Replace in content
new_section = f"{prefix}\n{new_exceptions}\n{suffix}"
new_content = content[:match.start()] + new_section + content[match.end():]

# Write back
with open(project_file, 'w') as f:
    f.write(new_content)

print(f"✅ Added {len(test_files)} test files to exceptions")
print(f"Total exceptions: {len(sorted_exceptions)}")
