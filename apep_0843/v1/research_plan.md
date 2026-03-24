# Research Plan: Notarize This — RON Laws and New Business Formation

## Research Question

Do Remote Online Notarization (RON) laws increase new business formation? Specifically, does removing the in-person notarization requirement for business filings reduce a bureaucratic friction that constrains entrepreneurship?

## Background

Remote Online Notarization allows notarial acts via audio-video technology without physical co-presence. Virginia was first to authorize RON permanently (2012), followed by staggered adoption across ~22 states by end-2019. COVID prompted temporary emergency RON in 20+ additional states (excluded from primary specification to avoid confounding).

Business incorporation, LLC formation, and real estate transactions often require notarized documents. In-person notarization imposes scheduling costs, geographic frictions, and time costs that may disproportionately burden would-be entrepreneurs, especially in rural areas or those with time constraints.

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered difference-in-differences.** Treatment: state j adopts permanent RON law at time t. Control: never-treated states (those without permanent RON through 2019) and not-yet-treated states.

**Treatment cohorts (5):**
- 2012: Virginia
- 2015: Montana
- 2017: Texas, Nevada
- 2018: Indiana, Ohio, Michigan, Minnesota, Tennessee, Vermont
- 2019: Arizona, Florida, Idaho, Iowa, Kentucky, Maryland, Nebraska, North Dakota, Oklahoma, South Dakota, Utah, Washington

**Key advantages:**
- 22 treated states vs ~29 never-treated — well-powered
- Monthly data from July 2004 — 7-15 years pre-treatment per cohort
- Callaway-Sant'Anna handles heterogeneous treatment effects and forbidden comparisons

## Expected Effects and Mechanisms

**Primary hypothesis:** RON reduces transaction costs for business formation → positive effect on new business applications.

**Mechanism tests:**
1. Corporate BA (notarization-intensive: articles of incorporation typically require notarization) should respond more than High-Propensity BA or BA with Planned Wages (where notarization is one of many frictions)
2. Heterogeneity by pre-RON notarization stringency (states with more in-person requirements should see larger effects)

**Expected magnitude:** Small positive (SDE 0.005-0.05). Notarization is one friction among many in business formation. The smoke test showed Virginia's +4.4% raw increase post-RON, though this is before controlling for trends.

## Primary Specification

Y_{s,t} = Business Applications (BA) for state s in month t

ATT(g,t) estimated via Callaway-Sant'Anna with:
- Group: year-month of permanent RON adoption
- Time: year-month
- Control: never-treated states
- Covariates: none in baseline (event-study balance will validate)
- Clustering: state level
- Aggregation: simple weighted average across groups and time

## Exposure Alignment

**Who is treated:** All prospective business founders in states that adopted permanent RON laws. The treatment removes the in-person notarization requirement, which applies to state corporate filings (articles of incorporation, operating agreements, real property transfers). The relevant margin is anyone who needs notarized documents to complete a business formation.

**Alignment with outcome:** The BFS measures federal EIN applications (all new business registrations with the IRS). While EIN applications themselves do not require notarization, EIN timing tracks closely with state incorporation decisions. Corporate BA (CBA) is the closest proxy for notarization-intensive filings. The analysis examines all four BFS series to test whether the effect varies by notarization intensity.

**Treatment intensity:** Binary (state adopted or not). No continuous measure of notarization burden is available at the state level, so heterogeneity by stringency is tested via early vs. late adopter splits rather than cross-sectional notarization intensity.

## Robustness Checks

1. **Pre-trend event study:** Dynamic ATT(g,t) plotted for 36 months pre/post
2. **Alternative control group:** Not-yet-treated vs never-treated
3. **Leave-one-out:** Drop each treatment cohort iteratively
4. **Placebo outcome:** All Business Applications vs Corporate BA differential
5. **COVID exclusion:** Primary spec ends December 2019; robustness extends to 2023
6. **Wild cluster bootstrap:** Given 51 clusters, WCB for inference
7. **HonestDiD/Rambachan-Roth:** Sensitivity to violations of parallel trends

## Data Source and Fetch Strategy

**Source:** Census Bureau Business Formation Statistics (BFS) via FRED API

**Series (per state, 51 jurisdictions):**
- `BABATOTALSAXX` — Business Applications (BA)
- `BAHBATOTALSAXX` — High-Propensity Business Applications (HBA)
- `BAWBATOTALSAXX` — Business Applications with Planned Wages (WBA)
- `BACBATOTALSAXX` — Business Applications from Corporations (CBA)

Where XX is the 2-letter state FIPS code.

**Period:** July 2004 – December 2019 (pre-COVID primary), extended to latest for robustness.

**Treatment dates:** Compiled from National Notary Association, Notarize.com legal tracker, and state legislative records.

## Output Files

- `code/00_packages.R` — Library loading
- `code/01_fetch_data.R` — FRED API data acquisition
- `code/02_clean_data.R` — Panel construction, treatment assignment
- `code/03_main_analysis.R` — CS-DiD estimation, event studies
- `code/04_robustness.R` — Robustness checks
- `code/05_tables.R` — Table generation including SDE appendix
