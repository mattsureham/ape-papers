# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-03-31T18:28:20.072536

---

# 1. Idea Fidelity

The paper partially pursues the original idea but deviates significantly regarding the aggregate policy implication. The manifest explicitly promised a two-stage design: (1) inventor-level mobility effects via examiner IV, and (2) aggregation of these flows as an instrument for state-level knowledge worker supply using Azure QWI data. The submitted paper delivers only the first stage (inventor-level mobility) using USPTO BigQuery data. The state-level employment aggregation (Stage 2) is absent, removing the direct link to "local knowledge worker supply" and place-based policy evaluation promised in the manifest. Additionally, while the manifest flagged the novelty of geographic reallocation, the paper retains the core identification strategy (examiner leniency IV) and data source (USPTO PAIR) accurately.

# 2. Summary

This paper estimates the causal effect of patent rejection on inventor interstate mobility using quasi-random examiner assignment within art units. The author finds that rejection increases the probability of an inventor filing a subsequent patent in a different state by 1.1 percentage points (9% of baseline), with stronger effects for solo and experienced inventors. The result suggests patent examination policy inadvertently redistributes human capital across regions, termed the "rejection drain."

# 3. Essential Points

1.  **Violation of Randomization Assumptions:** The balance tests (Table 3) reveal that examiner leniency significantly predicts pre-determined characteristics, including *prior* interstate mobility (Column 4). This is a critical threat to the independence assumption. If "strict" examiners are systematically assigned to inventors who are already more mobile (or technologies that are more mobile), the exclusion restriction is compromised. The paper acknowledges this but proceeds with causal claims; this must be resolved or heavily qualified.
2.  **Selection Bias via Patenting Continuation:** The outcome variable (mobility) is observed only for inventors who file a *next* patent. If rejection causes inventors to exit the patenting system entirely (as suggested by Farre-Mensa et al. 2020), the sample is truncated. The estimated effect applies only to "continued patenters," potentially biasing the magnitude if exit correlates with mobility (e.g., movers stay in the system, stayers exit).
3.  **Deviation from Manifest Aggregate Goal:** The original idea intended to instrument for state-level knowledge worker supply (QWI data). By stopping at the inventor level, the paper misses the broader policy hook regarding state R&D tax credits and aggregate supply shifts. Either the aggregate stage must be restored, or the title/conclusion must be reframed to avoid implying macro-level supply effects that are not estimated.

# 4. Suggestions

To elevate this paper from a suggestive correlation to a robust causal contribution suitable for *AER: Insights*, I recommend the following econometric and structural improvements. These suggestions constitute the primary path to publication quality.

**Addressing the Balance/Randomization Threat**
The significant placebo test (leniency predicting prior moves) is the most dangerous econometric flaw. Quasi-random assignment within art units is the linchpin of this design. If strict examiners are assigned to sub-fields within an art unit that have higher inherent mobility (e.g., software vs. hardware within a broad tech class), the IV is invalid.
*   **Refine the Fixed Effects:** Instead of art-unit × year, consider art-unit × technology-subclass × year if data availability permits. This narrows the randomization pool.
*   **Examiner Switching Analysis:** Check if inventors who switch examiners (via continuation or divisional applications) show different mobility trends. If possible, restrict the sample to art units with confirmed random assignment protocols (some art units use first-available examiner, others use specialized queues).
*   **Control for Tech Trends:** Add fixed effects for CPC (Cooperative Patent Classification) subclasses rather than just art units. Art units are administrative; CPC classes are technological. Variation within CPC classes is more likely to be random.
*   **Re-evaluate the Placebo:** If the prior move coefficient remains significant, you must explicitly state that the IV identifies a *local* effect conditional on existing mobility trends, rather than a universal causal effect. Consider using the balance test results to bound the potential bias (e.g., using the magnitude of the placebo coefficient to adjust the main estimate).

**Improving Inventor Identification**
The paper relies on name-based matching (`all_inventors` table), acknowledging collisions and variants. In 2024, this is suboptimal given available disambiguated datasets.
*   **Use Disambiguated IDs:** The USPTO and Google Patents Public Data now offer disambiguated inventor IDs (based on Kuhn et al. methods). Switching to these IDs will reduce measurement error in the `Moved` variable. Name collisions often create false "moves" (two different people in different states treated as one mover). This noise likely attenuates your estimates, but systematic errors could bias them.
*   **Firm vs. Inventor Location:** Patent data often records the attorney or firm address rather than the inventor's residence. Ensure the state code reflects the inventor's residence, not the assignee's headquarters. If the assignee moves (e.g., acquisition), the inventor may appear to move without relocating. Control for assignee changes to isolate true inventor mobility.

**Handling Selection Bias (Continued Patenting)**
The outcome is conditional on filing a next patent. Rejection might cause exit, not just mobility.
*   **Survival Analysis:** Include a first-stage analysis on the probability of *any* subsequent filing (exit vs. stay). If rejection causes exit, the mobility sample is selected.
*   **Bounds:** Discuss the direction of bias. If rejected inventors exit the system (stop patenting) rather than move, your mobility estimate is based on a surviving subset. If the "movers" are the ones who stay in the system (because they are more resilient), your estimate is upwardly biased. If the "stayers" are the ones who stay in the system, it's downwardly biased. Explicitly modeling this selection (even qualitatively) strengthens the discussion.
*   **Alternative Data:** If feasible, link to LinkedIn or professional network data to track mobility even when patenting stops. This is ambitious but would solve the selection problem entirely.

**Restoring the Aggregate Link (Manifest Fidelity)**
The manifest promised a state-level supply instrument. Dropping this weakens the policy implication.
*   **Re-integrate QWI Data:** Even if a full Stage 2 IV regression is too noisy, construct the aggregate statistic: "State-level rejection-driven outflow." Correlate this with state-level employment growth in NAICS 541. A simple reduced-form correlation at the state-year level (with state FE) would satisfy the manifest's promise without requiring a full structural aggregate model.
*   **Policy Simulation:** If aggregation is impossible, use the micro estimates to simulate the "brain drain." For example: "California's strict examiner assignment implies X fewer inventors retained annually." This quantifies the policy impact without needing the QWI regression.

**Refining the Mechanism and Interpretation**
*   **Solo vs. Team:** The heterogeneity result (solo inventors move more) is compelling but needs nuance. Solo inventors are often unassigned (no firm). Team inventors are usually assigned to firms. Firm relocation is different from inventor relocation. Control for *assignee* changes. If the firm moves, the inventor moves with it. You want to capture the inventor leaving the firm/state due to rejection, not the firm relocating.
*   **LATE Clarification:** Emphasize that this is the effect for "marginal" applications (those where examiner leniency matters). High-quality patents (always granted) and low-quality patents (always rejected) are excluded. The policy implication applies specifically to the margin of examiner discretion.
*   **Standard Error Clustering:** You cluster at art-unit × year. Consider two-way clustering (art-unit × year and inventor) if there is serial correlation in inventor behavior across applications. However, given the instrument varies at art-unit × year, your current clustering is the conservative choice for the IV variance.

**Writing and Presentation**
*   **Title Adjustment:** If the aggregate stage is not restored, change the title to reflect the micro-focus. "The Rejection Drain" implies a macro flow; "Pat
