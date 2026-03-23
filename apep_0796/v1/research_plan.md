# Research Plan: apep_0796

## Research Question

Did Switzerland's 2012 Second Home Initiative — which banned new second-home construction in municipalities exceeding a 20% second-home share — actually convert housing stock from vacation to permanent use? While Hilber and Schoni (2020, JUE) documented that the policy reduced house prices by 15%, whether the ban achieved its stated compositional objective remains untested. We exploit the sharp 20% regulatory threshold in a regression discontinuity design using the federal housing inventory (Zweitwohnungsinventar), first published in 2017.

## Identification Strategy

**Sharp RDD at the 20% second-home share threshold.** Municipalities above 20% are banned from authorizing new second homes; those below face no restriction. The running variable is measured to two decimal places by the federal government. We estimate:

Y_m = α + τ · 1(SecondHomeShare_m > 20%) + f(SecondHomeShare_m) + X_m'β + ε_m

where Y_m is the change in primary-home share (ZWG_3110) between the earliest available inventory wave and the latest.

**Panel RDD extension:** With 16 semi-annual waves (2017-2025), we estimate dynamic effects to test whether conversion accelerated over time.

**Key checks:**
- McCrary density test at 20% threshold
- Covariate balance (population, altitude, language region, canton)
- Bandwidth sensitivity (Calonico-Cattaneo-Titiunik optimal, plus 2pp and 5pp windows)
- Placebo thresholds at 15%, 25%
- Donut hole excluding municipalities at exactly 20%

## Expected Effects and Mechanisms

**Theory predicts ambiguous sign:**
- **Conversion channel:** If ban prevents new second homes, existing vacation units may convert to primary use as permanent demand absorbs restricted supply → primary share increases above threshold
- **Vacancy trap:** If tourist municipalities lack permanent employment, restricted units may simply go vacant → no change in primary share, but increase in empty dwellings
- **Spatial substitution:** Developers redirect construction to municipalities just below 20% → primary share effect may be diluted

**A null result is scientifically valuable** — it would demonstrate that supply restrictions fail to achieve compositional change in housing markets lacking permanent-resident demand.

## Primary Specification

Local linear regression with triangular kernel, CCT-optimal bandwidth. Outcome: change in primary-home share (ZWG_3110) from 2017H1 to 2025H1. Running variable: second-home share as of the earliest inventory wave.

## Data Source and Fetch Strategy

1. **Federal Housing Inventory (Zweitwohnungsinventar):** geo.admin.ch STAC API. 2,131 municipalities × 16 semi-annual waves (2017-2025). Key variables: ZWG_3110 (primary home %), ZWG_3120 (secondary home %). Free, no authentication.

2. **Municipal characteristics:** BFS PXWeb API (population, surface area, language region, altitude). Free, no authentication.

3. **Empty dwelling rates:** BFS table px-x-0902030000_103 or similar. Municipal level.

4. **Referendum vote share:** March 11, 2012 municipal-level vote results from swissvotes or BFS. Useful for mechanism test.

## Key Risk

The housing inventory only starts in 2017, five years after the 2012 vote (and one year after the 2016 ZWG enforcement). We observe the stock composition but not the transition path. If conversion happened quickly (2012-2016) and stabilized by 2017, we may detect smaller effects. The panel RDD across 2017-2025 waves mitigates this by testing for continuing adjustment.
