# Research Plan: apep_0652

## Research Question
Does mandating electronic prescribing for controlled substances (EPCS) reduce opioid overdose mortality, or does it merely redirect the crisis from prescriptions to illicit fentanyl?

## The "Hydraulic Hypothesis"
EPCS mandates make it harder to obtain prescription opioids through doctor-shopping, forged prescriptions, and paper-based diversion. But if addicted individuals substitute to illicit fentanyl, total overdose deaths may not fall — the crisis merely changes channels. We call this the **Hydraulic Hypothesis**: squeezing the prescription channel inflates the illicit channel.

## Identification Strategy
**Callaway–Sant'Anna staggered DiD.** 25+ states mandated EPCS between 2016 and 2024, with exact effective dates. Not-yet-treated and never-treated states serve as controls.

Treatment: Binary indicator for state having an active EPCS mandate.

Key assumption: Absent the mandate, opioid mortality trends in treated states would have paralleled those in control states (conditional on state and time fixed effects).

## Primary Specification
Y_{s,t} = α_s + γ_t + ATT(g,t) + ε_{s,t}

Where ATT(g,t) is the group-time average treatment effect from Callaway–Sant'Anna (2021), with group = year of EPCS mandate adoption.

Clustering: State level.
Control group: Not-yet-treated + never-treated states.

## Mechanism Test (Built-in Placebo)
The key innovation: **opioid subtype decomposition**.

| ICD-10 Code | Opioid Type | Expected Effect |
|-------------|-------------|-----------------|
| T40.2 | Prescription opioids (natural/semisynthetic) | DECLINE (direct channel) |
| T40.4 | Synthetic opioids excl. methadone (fentanyl) | NULL or INCREASE (substitution) |
| T40.1 | Heroin | NULL or INCREASE (substitution) |

If EPCS works through the prescription channel:
- T40.2 deaths decline
- T40.4 deaths unchanged or increase (Hydraulic Hypothesis)
- Net effect on total opioid deaths is ambiguous — this is the key empirical question

## Data Sources
1. **CDC VSRR Provisional Drug Overdose Deaths** (Socrata API: data.cdc.gov, resource xkb8-kh2a)
   - State × month × opioid indicator, 2015–2024
   - 11 indicators including T40.2, T40.4, T40.1
   - No suppression concerns at state-month level

2. **EPCS mandate dates** — compiled from NCSL, Pharmacy Times, and state legislation:
   - NY (Mar 2016), ME (Jan 2017), PA (Oct 2019), AZ/CT/IA/MA/NC/OK/RI (Jan 2020), VA (Jul 2020), AL/AR/DE/IN/KY/MO/NV/SC/TN/TX/WA/WY (Jan 2021), KS (Jul 2021), CA/MD/MI/NE/NH/UT (Jan 2022), IL (Jan 2024)

3. **State population** — Census API for per-capita rates.

## Robustness Checks
1. Event study with 8+ pre-treatment periods for early adopters
2. Sun–Abraham estimator as alternative
3. HonestDiD/Rambachan–Roth sensitivity bounds
4. Wild cluster bootstrap (few-cluster inference for early adopters)
5. Placebo: non-opioid overdose deaths (T40.3 methadone as partial placebo; cocaine T40.5)
6. Leave-one-out (drop NY, earliest adopter)
7. Restrict to 2015–2022 to avoid provisional data concerns

## Heterogeneity
1. **Must-access vs. may-access PDMP states** — EPCS may be more binding where PDMP checks were already mandatory
2. **Pre-mandate prescription opioid death rate** — higher baseline = more room to decline
3. **Fentanyl penetration** — states with high illicit fentanyl may see more substitution

## Welfare Calculation
VSL × prevented prescription opioid deaths − VSL × additional illicit opioid deaths (if substitution occurs) − implementation costs.

## Expected Contribution
1. First multi-state causal study of EPCS mandates on opioid mortality
2. Opioid subtype decomposition as mechanism test — isolates prescription vs illicit channels
3. Direct test of the Hydraulic Hypothesis: does supply-side regulation merely redirect addiction?
4. Policy-relevant: informs whether digital health mandates save lives or need complementary demand-side interventions
