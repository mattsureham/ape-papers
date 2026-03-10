# Internal Review - Claude Code (Round 1)

## Review Summary

Internal review completed after advisor review (Stage A). Key issues identified and fixed:

### Issues Found and Fixed
1. **Sample count inconsistencies** — Abstract, data section, and tables reported different product counts (5,534 vs 5,342). Fixed: explained singleton removal explicitly.
2. **Missing coefficient** — Table 2 Col(2) omitted Post×Capital×Pre-Import (-0.092***). Fixed: added to table.
3. **Wrong Col(2) product count** — Reported 5,234, actual was 4,814. Fixed.
4. **Table 1 overflow** — Summary table exceeded page margins. Fixed: reduced columns, added adjustbox.
5. **Capital RI p-value unreported** — Computed and added: 0.265.
6. **Rounding inconsistency** — Standardized to 3 decimal places throughout.

### Revision Actions Taken
- Reconciled all sample counts with explicit data flow documentation
- Added 3 new robustness checks: short window (2017-2019), category trends, gov-sector exclusion
- Softened causal language where RI does not support strong claims
- Added CBE FX priority list discussion in Limitations
