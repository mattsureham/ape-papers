# Research Plan: apep_0715

## Research Question
Did the UK's April 2019 reduction of Fixed-Odds Betting Terminal (FOBT) maximum stakes from £100 to £2 reduce gambling-related harm, or did it merely displace gambling activity from land-based to online channels?

## Identification Strategy
**Continuous-treatment DiD with common treatment timing.** The FOBT stake reduction was a national policy taking effect 1 April 2019. However, it bit harder in Local Authorities with higher pre-reform FOBT density (betting premises per 10,000 population). We exploit this cross-LA variation in treatment intensity:

Y_{it} = α_i + γ_t + β × (FOBT_density_i × Post_t) + ε_it

where FOBT_density_i is the pre-reform (March 2019) number of betting premises per 10,000 adults in LA i.

**Key identifying assumption:** Absent the stake reduction, outcomes in high-FOBT-density and low-FOBT-density LAs would have followed parallel trends. Testable in the 16-quarter pre-period (2015Q1-2018Q4).

## Expected Effects and Mechanisms
1. **First stage:** Betting shop closures — FOBTs generated ~50% of bookmaker revenue. The £2 cap destroyed the product's viability, triggering closures concentrated in high-density LAs.
2. **Direct effect on gambling supply:** Fewer premises = fewer opportunities for impulse land-based gambling.
3. **Substitution channel:** Displaced gamblers may shift to online platforms, potentially increasing online gross gambling yield.
4. **Net welfare:** If online substitution is complete, the policy merely changed the venue, not the harm.

## Primary Specification
- **Unit:** Local Authority × quarter
- **Treatment intensity:** Pre-reform betting premises per 10,000 adults (continuous)
- **Pre-period:** 2015Q1–2018Q4 (16 quarters)
- **Post-period:** 2019Q2–2020Q1 (3 clean quarters before COVID disruption; Q1 2020 is partial)
- **Outcomes:** (1) Number of betting premises, (2) Number of gaming machines, (3) Gross gambling yield from betting premises
- **Fixed effects:** LA + quarter
- **Clustering:** LA level (~380 clusters)
- **Robustness:** Event study specification, dose-response bins (terciles/quartiles of FOBT density), permutation inference

## Data Source and Fetch Strategy
1. **Gambling Commission Industry Statistics:** Quarterly LA-level data on betting premises, gaming machine counts, and gross gambling yield. Published as downloadable Excel/CSV from the Gambling Commission website.
2. **ONS mid-year population estimates:** LA-level adult population for normalization.
3. **UK Police API:** LA-level crime data for secondary outcomes (anti-social behavior near betting shops).

## Exposure Alignment
The FOBT stake reduction applied exclusively to Category B2 gaming machines. B2 machines operated only in licensed betting premises (not in casinos, bingo halls, or arcades). The treated sector (betting) is therefore perfectly aligned with treatment exposure: 100% of betting premises hosted B2 machines, while 0% of control sector premises did. Over-the-counter betting within the same premises serves as an internal placebo — it is produced by the same firms in the same locations but is mechanically unaffected by the machine stake limit. This decomposition tests whether the GGY decline reflects the B2 channel specifically or a broader demand shock to betting shops.

## Key Risks
- COVID truncates the clean post-period to ~3 quarters
- Sector-level design has only 4 cross-sectional units (limited power for formal inference)
- Online gambling data is industry-level, not LA-level (limits substitution analysis)
