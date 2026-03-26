## Discovery
- **Idea selected:** idea_1232 — Latvia's 2018 AML shell-company ban. Chosen for clean natural experiment (FinCEN designation + legislative prohibition), confirmed open data, and portable mechanism ("laundering premium").
- **Data source:** Latvia Enterprise Register Open Data (dati.ur.gov.lv) — 482K firm records, worked on first attempt. No NACE sector codes available, required pivot to firm-type × geography design.
- **Key risk:** Pre-trends in the event study (noisy monthly dissolution data for the treated group).

## Execution
- **What worked:** Firm-type × geography DiD cleanly separates the shell-company channel. The farm-enterprise placebo (zero effect) and the 2000s cohort heterogeneity (peak non-resident banking era) both nail the mechanism. The sole-proprietor spillover adds depth — real domestic economic costs beyond the shells themselves.
- **What didn't:** The ATVK codes required manual mapping (10000 = Riga). The event study pre-period coefficients are noisy due to within-group volatility at monthly frequency. Linear trends specification has collinearity issues with only 4 groups.
- **Review feedback adopted:** Added dynamic effects section describing event study results (post-treatment break at t=0, large spikes at t=11-12 for compliance deadline). Added May 2018 treatment timing sensitivity (β=6.70 vs 7.47 baseline). Added inference discussion acknowledging 4-group clustering limitation. Added NACE limitation footnote. Did not implement cross-country placebo (Estonia/Lithuania data not fetched) or sector-municipality granularity (NACE codes unavailable in register) — flagged as future work.
