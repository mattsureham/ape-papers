# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-30T10:38:33.669542

---

**Idea Fidelity**

The paper follows the manifest almost exactly. It exploits the staggered adoption of Swiss cantonal debt brakes (1994–2014) and uses Callaway–Sant’Anna staggered DiD to study how these fiscal rules redistribute the functional composition of spending. The core data sources (EFV functional accounts), functional shares as outcomes, and the comparison between hard and soft rules are all present. The only omission is the manifesto’s explicit mention of mechanism (capital vs. current split) and welfare checks (infrastructure quality, per-pupil spending); the paper focuses narrowly on functional shares and leaves these additional tests implicit. Otherwise, the submitted manuscript preserves the original identification strategy and research question.

---

**Summary**

This short paper uses modern staggered DiD estimators to examine whether cantonal debt brakes in Switzerland distort the functional composition of subnational spending. Drawing on EFV accounts for 24 cantons between 1990 and 2024, the author finds no statistically or economically significant effects on any of the ten spending functions’ shares, even after conducting event studies, wild-cluster bootstrap inference, and robustness checks. A triple-difference exploiting rule stringency uncovers a modest, statistically significant reduction in administration’s share under hard rules, but this does not propagate to investment-heavy categories.

---

**Essential Points**

1. **Pre-trend evidence is mixed and needs clearer interpretation.** The event-study leads for transport and social spending show statistically significant coefficients (e.g., transport $t=-3$: –1.50 pp significant at 5%; social $t=-3$ and $t=-2$: positive and significant). These imply that treated and control cantons had diverging trends before debt-brake adoption, challenging the parallel trends assumption. The paper should investigate whether these lead coefficients survive adjustments for multiple comparisons (given the many cells) and clarify whether they reflect noise or genuine pre-treatment dynamics. Without reassurance, the credibility of the staggered DiD estimates is in question.

2. **The comparison group’s suitability is underexplored.** The identification relies on never-treated (N=4) plus not-yet-treated cantons as counterfactuals, but Table 1 shows meaningful pre-treatment differences: e.g., treated cantons already spent more on “economy” and less on health than controls. Controlling for these differences (either via covariates or by focusing on within-canton changes) and testing whether the results persist when comparing more similar cantons (e.g., by propensity-score weighting or synthetic control) would substantively bolster causal claims. At present one cannot rule out that the null reflects compositional convergence rather than debt-brake effects.

3. **Triple-difference results hinge on very few “soft rule” cantons.** The hard vs. soft specification treats two cantons (Appenzell Ausserrhoden and Innerrhoden) as the entire soft group, yet the paper interprets the estimated heterogeneity as substantive. With only two treated units, the estimate is likely driven by idiosyncratic shocks. The authors should either downplay this finding or supplement it with sensitivity checks (e.g., leave-one-out soft-canton analyses or using alternative proxies for stringency) to demonstrate robustness. As written, it risks over-interpreting noisy heterogeneity.

If these issues cannot be addressed convincingly, the paper should be rejected.

---

**Suggestions**

1. **Strengthen the parallel-trends diagnostics.** Present aggregate balance tests on pre-treatment trends (e.g., joint F-tests on lead coefficients across all functions) or plot aggregated leads to show whether the statistically significant ones are isolated quirks. Consider re-estimating event studies with a lead window trimmed to avoid extreme fluctuations (e.g., focus on $t=-3$ to $t=-1$) or discussing why the significance at $t=-3$ may be due to limited precision rather than actual pre-trend. If the leads persist, explore matching or weighting approaches that align the pre-treatment trajectories of treated and control cantons.

2. **Explore alternative comparison groups or functional balance.** The current design pools all not-yet-treated cantons as the control. To increase credibility, you might (i) restrict the control set to only “never-treated” cantons and check whether results hold (the paper already references four such cantons, but the main tables mix them with not-yet-treated), (ii) implement a weighted DiD using pre-treatment spending shares as covariates, or (iii) run a synthetic control-style exercise for a subset of key functions (e.g., education, transport). These exercises could demonstrate that the nulls are not driven by unbalanced pre-trends.

3. **Contextualize the “null” within statistical power.** While the point estimates are small, a brief power calculation could reassure readers that the study is well powered to detect plausible compositional shifts (e.g., a 2–3 pp change). Panel A of Table 4 already shows fairly wide wild bootstrap CIs; it would be helpful to narrate these intervals in the text (e.g., the education share confidence interval spans roughly ±2.6 pp, so effects larger than that size are ruled out). Doing so emphasizes that the null is informative rather than merely imprecise.

4. **Broaden the outcome set to test mechanisms.** The paper focuses on functional shares, but the manifesto emphasized capital vs. current splits and infrastructure quality. Including outcomes such as capital expenditure shares (if available) or proxies for infrastructure investment (e.g., transport infrastructure spending per capita) would enrich the story. Alternatively, decomposing categories like education into personnel vs. capital outlays (if possible) could detect whether the fiscal rule shifts within-category composition even if aggregate shares remain stable.

5. **Clarify the treatment of always-treated cantons.** St. Gallen and Fribourg were excluded from the main sample because their rules pre-date the panel. However, including them as additional “always-treated” units can strengthen estimation by expanding the treated set. The paper mentions that adding them leaves TWFE estimates unchanged, but this is only true if their treatment effect was constant; in a staggered DiD, they could help sharpen estimates. Consider estimating the Callaway–Sant’Anna specification including these units, or explicitly justify their exclusion (e.g., due to missing pre-treatment variation). If their inclusion is infeasible, discuss how their omission might bias results.

6. **More thoroughly motivate the triple-difference specification.** The narrative around the rule heterogeneity is interesting, but the triple-difference model should be accompanied by a discussion of its identifying assumptions. Are there other differences between hard- and soft-rule cantons (size, language region, fiscal capacity) that might confound the interaction? Adding canton-level controls or showing that the hard-vs-soft comparison is balanced on pre-treatment shares would help. If possible, present pre-treatment trends separately for hard and soft cantons to demonstrate comparable trajectories.

7. **Expand the discussion on external validity.** The null finding is useful but potentially specific to Switzerland’s political and fiscal institutions. A paragraph contrasting Swiss institutional features (e.g., revenue autonomy, direct democracy, equalization system) with settings where fiscal rules have been found to distort composition (e.g., some U.S. states or EU member states) would position the result and help readers gauge generalizability.

8. **Consider non-linear effects or thresholds.** Fiscal rules may only bind in certain years. If data on spending gaps or debt levels exist, you could interact the treatment indicator with a measure of how tightly the rule was binding (e.g., whether a canton breached its limit or had to invoke corrective measures). This would help establish whether the null reflects rules that seldom bind; if they rarely bind, the absence of compositional shifts is less informative about tighter enforcement.

9. **Address the compositional nature of the outcome.** Because the ten shares sum to one, a change in one category necessarily affects others. The paper could acknowledge this feature and, if feasible, apply compositional data methods (e.g., log-ratio transformations) or jointly estimate a system to ensure that the null on each share is not misleading due to the simplex constraint. Even if the current treatment is acceptable, a brief discussion of this issue would clarify interpretation.

10. **Improve transparency around data and replication.** Provide an appendix table listing the exact adoption year and rule type per canton, along with any codification choices (e.g., how partial adoptions were treated). Also, state whether expenditure shares are measured in nominal terms and whether any deflators or population adjustments were used. Sharing a replication archive (even if simulated) would greatly aid verification.

Implementing some of these suggestions would substantively strengthen the paper, bolstering causal claims and broadening the relevance of the findings.
