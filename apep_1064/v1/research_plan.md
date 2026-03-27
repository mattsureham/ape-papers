# Research Plan: Payment Infrastructure and the Formalization Margin

## Research Question

Does the adoption of instant digital payment infrastructure cause microenterprise formalization? We exploit Brazil's nationwide launch of Pix on November 16, 2020 and cross-municipal variation in pre-existing mobile phone penetration to estimate the causal effect of digital payment adoption on business registration.

## Identification Strategy

**Continuous treatment intensity DiD.** All 5,570 Brazilian municipalities are "treated" by Pix simultaneously, but adoption intensity varies based on pre-existing mobile phone penetration (ANATEL 2019 data). Municipalities with higher mobile penetration adopted Pix faster and more intensely, generating continuous treatment variation.

**Key specification:**
$$Y_{mt} = \alpha_m + \gamma_t + \beta \cdot (\text{Mobile}_m \times \text{Post}_t) + X_{mt}\delta + \varepsilon_{mt}$$

where $Y_{mt}$ is new business registrations per 10,000 population in municipality $m$ at time $t$, $\text{Mobile}_m$ is 2019 mobile phone density (per 100 inhabitants), $\text{Post}_t$ indicates months after November 2020, $\alpha_m$ and $\gamma_t$ are municipality and month-year fixed effects.

**Event study specification** with leads/lags to verify parallel pre-trends across the mobile penetration distribution.

## Expected Effects and Mechanisms

**Primary channel:** Pix reduces the cost of accepting formal payments. Informal microenterprises that previously relied on cash now face lower barriers to offering digital payment options — but only if they register as MEI (Microempreendedor Individual). The "formalization margin" is where the convenience gain from digital payments exceeds the compliance cost of registration.

**Expected direction:** Positive effect on MEI registrations, strongest in municipalities with high mobile penetration and large informal sectors.

**Magnitude prior:** We expect moderate effects (SDE 0.05–0.15) given that formalization decisions involve multiple margins beyond payment method.

## Primary Specification

- **Unit:** Municipality-month panel
- **Sample:** ~5,570 municipalities × ~48 months (Jan 2019 – Dec 2022)
- **Treatment intensity:** 2019 ANATEL mobile phone density (per 100 inhabitants)
- **Primary outcome:** New MEI registrations per 10,000 population (Mapa de Empresas)
- **Secondary outcomes:** (1) Total new CNPJ registrations; (2) Pix transaction volume per capita; (3) Formal employment (CAGED)
- **Fixed effects:** Municipality + year-month
- **Clustering:** State level (27 clusters — sufficient for conventional inference with wild bootstrap)
- **Controls:** Municipality × linear time trends, state × month FE (robustness)

## Robustness and Diagnostics

1. **Event study:** Pre-trend test across mobile penetration quartiles
2. **Placebo outcomes:** Agricultural land area, public employment — should not respond to digital payments
3. **Placebo treatment:** Pre-2020 "pseudo-treatment" at November 2018
4. **Leave-one-state-out:** Sensitivity to individual state removal
5. **Alternative instruments:** Internet access (PNAD) instead of mobile penetration
6. **Heterogeneity:** Urban vs. rural; high vs. low pre-existing informality (proxied by MEI share); North/Northeast vs. South/Southeast

## Data Sources and Fetch Strategy

| Source | Data | Access |
|--------|------|--------|
| BCB Pix OData API | Municipal Pix transactions, monthly | REST API (confirmed) |
| Mapa de Empresas / QSA (Receita Federal) | CNPJ/MEI registrations by municipality-month | Base dos Dados BigQuery |
| IBGE SIDRA | Municipal population, CEMPRE business counts | REST API (confirmed) |
| ANATEL | Municipal mobile phone density 2019 | Public CSV/API |
| CAGED (via Base dos Dados) | Formal employment by municipality-month | BigQuery |

**Fetch order:** ANATEL → BCB Pix → IBGE population → Mapa de Empresas → CAGED

## Exposure Alignment

The treatment (Pix launch) affects all municipalities simultaneously, but adoption intensity varies with pre-existing digital readiness (proxied by 2010 Census urbanization). The outcome (enterprise registrations from CEMPRE) is measured at the municipality level—the same geographic unit as the treatment intensity variable. Both treatment exposure and outcome are observed annually at the municipality level, ensuring proper exposure alignment. The identifying variation comes from the interaction of a time-invariant municipality characteristic (urbanization) with a discrete temporal shock (Pix availability), not from cross-unit differences in treatment timing.

## COVID Consideration

Pix launched during COVID-19. We address this by:
1. Including state × month FE to absorb differential pandemic trajectories
2. Showing that COVID intensity (cases/deaths per capita) does not correlate with mobile penetration conditional on controls
3. Noting that COVID would bias formalization *downward* (economic contraction), working against finding a positive Pix effect — our estimates are conservative
