# Research Plan: The Deterrence Gap

## Research Question
Does reducing the frequency of bank examinations increase risk-taking by community banks? Specifically, did the EGRRCPA (2018) extension of examination cycles from 12 to 18 months for banks with $1B–$3B in assets lead to deterioration in loan quality and capital adequacy?

## Policy Background
Section 210 of the Economic Growth, Regulatory Relief, and Consumer Protection Act (signed May 24, 2018; interim final rule August 29, 2018) raised the asset threshold below which well-capitalized, well-managed banks qualify for 18-month (rather than 12-month) on-site examination cycles from $1B to $3B. Approximately 445 additional community banks became eligible, representing a 50% extension in the unsupervised interval between examinations.

## Identification Strategy
**Difference-in-Differences:**
- **Treatment group:** Banks with assets $1B–$3B (CAMELS 1–2, ~445 banks) that gained the 18-month examination cycle
- **Control group:** Banks with assets $3B–$10B (~190 banks) that remained on 12-month cycles
- **Treatment date:** 2018Q3 (single, sharp)
- **Pre-period:** 2016Q1–2018Q2 (10 quarters)
- **Post-period:** 2018Q3–2023Q4 (22 quarters)

The identifying assumption is that absent the policy change, risk-taking trends would have been parallel across the treatment and control groups. We validate this with event-study coefficients and formal pre-trend tests.

## Expected Effects and Mechanisms
The "deterrence gap" hypothesis: longer intervals between examinations reduce the probability of detection for risk-taking behavior, lowering the expected cost of regulatory violations. This predicts:
1. Increased noncurrent loan ratios (primary outcome)
2. Shift in loan composition toward riskier categories (commercial real estate, C&I)
3. Faster asset growth (risk-appetite channel)
4. Possible decline in Tier 1 capital ratios (capital buffer erosion)

A null result is also informative: it would suggest that market discipline or internal governance substitutes for examination frequency.

## Primary Specification
```
Y_{it} = α_i + γ_t + β · (Treat_i × Post_t) + ε_{it}
```
Where Y is the noncurrent loan ratio (NCLNLS/total loans), α_i are bank fixed effects, γ_t are quarter fixed effects, and Treat_i = 1 for banks in the $1B–$3B range. Standard errors clustered at the bank level.

Event-study specification:
```
Y_{it} = α_i + γ_t + Σ_k β_k · (Treat_i × 1{t=k}) + ε_{it}
```
With 2018Q2 as the omitted reference period.

## Data Source and Fetch Strategy
**FDIC BankFind Suite API** (api.fdic.gov): Quarterly call report data for all FDIC-insured institutions. No API key required.
- Variables: REPDTE (date), ASSET, LNLSGR (gross loans), NCLNLS (noncurrent loans), NTLNLS (net charge-offs), ROA, IDT1CER (Tier 1 capital ratio), LNCI (C&I loans), LNCON (consumer loans), LNRE (real estate loans), NUMEMP
- Filters: ASSET between $500M and $10B (include buffer below treatment band for donut tests)
- Frequency: Quarterly, 2016Q1–2023Q4

## Robustness
1. Callaway & Sant'Anna (2021) — though treatment is simultaneous, this validates against contamination from time-varying composition
2. Donut hole: exclude banks very close to $1B and $3B thresholds (manipulation check)
3. Placebo: banks $500M–$1B (already had 18-month cycles — should show no effect)
4. Triple-difference: treated vs control × risky vs safe loan categories
5. Wild cluster bootstrap (bank-level clusters)
