# Research Plan: Slower Mail, Fewer Voters

## Research Question

Did the closure and suspension of USPS post offices during the 2011–2017 Retail Access Optimization Initiative (RAOI) causally reduce voter turnout and mail-in ballot usage in affected counties?

## Policy Background

In 2011, facing a $20 billion deficit, the USPS launched the Retail Access Optimization Initiative (RAOI), proposing to close ~3,700 post offices. After public backlash and Congressional moratorium debates, ~650 offices were suspended and ~480 were permanently discontinued between 2011 and 2017. These closures disproportionately affected rural communities, removing the nearest point of postal access for millions of Americans.

## Identification Strategy

**Design:** Staggered difference-in-differences exploiting county-level variation in the timing and intensity of post office closures during 2011–2017.

**Treatment:** Binary indicator for counties that lost at least one post office, with continuous treatment intensity measured as the share of the county's pre-period post offices that were discontinued. Treatment timing is determined by the year the first post office in the county was discontinued.

**Estimator:** Callaway and Sant'Anna (2021) for heterogeneity-robust staggered DiD. Sun and Abraham (2021) as robustness check.

**Control group:** Counties that never lost a post office during the sample period (never-treated).

**Pre-trends:** 2004–2010 EAVS waves (3–4 pre-treatment election cycles) provide basis for parallel trends assessment.

## Expected Effects and Mechanisms

1. **Mail-in ballot usage (primary):** Negative. Losing a post office increases the cost of mailing ballots — longer drive to the next post office, reduced mailbox collection. This is the most direct mechanism.
2. **Voter turnout (secondary):** Negative but smaller. Most voters use in-person polling, so the turnout effect may be concentrated among mail-in voters.
3. **Voter registration:** Potentially negative. Some voters register by mail; losing postal access may reduce registration flows.

**Heterogeneity predictions:**
- Larger effects in rural counties (fewer alternative postal access points)
- Larger effects in states with high pre-treatment mail-in ballot usage
- Smaller effects in states with universal vote-by-mail (ballots delivered to voters)

## Data Sources

1. **USPS Post Office Closures:** HIFLD (Homeland Infrastructure Foundation-Level Data) post office database and/or USPS Postal Bulletin discontinuance notices, mapped to counties via ZIP-county crosswalks.
2. **Election Outcomes:** MIT Election Lab county-level presidential and congressional returns (2000–2024) for turnout.
3. **EAC EAVS:** Election Administration and Voting Survey, county-level biennial data (2004–2024) on voter registration methods, mail ballots transmitted/returned/rejected, turnout by mode.
4. **Census ACS:** County-level controls — population, median income, % rural, % age 65+, % non-white, internet access rates.

## Primary Specification

Y_{ct} = α_c + α_t + β · D_{ct} + X_{ct}γ + ε_{ct}

Where:
- Y_{ct}: outcome (turnout rate, mail-in ballot share) for county c in election year t
- α_c, α_t: county and year fixed effects
- D_{ct}: treatment (post office closed in county c by year t)
- X_{ct}: time-varying controls
- Standard errors clustered at state level

## Robustness Checks

1. Event study plot (dynamic treatment effects)
2. HonestDiD / Rambachan-Roth sensitivity analysis for parallel trends violations
3. Placebo: urban counties with many post offices (diluted treatment)
4. Leave-one-out state analysis
5. Continuous treatment intensity (share of offices closed)
6. Bacon decomposition to check weight on clean comparisons
7. Wild cluster bootstrap (if state clusters < 50 effective)

## Sample Size Targets

- ~3,100 counties × 11 EAVS waves = ~34,000 county-election observations
- Treated counties: ~400–500 (counties that lost at least one post office)
- Pre-treatment periods: 4 waves (2004, 2006, 2008, 2010)
- Post-treatment periods: 4–7 waves (2012–2024)

## Exposure Alignment

The unit of treatment assignment is the county-NAICS level as recorded in the QCEW. Treatment is defined as a net loss of at least one USPS establishment (NAICS 491110, ownership code 1) between 2014 and 2018. The treated population consists of all voters residing in counties that lost postal infrastructure. The mechanism operates through reduced physical access to postal services — specifically, the loss of locations where voters can mail ballots, purchase stamps, or access registration materials. Treatment intensity varies: some counties lost one office, others lost multiple. The key exposure question is whether voters in treated counties actually experienced reduced postal access, or whether nearby offices absorbed the demand. Since RAOI closures targeted offices with proximity to alternatives, the treatment is likely attenuated — voters in most affected communities retained postal service within a few miles.

## Feasibility Risks

1. **USPS closure data availability:** May need to compile from multiple sources. If programmatic access fails, idea resolves as failed.
2. **County mapping:** ZIP-to-county crosswalk introduces measurement error for multi-county ZIPs.
3. **Biennial frequency:** Treatment timing granularity limited to 2-year windows.
4. **Mail-in ballot expansion:** COVID-19 massively expanded mail-in voting post-2020, potentially confounding later periods. Will test robustness to excluding 2020+ waves.
