# Research Plan: Purchase-Tax Notching in the Dutch BPM

## Research Question
Do manufacturers and importers strategically manipulate type-approval CO2 emissions to avoid discontinuous jumps in the Dutch BPM (Belasting van Personenauto's en Motorrijwielen) one-time purchase tax? If so, how elastic is type-approval CO2 to taxation, and does the response vary with notch size?

## Policy Background
The Netherlands levies BPM, a one-time vehicle purchase tax calculated from WLTP CO2 emissions. Since 1 July 2020, the tariff has four band boundaries with discontinuous per-gram rate jumps:
- 0–79 g/km: base €667 + €2/g
- 79–101 g/km: base €825 + €79/g (40x jump at 79)
- 101–141 g/km: base €9,483 + €173/g (2.2x jump at 101) [Note: correcting from manifest — will verify exact 2024 rates]
- 141–157 g/km: base + €284/g (1.6x jump at 141)
- 157+ g/km: base + €568/g (2x jump at 157)

## Identification Strategy
**Multi-cutoff bunching estimation** (Kleven 2016; Chetty et al. 2011). The key identifying assumption is that, absent the BPM tax bands, the CO2 density would be smooth across these thresholds. We test this with:

1. **Germany as control country** — Germany has a flat €2/g annual CO2 Kfz-Steuer with no notch at the same CO2 values → smooth density expected
2. **Pre-WLTP period** (NEDC-era registrations before 2020) — different thresholds applied
3. **Electric vehicles** — 0 g/km, outside all bands → no bunching expected

**Dose-response:** Four simultaneous notches with variable tax jumps allow testing whether bunching intensity is proportional to the marginal tax jump. Larger tax jumps at 79 g/km (40x) should produce more bunching than at 157 g/km (2x).

## Expected Effects
- **Excess mass** just below each notch (79, 101, 141, 157 g/km)
- **Missing mass** just above each notch
- Bunching magnitude proportional to tax-jump size (monotone dose-response)
- Zero or negligible bunching in Germany at identical CO2 values
- Implied elasticity of type-approval CO2 w.r.t. purchase tax, comparable to Sallee & Slemrod (2012) gas guzzler tax estimates

## Primary Specification
For each notch $k$:
- Estimate the counterfactual density using polynomial fit to bins outside the bunching/missing-mass region
- Calculate excess bunching $\hat{b}_k$ as observed - counterfactual density in the bunching region
- Implied response $\Delta z_k^*$: width of the dominated region
- Structural elasticity: $e = \Delta z^* / z^* \cdot (t / \Delta t)$ where $t$ is the average tax and $\Delta t$ is the notch size

## Data Source and Fetch Strategy
**European Environment Agency (EEA) CO2 Monitoring Data** — Vehicle-level microdata via SQL REST API at `discodata.eea.europa.eu`. Regulation EU 2019/631 requires manufacturers to report every new car registration with CO2, mass, fuel type, power.

- **Netherlands:** ~400K registrations/year, 2020–2024 for WLTP-era analysis
- **Germany:** ~3M registrations/year, same period, as placebo control
- **Fields needed:** CO2 WLTP (g/km), member state, year, fuel type, manufacturer, mass, engine capacity

Fetch via SQL queries to the EEA API. No authentication required.

## Key Risks
1. EEA API may rate-limit or have incomplete recent years
2. CO2 values may be reported with rounding that obscures sharp bunching
3. The 79 g/km threshold is close to the PHEV/zero-emission boundary — compositional effects need handling
4. BPM rates changed over 2020–2024 — need to track exact band boundaries by year
