# Research Plan: Offshore Wealth Repatriation and Swiss Real Estate

## Research Question

Did the 2017 Automatic Exchange of Information (AEOI) shock to Swiss banking secrecy cause offshore wealth repatriation that inflated domestic real estate prices in wealth-management hub regions?

## Background

Switzerland's adoption of the OECD Common Reporting Standard (CRS) via the Multilateral Competent Authority Agreement entered into force January 1, 2017. Wave 1 (38 countries, all EU members) began data collection in 2017 for first exchange in September 2018. Prior work establishes that ~CHF 81 billion exited Swiss banks 2015–2018 as foreign depositors withdrew. The SFTA reports ~107,000 Swiss residents voluntarily disclosed previously hidden foreign accounts during 2010–2020, with the AEOI announcement period (2013–2016) driving most disclosures.

The question: did this repatriated wealth flow into Swiss domestic real estate? If so, banking secrecy reform may have contributed to the housing affordability crisis in high-exposure regions (Geneva, Zurich, Zug).

## Identification Strategy

**Continuous-treatment Difference-in-Differences:**

`Price_rt = α_r + γ_t + β(Post_2017_t × BankingIntensity_r) + ε_rt`

- **Unit:** 12 SNB real estate regions × years (1970–2025)
- **Treatment timing:** 2017 (sharp, single-date national policy)
- **Treatment intensity:** Pre-determined cross-regional variation in banking sector concentration:
  - Primary: NOGA 64 (financial services) employment share by region (pre-2017 average)
  - Secondary: Share of foreign-controlled banks per SNB banking statistics
- **Outcome:** SNB regional real estate price index (apartments, houses, rental, commercial)
- **Clustering:** Region level (12 clusters — wild cluster bootstrap mandatory)

**Event study:** Estimate year-by-year coefficients β_t for t ∈ {2010, ..., 2023} to verify parallel pre-trends.

## Expected Effects and Mechanisms

**If repatriation → real estate:** Wealth-management hubs (Geneva, Zurich, Zug) should see differential price acceleration after 2017 relative to non-hub regions. Mechanism: repatriated offshore wealth enters domestic asset markets, with real estate as a natural destination for high-net-worth portfolios.

**If null:** Repatriated wealth may have (a) remained in financial assets, (b) been consumed, (c) left Switzerland entirely, or (d) distributed evenly across regions. A well-powered null settles an important open question.

## Primary Specification

1. **Main DiD:** Continuous treatment intensity × Post-2017, region + year FE
2. **Event study:** Year-by-year interactions with banking intensity
3. **Property type heterogeneity:** Apartments vs. houses vs. rental vs. commercial
4. **Robustness:**
   - Exclude 2015–2016 (CHF floor removal period)
   - Restrict post-period to 2017–2019 (pre-COVID)
   - Control for CHF/EUR exchange rate
   - Permutation inference (reassign treatment intensity across regions)
5. **Placebo:** Non-financial sector employment intensity should not predict differential price growth

## Data Sources

1. **SNB Regional Real Estate Price Indices** — `https://data.snb.ch/api/cube/plimoinreg/data/csv/en`
   - 12 regions, 1970–2025, annual
   - Property types: EW (apartments), EH (houses), MW (rental), BF (commercial)

2. **SNB Banking Statistics** — Regional banking employment/branch data for treatment intensity
   - Alternative: BFS STATENT for NOGA 64 employment by canton

3. **Treatment intensity construction:** Pre-2017 average of banking employment share per region, using BFS or SNB data. Cross-walk cantons to SNB regions.

## Key Risks

- **Small N:** 12 regions is below standard clustering thresholds. Mitigation: wild cluster bootstrap (Webb 2023), permutation inference, leave-one-out diagnostics.
- **Macroprudential confounds:** SNB countercyclical capital buffer (2013), mortgage tightening. Mitigation: these are national policies absorbed by year FE; only differential impact across regions could confound.
- **CHF appreciation shock (Jan 2015):** May differentially affect Geneva (cross-border workers). Mitigation: exclude 2015–2016 as robustness.
