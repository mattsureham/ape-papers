# Research Plan: Bunching at the 10 kWp Threshold

## Research Question

Germany's EEG 2014 exempted solar installations below 10 kWp from the self-consumption surcharge (~6.7 c/kWh, ~EUR 800/year for a marginal system). Did this threshold distort installation size decisions, and by how much? When the threshold moved to 30 kWp in 2021, did the distortion move with it?

## Identification Strategy

**Bunching estimation** (Saez 2010; Kleven & Waseem 2013). The EEG surcharge creates a notch/kink at 10 kWp: systems below are fully exempt; systems at or above pay the levy on self-consumed electricity. If installers respond, we observe excess mass just below 10 kWp and a "missing mass" region just above.

### Core Design

1. **Bunching at 10 kWp (2014-2020):** Plot empirical size distribution in 0.1 kWp bins. Fit polynomial counterfactual density excluding an exclusion window around 10 kWp. Estimate excess bunching mass B and implied behavioral elasticity.

2. **Difference-in-discontinuities (2021 reform):** EEG 2021 moved the exemption threshold to 30 kWp for residential rooftop systems. If bunching at 10 kWp is policy-induced:
   - Bunching at 10 kWp should disappear post-2021
   - New bunching should appear at 30 kWp
   This is the key falsification/confirmation test.

3. **Pre-policy placebo (pre-2014):** No bunching should exist at 10 kWp before August 2014.

4. **Placebo installation type:** Ground-mount (Freiflächenanlagen) face different incentive structures — no self-consumption motive — so should not bunch at 10 kWp.

### Key Assumptions
- No counterfactual technological bunching at exactly 10 kWp
- Installation capacity is a choice variable (not fully constrained by roof size)
- MaStR registration reflects true installed capacity

## Expected Effects and Mechanisms

**Primary:** Substantial bunching below 10 kWp during 2014-2020, driven by installers and homeowners downsizing systems to avoid the surcharge. The excess mass should be visible as a sharp spike at 9.9-10.0 kWp.

**Mechanism:** Solar installation companies optimize system design to just-below-threshold capacity. The cost is foregone renewable generation — each system that downsizes from, say, 12 kWp to 9.9 kWp produces ~20% less electricity annually.

**Magnitude:** Expect large bunching ratio (B/counterfactual density). The surcharge creates a meaningful per-year cost that compounds over the 20-year feed-in tariff period.

## Primary Specification

Kleven-Waseem bunching estimator:
- Bin width: 0.1 kWp
- Estimation window: 5-20 kWp (or 3-18 kWp)
- Exclusion window: to be determined from visual inspection (~9.0-11.0 kWp)
- Counterfactual polynomial: degree 7 (robustness: 5, 9)
- Standard errors: bootstrap (resample installations, re-estimate B)

Behavioral elasticity recovery:
- e = B / (f_0 * dk), where f_0 = counterfactual density at notch, dk = log change in effective cost at threshold

## Data Source and Fetch Strategy

**Marktstammdatenregister (MaStR)** — Germany's mandatory public registry of all energy installations.
- URL: https://www.marktstammdatenregister.de/MaStR/Datendownload
- Format: Bulk CSV download (~1.5 GB for solar units)
- Alternative: `open-mastr` Python package for API access
- Key fields: Nettonennleistung (capacity kW), InbetriebnahmeDatum (date), ArtDerSolaranlage (type), Bundesland, AnzahlSolarModule

**Fetch strategy:** Use the MaStR bulk download API or the open-mastr Python package to download all solar PV installations. Filter to residential rooftop (Gebäudesolaranlage) and ground-mount (Freiflächenanlage) separately. Keep installations from 2010-2023 for full pre/post coverage.

## Robustness Checks
1. Alternative polynomial degrees (5, 7, 9)
2. Alternative bin widths (0.05, 0.1, 0.2 kWp)
3. Alternative estimation windows
4. Donut exclusion (drop 9.9-10.1 kWp)
5. By Bundesland (16 states)
6. By year (annual bunching estimates → event study)
7. Module-count analysis (is bunching achieved by removing panels?)
8. McCrary-style density test at threshold
