# Research Plan: When the Roughnecks Arrive

## Research Question

Does male-biased labor demand from the US shale boom distort local sex ratios and worsen women's labor market outcomes? The fracking revolution created massive mining employment that is 14:1 male-to-female, shifting local sex ratios by up to 19 percentage points. We estimate whether this male-biased demand shock crowds women out of non-mining sectors, reduces their relative wages, or alters marriage market dynamics.

## Identification Strategy

**Callaway-Sant'Anna DiD** with geological shale exposure as treatment intensity. Treatment is continuous: county-level shale well count per capita (from Enverus/state geological surveys via FRED or EIA). We exploit staggered drilling onset across counties.

**Three phases:**
1. **Boom** (2005–2014): male-biased employment surge
2. **Bust** (2015–2018): oil price collapse, male employment crash
3. **Recovery** (2019–2022): partial rebound

**Key design features:**
- **Triple-difference:** female vs. male outcomes within county, comparing high-shale vs. low-shale counties
- **Continuous treatment:** wells per capita (or mining employment share) rather than binary
- **Built-in placebo:** female-dominated industries (healthcare, education) should show no direct treatment effect from drilling
- **Boom-bust asymmetry test:** if male-biased demand hurts women during boom, do women benefit during bust?

## Expected Effects and Mechanisms

1. **Labor market competition:** Male in-migration competes for housing, services, infrastructure — raising costs for all. Women in non-mining sectors face cost-of-living increases without corresponding wage gains → real wage decline.
2. **Marriage market distortion:** Surplus males improve women's marriage market position (Becker 1973) but may also increase domestic violence (Aizer 2010).
3. **Industry composition:** Resource booms may crowd out female-intensive service sectors through Dutch Disease (labor cost increases, resource reallocation).

**Primary specification:**
```
Y_ct = α_c + γ_t + β₁(ShaleProd_ct × Female_c) + β₂(ShaleProd_ct) + X_ct + ε_ct
```

Where Y is QWI employment or earnings by sex, ShaleProd is county oil/gas production, and we cluster at the state level.

## Data Sources

1. **QWI (Quarterly Workforce Indicators)** — Census Bureau API
   - County × quarter × sex × industry (2-digit NAICS)
   - Employment counts, average monthly earnings, hire/separation rates
   - Coverage: 2000–2023 for most states

2. **ACS (American Community Survey)** — Census Bureau API
   - County-level sex ratios (B01001), marriage rates (B12001), fertility (B13016)
   - 5-year estimates for small counties

3. **EIA / State oil & gas production data** — county-level production
   - Oil and gas well counts and production volumes by county
   - Via EIA API or state geological surveys

4. **Shale play boundaries** — EIA shale play maps
   - Binary geological indicator: county overlaps major shale play (Bakken, Eagle Ford, Permian, Marcellus, etc.)

## Fetch Strategy

1. Query QWI API for all US counties, quarterly, by sex and industry (2-digit NAICS), 2000–2023
2. Query ACS API for county demographics (sex ratios, marriage, fertility)
3. Download EIA county-level production data or construct shale exposure from geological boundaries
4. Merge on FIPS codes

## Key Risks

- **QWI suppression:** Small counties may have suppressed cells. Focus on counties with population >10,000.
- **Migration confounding:** In-migration is the mechanism, not a confounder — but need to distinguish in-migrant composition from local population effects.
- **TWFE bias:** Staggered drilling onset → use Callaway-Sant'Anna or Sun-Abraham, not naive TWFE.
