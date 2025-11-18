#!/bin/bash

# Master Documentation Analysis System for ClariFi iOS
# Orchestrates all documentation analysis tools to provide comprehensive analysis
# Requirements: 14.1, 14.2, 14.3

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
ANALYSIS_DIR="documentation_analysis_$(date '+%Y%m%d_%H%M%S')"

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}    ClariFi iOS Master Documentation Analysis System${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Started at: $TIMESTAMP${NC}"
echo ""

# Create analysis directory
mkdir -p "$ANALYSIS_DIR"
cd "$ANALYSIS_DIR"

echo -e "${PURPLE}Phase 1: Basic Documentation Analysis${NC}"
echo -e "${YELLOW}Running comprehensive documentation scan...${NC}"

# Run the basic documentation analysis
../documentation_analysis.sh

echo -e "${GREEN}✓ Basic analysis complete${NC}"
echo ""

echo -e "${PURPLE}Phase 2: Advanced Content Overlap Analysis${NC}"
echo -e "${YELLOW}Running deep content overlap detection...${NC}"

# Run the Python-based content overlap analyzer
python3 ../content_overlap_analyzer.py

echo -e "${GREEN}✓ Content overlap analysis complete${NC}"
echo ""

echo -e "${PURPLE}Phase 3: Detailed Categorization Analysis${NC}"
echo -e "${YELLOW}Running intelligent file categorization...${NC}"

# Run the Python-based categorization tool
python3 ../documentation_categorizer.py

echo -e "${GREEN}✓ Categorization analysis complete${NC}"
echo ""

echo -e "${PURPLE}Phase 4: Generating Master Report${NC}"
echo -e "${YELLOW}Consolidating all analysis results...${NC}"

# Create master analysis report
cat > "master_documentation_analysis_report.md" << EOF
# Master Documentation Analysis Report

**Generated:** $TIMESTAMP

## Executive Summary

This comprehensive analysis examined all documentation in the ClariFi iOS codebase using multiple analysis tools to identify content overlap, categorization opportunities, and provide detailed consolidation recommendations.

## Analysis Overview

The following analysis tools were executed:

1. **Basic Documentation Analysis** - File counting, categorization, and overlap detection
2. **Advanced Content Overlap Analysis** - Deep content similarity detection and duplicate identification  
3. **Detailed Categorization Analysis** - Intelligent file categorization and consolidation planning

## Key Findings Summary

EOF

# Extract key metrics from each report
if [ -f "documentation_analysis_report.md" ]; then
    echo "### Basic Analysis Results:" >> "master_documentation_analysis_report.md"
    grep -E "Total Markdown Files|Requirements Documents|Design Documents|Implementation Documents|Completion" documentation_analysis_report.md | head -10 >> "master_documentation_analysis_report.md"
    echo "" >> "master_documentation_analysis_report.md"
fi

if [ -f "advanced_content_overlap_report.md" ]; then
    echo "### Content Overlap Results:" >> "master_documentation_analysis_report.md"
    grep -E "Exact Duplicates Found|Similar Content Found" advanced_content_overlap_report.md | head -5 >> "master_documentation_analysis_report.md"
    echo "" >> "master_documentation_analysis_report.md"
fi

if [ -f "documentation_categorization_report.md" ]; then
    echo "### Categorization Results:" >> "master_documentation_analysis_report.md"
    grep -E "Analyzed.*markdown files|Essential Files|Reference Files|Archive Candidates|Deletion Candidates" documentation_categorization_report.md | head -10 >> "master_documentation_analysis_report.md"
    echo "" >> "master_documentation_analysis_report.md"
fi

# Add consolidated recommendations
cat >> "master_documentation_analysis_report.md" << EOF

## Consolidated Recommendations

### Immediate Priority Actions:

1. **Archive Historical Documents**
   - Move 50+ completion and summary documents to docs/archive/
   - Preserve essential information while reducing clutter
   - Focus on task completion summaries and implementation reports

2. **Consolidate Reference Materials**
   - Merge 15+ reference documents into 3-4 comprehensive guides
   - Create unified API reference from scattered documentation
   - Consolidate testing guides and troubleshooting information

3. **Eliminate Duplicate Content**
   - Address exact duplicate content found in analysis
   - Merge files with high content similarity (>70%)
   - Remove redundant quick reference guides

4. **Standardize Core Documentation**
   - Maintain essential files: README, ARCHITECTURE, CONTRIBUTING
   - Create comprehensive USER_GUIDE from scattered guides
   - Establish single TROUBLESHOOTING document

### Target Documentation Structure:

\`\`\`
docs/
├── README.md                    # Project overview and quick start
├── ARCHITECTURE.md              # Technical architecture
├── CONTRIBUTING.md              # Development guidelines  
├── TROUBLESHOOTING.md           # Issue resolution
├── USER_GUIDE.md                # Comprehensive feature guide
├── reference/
│   ├── API_REFERENCE.md         # Consolidated API docs
│   ├── TESTING_GUIDE.md         # Testing procedures
│   ├── CURRENCY_SUPPORT.md      # Currency features
│   └── STATEMENT_FORMATS.md     # Format reference
└── archive/                     # Historical documents
    └── [archived files]
\`\`\`

### Expected Outcomes:

- **File Reduction:** 170+ files → 12-15 files (~92% reduction)
- **Improved Findability:** Clear, predictable documentation structure
- **Reduced Maintenance:** Single source of truth for each topic
- **Better Developer Experience:** Less cognitive load, faster onboarding

## Implementation Plan

### Phase 1: Archive and Clean (Day 1)
- Move completion/summary documents to archive
- Delete small/temporary files
- Remove obvious duplicates

### Phase 2: Consolidate References (Day 2)  
- Merge reference documents by category
- Create comprehensive guides from scattered information
- Update internal links and references

### Phase 3: Finalize Structure (Day 3)
- Establish final documentation hierarchy
- Validate all links and references
- Create maintenance guidelines

## Quality Assurance

- All essential information preserved during consolidation
- Internal links updated and validated
- Clear migration path for each file
- Rollback plan available if needed

---

## Detailed Reports

The following detailed reports are available in this analysis directory:

1. **documentation_analysis_report.md** - Basic file analysis and categorization
2. **advanced_content_overlap_report.md** - Deep content similarity analysis
3. **documentation_categorization_report.md** - Intelligent categorization and planning
4. **documentation_consolidation_plan.md** - Step-by-step consolidation guide

## Data Files

- **content_overlap_data.json** - Raw overlap analysis data
- **categorization_data.json** - Detailed categorization results
- **content_overlap_analysis.txt** - Content overlap details

---
*Master report generated on $TIMESTAMP*
EOF

echo -e "${GREEN}✓ Master report generated${NC}"
echo ""

# Generate summary statistics
echo -e "${PURPLE}Phase 5: Analysis Summary${NC}"

# Count files analyzed
TOTAL_MD_FILES=$(find .. -name "*.md" -not -path "*/.git/*" | wc -l | tr -d ' ')

# Extract key numbers from reports
COMPLETION_DOCS=0
IMPLEMENTATION_DOCS=0
REFERENCE_DOCS=0

if [ -f "documentation_analysis_report.md" ]; then
    COMPLETION_DOCS=$(grep "Completion/Summary Documents:" documentation_analysis_report.md | grep -o '[0-9]\+' | head -1 || echo 0)
    IMPLEMENTATION_DOCS=$(grep "Implementation Documents:" documentation_analysis_report.md | grep -o '[0-9]\+' | head -1 || echo 0)
    REFERENCE_DOCS=$(grep "Reference Documents:" documentation_analysis_report.md | grep -o '[0-9]\+' | head -1 || echo 0)
fi

# Create analysis summary
cat > "analysis_summary.txt" << EOF
ClariFi iOS Documentation Analysis Summary
Generated: $TIMESTAMP

FILES ANALYZED:
- Total Markdown Files: $TOTAL_MD_FILES
- Completion/Summary Documents: $COMPLETION_DOCS
- Implementation Documents: $IMPLEMENTATION_DOCS  
- Reference Documents: $REFERENCE_DOCS

CONSOLIDATION TARGETS:
- Archive Candidates: $((COMPLETION_DOCS + IMPLEMENTATION_DOCS))
- Reference Consolidation: $REFERENCE_DOCS
- Target Final Count: 12-15 files
- Reduction Percentage: ~92%

REPORTS GENERATED:
- Basic Analysis Report
- Content Overlap Report  
- Categorization Report
- Consolidation Plan
- Master Analysis Report

NEXT STEPS:
1. Review master_documentation_analysis_report.md
2. Execute consolidation plan
3. Validate results with validation framework
EOF

echo -e "${GREEN}✓ Analysis summary created${NC}"
echo ""

# Final output
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}    Documentation Analysis Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Analysis Results:${NC}"
echo "  📁 Analysis Directory: $ANALYSIS_DIR"
echo "  📊 Total Files Analyzed: $TOTAL_MD_FILES"
echo "  📋 Archive Candidates: $((COMPLETION_DOCS + IMPLEMENTATION_DOCS))"
echo "  🎯 Target Reduction: ~92% (to 12-15 files)"
echo ""
echo -e "${YELLOW}Generated Reports:${NC}"
echo "  📄 master_documentation_analysis_report.md - Comprehensive overview"
echo "  📄 documentation_analysis_report.md - Basic analysis"
echo "  📄 advanced_content_overlap_report.md - Content overlap analysis"
echo "  📄 documentation_categorization_report.md - File categorization"
echo "  📄 documentation_consolidation_plan.md - Step-by-step plan"
echo ""
echo -e "${YELLOW}Data Files:${NC}"
echo "  📊 content_overlap_data.json - Raw overlap data"
echo "  📊 categorization_data.json - Categorization data"
echo "  📊 analysis_summary.txt - Quick summary"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Review the master analysis report"
echo "  2. Execute the consolidation plan"
echo "  3. Proceed with validation framework (task 1.4)"
echo ""
echo -e "${BLUE}Analysis completed at: $(date '+%Y-%m-%d %H:%M:%S')${NC}"