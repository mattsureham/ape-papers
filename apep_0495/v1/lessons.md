## Discovery
- **Policy chosen:** UK 20% VAT on private school fees (Jan 2025) — first large-scale fee shock to private education in a developed economy, provides clean exogenous variation in the relative cost of private vs. state schooling
- **Ideas rejected:** (1) University admissions / LEO earnings outcomes — infeasible because no post-treatment cohort has graduated yet; data requires TRE access. (2) State school enrollment pressure — only 1 annual post-treatment observation available. (3) Local economic multiplier of private schools — treatment-outcome mismatch (too diluted). (4) Announcement-premium standalone paper — thin at weekly transaction frequency
- **Data source:** Land Registry PPD (housing transactions, monthly, postcode-level, 24M+ records since 1995) + GIAS/Edubase (all school locations, types, Ofsted ratings) + postcodes.io (geocoding). All confirmed accessible via API/bulk download.
- **Key risk:** Short post-treatment window (14 months). Mitigated by: (1) framing as short-run capitalization study, (2) multi-stage anticipation events, (3) massive statistical power from millions of transactions, (4) housing markets respond faster than education outcomes.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT, Grok, Codex; Gemini FAIL) after 13 iterations
- **Top criticism:** Temporal placebo (-0.039) is 80% of main effect (-0.048), undermining causal interpretation. All three referees flagged this as the central weakness.
- **Surprise feedback:** The negative DDD sign (opposite to Fack-Grenet prediction) generated useful theoretical discussion. Referees appreciated the honesty.
- **What changed:** Downgraded all causal language to "association"/"descriptive evidence"; added formal placebo comparison; strengthened London discussion; expanded GIAS endogeneity defense; standardized variable naming across all tables

## Summary
- **Main finding:** Negative DDD of -0.048 (school quality premium decreased in high-private areas), concentrated at election announcement. Temporal placebo precludes confident causal attribution.
- **Biggest challenge:** Getting advisor review to pass took 13 iterations. Each model finds new issues each run. Variable naming standardization and coefficient consistency across tables were recurring themes.
- **Process lesson:** For UK papers, note GIAS post-treatment extract date and Land Registry registration lag as limitations early.
