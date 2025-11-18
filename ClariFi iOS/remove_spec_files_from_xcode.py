#!/usr/bin/env python3
"""
Remove spec markdown files from Xcode project's Copy Bundle Resources phase.
This fixes the "Multiple commands produce" build error.
"""

import re
import sys
from pathlib import Path

def fix_xcode_project(project_path):
    """Remove spec .md files from the Xcode project."""
    
    pbxproj_path = project_path / "project.pbxproj"
    
    if not pbxproj_path.exists():
        print(f"Error: Could not find {pbxproj_path}")
        return False
    
    print(f"Reading {pbxproj_path}...")
    
    with open(pbxproj_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Find file references to spec .md files
    spec_patterns = [
        r'.kiro/specs/[^/]+/design\.md',
        r'.kiro/specs/[^/]+/requirements\.md',
        r'.kiro/specs/[^/]+/tasks\.md',
    ]
    
    # Track what we're removing
    removed_files = []
    
    # Find and collect file reference IDs for spec files
    file_ref_ids = []
    for pattern in spec_patterns:
        # Find PBXFileReference entries
        regex = rf'([A-F0-9]+) /\* [^*]+ \*/ = \{{[^}}]*path = {pattern}[^}}]*\}};'
        matches = re.finditer(regex, content)
        for match in matches:
            file_id = match.group(1)
            file_ref_ids.append(file_id)
            removed_files.append(pattern)
            print(f"Found file reference: {file_id} for {pattern}")
    
    if not file_ref_ids:
        print("No spec .md files found in project. They may have already been removed.")
        return True
    
    # Remove these file references from PBXBuildFile sections
    for file_id in file_ref_ids:
        # Remove PBXBuildFile entries that reference these files
        build_file_regex = rf'[A-F0-9]+ /\* [^*]+ in Resources \*/ = \{{isa = PBXBuildFile; fileRef = {file_id}[^}}]*\}};'
        content = re.sub(build_file_regex, '', content)
        
        # Remove from PBXResourcesBuildPhase files array
        content = re.sub(rf'{file_id} /\* [^*]+ in Resources \*/,?\s*', '', content)
    
    # Remove the PBXFileReference entries themselves
    for file_id in file_ref_ids:
        file_ref_regex = rf'{file_id} /\* [^*]+ \*/ = \{{[^}}]*\}};'
        content = re.sub(file_ref_regex, '', content)
    
    # Clean up any trailing commas in arrays
    content = re.sub(r',(\s*\);)', r'\1', content)
    
    if content == original_content:
        print("No changes needed.")
        return True
    
    # Backup original file
    backup_path = pbxproj_path.with_suffix('.pbxproj.backup')
    print(f"Creating backup at {backup_path}...")
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(original_content)
    
    # Write modified content
    print(f"Writing modified project file...")
    with open(pbxproj_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"\n✅ Successfully removed {len(file_ref_ids)} spec file(s) from Xcode project:")
    for pattern in set(removed_files):
        print(f"   - {pattern}")
    
    print(f"\n📝 Backup saved to: {backup_path}")
    print("\n🔨 Next steps:")
    print("   1. Open Xcode")
    print("   2. Clean build folder (Cmd+Shift+K)")
    print("   3. Build project (Cmd+B)")
    
    return True

def main():
    # Find the Xcode project
    current_dir = Path.cwd()
    parent_dir = current_dir.parent
    
    project_path = parent_dir / "ClariFi iOS.xcodeproj"
    
    if not project_path.exists():
        print(f"Error: Could not find Xcode project at {project_path}")
        print(f"Current directory: {current_dir}")
        sys.exit(1)
    
    print(f"Found Xcode project: {project_path}")
    print()
    
    success = fix_xcode_project(project_path)
    
    if success:
        print("\n✅ Done!")
        sys.exit(0)
    else:
        print("\n❌ Failed to fix project")
        sys.exit(1)

if __name__ == "__main__":
    main()
