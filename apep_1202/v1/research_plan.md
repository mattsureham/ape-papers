# Research Plan: Preempted from the Doctor's Screen

## Research Question
Did state municipal broadband preemption laws reduce telehealth adoption during the COVID-19 pandemic? If so, did the effect concentrate in rural areas where municipal broadband was the only viable alternative to incumbent providers?

## Identification Strategy
**Design:** Cross-sectional DiD around the COVID-19 telehealth shock (2020Q2).

**Treatment:** Binary indicator for 22 states with municipal broadband preemption laws enacted between 1997-2019, all predetermined before COVID. These laws were passed to protect incumbent telecom providers from municipal competition — their timing is plausibly exogenous to pandemic telehealth demand.

**Control:** 28 states + DC without broadband preemption laws.

**Key insight:** Telehealth was essentially zero before COVID, so pre-trends in the outcome are mechanically satisfied. The identifying assumption is that preempted and non-preempted states would have experienced similar telehealth trajectories absent the laws' effect on broadband infrastructure. We support this with:
1. Pre-COVID internet access trends (ACS) showing the infrastructure channel
2. Event study showing the gap opens precisely at COVID onset
3. Rural × preemption interaction (mechanism should bite hardest where municipal broadband was the only alternative)

## Expected Effects and Mechanisms
- **Main:** Preemption → lower broadband infrastructure → lower telehealth adoption (negative coefficient)
- **Heterogeneity:** Effect concentrated in rural areas (triple-diff: preempted × rural × post-COVID)
- **Mechanism:** Pre-COVID ACS internet subscriptions lower in preempted states (first stage)
- **Magnitude:** Idea smoke test shows 9.1pp rural telehealth gap

## Primary Specification
```
Telehealth_st = α + β(Preemption_s × Post_t) + γX_st + δ_s + θ_t + ε_st
```
Where s = state, t = quarter. State FEs absorb time-invariant confounds; quarter FEs absorb national trends. β captures the differential telehealth trajectory in preempted states post-COVID.

## Data Sources
1. **CMS Medicare Telehealth Trends** (data.cms.gov): State × quarter × rural/urban telehealth utilization, 2020Q1-2025Q1
2. **Census ACS B28002**: State-level broadband/internet subscriptions (annual, 2015-2022)
3. **State preemption law dates**: Compiled from ILSR/BroadbandNow (22 states, 1997-2019)
4. **Controls:** ACS demographics (income, age, education, urbanization)

## Robustness
- Callaway-Sant'Anna treating COVID onset as common treatment with preemption as cross-sectional variation
- Triple-diff: preemption × rural × post-COVID-expansion
- Placebo: non-telehealth Medicare spending (should not respond to broadband)
- Leave-one-out jackknife across treated states
- Controls for Medicaid expansion, telehealth parity laws
