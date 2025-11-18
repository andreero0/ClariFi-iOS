#!/usr/bin/env python3
"""
Add test directories to the PBXFileSystemSynchronizedBuildFileExceptionSet
"""

import re

project_file = '../ClariFi iOS.xcodeproj/project.pbxproj'

# Directories to exclude
dirs_to_exclude = [
    'ClariFi iOSTests',
    'ClariFi iOSUITests',
]

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

# Add directories
all_exceptions = set(existing_list)
for dir_name in dirs_to_exclude:
    all_exceptions.add(dir_name)

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

print(f"✅ Added test directories to exceptions")
print(f"Total exceptions: {len(sorted_exceptions)}")
