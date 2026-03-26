# Research Plan: apep_1018

## Research Question

Does co-ethnic refugee absorption depress local labor markets when institutional barriers to integration are absent? The sudden displacement of 100,625 ethnic Armenians from Nagorno-Karabakh in September 2023 provides a natural experiment: refugees share ethnicity, language, and full citizenship with the host population, isolating structural labor market rigidities from institutional integration costs.

## Identification Strategy

**Shift-share DiD:** National exodus shock × marz-level refugee-to-population ratio (ranges 2.3%–29.4% across Armenia's 11 marzes). Settlement was driven by pre-existing family networks and geographic proximity to the Lachin corridor entry point, not by local labor demand conditions.

- **Treatment intensity:** Refugees per 1,000 marz population (continuous)
- **Control variation:** Low-absorption marzes (Vayots Dzor, Syunik, Aragatsotn) vs. high-absorption marzes (Kotayk, Ararat, Yerevan)
- **Pre-treatment period:** 2014–2022 (9 years)
- **Post-treatment period:** 2023Q4–2024

**IV robustness:** Road distance from each marz capital to the Lachin corridor crossing as an instrument for refugee concentration. Exclusion: geographic proximity to the NK border affects labor markets only through refugee inflows after September 2023.

## Expected Effects and Mechanisms

1. **Labor supply shock:** 3.6% national population increase concentrated in specific marzes. Standard Rybczynski theorem predicts wage depression in low-skill sectors.
2. **Co-ethnic advantage hypothesis:** If cultural/linguistic proximity eliminates integration frictions, absorption should be faster than in cross-ethnic refugee settings. Expect smaller wage effects than Borjas (2017) Mariel estimates.
3. **Sectoral reallocation:** Refugees may enter construction, services, agriculture — sectors with elastic demand. Look for sector-specific displacement vs. complementarity.
4. **Government stipend cushion:** $185/month stipends may delay labor force entry, attenuating short-run effects.

## Primary Specification

$$Y_{imt} = \alpha + \beta \cdot (\text{RefugeeShare}_m \times \text{Post}_t) + \gamma_m + \delta_t + X_{it}'\theta + \varepsilon_{imt}$$

Where:
- $Y_{imt}$: employment status, log wages, unemployment for individual $i$ in marz $m$ at time $t$
- $\text{RefugeeShare}_m$: refugees per 1,000 residents in marz $m$
- $\text{Post}_t$: indicator for 2023Q4+ (post-exodus)
- $\gamma_m, \delta_t$: marz and year fixed effects
- $X_{it}$: age, education, gender, urban/rural

**Inference:** Wild cluster bootstrap (11 clusters) + Fisher randomization inference (permuting refugee shares across marzes).

## Data Sources

1. **ARMSTAT Labour Force Survey (LFS):** Individual-level microdata, ~27,000 obs/year, 2014–2024. Variables: employment status, occupation, industry (NACE), wages, education, marz.
2. **UNHCR/Armenian government displacement data:** Marz-level refugee counts (September–December 2023).
3. **World Bank WDI:** Armenia macro indicators for context.
4. **ARMSTAT population estimates:** Marz-level population for computing refugee shares.

## Fetch Strategy

- ARMSTAT LFS: Download from ARMSTAT statistical database (armstatbank.am) or use cached microdata if available from smoke test
- Refugee settlement data: UNHCR Armenia response portal + government reports
- World Bank: WDI API for macro context
