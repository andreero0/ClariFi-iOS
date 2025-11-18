#!/bin/bash

# Comprehensive Codebase Baseline Analysis Script
# This script analyzes the current state of the ClariFi iOS codebase
# Requirements: 13.1, 16.1

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Output file
OUTPUT_FILE="baseline_analysis_report.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${BLUE}Starting Comprehensive Codebase Baseline Analysis...${NC}"

# Initialize report
cat > "$OUTPUT_FILE" << EOF
# ClariFi iOS Codebase Baseline Analysis Report

**Generated:** $TIMESTAMP

## Executive Summary

This report provides a comprehensive analysis of the current ClariFi iOS codebase state, including file counts, organization patterns, and architectural inconsistencies.

EOF

echo -e "${YELLOW}Analyzing file structure and counts...${NC}"

# File counting and categorization
echo "## File Structure Analysis" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Count Swift files
SWIFT_COUNT=$(find . -name "*.swift" -not -path "./.git/*" | wc -l | tr -d ' ')
echo "### Swift Files: $SWIFT_COUNT" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Swift files by directory
echo "#### Swift Files by Directory:" >> "$OUTPUT_FILE"
find . -name "*.swift" -not -path "./.git/*" | sed 's|/[^/]*$||' | sort | uniq -c | sort -nr | while read count dir; do
    echo "- $dir: $count files" >> "$OUTPUT_FILE"
done
echo "" >> "$OUTPUT_FILE"

# Count markdown files
MD_COUNT=$(find . -name "*.md" -not -path "./.git/*" | wc -l | tr -d ' ')
echo "### Markdown Files: $MD_COUNT" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Markdown files by directory
echo "#### Markdown Files by Directory:" >> "$OUTPUT_FILE"
find . -name "*.md" -not -path "./.git/*" | sed 's|/[^/]*$||' | sort | uniq -c | sort -nr | while read count dir; do
    echo "- $dir: $count files" >> "$OUTPUT_FILE"
done
echo "" >> "$OUTPUT_FILE"

# Count shell scripts
SCRIPT_COUNT=$(find . -name "*.sh" -not -path "./.git/*" | wc -l | tr -d ' ')
echo "### Shell Scripts: $SCRIPT_COUNT" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Scripts by location
echo "#### Shell Scripts by Location:" >> "$OUTPUT_FILE"
find . -name "*.sh" -not -path "./.git/*" | while read script; do
    echo "- $script" >> "$OUTPUT_FILE"
done
echo "" >> "$OUTPUT_FILE"

# Root directory analysis
echo "### Root Directory Files" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
ROOT_FILES=$(ls -la | grep -v "^d" | grep -v "^total" | wc -l | tr -d ' ')
echo "**Total files in root directory:** $ROOT_FILES" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "#### Root Directory Contents:" >> "$OUTPUT_FILE"
ls -la | grep -v "^d" | grep -v "^total" | awk '{print "- " $9 " (" $5 " bytes)"}' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo -e "${YELLOW}Analyzing project structure patterns...${NC}"

# Project structure analysis
echo "## Project Structure Analysis" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Directory structure
echo "### Directory Structure:" >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
find . -type d -not -path "./.git/*" -not -path "./.*" | head -30 | sort >> "$OUTPUT_FILE"
echo '```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Identify architectural patterns
echo "### Architectural Patterns Analysis" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Check for ViewModels
VIEWMODEL_COUNT=$(find . -name "*ViewModel.swift" -not -path "./.git/*" | wc -l | tr -d ' ')
echo "- **ViewModels:** $VIEWMODEL_COUNT files" >> "$OUTPUT_FILE"

# Check for Services
SERVICE_COUNT=$(find . -name "*Service.swift" -not -path "./.git/*" | wc -l | tr -d ' ')
echo "- **Services:** $SERVICE_COUNT files" >> "$OUTPUT_FILE"

# Check for Views
VIEW_COUNT=$(find . -name "*View.swift" -not -path "./.git/*" | wc -l | tr -d ' ')
echo "- **Views:** $VIEW_COUNT files" >> "$OUTPUT_FILE"

# Check for Models
MODEL_COUNT=$(find . -path "*/Models/*.swift" -not -path "./.git/*" | wc -l | tr -d ' ')
echo "- **Models:** $MODEL_COUNT files" >> "$OUTPUT_FILE"

# Check for Repositories
REPO_COUNT=$(find . -name "*Repository*.swift" -not -path "./.git/*" | wc -l | tr -d ' ')
echo "- **Repositories:** $REPO_COUNT files" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"

echo -e "${YELLOW}Analyzing architectural inconsistencies...${NC}"

# Architectural inconsistencies
echo "## Architectural Inconsistencies" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Check for mixed patterns in ViewModels
echo "### ViewModel Patterns:" >> "$OUTPUT_FILE"
if [ -d "ViewModels" ]; then
    echo "- ViewModels directory exists: ✓" >> "$OUTPUT_FILE"
else
    echo "- ViewModels directory missing: ✗" >> "$OUTPUT_FILE"
fi

if [ -d "Presentation/ViewModels" ]; then
    echo "- Presentation/ViewModels directory exists: ✓" >> "$OUTPUT_FILE"
else
    echo "- Presentation/ViewModels directory missing: ✗" >> "$OUTPUT_FILE"
fi

# Check for DI patterns
echo "" >> "$OUTPUT_FILE"
echo "### Dependency Injection Patterns:" >> "$OUTPUT_FILE"
DI_FILES=$(find . -name "*.swift" -not -path "./.git/*" -exec grep -l "DIContainer\|@Environment.*DI\|init.*:.*Protocol" {} \; | wc -l | tr -d ' ')
echo "- Files using DI patterns: $DI_FILES" >> "$OUTPUT_FILE"

# Check for error handling patterns
ERROR_HANDLING_FILES=$(find . -name "*.swift" -not -path "./.git/*" -exec grep -l "AppError\|LocalizedError" {} \; | wc -l | tr -d ' ')
echo "- Files using standardized error handling: $ERROR_HANDLING_FILES" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"

echo -e "${YELLOW}Analyzing code quality metrics...${NC}"

# Code quality analysis
echo "## Code Quality Metrics" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Lines of code
TOTAL_LOC=$(find . -name "*.swift" -not -path "./.git/*" -exec wc -l {} \; | awk '{sum += $1} END {print sum}')
echo "- **Total Lines of Code (Swift):** $TOTAL_LOC" >> "$OUTPUT_FILE"

# Average file size
AVG_FILE_SIZE=$(echo "scale=1; $TOTAL_LOC / $SWIFT_COUNT" | bc)
echo "- **Average Swift File Size:** $AVG_FILE_SIZE lines" >> "$OUTPUT_FILE"

# TODO comments
TODO_COUNT=$(find . -name "*.swift" -not -path "./.git/*" -exec grep -c "TODO\|FIXME\|HACK" {} \; | awk '{sum += $1} END {print sum}')
echo "- **TODO/FIXME/HACK Comments:** $TODO_COUNT" >> "$OUTPUT_FILE"

# Import analysis
IMPORT_COUNT=$(find . -name "*.swift" -not -path "./.git/*" -exec grep -c "^import " {} \; | awk '{sum += $1} END {print sum}')
echo "- **Total Import Statements:** $IMPORT_COUNT" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"

echo -e "${YELLOW}Generating file size analysis...${NC}"

# File size analysis
echo "## File Size Analysis" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Largest Swift Files:" >> "$OUTPUT_FILE"
find . -name "*.swift" -not -path "./.git/*" -exec wc -l {} \; | sort -nr | head -10 | while read lines file; do
    echo "- $file: $lines lines" >> "$OUTPUT_FILE"
done

echo "" >> "$OUTPUT_FILE"
echo "### Largest Markdown Files:" >> "$OUTPUT_FILE"
find . -name "*.md" -not -path "./.git/*" -exec wc -l {} \; | sort -nr | head -10 | while read lines file; do
    echo "- $file: $lines lines" >> "$OUTPUT_FILE"
done

echo "" >> "$OUTPUT_FILE"

echo -e "${YELLOW}Analyzing naming conventions...${NC}"

# Naming convention analysis
echo "## Naming Convention Analysis" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Check for consistent naming patterns
echo "### File Naming Patterns:" >> "$OUTPUT_FILE"

# ViewModels naming
CONSISTENT_VM=$(find . -name "*ViewModel.swift" -not -path "./.git/*" | wc -l | tr -d ' ')
INCONSISTENT_VM=$(find . -name "*VM.swift" -o -name "*Model.swift" | grep -v ViewModel | wc -l | tr -d ' ')
echo "- Consistent ViewModel naming: $CONSISTENT_VM files" >> "$OUTPUT_FILE"
echo "- Inconsistent ViewModel naming: $INCONSISTENT_VM files" >> "$OUTPUT_FILE"

# Services naming
CONSISTENT_SERVICE=$(find . -name "*Service.swift" -not -path "./.git/*" | wc -l | tr -d ' ')
echo "- Consistent Service naming: $CONSISTENT_SERVICE files" >> "$OUTPUT_FILE"

# Views naming
CONSISTENT_VIEW=$(find . -name "*View.swift" -not -path "./.git/*" | wc -l | tr -d ' ')
echo "- Consistent View naming: $CONSISTENT_VIEW files" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"

# Summary and recommendations
echo "## Summary and Recommendations" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "### Critical Issues Identified:" >> "$OUTPUT_FILE"
echo "1. **Documentation Overload:** $MD_COUNT markdown files need consolidation" >> "$OUTPUT_FILE"
echo "2. **Root Directory Clutter:** $ROOT_FILES files in root directory" >> "$OUTPUT_FILE"
echo "3. **Script Organization:** $SCRIPT_COUNT shell scripts need organization" >> "$OUTPUT_FILE"
echo "4. **Code Quality:** $TODO_COUNT TODO/FIXME comments need attention" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "### Cleanup Priorities:" >> "$OUTPUT_FILE"
echo "1. Consolidate $MD_COUNT markdown files to 12-15 essential files" >> "$OUTPUT_FILE"
echo "2. Organize $SCRIPT_COUNT shell scripts into scripts/ directory" >> "$OUTPUT_FILE"
echo "3. Clean up root directory (remove $ROOT_FILES non-essential files)" >> "$OUTPUT_FILE"
echo "4. Standardize architectural patterns across $SWIFT_COUNT Swift files" >> "$OUTPUT_FILE"
echo "5. Address $TODO_COUNT technical debt items" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "---" >> "$OUTPUT_FILE"
echo "*Report generated by baseline_analysis.sh on $TIMESTAMP*" >> "$OUTPUT_FILE"

echo -e "${GREEN}✓ Baseline analysis complete!${NC}"
echo -e "${BLUE}Report saved to: $OUTPUT_FILE${NC}"
echo ""
echo -e "${YELLOW}Key Findings:${NC}"
echo "- Swift files: $SWIFT_COUNT"
echo "- Markdown files: $MD_COUNT"
echo "- Shell scripts: $SCRIPT_COUNT"
echo "- Root directory files: $ROOT_FILES"
echo "- TODO comments: $TODO_COUNT"
echo ""
echo -e "${GREEN}Next steps: Review the detailed report and proceed with dependency mapping.${NC}"