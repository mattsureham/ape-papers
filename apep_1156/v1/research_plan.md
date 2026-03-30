# Research Plan: Mexico's Gender Violence Alerts and Domestic Violence Reporting

## Research Question

Do Gender Violence Alerts (AVGM) increase domestic violence reporting without reducing lethal violence? Mexico's staggered AVGM declarations across 22 states (2015–2021) mandated emergency resources — shelters, legal aid, specialized prosecution, and awareness campaigns — in designated municipalities. This paper estimates the causal effect on domestic violence (DV) reporting rates and feminicide, separating the "reporting channel" (improved institutional capacity surfaces hidden violence) from the "violence channel" (policy reduces actual violence).

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered difference-in-differences.** Treatment is the AVGM declaration date for each state's municipalities. 22 treated states entered treatment between July 2015 and August 2021; 10 states remain never-treated controls.

**Why timing is plausibly exogenous:** AVGM petitions are filed by civil society organizations (not municipalities), undergo multi-year federal administrative litigation (median 2+ years), and the federal declaration date depends on inter-institutional negotiation — bureaucratic delay orthogonal to short-run municipal crime dynamics.

**Key identification assumption:** Absent AVGM, treated municipalities would have followed the same trend as control municipalities. Tested via pre-treatment event study coefficients and property crime placebo (which AVGM does not target).

## Expected Effects and Mechanisms

1. **DV reporting increases** (primary): AVGM mandates shelters, legal aid, training, and awareness. These lower barriers to reporting → more cases appear in administrative data even if underlying violence is unchanged. Expected sign: positive, potentially large.
2. **Feminicide unchanged or modest decrease** (secondary): Feminicide is a "hard" outcome less susceptible to reporting bias. If AVGM reduces lethal violence, we should see a decrease; if it primarily operates through the reporting channel, feminicide should be unaffected. Expected sign: null or small negative.
3. **Property crime unaffected** (placebo): AVGM targets gender violence specifically. Property crime should show no effect.

## Primary Specification

$$Y_{mt} = \alpha_m + \gamma_t + \beta \cdot \text{AVGM}_{s(m),t} + \varepsilon_{mt}$$

Where $Y_{mt}$ is the DV reporting rate per 100,000 population in municipality $m$ at month $t$, $\text{AVGM}_{s(m),t}$ is a binary indicator for whether state $s$ containing municipality $m$ has an active AVGM at time $t$. Estimated via `did::att_gt()` with state-level clustering and wild bootstrap inference (32 clusters).

## Data Source and Fetch Strategy

**SESNSP municipal crime incidence data:**
- Source: GitHub mirror of official datos abiertos (`lapanquecita/incidencia-delictiva`)
- File: `timeseries_municipal.csv`
- Coverage: 2,488 municipalities, 83 crime categories, monthly, 2015–2025
- Key variables: Violencia familiar, Feminicidio, Violación simple, Abuso sexual, Robo (property crime placebo)

**AVGM treatment dates:**
- Source: Data Cívica (avgmciudadana.datacivica.org) and CONAVIM official declarations
- Hard-coded from verified timeline: 22 states with specific declaration months

**Population denominators:**
- CONAPO municipal population projections (for per-capita rates)
- Fallback: INEGI intercensal estimates

## Methodology

- **Estimator:** Callaway-Sant'Anna (2021) via R `did` package
- **Clustering:** State level (32 clusters) — wild cluster bootstrap for inference
- **Event study:** Dynamic ATT(g,t) aggregated to event time
- **Heterogeneity:** Urban vs. rural municipalities; state capacity proxies
- **Robustness:** (1) Sun-Abraham estimator; (2) property crime placebo; (3) leave-one-state-out; (4) alternative population denominators
