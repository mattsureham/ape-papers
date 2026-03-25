# Research Plan: The Regulatory Ladder of Solar

## Research Question

Does Germany's capacity-dependent regulatory structure for solar PV cause strategic undersizing of installations? Across five EEG thresholds (10, 30, 40, 100, 750 kWp), do installers bunch below regulatory cutoffs to avoid compliance burdens — and did the 2021 reform's threshold shift from 10 to 30 kWp cause bunching to migrate?

## Identification Strategy

**Multi-cutoff bunching estimation** (Kleven & Waseem 2013; Kleven 2016). Five simultaneous thresholds in the EEG create capacity-dependent regulatory burdens:

1. **10 kWp** (pre-2021): EEG surcharge exemption for self-consumed electricity
2. **30 kWp** (post-2021): Expanded surcharge exemption threshold
3. **40 kWp**: Feed-in tariff rate break (higher rate below, lower above)
4. **100 kWp**: Mandatory direct marketing requirement
5. **750 kWp**: Mandatory participation in competitive tenders

Each threshold creates a kink or notch in the marginal revenue schedule. The multi-cutoff design provides internal replication — if bunching reflects strategic optimization, excess mass should scale with the financial incentive at each threshold.

**Difference-in-bunching (2021 reform):** The January 2021 EEG amendment shifted the self-consumption surcharge exemption from 10 to 30 kWp. Pre-2021 bunching at 10 kWp should dissolve; new bunching at 30 kWp should appear. Unchanged thresholds (40, 100, 750) serve as placebos.

## Expected Effects

- Significant bunching below all five thresholds, with excess mass proportional to financial incentive
- Bunching migration from 10 to 30 kWp after 2021 reform
- Technology constraint heterogeneity: residential rooftop installations physically constrained near 10 kWp; commercial/ground-mount installations unconstrained near 100/750 kWp
- Welfare: aggregate kWp "left on the roof" due to strategic undersizing is directly quantifiable

## Primary Specification

For each threshold $k$:
- Estimate counterfactual capacity distribution using polynomial fit (order 7-9) on bins outside the bunching region
- Measure excess mass $\hat{b}_k$ = (observed - counterfactual) / counterfactual in the bunching window
- Standard errors via bootstrap (500 replications)
- Elasticity of installation capacity: $\hat{e}_k = \hat{b}_k / (dk_k / (1 - \tau_k))$

Difference-in-bunching: Compare excess mass at 10 kWp and 30 kWp pre vs post January 2021.

## Data Source and Fetch Strategy

**Primary:** Marktstammdatenregister (MaStR) — Germany's comprehensive register of all electricity generation units. 8.5M+ solar PV installations with exact capacity (kWp, decimal precision), commissioning date, Bundesland, installation type. Available via Zenodo open-MaStR package (DOI: 10.5281/zenodo.14783581) or MaStR API.

**Strategy:** Download the open-MaStR Zenodo export (CSV format). Filter to solar PV units. Key variables: Nettonennleistung (net rated capacity in kW), InbetriebnahmeDatum (commissioning date), Bundesland (federal state), Lage (location type: rooftop vs ground-mount), AnzahlSolarModule (module count).

**EEG tariff schedule:** Published by BNetzA. Map each installation to its applicable tariff schedule based on commissioning date.
