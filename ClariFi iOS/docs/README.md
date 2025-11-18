# ClariFi iOS Documentation

This directory contains all project documentation organized by purpose.

## Directory Structure

### `/setup/`
Setup and configuration guides for getting the project running:

- **AUTHENTICATION_SETUP_GUIDE.md** - Guide for setting up authentication
- **COMPILATION_FIXES_NEEDED.md** - Compilation fixes and workarounds
- **TEST_TARGET_FIX_GUIDE.md** - Guide for fixing test target issues
- **XCODE_BUILD_FIX.md** - Xcode build configuration fixes

### `/reports/`
Analysis, audit, and verification reports:

- **AUTOMATED_TESTING_AND_VERIFICATION_REPORT.md** - Automated testing verification results
- **baseline_analysis_report.md** - Baseline codebase analysis
- **CODEBASE_VALIDATION_REPORT.md** - Codebase validation results
- **dependency_analysis_report.md** - Dependency analysis
- **DESIGN_SYSTEM_AUDIT_REPORT.md** - Design system audit findings
- **documentation_analysis_report.md** - Documentation analysis
- **LLM_CATEGORIZATION_BUSINESS_LOGIC_REPORT.md** - LLM categorization business logic analysis
- **SESSION_SUMMARY_REPORT.md** - Development session summaries
- **UI_VERIFICATION_REPORT.md** - UI verification results
- **USER_PROFILE_ANALYSIS_REPORT.md** - User profile analysis

### `/features/`
Feature-specific documentation organized by feature domain:

#### `/features/authentication/`
- **USER_AUTHENTICATION_ARCHITECTURE.md** - Authentication architecture design
- **USER_AUTHENTICATION_IMPLEMENTATION_SUMMARY.md** - Implementation summary

#### `/features/backup/`
- **SUPABASE_CLOUD_BACKUP_ARCHITECTURE.md** - Cloud backup architecture

#### `/features/currency/`
- **CRITICAL_CURRENCY_FIX_PLAN.md** - Currency fix implementation plan
- **CURRENCY_FEATURE_IMPLEMENTATION_SUMMARY.md** - Currency feature implementation summary
- **CURRENCY_FEATURE_PROOF.md** - Currency feature proof of concept
- **WHERE_IS_CURRENCY_SETTING.md** - Currency setting location guide

### `/guides/`
User and developer guides:

- **CURRENCY_SUPPORT_GUIDE.md** - How to use currency features
- **HOW_TO_CHANGE_CURRENCY.md** - Step-by-step currency change guide
- **TROUBLESHOOTING.md** - Common issues and solutions
- **USER_GUIDE_UX_FEATURES.md** - UX features user guide

### `/testing/`
Testing documentation and guides:

- **INTEGRATION_TEST_COVERAGE.md** - Integration test coverage analysis
- **UI_TESTS_README.md** - UI testing guide

### `/reference/`
Technical reference documentation that remains relevant for ongoing development:

- **STATE_MANAGEMENT_PATTERNS.md** - Patterns and best practices for state management in SwiftUI
- **STATEMENT_FORMATS_OVERVIEW.md** - Overview of supported bank statement formats
- **SUPPORTED_STATEMENT_FORMATS.md** - Detailed list of supported statement formats
- **TEST_COVERAGE_ANALYSIS.md** - Analysis of test coverage across the codebase

### `/archive/`
Historical implementation documentation from completed tasks and features. These documents provide context about past decisions and implementations but are not required for day-to-day development.

Archived documents include:
- Task completion summaries (TASK_*.md files)
- Implementation guides from completed features
- Historical fix documentation
- Progress summaries
- Deprecated documentation

## Essential Documentation

For current development, refer to these key documents:

1. **[../ARCHITECTURE.md](../ARCHITECTURE.md)** - Primary architecture documentation (in project root)
2. **[../README.md](../README.md)** - Project overview and getting started guide (in project root)
3. **[reference/](./reference/)** - Technical reference materials

## Documentation Guidelines

### When to Add Documentation

- **Architecture changes**: Update ARCHITECTURE.md
- **New patterns**: Add to appropriate reference doc
- **Completed tasks**: Archive in `/archive/` if needed for historical context
- **New features**: Update README.md and relevant reference docs

### When to Archive Documentation

Archive documentation when:
- Task or feature implementation is complete
- Document is primarily historical context
- Information has been consolidated into ARCHITECTURE.md or code comments
- Document is no longer needed for active development

### Documentation Principles

1. **Keep it minimal**: Only document what's necessary
2. **Keep it current**: Update docs when code changes
3. **Keep it accessible**: Essential docs in root, reference docs organized by topic
4. **Keep it actionable**: Focus on what developers need to know, not what was done
