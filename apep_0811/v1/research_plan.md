# Research Plan: apep_0811

## Research Question

Does mandatory calorie labeling deter new restaurant entry? England's April 2022 Calorie Labelling Regulations required food businesses with 250+ employees to display calorie counts on menus. Scotland did not adopt the mandate. If the regulation imposes compliance costs, increases consumer scrutiny, or signals tightening regulation, it may reduce new food business formation in England relative to Scotland — even among exempt small businesses.

## Identification Strategy

**Triple-Difference (DDD):**
- **Dimension 1 (Country):** England (treated) vs Scotland (control)
- **Dimension 2 (Sector):** Food service (SIC 56: restaurants, takeaways, catering) vs placebo sectors (SIC 47 retail, SIC 62 IT services, SIC 45 motor trades)
- **Dimension 3 (Time):** Pre (Jan 2019–Mar 2022) vs Post (Apr 2022–Dec 2025)

The triple interaction (England × FoodService × Post) isolates the regulation's effect on food business entry, controlling for:
- England-wide macroeconomic shocks (absorbed by England × Post)
- UK-wide food sector trends (absorbed by FoodService × Post)
- Persistent country-sector differences (absorbed by Country × Sector FE)

**Main specification:**
$$Y_{cst} = \beta \cdot \text{England}_c \times \text{FoodService}_s \times \text{Post}_t + \alpha_{cs} + \gamma_{ct} + \delta_{st} + \varepsilon_{cst}$$

where $Y_{cst}$ is log monthly incorporations in country $c$, sector $s$, month $t$.

## Expected Effects and Mechanisms

**Predictions:**
1. If compliance costs deter entry: negative β (fewer food businesses in England post-regulation)
2. If regulation signals future tightening: negative β even for exempt small businesses
3. If regulation legitimizes/modernizes the sector: positive β (professionalization attracts entry)

**Mechanism tests:**
- Subsector heterogeneity: restaurants (SIC 56.10) vs takeaways vs catering
- Size proxy: limited companies vs LLPs (rough size proxy)
- Regional heterogeneity: high-obesity vs low-obesity areas

## Primary Specification

Poisson regression with country × sector, country × month, and sector × month fixed effects. Standard errors clustered at the country × sector level. Robustness: OLS on log(incorporations + 1), negative binomial.

## Data Source and Fetch Strategy

**Primary:** Companies House bulk data (monthly CSV snapshot from download.companieshouse.gov.uk). Contains all ~5M UK companies with:
- IncorporationDate → monthly entry counts
- DissolutionDate → monthly exit counts
- SICCode → sector classification
- CompanyNumber prefix (SC = Scotland) → country classification
- RegAddress.Country → backup country classification

**Construction:** From a single snapshot, reconstruct time series of monthly incorporations by country × SIC division from Jan 2019 to present.

**Placebo sectors:** SIC 47 (retail), SIC 62 (IT/computer services), SIC 45 (motor trades) — chosen because they face similar macro conditions but are unaffected by calorie labeling.
