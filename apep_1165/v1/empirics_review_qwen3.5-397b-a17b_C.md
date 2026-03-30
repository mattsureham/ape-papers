# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-03-30T20:50:32.659396

---

**1. Idea Fidelity**

The paper deviates substantially from the Original Idea Manifest. The manifest proposed a national analysis leveraging ~350 merger events and ~1,000 dissolved municipalities across Switzerland using BFS and EFV national data. The submitted paper, however, restricts the sample to Canton Zurich only, comprising merely 8 merger events and 18 dissolved municipalities. While the manifest listed Zurich data as a component, the primary identification strategy relied on the broader national variation to ensure power and external validity. The shift to a single-canton case study significantly reduces the statistical power and limits the generalizability claimed in the introduction ("global policy lever"). Additionally, while the manifest promised a decomposition by functional category using modern staggered DiD, the paper delivers this only for Zurich. The core identification strategy (C&S 2021) remains consistent, but the scale of the empirical exercise is an order of magnitude smaller than proposed.

**2. Summary**

This paper estimates the heterogeneous effects of municipal mergers on functional spending categories using staggered difference-in-differences (Callaway & Sant'Anna, 2021) within Canton Zurich. The authors find a sharp 33 percent reduction in administrative spending following mergers, while finding null effects for nine service-delivery categories (education, health, transport, etc.). The authors term this the "overhead illusion," arguing that fiscal savings from consolidation are driven exclusively by administrative compression rather than service-delivery efficiency.

**3. Essential Points**

1.  **Inference with Few Treated Clusters:** The identification relies on only 8 treated municipalities (successor entities). While the Callaway & Sant'Anna (C&S) estimator uses multiplier bootstrapping, asymptotic theory is fragile with so few treated groups ($G=8$). The standard errors (e.g., 46.1 on a coefficient of -120.3) may underestimate true uncertainty if there is serial correlation or heterogeneity across these few units. With $N_{treated}=8$, a single outlier merger (e.g., Wädenswil) could drive the result, as hinted at in the leave-one-out checks where estimates range from -73 to -141.
2.  **Missing Event-Study Visualization:** The text claims "pre-treatment event-study coefficients show no evidence of differential trends," yet no event-study figure is included in the LaTeX source. In staggered DiD applications, visual confirmation of parallel pre-trends is non-negotiable, especially with few treated units. Tables alone cannot convey the dynamics of the coefficients leading up to the merger.
3.  **Scope and External Validity:** The reduction from a national sample (~350 events) to a single canton (8 events) undermines the paper's broader policy claims regarding Denmark, Japan, and Germany. Zurich municipalities are wealthier and have different administrative structures than those in Ticino or Fribourg (which had larger merger waves). The paper must explicitly justify why Zurich is representative or temper the claims about global applicability.

**4. Suggestions**

**Strengthening Inference and Robustness**
Given the small number of treated units, you should prioritize inference methods designed for few clusters. The multiplier bootstrap in C&S is a good start, but I recommend supplementing this with a **wild bootstrap** or **permutation inference** (randomization inference) specifically tailored for DiD with few treated units (see *Conley & Taber, 2011* or *Young, 2019*). With only 8 treated municipalities, the distribution of the test statistic may not be well-approximated by the bootstrap if the treated units are heterogeneous. You should report the number of permutations possible and the exact p-value derived from them. Additionally, consider reporting **Conley-Taber style inference** which accounts for the possibility that only a few controls are truly comparable.

Regarding the leave-one-cohort-out checks in Table 3, Panel B: The range of estimates (-73.5 to -141.0) is substantial. While all are negative, the magnitude varies by a factor of two. You should discuss *why* this variation exists. Is it driven by the size of the merger (as you note in Panel C) or specific cantonal subsidies attached to specific cohorts? If the 2019 mergers (Stammheim, Wädenswil) are larger, they might drive the larger effects. Explicitly linking the leave-one-out variation to the heterogeneity analysis would strengthen the narrative.

**Visualizing Identification**
You must include an event-study figure. In the C&S framework, this typically plots the aggregated dynamic treatment effects relative to the base period. This figure serves two purposes: it validates the parallel trends assumption (coefficients should be indistinguishable from zero pre-treatment) and it shows the timing of the effect (immediate drop vs. gradual adjustment). Given your finding of a 33% drop, readers will want to see if this happens instantly in year $t+1$ or phases in over $t+1$ to $t+3$. An instantaneous drop supports the "administrative cut" story; a gradual drop might suggest broader restructuring. Without this figure, the claim of "no differential trends" rests solely on assertion.

**Expanding the Sample (Returning to the Manifest)**
The original manifest identified ~350 merger events nationwide. The restriction to Zurich suggests harmonization issues with the EFV national data. I strongly encourage you to attempt to incorporate at least one additional canton with high merger activity, such as Fribourg (153 dissolutions) or Ticino (160 dissolutions). Even if the functional classification differs slightly, you could harmonize the "Administration" category across cantons. Increasing the treated units from 8 to, say, 50 would drastically improve the credibility of your standard errors and the external validity of the "Overhead Illusion" claim. If national harmonization is impossible, you must explicitly discuss in the data section why Zurich is the *only* viable case (e.g., "Only Zurich publishes consistent functional data over the full period") to justify the scope reduction.

**Mechanism and Heterogeneity**
The heterogeneity by merger size (Panel C) is your strongest mechanistic evidence. Large mergers reduce admin spending by CHF 300 vs. CHF 74 for small mergers. You should expand on this. Does this scale linearly with the number of dissolved councils? If you merge 3 towns, do you eliminate 2 mayors and 2 councils? Providing a simple back-of-the-envelope calculation would be persuasive. For example: "Average mayor salary is CHF X, council compensation is CHF Y. Eliminating 2 sets of these accounts for Z% of the CHF 300 drop." This grounds the econometric result in institutional reality.

Furthermore, consider heterogeneity by **initial administrative intensity**. Do municipalities with higher-than-average admin spending pre-merger see larger drops? This would support the idea that mergers target "bloated" administrations. If the effect is uniform regardless of initial spending, it suggests a fixed cost elimination rather than efficiency correction.

**Placebo and Falsification**
The finance and tax placebo is excellent. I suggest adding a **pseudo-treatment date placebo**. Assign false merger dates to the control municipalities (e.g., shift the treatment date by 3 years) and re-estimate. You should find null effects. This helps rule out the possibility that the result is driven by some secular trend in Zurich municipal finance coinciding with the 2014-2023 window. Additionally, consider a placebo outcome that should *not* be affected but might be correlated, such as private sector wages in the municipality (if data exists) or population growth (mergers shouldn't instantly change population density trends absent migration).

**Clarifying the "Overhead" Definition**
In the Institutional Background, you note administration includes "executive salaries, council compensation, clerical staff, IT infrastructure." In Swiss municipalities, political compensation (Milizsystem) is often modest. Is the CHF 120 drop driven by staff reductions or political consolidation? If possible, distinguish between "Political Administration" (councils, executives) and "Professional Administration" (clerks, IT). If the drop is mostly professional staff, the efficiency implication is different than if it is mostly political overhead. The EFV classification might allow this split (e.g., "General Administration" vs. "Organs"). If not, acknowledge this limitation.

**Writing and Framing**
Finally, adjust the introduction to reflect the actual sample size earlier. Currently, the abstract and intro highlight the global context and the "first functional decomposition," but the Zurich limitation appears in Section 2. Move this limitation to the introduction to manage reader expectations. Frame the paper as a "high-resolution case study" rather than a national evaluation. This protects you from criticism regarding external validity while highlighting the strength of your granular data.

The core finding—that savings are in overhead, not services—is economically meaningful and policy-relevant. However, the credibility of the magnitude hinges on convincing the reader that the 8 treated units are not driving a spurious result through fragile inference. Strengthening the inference section and visualizing the pre-trends will go a long way toward securing publication.
