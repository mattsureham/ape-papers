# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-04-02T13:28:08.409215

---

**Idea Fidelity**

The manuscript diverges considerably from the original idea manifest. While the manifest proposed exploiting Colombia’s municipal-level draft lottery (sorteo) and using the randomness of lottery selection as an instrument for actual conscription across cohorts, the submitted paper instead constructs a triple-difference based on gender, conflict intensity, and pre/post-2016 cohorts using Saber exam scores. The lottery-based identification strategy, the use of DANE GEIH microdata, and the focus on conscription’s effects on earnings and employment were central to the manifest but are absent from the paper. As such, the current draft does not pursue the intended natural experiment or the advertised outcomes; it instead analyzes anticipatory educational effects of wartime conscription without leveraging the random assignment mechanism that was highlighted as the novel contribution. This is a substantial departure from the manifest, and the authors should either realign with the original design or justify why the alternate approach is preferable.

---

**Summary**

This paper investigates the effect of Colombia’s wartime conscription on academic achievement, leveraging a triple-difference design that compares male versus female Saber exam scores across high- and low-conflict departments and before versus after the 2016 peace agreement. The author finds negative male-specific effects in high-conflict departments for conflict-era cohorts—about 0.42 points on Saber 11 mathematics and 2.4 points on Saber Pro quantitative reasoning—interpreting these as anticipatory disinvestment triggered by the threat of being drafted. The study further reports heterogeneity by socioeconomic status and presents placebo and robustness checks supporting the gender-specific draft narrative.

---

**Essential Points**

1. **Identification Strategy and Mechanism Clarity:** The core identification claim is that the triple-difference isolates a conscription penalty via gender-specific exposure to the draft. However, the design rests heavily on the assumption that no other gender-differential mechanism changed between conflict-era and peace-era cohorts in high-conflict departments (e.g., gender-targeted violence, labor demand shifts, or schooling reforms). The current evidence—limited to a female placebo—is insufficient to rule out alternative explanations. The authors need to provide more direct evidence that the observed male gap is driven by draft expectations rather than, say, differential male dropout or labor-market reallocations in conflict zones. I suggest exploring additional falsification checks (e.g., outcomes not plausibly affected by conscription) and/or testing whether the gender gap trajectories were parallel before the conflict-era cutoff using older cohorts.

2. **Timing of Treatment and Coinciding Changes:** The choice of 2016 as the cohort cutoff conflates the peace agreement with many other contemporaneous policy and economic changes. Given that the treated cohorts turn 18 around 2014-2016, it would be helpful to show whether similar triple-difference patterns exist for earlier “placebo” cutoffs (e.g., cohorts turning 18 in 2010 vs. 2012) when no peace agreement occurred. Without this, the cohort contrast may capture broader time trends affecting males in conflict departments (possibly related to FARC demobilization, economic shifts, or changes in schooling). The authors should demonstrate that the gender gap did not change differentially across high-/low-conflict departments before peace, which would strengthen the claim that the 2016 peace agreement—and hence the conscription threat—is driving the results.

3. **Interpretation of Anticipatory Mechanism:** The paper argues that the Saber 11 penalty reflects anticipatory disinvestment before military service because the exam precedes draft age. That is plausible but remains speculative without direct behavioral evidence. Are there data on school attendance, subject choices, or dropout that change around age 17 specifically for males in high-conflict cohorts? Can the authors rule out that the observed gaps reflect compositional changes in who takes the exam (even if take-up is high) or early labor-market entry patterns unrelated to anticipatory conscription? The paper would benefit from explicitly testing the anticipatory channel, perhaps by examining within-year age variation relative to draft eligibility or by showing that the penalty does not appear in subjects unlikely to be affected by anticipatory avoidance.

If these issues cannot be convincingly addressed, the paper’s attribution of the observed gaps to a “conscription tax” remains tenuous.

---

**Suggestions**

1. **Strengthen the Connection to Conscription:** Since the title and framing emphasize conscription, the paper should more clearly document how the draft threat manifests for the cohorts under study. Can the authors provide direct statistics on draft lottery intensity, enforcement (batidas), or enlistment rates over time across departments to show that males in high-conflict departments truly faced a greater conscription threat before 2016? Including brief descriptive evidence—perhaps administrative conscription records or media accounts of enforcement—would ground the story and help readers assess whether the triple interaction plausibly reflects draft expectations.

2. **Explore Alternative Comparison Groups:** The DDD relies on females as the untreated group, but there may be other groups similarly unaffected by the draft that can serve as additional controls (e.g., younger male cohorts not yet draft-eligible or male students from departments where the draft was unenforced). Adding such comparisons could help demonstrate that the effect is indeed specific to draft-eligible males in conflict departments. Similarly, the authors could consider using non-math subjects as placebo outcomes (e.g., language scores) if the draft threat should affect all academic performance equally; finding no effect there would reinforce the math-specific interpretation.

3. **Provide More Granular Timing Analysis:** The anticipatory narrative would be strengthened by examining within-cohort variation. For example, does the male penalty differ by exact birth year or by exam year relative to the 2016 agreement? Plotting the triple-difference estimate for each exam year could reveal whether the gap widens as cohorts approach draft age and whether it shrinks abruptly after the peace deal. Such visual evidence would support the claim that the effect tracks the evolving salience of conscription.

4. **Address Potential Spillovers and Selection:** Given that the penalized outcome appears before actual service, the story may hinge on expectations and selection. The authors should investigate whether conflict-era males in high-conflict departments differ selectively in observable characteristics (ability proxies, school type, SES) compared to similar males in low-conflict areas or peace cohorts. Including pre-treatment controls and showing balance would ease worries that compositional changes drive the results. If data permit, tracking cohorts longitudinally (even imperfectly) to observe actual enlistment or dropout could provide direct evidence that the draft threat altered planning decisions.

5. **Expand Discussion of Policy Mechanism:** The paper currently claims that the conscription tax operates through anticipatory disinvestment tied to the libreta militar and draft uncertainty. Expanding this discussion with citations to qualitative or ethnographic work (e.g., interviews with families or schools) would lend credibility to the mechanism. If such sources are unavailable, the authors could construct a theoretical framework or simple model of investment under uncertainty to illustrate how the presence of the draft would depress pre-service effort more for high-SES boys, aligning with the empirical heterogeneity.

6. **Clarify the Scope of Results:** Since the main data are administrative exams, it would be helpful to explicitly state whether the results are identifying average effects on all school-going youth or just those who make it to the exam. This is particularly relevant for high-conflict departments, where dropout may differ by gender. Elaborating on which segment of the population the estimates pertain to will aid in interpreting the size and policy relevance of the conscription tax.

7. **Consider Reframing in Light of Manifest:** If the authors intend to pursue this triple-difference approach, they should address why the lottery-based natural experiment outlined in the manifest was not feasible or preferable. A brief section in the introduction or background justifying the current empirical strategy—and acknowledging the missed opportunity to use the sorteos—would help reconcile the paper with the declared research direction and reassure readers that the most credible identification path was considered.

Overall, the paper tackles an important question about the hidden costs of wartime conscription, but it would benefit from a more robust identification narrative, additional falsification checks, and clearer evidence that the observed effects stem from the draft rather than from other conflict-related shocks.
