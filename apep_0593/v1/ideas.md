# Research Ideas

## Idea 1: Roaming Abolition and Cross-Border Tourism: Real-Economy Spillovers of the EU's Roam Like at Home Regulation
**Policy:** EU Regulation 2017/920 ("Roam Like at Home") eliminated retail roaming surcharges across the EEA effective June 15, 2017. Applied simultaneously to all 28 EU member states plus Iceland, Liechtenstein, Norway.
**Outcome:** Primary: Foreign tourist nights at NUTS2 (Eurostat tour_occ_nin2), 2012-2022, 8,135+ observations. Secondary: NUTS3 GDP (nama_10r_3gdp). Mechanism: BEREC data showing explosion in roaming data volumes post-June 2017.
**Identification:** Spatial DiD. Treatment: ~80-100 border NUTS2 regions (internal EU land borders). Control: ~170+ interior NUTS2 regions. Treatment intensity: distance to nearest EU internal border or pre-treatment cross-border tourism share. 5 pre-treatment years (2012-2016). Placebos: (1) domestic tourism nights (null expected); (2) external border regions (EU-non-EU, RLAH doesn't apply); (3) pre-treatment falsification.
**Why it's novel:** All existing RLAH literature is telecom-focused (Quinn et al. 2024 EJ, Muñoz-Acevedo & Grzybowski 2023, Verboven et al. 2024). No paper estimates real-economy tourism spillovers of roaming abolition.
**Feasibility check:** Confirmed: 288 internal border NUTS3 → ~80-100 border NUTS2 vs ~170+ interior; Eurostat tour_occ_nin2 returns 8,135 values; no paper links RLAH to tourism; 2,970+ region-year observations.

## Idea 2: The HFC Squeeze: How EU F-Gas Quotas Reshaped the Cooling Equipment Industry
**Policy:** EU Regulation 517/2014 imposed quantity-based HFC phase-down. The 2018 step was the largest single cut (-37pp), triggering 400-700% refrigerant price spikes.
**Outcome:** Eurostat SBS C2825 (HVAC manufacturing): 742 values, 12 countries, 2008-2020. UN Comtrade bilateral HFC trade data.
**Identification:** Continuous DiD with pre-regulation HFC intensity as treatment. Triple-difference adding non-HFC sectors as within-country controls. 7 pre-treatment years.

## Idea 3: Did the EU Geo-Blocking Ban Increase Cross-Border E-Commerce?
**Policy:** EU Regulation 2018/302 prohibited nationality-based online discrimination for goods but exempted audiovisual services. Applied from December 3, 2018.
**Outcome:** Eurostat HICP monthly indices by COICOP category (12,960 values) and cross-border e-commerce survey data (390 values).
**Identification:** Triple-Difference: Time (pre/post Dec 2018) × Product (covered goods vs excluded services) × Cross-country price dispersion. Built-in placebo: exempted service categories.
