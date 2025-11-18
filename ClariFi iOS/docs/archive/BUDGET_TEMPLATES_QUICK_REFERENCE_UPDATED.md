# Budget Templates Quick Reference - Updated

## All 18 Templates at a Glance

| # | Template ID | Template Name | Target Audience | Top Priority | Period |
|---|-------------|---------------|-----------------|--------------|--------|
| 1 | `student` | Student Budget | College students | Tuition (30%) | Monthly |
| 2 | `gig-worker` | Gig Worker Budget | Freelancers | Taxes (30%) | Monthly |
| 3 | `family` | Family Budget | Families with kids | Housing (30%) | Monthly |
| 4 | `professional` | Professional Budget | Career professionals | Housing (30%) | Monthly |
| 5 | `retiree` | Retiree Budget | Retirees | Housing (32%) | Monthly |
| 6 | `single-parent` | Single Parent Budget | Single parents | Housing (30%) | Monthly |
| 7 | `young-professional` | Young Professional Budget | Early career | Housing (32%) | Monthly |
| 8 | `minimalist` | Minimalist Budget | Minimalists/FIRE | Housing (30%) | Monthly |
| 9 | `entrepreneur` | Entrepreneur Budget | Business owners | Business Ops (25%) | Monthly |
| 10 | `couple` | Couple Budget | Couples | Housing (28%) | Monthly |
| 11 | `debt-payoff` | Debt Payoff Budget 🆕 | Debt elimination | Debt (40%) | Monthly |
| 12 | `savings-goal` | Savings Goal Budget 🆕 | Major savings goal | Savings (32%) | Monthly |
| 13 | `remote-worker` | Remote Worker Budget 🆕 | Remote employees | Housing (30%) | Monthly |
| 14 | `military` | Military Budget 🆕 | Military personnel | BAH (30%) | Monthly |
| 15 | `artist-creative` | Artist & Creative Budget 🆕 | Artists/creatives | Studio (25%) | Monthly |
| 16 | `healthcare-worker` | Healthcare Worker Budget 🆕 | Medical professionals | Housing (28%) | Monthly |
| 17 | `teacher` | Teacher Budget 🆕 | Teachers/educators | Housing (30%) | Monthly |
| 18 | `new-graduate` | New Graduate Budget 🆕 | Recent graduates | Housing (28%) | Monthly |

## Template Selection Flowchart

```
Are you focused on a specific financial goal?
├─ YES → Debt elimination? → Debt Payoff Budget
│        Saving for something? → Savings Goal Budget
│        Financial independence? → Minimalist Budget
│
└─ NO → What's your primary situation?
         │
         ├─ Student/Education
         │  ├─ Currently in school → Student Budget
         │  ├─ Just graduated → New Graduate Budget
         │  └─ Early career → Young Professional Budget
         │
         ├─ Working Professional
         │  ├─ Work from home → Remote Worker Budget
         │  ├─ Healthcare field → Healthcare Worker Budget
         │  ├─ Education field → Teacher Budget
         │  └─ General professional → Professional Budget
         │
         ├─ Family Situation
         │  ├─ Married/partnered, no kids → Couple Budget
         │  ├─ Family with kids → Family Budget
         │  └─ Single parent → Single Parent Budget
         │
         ├─ Self-Employed
         │  ├─ Freelancer/contractor → Gig Worker Budget
         │  ├─ Business owner → Entrepreneur Budget
         │  └─ Artist/creative → Artist & Creative Budget
         │
         └─ Other
            ├─ Military → Military Budget
            └─ Retired → Retiree Budget
```

## Category Count by Template

| Template | Categories | Notes |
|----------|-----------|-------|
| Student | 8 | Focused on education costs |
| Gig Worker | 8 | Variable income management |
| Family | 10 | Comprehensive household |
| Professional | 10 | Career growth focus |
| Retiree | 10 | Healthcare emphasis |
| Single Parent | 10 | Childcare priority |
| Young Professional | 10 | Debt + savings balance |
| Minimalist | 8 | Essential spending only |
| Entrepreneur | 9 | Business/personal split |
| Couple | 10 | Shared finances |
| Debt Payoff 🆕 | 9 | Aggressive debt reduction |
| Savings Goal 🆕 | 9 | Maximized savings |
| Remote Worker 🆕 | 10 | Home office included |
| Military 🆕 | 10 | BAH and TSP included |
| Artist & Creative 🆕 | 10 | Materials and studio |
| Healthcare Worker 🆕 | 10 | Continuing education |
| Teacher 🆕 | 10 | Summer buffer included |
| New Graduate 🆕 | 10 | Emergency fund building |

## Rollover Settings

### Rollover Enabled (15 templates)
Templates where unused budget carries over to next period:
- Student, Gig Worker, Professional, Single Parent, Young Professional
- Minimalist, Entrepreneur, Couple
- Debt Payoff ❌ (disabled for consistency)
- Savings Goal, Remote Worker, Military
- Artist & Creative, Healthcare Worker, Teacher, New Graduate

### Rollover Disabled (3 templates)
Templates where budget resets each period:
- Family (fresh start each month)
- Retiree (fixed income management)
- Debt Payoff (consistent payments)

## Top Allocation Priorities

### Housing-First (30%+)
- Student (24%), Family (30%), Professional (30%)
- Retiree (32%), Single Parent (30%), Young Professional (32%)
- Minimalist (30%), Couple (28%), Remote Worker (30%)
- Military (30%), Artist & Creative (25%), Healthcare Worker (28%)
- Teacher (30%), New Graduate (28%)

### Savings/Debt-First (30%+)
- Gig Worker (Taxes 30%)
- Debt Payoff (Debt 40%)
- Savings Goal (Savings 32%)
- Minimalist (Savings 30%)

### Business-First (25%+)
- Entrepreneur (Business Ops 25%)
- Artist & Creative (Studio 25%)

## Special Features by Template

| Template | Special Features |
|----------|-----------------|
| Student | Tuition & fees category |
| Gig Worker | Tax savings emphasis |
| Family | Childcare & education |
| Professional | Professional development |
| Retiree | Healthcare & medications |
| Single Parent | Childcare priority |
| Young Professional | Student loan focus |
| Minimalist | Maximum savings rate |
| Entrepreneur | Business/personal split |
| Couple | Date nights category |
| Debt Payoff 🆕 | 40% debt allocation |
| Savings Goal 🆕 | Primary savings goal |
| Remote Worker 🆕 | Internet & tech budget |
| Military 🆕 | BAH and TSP categories |
| Artist & Creative 🆕 | Art supplies & studio |
| Healthcare Worker 🆕 | Continuing education |
| Teacher 🆕 | Summer income buffer |
| New Graduate 🆕 | Professional wardrobe |

## Usage Tips

### First-Time Users
Start with the template closest to your situation, even if not perfect.

### Customization
All templates can be fully customized after selection.

### Multiple Budgets
Create different budgets for different scenarios (e.g., debt payoff vs. normal spending).

### Scaling
Enter your total income to automatically scale all categories.

### Review Period
Use a template for 1-2 months before heavy customization.

## Implementation Details

- **File**: `Services/BudgetTemplateService.swift`
- **Total Lines**: 538
- **Template Methods**: 18
- **Integration**: Automatic via `BudgetCreationViewModel`
- **Backward Compatible**: Yes
- **Breaking Changes**: None

## Version History

- **v1.0**: Initial 10 templates
- **v2.0**: Expanded to 18 templates (+8 new)
  - Added: Debt Payoff, Savings Goal, Remote Worker, Military
  - Added: Artist & Creative, Healthcare Worker, Teacher, New Graduate

---

**Quick Tip**: Can't decide? Try "Professional" or "Young Professional" as a starting point - they're the most flexible!
