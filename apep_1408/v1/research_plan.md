# Research Plan: apep_1408

## Research Question
Did Colombia's voluntary coca substitution program (PNIS, 2017–2020) reduce coca cultivation in enrolled municipalities, and did the reduction persist or reverse after program payments ended?

## The Empirical Object: The Substitution Mirage
The core question is whether paying farmers to stop growing coca actually works — or whether it creates a *substitution mirage*: temporary compliance during payment windows followed by rapid reversion. This matters because PNIS cost ~$350M and is the centerpiece of Colombia's peace accord drug policy.

## Identification Strategy
**Staggered DiD with Callaway-Sant'Anna estimator.**

- **Unit:** Municipality × year (2001–2023)
- **Treatment:** First PNIS enrollment wave in municipality (Wave 1: 2017 Q4 Putumayo/Nariño/Caquetá; Wave 2: 2018; Wave 3: 2019-2020)
- **Never-treated:** Municipalities with pre-2017 coca cultivation but no PNIS enrollment
- **Outcome:** Log coca hectares (SIMCI/datos.gov.co panel acs4-3wgp, 319 municipalities × 23 years)

**Why this works:** PNIS rollout was determined by the peace accord implementation timeline and local community readiness, not by anticipated coca trends. Pre-trend tests on 2001–2016 coca trajectories will verify parallel trends.

## Expected Effects
- **Short-run (0–2 years):** Large negative effect on coca area during payment window
- **Medium-run (3–5 years):** Possible reversion as payments expire — the "substitution mirage"
- **Mechanism:** Shift from coca to legal crops (testable with eradication method data)
- **Heterogeneity:** Effects stronger in municipalities with better infrastructure, road access, and PDET co-treatment

## Primary Specification
```
Y_{mt} = α_m + λ_t + β × PNIS_{mt} + X'_{mt}γ + ε_{mt}
```
Using Callaway-Sant'Anna ATT(g,t) with never-treated comparison group. Clustered at municipality level.

## Data Sources
1. **Coca cultivation panel** — datos.gov.co resource `acs4-3wgp` (SIMCI): 319 municipalities × 2001–2023
2. **PNIS enrollment** — datos.gov.co resource `v4pt-rnn9`: 56 municipalities, enrollment counts
3. **Eradication events** — datos.gov.co resource `p72f-qcvk`: 145K events with method (voluntary/forced)
4. **PDET municipalities** — datos.gov.co: 170 PDET municipalities for within-PDET comparison
5. **Municipality covariates** — DANE census/projections for population, area

## Exposure Alignment
PNIS treated individual farming families (99,097), but the outcome is measured at the municipality level (56 treated municipalities). The exposure alignment concern is that municipality-level coca area reflects both enrolled and non-enrolled households. This means our estimates capture the net municipality-level effect of PNIS — including any within-municipality displacement from enrolled to non-enrolled plots. The municipality-level estimand is policy-relevant (governments care about territorial coca reduction), but we cannot distinguish household compliance from displacement without household-level data.

## Robustness
1. Pre-trend tests (event study 2001–2016)
2. Placebo: non-PNIS high-coca municipalities
3. Dose-response: pre-PNIS coca intensity × post
4. Within-PDET comparison (nets out PDET investment)
5. Excluding forced eradication surges
6. Wild cluster bootstrap (56 clusters)
