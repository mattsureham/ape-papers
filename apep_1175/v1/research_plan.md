# Research Plan: Crushed Futures — OxyContin Reformulation and Labor Market Scarring

## Research Question

Does the 2010 OxyContin abuse-deterrent reformulation — which shifted opioid misuse from prescription to illicit sources — cause labor market scarring in exposed communities? Specifically: do counties with higher pre-reform OxyContin brand dependence experience worse employment and earnings trajectories after the reformulation forced users toward heroin and illicit fentanyl?

## Policy Context

In August 2010, Purdue Pharma replaced crushable OxyContin with an abuse-deterrent formulation. The reformulation did not change legal oxycodone supply but eliminated the ability to crush, snort, or inject OxyContin — the dominant mode of misuse. Alpert, Powell, and Pacula (2018 AER) show this caused substitution toward heroin in high-exposure areas. Evans, Lieber, and Power (2019 JPE) document the resulting mortality spike.

**What's missing:** No paper identifies the causal labor market consequences of the prescription-to-illicit transition specifically. This matters because the policy implications differ sharply: prescription opioid problems suggest supply-side regulation (PDMP, prescriber limits), while illicit opioid labor damage suggests demand-side treatment and harm reduction.

## Identification Strategy

**Instrument:** Pre-reform (2006-2009) county-level OxyContin brand share of total oxycodone pill shipments from DEA ARCOS transaction data. This measures a county's dependence on the specific formulation that became abuse-deterrent.

**Variation source:** OxyContin brand share is determined by Purdue Pharma's marketing territories, distributor sourcing networks, and local prescriber brand preferences — not by county-level addiction vulnerability. Conditional on total oxycodone per capita (overall prescribing intensity), the brand composition is driven by supply-side factors.

**Design:**
1. **Reduced form (primary):** Continuous-treatment event study: Y_{ct} = Σ_k β_k (OxyShare_c × 1[Year=k]) + α_c + γ_t + X_{ct}δ + ε_{ct}. This traces how labor outcomes evolve differentially in high- vs. low-OxyContin-share counties around 2010.
2. **2SLS (supplementary):** Use OxyContin share × post-2010 as instrument for heroin/illicit opioid death rate → QWI outcomes.

**Key threats and responses:**
- *Pre-trends:* Event study reveals any differential pre-trends in high-share counties
- *Confounders:* Control for total oxycodone per capita (level of prescribing), county demographics, industry composition
- *Exclusion:* The reformulation changed the abuse-deterrent properties of one brand, not local economic conditions. Conditional on total prescribing, brand composition should be orthogonal to labor market shocks.
- *SUTVA:* Spillovers across counties are a concern if users migrate. Address with commuting-zone-level analysis as robustness.

## Expected Effects

Higher OxyContin share → larger supply disruption → more heroin substitution → worse labor outcomes:
- Employment: negative (disability, incarceration, mortality reduce labor force)
- Earnings: negative (productivity decline, job loss)
- Separations: positive (involuntary separations increase)
- Hires: negative (reduced labor demand in affected areas, employer reluctance)

Effects likely concentrated among prime-age males (25-44) — the demographic most affected by opioid misuse.

## Data

1. **DEA ARCOS** (Azure: `raw/arcos/arcos_transactions.parquet`): 178.6M opioid pill transactions, 2006-2012. Construct county-level OxyContin brand share of total oxycodone.
2. **QWI** (Azure: `derived/qwi/sa/ns/`): County-quarter-industry-age employment/earnings panel, 2001-2025. Outcomes: Emp, EarnS, HirA, Sep.
3. **CDC WONDER** (API): County-level drug overdose deaths by cause (heroin, synthetic opioids) for first-stage mechanism evidence.

## Primary Specification

```
Y_{ct} = Σ_{k≠2009} β_k (OxyShare_c × 1[Year=k]) + α_c + γ_t + (TotalOxy_c × γ_t) + X_c × γ_t + ε_{ct}
```

Where:
- Y_{ct}: log employment or average earnings in county c, year t
- OxyShare_c: pre-reform OxyContin share (2006-2009 average)
- α_c, γ_t: county and year FEs
- TotalOxy_c × γ_t: total oxycodone per capita interacted with year (controls for prescribing intensity)
- Clustering: state level

## Robustness

1. Commuting zone aggregation
2. Alternative pre-periods for instrument (2006 only, 2008-2009 only)
3. Dropping top/bottom 5% OxyContin share counties
4. Placebo: outcomes for age 55-64 (less affected by opioid misuse)
5. HonestDiD sensitivity to parallel trends violations
