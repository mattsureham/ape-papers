# V1 Empirics Check — openai/gpt-5.4 (Variant C)

**Model:** openai/gpt-5.4
**Variant:** C
**Date:** 2026-03-14T16:45:49.894169

---

## 1. **Idea Fidelity**

The paper clearly pursues the core question in the manifest: whether the IR35 off-payroll reforms reduced the number of PSC-like companies, using NOMIS Business Counts and a sector-by-time DiD design. It also uses the 2020 delay as a placebo, which was a key idea in the manifest.

That said, the paper departs from the original identification strategy in important ways. First, the manifest emphasized the *staggered nature* of the reforms: a public-sector reform in 2017 and a private-sector reform in 2021, with exposure depending on whether sectors supplied public clients versus private clients. In the paper, treatment is instead collapsed to a simple binary “high-PSC sector” indicator, and both reforms are estimated off the same treated sectors relative to the same controls. That is a much weaker design than the manifest envisioned, because the 2017 reform should have heterogeneous exposure across sectors and places depending on public procurement reliance. Second, the paper does not use the small-firm exemption in the 2021 reform, even though that is one of the most attractive margins for identification. Third, the manifest highlighted legal status and possibly employment-size structure; the paper uses legal status but does not exploit size bands, which could have helped distinguish exempt small-client activity from non-exempt large-client activity.

So: the paper is faithful to the broad idea, but it leaves substantial identification power on the table and does not fully implement the strongest features of the original design.

## 2. **Summary**

This paper argues that the UK’s 2021 private-sector IR35 reform caused a large decline in registered companies in contractor-intensive sectors, especially IT and consulting. Using NOMIS counts by local authority, sector, and legal status, the author estimates a roughly 19 percent decline in companies in treated sectors after 2021 relative to control sectors, with little evidence of offsetting growth in sole proprietorships.

The question is important and the headline result is potentially economically meaningful. But in its current form, the paper does not yet convincingly establish a causal effect of the reform, mainly because the identifying variation is too coarse and the inference is not reliable given the treatment structure.

## 3. **Essential Points**

1. **Identification is too weak for the strength of the claims.**  
   The paper’s preferred specification includes sector FE and LA×year FE, so identification comes entirely from differences across only eight sectors in post-2021 relative changes. That is essentially a sector-level DiD with four treated and four control sectors, replicated across local authorities. The local-authority dimension does not generate independent treatment variation because treatment is assigned at the sector-year level. This makes the design highly vulnerable to sector-specific shocks unrelated to IR35, including post-pandemic reorganization, digitization reversals, changes in remote work demand, and sector-specific incorporation trends. The paper needs either a more credible exposure measure—e.g. pre-reform PSC intensity, public-sector dependence for 2017, or client-size exposure for 2021—or the claims need to be scaled back substantially.

2. **The standard errors and inference are not appropriate as presented.**  
   With treatment varying at the sector-time level and only eight sectors total, sector-clustered inference is the relevant baseline, but it is also extremely fragile with only eight clusters. LA-clustered standard errors are not informative here and substantially overstate precision because they treat repeated copies of the same sector-time treatment shock across LAs as independent variation. Two-way clustering does not solve the fundamental few-treated-groups problem. At minimum, the paper should use randomization inference / permutation tests over sector assignments, wild cluster bootstrap with clear caveats, and report the number of treated and control clusters prominently. Right now the “highly significant” alternative clustering results should not be used to reassure the reader.

3. **The economic interpretation overreaches the evidence.**  
   A 19 percent reduction in registered companies in treated sectors is large but not obviously implausible given the raw series. However, the paper repeatedly translates this into “killed 43,000 companies,” “mass dissolution,” and “caused over 43,000 companies to dissolve,” which the design does not establish. The estimates are relative differences in enterprise counts by sector, not direct evidence of dissolution of PSCs, and the paper cannot separately identify closure, reclassification, migration across SICs, mergers into umbrella companies, or changes in registration behavior. The magnitudes may be directionally plausible, but the wording needs to become much more disciplined.

## 4. **Suggestions**

The paper has a real opportunity if it becomes more modest and more design-driven. My main suggestions are below.

**First, strengthen treatment measurement.**  
A binary treated/control split at the 2-digit SIC level is too crude. The obvious improvement is to build a continuous exposure measure using pre-reform shares of companies in sectors/legal forms most likely to be PSCs. Even within SIC 62 or 70, local authorities differ greatly in contractor intensity. A Bartik-style or shift-share exposure based on pre-2017 or pre-2019 PSC prevalence would be much more convincing than assigning all treated sectors the same exposure. If the NOMIS data cannot identify PSCs directly, consider using Companies House naming patterns, director counts, micro-size bands, or external contractor survey data to proxy for PSC intensity.

**Second, exploit the reform’s institutional margins more directly.**  
The paper discusses but does not use the most attractive quasi-experimental features:
- the **2017 public-sector reform**, which should disproportionately affect places/sectors more exposed to public procurement;
- the **2021 private-sector reform**, which exempted **small clients**;
- the **2020 delay**, which can be used more sharply in an event-study or stacked design.  
For example, if size-band data are available, one could examine whether declines are concentrated in cells more likely to serve medium/large clients rather than very small firms. Even a difference-in-difference-in-differences design using sector exposure × post × client-size composition would materially improve the paper.

**Third, reconsider the control group.**  
Retail, food service, and wholesale are poor controls for IT consulting and management consulting. Their post-2020 dynamics were shaped by very different forces. Legal/accounting is probably closer economically, but as the paper notes, it may itself have IR35 exposure. I would encourage a more systematic control selection strategy: show pre-2016 to 2019 trends if available, report sector comparability, and perhaps use synthetic control weights at the sector level rather than an ad hoc set of four controls. At a minimum, present results leaving out each control sector one at a time and show that the estimate is not driven by food service or retail’s unusual pandemic recovery path.

**Fourth, improve the event study and pre-trend discussion.**  
The event study is helpful, but with only a handful of sector clusters, “insignificant pre-trends” are weak evidence. More importantly, 2019 is used as the reference year, which may be sensible for the 2021 reform, but then the 2017 reform becomes awkwardly folded into the same specification. I would separate the two reforms rather than estimate a single model with treated×post-2017 and treated×post-2021 on the same treatment group. The current setup risks making the 2017 coefficient hard to interpret and the 2021 event study absorb a mix of prior dynamics.

**Fifth, be more careful with level translations.**  
The paper moves between “43,000 vanished” in raw IT counts, a DiD estimate of 19.3 log points across four sectors, and a level estimate implying 29,000 dissolved companies nationally. These are not interchangeable. AER: Insights readers will immediately notice the slippage. I would recommend:
- keep the regression estimates in percentage/log terms;
- clearly distinguish raw aggregate changes from causal estimates;
- avoid multiplying an average cell-level effect by the number of LAs unless you show that the levels specification is well behaved and that this aggregation maps cleanly to national totals.

**Sixth, tighten the discussion of legal-status substitution.**  
The decomposition is interesting, but the current interpretation is too speculative. A non-result for sole proprietorships does not establish transitions into payroll employment or umbrella companies. It is fine to propose those as plausible channels, but they should be labeled as hypotheses. If possible, add direct evidence: e.g. did SIC 78 grow more in LAs with higher pre-IR35 IT exposure? Did company declines concentrate among the smallest employment-size bands, where PSCs are most likely? That would materially strengthen the umbrella-company channel.

**Seventh, use more appropriate inference tools and present them transparently.**  
Given the tiny number of sector clusters, I would like to see:
- wild cluster bootstrap p-values at the sector level;
- permutation/randomization inference over sector treatment assignments;
- perhaps an aggregate sector-year analysis with sector weights, making clear that the effective sample is very small.  
If the result survives those exercises, the paper becomes much more credible. If not, the authors should present the estimate as suggestive rather than definitive.

**Eighth, clarify what NOMIS/IDBR counts actually measure.**  
The paper uses language like “dissolved” and “vanished,” but business-register counts reflect stocks, not necessarily true dissolutions. Some firms become dormant, change SIC, move legal form, or drop from coverage thresholds. A short data discussion on what entry/exit from the register means would help. Relatedly, I would want reassurance that the outcome is not contaminated by changes in classification, especially around hybrid consultancy/agency/umbrella structures.

**Ninth, scale back the title and headline framing.**  
“The Dissolution Tax” and “killed 43,000 companies” are much stronger than the evidence supports. The paper’s central contribution is already interesting without rhetorical overstatement: shifting compliance responsibility appears associated with a sizable decline in company registrations in contractor-intensive sectors. That is a credible, policy-relevant claim if carefully presented.

**Finally, sharpen the paper’s contribution.**  
The most convincing and economically meaningful result here is not that “no tax rate changed,” because expected tax liabilities and enforcement exposure effectively did change. Rather, it is that *administrative incidence and compliance-risk assignment* appear to alter organizational form. That is a good idea. To land it, the paper should be more precise about what changed economically, more careful about causal language, and much stronger on identification.

In sum, there is a publishable paper somewhere in this project, but not yet in this draft. The raw patterns are striking and the magnitude is plausible. The present design, however, is too close to a four-treated-versus-four-control sector comparison with fragile inference to support the very strong causal and quantitative claims.
