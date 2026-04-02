# Research Plan: Section 301 China Tariffs and the Asian-White Manufacturing Wage Gap

## Research Question
Did Section 301 tariffs on Chinese imports (2018-2019) compress the Asian-White wage gap in highly exposed manufacturing industries? If Asian workers are disproportionately concentrated in tariff-exposed sectors (electronics, machinery), import protection may differentially affect their earnings relative to White workers.

## Identification Strategy
**Triple-Difference (DDD):**
- D1: Pre/post July 2018 (List 1 tariffs)
- D2: High-exposure vs low-exposure 4-digit NAICS industries (continuous tariff intensity index)
- D3: Asian workers vs White workers

The key identifying assumption: absent Section 301 tariffs, the Asian-White earnings gap would have evolved similarly in high-exposure and low-exposure industries. We test this via pre-trend analysis in the 2015Q1-2018Q2 window.

## Expected Effects and Mechanisms
**Primary hypothesis:** Section 301 tariffs reduced import competition in exposed industries, potentially raising domestic wages. If Asian workers are overrepresented in these industries, the tariff "windfall" flows disproportionately to Asian workers, compressing the Asian-White gap in manufacturing.

**Alternative mechanisms:**
1. Chinese retaliatory tariffs on agricultural goods hurt White rural workers → gap compression from the other end
2. Tariff uncertainty reduces hiring in exposed industries → compositional effects if marginal Asian workers differ from average
3. Supply chain disruption hurts Asian-concentrated subsectors → gap widening

## Primary Specification
$$Y_{i,r,t} = \alpha + \beta_1(\text{Tariff}_i \times \text{Asian}_r \times \text{Post}_t) + \beta_2(\text{Tariff}_i \times \text{Post}_t) + \beta_3(\text{Asian}_r \times \text{Post}_t) + \gamma_{ir} + \delta_{rt} + \theta_{it} + \epsilon_{i,r,t}$$

Where:
- $i$ = 4-digit NAICS industry
- $r$ = race (Asian, White)
- $t$ = year-quarter
- $\text{Tariff}_i$ = continuous industry-level tariff exposure index
- Fixed effects: industry×race, race×quarter, industry×quarter
- Cluster at state×industry level

## Data Sources
1. **QWI Race×Ethnicity Panel** (Azure): `az://apepdata/derived/qwi/rh/ns/*.parquet` — 143.9M rows, county×quarter×NAICS×race with average monthly earnings
2. **USTR Section 301 Tariff Lists** — HS6 product codes with tariff rates (Lists 1-3)
3. **HS6-to-NAICS Concordance** — Census Bureau crosswalk to map tariff exposure to 4-digit NAICS
4. **County Business Patterns (CBP)** — Industry output/employment for constructing exposure index

## Tariff Exposure Index Construction
$$\text{TariffExposure}_i = \frac{\sum_{h \in i} \text{ImportValue}_{h,\text{China}} \times \Delta\text{Tariff}_h}{\text{IndustryOutput}_i}$$

Where $h$ indexes HS6 product codes mapped to NAICS industry $i$.

## Outcome Variables
- **Primary:** Average monthly earnings (Earn_S) from QWI
- **Secondary:** Employment (beginning-of-quarter employment B), hiring (HirA), separation rate

## Robustness
1. Event-study plots for pre-trend validation
2. Placebo: Black-White gap in same industries (different mechanism → shouldn't show same pattern)
3. Placebo: Asian-White gap in non-manufacturing/services (no tariff exposure)
4. Wild cluster bootstrap for inference
5. Leave-one-state-out sensitivity
6. Bartik-style IV using pre-2018 industry×race employment shares
