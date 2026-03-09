# Initial Research Plan — apep_0562

## Research Question

Does social-network exposure to asylum-seeker dispersal increase far-right (RN) vote share in departments that did not themselves receive asylum seekers? Does this network channel operate in the opposite direction to the local contact effect?

## Theoretical Framework

Allport's (1954) contact hypothesis predicts that direct exposure to outgroup members reduces prejudice, conditional on institutional support. Schneider-Strawczynski (2024, JEEA) confirms this locally: French departments hosting asylum seekers see RN vote share *decline*. But what about departments that are socially connected to hosting areas without direct contact? Information transmission through social networks may amplify salience, anxiety, and perceived threat — generating a network backlash effect that operates in the *opposite* direction to the local contact effect.

This mirrors the mechanism in apep_0464 (Connected Backlash), which found that social-network exposure to carbon tax costs increased RN support in non-fuel-dependent areas. We test whether the same network amplification channel operates for immigration shocks.

## Identification Strategy

**Shift-share (Bartik) DiD:**

- **Shares (S_ij):** Facebook Social Connectedness Index (SCI) between department i and department j. Pre-determined (2026 snapshot, but reflects long-run social ties). Normalized so shares sum to 1 within each department.
- **Shifts (Z_j):** New asylum reception capacity (CADA + CAES places) created in department j under the Schema National d'Accueil 2021-2023.
- **Treatment variable:** NetworkDispersal_i = Σ_j SCI(i,j) × NewPlaces_j — the SCI-weighted sum of asylum reception capacity across all departments j, for each department i.
- **Identifying assumption:** Conditional on department and election FE, the SCI-weighted sum of new asylum places is uncorrelated with department-level shocks to RN support. We follow Borusyak, Hull & Jaravel (2022) and treat shifts as exogenous: the dispersal scheme was a centralized policy allocating places based on capacity targets, not local political dynamics.

**Key estimating equation:**

RN_it = α_i + γ_t + β × NetworkDispersal_i × Post_t + X_it'δ + ε_it

where i indexes departments, t indexes elections, Post_t = 1 for elections after 2021.

## Expected Effects and Mechanisms

**Primary prediction:** β > 0 — network exposure to asylum dispersal increases RN vote share. This is the "network anxiety" channel: departments with strong social ties to hosting areas become more politically activated against immigration even without direct contact.

**Mechanism tests:**
1. **Local contact placebo:** Departments that *directly* received asylum seekers should show null or negative β (contact hypothesis), while the network effect operates only through non-hosting SCI connections.
2. **Cosmopolitan confounding test:** Following apep_0464's design, test whether high-SCI departments are systematically more cosmopolitan (which would bias *against* finding network backlash). Control for education, urban share, incumbent RN baseline.
3. **Migration proxy:** Validate SCI pre-determination using historical migration flows (2013 INSEE migration matrices) as instrument for SCI.

## Primary Specification

**Panel:** ~96 metropolitan departments × 4 elections (2017 presidential R1, 2019 European, 2022 presidential R1, 2024 European). Treatment timing: 2021 (decree December 2020, implementation 2021-2022).

**Pre-periods:** 2 (2017, 2019)
**Post-periods:** 2 (2022, 2024)

**Controls:**
- Department FE, election FE
- Department-level: log population, unemployment rate, education share, foreign-born share, median income
- Lagged RN share (pre-trend control)

**Standard errors:** AKM (Adão, Kolesár, Morales 2019) for shift-share designs, clustered at department level.

## Planned Robustness Checks

1. **Event study:** Interact NetworkDispersal_i with election dummies to show flat pre-trend and post-treatment break
2. **Leave-one-out:** Drop each department from the shift calculation to test no single department drives results
3. **Alternative SCI normalization:** Raw SCI vs. row-normalized vs. log SCI
4. **Alternative treatment measures:** Binary (above/below median NetworkDispersal) vs. continuous
5. **Placebo outcomes:** Turnout, left-wing vote share, centrist vote share (should show null or weaker effects)
6. **Randomization inference:** Permute SCI weights across departments to construct null distribution
7. **Triple-difference:** Compare network effect for departments with vs. without direct asylum reception
8. **Wild cluster bootstrap:** Address small-cluster concerns (96 departments)

## Exposure Alignment (Shift-Share DiD)

- **Who is treated?** Departments with high SCI-weighted exposure to asylum-receiving departments
- **Treatment is continuous:** NetworkDispersal_i varies across departments
- **Primary estimand population:** Voters in all metropolitan departments
- **Placebo/control population:** Departments that directly received asylum seekers (contact channel dominates)
- **Design:** Standard shift-share DiD (not staggered — single treatment timing in 2021)

## Power Assessment

- **Departments:** ~96 metropolitan France
- **Pre-treatment elections:** 2 (2017, 2019)
- **Post-treatment elections:** 2 (2022, 2024)
- **Total observations:** ~384
- **RN vote share SD:** ~8 percentage points (from smoke test: 2014 mean=24.2%, SD=7.7%)
- **MDE:** With 384 obs, department FE (96), election FE (4), and R² ~ 0.8 from FE, residual variation yields MDE ≈ 2-3 pp for continuous treatment at conventional power. This is a meaningful effect given RN shares moved ~9 pp between 2014 and 2024.

## Data Sources

1. **SCI NUTS3:** Facebook/Meta, via Humanitarian Data Exchange (public download)
2. **Election data:** data.gouv.fr aggregated election Parquet (1999-2024)
3. **Asylum reception capacity:** OFPRA/OFII annual reports, data.gouv.fr asylum datasets, Schéma National d'Accueil documents
4. **Controls:** INSEE BDM (population, unemployment, education, income, foreign-born share)
