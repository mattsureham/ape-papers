# Research Plan: Darkness Falls Unevenly

## Research Question
Does the abolition of daylight saving time increase crime through earlier evening darkness? Mexico's October 2022 DST abolition — with exemptions for 33 border municipalities that retained DST for US economic integration — provides a spatial quasi-experiment.

## Identification Strategy
**Within-state difference-in-differences with spatial discontinuity.**

- **Treatment group:** ~252 non-border municipalities in 4 split states (Chihuahua, Coahuila, Nuevo León, Tamaulipas) that lost DST — evenings get darker 1 hour earlier during March–October.
- **Control group:** ~28 border municipalities in the same 4 states that retained DST (exempt by federal statute for US border alignment).
- **Key insight:** The exemption is determined by geographic adjacency to the US border — not by crime, economics, or politics.

### Primary Specification
$$Y_{mst} = \alpha + \beta \cdot \text{NonBorder}_m \times \text{PostReform}_t + \gamma_m + \delta_{st} + \varepsilon_{mst}$$

Where:
- $Y_{mst}$: crime rate per 100,000 in municipality $m$, state $s$, month $t$
- $\text{NonBorder}_m$: indicator for municipalities that lost DST
- $\text{PostReform}_t$: indicator for months after October 2022
- $\gamma_m$: municipality fixed effects
- $\delta_{st}$: state × year-month fixed effects (absorb state-level shocks)
- Cluster SEs at municipality level

### Built-in Placebos
1. **Temporal placebo:** November–February (both groups on standard time — no treatment contrast)
2. **Crime-type placebo:** White-collar crimes (fraud, embezzlement) should be unaffected by darkness
3. **Seasonal dose:** Effects should peak in months with maximal sunset-time differences (June–July)

## Expected Effects
Following Doleac & Sanders (2015, REStat):
- Street crimes (robbery, assault) increase in treated municipalities during DST-active months (March–October)
- No effect during November–February or on white-collar crimes
- Larger effects in urban municipalities where street crime is more prevalent

## Data Source and Fetch Strategy
**SESNSP** (Secretariado Ejecutivo del Sistema Nacional de Seguridad Pública):
- Municipality-level monthly crime counts by type, 2015–2025
- Open data from gob.mx
- Download: Municipal-Delitos-2015-2025 ZIP file from SharePoint link
- Covers all ~2,469 municipalities

**Population data:** CONAPO municipal population projections (for crime rates per 100,000)

**Border municipality list:** Federal statute defines the 33 exempt municipalities. Will hard-code from official gazette.

## Exposure Alignment
The treatment is municipality-level and binary: non-border municipalities lost DST (sunsets shift 1 hour earlier during March-October), while border municipalities retained it. Treatment assignment is determined by federal statute based on geographic adjacency to the US border — not by any municipality-level characteristic. All residents, businesses, and public spaces within a non-border municipality are simultaneously exposed to the earlier sunset. The crime outcome (monthly municipality-level counts from SESNSP) is measured at the same geographic unit as treatment assignment, so there is no mismatch between treatment and outcome units. The triple-difference design further ensures the treatment contrast is isolated to DST-active months when the sunset difference actually exists.

## Key Risks
1. SharePoint download may require browser; will try curl with redirect following
2. Small control group (28 municipalities) — will use wild cluster bootstrap
3. Border municipalities differ economically from interior — parallel trends must hold
4. Cartel violence may dominate crime counts — will examine crime-type decomposition
