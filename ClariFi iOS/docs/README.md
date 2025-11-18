# ClariFi iOS Documentation

This directory contains all project documentation organized by purpose.

## Directory Structure

### `/reference/`
Technical reference documentation that remains relevant for ongoing development:

- **STATE_MANAGEMENT_PATTERNS.md** - Patterns and best practices for state management in SwiftUI
- **STATEMENT_FORMATS_OVERVIEW.md** - Overview of supported bank statement formats
- **SUPPORTED_STATEMENT_FORMATS.md** - Detailed list of supported statement formats
- **TEST_COVERAGE_ANALYSIS.md** - Analysis of test coverage across the codebase

### `/archive/`
Historical implementation documentation from completed tasks and features. These documents provide context about past decisions and implementations but are not required for day-to-day development.

Archived documents include:
- Task completion summaries
- Implementation guides
- Feature-specific documentation
- Build fix documentation
- Test implementation summaries

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
