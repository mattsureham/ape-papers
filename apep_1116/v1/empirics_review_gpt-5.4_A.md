# V1 Empirics Check — openai/gpt-5.4 (Variant A)

**Model:** openai/gpt-5.4
**Variant:** A
**Date:** 2026-03-29T21:00:20.485729

---

## 1. Idea Fidelity

The paper clearly pursues the core idea in the manifest: using continuation/divisional applications as within-family “twins” to study whether examiner reassignment within the same art unit generates inconsistent patent outcomes. It uses the intended PatEx/BigQuery data, focuses on same-art-unit parent-child pairs, and emphasizes examiner heterogeneity and small-entity disparities. In that sense, the paper is faithful to the broad research question.

That said, the implementation departs from the manifest in several important ways. First, the manifest’s central causal design was a within-family, within-art-unit comparison exploiting quasi-random reassignment and then relating child outcomes to examiner leniency among reassigned pairs. The paper does this only partially. It does **not** fully “hold invention quality fixed” in the econometric sense; instead of a family fixed-effect or a richer within-family design, it uses the parent outcome as a control. That is much weaker than the twin-study framing suggests. Second, the manifest described 135,624 same-AU reassigned pairs and a 36.0% discordance rate with 4.2 pp excess discordance relative to same-examiner pairs; the paper reports 97,922 reassigned pairs, 29.8% discordance, and 7.7 pp excess discordance (11.0 pp raw). Such differences may reflect additional sample restrictions, but the paper never reconciles them. Third, the manifest hinted at an IV-style use of examiner leniency; the paper instead estimates reduced-form OLS of grant on examiner leniency and then reports a “first-stage F-statistic,” which is conceptually inappropriate absent a clearly defined 2SLS design.

So the paper captures the spirit of the original idea, but it does not yet fully deliver the identification strategy promised by the manifest, and the discrepancies in numbers need to be explained.

## 2. Summary

This paper studies whether patent examination is inconsistent by comparing continuation/divisional applications to their parent applications when the child is reassigned to a different examiner within the same art unit. It finds that reassignment is associated with substantially higher parent-child outcome discordance and that examiner leniency strongly predicts the child’s grant probability, with somewhat larger effects for small entities.

The topic is important, the data are well suited to the question, and the continuation-family design is potentially novel and valuable. The main issue is whether the empirical strategy credibly isolates examiner-driven inconsistency from endogenous differences in claims, selection into continuation filing, and non-random reassignment within art units.

## 3. Essential Points

**1. The current identification strategy does not convincingly hold invention quality fixed.**  
The paper’s rhetoric repeatedly says that continuation-family comparisons “hold invention quality fixed,” but parent and child applications are not the same case. Continuations often differ in claims, timing, prosecution strategy, attorney quality, and applicant response to information learned during prosecution of the parent. Divisionals may be especially different, since they can reflect examiner-imposed restriction requirements. Controlling for parent grant status is not enough to purge these differences. The key question is not whether applications are in the same family, but whether reassignment is orthogonal to the *incremental differences* between parent and child within a family. The paper needs a much sharper discussion of what is and is not identified, and ideally designs that come closer to a true within-family comparison: e.g., restricting to narrow claim-overlap pairs if available, sibling continuations filed close in time, or family fixed-effect specifications using multiple children within a family.

**2. The claim that reassignment is “as-good-as-random” within art-unit × year is not yet credible enough.**  
The balance tests are too thin. Showing small correlations with small-entity status and parent grant status is not sufficient, especially because assignment may depend on unobservables like claim scope, sub-specialization within art unit, backlog, examiner-specific expertise, or complexity. Moreover, the institutional discussion itself mentions “specialty matching,” which cuts directly against random assignment. The paper should provide much more evidence on assignment: balance on observable patent characteristics (number of claims, independent claims, citations, attorney/agent indicators, continuation vs divisional, time since parent, family size, parent office actions, technology subclass if available), event-time evidence around examiner exits/transfers, and perhaps examiner workload measures. Without this, the causal interpretation of both the discordance and leniency results remains too strong.

**3. The leniency specification is misinterpreted and, as written, does not match the causal claims.**  
Equation (2) is an OLS regression of child grant on examiner leave-one-out grant rate. That is a useful descriptive measure of examiner heterogeneity, but it is not an IV design, and the reported “first-stage F-statistic” is not meaningful in this context. More substantively, examiner leniency is itself an outcome of examiner case mix and behavior; even within reassigned pairs, OLS of grant on leniency does not automatically identify a causal derivative unless assignment is random conditional on controls. The paper should either (i) present this as reduced-form evidence on examiner heterogeneity and stop short of stronger causal language, or (ii) redesign the estimation to better align with a random-assignment framework, for example using examiner fixed effects or examiner-by-year leave-out measures within art unit-year cells and very explicit identifying assumptions.

## 4. Suggestions

This is a promising paper. The empirical setting is interesting, the question is important, and the continuation-family angle could make a useful contribution. My suggestions below are meant to help the paper match its ambition.

First, I would strongly encourage the authors to **sharpen the estimand and tone down several claims**. The paper currently alternates between “same invention” and “same invention family.” Those are not equivalent. A continuation may reflect strategically amended claims after seeing the parent prosecution history; a divisional may isolate a different invention disclosed in the same specification. The paper will be much more credible if it states clearly: “We compare related applications within the same family, not literally identical cases.” Then frame the main result as evidence that examiner identity contributes meaningfully to within-family variation in outcomes, rather than as a pure test of whether identical inventions receive different verdicts.

Second, the paper would benefit from **more institutional detail on continuation assignment**. The current assignment discussion is too generic. For this design, the crucial institutional questions are: Who decides whether the child stays with the parent examiner? Under what circumstances are continuations retained vs reassigned? Are divisionals more likely to be assigned by sub-specialty than continuations? Does the USPTO have formal rules, or is it art-unit-specific practice? If there are MPEP provisions or administrative manuals governing transfer or retention, they should be quoted. If not, that absence itself should be documented. A short but precise institutional section would materially improve the reader’s ability to assess identification.

Third, I would recommend **richer balance and selection tests**. At minimum, regress reassignment and examiner leniency on a broad set of observables within art-unit × year: continuation vs divisional, lag from parent filing, lag from parent disposition, number of claims, independent claims, number/type of office actions on the parent, parent examiner tenure, family size, applicant type, assignee status, attorney representation, and technology subclass indicators if available. Show standardized differences, not just t-stats. If possible, compare reassigned and non-reassigned children within the same family-size strata or same-parent-outcome strata. A table and an appendix figure would help.

Fourth, I think the paper should **exploit family structure more fully**. One attractive extension would be to move from parent-child pairs to the family level and compare multiple children from the same parent or same extended family. If some families generate multiple continuations examined by different examiners, one can include family fixed effects and estimate whether higher-leniency examiners are more likely to grant within the same family. That would be much closer to the “twin study” language and would reduce concern that parent outcome is too crude a control for family quality.

Fifth, the paper should do more to address the possibility that **discordance is not necessarily inconsistency**. Parent-child differences can arise because claims differ for legitimate reasons. One way to get at this is to examine intermediate outcomes: final rejection types, allowance after appeal/RCE, number of office actions, prosecution length, and claim amendments if available. If examiner reassignment mainly changes timing or rejection path but not ultimate grant for certain subsets, that would nuance the “lottery” interpretation. Conversely, if reassignment changes outcomes even among very similar procedural subsets, the case becomes stronger.

Sixth, I would encourage the authors to **separate continuations from divisionals much more prominently**. These are not just robustness subsamples; they are conceptually different objects. Divisionals may be generated by restriction requirements and thus are more likely to involve distinct claim sets or examiner specialization. Continuations may be the cleaner setting for a consistency test. I would consider making continuations the main analysis and treating divisionals as a secondary extension.

Seventh, there is room to improve the **main regression design for discordance**. A regression of discordance on reassignment is useful, but it is fairly reduced-form and potentially conflates examiner effects with any systematic differences between cases that get reassigned and those that do not. Consider:
- adding richer controls for parent prosecution characteristics,
- estimating separately by parent grant/abandon status,
- controlling for time elapsed between parent and child,
- and, if feasible, including parent examiner fixed effects or art-unit × parent-examiner-year controls.  
These would help absorb systematic tendencies of some examiners to retain or shed cases.

Eighth, for the leniency analysis, I suggest **redefining leniency more locally**. A full-career leave-one-out grant rate may mix persistent leniency with changing examiner composition and technology drift. More credible alternatives would be a leave-out rate measured within art unit × year, or within a rolling window, or standardized within examiner cohort and art unit-year. The paper does one standardized robustness check, but this should be moved closer to the main specification.

Ninth, the authors should **fix the econometric presentation around the leniency results**. If the analysis is OLS, call it OLS. Do not report a first-stage F-statistic unless there is an actual 2SLS setup with a clearly defined endogenous regressor and instrument. More generally, be careful with language like “causally determines patent rights.” The reassignment specification may support a causal interpretation under strong assumptions; the leniency specification is better viewed as evidence that examiner-specific tendencies strongly shape outcomes, conditional on observables and the sample design.

Tenth, it would help to provide **a transparent reconciliation of sample counts and headline statistics**, especially relative to the exploratory results from which the paper appears to have been developed. Why did same-AU reassigned pairs fall from 135,624 to 97,922? Is the difference due to requiring resolved outcomes, restricting years, deduplication, or excluding some continuation chains? Likewise, why are discordance rates substantially lower than in the original exploration? Readers will trust the analysis more if they can see exactly how the sample evolved.

Eleventh, the heterogeneity analysis on small entities is interesting, but it needs **a more disciplined interpretation**. A larger reassignment effect for small entities could reflect fewer resources, as the paper suggests, but it could also reflect differences in claim scope, attorney quality, or case complexity. I would recommend showing whether the small-entity differential survives richer controls and whether it is concentrated in continuations vs divisionals, specific technology centers, or cases without representation. If attorney/agent information is available, that would be particularly valuable.

Twelfth, I think the paper should make better use of the **office action data**. The manifest emphasized rejection types and process measures; the current draft barely uses them. This is a missed opportunity. Process outcomes could distinguish between substantive inconsistency and normal claim evolution. For example:
- Does reassignment increase §102 or §103 rejection incidence?
- Does it lengthen prosecution?
- Does it increase the probability of abandonment after final rejection?
- Does it alter appeal behavior or the use of RCEs?  
These would enrich the paper and make the mechanism more persuasive.

Finally, the discussion section should be **more restrained about downstream welfare magnitudes**. Extrapolating from Farre-Mensa et al. to “billions in startup investment” or large employment consequences is premature here, because this paper does not estimate downstream impacts and the mapping from within-family discordance to marginal patent grants is not straightforward. I would keep the policy discussion focused on consistency and administrative quality rather than large aggregate welfare claims.

In sum, I see a paper with real potential, but the current version overstates what the design can identify. If the authors can tighten the identification, exploit the family structure more fully, provide more compelling assignment evidence, and align the empirical claims with the actual regressions, this could become a strong and interesting short paper. As written, however, the causal interpretation is not yet sufficiently convincing for a top-field-journal standard.
