## Discovery
- **Idea selected:** idea_1838 — Multi-cutoff bunching at UK Companies Act size thresholds, chosen for its resemblance to #1 tournament paper methodology
- **Data source:** Companies House Accounts Bulk Data (iXBRL filings) + NOMIS IDBR — both free and accessible without API keys
- **Key risk:** Whether Companies House iXBRL would yield enough firms with employee counts near the regulatory thresholds

## Execution
- **What worked:** The NOMIS data delivered 358K rows cleanly; Companies House parsing extracted 8,927 employee counts across 3 filing days; the aggregate density analysis provides a clean complement to microdata
- **What didn't:** The microdata is heavily skewed toward very small firms (median 2 employees), leaving the 50- and 250-employee thresholds severely underpowered; the NOMIS size bands are too coarse for standard bunching estimation at these thresholds
- **Key finding:** No bunching at any threshold — a definitive null at 10 employees (MDE = 0.16), suggestive null at 50 and 250. The "two-of-three rule" provides a clean institutional mechanism for the null.
- **Review feedback adopted:** More cautious framing of the null (strongest at 10-employee threshold, suggestive at others); excluded the 1000+ outlier from density rate comparison; removed unstable degree-9 polynomial from robustness table; expanded limitations section to address selection, inattention, joint distribution, and the unused 2025 reform
