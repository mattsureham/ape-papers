# Research Plan: Does Legal Gambling Kill? Online Sports Betting and Suicide Mortality

## Research Question
Does the staggered legalization of online sports betting across US states cause an increase in suicide mortality?

## Motivation
Clinical evidence shows gambling disorder patients face 15x higher suicide risk (Moghaddam et al. 2015). Recent quasi-experimental work documents that online sports betting legalization worsens self-reported mental health (Humphreys & Ruseski 2024) and increases financial distress (Hollenbeck 2025). Yet no paper tests whether these precursors translate to actual suicide deaths—the most severe and irreversible outcome.

## Identification Strategy
**Callaway–Sant'Anna staggered difference-in-differences** at the state-week level.

- **Treatment:** State legalization of online sports betting (first date mobile wagering goes live)
- **Treated states (14 in 2018–2021 window):** NJ (Jun 2018), PA (Jul 2019), IN (Oct 2019), WV (Aug 2019), CO (May 2020), IL (Jun 2020), IA (Aug 2020), NH (Jan 2020), MI (Jan 2021), TN (Nov 2020), VA (Jan 2021), AZ (Sep 2021), WY (Sep 2021), LA (Jan 2022)
- **Control group:** ~37 states without online sports betting in this window
- **Running variable:** State × week panel, 2016–2021

## Exposure Alignment
The treatment (state-level legalization of online sports betting) affects the **entire adult population** of each treated state, since mobile betting platforms are accessible to anyone with a smartphone. However, the **at-risk population** for suicide through gambling is narrow: clinical evidence suggests 1–2% of adults develop problem gambling, and the 15x elevated suicide risk applies to this subgroup. The outcome (total state-week suicide deaths) captures all suicides regardless of gambling involvement, meaning the design estimates the **intent-to-treat effect** of making mobile betting available. This is the policy-relevant estimand—policymakers decide whether to legalize at the state level, not whether individuals gamble. The key exposure alignment concern is that total suicides may be too coarse to detect effects concentrated in a small at-risk subgroup, which motivates the MDE calculation in the paper.

## Expected Effects and Mechanisms
1. **Main effect:** Positive (increased suicide deaths post-legalization)
2. **Financial distress channel:** Effect should be larger in states with higher pre-existing bankruptcy rates
3. **NFL season amplification:** Stronger effect during NFL season (Sep–Feb) when betting volume peaks
4. **Age heterogeneity:** Stronger among 25–44 males (peak gambling demographics)

## Primary Specification
$$Y_{st} = \alpha + \tau \cdot D_{st} + \gamma_s + \delta_t + \varepsilon_{st}$$
where $Y_{st}$ is the median estimated suicide death count in state $s$ and week $t$, $D_{st}$ is an indicator for online sports betting being legal, and $\gamma_s$, $\delta_t$ are state and week FE. CS-DiD estimates group-time ATTs and aggregates.

## Data Sources
1. **CDC Early Model-Based Provisional Estimates** (data.cdc.gov, dataset v2g4-wqg2): State-week suicide death counts, 51 jurisdictions, 2016–2021. ~15,555 observations.
2. **AGA (American Gaming Association):** State legalization dates for online sports betting.
3. **CDC WONDER** (for annual robustness): State-year age-adjusted suicide mortality rates.
4. **Placebo outcomes:** Transportation deaths and cancer mortality from the same CDC provisional dataset.

## Robustness
- Callaway–Sant'Anna event study (pre-trends test)
- Bacon decomposition of TWFE
- Leave-one-out (excluding each treated state)
- Pre-COVID restriction (NJ/PA/IN/WV only, 2018–2019)
- Placebo outcomes (transportation, cancer)
- NFL season interaction
- Alternative bandwidths (state-month aggregation)
- Wild cluster bootstrap inference (14 treated clusters)

## Key Risks
1. **Small treated cluster count (14):** Requires cluster-robust inference; wild bootstrap essential
2. **COVID confound:** Pandemic caused spike in suicides; need to disentangle from betting legalization
3. **Model-based estimates:** CDC data are modeled, not raw counts—adds uncertainty
4. **Measurement:** Weekly estimates are noisy for small states
