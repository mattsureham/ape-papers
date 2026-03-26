# Research Plan: Renovate or Retreat — Bunching at France's DPE Rental Ban Thresholds

## Research Question

Does the phased rental ban schedule in France's 2021 Climat et Resilience law induce strategic renovation behavior visible as bunching in building energy performance diagnostics (DPE) at regulatory thresholds? How does bunching intensity evolve as ban deadlines approach?

## Policy Background

France's Loi Climat et Resilience (Law 2021-1104, August 2021) bans renting properties based on DPE energy labels:
- Jan 2023: G+ (>450 kWh/m2/yr) banned
- Jan 2025: All G (>420 kWh/m2/yr) banned
- Jan 2028: F (>330 kWh/m2/yr) banned
- Jan 2034: E (>250 kWh/m2/yr) banned

The DPE scale assigns labels based on continuous primary energy consumption (kWh/m2/yr). This creates sharp regulatory thresholds at 420, 330, and 250 kWh/m2/yr where properties just below avoid rental market exclusion.

## Identification Strategy

### Primary: Bunching Estimator (Saez 2010; Kleven & Waseem 2013)

1. **Static bunching** at 420 kWh/m2 (F/G threshold): Plot density of continuous energy consumption in fine bins (5 kWh/m2). Fit smooth polynomial to counterfactual density excluding manipulation window. Measure excess mass B below threshold and missing mass above.

2. **Difference-in-bunching over time**: If bunching reflects landlord behavioral response to rental ban:
   - Bunching at 420 should intensify as Jan 2025 G-ban approached (2022→2024)
   - Bunching at 330 (F boundary) should be weaker initially, growing as 2028 approaches
   - Bunching at 250 (E boundary) should be minimal (2034 is far away)
   This temporal gradient is the key identification: it separates behavioral responses from mechanical artifacts of the DPE methodology.

3. **Geographic heterogeneity**: Bunching should concentrate in tight rental markets (Paris, Lyon, Marseille IDF) where rental revenue loss from ban compliance is largest. Owner-occupied-dominant rural areas should show no bunching.

4. **July 2024 small-property reform**: April 2024 amendment relaxed thresholds for properties <40m2, reclassifying many small G-rated units to F. Difference-in-bunching: bunching at 420 should diminish for <40m2 properties post-July 2024 but persist for larger properties.

### Placebos

- **B/C threshold (110 kWh/m2)**: No regulatory consequence — should show no bunching
- **GHG dimension**: DPE has a dual criterion (energy + GHG). If bunching is about rental ban compliance, it should concentrate on the binding energy dimension

## Expected Effects

- **Excess mass below 420 kWh/m2**: Positive and growing over 2022-2025
- **Temporal gradient**: Bunching at 420 > bunching at 330 > bunching at 250 (proportional to deadline proximity)
- **Geographic concentration**: Bunching in high-rental-share, tight-market communes
- **Mechanism**: Mix of genuine renovation (moving energy consumption below threshold) and potential diagnostician discretion at borderline cases

## Primary Specification

Following Kleven (2016), estimate bunching as:
$$B = \int_{z^*-\delta}^{z^*} [h(z) - h_0(z)] dz$$

where h(z) is the observed density, h_0(z) is the counterfactual polynomial, z* = 420 (or 330), and δ is the manipulation window estimated iteratively.

Difference-in-bunching: estimate B separately by diagnostic year and test for a time trend using:
$$B_t = \alpha + \beta \cdot t + \gamma \cdot \text{Post2023} + \epsilon_t$$

## Data Source and Fetch Strategy

**ADEME DPE open data** (dataset: `dpe03existant`)
- 14.4M building-level diagnostic records, July 2021 - March 2026
- API: `https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines`
- No authentication required
- Key fields: `conso_5_usages_par_m2_ep` (continuous energy consumption), `etiquette_dpe` (label), `date_etablissement_dpe` (date), `code_postal_ban` (location), `surface_habitable` (surface area)
- Fetch strategy: Download records in energy consumption bins around thresholds (350-500 kWh/m2 for F/G threshold, 280-380 for E/F, 60-160 for B/C placebo), paginating through API

## Key Risks

1. **Diagnostician manipulation vs. genuine renovation**: If bunching is driven by assessors gaming borderline cases (as Collins & Curtis 2018 found for Ireland), it's a measurement paper, not a behavioral response paper. The temporal gradient test and geographic heterogeneity help distinguish these.
2. **DPE methodology change (July 2021)**: The new DPE method itself could mechanically create density discontinuities. Difference-in-bunching across years controls for this (methodology is constant post-July 2021).
3. **Sample selection**: Properties get DPE diagnostics when sold or rented. If the rental ban causes G-rated properties to exit the rental market entirely (no DPE filed), we observe "retreat" as missing mass without corresponding bunching.
