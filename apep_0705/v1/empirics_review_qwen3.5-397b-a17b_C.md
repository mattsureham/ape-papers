# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-03-16T20:02:49.879185

---

# Review of "Taxing Away the Shadow: Sweden's Household Services Deduction and the Formalization of Domestic Work"

## 1. Idea Fidelity

The paper pursues the original idea manifest with high fidelity regarding the core identification strategy: exploiting municipality-level variation in pre-reform income as a continuous treatment intensity measure for the 2007 RUT deduction. The authors correctly utilize SCB administrative data and maintain the focus on resolving the Swedish National Audit Office's causal identification gap. However, there is a significant deviation in the employment data usage. The manifest proposed using RAMS data from 2004–2018 (leveraging SNI2002 for pre-reform years), but the paper truncates the sector employment analysis to 2008–2018 (SNI2007 only) due to classification concordance issues. This limits the ability to establish pre-reform employment parallel trends, weakening the mechanism evidence compared to the original proposal. Additionally, the employment specification shifts focus to "Post-2012" effects rather than the 2007 reform date, which diverges from the manifest's primary treatment timing.

## 2. Summary

This paper provides causal evidence that Sweden's 2007 household services tax deduction (RUT) successfully shifted economic activity from the informal to the formal sector. Using a continuous treatment difference-in-differences design across 290 municipalities, the authors find that municipalities with higher pre-reform income intensity experienced 0.6–0.9% higher declared income growth and 1.8% faster service-sector employment growth post-reform. The results survive controls for pre-reform convergence trends and Fisher randomization inference, suggesting that demand-side subsidies can effectively formalize shadow economy work even in high-compliance environments.

## 3. Essential Points

The authors must address the following three critical issues to ensure the validity of the causal claims:

1.  **Fragility of Linear Trend Controls:** The paper acknowledges that high-income municipalities had slower income growth pre-reform (convergence) and controls for this using municipality-specific linear trends. This is econometrically fragile. If the convergence process was nonlinear or naturally terminated around 2007 independent of the policy, the linear trend control will attribute the break
