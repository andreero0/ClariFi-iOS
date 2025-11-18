#!/usr/bin/env python3
"""
Remove .kiro/specs markdown files from Xcode project.pbxproj
"""

import re
import sys

project_file = '../ClariFi iOS.xcodeproj/project.pbxproj'

print("Reading project file...")
with open(project_file, 'r') as f:
    content = f.read()

original_lines = content.count('\n')

# Pattern to match lines with .kiro/specs/*.md references
patterns = [
    # File reference lines
    r'^\s*[A-F0-9]+ /\* [^*]+ \*/ = \{isa = PBXFileReference;[^}]*path = "?\.kiro/specs/[^"]*\.md"?;[^}]*\};\n',
    # Build file lines
    r'^\s*[A-F0-9]+ /\* [^*]+ in Resources \*/ = \{isa = PBXBuildFile; fileRef = [A-F0-9]+ /\* [^*]*\.md \*/; \};\n',
    # Array entries with paths
    r'^\s*"\.kiro/specs/[^"]*\.md",?\n',
]

lines_removed = 0
for pattern in patterns:
    matches = re.findall(pattern, content, re.MULTILINE)
    lines_removed += len(matches)
    content = re.sub(pattern, '', content, flags=re.MULTILINE)

# Also remove orphaned file references in PBXBuildFile sections
# Find all file IDs that reference .md files
md_file_ids = set()
for match in re.finditer(r'([A-F0-9]+) /\* ([^*]+\.md) \*/', content):
    file_id = match.group(1)
    md_file_ids.add(file_id)

# Remove PBXBuildFile entries that reference these IDs
for file_id in md_file_ids:
    pattern = rf'^\s*[A-F0-9]+ /\* [^*]+ in Resources \*/ = \{{isa = PBXBuildFile; fileRef = {file_id} /\* [^*]+ \*/; \}};\n'
    matches = re.findall(pattern, content, re.MULTILINE)
    if matches:
        lines_removed += len(matches)
        content = re.sub(pattern, '', content, flags=re.MULTILINE)

print(f"Original lines: {original_lines}")
print(f"Lines removed: {lines_removed}")

if lines_removed > 0:
    print("Writing cleaned project file...")
    with open(project_file, 'w') as f:
        f.write(content)
    print(f"✅ Successfully removed {lines_removed} spec file references")
else:
    print("⚠️  No spec file references found to remove")

sys.exit(0)
