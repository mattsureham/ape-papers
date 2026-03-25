# Research Plan: Equal Pay for Equal Work? Japan's 2020 Anti-Discrimination Law and the Non-Regular Wage Gap

## Research Question
Did Japan's 2020 Equal Pay for Equal Work Act reduce the wage gap between regular and non-regular workers? With 37% of Japan's workforce in non-regular employment — one of the highest rates in the OECD — this reform represents one of the most significant labor market interventions in a dual economy, yet no causal evaluation exists.

## Identification Strategy
**Staggered DiD** exploiting the firm-size-based rollout:
- **Large firms** (≥300 employees): treated April 1, 2020
- **SMEs** (<300 employees): treated April 1, 2021

This staggered design provides two independent tests of the reform's effect. If the wage gap narrows for large firms in 2020 AND for SMEs in 2021, the pattern is difficult to attribute to COVID-19 alone, since COVID hit both firm sizes simultaneously but the reform hit them sequentially.

### Key Threat: COVID-19 Confound
April 2020 treatment coincides with Japan's first COVID-19 state of emergency (April 7, 2020). Mitigation:
1. **Staggered replication**: Effect should appear at both treatment dates
2. **Industry × year FEs**: Absorb industry-specific COVID shocks
3. **Employment placebo**: If results are COVID-driven, total employment should show similar differential patterns
4. **Hours placebo**: COVID differentially affected hours; test if hours-adjusted wages tell the same story
5. **Callaway-Sant'Anna estimator**: Avoids forbidden comparisons in staggered settings

## Primary Specification
$$\text{WageGap}_{ist} = \alpha_i + \gamma_t + \beta \cdot \text{Post}_{st} + X_{ist}'\delta + \varepsilon_{ist}$$

Where $i$ indexes industry × firm-size cells, $s$ indexes the firm-size group (large/SME), and $t$ indexes years. Using Callaway-Sant'Anna ATT(g,t) for group-time treatment effects, with event-study visualization.

## Expected Effects
- **Primary**: Non-regular/regular wage ratio increases (gap narrows) by 2-5 pp
- **Mechanism 1**: Non-regular wages rise (compliance effect)
- **Mechanism 2**: Non-regular employment share may decrease (substitution toward regular employment or automation)
- **Mechanism 3**: Heterogeneity by industry non-regular share (retail/services vs manufacturing)
- **Null hypothesis**: Soft enforcement (no statutory penalties) → limited real-world effect

## Data Sources
1. **MHLW Basic Survey on Wage Structure** (賃金構造基本統計調査): Annual, 2014-2024
   - Available via MHLW Excel downloads and e-Stat API
   - Industry × firm-size × sex × employment-type cells
   - Variables: scheduled wages, bonuses, hours, employment counts
2. **MHLW Monthly Labour Survey** (毎月勤労統計調査): Monthly, for robustness
   - Establishment-level aggregates by industry and firm size
3. **e-Stat API**: ESTAT_APP_ID confirmed available

## Fetch Strategy
1. Download MHLW Basic Survey Excel files for 2014-2024 (11 years)
2. Parse industry × firm-size × employment-type wage tables
3. Construct balanced panel of cells
4. If Excel parsing proves difficult, use e-Stat API for structured access

## Design Parameters
- **Treated units**: ~48 cells (large firm × industry × sex) for first treatment, ~48 more for second
- **Pre-periods**: 6 years (2014-2019) → satisfies ≥5 requirement
- **Post-periods**: 4-5 years (2020-2024)
- **Clusters**: By industry (16 industries) — need to verify ≥20
- **Outcome variation**: Wage gap ratio ranges from ~58 (utilities) to ~79 (research)
