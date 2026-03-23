# Research Plan: Working Themselves to Death?

## Research Question

Did Italy's 2011 Fornero pension reform — which suddenly raised the retirement age, trapping approximately 350,000 workers ("esodati") — increase mortality among 55–64 year-olds? This paper exploits regional variation in the reform's "bite" (the forced increase in older-worker employment) and the gender differential (women faced up to a 7-year increase vs. 2 years for men) to test the "retirement kills" hypothesis at unprecedented scale.

## Motivation

The Monti-Fornero reform (Law 214/2011), enacted in 20 days under financial crisis pressure, raised Italy's old-age retirement age to 66–67 for all workers. Women's retirement age increased from 60 to 67 (up to 7 years); men's from 65 to 67 (up to 2 years). This created massive cross-regional variation: the "Fornero bite" — the increase in 55–64 employment rates — ranged from +1.4pp in Sicilia to +15.4pp in Umbria. If forced work retention increases mortality, this is the cleanest large-scale natural experiment available.

## Identification Strategy

**Continuous-treatment DiD across 21 Italian NUTS2 regions.**

- **Treatment intensity:** "Fornero bite" = change in 55–64 employment rate from 2010 to 2014 per NUTS2 region.
- **Pre-period:** 2000–2011 (12 years of mortality data).
- **Post-period:** 2012–2020.
- **Gender dose-response:** Women faced 3.5× larger retirement age increase (7 vs. 2 years), providing a within-region test.
- **Age placebo:** Mortality among 45–54 year-olds (unaffected by reform) should show no effect.

## Data Sources

1. **Eurostat `demo_r_magec`:** Deaths by single year of age, sex, NUTS2, 2000–2020.
2. **Eurostat `demo_r_pjangroup`:** Population by 5-year age group, sex, NUTS2, 2000–2020.
3. **Eurostat `lfst_r_lfe2emprt`:** Employment rates by age, sex, NUTS2, 2000–2023.
4. **Eurostat `hlth_cd_acdr2`:** Cause-of-death by ICD-10 category, NUTS2, 2011–2020 (for decomposition).

## Outcome Variables

| Variable | Source | Measure |
|----------|--------|---------|
| Death rate (55–64) | demo_r_magec / demo_r_pjangroup | Deaths per 100,000 population |
| Employment rate (55–64) | lfst_r_lfe2emprt | % employed (first stage) |
| Cause-specific mortality | hlth_cd_acdr2 | Cardiovascular, suicide, alcohol |

## Primary Specification

$$\text{DeathRate}_{r,s,t} = \alpha_r + \alpha_t + \beta \cdot (\text{FBite}_{r,s} \times \text{Post}_t) + X'_{rt}\gamma + \epsilon_{r,s,t}$$

Where $r$ = NUTS2 region, $s$ = sex, $t$ = year; FBite = Fornero bite (employment rate change 2010→2014); Post = indicator for 2012+. Standard errors clustered at NUTS2 level.

## Robustness

1. Age-group placebo (45–54 vs. 55–64)
2. Gender dose-response (women vs. men)
3. Event study with yearly coefficients
4. Leave-one-out (drop each region)
5. Cause-of-death decomposition (cardiovascular, suicide, alcohol)

## Design Parameters

- Treated units: 21 NUTS2 regions (continuous intensity)
- Pre-periods: 12 years (2000–2011)
- Treatment timing: December 2011 (sharp, common)
- Observations: ~21 regions × 2 sexes × 21 years = ~882
