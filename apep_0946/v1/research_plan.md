# Research Plan: apep_0946

## Research Question

Does pro-competitive telecom regulation reduce consumer communications prices? Specifically, what is the causal effect of transposing EU Directive 2018/1972 (European Electronic Communications Code, EECC) on consumer communications price indices, and what is the consumer welfare cost of regulatory delay?

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered DiD** exploiting administrative-delay-driven variation in EECC transposition timing across 27 EU member states.

- **Treatment:** Year a member state formally transposed the EECC into national law
- **Treatment cohorts:** Dec 2020 (DK, GR, HU); 2021 (FI, BG, FR, CZ, AT, DE, LU, MT); 2022 (BE, EE, CY, NL, ES, SE, HR, LV, RO, PT, SI); 2023 (IE)
- **Never-treated:** IT, LT, PL, SK (transposed post-2024); NO, CH (non-EU, outside EECC scope)
- **Exogeneity argument:** Commission brought infringement proceedings against 24/27 member states — delays reflect bureaucratic/legal capacity, not strategic regulatory timing

**Exposure alignment:** Treatment is transposition of the EECC into national law, which directly affects all telecom consumers within the member state by altering the regulatory framework governing wholesale access, portability, and contracts. The unit of observation (country-year) aligns with the treatment unit (national transposition). All consumers within a transposing country are exposed simultaneously — there is no partial or differential exposure within countries.

**Key threats and diagnostics:**
1. Pre-trends: 6-7 years pre-treatment per cohort (2014-2019/2020); event-study coefficients
2. Anticipation: Use official national gazette publication date; test t-2, t-1 coefficients
3. Placebo outcomes: Food (CP011), transport (CP07), housing (CP04) CPI — EECC should not affect these
4. Heterogeneity: Pre-treatment market concentration (HHI proxy from BEREC reports)

## Expected Effects and Mechanisms

**Primary hypothesis:** EECC transposition reduces communications CPI through:
1. Enhanced wholesale access obligations → more retail competition
2. Faster number portability (1 business day) → lower switching costs
3. Anti-lock-in contract rules → competitive pressure on incumbents

**Expected direction:** Negative (price-reducing). Magnitude: moderate (-2% to -8% relative to pre-treatment mean), based on Genakos-Valletti (2018) finding 14-20% wholesale-retail pass-through.

**Null result interpretation:** If null, suggests EECC provisions are insufficiently binding or that markets were already competitive — a meaningful finding about regulatory efficacy.

## Primary Specification

```
Y_it = α_i + γ_t + β * EECC_it + X_it'δ + ε_it
```

Where Y_it is the HICP communications index (CP08) for country i in year t, EECC_it is an indicator for having transposed the directive, and α_i, γ_t are country and year fixed effects. Estimated via Callaway-Sant'Anna ATT(g,t) with never-treated as comparison group.

## Data Sources

1. **Eurostat HICP CP08** (communications CPI): 28 countries × 12 years (2014-2025), ~336 obs. Annual index, 2015=100.
2. **EECC transposition dates**: From EU Official Journal, Squire Patton Boggs tracker, EUR-Lex CELLAR SPARQL
3. **Placebo outcomes**: Eurostat HICP CP011 (food), CP07 (transport), CP04 (housing)
4. **Secondary outcome**: World Bank WDI fixed broadband subscriptions per 100 people
5. **Controls (optional)**: GDP per capita, population, internet penetration

## Fetch Strategy

- Eurostat: `eurostat` R package → `get_eurostat("prc_hicp_aind")` filtered to CP08, CP011, CP07, CP04
- Transposition dates: Hard-code from verified EU sources (23 countries with known dates)
- WDI: `WDI` R package → `WDI(indicator="IT.NET.BBND.P2")`
