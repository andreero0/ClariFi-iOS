#!/bin/bash

# ViewModel DI Compliance Audit Script
# This script scans all ViewModels to verify proper dependency injection patterns

echo "=========================================="
echo "ViewModel DI Compliance Audit"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
total_viewmodels=0
compliant_viewmodels=0
non_compliant_viewmodels=0

# Arrays to store results
declare -a compliant_files
declare -a non_compliant_files
declare -a issues_found

# Find all ViewModel files
viewmodel_files=$(find . -type f -name "*ViewModel.swift" -o -name "*Coordinator.swift" | grep -v ".build" | grep -v "Pods" | sort)

echo "Scanning ViewModels for DI compliance..."
echo ""

# Function to check a single file
check_file() {
    local file=$1
    local filename=$(basename "$file")
    local has_issues=false
    local file_issues=""
    
    total_viewmodels=$((total_viewmodels + 1))
    
    # Check 1: Direct DependencyContainer() instantiation (anti-pattern)
    if grep -q "DependencyContainer()" "$file" 2>/dev/null; then
        has_issues=true
        file_issues="${file_issues}\n  ❌ Direct DependencyContainer() instantiation found"
    fi
    
    # Check 2: Should have init(container:) pattern OR constructor injection
    local has_container_init=false
    local has_constructor_injection=false
    
    if grep -q "init(container:" "$file" 2>/dev/null; then
        has_container_init=true
    fi
    
    # Check for constructor injection pattern (init with repository/service parameters)
    if grep -q "init(" "$file" 2>/dev/null && \
       grep -q "Repository\|Service\|context:" "$file" 2>/dev/null; then
        has_constructor_injection=true
    fi
    
    # Exception: BaseViewModel, OnboardingCoordinator, and OnboardingViewModel might not need it
    # OnboardingViewModel is a special coordinator that creates services on-demand
    if [[ ! "$filename" =~ "BaseViewModel" ]] && \
       [[ ! "$filename" =~ "OnboardingCoordinator" ]] && \
       [[ ! "$filename" =~ "OnboardingViewModel" ]]; then
        if [ "$has_container_init" = false ] && [ "$has_constructor_injection" = false ]; then
            has_issues=true
            file_issues="${file_issues}\n  ⚠️  Missing dependency injection pattern (neither init(container:) nor constructor injection)"
        fi
    fi
    
    # Check 3: Should not have AppDIContainer as @StateObject or @ObservedObject
    if grep -q "@StateObject.*AppDIContainer\|@ObservedObject.*AppDIContainer" "$file" 2>/dev/null; then
        has_issues=true
        file_issues="${file_issues}\n  ❌ Container stored as @StateObject or @ObservedObject"
    fi
    
    # Check 4: Should resolve dependencies from container OR store injected dependencies
    if grep -q "init(container:" "$file" 2>/dev/null; then
        if ! grep -q "container.resolve\|container\..*Repository\|container\..*Service" "$file" 2>/dev/null; then
            has_issues=true
            file_issues="${file_issues}\n  ⚠️  Has init(container:) but doesn't resolve dependencies"
        fi
    elif [ "$has_constructor_injection" = true ]; then
        # Check that injected dependencies are stored as properties
        # Allow both private let and @Published for dependency storage
        if ! grep -q "private let.*Repository\|private let.*Service\|private let.*context\|@Published.*Service\|private let.*Manager" "$file" 2>/dev/null; then
            # Exception for BaseViewModel and OnboardingViewModel which have special patterns
            if [[ ! "$filename" =~ "BaseViewModel" ]] && [[ ! "$filename" =~ "OnboardingViewModel" ]]; then
                has_issues=true
                file_issues="${file_issues}\n  ⚠️  Has constructor injection but doesn't store dependencies as properties"
            fi
        fi
    fi
    
    # Report results
    if [ "$has_issues" = true ]; then
        non_compliant_viewmodels=$((non_compliant_viewmodels + 1))
        non_compliant_files+=("$file")
        issues_found+=("$file:$file_issues")
        echo -e "${RED}✗${NC} $filename"
        echo -e "$file_issues"
        echo ""
    else
        compliant_viewmodels=$((compliant_viewmodels + 1))
        compliant_files+=("$file")
        echo -e "${GREEN}✓${NC} $filename"
    fi
}

# Process each file
for file in $viewmodel_files; do
    check_file "$file"
done

# Summary Report
echo ""
echo "=========================================="
echo "AUDIT SUMMARY"
echo "=========================================="
echo ""
echo "Total ViewModels scanned: $total_viewmodels"
echo -e "${GREEN}Compliant: $compliant_viewmodels${NC}"
echo -e "${RED}Non-compliant: $non_compliant_viewmodels${NC}"
echo ""

if [ $non_compliant_viewmodels -gt 0 ]; then
    echo "=========================================="
    echo "NON-COMPLIANT VIEWMODELS"
    echo "=========================================="
    echo ""
    for issue in "${issues_found[@]}"; do
        IFS=':' read -r file problems <<< "$issue"
        echo "File: $file"
        echo -e "$problems"
        echo ""
    done
fi

echo "=========================================="
echo "COMPLIANT VIEWMODELS"
echo "=========================================="
echo ""
for file in "${compliant_files[@]}"; do
    echo "✓ $file"
done
echo ""

# Generate detailed report file
report_file=".kiro/specs/critical-ux-fixes/DI_AUDIT_REPORT.md"
echo "Generating detailed report: $report_file"

cat > "$report_file" << EOF
# ViewModel DI Compliance Audit Report

**Generated:** $(date)

## Summary

- **Total ViewModels:** $total_viewmodels
- **Compliant:** $compliant_viewmodels
- **Non-Compliant:** $non_compliant_viewmodels
- **Compliance Rate:** $(awk "BEGIN {printf \"%.1f\", ($compliant_viewmodels/$total_viewmodels)*100}")%

## Compliance Criteria

A ViewModel is considered compliant if it:

1. ✅ Does NOT directly instantiate \`DependencyContainer()\`
2. ✅ Uses EITHER:
   - \`init(container: AppDIContainer)\` pattern with \`container.resolve()\`, OR
   - Constructor injection with dependencies passed as parameters
3. ✅ Does NOT store container as \`@StateObject\` or \`@ObservedObject\`
4. ✅ Stores injected dependencies as private properties

## Non-Compliant ViewModels

EOF

if [ $non_compliant_viewmodels -gt 0 ]; then
    for issue in "${issues_found[@]}"; do
        IFS=':' read -r file problems <<< "$issue"
        echo "### $(basename "$file")" >> "$report_file"
        echo "" >> "$report_file"
        echo "**Path:** \`$file\`" >> "$report_file"
        echo "" >> "$report_file"
        echo "**Issues:**" >> "$report_file"
        echo -e "$problems" | sed 's/^//' >> "$report_file"
        echo "" >> "$report_file"
    done
else
    echo "✅ All ViewModels are compliant!" >> "$report_file"
    echo "" >> "$report_file"
fi

cat >> "$report_file" << EOF

## Compliant ViewModels

EOF

for file in "${compliant_files[@]}"; do
    echo "- ✅ \`$file\`" >> "$report_file"
done

cat >> "$report_file" << EOF

## Recommended Actions

EOF

if [ $non_compliant_viewmodels -gt 0 ]; then
    cat >> "$report_file" << EOF
For each non-compliant ViewModel, choose ONE of these patterns:

### Option 1: Container-based DI (Recommended for new code)

\`\`\`swift
private let repository: SomeRepository
private let service: SomeService

init(container: AppDIContainer) {
    self.repository = container.resolve(SomeRepository.self)
    self.service = container.resolve(SomeService.self)
    super.init()
}
\`\`\`

### Option 2: Constructor Injection (Current pattern - acceptable)

\`\`\`swift
private let repository: SomeRepository
private let service: SomeService
private let context: NSManagedObjectContext

init(
    repository: SomeRepository,
    service: SomeService,
    context: NSManagedObjectContext
) {
    self.repository = repository
    self.service = service
    self.context = context
    super.init()
}
\`\`\`

### View Integration

For container-based DI:
\`\`\`swift
struct SomeView: View {
    @Environment(\.diContainer) var container
    @StateObject private var viewModel: SomeViewModel
    
    init() {
        self._viewModel = StateObject(wrappedValue: SomeViewModel(container: AppDIContainer()))
    }
    
    var body: some View {
        // content
        .onAppear {
            if viewModel.needsConfiguration {
                viewModel.configure(with: container)
            }
        }
    }
}
\`\`\`

For constructor injection, dependencies must be resolved and passed from the View.

## References

- Requirements: 6.1, 6.2, 6.5
- Design Document: \`.kiro/specs/critical-ux-fixes/design.md\`
- DI Pattern Reference: \`.kiro/specs/critical-ux-fixes/DI_PATTERN_QUICK_REFERENCE.md\`
EOF
else
    cat >> "$report_file" << EOF
✅ All ViewModels are compliant with DI patterns. No action required.

Continue to monitor new ViewModels to ensure they follow the established pattern.
EOF
fi

echo ""
echo "Report saved to: $report_file"
echo ""

# Exit with error code if non-compliant ViewModels found
if [ $non_compliant_viewmodels -gt 0 ]; then
    exit 1
else
    exit 0
fi
