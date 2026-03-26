# Research Plan: The Domestic Toll of Aid Dismantlement

## Research Question

Did the sudden 2025 USAID contract terminations reduce employment in US counties with high USAID contractor concentration? What is the implied local employment multiplier of foreign aid procurement spending?

## Background

The Trump administration terminated 83% of USAID contracts ($54B) between January and July 2025, culminating in USAID's formal closure on July 1, 2025. Major prime contractors (Chemonics, DAI, Abt Associates, FHI 360, AECOM) are geographically concentrated in specific US counties, primarily in the DC metropolitan area but also across 46 states. This creates a sharp, quasi-exogenous employment shock whose geographic incidence is determined by pre-shock contractor locations — a classic shift-share/Bartik design.

## Identification Strategy

**Design:** Shift-share / Bartik-style DiD exploiting pre-determined geographic variation in USAID contract concentration.

- **Treatment intensity:** County-level USAID prime contract dollars (2022-2024 average) normalized by county employment, from USASpending.gov bulk data.
- **Outcome:** QWI county × quarter employment (Emp, HirN, Sep, EarnS) in NAICS 54 (Professional/Technical Services) and total private sector.
- **Event study:** Quarterly leads/lags around January 2025 shock, with 16 pre-periods (2021Q1–2024Q4).
- **Identifying assumption:** Pre-shock USAID contract intensity is uncorrelated with county-level employment trends, conditional on county and time fixed effects. Plausible because USAID contractor locations were determined by firm-specific factors (DC proximity, historical government ties) unrelated to local labor trajectories.

**Key threats and responses:**
1. DC metro confounding (broader federal cuts): Include DMV indicator, federal employment share control; estimate excluding DC-VA-MD.
2. Selection on pre-trends: Formal parallel trends test with 12+ quarterly leads.
3. Direct vs. multiplier: Separate NAICS 54 (direct contractor employment) from NAICS 44-45 and 72 (downstream spending multiplier).

**Mechanism tests:**
- Hiring freeze (HirN decline) vs. layoffs (Sep spike) decomposition
- Spillovers to local consumer services (NAICS 72: accommodation/food)
- Income channel: EarnS × employment loss = county-level income impact

## Data Sources

1. **QWI (Azure):** `az://apepdata/derived/qwi/sa/ns/*.parquet` — county × quarter × NAICS sector employment, 2001–2025Q2. Confirmed available with Emp, HirN, Sep, EarnS columns.
2. **USASpending.gov:** Bulk download of USAID prime contracts 2020-2024. Fields: `recipient_county_fips`, `total_obligation`, `awarding_agency_name`. Public, no authentication.

## Primary Specification

```
Y_{c,t} = α_c + γ_t + β × (USAIDIntensity_c × Post_t) + X_{c,t}δ + ε_{c,t}
```

Where USAIDIntensity_c = avg USAID contract $/county employment (2022-2024), Post_t = 1(t ≥ 2025Q1).

Event study version with quarterly leads/lags for parallel trends visualization.

Clustering: State level (robust to county-level clustering).

## Expected Effects

- **NAICS 54 employment:** Negative in high-exposure counties (professional services layoffs/hiring freeze)
- **Local multiplier:** Smaller negative spillover to NAICS 72, 44-45
- **Mechanism:** Primarily hiring freeze (HirN decline) rather than mass layoffs (Sep spike), given contract wind-down timeline
- **Magnitude:** Smoke test suggests -12.2% aggregate NAICS 54 decline; county-level variation by USAID exposure is the identifying variation

## Output Plan

- Table 1: Summary statistics (treatment/control counties)
- Table 2: Main DiD results (NAICS 54, total private)
- Table 3: Mechanism decomposition (hires vs. separations)
- Table 4: Robustness (excl. DMV, alt. treatment measures, wild bootstrap)
- Table F1: SDE appendix
