# Internal Review: "The Democratic Cost of Consolidation: Municipal Mergers and Referendum Participation in Switzerland"

**Reviewer:** Claude Code (Internal Review, Reviewer 2 style)
**Date:** 2026-03-04
**Paper:** apep_0501/v1

---

## Summary

This paper investigates whether Swiss municipal mergers reduce citizen participation in federal referendums. Using commune-level turnout data from 1960 to 2025 and a BFS merger timeline covering 637 events, the author employs both traditional TWFE and a stacked difference-in-differences design. The central methodological finding is that TWFE produces a near-zero estimate (0.05 pp, n.s.) while the stacked DiD yields -1.67 pp (p<0.001), with the divergence attributed to an Ashenfelter's dip: merging communes were already on declining turnout trajectories for a decade before merger. A dose-response analysis finds, counterintuitively, that larger mergers produce smaller turnout declines, which the author interprets as evidence for community identity loss rather than free-riding as the dominant mechanism. HonestDiD bounds confirm statistical significance only under strict parallel trends (M=0), with the confidence set widening to include zero at M=0.5*Delta.

The paper addresses an important and understudied question. The setting is genuinely excellent — Swiss federal referendums provide very high-frequency, administratively precise outcome data, and the BFS retrospective harmonization elegantly solves the boundary-change measurement problem. The paper's methodological self-awareness is a genuine strength. However, several serious identification concerns require explicit attention before the paper can be considered ready for a top-five journal.

---

## I. Contribution and Positioning

**Strengths.** The paper makes a clear contribution by being the first systematic study of consolidation effects on direct democratic participation (as opposed to representative elections). The distinction matters: in a referendum system, voter withdrawal is a withdrawal from policy itself, not merely from candidate selection. The framing around Ashenfelter's dip as a selection story rather than a nuisance is novel and adds methodological value for the broader literature on program evaluation with trend-based selection.

**Concerns.**

1. **Koch and Rochat (2017) overlap.** The paper cites Koch and Rochat (2017) as a study of the Glarus reform but does not clearly differentiate this paper's contribution from theirs. Koch and Rochat study a single canton (Glarus), using a similar turnout outcome. The present paper treats Glarus as an outlier and excludes it as a robustness check. The author should explain more precisely what the present paper adds relative to Koch and Rochat: is it the national scope, the methodology, the dose-response analysis, the identification of Ashenfelter's dip? The contribution section would benefit from a direct sentence stating what Koch and Rochat found and why the present paper supersedes or complements it.

2. **The Callaway-Sant'Anna estimator is missing.** The paper cites Callaway and Sant'Anna (2021) in passing but does not implement their group-time ATT estimator as an alternative to the stacked design. Given that the paper's central methodological claim is that stacked DiD outperforms TWFE, the natural complement is to also show CS-DiD estimates. The omission of CS-DiD, which is now standard practice at top journals when staggered timing is present, will draw referee criticism. The stacked approach and CS-DiD are not identical — they weight cohorts differently — and comparing them would strengthen the paper's empirical case.

3. **Harjunen et al. (2021) comparison.** The paper notes this Finnish study found larger turnout effects for involuntary consolidations. The Swiss setting is entirely voluntary, which the author correctly acknowledges as a source of attenuation. However, the literature comparison would be strengthened by noting whether the Finnish study faced similar pre-trend issues and whether their identification strategy addressed it. If they did not, the present paper's -1.67 pp may actually be the most credible estimate of voluntary merger effects in the literature.

---

## II. Identification

This is the paper's most exposed area. I have substantial concerns.

**Concern 1: The stacked DiD addresses heterogeneous timing but does not solve the Ashenfelter's dip.**

The author correctly argues that the ±5-year window reduces the scope for long-run trend divergence. But the event study (Figure 1, Table 3) shows that within a 5-year pre-merger window, the pre-treatment coefficients are still negative and jointly significant: the coefficients at e=-5 (-1.36 pp) and e=-4 (-1.14 pp) are both statistically significant at the 5 percent level. This means the declining trend is not a distant pre-history that the narrow window excises — it is still present within the window itself.

The stacked DiD estimate of -1.67 pp therefore captures the additional decline in turnout in the 5 post-merger years relative to the 5 pre-merger years, relative to the same difference for controls. If treated communes were declining at, say, 0.25 pp per year relative to controls within the window, a mechanical continuation would produce a 1.25 pp aggregate decline over five years — a substantial fraction of the estimated -1.67 pp. The author acknowledges this on page 27 but does not quantify the potential bias. A simple back-of-envelope calculation, or a linear trend correction within the stacked window, would allow the reader to bound the degree of residual contamination.

**Concern 2: The dose-response specification uses TWFE, not stacked DiD.**

Table 7 (dose-response) uses the TWFE specification (Equation 5), not the stacked DiD. This is a significant inconsistency. The paper's entire argument is that TWFE is contaminated by selection on pre-trends in the main result. Why should the dose-response results be free of this contamination? If the selection-on-trends bias varies systematically with merger size (e.g., if communes with larger size ratios tend to be absorptions where the dominant commune was not in civic decline, whereas equal-partner fusions involve both communes declining), then the TWFE dose-response coefficient could be capturing differential selection rather than a differential treatment effect. The author briefly acknowledges this possibility on page 28 ("the dose-response captures differential selection rather than a differential treatment effect") but describes it as "beyond the scope of the present analysis." This is not credible at a top-five journal. At minimum, the dose-response analysis should be repeated in the stacked DiD framework. If data limitations prevent this, the author should explain precisely why.

**Concern 3: The control group is contaminated by "clean control" assumption violations.**

The stacked design uses communes that experienced no merger during 2000–2020 as clean controls. However, the control pool of 1,917 communes includes communes whose mergers occurred after 2020. The author notes (page 12) these "contribute only pre-treatment observations within any relevant estimation window." But in the stacked design, a commune merging in 2022 would be a control for cohort 2018 during the pre-2020 window, then become treated in 2022. If anticipation effects begin before 2022 — and the paper's own evidence suggests anticipation concerns exist (Section 5.7.3) — these communes' control-period observations may be contaminated. The author should either exclude post-2020 mergers from the control group entirely or demonstrate that results are robust to doing so.

**Concern 4: The BFS retrospective harmonization introduces a mechanical pre-trend.**

The paper discusses (pages 10-11 and 30) that the BFS reports all referendum results in current (2025) boundaries. This means that the pre-merger turnout for a treated commune is already an aggregated weighted average of what will become the merged entity's predecessor communes. This is important but under-examined. If the predecessor communes had divergent pre-merger trends — one declining (driving the merger decision) and one stable — the BFS aggregate smooths these over, potentially attenuating the pre-trend that the event study shows. Conversely, if the BFS weights are proportional to current electorate (post-merger), and the absorbed commune has shrunk faster than the absorbing commune before the merger, the pre-merger aggregate could overstate the true pre-merger turnout of the eventually-merged unit. The direction of bias depends on the specific aggregation rule the BFS uses, which the paper does not fully specify. The author should either obtain the BFS aggregation methodology documentation or flag this as a measurement concern with unknown direction.

**Concern 5: The Ashenfelter's dip framing is partially inconsistent with the post-treatment pattern.**

In the canonical Ashenfelter's dip, treated units' outcomes recover post-treatment as regression to the mean occurs. The author argues this setting is different because "merging communes do not show evidence of mean reversion in the absence of treatment." But this claim cannot be directly tested — we only observe post-merger outcomes for merged communes, and we cannot observe what would have happened absent the merger. More importantly, Figure 1 shows post-treatment coefficients that decline from -2.36 at e=0 to approximately -0.64 at e=10. The author interprets this recovery as evidence of identity reformation. But if the selection-on-trends story is correct and the pre-existing decline would have continued without the merger, the partial post-treatment recovery might instead reflect regression to the mean of that trend. The author needs to grapple more explicitly with the interpretation of post-treatment dynamics under both the "merger caused the drop" and the "trend continuation" scenarios.

---

## III. Inference

**Cluster level.** Standard errors are clustered at the commune level, which is appropriate for serial correlation within communes. For the stacked design, the author correctly uses the original commune identifier rather than the stacked identifier (a non-trivial and correct implementation choice). However, there may be spatial correlation across communes within the same canton. Cantonal merger incentive programs create correlated treatment timing within cantons, which means error terms may be correlated within cantonal clusters. The author should consider two-way clustering at commune and canton levels, or at minimum show canton-clustered standard errors as a robustness check. With 26 cantons, there are enough clusters for asymptotic validity.

**Figure 3 is missing the control series.** The caption for Figure 3 states the figure shows average referendum turnout for treated communes (red) and control communes (blue), but the figure as reproduced appears to show only the red series. This may be a rendering issue, but it needs correction — Figure 3 is intended to provide visual evidence of the Ashenfelter's dip and the absence of a control series undermines this purpose entirely.

**HonestDiD implementation.** The HonestDiD analysis is applied to the TWFE event-study estimates, not to the stacked DiD event study. Since the paper's preferred estimate is the stacked DiD, the HonestDiD analysis should be applied to a stacked DiD event study for consistency. The current implementation, applied to a TWFE that the author argues is misspecified, is formally valid but potentially misleading — the confidence bounds at M=0 reflect assumptions about trend violations in the TWFE specification, which may not translate directly to the stacked specification.

**The dose-response p-values.** Table 7 reports beta_2 = +5.14 with SE = 2.041, significant at p<0.05. This is a borderline result with a t-statistic of approximately 2.52. With 197 treated communes and a continuous interaction variable, this result may be sensitive to outliers. The author should show a binned scatter plot of the dose-response relationship with confidence intervals to demonstrate that the positive slope is not driven by a small number of very large or very small mergers. Figure 2 shows quartile averages but not standard errors for each quartile, making it difficult to assess precision.

---

## IV. The Dose-Response Mechanism Test

The dose-response analysis is the paper's most interesting empirical contribution — the claim that larger mergers produce smaller turnout declines challenges standard collective-action predictions and supports community identity loss as the dominant channel.

However, the mechanism test as constructed is incomplete. The author identifies three channels (scale/free-riding, identity loss, administrative disruption) and two predictions that differentiate them (dose-response sign, timing). But the absorption-vs-fusion typology defined in Section 2.3 — which maps directly onto the asymmetric vs. symmetric merger distinction that underlies the identity channel prediction — is never used as a formal test variable. If identity loss is concentrated in absorbed communes (Section 2.3 says "identity loss is concentrated in the absorbed commune" in absorptions), then the turnout effect should differ between absorption events and fusion/aggregation events. The author defines this typology and codes it from BFS data but never uses it in a regression. This is a glaring omission given that it would provide a more direct and less confounded test of the identity channel than the size ratio.

Additionally, the paper does not test Prediction 4 (persistence/gradual deepening) formally. The event-study dynamics show recovery, which the author says is consistent with either identity reformation or trend reversion. A formal test would compare the post-treatment event-study profiles for large versus small mergers: under the identity channel, large mergers (absorptions where one commune's identity is erased) should show quicker recovery (as residents adapt) while small equal-partner fusions should show either slower recovery (both communities' identities must rebuild) or different dynamics. This is testable with the existing data.

---

## V. Robustness Gaps

**Missing:** The paper shows TWFE excluding Glarus and a matched DiD, but does not show:

1. **Stacked DiD with different window widths.** Using ±3 years instead of ±5 years would test whether the result is sensitive to window choice and help bound the residual pre-trend contamination concern raised above.

2. **Canton fixed effects.** The cantonal merger incentive programs (Fribourg, Ticino, Graubunden, Thurgau) create correlated treatment timing. Including canton-by-year fixed effects, or canton-specific linear trends, would absorb cantonal reform waves and test whether the result is driven by cantons that had active merger programs.

3. **Heterogeneity by merger type.** As noted above, absorption vs. fusion as a treatment variable is defined but never tested.

4. **Separate analysis by time period.** Mergers before 2011 (pre-Glarus wave) and after 2011 may have different dynamics. Postal voting (universally adopted by 2005) changed the cost structure of participation; mergers after the postal voting transition may have smaller administrative disruption effects.

5. **Proposition-type heterogeneity.** Federal referendums vary substantially in salience (immigration quotas vs. technical infrastructure decisions). High-salience votes that drive turnout nationally may swamp the merger effect; low-salience votes may be more affected. The paper's outcome is mean turnout across dates, but exploring whether the effect is concentrated in low-salience referendums would sharpen the mechanism story.

---

## VI. Presentation and Exposition

**Strengths.** The paper is exceptionally clearly written. The conceptual framework (Section 3) is well-organized, the empirical strategy section is honest about limitations, and the discussion of TWFE vs. stacked DiD divergence (Section 6.2) is a model of methodological transparency. The HonestDiD interpretation in Appendix B.3 is unusually honest about what the data can and cannot establish.

**Issues.**

1. **Figure 3 appears to be missing the control group series.** The caption mentions blue control communes but only the red treated series is visible. This must be corrected.

2. **The dose-response bar chart (Figure 2) lacks confidence intervals on the quartile estimates.** The impression from the figure — that Q1 is clearly negative, Q2-Q3 ambiguous, Q4 positive — could easily reverse with standard errors. Replace with a scatter plot or add error bars.

3. **The event study (Figure 1) bins endpoints at ±10.** With the full panel extending to ±10, this is fine for standard analysis. However, the post-treatment coefficients at e=+9 and e=+10 have large standard errors (-1.123, SE=0.858 and -0.637, SE=1.121), yet the narrative on page 20 states the effect "gradually diminishes" to -0.64. This description is imprecise — the point estimate is indeed small but spans a range from about -2.7 to +1.5 at 95% confidence at e=+10. The partial recovery story should be stated more tentatively.

4. **Abstract claims p<0.001 for stacked DiD but Table 2 reports SE=0.237 and ATT=-1.672.** With t-stat of approximately 7.05 this is indeed highly significant. However, the abstract states "p<0.001" while the full specification Table 6 uses *** for p<0.01. These are consistent but the precision of the abstract claim should be matched to what is reported in the tables (*** = p<0.001 is appropriate since the threshold for three stars in Table 6 is p<0.01 and the t-stat easily clears 3.29).

5. **The matched DiD (Section 5.5) is presented as a robustness check but its failure is actually used as additional methodological evidence.** This is a legitimate use, but the paper should be explicit about this: the matched DiD result is informative not because it provides a robust estimate of the ATT but because its failure to detect an effect, despite balancing on levels, confirms that the selection operates on trends rather than levels. The text could frame this more clearly.

---

## VII. Minor Comments

- Section 2.4 discusses postal voting adoption (1978-2005) as eliminating the polling-station mechanism. However, if communes merged between 1978 and 2005 (before universal postal adoption), some of the 197 treated communes in the analysis window may have been affected by polling station closures during part of their post-treatment window. The author restricts to 2000-2020 mergers, and most cantons had adopted postal voting by 2005, so this window is partially exposed. Consider an additional check excluding the 2000-2004 cohort.

- The paper notes the BFS reports turnout as "ballots cast / eligible voters." Switzerland has mandatory voter registration but not mandatory voting. It would be useful to note whether the eligible voter denominator accounts for population changes in the merged commune or is fixed at some base-year count, since a merger that attracts new residents (e.g., via fiscal improvements) could mechanically change the denominator even without changing civic participation habits.

- Section 5.6 states the RI permutes "merger dates across treated communes" by drawing from actual treatment years 1990-2020. Why 1990-2020 rather than 2000-2020 (the analysis window)? Drawing placebo dates from 1990-1999 (before the analysis window) for treated communes in the analysis panel seems problematic — such a placebo would place the "post-merger" period largely in the pre-period of the actual analysis. Clarify the permutation procedure.

- The paper does not report the distribution of merger sizes in the treated sample. How many of the 197 treated communes experienced very small mergers (size ratio near 1) versus large absorptions? This is relevant for assessing how much variation the dose-response regression is exploiting and whether outlier mergers drive the result.

---

## VIII. Overall Assessment

This paper makes a genuine contribution. The setting is excellent, the data are comprehensive and administratively precise, and the author's treatment of methodological complexity is unusually honest. The identification of Ashenfelter's dip as a selection mechanism in municipal merger research is a valuable observation that the literature has not emphasized. The stacked DiD approach, properly executed, is appropriate given the violation of TWFE's parallel trends assumption.

However, the paper has several serious gaps that prevent recommendation for publication at a top journal in current form:

1. The dose-response analysis uses TWFE rather than stacked DiD, creating an internal inconsistency with the paper's own methodological argument. This is the most important revision required.

2. The stacked DiD estimate may be contaminated by residual within-window pre-trends, which the author acknowledges but does not quantify. A formal bound or trend-adjustment test is needed.

3. The HonestDiD analysis shows that significance breaks down at M=0.5*Delta — a moderate violation — and this needs to be discussed more prominently in the abstract and conclusion, not only in Section 7.1 and Appendix B.3.

4. Several obvious robustness checks are missing: alternative window widths, canton-by-year fixed effects, and heterogeneity by merger type (absorption vs. fusion).

5. The Callaway-Sant'Anna estimator should be implemented as a complement to the stacked design, given that it is now standard practice in the staggered DiD literature.

The core result — that mergers reduce referendum turnout by approximately 1.67 pp, operating through identity loss rather than free-riding — is plausible, interesting, and broadly consistent with the international literature. With the revisions outlined above, particularly items 1-3, this paper has genuine potential for publication in a strong field journal. Whether it reaches AEJ:Economic Policy or better depends on how convincingly the identification concerns can be addressed.

---

**DECISION: MAJOR REVISION REQUIRED**

The paper requires substantial methodological revisions before it can be accepted. The dose-response analysis must be implemented in the stacked DiD framework for internal consistency (item 1 above). The residual within-window pre-trend contamination must be bounded or corrected (item 2). The HonestDiD fragility at moderate M values must be prominently acknowledged and discussed (item 3). Additional robustness checks should be provided (items 4-5). These revisions are tractable given the existing data and code infrastructure, and do not require new data collection.
