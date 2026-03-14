# Research Plan: Less Cash in the Drug Economy

## Research Question

Did the staggered rollout of Electronic Benefit Transfer (EBT) across US states (1996-2004) reduce drug-market activity by eliminating paper food stamps as a quasi-currency?

## Why It Matters

Paper food stamps were a well-documented shadow currency in drug markets, trading at roughly 50 cents on the dollar. USDA estimated trafficking rates of ~4% in the 1990s, declining to ~1.6% after EBT. EBT eliminated the physical medium of exchange — the paper coupon — that connected welfare benefits to drug transactions. This is a natural experiment in "accidental currency reform" targeting the drug economy's payment infrastructure.

## Identification Strategy

**Callaway-Sant'Anna Difference-in-Differences** exploiting the staggered state adoption of EBT from 1996 to 2004. All 51 states (including DC) eventually adopted, so identification uses not-yet-treated states as the control group.

**Key strengths:**
- 51 units with staggered timing (8-year rollout window)
- 6+ pre-treatment years (1990-1995)
- Treatment timing driven by federal mandate (PRWORA 1996) and state administrative capacity, not crime conditions
- Modern heterogeneity-robust estimator (CS-DiD)

**Parallel trends assumption:** Crime trends in early-adopting and late-adopting states evolved similarly before EBT implementation. Tested via event study and HonestDiD sensitivity analysis.

## Expected Effects and Mechanisms

**Primary prediction:** EBT reduces drug-market activity (measured by drug abuse violation arrest rates) by eliminating paper food stamps as a quasi-currency in drug transactions.

**Mechanism test (decomposition):**
- Drug arrests should decline (direct drug-market effect)
- Violent crime should decline (drug-trade violence)
- Property crime may decline (reduced SNAP trafficking/fraud)
- Non-drug, non-property crimes: smaller or null effect (placebo)

**Heterogeneity:**
- Effects concentrated in states with higher pre-EBT SNAP caseloads (more "currency" removed)
- Effects stronger in urban states (denser drug markets)

## Primary Specification

$$Y_{st} = \text{ATT}(g,t) \text{ via Callaway-Sant'Anna estimator}$$

Where:
- $Y_{st}$: Crime rate (per 100,000) in state $s$, year $t$
- Treatment: Year of statewide EBT completion
- Control group: Not-yet-treated states
- Clustering: State level (51 clusters)

## Data Sources

1. **EBT rollout dates:** USDA Food and Nutrition Service / SNAP Policy Database. Year of statewide EBT completion by state. Hard-coded from published research (Currie & Gahvari 2008; USDA FNS EBT Status Reports).

2. **Crime data:** FBI Uniform Crime Reporting Program via FRED (Federal Reserve Economic Data) for state-level crime rates:
   - Property crime rate per 100,000
   - Violent crime rate per 100,000

   FBI Crime Data Explorer API for drug-specific arrest data (if available).

3. **Population:** US Census Bureau / FRED for state population denominators.

4. **SNAP caseloads:** USDA FNS for state-level SNAP participation (for heterogeneity analysis).

## Fetch Strategy

1. Use `fredr` R package to download state-level crime rates from FRED (reliable, API key available)
2. Attempt FBI Crime Data Explorer API for drug-specific arrests
3. Hard-code EBT completion dates from published literature
4. If any critical data is unavailable, fail loudly — no simulated data

## Novelty

1. Wright et al. (2017, JLE) studied EBT and crime in **Missouri only**. This is the first nationwide CS-DiD.
2. First paper to decompose EBT's crime effect into drug-market vs. non-drug channels.
3. "Currency channel" framing — distinct from benefit-adequacy or surveillance channels.
4. Modern heterogeneity-robust estimator (CS-DiD) on the full staggered rollout.
