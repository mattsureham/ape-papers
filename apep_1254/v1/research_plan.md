# Research Plan: The Golden Visa Waterbed

## Research Question

Does restricting foreign investor-visa real estate purchases in prime urban areas push capital to eligible alternatives (a *waterbed effect*), or does investment simply leave the country? Portugal's January 2022 geographic restriction on golden visa property investment — barring purchases in Lisbon, Porto, and coastal Algarve while keeping interior regions eligible — provides a sharp natural experiment.

## Identification Strategy

**Difference-in-differences** with a NUTS3 × month panel, January 2015 through December 2024 (120 months).

- **Treatment group:** ~8-10 NUTS3 regions that lost golden visa real estate eligibility in January 2022 (Grande Lisboa, Península de Setúbal, Porto metropolitan sub-regions, Algarve)
- **Control group:** ~15 interior and island NUTS3 regions that retained eligibility (Centro interior, Alentejo, Norte interior, Azores, Madeira)
- **Treatment date:** January 2022 (with announcement in April 2021 for anticipation test)

Key identifying assumption: parallel trends in housing appraisal values between coastal/metro and interior NUTS3 regions, testable with 7 years of pre-treatment data (84 monthly observations).

**Threats:**
1. Concurrent policy — Portugal's "Mais Habitação" program (Oct 2023) is outside the primary 2015-2023 evaluation window and affects all regions
2. COVID recovery differential — include COVID controls and test robustness to excluding 2020-2021
3. Tourism recovery — may differentially affect coastal regions; use tourism-intensity heterogeneity as mechanism test

## Expected Effects and Mechanisms

**Primary hypothesis:** Treated regions (Lisbon, Porto, Algarve) experience relative price *decline* (or slower growth) after losing golden visa eligibility, while control regions (interior) experience relative price *increase* if capital diverts.

**Mechanism — The Waterbed Effect:**
- If golden visa investors are geographically flexible, restricting prime areas should push demand to eligible interior regions → positive spillover
- If investors are location-specific (want Lisbon, not Alentejo), restriction → investment leaves Portugal entirely → no spillover
- The relative magnitude of treatment vs. control effects distinguishes these channels

**Secondary mechanisms:**
- Anticipation effects (April-December 2021, between announcement and enactment)
- Composition effects (shift in property types, new vs. existing)

## Primary Specification

$$Y_{it} = \alpha_i + \gamma_t + \beta \cdot \text{Treated}_i \times \text{Post}_t + \varepsilon_{it}$$

Where:
- $Y_{it}$: median bank appraisal value (€/m²) in NUTS3 region $i$, month $t$
- $\alpha_i$: NUTS3 fixed effects
- $\gamma_t$: month fixed effects
- $\text{Treated}_i$: indicator for regions that lost golden visa eligibility
- $\text{Post}_t$: indicator for $t \geq$ January 2022

Clustering: NUTS3 level (~25 clusters). Given moderate cluster count, supplement with wild cluster bootstrap.

**Event study specification:**
$$Y_{it} = \alpha_i + \gamma_t + \sum_{k \neq -1} \delta_k \cdot \text{Treated}_i \times \mathbf{1}(t = k) + \varepsilon_{it}$$

## Data Source and Fetch Strategy

1. **INE BPIHE (primary):** Monthly bank housing appraisal values (€/m²) by NUTS3 region from INE Portugal's JSON-stat API. Endpoint: `https://www.ine.pt/ine/json_indicador/pindica.jsp`. ~25 NUTS3 × 120 months ≈ 3,000 observations.

2. **Eurostat HPI (secondary):** National quarterly house price index (prc_hpi_q) for Portugal and comparator countries (Spain, Italy, Netherlands, Ireland). REST API: `https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/prc_hpi_q`.

3. **Treatment assignment:** Hard-coded from Decreto-Lei 14/2021 — Metropolitan Areas of Lisbon and Porto, plus Algarve coastal municipalities.

## Robustness Checks

1. Event study with pre-trend test (primary diagnostic)
2. Wild cluster bootstrap p-values
3. Placebo treatment dates (2018, 2019)
4. Excluding COVID period (2020-2021)
5. HonestDiD sensitivity analysis for violations of parallel trends
6. Synthetic control for Lisbon vs. interior regions (supplementary)
7. Anticipation test: separate announcement (April 2021) from enactment (January 2022)
