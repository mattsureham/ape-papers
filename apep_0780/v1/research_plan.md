# Research Plan: Last Orders for Crime?

## Research Question

Do alcohol licensing restrictions reduce violent crime? We exploit the April 2018 statutory strengthening of Cumulative Impact Assessments (CIAs) in England, which gave 107 licensing authorities a rebuttable presumption against new alcohol license applications in designated zones.

## Identification Strategy

**Binary difference-in-differences.**

- **Treated:** 107 Local Authorities that had adopted CIAs by April 2018 (received statutory backing via Policing and Crime Act 2017, §141)
- **Control:** 231 Local Authorities without CIAs
- **Pre-period:** Financial years 2013/14–2017/18 (5 years)
- **Post-period:** Financial years 2018/19–2023/24 (6 years)

## Exposure Alignment

**Who is affected:** Licensed premises and applicants in CIA zones face a rebuttable presumption of refusal for new or varied licenses. The statutory strengthening gave these policies legal force — previously, CIAs were advisory statements published under non-statutory guidance. After April 2018, applicants bore the burden of proving their premise would not add to cumulative impact.

**Control group exposure:** LAs without CIAs experienced no change in their licensing framework. The Licensing Act 2003 continued to apply identically. Common macroeconomic shocks (austerity, COVID, cost-of-living) affect both groups symmetrically.

**Why CIA adoption is plausibly exogenous to crime trends:** LAs adopted CIAs in response to cumulative alcohol-related issues in specific zones, not in anticipation of future crime trends. The statutory strengthening was a national legislative event applied uniformly to all existing CIAs — the timing was determined by Parliament, not by individual LAs.

## Expected Effects

**Theoretical prediction:** Restricting new alcohol outlet density should reduce alcohol-fueled crime through two channels:
1. **Availability channel:** Fewer outlets → less access → less consumption → less violence
2. **Competition channel:** Fewer outlets → less price competition → higher prices → less consumption

**Expected direction:**
- Violent crime: negative (reduction)
- Anti-social behaviour: negative (reduction)
- Bicycle theft (placebo): null
- Vehicle crime (placebo): null

## Data Sources

1. **Crime data:** Home Office Police Recorded Crime by CSP, 2013/14–2023/24. Downloadable ODS files from gov.uk. Violent crime, sexual offences, robbery, public order, ASB.

2. **CIA adoption status:** Home Office Alcohol and Late Night Refreshment Licensing Statistics, Table 5. Lists LAs with CIAs and adoption dates.

3. **Licensed premises counts:** Home Office Table 1. Number of premises licenses by LA and year.

## Primary Specification

$$Y_{it} = \beta \cdot \text{CIA}_i \times \text{Post}_t + \alpha_i + \gamma_t + \varepsilon_{it}$$

Where $i$ = LA, $t$ = financial year, $\text{CIA}_i$ = 1 if LA had a CIA by March 2018, $\text{Post}_t$ = 1 for 2018/19 onward. Clustered at LA level.
