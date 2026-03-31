# Research Plan: Unleashing Anesthesia — CRNA Opt-Out and Ambulatory Health Care Labor Markets

## Research Question

Does removing physician supervision requirements for Certified Registered Nurse Anesthetists (CRNAs) expand ambulatory health care employment and restructure the health care labor market?

## Policy Background

In November 2001, CMS finalized a Medicare Conditions of Participation rule requiring physician supervision of CRNAs in hospitals and ambulatory surgical centers. The rule included a governor opt-out provision (42 CFR 482.52, 485.639). States adopted opt-out in staggered waves:

- **Wave 1 (2001-02):** IA, NE, ID, MN, NH
- **Wave 2 (2003):** KS, ND, WA, AK, OR
- **Wave 3 (2004-05):** MT, SD, WI
- **Wave 4 (2008-12):** CA, CO, KY
- **Wave 5 (2016-24):** AZ, OK, MA, and others

25+ states opted out; 25+ never did (NY, PA, OH, GA, FL, TX, IL, NJ, MI, VA).

## Identification Strategy

**Staggered Difference-in-Differences** using Callaway and Sant'Anna (2021) heterogeneity-robust estimator.

- **Treatment:** State-level CRNA supervision opt-out
- **Treated units:** 25+ states across 5+ adoption waves
- **Control units:** Never-opt-out states
- **Pre-periods:** 10+ years (1990s-2001)
- **Estimand:** ATT on ambulatory health care employment for BA+ workers

**Triple-difference (DDD):**
(Ambulatory [621] − Hospital [622]) × (Opt-out − Never) × (Post − Pre)

## Expected Effects and Mechanisms

If physician supervision requirements constrain CRNA practice:
1. Opt-out → more independent CRNA practice in ambulatory settings
2. → increased ambulatory care employment (BA+ education group)
3. → possible shift from hospital to ambulatory settings
4. → no effect on non-health-care sectors (placebo)

**Mechanism:** "Scope-of-practice dividend" — removing supervisory mandates unlocks existing clinical capacity, allowing CRNAs to practice at the top of their license.

## Primary Specification

Y_{s,t} = α_s + γ_t + β · OptOut_{s,t} + ε_{s,t}

where Y is log employment of BA+ workers in NAICS 621 (Ambulatory), α_s are state FEs, γ_t are quarter FEs.

Using Callaway-Sant'Anna with not-yet-treated as control group.

## Data Sources

1. **QWI (Quarterly Workforce Indicators):** Azure Parquet files
   - Path: `derived/qwi/se/n3/*.parquet`
   - Demographics: sex × education
   - Industry: 3-digit NAICS (621, 622, 623)
   - Geography: state-level
   - Period: 2001-2025 (quarterly)
   - Key variables: Emp (employment), EarnS (earnings), HirA (hires)

2. **CRNA Opt-Out Dates:** Hand-coded from CMS records and AANA (American Association of Nurse Anesthesiology) tracking

## Placebos and Robustness

1. **Industry placebo:** NAICS 623 (Nursing and Residential Care) — no CRNA activity
2. **Education placebo:** Workers without BA+ (E1/E2) — not CRNAs
3. **Event study:** Pre-trend visualization with HonestDiD bounds
4. **Leave-one-out:** Drop each wave sequentially
5. **Border-pair design:** County-level pairs at state borders (if sample size sufficient)

## Outcome Variables

- **Primary:** Log employment of BA+ workers in NAICS 621
- **Secondary:** Log earnings, new hires, separations in NAICS 621 (BA+)
- **DDD:** (621 − 622) × treatment interaction
- **Heterogeneity:** Rural vs urban states, early vs late adopters

## Feasibility Assessment

- **Variation:** 25+ treated states in 5+ waves — well above the 20-unit threshold
- **Data:** QWI on Azure, confirmed available
- **Novelty:** Zero APEP papers on CRNA/anesthesia; novel angle vs Sun (2020 JHE) which studied safety, not labor markets
- **Sample:** 5,678 state-quarter observations per sector-education cell
