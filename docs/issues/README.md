# Critical Issues Tracker

## Overview

This directory contains detailed GitHub-style issue tracking for critical bugs identified during the comprehensive code review of ClariFi iOS.

## Issues

### 🔴 Critical Priority

| Issue | Title | Status | Estimated Time |
|-------|-------|--------|----------------|
| [#001](./issue-001-account-balance-persistence.md) | Account Balances Not Persisted During Onboarding | 🔴 Open | 2-3 hours |
| [#002](./issue-002-first-action-not-executing.md) | First Action Not Executing After Onboarding | 🔴 Open | 2-3 hours |
| [#004](./issue-004-fake-balance-calculation.md) | HomeView Displays Fake Account Balances | 🔴 Open | 2 hours |

### 🟠 High Priority

| Issue | Title | Status | Estimated Time |
|-------|-------|--------|----------------|
| [#003](./issue-003-account-validation-contradiction.md) | Account Setup Validation Contradicts Optional Flag | 🟠 Open | 1-2 hours |
| [#005](./issue-005-validation-bypass-swipe.md) | Users Can Bypass Validation by Swiping | 🟠 Open | 3-4 hours |

## Implementation Order

1. **Issue #001** - Account Balance Persistence (prerequisite for #004)
2. **Issue #004** - Real Balance Calculation (depends on #001)
3. **Issue #002** - First Action Execution
4. **Issue #003** - Account Validation Contradiction
5. **Issue #005** - Validation Bypass via Swipe

**Total Estimated Time**: 10-14 hours

## Dependencies

```
#001 (Account Balance)
  └─> #004 (Real Balance Calculation)

#002 (First Action) - Independent
#003 (Validation) - Independent
#005 (Swipe Bypass) - Independent
```

## References

- [Comprehensive Code Review Report](../review-report.md)
- [Critical Fix Proposals](../fixes/CRITICAL_FIX_PROPOSALS.md)

## Status Legend

- 🔴 Critical - Data loss or core feature broken
- 🟠 High - Major UX issue or business logic problem
- 🟡 Medium - Minor UX issue or enhancement
- 🟢 Low - Polish or optimization

## Progress Tracking

- [ ] Issue #001 - Account Balance Persistence
- [ ] Issue #002 - First Action Execution
- [ ] Issue #003 - Account Validation Contradiction
- [ ] Issue #004 - Real Balance Calculation
- [ ] Issue #005 - Validation Bypass via Swipe

Last Updated: 2025-11-18
