#!/bin/bash

# Documentation Analysis System for ClariFi iOS
# Analyzes content overlap in 166+ markdown files and identifies consolidation opportunities
# Requirements: 14.1, 14.2, 14.3

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Output files
DOC_REPORT="documentation_analysis_report.md"
CONSOLIDATION_PLAN="documentation_consolidation_plan.md"
OVERLAP_ANALYSIS="content_overlap_analysis.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo -e "${BLUE}Starting Documentation Analysis...${NC}"

# Initialize report
cat > "$DOC_REPORT" << EOF
# ClariFi iOS Documentation Analysis Report

**Generated:** $TIMESTAMP

## Overview

This report analyzes all markdown files in the ClariFi iOS codebase to identify content overlap, categorize documentation types, and provide consolidation recommendations.

EOF

echo -e "${YELLOW}Scanning for markdown files...${NC}"

# Create temporary files for analysis
TEMP_FILES=$(mktemp)
TEMP_CONTENT=$(mktemp)
TEMP_KEYWORDS=$(mktemp)

# Find all markdown files
find . -name "*.md" -not -path "./.git/*" > "$TEMP_FILES"

TOTAL_MD_FILES=$(wc -l < "$TEMP_FILES")

echo "## Documentation Inventory" >> "$DOC_REPORT"
echo "" >> "$DOC_REPORT"
echo "- **Total Markdown Files:** $TOTAL_MD_FILES" >> "$DOC_REPORT"
echo "" >> "$DOC_REPORT"

echo -e "${YELLOW}Categorizing documentation files...${NC}"

# Initialize counters
REQUIREMENTS_COUNT=0
DESIGN_COUNT=0
IMPLEMENTATION_COUNT=0
COMPLETION_COUNT=0
REFERENCE_COUNT=0
GUIDE_COUNT=0
ARCHIVE_COUNT=0
OTHER_COUNT=0

# Categorize files
echo "### Documentation Categories:" >> "$DOC_REPORT"
echo "" >> "$DOC_REPORT"

# Create category analysis
while IFS= read -r file; do
    filename=$(basename "$file")
    filepath=$(dirname "$file")
    
    # Categorize based on filename patterns and content
    if [[ "$filename" =~ [Rr]equirements || "$file" =~ requirements\.md ]]; then
        REQUIREMENTS_COUNT=$((REQUIREMENTS_COUNT + 1))
        echo "REQUIREMENTS: $file" >> "$TEMP_CONTENT"
    elif [[ "$filename" =~ [Dd]esign || "$file" =~ design\.md ]]; then
        DESIGN_COUNT=$((DESIGN_COUNT + 1))
        echo "DESIGN: $file" >> "$TEMP_CONTENT"
    elif [[ "$filename" =~ [Ii]mplementation || "$filename" =~ IMPLEMENTATION || "$filename" =~ _IMPLEMENTATION ]]; then
        IMPLEMENTATION_COUNT=$((IMPLEMENTATION_COUNT + 1))
        echo "IMPLEMENTATION: $file" >> "$TEMP_CONTENT"
    elif [[ "$filename" =~ [Cc]ompletion || "$filename" =~ COMPLETION || "$filename" =~ _COMPLETE || "$filename" =~ SUMMARY ]]; then
        COMPLETION_COUNT=$((COMPLETION_COUNT + 1))
        echo "COMPLETION: $file" >> "$TEMP_CONTENT"
    elif [[ "$filename" =~ [Rr]eference || "$filename" =~ REFERENCE || "$filename" =~ API_ || "$filename" =~ QUICK_REFERENCE ]]; then
        REFERENCE_COUNT=$((REFERENCE_COUNT + 1))
        echo "REFERENCE: $file" >> "$TEMP_CONTENT"
    elif [[ "$filename" =~ [Gg]uide || "$filename" =~ GUIDE || "$filename" =~ USER_ || "$filename" =~ HOW_TO ]]; then
        GUIDE_COUNT=$((GUIDE_COUNT + 1))
        echo "GUIDE: $file" >> "$TEMP_CONTENT"
    elif [[ "$filepath" =~ archive || "$filepath" =~ Archive ]]; then
        ARCHIVE_COUNT=$((ARCHIVE_COUNT + 1))
        echo "ARCHIVE: $file" >> "$TEMP_CONTENT"
    else
        OTHER_COUNT=$((OTHER_COUNT + 1))
        echo "OTHER: $file" >> "$TEMP_CONTENT"
    fi
done < "$TEMP_FILES"

# Report categories
echo "- **Requirements Documents:** $REQUIREMENTS_COUNT" >> "$DOC_REPORT"
echo "- **Design Documents:** $DESIGN_COUNT" >> "$DOC_REPORT"
echo "- **Implementation Documents:** $IMPLEMENTATION_COUNT" >> "$DOC_REPORT"
echo "- **Completion/Summary Documents:** $COMPLETION_COUNT" >> "$DOC_REPORT"
echo "- **Reference Documents:** $REFERENCE_COUNT" >> "$DOC_REPORT"
echo "- **User Guides:** $GUIDE_COUNT" >> "$DOC_REPORT"
echo "- **Archived Documents:** $ARCHIVE_COUNT" >> "$DOC_REPORT"
echo "- **Other Documents:** $OTHER_COUNT" >> "$DOC_REPORT"

echo "" >> "$DOC_REPORT"

echo -e "${YELLOW}Analyzing content overlap...${NC}"

# Content overlap analysis
echo "## Content Overlap Analysis" >> "$DOC_REPORT"
echo "" >> "$DOC_REPORT"

# Initialize overlap analysis file
> "$OVERLAP_ANALYSIS"

# Common keywords to look for overlap
KEYWORDS=("budget" "transaction" "category" "currency" "analytics" "onboarding" "premium" "security" "privacy" "navigation" "insights" "LLM" "statement" "template")

echo "### Keyword Frequency Analysis:" >> "$DOC_REPORT"

for keyword in "${KEYWORDS[@]}"; do
    count=$(grep -ri "$keyword" --include="*.md" . 2>/dev/null | wc -l | tr -d ' ')
    files=$(grep -rl "$keyword" --include="*.md" . 2>/dev/null | wc -l | tr -d ' ')
    echo "- **$keyword**: $count mentions across $files files" >> "$DOC_REPORT"
    
    if [ "$files" -gt 5 ]; then
        echo "HIGH OVERLAP - $keyword: $files files" >> "$OVERLAP_ANALYSIS"
        grep -rl "$keyword" --include="*.md" . 2>/dev/null | head -10 >> "$OVERLAP_ANALYSIS"
        echo "" >> "$OVERLAP_ANALYSIS"
    fi
done

echo "" >> "$DOC_REPORT"

echo -e "${YELLOW}Identifying duplicate content patterns...${NC}"

# Look for files with similar titles or content
echo "### Potential Duplicate Content:" >> "$DOC_REPORT"
echo "" >> "$DOC_REPORT"

# Find files with similar names
echo "#### Files with Similar Names:" >> "$DOC_REPORT"
while IFS= read -r file1; do
    basename1=$(basename "$file1" .md)
    while IFS= read -r file2; do
        basename2=$(basename "$file2" .md)
        if [ "$file1" != "$file2" ] && [[ "$basename1" == *"$basename2"* || "$basename2" == *"$basename1"* ]]; then
            if [ ${#basename1} -gt 5 ] && [ ${#basename2} -gt 5 ]; then
                echo "- Similar: $file1 ↔ $file2" >> "$DOC_REPORT"
            fi
        fi
    done < "$TEMP_FILES"
done < "$TEMP_FILES" | sort | uniq | head -20

echo "" >> "$DOC_REPORT"

echo -e "${YELLOW}Analyzing file sizes and content density...${NC}"

# File size analysis
echo "### File Size Analysis:" >> "$DOC_REPORT"
echo "" >> "$DOC_REPORT"

# Large files that might need splitting
echo "#### Largest Documentation Files:" >> "$DOC_REPORT"
while IFS= read -r file; do
    if [ -f "$file" ]; then
        size=$(wc -l < "$file" 2>/dev/null || echo 0)
        echo "$size $file"
    fi
done < "$TEMP_FILES" | sort -nr | head -10 | while read size file; do
    echo "- $file: $size lines" >> "$DOC_REPORT"
done

echo "" >> "$DOC_REPORT"

# Small files that might be consolidated
echo "#### Small Files (Potential Consolidation Candidates):" >> "$DOC_REPORT"
while IFS= read -r file; do
    if [ -f "$file" ]; then
        size=$(wc -l < "$file" 2>/dev/null || echo 0)
        if [ "$size" -lt 20 ] && [ "$size" -gt 0 ]; then
            echo "$size $file"
        fi
    fi
done < "$TEMP_FILES" | sort -n | while read size file; do
    echo "- $file: $size lines" >> "$DOC_REPORT"
done

echo "" >> "$DOC_REPORT"

echo -e "${YELLOW}Generating consolidation recommendations...${NC}"

# Create consolidation plan
cat > "$CONSOLIDATION_PLAN" << EOF
# Documentation Consolidation Plan

**Generated:** $TIMESTAMP

## Current State
- **Total Files:** $TOTAL_MD_FILES markdown files
- **Target:** 12-15 essential files (90%+ reduction)

## Consolidation Strategy

### Phase 1: Archive Historical Documents
**Target for Archival:** $((COMPLETION_COUNT + IMPLEMENTATION_COUNT)) files

Files to move to \`docs/archive/\`:
EOF

# List completion and implementation files for archival
grep "COMPLETION:\|IMPLEMENTATION:" "$TEMP_CONTENT" | while read category file; do
    echo "- $file" >> "$CONSOLIDATION_PLAN"
done

cat >> "$CONSOLIDATION_PLAN" << EOF

### Phase 2: Consolidate Core Documentation
**Target Consolidated Files:**

1. **README.md** - Project overview and quick start
2. **ARCHITECTURE.md** - Technical architecture and patterns
3. **CONTRIBUTING.md** - Development guidelines and standards
4. **TROUBLESHOOTING.md** - Common issues and solutions
5. **USER_GUIDE.md** - Feature usage and workflows

### Phase 3: Create Reference Documentation
**Target Reference Files:**

1. **docs/reference/API_REFERENCE.md** - Consolidated API documentation
2. **docs/reference/TESTING_GUIDE.md** - Testing procedures and standards
3. **docs/reference/STATEMENT_FORMATS.md** - Supported formats reference
4. **docs/reference/CURRENCY_SUPPORT.md** - Currency feature documentation

### Phase 4: Consolidate Requirements and Design
**Spec Consolidation:**

EOF

# List requirements and design files
grep "REQUIREMENTS:\|DESIGN:" "$TEMP_CONTENT" | while read category file; do
    echo "- $file → Consolidate into spec directories" >> "$CONSOLIDATION_PLAN"
done

cat >> "$CONSOLIDATION_PLAN" << EOF

## Consolidation Rules

### Keep (Essential Files):
- Current spec files (requirements.md, design.md, tasks.md)
- Main README.md and ARCHITECTURE.md
- Active user guides and troubleshooting docs

### Archive (Historical Files):
- Task completion summaries
- Implementation progress reports
- Build fix documentation
- Temporary analysis reports

### Merge (Overlapping Content):
- Multiple quick reference guides → Single reference
- Scattered API docs → Consolidated API reference
- Multiple troubleshooting docs → Single guide
- Feature-specific guides → Comprehensive user guide

### Delete (Obsolete Files):
- Empty or placeholder files
- Duplicate information
- Outdated implementation details
- Temporary analysis files

## Expected Outcome
- **Before:** $TOTAL_MD_FILES files
- **After:** 12-15 essential files
- **Reduction:** ~90%
- **Improved:** Findability, maintainability, clarity
EOF

# Add recommendations to main report
echo "## Consolidation Recommendations" >> "$DOC_REPORT"
echo "" >> "$DOC_REPORT"

echo "### Immediate Actions:" >> "$DOC_REPORT"
echo "1. **Archive $COMPLETION_COUNT completion/summary documents** to docs/archive/" >> "$DOC_REPORT"
echo "2. **Consolidate $REFERENCE_COUNT reference documents** into 3-4 comprehensive references" >> "$DOC_REPORT"
echo "3. **Merge $GUIDE_COUNT user guides** into single comprehensive guide" >> "$DOC_REPORT"
echo "4. **Review $IMPLEMENTATION_COUNT implementation documents** for essential information extraction" >> "$DOC_REPORT"

echo "" >> "$DOC_REPORT"

echo "### Priority Consolidations:" >> "$DOC_REPORT"

# Find high-overlap topics for priority consolidation
if [ -s "$OVERLAP_ANALYSIS" ]; then
    echo "Based on content overlap analysis:" >> "$DOC_REPORT"
    head -20 "$OVERLAP_ANALYSIS" | while IFS= read -r line; do
        if [[ "$line" =~ "HIGH OVERLAP" ]]; then
            echo "- $line" >> "$DOC_REPORT"
        fi
    done
fi

echo "" >> "$DOC_REPORT"

echo "### Target File Structure:" >> "$DOC_REPORT"
echo '```' >> "$DOC_REPORT"
echo "docs/" >> "$DOC_REPORT"
echo "├── README.md                    # Project overview" >> "$DOC_REPORT"
echo "├── ARCHITECTURE.md              # Technical architecture" >> "$DOC_REPORT"
echo "├── CONTRIBUTING.md              # Development guidelines" >> "$DOC_REPORT"
echo "├── TROUBLESHOOTING.md           # Issue resolution" >> "$DOC_REPORT"
echo "├── USER_GUIDE.md                # Feature usage" >> "$DOC_REPORT"
echo "├── reference/" >> "$DOC_REPORT"
echo "│   ├── API_REFERENCE.md         # API documentation" >> "$DOC_REPORT"
echo "│   ├── TESTING_GUIDE.md         # Testing procedures" >> "$DOC_REPORT"
echo "│   ├── STATEMENT_FORMATS.md     # Format reference" >> "$DOC_REPORT"
echo "│   └── CURRENCY_SUPPORT.md      # Currency features" >> "$DOC_REPORT"
echo "└── archive/                     # Historical documents" >> "$DOC_REPORT"
echo '```' >> "$DOC_REPORT"

echo "" >> "$DOC_REPORT"
echo "---" >> "$DOC_REPORT"
echo "*Analysis generated by documentation_analysis.sh on $TIMESTAMP*" >> "$DOC_REPORT"

# Cleanup temporary files
rm -f "$TEMP_FILES" "$TEMP_CONTENT" "$TEMP_KEYWORDS"

echo -e "${GREEN}✓ Documentation analysis complete!${NC}"
echo -e "${BLUE}Reports generated:${NC}"
echo "  - Analysis report: $DOC_REPORT"
echo "  - Consolidation plan: $CONSOLIDATION_PLAN"
if [ -s "$OVERLAP_ANALYSIS" ]; then
    echo "  - Overlap analysis: $OVERLAP_ANALYSIS"
fi
echo ""
echo -e "${YELLOW}Key Findings:${NC}"
echo "- Total markdown files: $TOTAL_MD_FILES"
echo "- Completion/summary docs: $COMPLETION_COUNT (candidates for archival)"
echo "- Implementation docs: $IMPLEMENTATION_COUNT (candidates for archival)"
echo "- Reference docs: $REFERENCE_COUNT (candidates for consolidation)"
echo "- Target reduction: ~90% (to 12-15 essential files)"
echo ""
echo -e "${GREEN}Next steps: Review consolidation plan and proceed with validation framework.${NC}"