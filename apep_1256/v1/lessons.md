## Discovery
- **Idea selected:** idea_2216 — Donor-funded mayors and procurement capture in Colombia. Selected for sharp institutional lever (close-election RDD), strong microdata (SECOP II + Cuentas Claras), first-order stakes (corruption/state capacity), and vivid mechanism ("capture premium").
- **Data source:** SECOP II (Socrata jbjy-vk9h), Cuentas Claras (jgra-rz2t), CEDAE election results (S3 CSV). All publicly available, no auth needed. Server-side aggregation on Socrata worked after fixing case sensitivity (orden='Territorial' not 'TERRITORIAL').
- **Key risk:** SECOP II coverage is incomplete — only ~60% of municipalities have data, biasing toward larger, more formalized local governments.

## Execution
- **What worked:** The close-election RDD framework translated cleanly from the idea manifest. Name-matching across three datasets using Jaro-Winkler at 0.3 threshold captured 90% of municipalities. Extending pre-period to 2018 (from 2019) fixed the n_pre validation gate AND produced a cleaner placebo test.
- **What didn't:** Initial heterogeneity split (median pre-period discretionary share) produced degenerate group (all zeros → SD=0 → Inf SDE). Switched to municipality size split. The rdrobust cross-section estimates are large and noisy with the small effective sample (~74 observations); the panel DiD-in-discontinuity with FEs is the more reliable specification.
- **Review feedback adopted:** Added wild cluster bootstrap (p=0.106), explained discretionary share discrepancy (42% sample vs 79% national), added COVID caveat, toned down overclaiming language, fixed SDE table Inf values.
