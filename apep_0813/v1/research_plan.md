# Research Plan: apep_0813

## Research Question

Did Swiss cantons change their spending composition when CHF 3.5–4 billion in annual federal transfers switched from earmarked conditional grants to unconditional block grants under the 2008 Neuer Finanzausgleich (NFA) reform? And did the resulting fiscal equalization alter inter-cantonal migration patterns?

## Motivation

The flypaper effect — the finding that lump-sum grants increase government spending more than equivalent private income — is one of the most robust anomalies in public finance. But nearly all evidence comes from settings where grants are conditional (earmarked for specific functions). Theory predicts that conditional grants should constrain spending more than unconditional grants. Switzerland's 2008 NFA reform provides a rare natural experiment: it replaced the 1959 system of earmarked federal-cantonal cost-sharing with unconditional resource equalization, while keeping the total transfer volume roughly constant. If spending composition doesn't change when conditionality is removed, the entire apparatus of earmarking is illusory — the flypaper effect dominates regardless.

The migration arm tests a complementary Tiebout hypothesis: if unconditional transfers allow recipient cantons to improve public services or cut taxes, net in-migration should increase, revealing fiscal equalization's effect on the spatial equilibrium.

## Identification Strategy

**Design:** Continuous treatment intensity DiD with a common sharp cutoff (January 1, 2008).

**Treatment variable:** Per-capita NFA transfer amount (CHF), positive for net-recipient cantons, negative for net-payers. Published annually by the EFV (Federal Finance Administration). ~12 net-recipients, ~8 net-payers, ~6 near-zero.

**Specification (main):**
```
Y_{ct} = α_c + α_t + β × (NFA_intensity_c × Post_t) + ε_{ct}
```

Where `NFA_intensity_c` is the average per-capita transfer in the first NFA period (2008–2010), `Post_t = 1(year ≥ 2008)`, and outcomes are cantonal expenditure shares by function, tax multipliers, and net migration rates.

**Event study:**
```
Y_{ct} = α_c + α_t + Σ_k β_k × (NFA_intensity_c × 1(year = k)) + ε_{ct}
```

For k ∈ {2001, ..., 2022}, normalized at k = 2007.

**Inference:** Wild cluster bootstrap at the canton level (26 clusters). Supplement with randomization inference (RI) permuting treatment intensity across cantons.

**Pre-trend validation:** Event-study coefficients for 2001–2006 should be insignificant. Placebo cutoffs at 2004 and 2006.

## Expected Effects and Mechanisms

1. **Flypaper (spending composition):** If the flypaper effect dominates, spending composition should NOT change when grants become unconditional — cantonal preferences were already aligned with federal priorities. If fungibility dominates, recipient cantons should shift spending toward locally preferred functions (e.g., from federally mandated roads to locally preferred social welfare).

2. **Tax response:** Net-recipient cantons might lower tax multipliers (Steuerfuss) with unconditional money. Net-payers might raise them to compensate for lost transfers.

3. **Migration:** If NFA improves fiscal conditions in recipient cantons (lower taxes or better services), net in-migration should increase. Tiebout sorting predicts population flows toward fiscal attractors.

## Primary Specification

**Outcome 1 — Expenditure shares:** Share of total cantonal expenditure allocated to each function (education, health, social welfare, transport/infrastructure). Source: EFV financial statistics.

**Outcome 2 — Tax multipliers:** Cantonal income tax multiplier (Steuerfuss). Source: BFS/cantonal tax offices.

**Outcome 3 — Net migration rate:** (In-migrants − Out-migrants) / Population × 1000, inter-cantonal flows only. Source: BFS PXWeb demographic balance (px-x-0102020000_101).

## Data Sources and Fetch Strategy

| Data | Source | API/Method | Years | Unit |
|------|--------|-----------|-------|------|
| Inter-cantonal migration | BFS PXWeb (px-x-0102020000_101) | POST JSON API | 1981–2024 | Canton-year |
| NFA transfer amounts | EFV Finanzausgleich reports | Download CSV/Excel | 2008–2022 | Canton-year |
| Cantonal public expenditure | EFV financial statistics (FS model) | Download Excel | 2001–2022 | Canton-year-function |
| Cantonal tax multipliers | BFS/EFD tax data | PXWeb or download | 2001–2022 | Canton-year |
| Population | BFS PXWeb | POST JSON API | 2001–2022 | Canton-year |

**Fallback:** If EFV Excel downloads fail programmatically, manually classify cantons as net-recipient/net-payer/near-zero using published EFV summary tables. Treatment intensity classification is well-documented in EFV Wirksamkeitsberichte.

## Robustness Checks

1. Placebo cutoffs (2004, 2006) — pre-trend test
2. Binary treatment (recipient vs. payer) instead of continuous intensity
3. Excluding near-zero cantons (~6) that could contaminate either group
4. Canton-specific linear trends to absorb differential secular trends
5. Leave-one-out: drop each canton, check stability
6. Randomization inference: permute treatment intensity across cantons (1000 draws)
