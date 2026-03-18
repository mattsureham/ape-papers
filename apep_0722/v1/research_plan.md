# Research Plan: Japan's Split-Rate Consumption Tax and Cross-Category Substitution

## Research Question
Did Japan's 2019 introduction of a dual-rate consumption tax — 10% for restaurant dining, 8% for food at home — cause consumer substitution from restaurants to takeout/home meals? What is the cross-category substitution elasticity?

## Identification Strategy
Triple-difference exploiting three sources of variation:
1. **Product category:** 10%-rate categories (restaurants/hotels CP11, alcohol CP02) vs 8%-rate categories (food CP01)
2. **Time:** Before vs after October 1, 2019
3. **Placebo:** The April 2014 hike (5%→8%) hit ALL categories uniformly — the same cross-category comparison should yield null in 2014.

The 2014 placebo validates the identifying assumption: absent differential tax rates, restaurant and food CPI move in parallel around tax changes.

## Exposure Alignment
Treatment operates at the product-category level nationwide. ALL consumers in Japan face the same price wedge between eat-in (10%) and takeout (8%) from October 1, 2019. The treatment is universal — there is no within-country variation in tax rates. Identification comes from cross-category comparisons (treated categories vs shielded categories) rather than cross-unit comparisons.

## Expected Effects and Mechanisms
- **Restaurant prices:** Should increase ~2% relative to food-at-home prices (reflecting the 2pp tax wedge)
- **CPI divergence:** CP11 (restaurants) should jump relative to CP01 (food) at Oct 2019
- **Substitution:** Consumer expenditure should shift from restaurants toward takeout/prepared food
- **Mechanism:** The "identical item" provision (same food = 8% if taken out, 10% if eaten in) creates a margin for tax-motivated behavioral change
- **Welfare:** Dual-rate VAT creates a distortionary wedge that standard uniform-rate systems avoid

## Primary Specification
Difference-in-differences at the CPI category × month level:
```
log(CPI_{ct}) = α_c + γ_t + β × (Restaurant_c × Post2019_t) + ε_{ct}
```
Where c indexes COICOP categories and t indexes months.

For the triple-difference (with 2014 placebo):
Compare the DiD estimate in the 2019 window vs the 2014 window.

## Data Source and Fetch Strategy
**Primary:** OECD SDMX API — Monthly CPI by COICOP division
- URL: https://sdmx.oecd.org/public/rest/data/OECD.SDD.TPS,DSD_PRICES@DF_PRICES_ALL/...
- Variables: CP01 (Food), CP02 (Alcohol), CP03 (Clothing), CP04 (Housing), CP05 (Furnishings), CP06 (Health), CP07 (Transport), CP08 (Communications), CP09 (Recreation), CP10 (Education), CP11 (Restaurants/Hotels), CP12 (Misc)
- Period: 2012-2020 (covers both 2014 and 2019 tax changes)
- No API key required

**Treatment assignment:**
- 10% rate (Oct 2019+): CP02 (Alcohol), CP03-CP12 (all non-food)
- 8% rate (Oct 2019+): CP01 (Food and non-alcoholic beverages)
- Key comparison: CP11 (Restaurants) vs CP01 (Food) — cleanest test of the eat-in/takeout margin
