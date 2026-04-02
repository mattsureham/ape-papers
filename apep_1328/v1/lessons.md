## Discovery
- **Idea selected:** idea_0182 — Estonia's e-Residency as world's first digital border elimination for firm formation; zero prior causal papers
- **Data source:** World Bank API (IC.BUS.NDNS.ZS, IC.BUS.NREG) + e-Residency Dashboard — API worked perfectly, balanced 9-country panel
- **Key risk:** Single treated unit (1 country) limits statistical power for formal inference

## Execution
- **What worked:** Clean identification — 9-year pre-period with parallel trends, massive effect (66-81% increase), decomposition showing both e-Resident and spillover effects. The "digital border dividend" framing gives a portable concept.
- **What didn't:** P-value computation was initially wrong — used normal approximation instead of t-distribution for few-cluster inference. Consistency checker caught this before review, saving a round of revision. Also: many numbers in the text were initially inconsistent with tables (pre-treatment average, percentage calculations).
- **Review feedback adopted:** (1) Added permutation inference — honest about p=0.111 for full panel. (2) Softened "hollow dividend" to acknowledge fiscal benefits. (3) Relabeled "Domestic" to "Non-e-Resident." (4) Added power discussion for GDP null. Reviewers' main unfixable concern: this is inherently low-power due to country-level design.
