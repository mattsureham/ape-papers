# Initial Research Plan: Do Policy Reversals Undo Effects?

## Research Question

When governments repeal a policy, does the outcome return to its pre-policy level? This paper estimates the "reversal ratio" — the fraction of the original policy effect that unwinds upon repeal — for five European reforms that were both introduced and reversed within a short window. A reversal ratio of −1 indicates full unwinding; values closer to 0 indicate hysteresis.

## Why This Matters

Policymakers routinely debate whether to extend temporary programs or sunset permanent ones. The implicit assumption is that effects are reversible — stop the policy, stop the effect. But if habit formation, sunk costs, or institutional lock-in create hysteresis, then temporary programs have permanent consequences and the option value of policy experimentation is lower than standard models suggest. Despite its importance, there is essentially no systematic evidence on this question.

## The Five Reforms

| # | Country | Policy | ON Date | OFF Date | Duration | Domain | Primary Outcome |
|---|---------|--------|---------|----------|----------|--------|----------------|
| 1 | Denmark | Saturated fat tax (DKK 16/kg) | Oct 2011 | Jan 2013 | 15 months | Price/consumption | HICP food prices (prc_hicp_midx) |
| 2 | Czech Republic | Healthcare co-payments (CZK 30-90) | Jan 2008 | Jan 2015 | 7 years | Health | Health expenditure by financing (hlth_sha11_hf) |
| 3 | Italy | Reddito di Cittadinanza (basic income) | Apr 2019 | Aug 2023 | 4.5 years | Transfer/labor | At-risk-of-poverty rate (ilc_li41), employment by region (lfst_r_lfe2emprt) |
| 4 | Poland | Retirement age (raised to 67) | Jan 2013 | Oct 2017 | 4.75 years | Labor | Employment rate by age/sex (lfsq_ergan) |
| 5 | France | 75% supertax on income >€1M | Jan 2013 | Dec 2014 | 2 years | Tax/labor | Labor cost index (lc_lci_r2_q) |

## Identification Strategy

### Within-Reform Symmetric DiD

For each reform *r*, we estimate a "switch-on" and "switch-off" specification:

**Switch-ON:** Y_{ct} = α + β^ON · Treat_c · Post^ON_t + γ_c + δ_t + ε_{ct}

**Switch-OFF:** Y_{ct} = α + β^OFF · Treat_c · Post^OFF_t + γ_c + δ_t + ε_{ct}

where c indexes countries (or regions/product categories within country), t indexes time, and Treat identifies the treated entity.

The **reversal ratio** is: RR_r = β^OFF_r / β^ON_r

- RR = −1: full reversal (perfect symmetry)
- RR ∈ (−1, 0): partial reversal (some hysteresis)
- RR = 0: no reversal (complete hysteresis)
- RR > 0: perverse dynamics (reversal amplifies rather than undoes)

### Treatment-Control Assignments

| Reform | Treated | Control | Unit | Frequency |
|--------|---------|---------|------|-----------|
| Denmark fat tax | DK food prices (CP0111-CP0122) | DK non-food prices (CP03-CP09) | Product category × month | Monthly |
| Czech co-payments | CZ household OOP health expenditure | CZ government health expenditure | Financing scheme × year | Annual |
| Italy RdC | IT regions with high initial poverty | IT regions with low initial poverty | NUTS2 × quarter | Quarterly |
| Poland retirement age | PL women 60-64 (directly affected) | PL men 60-64 (less affected, threshold was already 65→67) | Sex-age group × quarter | Quarterly |
| France supertax | FR labor cost index (total economy) | DE/NL/BE labor cost index (unaffected neighbors) | Country × quarter | Quarterly |

### Placebo Tests (Built-in)

Each reform has a natural placebo group:
- Denmark: non-food HICP categories (no fat tax applies)
- Czech Republic: government spending on health (co-payments affect household OOP, not government share)
- Italy: Northern regions with very low baseline poverty (minimal RdC take-up)
- Poland: Men 60-64 (less binding margin, since male retirement was 65→67 vs female 60→67)
- France: Neighboring countries (no supertax)

## Expected Effects and Mechanisms

### Hypothesis 1: Price instruments reverse more fully than eligibility programs
- Fat tax (price) should show RR ≈ −1 (quick pass-through)
- RdC (eligibility) should show |RR| < 1 (behavioral lock-in, welfare stigma reduction)

### Hypothesis 2: Shorter policies reverse more fully
- Denmark (15 months) should reverse more than Poland (4.75 years)
- Mechanism: longer exposure creates deeper habit formation

### Hypothesis 3: Labor supply effects exhibit greater hysteresis than price effects
- Poland retirement (labor) and Italy poverty (labor-adjacent) should show lower |RR| than Denmark (price)
- Mechanism: job search frictions, employer expectations, career path dependence

## Primary Specification

For each reform, estimate event-study coefficients:

Y_{ct} = α + Σ_k β_k · D_{ct}^k + γ_c + δ_t + ε_{ct}

where k indexes periods relative to both the introduction and reversal dates. The event study has two events: one "switch-on" window and one "switch-off" window.

## Robustness Checks

1. **Placebo outcomes** — estimate the same specifications on unaffected categories
2. **Synthetic control** — for single-country reforms, construct counterfactual from untreated neighbors
3. **Permutation inference** — with N=5 reforms, use randomization of reform assignment for meta-regression
4. **Leave-one-out** — verify meta-regression results are not driven by any single reform
5. **Alternative comparison groups** — vary the control group for each reform
6. **Bandwidth sensitivity** — vary the pre/post windows symmetrically

## Exposure Alignment (DiD Requirements)

- **Who is actually treated?** Varies by reform: consumers (DK), patients (CZ), low-income households (IT), near-retirement women (PL), high earners/employers (FR)
- **Primary estimand:** ATT for each reform's target population
- **Placebo/control:** Non-affected groups within same country (see table above)
- **Design:** Standard DiD (not staggered — each reform is its own episode)

## Power Assessment

| Reform | Pre-periods | Treated units | Post-ON periods | Post-OFF periods |
|--------|------------|---------------|-----------------|-----------------|
| Denmark fat tax | ~36 months | ~12 food COICOP | ~15 months | ~36 months |
| Czech co-payments | ~5 years | 1 financing scheme | ~7 years | ~5 years |
| Italy RdC | ~16 quarters | ~10 high-poverty regions | ~17 quarters | ~8 quarters |
| Poland retirement | ~12 quarters | 1 sex-age group (women 60-64) | ~19 quarters | ~12 quarters |
| France supertax | ~12 quarters | 1 country (FR) | ~8 quarters | ~12 quarters |

The Denmark case is the most powerful (high-frequency monthly data, multiple treated product categories). The France case is the weakest (single treated country).
