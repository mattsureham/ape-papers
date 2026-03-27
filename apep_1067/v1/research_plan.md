# Research Plan: The Bridge to Funding

## Research Question

Do U.S. states strategically manipulate bridge sufficiency ratings to qualify for federal replacement funding, and did the elimination of the sufficiency-based funding formula under MAP-21 (2012) reduce this manipulation?

## Identification Strategy

**Primary: Bunching estimation** (Kleven 2016) at the SR=50 threshold in the National Bridge Inventory. Bridges with SR<50 qualify for federal replacement funding under the Highway Bridge Program (HBP); SR≥50 receive only rehabilitation or no funding. If states strategically deflate ratings, we expect excess mass just below 50 and a deficit just above.

**Difference-in-bunching:** MAP-21 (signed July 2012, effective October 2012) eliminated the HBP and folded bridge funding into the NHPP, which uses a structurally-deficient deck-area trigger rather than SR<50. This weakened the SR<50 incentive. If bunching is strategic, it should attenuate post-2012.

**Placebos:**
1. No bunching at SR=80 (rehabilitation threshold — confirmed in smoke test)
2. No bunching at SR=60, 70 (no policy thresholds)
3. Owner heterogeneity: state DOT bridges (more sophisticated, more federal dependency) should show more bunching than locally-owned bridges

**Cross-sectional heterogeneity:** States with higher HBP dependency should show more bunching.

## Expected Effects and Mechanisms

- **Excess mass below SR=50:** States have incentive to rate bridges just below 50 to access replacement funding. The sufficiency rating has subjective components (serviceability, essentiality) that allow discretion.
- **Bunching attenuation post-MAP-21:** With the SR<50 threshold weakened, the incentive to manipulate diminishes.
- **State DOT bridges show more bunching:** Professional highway agencies are more sophisticated at gaming the formula.

## Primary Specification

Bunching estimator (polynomial counterfactual) at SR=50. Estimate excess mass B̂ = (observed count in bunching region − counterfactual count) / counterfactual count. McCrary (2008) density test as formal statistical test.

Difference-in-bunching: compare B̂ pre-MAP-21 (1992-2012) vs post-MAP-21 (2013-2018).

## Data Source and Fetch Strategy

**National Bridge Inventory (NBI):** Annual delimited text files from FHWA, 1992-2018. ~620,000 bridges/year. Key fields: STRUCTURE_NUMBER (panel ID), STATE_CODE, SUFFICIENCY_RATING, OWNER (state DOT vs local), YEAR_BUILT, ADT (average daily traffic), DECK_COND, SUPERSTRUCTURE_COND, SUBSTRUCTURE_COND.

**Fetch strategy:** Download state-year delimited files from `https://www.fhwa.dot.gov/bridge/nbi/{YEAR}/delimited/{ST}{YY}.txt`. Parse and stack into a single panel. Focus on years 2000-2018 for main analysis (pre-period: 2000-2012, post-period: 2013-2018).

Note: SUFFICIENCY_RATING was dropped from NBI files in 2019, limiting post-period to 6 years.
