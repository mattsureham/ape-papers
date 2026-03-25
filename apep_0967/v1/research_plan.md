# Research Plan: Worker Voice Dismantled — The CSE Reform and Far-Right Voting in France

## Research Question

Did the 2017 Ordonnances Macron, which merged three worker representation bodies (CE, DP, CHSCT) into a single CSE and reduced elected worker representatives by 40-50%, increase far-right (Rassemblement National) voting in more exposed communes?

## Policy Background

Ordonnance No. 2017-1386 (September 22, 2017) created the Comité Social et Économique (CSE), replacing three separate bodies:
- **CE** (Comité d'Entreprise): works council, information/consultation on firm strategy
- **DP** (Délégués du Personnel): individual grievance handling
- **CHSCT** (Comité d'Hygiène, de Sécurité et des Conditions de Travail): health, safety, working conditions

**Key features:**
- Mandatory adoption by January 1, 2020
- Reduced total elected representative seats by 40-50%
- Eliminated CHSCT's autonomous health/safety investigation mission
- Capped successive mandates at three terms
- Also introduced the "barème Macron" capping prud'hommes (labor court) damages

**Treatment timing:** Announced September 2017, phased in 2018-2019, fully mandatory by January 2020. The 2017 presidential election (April-May) was entirely pre-reform. The 2022 election (April) was fully post-implementation.

## Identification Strategy

**Cross-sectional intensity DiD:**

Y_{ct} = α_c + δ_t + β(Intensity_c × Post_t) + X_{ct}'γ + ε_{ct}

Where:
- Y_{ct} = RN first-round vote share in commune c, election t
- α_c = commune fixed effects
- δ_t = election fixed effects
- Intensity_c = share of private-sector establishments with 50+ employees in commune c (from Sirene, measured in 2017 before reform)
- Post_t = indicator for 2022 election
- X_{ct} = time-varying commune controls (population, unemployment)

**Treatment intensity rationale:** Firms with 50+ employees were required to have all three bodies (CE, DP, CHSCT) before the reform. These firms experienced the largest reduction in representation when forced to merge into a single CSE. Firms with 11-49 employees only had DP, so the reform's representational impact was smaller. Firms <11 had no representatives.

**Pre-trend test:** The 2012→2017 change in RN vote share should not correlate with treatment intensity (both are pre-reform). This is the core parallel trends check.

**Dose-response:** Compare effects across bins of establishment size (11-49 vs 50-99 vs 100+) to test whether communes with more 50-99 employee firms (which lost the most representation per firm) show stronger effects.

## Exposure Alignment

The treatment (share of 50+ employee establishments) is measured at the commune level using the Sirene establishment stock file. The outcome (Le Pen vote share) is also commune-level. Alignment: the policy shock operates through firms with 50+ employees that previously had all three representation bodies (CE, DP, CHSCT). Workers in these firms are the directly affected population. The commune-level share captures the structural presence of such firms in each locality. Key assumption: workers tend to live near where they work, so commune-level treatment intensity reflects voter-level exposure. This is stronger in rural/small communes (where commuting is limited) and weaker in urban areas with large commuting zones. We test this by examining heterogeneity across commune size.

**Measurement timing:** Treatment is measured from the 2026 Sirene vintage (current stock), not a 2017 snapshot. This introduces measurement error to the extent that firms crossed the 50-employee threshold between 2017 and 2026. We argue this error is likely classical (attenuating the coefficient) because the rank ordering of communes by establishment size is highly persistent.

## Expected Effects and Mechanisms

**Primary hypothesis:** Communes with higher shares of 50+ employee establishments saw larger increases in RN vote share between 2017 and 2022 (β > 0).

**Mechanism — voice displacement:** When institutional channels for worker grievances (elected representatives, CHSCT safety committees, works councils) are reduced, workers lose a structured outlet for workplace concerns. The far right offers an alternative narrative: "the system doesn't represent you, we will." The Algan et al. (2026) finding that RN voters report feeling isolated and distrustful of institutions is consistent with this mechanism.

**Alternative mechanisms to rule out:**
1. **Economic composition:** Communes with more large firms may have different economic trajectories → control for employment changes, unemployment
2. **Urbanization:** Larger firms concentrate in urban areas → commune FE absorb this
3. **Secular RN rise:** RN grew everywhere → the DiD nets this out via election FE

**Null result interpretation:** If β ≈ 0, this suggests workplace representation reform does not spill into political preferences, implying workplace and political voice are substitutes only at the margin, or that other channels (social media, unions, media) compensated.

## Primary Specification

Main regression with commune and election year FE, clustering standard errors at the département level (~100 clusters).

**Robustness:**
1. Alternative treatment measures (share of 50-99 only; employment-weighted share)
2. Placebo outcomes (Mélenchon vote share, turnout)
3. Pre-trend falsification (2012→2017 as if treated)
4. Controls for local economic conditions
5. Wild cluster bootstrap (for inference with ~100 clusters)

## Data Sources

### 1. Sirene Stock File (Establishment Data)
- **Source:** data.gouv.fr, INSEE Sirene open data
- **Format:** Parquet, ~2.0GB
- **Key variables:** codeCommuneEtablissement, trancheEffectifsEtablissement (size bracket codes: 11=10-19, 12=20-49, 21=50-99, 22=100-199, etc.)
- **Usage:** Compute commune-level share of establishments in 50+ bracket as of 2017

### 2. Presidential Election Results
- **Source:** data.gouv.fr election results
- **Elections:** 2012 first round (April 22), 2017 first round (April 23), 2022 first round (April 10)
- **Key variables:** commune code, candidate vote counts, registered voters, turnout
- **Usage:** Compute RN candidate vote share (Marine Le Pen in all three elections)

### 3. Controls (secondary)
- **INSEE BDM/SDMX:** Commune-level population, employment indicators
- **Département-level unemployment:** From INSEE
