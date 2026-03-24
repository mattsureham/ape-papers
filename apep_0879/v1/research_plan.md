# Research Plan: Does Raising the Floor Change Who Gets Hired?

## Research Question
Do state minimum wage increases alter the racial composition of new hires in low-wage industries? Specifically, does compressing the wage distribution reduce statistical or taste-based discrimination in hiring, as predicted by Becker (1957)?

## Identification Strategy
**Callaway-Sant'Anna (2021) staggered DiD** exploiting state minimum wage increases above 110% of the federal floor between 2010 and 2024.

- **Treatment definition:** State-quarter where the effective minimum wage first exceeds 110% of the federal minimum ($7.25 × 1.1 = $7.98). This creates a binary treatment timing variable with ~30 treated states and ~15 never-treated states.
- **Unit of analysis:** County-quarter (for main specification) and state-quarter (for robustness).
- **Key controls:** County FE, quarter FE.

**Three robustness layers:**
1. **Border county pairs** (Dube-Lester-Reich 2010): Compare counties on opposite sides of state borders where one state raises MW and the other doesn't. This absorbs local labor market conditions.
2. **Triple-difference:** MW-exposed industries (Accommodation/Food Services NAICS 72, Retail NAICS 44-45) vs. non-exposed industries (Finance NAICS 52, Professional Services NAICS 54) within the same county-quarter.
3. **Placebo sector:** Healthcare (NAICS 62) where MW is less binding due to higher baseline wages.

## Expected Effects and Mechanisms
**Becker discrimination channel:** When the minimum wage binds, employers cannot hire minority workers at a discount. This eliminates the "wage wedge" that sustains taste-based discrimination. Predicted sign: MW increases → higher Black share of new hires.

**Statistical discrimination channel:** If employers use race as a proxy for productivity, higher MW raises the threshold for hiring any worker. This could disproportionately screen out minorities. Predicted sign: MW increases → lower Black share of new hires.

**Net effect is an empirical question** — the sign discriminates between theories.

## Primary Specification
```
Y_{c,t} = α_c + γ_t + β × Post_{s(c),t} + X_{c,t}Γ + ε_{c,t}
```

Where:
- Y = Black share of new hires, Black-White new hire earnings ratio
- Post = indicator for state MW > 110% federal
- α_c = county FE, γ_t = quarter FE
- SEs clustered at state level

CS DiD will estimate group-time ATTs, aggregated to overall ATT and dynamic event-study coefficients.

## Data Source and Fetch Strategy
**Primary:** QWI race/ethnicity data on Azure: `az://derived/qwi/rh/ns/*.parquet`
- 48 states, 3,014 counties, 2010-2024 quarterly
- Variables: HirN (new hires), Sep (separations), Emp (employment), EarnS (earnings) by race (A1=White, A2=Black)
- 359,598 county-quarter-race observations

**Treatment variable:** State minimum wage history. Source: Vaghul & Zipperer (2016) minimum wage database, supplemented by Department of Labor records. Will construct from known legislative changes.

**Border counties:** Use Census county adjacency file to identify cross-state border pairs.

## Outcome Variables
1. **Black share of new hires** = HirN(Black) / [HirN(Black) + HirN(White)] at county-quarter level
2. **Black-White new hire earnings ratio** = EarnS(Black) / EarnS(White) at county-quarter level
3. **Black separation rate** = Sep(Black) / Emp(Black) — mechanism: are gains from hiring or retention?

## Heterogeneity
- By industry (MW-exposed vs. non-exposed)
- By pre-treatment Black employment share (high vs. low minority presence)
- By MW bite size (large vs. small increase relative to median wage)
