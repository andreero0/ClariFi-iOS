#!/bin/bash

# Dependency Mapping Tool for ClariFi iOS
# Analyzes import statements and file dependencies across all Swift files
# Requirements: 16.1, 17.1

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Output files
DEPENDENCY_REPORT="dependency_analysis_report.md"
DEPENDENCY_GRAPH="dependency_graph.dot"
CIRCULAR_DEPS="circular_dependencies.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${BLUE}Starting Dependency Mapping Analysis...${NC}"

# Initialize report
cat > "$DEPENDENCY_REPORT" << EOF
# ClariFi iOS Dependency Analysis Report

**Generated:** $TIMESTAMP

## Overview

This report analyzes import statements, file dependencies, and potential circular dependencies across all Swift files in the ClariFi iOS codebase.

EOF

echo -e "${YELLOW}Analyzing import statements...${NC}"

# Create temporary files for analysis
TEMP_IMPORTS=$(mktemp)
TEMP_FILES=$(mktemp)
TEMP_DEPS=$(mktemp)

# Find all Swift files
find . -name "*.swift" -not -path "./.git/*" > "$TEMP_FILES"

echo "## Import Statement Analysis" >> "$DEPENDENCY_REPORT"
echo "" >> "$DEPENDENCY_REPORT"

# Analyze imports
echo "### Import Statistics:" >> "$DEPENDENCY_REPORT"

# Count total imports
TOTAL_IMPORTS=$(find . -name "*.swift" -not -path "./.git/*" -exec grep -h "^import " {} \; | wc -l | tr -d ' ')
echo "- **Total Import Statements:** $TOTAL_IMPORTS" >> "$DEPENDENCY_REPORT"

# Count unique imports
UNIQUE_IMPORTS=$(find . -name "*.swift" -not -path "./.git/*" -exec grep -h "^import " {} \; | sort | uniq | wc -l | tr -d ' ')
echo "- **Unique Imports:** $UNIQUE_IMPORTS" >> "$DEPENDENCY_REPORT"

echo "" >> "$DEPENDENCY_REPORT"

# Most common imports
echo "### Most Common Imports:" >> "$DEPENDENCY_REPORT"
find . -name "*.swift" -not -path "./.git/*" -exec grep -h "^import " {} \; | sort | uniq -c | sort -nr | head -15 | while read count import; do
    echo "- $import: $count files" >> "$DEPENDENCY_REPORT"
done

echo "" >> "$DEPENDENCY_REPORT"

echo -e "${YELLOW}Mapping file dependencies...${NC}"

# Create dependency mapping
echo "## File Dependency Mapping" >> "$DEPENDENCY_REPORT"
echo "" >> "$DEPENDENCY_REPORT"

# Initialize dependency graph
echo "digraph Dependencies {" > "$DEPENDENCY_GRAPH"
echo "  rankdir=TB;" >> "$DEPENDENCY_GRAPH"
echo "  node [shape=box, style=rounded];" >> "$DEPENDENCY_GRAPH"
echo "" >> "$DEPENDENCY_GRAPH"

# Analyze each Swift file
while IFS= read -r file; do
    # Get file name without path and extension
    filename=$(basename "$file" .swift)
    
    # Get imports for this file
    imports=$(grep "^import " "$file" 2>/dev/null | sed 's/import //' | grep -v "Foundation\|SwiftUI\|UIKit\|CoreData\|Combine" || true)
    
    if [ -n "$imports" ]; then
        echo "$file -> $imports" >> "$TEMP_DEPS"
        
        # Add to dependency graph
        while IFS= read -r import; do
            if [ -n "$import" ]; then
                echo "  \"$filename\" -> \"$import\";" >> "$DEPENDENCY_GRAPH"
            fi
        done <<< "$imports"
    fi
done < "$TEMP_FILES"

echo "}" >> "$DEPENDENCY_GRAPH"

echo -e "${YELLOW}Analyzing dependency patterns...${NC}"

# Analyze dependency patterns by directory
echo "### Dependencies by Directory:" >> "$DEPENDENCY_REPORT"
echo "" >> "$DEPENDENCY_REPORT"

# Core dependencies
CORE_DEPS=$(find ./Core -name "*.swift" 2>/dev/null -exec grep -c "^import " {} \; | awk '{sum += $1} END {print sum+0}')
echo "- **Core/**: $CORE_DEPS import statements" >> "$DEPENDENCY_REPORT"

# Services dependencies
SERVICES_DEPS=$(find ./Services -name "*.swift" 2>/dev/null -exec grep -c "^import " {} \; | awk '{sum += $1} END {print sum+0}')
echo "- **Services/**: $SERVICES_DEPS import statements" >> "$DEPENDENCY_REPORT"

# ViewModels dependencies
VIEWMODELS_DEPS=$(find ./ViewModels -name "*.swift" 2>/dev/null -exec grep -c "^import " {} \; | awk '{sum += $1} END {print sum+0}')
echo "- **ViewModels/**: $VIEWMODELS_DEPS import statements" >> "$DEPENDENCY_REPORT"

# Views dependencies
VIEWS_DEPS=$(find ./Views -name "*.swift" 2>/dev/null -exec grep -c "^import " {} \; | awk '{sum += $1} END {print sum+0}')
echo "- **Views/**: $VIEWS_DEPS import statements" >> "$DEPENDENCY_REPORT"

# Models dependencies
MODELS_DEPS=$(find ./Models -name "*.swift" 2>/dev/null -exec grep -c "^import " {} \; | awk '{sum += $1} END {print sum+0}')
echo "- **Models/**: $MODELS_DEPS import statements" >> "$DEPENDENCY_REPORT"

# Repositories dependencies
REPOS_DEPS=$(find ./Repositories -name "*.swift" 2>/dev/null -exec grep -c "^import " {} \; | awk '{sum += $1} END {print sum+0}')
echo "- **Repositories/**: $REPOS_DEPS import statements" >> "$DEPENDENCY_REPORT"

echo "" >> "$DEPENDENCY_REPORT"

echo -e "${YELLOW}Detecting circular dependencies...${NC}"

# Simple circular dependency detection
echo "## Circular Dependency Analysis" >> "$DEPENDENCY_REPORT"
echo "" >> "$DEPENDENCY_REPORT"

# Clear circular dependencies file
> "$CIRCULAR_DEPS"

# Check for potential circular dependencies
# This is a simplified check - looks for files that might import each other
while IFS= read -r file; do
    filename=$(basename "$file" .swift)
    
    # Check if any other file imports this file's module
    potential_circulars=$(find . -name "*.swift" -not -path "./.git/*" -not -path "$file" -exec grep -l "import.*$filename\|$filename\." {} \; 2>/dev/null || true)
    
    if [ -n "$potential_circulars" ]; then
        # Check if this file imports any of those files back
        while IFS= read -r potential_file; do
            if [ -n "$potential_file" ]; then
                potential_name=$(basename "$potential_file" .swift)
                if grep -q "import.*$potential_name\|$potential_name\." "$file" 2>/dev/null; then
                    echo "Potential circular dependency: $file <-> $potential_file" >> "$CIRCULAR_DEPS"
                fi
            fi
        done <<< "$potential_circulars"
    fi
done < "$TEMP_FILES"

# Report circular dependencies
if [ -s "$CIRCULAR_DEPS" ]; then
    echo "### ⚠️ Potential Circular Dependencies Found:" >> "$DEPENDENCY_REPORT"
    echo "" >> "$DEPENDENCY_REPORT"
    while IFS= read -r line; do
        echo "- $line" >> "$DEPENDENCY_REPORT"
    done < "$CIRCULAR_DEPS"
else
    echo "### ✅ No Obvious Circular Dependencies Detected" >> "$DEPENDENCY_REPORT"
fi

echo "" >> "$DEPENDENCY_REPORT"

echo -e "${YELLOW}Analyzing import optimization opportunities...${NC}"

# Import optimization analysis
echo "## Import Optimization Opportunities" >> "$DEPENDENCY_REPORT"
echo "" >> "$DEPENDENCY_REPORT"

# Files with many imports
echo "### Files with Most Imports:" >> "$DEPENDENCY_REPORT"
find . -name "*.swift" -not -path "./.git/*" -exec sh -c 'echo "$(grep -c "^import " "$1" 2>/dev/null || echo 0) $1"' _ {} \; | sort -nr | head -10 | while read count file; do
    echo "- $file: $count imports" >> "$DEPENDENCY_REPORT"
done

echo "" >> "$DEPENDENCY_REPORT"

# Unused import detection (simplified)
echo "### Potential Unused Imports:" >> "$DEPENDENCY_REPORT"
echo "" >> "$DEPENDENCY_REPORT"

UNUSED_COUNT=0
while IFS= read -r file; do
    # Check for imports that might not be used
    imports=$(grep "^import " "$file" 2>/dev/null | sed 's/import //' | grep -v "Foundation\|SwiftUI\|UIKit\|CoreData\|Combine" || true)
    
    while IFS= read -r import; do
        if [ -n "$import" ]; then
            # Simple check: if import name doesn't appear elsewhere in file
            if ! grep -q "$import" "$file" 2>/dev/null | grep -v "^import "; then
                echo "- $file: potentially unused import '$import'" >> "$DEPENDENCY_REPORT"
                UNUSED_COUNT=$((UNUSED_COUNT + 1))
            fi
        fi
    done <<< "$imports"
done < "$TEMP_FILES"

if [ $UNUSED_COUNT -eq 0 ]; then
    echo "- No obvious unused imports detected" >> "$DEPENDENCY_REPORT"
fi

echo "" >> "$DEPENDENCY_REPORT"

echo -e "${YELLOW}Generating dependency statistics...${NC}"

# Dependency statistics
echo "## Dependency Statistics" >> "$DEPENDENCY_REPORT"
echo "" >> "$DEPENDENCY_REPORT"

# Calculate average imports per file
SWIFT_FILE_COUNT=$(wc -l < "$TEMP_FILES")
AVG_IMPORTS=$(echo "scale=1; $TOTAL_IMPORTS / $SWIFT_FILE_COUNT" | bc 2>/dev/null || echo "N/A")
echo "- **Average imports per file:** $AVG_IMPORTS" >> "$DEPENDENCY_REPORT"

# Most imported modules
echo "" >> "$DEPENDENCY_REPORT"
echo "### Most Imported External Modules:" >> "$DEPENDENCY_REPORT"
find . -name "*.swift" -not -path "./.git/*" -exec grep -h "^import " {} \; | grep -E "Foundation|SwiftUI|UIKit|CoreData|Combine|Network" | sort | uniq -c | sort -nr | while read count import; do
    echo "- $import: $count files" >> "$DEPENDENCY_REPORT"
done

echo "" >> "$DEPENDENCY_REPORT"

# Internal dependencies
echo "### Internal Module Dependencies:" >> "$DEPENDENCY_REPORT"
find . -name "*.swift" -not -path "./.git/*" -exec grep -h "^import " {} \; | grep -v -E "Foundation|SwiftUI|UIKit|CoreData|Combine|Network|XCTest" | sort | uniq -c | sort -nr | head -10 | while read count import; do
    echo "- $import: $count files" >> "$DEPENDENCY_REPORT"
done

echo "" >> "$DEPENDENCY_REPORT"

# Recommendations
echo "## Recommendations" >> "$DEPENDENCY_REPORT"
echo "" >> "$DEPENDENCY_REPORT"

echo "### Optimization Opportunities:" >> "$DEPENDENCY_REPORT"
echo "1. **Review files with high import counts** (>10 imports may indicate tight coupling)" >> "$DEPENDENCY_REPORT"
echo "2. **Investigate potential circular dependencies** for architectural improvements" >> "$DEPENDENCY_REPORT"
echo "3. **Remove unused imports** to reduce compilation time and improve clarity" >> "$DEPENDENCY_REPORT"
echo "4. **Consider dependency injection** to reduce direct import dependencies" >> "$DEPENDENCY_REPORT"
echo "5. **Group related imports** and organize them consistently" >> "$DEPENDENCY_REPORT"

echo "" >> "$DEPENDENCY_REPORT"
echo "### Next Steps:" >> "$DEPENDENCY_REPORT"
echo "1. Review the dependency graph (dependency_graph.dot) with a graph visualization tool" >> "$DEPENDENCY_REPORT"
echo "2. Address any circular dependencies found" >> "$DEPENDENCY_REPORT"
echo "3. Optimize imports in files with high import counts" >> "$DEPENDENCY_REPORT"
echo "4. Standardize import organization across all files" >> "$DEPENDENCY_REPORT"

echo "" >> "$DEPENDENCY_REPORT"
echo "---" >> "$DEPENDENCY_REPORT"
echo "*Report generated by dependency_mapping.sh on $TIMESTAMP*" >> "$DEPENDENCY_REPORT"

# Cleanup temporary files
rm -f "$TEMP_IMPORTS" "$TEMP_FILES" "$TEMP_DEPS"

echo -e "${GREEN}✓ Dependency mapping analysis complete!${NC}"
echo -e "${BLUE}Reports generated:${NC}"
echo "  - Dependency analysis: $DEPENDENCY_REPORT"
echo "  - Dependency graph: $DEPENDENCY_GRAPH"
if [ -s "$CIRCULAR_DEPS" ]; then
    echo "  - Circular dependencies: $CIRCULAR_DEPS"
fi
echo ""
echo -e "${YELLOW}Key Findings:${NC}"
echo "- Total imports: $TOTAL_IMPORTS"
echo "- Unique imports: $UNIQUE_IMPORTS"
echo "- Average imports per file: $AVG_IMPORTS"
if [ -s "$CIRCULAR_DEPS" ]; then
    CIRCULAR_COUNT=$(wc -l < "$CIRCULAR_DEPS")
    echo "- Potential circular dependencies: $CIRCULAR_COUNT"
else
    echo "- Circular dependencies: None detected"
fi
echo ""
echo -e "${GREEN}Next steps: Review dependency reports and proceed with documentation analysis.${NC}"