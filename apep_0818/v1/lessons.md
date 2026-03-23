## Discovery
- **Idea selected:** idea_0856 — Zombie nonprofits and creative destruction. Picked for sharp institutional lever (IRS auto-revocation), large N (3,060 counties), and vivid framing connecting to AER-published zombie firm literature.
- **Data source:** IRS bulk downloads (revocation list, BMF, SOI county) + Census QWI. IRS revocation list required ZIP download from apps.irs.gov (pipe-delimited, not CSV). SOI county data unavailable pre-2011, killing DiD for charitable giving.
- **Key risk:** Counties with more zombie nonprofits may be systematically different. Addressed via county FE, pre-trends, and controlled specification.

## Execution
- **What worked:** The event study reveals a rich "false spring" pattern — burst then collapse — that tells a more compelling story than the average effect alone. The continuous-treatment design with county-year FE is clean and intuitive.
- **What didn't:** QWI API refused multi-year requests (had to loop state×year). SOI county data missing for 2006-2010 prevented DiD on charitable giving. The t=-2 pre-trend coefficient is marginally significant, creating a vulnerability.
- **Review feedback adopted:** (1) Added explicit discussion of reinstatement concern; (2) Promoted controlled specification (-0.371***) as key robustness addressing pre-trend concern; (3) Explicitly labeled charitable giving results as descriptive/cross-sectional.
