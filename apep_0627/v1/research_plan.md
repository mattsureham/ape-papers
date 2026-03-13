# Research Plan: Speed Kills Less at 20mph

## Research Question

Does Wales's nationwide reduction of the default urban speed limit from 30mph to 20mph reduce road casualties? We provide the first rigorous causal evaluation of this policy using the England-Wales border as identification.

## Policy Background

On September 17, 2023, Wales became the first nation in the UK to lower the default speed limit on restricted roads (those with street lighting in built-up areas) from 30mph to 20mph, under the Restricted Roads (20mph Speed Limit) (Wales) Order 2022. England retained the 30mph default throughout. This creates a sharp temporal break and a natural cross-border counterfactual.

## Identification Strategy

**Primary: Cross-border Difference-in-Differences**

- **Treated units:** 22 Welsh Local Authorities (all treated simultaneously on September 17, 2023)
- **Control units:** ~300+ English Local Authorities (retained 30mph default)
- **Pre-period:** January 2018 – August 2023 (68 months, excluding COVID months March 2020 – June 2021)
- **Post-period:** September 2023 – December 2024 (16 months)
- **Level:** LA-month collision counts
- **Estimator:** Standard TWFE DiD (single treatment date, no staggering)
- **Key assumption:** Parallel trends in Welsh and English LA-level collision counts pre-September 2023

**Specification:**
Y_it = α_i + δ_t + β·(Welsh_i × Post_t) + ε_it

Where Y_it is the collision count (or log), α_i are LA fixed effects, δ_t are month fixed effects, and Welsh_i × Post_t is the treatment indicator.

## Expected Effects and Mechanisms

- **Speed reduction → reduced collision frequency:** Lower speeds give drivers more time to react and avoid collisions entirely.
- **Speed reduction → reduced severity conditional on collision:** Physics: kinetic energy scales with v². A pedestrian hit at 20mph has ~5% fatality risk vs ~45% at 30mph.
- **Therefore:** We expect effects concentrated in severity (KSI reduction > total collision reduction) and in pedestrian casualties.

## Primary Specification

1. **Total collisions per LA-month** (extensive margin)
2. **KSI (killed or seriously injured) per LA-month** (severity margin — expected main result)
3. **Pedestrian KSI per LA-month** (mechanism: pedestrians are the primary beneficiaries of lower speeds)

## Exposure Alignment

The treatment (Wales's 20mph default) applies to all restricted roads in Wales, affecting every road user on those roads. The outcome (collision counts by LA-month) captures all police-reported personal-injury collisions in each LA, which includes collisions on both treated (restricted/20mph) and untreated (high-speed) roads. This creates a potential misalignment: the outcome includes collisions on roads where the speed limit did not change. We address this by: (1) decomposing collisions by road speed limit (restricted vs. high-speed) to isolate the treated margin, (2) using the high-speed road outcome as a falsification test, and (3) constructing a pedestrian-specific KSI measure that focuses on the population most directly affected by lower urban speeds.

## Robustness

1. **Border LAs only:** Restrict to Welsh LAs bordering England and English LAs bordering Wales (~12 LAs total)
2. **Event study:** Month-by-month coefficients to verify parallel trends and trace out dynamic effects
3. **Severity decomposition:** Fatal, serious, slight separately
4. **Placebo test:** Pseudo-treatment date of September 2022 (one year earlier)
5. **Poisson regression:** Count data model as alternative to OLS on levels/logs
6. **Exclude London:** London's unique traffic patterns may distort the English control group

## Data Source and Fetch Strategy

- **STATS19 collision data:** Annual CSVs from data.dft.gov.uk. Download 2018–2024. Each record has: severity, date, coordinates, police force, LA code (ONS), speed limit, road type, vehicle/casualty details.
- **R package:** `stats19` (rOpenSci) for automated download
- **Welsh LAs identified by:** W-prefix on ONS LA codes (e.g., W06000001–W06000024) and police force codes 60–63
- **Sample size:** ~130,000 GB collisions/year; ~5,000–6,000 in Wales. At LA-month level: ~350 LAs × 84 months ≈ 29,400 LA-month observations.
