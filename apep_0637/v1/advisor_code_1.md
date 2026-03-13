# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant C)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** C
**Date:** 2026-03-13T17:47:03.533768

---

**Idea Fidelity**

The submitted paper takes the core identification strategy from the manifest—examiner leniency as an instrument for patent grants—and applies it to the question of whether a granted patent shapes rival filing behavior. However, it departs from the manifest in several important respects. The original plan emphasized CPC-4 based linking to competitors, a suite of rival-level outcomes (grant rate, citation-weighted filings, claim breadth, HHI), heterogeneity along firm size, technology concentration, and specific policy-relevant sectors (pharma), as well as welfare tests linking filings to R&D. The paper instead operates at the broader USPC class level, reports only aggregate class filing responses, and omits the richer competitor-, claim-, and welfare-level analyses. These omissions mean the paper only partially delivers on the manifest’s promises: the identification strategy is faithfully implemented, but the data linkage and economic mechanisms outlined in the manifest remain largely unexplored.

---

**Summary**

The paper uses quasi-random examiners’ leniency to instrument for patent grants, exploiting 1.7 million USPTO utility applications (2008–2015) with powerful first-stage variation ($F>16{,}000$). The 2SLS estimates show that a patent grant has essentially zero effect on the log number of filings within the same USPC class over one to three years (point estimates between 0.0008 and 0.0193, SE ≈ 0.072), with narrow confidence intervals that rule out even modest effects. The paper concludes that the marginal patent grant does not trigger a measurable competitor “arms race” at the technology-class level.

---

**Essential Points**

1. **Outcome aggregation masks the economic mechanism the manifest emphasizes.** The paper measures the response at the level of total class filings, which average over 2,400 applications per year. Even if rival firms strategically file in response to a granted patent, their filings would be a small share of this total and entirely swallowed by the noise. The precision reported (SE ≈ 0.072 in log filings) is high, but the outcome includes massive variation unrelated to the focal application, so the null may simply reflect measurement dilution. The authors need to provide evidence that the outcome is sufficiently sensitive to the intended mechanism—e.g., by estimating the effect on filings by direct competitors (assignees in the same CPC-4 cell) or on newly linked assignees. Without such evidence, the null is uninformative for the theory of defensive patenting.

2. **Standard errors and inference do not account for serial or spatial spillovers.** The paper clusters at the art-unit level, but the outcome aggregates filings across the entire USPC class, which can span multiple art units and years. Competitor responses might be localized in time (short horizon spikes) or correlated across classes, violating the independence assumptions underlying the clustered SEs. The authors should consider clustering at the class level (or two-way clustering) and reporting estimates that allow for heterogeneous temporal or spatial dependence. Otherwise the confidence intervals may understate uncertainty, especially since the null is central to the conclusion.

3. **The causal estimand is not clearly tied to the policy question.** The paper interprets the 2SLS estimate as the effect of a single patent grant on aggregate class filings, but the manifest sought evidence on competitors’ strategic responses. The LATE identified by examiner leniency applies to marginal applications whose grant status is responsive to lenient vs. strict examiners. These “marginal” patents may be less likely to provoke defensive responses, while the patents that do trigger arms races (e.g., high-value, widely cited patents) would be granted regardless. The authors note this in the Discussion but do not attempt to bound or test it. They should either argue more convincingly that the compliers are economically relevant for patent thickets or augment the analysis (e.g., by interacting the treatment with indicators for focal patent quality or citations) to ensure the LATE is informative for the theory.

Given these concerns, the paper is not ready for publication in its current form. The authors should address them before resubmission.

---

**Suggestions**

- **Reorient the outcome to closer proxies for competitor behavior.** The manifest envisioned tracing filings by distinct assignees within the same CPC-4 technology cell, including metrics such as claim breadth, grant rate, and forward citations. The current aggregate-class measure is too coarse to detect targeted defensive responses. Use the Google Patents publications data (already mentioned in the manifest) to identify rival firms (distinct `assignee_harmonized` strings), filter to those active in the same CPC-4 group, and then measure their filing intensity after a focal grant. A firm-level competitor response naturally ties back to strategic patenting theory, makes the magnitudes interpretable (e.g., additional filings per rival), and aligns with the manifest’s mechanism tests.

- **Explore differential effects by focal patent importance.** Defensive patenting theory suggests that only “threatening” patents trigger an arms race. Identify proxies for importance—number of claims, forward citations, continuation status, priority family size—and interact them with the treatment. If granted patents with higher claim scope or citation potential elicit a response while marginal ones do not, that would reconcile a null baseline with theory. Alternatively, stratify the sample by examiners’ propensity to handle high-stakes applications; if the compliers include more routine patents, the null is less informative.

- **Strengthen the exclusion restriction discussion.** The paper assumes competitors cannot observe examiner identity, but they may observe grant delays or timing that correlate with examiner assignments or with technology class congestion. Provide balance tables on additional observables (e.g., application backlog length, type of applicant) to show leniency is orthogonal to other strategic signals. Consider including lagged class-level filing trends or patent family characteristics to absorb class-specific dynamics that could confound the outcome.

- **Revisit the interpretation of null effects.** The paper concludes that individual patent grants are “drops in the ocean,” but the confidence intervals rule out effects smaller than 0.14 log points, roughly 45 filings on average. That is not negligible if we think about strategic implications: 45 filings spread over the next year could represent meaningful defensive activity in some classes. Present additional benchmarks—for example, typical annual entry rates or average filings by the top ten assignees—to contextualize what the estimated precision implies in economic terms.

- **Add robustness using alternative clustering and randomization inference.** Given the aggregated outcome, cluster-robust SEs at the USPC class level (or two-way clustering by class and art unit) and compare. This will reassure readers that the reported null is not an artifact of under-clustering. The permutation test is helpful, but it should be matched to the structure of the second-stage estimator (e.g., randomizing leniency across applications within class rather than art-unit-year). Transparency on robustness strengthens the claim of a “precise null.”

- **Expand the heterogeneity analysis to capture policy-relevant sectors.** The manifest emphasized pharmaceutical classes (A61K) due to policy interest in terminal disclaimers. Construct analogous splits (e.g., compare CPI class effect in high-tech vs. pharma) and report whether the null holds there. Similarly, differentiate between concentrated and diffuse subclasses using actual CPC-4 HHI measures rather than art-unit size, which only proxies concentration. These targeted tests will help policymakers understand whether the null is universal or driven by specific sectors.

- **Formalize the welfare discussion with back-of-the-envelope calculations.** The paper argues that the null implies negative externalities do not arise from marginal grants, but lacks an explicit welfare framework. Use the estimated bounds to quantify the maximum possible defensive filings induced per grant and then translate that into R&D diversion cost (e.g., using average cost of filing or citations as a proxy for quality). Even a rough back-of-the-envelope estimate will make the policy implications more concrete.

---

In sum, the paper addresses an important question with a powerful instrument, but it needs to align more closely with the original manifest’s focus on competitor behavior, sharpen its measurement strategy, and clarify the interpretation of the null. Addressing the points above would substantially strengthen the contribution.
