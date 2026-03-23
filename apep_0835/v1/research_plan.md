# Research Plan: The Cash Curtain — Mandatory POS Terminals and Business Formalization in Greece

## Research Question

Did Greece's mandatory POS terminal requirements (Law 4446/2016, staggered rollout 2017) increase formal business activity in treated sectors relative to never-treated sectors?

## Policy Background

Greece's Law 4446/2016 (December 2016) mandated POS terminal installation for businesses:
- **Wave 1 (H1 2017):** ~85 professions — restaurants, bars, doctors, lawyers, plumbers, beauty salons
- **Wave 2 (H2 2017):** additional professions (total ~196)
- **Wave 3 (2024):** 35 more (taxis, cinemas, minimarkets)

Complementary demand-side policy: from 2017, taxpayers must spend 30% of declared income via electronic payments or face 22% surcharge.

Context: Greece's shadow economy ≈ 21% of GDP (highest in EU), self-employment rate ≈ 30% (highest in EU).

## Identification Strategy

**Sector-level staggered DiD** exploiting cross-sector variation in mandate timing.

- **Treated sectors:** Retail (G), Accommodation & food (I), Professional services (M), Human health (Q) — all mandated in 2017 waves
- **Control sectors:** Manufacturing (C), ICT (J), Mining (B), Utilities (D/E) — never mandated or mandated much later (2024)
- **Estimator:** Callaway & Sant'Anna (2021) with never-treated controls
- **Fixed effects:** Region × year FEs absorb geographic shocks; sector FEs absorb level differences
- **Clustering:** Two-way (sector, region) or sector-level

## Expected Effects

1. **Establishments:** Ambiguous. Mandate could deter marginal informal entrants (negative) or formalize existing informal businesses (positive).
2. **Employment:** Positive — forced formalization should increase reported employment
3. **Wages:** Positive — electronic payments create paper trail, reducing underreporting

## Primary Specification

Y_{s,r,t} = α + β × Treated_{s,t} + γ_{r,t} + δ_s + ε_{s,r,t}

where s = NACE sector, r = NUTS2 region, t = year. Treated_{s,t} = 1 for mandated sectors post-2017.

## Data Sources

1. **Eurostat Structural Business Statistics (SBS):** sbs_r_nuts06_r2 — region × sector panel, 2012–2020. Variables: local units (V11110), persons employed (V16110), wages/salaries (V13310).
2. **Eurostat Labour Force Survey (LFS):** Self-employment by NACE sector — for mechanism tests.
3. **Eurostat VAT revenue:** gov_10a_taxag — for aggregate revenue validation.

## Robustness

1. Event-study plot (sector-level dynamic effects pre/post 2017)
2. Placebo treatment timing (assign mandate to 2015 instead of 2017)
3. Drop 2020 (COVID contamination)
4. Permutation inference (randomly reassign sectors to waves)
5. Triple-difference: cash-intensive vs. non-cash-intensive subsectors within treated sectors

## Key Risks

- **COVID contamination:** Post-period includes 2020. Mitigated by restricting to 2012-2019 as main spec.
- **Concurrent reforms:** Capital controls (2015), bailout conditions — absorbed by region × year FEs.
- **Sample size:** ~78-104 treated region-sector cells. Modest but above minimum thresholds.
- **Eurostat data gaps:** SBS has ~90% fill rate. Missing cells handled via balanced panel restriction.
