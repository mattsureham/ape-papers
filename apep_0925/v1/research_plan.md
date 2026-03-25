# Research Plan: apep_0925

## Research Question

Does England's mandatory calorie labeling regulation (April 2022, applying only to food businesses with 250+ employees) cause firms to strategically avoid crossing the 250-employee threshold? Do treated food businesses in England reduce employment or restructure relative to untreated counterparts in Scotland?

## Identification Strategy

**Triple-difference design:**
1. **Time**: Pre-regulation (2015–2021) vs post-regulation (2023–2024)
2. **Geography**: England (treated) vs Scotland (untreated — Scotland did not adopt)
3. **Industry**: Food services (SIC 56, treated industry) vs other service sectors (untreated)

**Primary specification**: Compare the ratio of enterprises in the 250–499 size band to those in the 100–249 band (the "threshold ratio") across England vs Scotland, food services vs other sectors, before and after April 2022.

**Built-in placebos:**
- Scotland food services (same industry, untreated jurisdiction)
- England non-food services (same jurisdiction, untreated industry)
- Other size band transitions (e.g., 50–99 to 100–249 — no regulatory threshold)

## Expected Effects and Mechanisms

**Hypothesis 1 (Threshold avoidance):** If compliance costs are material, food businesses near the threshold will strategically stay below 250 employees. This would show up as an increase in the 100–249 band and decrease in the 250–499 band for food services in England.

**Hypothesis 2 (Compliance absorption):** If compliance costs are modest, firms comply without restructuring. No change in size distribution. This null result is equally publishable — it measures the "revealed compliance burden."

**Mechanisms to test:**
- Firm count shifts across size bands (threshold avoidance)
- Total employment in food services (labor demand effect)
- Enterprise births/deaths in food services (entry/exit)

## Primary Specification

$$Y_{g,s,t} = \alpha + \beta_1 (\text{England}_g \times \text{Food}_s \times \text{Post}_t) + \gamma_{g,s} + \delta_{s,t} + \theta_{g,t} + \varepsilon_{g,s,t}$$

Where:
- $Y$: threshold ratio (enterprises 250–499 / enterprises 100–249) or log employment
- $g$: geography (local authority / region)
- $s$: industry sector
- $t$: year
- Three-way fixed effects absorb geography×industry, industry×year, geography×year

## Data Source and Fetch Strategy

**Primary data:** ONS UK Business Counts from NOMIS (NM_142_1 — enterprises by industry, size band, geography)
- Coverage: Annual, March reference date, 2015–2024
- Geography: Local authority districts (England + Scotland)
- Industry: 4-digit SIC code (SIC 5610, 5621, 5629, 5630 for food services; SIC 55, 47, 49 as controls)
- Size bands: 0–4, 5–9, 10–19, 20–49, 50–99, 100–249, 250–499, 500–999, 1000+

**Supplementary data:** NOMIS BRES (NM_189_1) for total employment by industry and geography

**Fetch method:** NOMIS API via `nomisr` R package (API key in .env)

## Idea Source
idea_0964: UK mandatory calorie labeling, 250-employee threshold, firm-size RDD
