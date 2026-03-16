# Research Plan: Cap, Repeal, and the FinTech Frontier: Kenya's Interest Rate Controls and Digital Credit Substitution

**Paper ID:** apep_0702
**Idea:** idea_0221
**Date:** 2026-03-16

---

## Research Question

Do formal banking interest rate caps cause borrowers to substitute toward unregulated digital credit, and does the symmetric repeal of the cap reverse this substitution? Specifically, did Kenya's 2016 Banking Amendment Act (capping lending rates at CBR + 4%) reduce formal bank credit while driving growth of expensive mobile lending (M-Shwari, Tala, Branch), with effects reversed after the November 2019 repeal?

This paper resolves a central debate in financial regulation: interest rate controls aim to protect borrowers from high rates, but if digital lenders fall outside the regulatory perimeter, caps may push borrowers toward *more* expensive credit. The symmetric cap-and-repeal episode provides a rare opportunity to test both directions of this mechanism.

---

## Identification Strategy

### Design 1: Cross-country Difference-in-Differences
- **Treatment:** Kenya (Banking Amendment Act, effective September 2016; repealed November 2019)
- **Controls:** Uganda, Tanzania, Rwanda — East African peers without interest rate caps during 2010-2023
- **Outcome:** Domestic credit to private sector (% GDP), lending rates, bank branches per 100K adults
- **Source:** World Bank WDI (annual, confirmed 48+ years for Kenya and comparators)
- **Pre-period:** 2010-2015 (6 years)
- **Treatment periods:** 2017-2019 (cap period), 2020-2023 (post-repeal)

**Identifying assumption:** Uganda, Tanzania, Rwanda provide a valid counterfactual for Kenya's credit market trajectory absent the cap.

**Validation:** (1) Parallel pre-trends in credit/GDP 2010-2015; (2) No concurrent banking regulation changes in comparators; (3) Symmetric event study showing both cap (2016) and repeal (2019) effects.

### Design 2: Within-Kenya Symmetric Event Study
- Uses only Kenya data with cap (2016) and repeal (2019) as two shocks
- Tests for hysteresis: if the cap created persistent digital credit penetration, the repeal should not fully reverse formal credit recovery
- Uses quarterly CBK Monetary Policy Committee data on bank lending

### Design 3: FinTech Substitution (within-Kenya, county-level)
- Exploits cross-county variation in pre-cap bank branch penetration (bank branches/1000 adults by county)
- Counties with higher pre-cap bank access were more exposed to the cap
- Outcome: digital credit adoption from FinAccess 2016 and 2019 surveys

---

## Expected Effects and Mechanisms

1. **Formal credit rationing:** Cap reduces bank profitability for risky borrowers; banks ration SME credit. Credit/GDP falls.
2. **Digital substitution:** Excluded digital lenders (M-Shwari, Tala, Branch) fill the gap. Digital credit users rise 10x (200K → 2M) during cap period.
3. **Welfare concern:** Digital lenders charge ~7.5% per 30 days (90% APR). Substitution may increase over-indebtedness.
4. **Repeal reversal:** Bank lending rates fall back to market rates; formal credit recovers; digital credit growth slows.

**Key test:** If FinTech substitution is real, counties more exposed to banking (higher pre-cap penetration) should show greater digital credit adoption during the cap period relative to low-penetration counties.

---

## Primary Specification

**Main DiD (country level):**
```
Y_{ct} = alpha_c + gamma_t + beta_1 * (Kenya_c × Cap_t) + beta_2 * (Kenya_c × PostRepeal_t) + epsilon_{ct}
```
where Y = credit/GDP, c = country, t = year; Cap_t = 1 for 2017-2019; PostRepeal_t = 1 for 2020-2023.

**Event study (symmetric):**
```
Y_{ct} = alpha_c + gamma_t + sum_k [beta_k^cap * (Kenya_c × I(t = cap_year + k))] +
         sum_k [beta_k^repeal * (Kenya_c × I(t = repeal_year + k))] + epsilon_{ct}
```

**FinTech substitution (county level, FinAccess):**
```
Y_{it} = alpha_i + gamma_t + delta * (BankPen_i × Post2016_t) + controls + epsilon_{it}
```
where BankPen_i = pre-cap bank branch density by county, Y = digital credit adoption.

---

## Data Sources

1. **World Bank WDI:** Annual country-level data
   - `FS.AST.PRVT.GD.ZS` — domestic credit to private sector (% GDP)
   - `FR.INR.LEND` — lending interest rates
   - `FB.AST.NPER.ZS` — NPL ratios
   - `FB.CBK.BRCH.P5` — bank branches per 100K adults
   - Countries: KE, UG, TZ, RW; Years: 2010-2023
   - API: `https://api.worldbank.org/v2/`

2. **FinAccess Household Survey (Kenya):**
   - Waves: 2006, 2009, 2013, 2016, 2019 (2022 if available)
   - ~8,600 respondents per wave; county-level household finance module
   - Digital credit use, bank account ownership, over-indebtedness
   - Source: Harvard Dataverse (doi:10.7910/DVN/QUTLO2) and FSD Kenya website

3. **Central Bank of Kenya (CBK) Data:**
   - Monthly bank lending rates, credit growth, NPL ratios
   - Available from CBK statistical bulletin
   - URL: https://www.centralbank.go.ke/financial-sector-stability/financial-sector-statistics/

4. **FRED/IMF IFS:**
   - Backup for country-level monetary aggregates

---

## Primary Specification Notes

- Cluster standard errors at country level (4 clusters) — acknowledge small cluster concern; use wild-cluster bootstrap (cgmwildboot) or permutation tests
- For county-level FinAccess analysis: cluster at county level (~47 clusters)
- Use Callaway-Sant'Anna for staggered treatment if extending beyond 2 shocks
- For robustness: Synthetic Control Method with SSA donor pool (20+ countries)

---

## Phase Gate Check

- ≥20 treated units? YES for county-level FinAccess design (47 counties)
- ≥5 pre-periods? YES (2010-2015 for country DiD; 2006-2015 for FinAccess)
- No simulated data? CONFIRMED — World Bank WDI, FinAccess microdata, CBK statistics

---

## File Structure

```
output/apep_0702/v1/
├── research_plan.md
├── field_notes.md
├── paper.tex
├── paper.pdf
├── paper.bbl
├── timing.json
├── timing_data.tex
├── code/
│   ├── 00_packages.R
│   ├── 01_fetch_data.R
│   ├── 02_clean_data.R
│   ├── 03_main_analysis.R
│   ├── 04_robustness.R
│   └── 05_tables.R
├── data/
│   ├── wdi_raw.csv
│   ├── finaccess_county.csv
│   └── diagnostics.json
└── tables/
    ├── tab1_summary.tex
    ├── tab2_main_did.tex
    ├── tab3_eventstudy.tex
    ├── tab4_heterogeneity.tex
    └── tabF1_sde.tex
```
