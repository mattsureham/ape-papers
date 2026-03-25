# Research Plan: Rockets and Feathers in Food Taxation — Denmark's Fat Tax Experiment

## Research Question

Did Denmark's saturated-fat tax (October 2011 – January 2013) generate asymmetric price pass-through — with prices rising faster at introduction than falling at abolition — and does this "rockets and feathers" pattern vary across product categories with different market structures?

## Policy Background

Denmark's saturated-fat tax (Lov nr. 247 af 30. marts 2011) imposed 16 DKK/kg of saturated fat on foods exceeding 2.3% saturated fat content. Products affected: butter, margarine, cheese, cream, fatty meats. The tax took effect October 1, 2011 and was abolished January 1, 2013 (announced November 2012). This is the only enacted-and-repealed saturated-fat tax in the world, creating a unique symmetric natural experiment.

## Identification Strategy

### Strategy 1: Product-Level Event Study (Primary)
- **Treated products**: Butter/oils/margarine (PRIS6: 011500), meat (011200), cheese (011440)
- **Control products**: Fish (011300), bread/cereals (011100) — untaxed, share retail shelf space
- **Design**: Difference-in-differences event study around two events:
  - Event 1: Tax introduction (October 2011)
  - Event 2: Tax abolition (January 2013)
- **Test**: Asymmetric pass-through: |β_introduction| ≠ |β_abolition|
- **Fixed effects**: Product group × month-of-year (seasonality), product group trends
- **Clustering**: Product-group level (conservative, accounts for serial correlation)

### Strategy 2: Cross-Country Synthetic Control (Secondary)
- **Treated**: Denmark food CPI categories
- **Control**: Sweden (via Eurostat HICP) — same food supply chains, retail structure, income, no fat tax
- **Design**: Synthetic DiD treating introduction and abolition as separate events
- **Purpose**: Rules out Denmark-wide confounders affecting all food prices

## Expected Effects and Mechanisms

1. **Symmetric pass-through hypothesis (null)**: Prices rise at introduction and fall symmetrically at abolition. Competitive retail market transmits tax changes proportionally.
2. **Rockets-and-feathers hypothesis (alternative)**: Prices rise faster/more at introduction than they fall at abolition. Mechanisms:
   - Menu cost asymmetry: retailers incur fixed costs to change prices; upward adjustments are more salient/justified
   - Strategic pricing: retailers use tax as cover for margin expansion ("overshifting"), then retain margins post-abolition
   - Supply chain stickiness: wholesale contracts renegotiate asymmetrically
3. **Product heterogeneity**: More concentrated product markets (cheese, butter) may show stronger asymmetry than fragmented ones (meat)

## Primary Specification

```
Y_{it} = α_i + γ_t + Σ_k β_k · D_{it}^k + ε_{it}
```

Where:
- Y_{it} = log CPI index for product group i in month t
- α_i = product group FE
- γ_t = calendar month FE
- D_{it}^k = event-time dummies (relative to Oct 2011 for introduction, Jan 2013 for abolition)
- Comparison: β_{intro,+1} vs |β_{abolition,+1}| for asymmetry test

## Data Sources

1. **Statistics Denmark PRIS6** (primary): Monthly CPI by product group, 2000M01–2015M12. Free API, no authentication. ~168 months × 7+ product groups.
2. **Eurostat HICP** (secondary): Monthly harmonized CPI for Denmark and Sweden by COICOP category. Free API via `eurostat` R package.
3. **Statistics Denmark DETAILH** (tertiary): Retail trade turnover by industry, monthly. For volume/quantity outcomes.

## Exposure Alignment

The treatment is clearly defined by the statutory 2.3% saturated-fat threshold. Products are classified as treated/control based on their product-group composition:
- **Treated** (>2.3% sat fat): Butter/oils/margarine, cheese, all meat subcategories (beef, veal, pork, lamb, poultry, processed meat), milk, other dairy (cream, yogurt)
- **Control** (<2.3% sat fat): Fish, bread/cereals, eggs, fruit, fresh vegetables, potatoes, frozen vegetables, sugar/sweets, other food, coffee/tea, soda/juice

All products within a treated category are subject to the tax — there is no within-category variation in treatment status. The CPI indices aggregate within each category, so the measured outcome directly reflects the tax's impact on prices for those product groups. The timing is sharp: tax effective October 1, 2011; abolition January 1, 2013. No staggering, no phase-in.

## Fetch Strategy

1. Statistics Denmark API: `https://api.statbank.dk/v1/data/PRIS6/CSV` with product group and time parameters
2. Eurostat: `eurostat::get_eurostat("prc_hicp_midx")` filtered to DK and SE
3. All sources confirmed accessible, no authentication required
