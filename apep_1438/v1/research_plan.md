# Research Plan: The Welfare Cost of Pay-to-Play

## Question
Does electing mayors whose campaigns are financed by donors with strong contractor ties degrade the quality of municipal public services — measured by student test scores — in Colombia?

## Setting
1,102 Colombian mayors elected October 2019, took office January 1, 2020, three-year term, no reelection. Mayors control municipal procurement (≈70-80% direct-award contracts) and influence local education spending.

## Identification
**Difference-in-differences with continuous treatment intensity.** For each municipality, we measure ex-post donor capture: the share of post-election (2020-2022) municipal contract value awarded to firms/individuals whose cedulas appear in the elected mayor's 2019 donor list. We then estimate two-way fixed-effects panel regressions of municipal mean Saber 11 scores on this treatment intensity (continuous) interacted with a post-2019 indicator, with municipality and cohort-year fixed effects.

Identifying assumption: parallel pre-trends in test scores between high- and low-donor-capture municipalities prior to the 2019 election. We test this with an event-study (cohort 2013-2022, treatment = post-2019 × donor-capture intensity) and verify pre-period coefficients are statistically indistinguishable from zero.

(Note: vote-margin RDD was infeasible because Registraduría municipal vote totals are not posted on the open Socrata catalog; only the list of elected mayors is. We retain elected-mayor identification with the DiD design.)

## Outcomes
- Primary: ICFES Saber 11 `punt_global` (mean municipal score), 2013-2022, with treatment cohort 2020-2022.
- Secondary: `punt_matematicas`, `punt_lectura_critica`.

## Specifications
1. Local-linear RDD via `rdrobust::rdrobust` with triangular kernel, MSE-optimal bandwidth (Calonico-Cattaneo-Titiunik).
2. Two-way fixed-effects DiD as a robustness check on the full sample (treated municipalities = donor-connected winner).
3. Event-study on cohort year (2013-2022) interacted with treatment.

## Data
- **Cuentas Claras 2019** (Socrata `8yi3-eb8u` donors and `iqsc-y9rb` candidates) — donor cedulas linked to candidates.
- **SECOP II** (`jbjy-vk9h`) contracts 2020-2022 with `documento_proveedor` = cedula.
- **ICFES Saber 11** (`kgxf-xxbe`) 2013-2022 student records.
- **MOE / Registraduría 2019 mayoral elections** — vote totals by candidate by municipality.

All Colombian datasets are open Socrata, no auth required.

## Sample
948 of 1,100 elected mayors matched to Cuentas Claras donor file via fuzzy name match within municipality. 48 treated municipalities (5.07%). Pre-periods: 6 cohorts (2014-2019). Post-periods: 3 cohorts (2020-2022).

## Exposure alignment
The treatment is the elected mayor's *de facto* governance choice; the unit of treatment is the municipality. The cohort-level outcome (Saber 11 scores) reflects students who lived under the mayor's administration during their final years of secondary school. Cohorts 2020-2022 are 11th-graders whose entire 11th-grade year (and earlier years for 2021-2022 cohorts) was administered under the elected mayor; they are the directly exposed units. We do not assume the policy reached every student in the muni equally — the relevant exposure is the muni-level resource allocation flowing through the mayor's procurement decisions, which the test-score panel captures as a weighted municipality-level mean. Pre-2020 cohorts in the same munis serve as the within-unit baseline, and untreated munis serve as the across-unit control.

## Hard rules satisfied
Real API data only; R for econometrics; close-election RDD has well-known credibility (Lee 2008; Gulzar et al. 2022 AJPS).
