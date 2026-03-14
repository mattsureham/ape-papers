# Research Plan: The MATS Compliance Bifurcation

## Research Question
How did the Mercury and Air Toxics Standards (MATS, 2012-2015) affect local labor markets through coal plant retirement decisions? Specifically: what predetermined generator characteristics predict retirement vs. investment, and what are the downstream employment effects in coal-plant communities?

## Policy Setting
MATS was finalized February 16, 2012 (77 FR 9304), with compliance required by April 16, 2015 (extensions to April 2016 available). Every coal-fired generator ≥25 MW had to either: (a) install activated carbon injection (ACI) or other pollution controls (~$5.8M/unit), or (b) retire. Approximately 87 GW installed controls while ~20 GW retired — a ~19% retirement rate by capacity. This binary compliance decision creates a natural experiment for studying managed industrial decline.

## Identification Strategy

### Generator-Level First Stage
Model the retirement decision as a function of pre-MATS (2010-2011) generator characteristics:
- Heat rate (efficiency: higher → more costly to operate, more likely to retire)
- Vintage (year of initial commercial operation)
- Nameplate capacity (MW)
- Existing FGD/scrubber equipment (already invested → less likely to retire)
- Regulated vs. merchant market structure

### County-Level Second Stage (Bartik-style)
- **Exposure measure:** For each county, compute predicted MATS retirement capacity = Σ(predicted retirement probability × generator MW capacity) across all coal generators in the county
- **Design:** County × year panel (2008-2020), comparing counties with high vs. low predicted MATS retirement exposure, before vs. after the 2015 compliance deadline
- **Specification:** Y_{ct} = α_c + δ_t + β × (PredRetire_c × Post_t) + γ × X_c × Year_t + ε_{ct}
- **Clustering:** State level

## Expected Effects
- Employment decline in high-exposure counties, particularly in mining (NAICS 21) and utilities (NAICS 22)
- Potential spillover to local services/retail
- Larger effects in merchant (deregulated) markets where generators face competitive pressure
- Electricity price pass-through in regulated states

## Primary Data Sources
1. **EIA-860:** Generator-level annual data (capacity, status, vintage, fuel, equipment) — EIA API v2
2. **EIA-923:** Generation and fuel consumption (for heat rate) — EIA API v2
3. **BLS QCEW:** County-level annual employment by industry — bulk CSV downloads
4. **EIA-861:** State retail electricity prices — EIA API v2

## Feasibility
- ~3,000+ coal generators in 2012, ~500+ retired by 2017
- ~200-300 unique coal-plant counties
- EIA APIs confirmed working; QCEW bulk files publicly available
- Pre-MATS variation in generator characteristics is substantial

## Method Notes
This is an IV/Bartik design. The key exclusion restriction is that a generator's pre-MATS characteristics (2010 heat rate, vintage, existing FGD) affect county employment only through their effect on the generator's retirement decision under MATS. This is plausible because heat rate and vintage are engineering characteristics that don't independently cause county employment changes in the absence of MATS.
