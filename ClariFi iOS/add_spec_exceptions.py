#!/usr/bin/env python3
"""
Add all .kiro/specs/*.md files to the PBXFileSystemSynchronizedBuildFileExceptionSet
"""

import re
import os
import glob

project_file = '../ClariFi iOS.xcodeproj/project.pbxproj'

# Find all spec markdown files
spec_files = []
for spec_dir in glob.glob('.kiro/specs/*'):
    if os.path.isdir(spec_dir):
        for md_file in ['design.md', 'requirements.md', 'tasks.md', 'README.md']:
            file_path = os.path.join(spec_dir, md_file)
            if os.path.exists(file_path):
                # Use relative path from ClariFi iOS directory
                rel_path = file_path
                spec_files.append(rel_path)

print(f"Found {len(spec_files)} spec files to exclude")

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
for spec_file in spec_files:
    all_exceptions.add(spec_file)

# Sort for consistency
sorted_exceptions = sorted(all_exceptions)

# Format as Xcode expects
formatted_exceptions = []
for exc in sorted_exceptions:
    # Don't quote if it doesn't have spaces
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

print(f"✅ Added {len(spec_files)} spec files to exceptions")
print(f"Total exceptions: {len(sorted_exceptions)}")
