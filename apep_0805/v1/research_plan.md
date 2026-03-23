# Research Plan: Burning by Permission

## Research Question
Does reducing tort liability for prescribed burning reduce destructive wildfire? States that shift from strict liability to simple or gross negligence for prescribed fire remove a key legal barrier to preventive burning. If liability reform increases prescribed burn activity, the resulting fuel load reduction should decrease subsequent wildfire frequency and severity.

## Identification Strategy
**Callaway-Sant'Anna (2021) staggered DiD.** Treatment is the state-level shift from strict liability to a less restrictive regime (simple negligence or gross negligence) for prescribed burning. States reform at different times from ~1990–2021, providing staggered adoption. Never-treated states (those retaining strict liability or with no prescribed fire statute) serve as the comparison group.

- **Unit:** State-year (primary panel); county-year (robustness)
- **Clustering:** State level
- **Estimator:** `did` R package (Callaway & Sant'Anna 2021)

## Expected Effects and Mechanisms
1. **Primary:** Reform → fewer wildfires, fewer acres burned, fewer large fires (>100 acres)
2. **Mechanism:** Reform → more prescribed burning acreage (NIFC data) → less fuel → fewer wildfires
3. **Heterogeneity:** Effects stronger on private land (liability reform affects private landowner incentives); weaker on federal/state land
4. **Placebo:** Lightning-caused fires on federal land should be unaffected by state tort reform

## Primary Specification
```
Y_{s,t} = ATT(g,t) via Callaway-Sant'Anna
```
Where Y is log(1 + wildfire count) or log(1 + acres burned) at the state-year level, treatment group g is the reform year, and ATTs are aggregated into an overall effect and event-study coefficients.

## Data Sources
1. **USDA FPA FOD 6th Edition** (Short 2022): 2.3M georeferenced wildfire records 1992–2020. SQLite download from USDA Research Data Archive (doi.org/10.2737/RDS-2013-0009.6). Key fields: STATE, FIRE_SIZE, STAT_CAUSE_DESCR, DISCOVERY_DATE.
2. **`daLaw` dataset** from R package `erer`: Classification of all 50 states' prescribed fire liability regimes (0=strict, 1=uncertain, 2=simple negligence, 3=gross negligence).
3. **NIFC prescribed fire statistics** (1998–2019): State-level prescribed burn acreage for mechanism test.
4. **PRISM climate data** (optional controls): State-year temperature and precipitation.

## Fetch Strategy
- FPA FOD: Download SQLite from USDA (~800MB). Extract state-year panel of wildfire counts and acres by cause.
- `daLaw`: Load directly from `erer` package in R. Cross-reference with legal literature for reform dates.
- NIFC: Publicly available prescribed fire acreage tables.

## Exposure Alignment
Treatment operates at the state level through tort reform affecting prescribed fire liability. The directly affected population is private landowners and land managers who make prescribed burning decisions based on legal risk. The outcome—wildfire frequency and severity—is measured at the same state level, ensuring alignment between treatment exposure and outcome measurement. Federal land fires serve as a within-state placebo because federal agencies are not subject to state tort law.

## Key Risks
1. **Reform date coding:** `daLaw` classifies current status but may not have exact reform dates. Will need to verify against legal sources (Cleaves & Haines 2002, Yoder 2008, NASF reports).
2. **FPA FOD reporting quality:** Reporting improved over time; must control for year FE and test for differential reporting trends.
3. **Confounds:** States reforming liability may also adopt other fire management policies. Will test for policy bundling.
