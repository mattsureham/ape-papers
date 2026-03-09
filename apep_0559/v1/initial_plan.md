# Initial Research Plan: Cap On, Cap Off

## Research Question

Does interest rate regulation cause irreversible credit rationing? Kenya's Banking Amendment Act (2016) capped lending rates at CBR+4%, then the Finance Act (2019) repealed it, creating a 38-month symmetric on-off natural experiment. We estimate: (1) the causal effect of the cap on bank lending portfolios using bank-level supervisory data, (2) whether credit rationing reversed upon repeal, and (3) the welfare cost of borrower substitution into unregulated digital credit.

## Identification Strategy

**Design:** Continuous-treatment DiD exploiting bank-level heterogeneity in pre-cap exposure to the interest rate ceiling.

**Treatment:** The interest rate cap (CBR+4%) binds differentially across banks. Banks with higher pre-cap lending rates (those serving riskier, SME-heavy clienteles) face a larger bite. We construct a continuous exposure measure from pre-cap (2015) bank balance sheets:

- **Primary:** Pre-cap interest rate spread = (bank lending rate − CBR) / cap margin
- **Secondary:** Pre-cap loan-to-asset ratio (high = more exposed, can't easily shift to govt securities)
- **Tertiary:** Pre-cap government securities share (low = less hedged against the cap)

**Estimation:**

Y_{it} = α_i + δ_t + β₁(Exposure_i × Post_t) + β₂(Exposure_i × Repeal_t) + X_{it}γ + ε_{it}

where i = bank, t = month/year. β₁ captures the cap effect; β₂ captures whether the effect reverses after repeal. Full event-study specification with leads and lags.

**Key assumptions:**
1. Parallel trends: High- and low-exposure banks would have followed similar trajectories absent the cap (testable with 2010-2015 pre-period)
2. No contemporaneous bank-specific shocks correlated with exposure
3. The cap is the only systematic treatment that differentially affects high-exposure banks at the treatment date

## Expected Effects and Mechanisms

**Cap-on period (Sep 2016 – Nov 2019):**
- High-exposure banks reduce private sector lending (β₁ < 0)
- High-exposure banks increase government securities holdings (portfolio substitution)
- NPL ratios spike as banks ration credit to marginal borrowers but remaining loans concentrate in riskier segments
- Aggregate private credit/GDP falls

**Mechanism:** Stiglitz-Weiss (1981) adverse selection: cap prevents risk-based pricing → banks exit risky lending segments → shift to safe government securities.

**Cap-off period (Nov 2019+):**
- If credit rationing is reversible: β₂ > 0 (symmetric reversal)
- If credit rationing is irreversible (hysteresis): β₂ ≈ 0 (banks don't return to SME lending)
- Hysteresis sources: relationship destruction, organizational learning loss, regulatory caution

**Digital credit substitution:**
- Borrowers rationed out of formal banking turn to M-Pesa digital credit (M-Shwari, KCB M-Pesa, Tala, Branch)
- Digital credit APR: 7.5% per 30 days ≈ 138% effective APR vs. 14% regulated bank rate
- Welfare cost: borrowers pay ~10× more for credit, with higher default and over-indebtedness rates

## Primary Specification

**Unit of analysis:** Bank × year (annual balance sheet data from CBK Annual Reports, 42 banks × 10 years ≈ 420 obs)

**Supplementary:** Monthly aggregate data from CBK statistical bulletins for aggregate event study

**Dependent variables:**
1. log(Loans & Advances) — credit volume
2. Government Securities / Total Assets — portfolio rebalancing
3. NPL Ratio — credit quality
4. Interest Income / Loans — effective lending rate

**Independent variable:** Exposure_i × Period_t (continuous treatment × period dummies for pre/cap/repeal)

**Fixed effects:** Bank FE + Year FE (or Month FE for aggregate)

**Clustering:** Bank level (42 clusters) with wild cluster bootstrap

## Planned Robustness Checks

1. **Pre-trends test:** Event-study with year-by-year leads, joint F-test
2. **Alternative exposure measures:** Tier dummies, loan/asset ratio, interest spread — show results are robust across specifications
3. **Pre-COVID repeal window:** Restrict to Nov 2019 – Feb 2020 (4 months clean)
4. **Leave-one-out:** Drop each bank sequentially to test for outlier dependence
5. **Randomization inference:** Permute exposure across banks (42 permutations feasible)
6. **Cross-country comparison:** Kenya vs Uganda/Tanzania/Rwanda credit/GDP from World Bank WDI (supportive evidence)
7. **Placebo outcomes:** Bank size, employee count (should not respond differentially)
8. **Callaway-Sant'Anna:** If converting to discrete treatment (above/below median exposure)

## Data Sources

| Source | Granularity | Coverage | Access |
|--------|------------|----------|--------|
| CBK Annual Reports | Bank × Year | 2010-2023, ~42 banks | PDF (cbk.go.ke) |
| CBK Monthly Statistical Bulletin | Aggregate × Month | 2014-2024 | CSV (cbk.go.ke) |
| CBK Weighted Average Rates | Monthly | 1991-2024 | CSV |
| World Bank WDI | Country × Year | 1960-2023 | API |
| FinAccess Household Survey | Individual | 2016, 2019 | Harvard Dataverse |
| OxCGRT COVID Stringency | Country × Day | 2020-2023 | GitHub |

## Power Assessment

- 42 banks × 10 years = 420 bank-year observations
- Pre-treatment periods: 6 years (2010-2015)
- Treatment period: 4 years (2016-2019)
- Post-repeal: 4 years (2020-2023)
- With bank and year FE, effective DoF for the interaction term is reasonable
- Wild cluster bootstrap accounts for 42 clusters
- The first stage is strong: lending rate dropped 3.8pp immediately at cap (17.66% → 13.86%)

## Key Risks

1. **CBK Annual Report PDFs may require manual extraction** — need table parsing from PDFs
2. **COVID contamination of repeal period** — mitigated by pre-COVID window analysis
3. **Bank mergers/exits during sample period** — track entry/exit, use balanced panel as robustness
4. **Digital credit data limitations** — FinAccess is cross-sectional per wave, not panel; treat as mechanism evidence
