# Research Plan: When the Grocery Store Leaves — SNAP Retailer Exits and Adverse Birth Outcomes

## Research Question

Do grocery store closures causally worsen birth outcomes for mothers in affected communities? Specifically, when SNAP-authorized supermarkets exit a county, do rates of low birth weight, preterm birth, and gestational diabetes increase — and are these effects concentrated among Medicaid-enrolled mothers?

## Identification Strategy

### Primary Design: Event-Study Difference-in-Differences

Treatment is defined as a county experiencing a significant supermarket exit (loss of ≥1 SNAP-authorized supermarket-class retailer). The event-study framework estimates dynamic treatment effects across years relative to the exit event, with county and year fixed effects absorbing time-invariant county characteristics and national trends.

### Instrumental Variable: Corporate Chain Bankruptcy Shocks

To address endogeneity (stores may close in declining areas), I instrument local supermarket exits using national chain bankruptcy events:
- **A&P / Pathmark (2015):** ~300 stores closed nationwide
- **Tops Friendly Markets (2018):** Regional bankruptcy in Northeast
- **Southeastern Grocers / Winn-Dixie (2018):** ~100 stores closed
- **Lucky's Market (2020):** Rapid closure of ~30 stores

The IV exploits the fact that a county's exposure to national chain bankruptcies depends on pre-period chain presence — a Bartik-style instrument where the "share" is pre-period chain market share and the "shift" is the national bankruptcy event. Counties with higher pre-period A&P presence, for example, experienced larger supermarket losses in 2015 for reasons unrelated to local health trends.

### Falsification Tests
- **Non-nutrition birth outcomes:** Cesarean delivery rates should not respond to food access changes
- **Pre-trends:** Event-study coefficients should be zero in pre-treatment periods
- **Placebo treatment:** Counties with non-supermarket SNAP retailer exits (convenience stores, dollar stores) should show weaker/no effects

## Expected Effects and Mechanisms

**Primary mechanism:** Reduced access to affordable fresh produce → worsened maternal nutrition during pregnancy → adverse birth outcomes.

**Expected direction:** Supermarket exits should increase low birth weight rates and preterm birth rates, with larger effects for Medicaid-enrolled mothers (lower-income, less mobile, fewer alternative shopping options).

**Effect size prior:** Hoynes, Schanzenbach, and Almond (2011, ReStat) found food stamp introduction reduced low birth weight by 2-5%. The mirror experiment (food access removal) should show effects of similar or smaller magnitude, given partial substitution to other food sources.

## Primary Specification

$$Y_{ct} = \alpha_c + \gamma_t + \sum_{k=-4}^{4} \beta_k \cdot \mathbb{1}[t - E_c = k] + \epsilon_{ct}$$

where $Y_{ct}$ is a birth outcome in county $c$, year $t$; $\alpha_c$ and $\gamma_t$ are county and year FE; $E_c$ is the year of first significant supermarket exit; and $\beta_k$ traces the dynamic path.

**IV first stage:**
$$\text{SupermarketExits}_{ct} = \pi_c + \lambda_t + \delta \cdot \text{ChainBankruptcyExposure}_{ct} + u_{ct}$$

where $\text{ChainBankruptcyExposure}_{ct} = \sum_j \text{Share}_{cj,2012} \times \text{NationalClosure}_{jt}$ sums over chains $j$.

## Data Sources

### 1. SNAP Retailer Database (USDA FNS)
- **Source:** USDA Food and Nutrition Service Historical SNAP Retailer Locator
- **Coverage:** All SNAP-authorized retailers, 2005-2025
- **Variables:** Store name, address, store type (supermarket, grocery, convenience), authorization dates, chain affiliation
- **Access:** Public download from USDA FNS website

### 2. CDC WONDER Natality Data
- **Source:** CDC WONDER Natality Expanded database
- **Coverage:** County-year, 2016-2024
- **Variables:** Birth weight, gestational age, delivery method, payment source (Medicaid/private), maternal demographics
- **Restriction:** Counties with ≥100K population for identified FIPS (609 counties, ~79% of US births)

### 3. County Controls
- **Source:** Census Bureau ACS 5-year estimates, BLS LAUS
- **Variables:** Median household income, poverty rate, unemployment rate, population, urbanization

## Sample Construction

1. Download SNAP retailer panel → identify supermarket-class exits by county-year
2. Download CDC natality county-year aggregates for 609 identified counties
3. Construct chain bankruptcy exposure instrument from pre-period chain presence
4. Merge county controls from ACS
5. Final panel: ~609 counties × 9 years = ~5,481 county-year observations

## Key Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Store closures endogenous to local decline | Chain bankruptcy IV provides exogenous variation |
| County-level aggregation masks heterogeneity | Stratify by Medicaid vs. private pay, urbanicity |
| Limited post-period for some bankruptcy events | Focus on A&P (2015) with longest post-window |
| SNAP retailer data may not perfectly capture all exits | Validate against USDA Food Access Research Atlas |
