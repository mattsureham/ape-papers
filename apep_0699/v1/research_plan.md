# Research Plan: apep_0699

**Title:** Unshackled: Saudi Arabia's Guardianship Reform and the Female Employment Surge

**Idea:** idea_0668

---

## Research Question

Did Royal Decree M/134 (August 2019) — which granted Saudi women aged 21+ the right to work without male guardian permission — cause a discrete increase in Saudi female labor force participation, distinct from the effects of the June 2018 driving ban lift?

---

## Identification Strategy

**Primary DiD:** Compare Saudi women (treated) vs. Saudi men (control 1) and non-Saudi women (control 2), using quarterly GASTAT GLMM employment data (Q1 2017 – Q1 2024).

- Treatment group: Saudi women aged 15+
- Control 1: Saudi men (same macro shocks, not subject to guardianship)
- Control 2: Non-Saudi women (not subject to guardianship as expatriates)
- Treatment timing: Q3 2019 (August 2019 decree)

**Built-in placebo window:** June 2018 driving ban (Q2 2018). Saudi female LFP rose +0.7pp post-driving vs. +5.5pp post-guardianship → 8x differential is the key variation. Pre-guardianship post-driving period (Q3 2018 – Q2 2019) serves as a falsification test.

**Event study:** Quarterly leads/lags around both reform dates (driving ban + guardianship), with 6 pre-guardianship quarters to assess parallel trends.

**Robustness:**
- Synthetic Control: GCC + MENA countries as donor pool (World Bank WDI annual data)
- Non-Saudi women as within-gender placebo
- Permutation tests / randomization inference
- Oil price + COVID (2020) controls in the DiD regression

---

## Expected Effects and Mechanisms

- Primary: Large positive effect on Saudi female LFP (~5pp) from guardianship reform, small effect from driving ban (~0.7pp)
- Mechanism: Legal autonomy (guardianship) was the binding constraint, not physical mobility (driving)
- Heterogeneity hypothesis: Per Bursztyn et al. (2023), married women did not gain from driving → guardianship reform should disproportionately benefit married women (testable if disaggregated data available)

---

## Primary Specification

```
LFP_{g,q} = α + β * (Saudi_women_{g} × Post_guardianship_{q}) + γ * (Saudi_women_{g} × Post_driving_{q}) + θ_g + τ_q + ε_{g,q}
```

Where g ∈ {Saudi women, Saudi men, non-Saudi women, non-Saudi men} and q = quarter.

Main coefficient of interest: β (guardianship reform effect on Saudi women), while γ captures driving reform.

---

## Data Sources

1. **GASTAT GLMM quarterly tables** (primary): Gulf Labour Market and Migration quarterly LFP/employment by nationality × sex, Q1 2017 – Q1 2024. Access: gulfmigration.grc.net and GLMM.gulfmigration.org.
2. **World Bank WDI API**: Annual Saudi female LFP 2010-2024 (`SL.TLF.CACT.FE.ZS`). Confirmed accessible via World Bank API.
3. **ILOSTAT**: Annual LFP estimates for cross-country comparison.
4. **ILO ILOSTAT API**: Cross-country annual panel for SCM donor pool.

---

## Timeline

- Q1 2017 – Q2 2018: Pre-driving ban (6 quarters)
- Q3 2018: Driving ban lifted
- Q3 2018 – Q2 2019: Post-driving/pre-guardianship window (4 quarters, placebo)
- Q3 2019: Guardianship decree effective
- Q4 2019 – Q1 2024: Post-guardianship (18 quarters)

Total: 28 quarterly observations

---

## Paper Format

AER: Insights (V1) — ≤6,000 words, ≤5 tables, 0 figures, 8-15 pages.

**Tables:**
1. Summary statistics (group × period means)
2. Main DiD results (Saudi women effect: driving vs guardianship)
3. Event study coefficients (quarterly leads/lags)
4. Robustness (alternative controls, COVID restriction)
5. Heterogeneity (if disaggregated data available)

**SDE appendix:** tabF1_sde.tex (LFP rate as main outcome)

---

## Exposure Alignment

**Who is treated:** The treatment-eligible population is Saudi women aged 21+ (the cohort directly affected by Royal Decree M/134). The DDD design defines the affected population as Saudi women (is_saudi=1, is_female=1) vs. three comparison groups: Saudi men (not subject to guardianship), non-Saudi women (expatriates, not subject to guardianship as citizens), and non-Saudi men.

**Triple-diff structure:** The DDD estimator identifies the guardianship reform effect by comparing the Saudi women's LFP trajectory to the triple interaction: (Saudi × Female × Post-guardianship). This isolates the reform's effect from (a) contemporaneous macro shocks affecting all Saudis, (b) global female LFP trends affecting all women, and (c) country-specific trends. The driving ban reform is similarly captured by (Saudi × Female × Post-driving), allowing both reforms to be estimated simultaneously. Saudi women are the fully treatment-eligible group; the other three gender-nationality groups serve as controls who experience the same macro environment but are not subject to guardianship law.
