# V1 Empirics Check — openai/gpt-5.4 (Variant A)

**Model:** openai/gpt-5.4
**Variant:** A
**Date:** 2026-03-23T15:25:00.941706

---

## 1. Idea Fidelity

The paper does **not fully pursue the original idea in the manifest**, and that matters for both novelty and identification.

Most importantly, the manifest proposed exploiting **examiner-driven claim narrowing during prosecution**—that is, the change from pre-grant/publication claims to granted claims—as the key scope measure. That design is attractive because it comes closer to isolating examiner-induced changes in scope from applicant demand for scope. By contrast, the paper uses **the number of claims at grant** as its treatment and instruments it with examiner-specific leave-one-out average granted claims. This is a substantially different object. Number of claims at grant is at best an imperfect proxy for legal breadth, and it mechanically conflates examiner behavior with applicant drafting choices and technology complexity. In this sense, the paper shifts from “how much examiners narrow claims” to “how many claims survive,” which is easier to implement but materially weaker conceptually.

The manifest also emphasized a design that would distinguish the **extensive margin of grant** from the **intensive margin of scope conditional on grant**. The paper instead works only in the sample of granted patents, without addressing selection into grant or using the proposed grant-rate instrument as a separate margin. That omission is consequential: if examiner leniency affects whether marginal applications are granted, then conditioning on grant may induce nontrivial selection.

Finally, the manifest pointed to BigQuery-based pre-grant/granted comparison data as central to the contribution. The paper uses PatentsView and granted-patent data only. That choice is understandable for tractability, but it abandons the most distinctive empirical ingredient of the original idea. So while the paper is directionally related to the manifest, it does not implement the key identification insight that would have made the project especially compelling.

## 2. Summary

This paper studies whether broader patents generate more follow-on innovation, using variation in examiner “leniency” within technology-by-year cells as an instrument for the number of claims allowed at grant. The main finding is that patents assigned to examiners who allow more claims receive more forward citations, especially competitor citations, which the paper interprets as evidence that broader patents stimulate rather than block follow-on innovation.

The topic is important and the sample is impressively large. However, in its current form, the empirical design does not yet support the paper’s causal interpretation about patent scope.

## 3. Essential Points

**1. The treatment variable is not a credible measure of patent scope for the question you want to answer.**  
The paper repeatedly equates “more claims” with “broader patents,” but these are not the same. A patent can have many narrow claims or a few broad independent claims. The introduction and policy interpretation are framed around legal scope/breadth, yet the empirical treatment is simply the count of granted claims. This mismatch is central. At minimum, the paper needs to (i) justify why claim count is an economically meaningful scope measure, (ii) distinguish independent from dependent claims, and (iii) ideally move to the manifest’s stronger measure: examiner-induced **claim narrowing from publication to grant** (or at least changes in words per independent claim, claim cancellations, or other prosecution-based indicators). Without this, the paper is best interpreted as studying the effects of claim count, not patent breadth.

**2. The exclusion restriction is presently unconvincing because examiner leniency likely affects citations through channels other than claim count.**  
Examiners may differ not only in allowed claims but also in grant probability, prosecution duration, amendment burden, clarity, prior-art screening intensity, and ultimate patent validity. The paper acknowledges that grant lag responds to the instrument but then dismisses this as non-threatening; I do not think that is adequate. A change in prosecution length alone can affect citation windows, information disclosure, and the timing of technological diffusion. More broadly, “lenient examiner” is a multidimensional treatment. You need much more evidence that examiner assignment shifts citations specifically through scope rather than through patent quality, validity, timing, or selection. Right now, the instrument seems to capture overall examiner style, not a clean scope margin.

**3. Conditioning on granted patents creates a serious selection problem that the paper does not address.**  
The paper’s estimand is ostensibly “the intensive-margin effect of scope conditional on grant,” but examiner leniency may itself affect whether an application gets granted. If so, the sample of granted patents is endogenous to the instrument. This is especially problematic when using examiner-level instruments. The original manifest correctly recognized this issue and proposed separately handling the grant margin. The paper needs to confront this directly—either by incorporating application-level data and modeling grant selection, by showing that the relevant examiner measure is orthogonal to grant propensity within the sample used, or by redesigning around prosecution-stage changes among eventually granted applications where the selection issue is more contained.

If the authors cannot satisfactorily address these three points, I would not view the current causal claims as ready for publication in AER: Insights.

## 4. Suggestions

The paper is promising, and I think there is a path forward, but it likely requires sharpening both the estimand and the design.

First, I strongly encourage the authors to return to the **original prosecution-based idea**. The most convincing treatment would be something like:
- change in number of claims from pre-grant publication to issue,
- change in words per independent claim,
- cancellation of independent claims,
- fraction of original claims surviving,
- or a composite narrowing index built from publication and grant documents.

That would align the measurement with the stated mechanism: examiners force narrowing during prosecution. It would also help distinguish examiner-induced narrowing from applicant initial drafting choices. If this can be done, the paper would become both more novel and more credible.

Second, the paper needs a much deeper discussion of **what exactly is random in examiner assignment**. The current text cites prior literature and effectively assumes quasi-random assignment within class-year cells. But the relevant literature is more careful than that, and random assignment may hold only within finer institutional units, often Art Unit or examiner queue structures, and sometimes only conditionally. You should:
- define the assignment unit precisely,
- show institutional evidence on assignment,
- explain the roles of Art Unit, supervisory patent examiner, and primary examiner,
- and run balance tests on predetermined application characteristics.

The current balance test on grant lag is not a balance test, because grant lag is post-assignment and plausibly endogenous. Better predetermined variables would include application type, assignee type, small-entity status, number of inventors, pre-grant claim count, specification length, technology subclass, continuation/divisional status, and perhaps applicant fixed effects where feasible.

Relatedly, the fixed effects are inconsistently described: tables say “art_unit_year fixed effects,” while the text says “USPC class × filing year.” That inconsistency is not cosmetic; it goes to the heart of the identification strategy. The paper should settle on the assignment-relevant cell and then justify it carefully. If assignment is within Art Unit, then USPC×year may be too coarse; if examiners specialize more narrowly than the FE permit, residual sorting is likely.

Third, the paper should reckon with the fact that the instrument is built from **granted outcomes of other patents**. This creates at least two issues. One is reflection-type concerns and common shocks within examiner-cell groups. The other is that an examiner’s average granted claims may partly reflect the composition of applications she handles rather than examiner behavior. A leave-one-out construction helps mechanically, but it does not solve endogenous grouping. Some ways to strengthen the design:
- residualize claim outcomes on rich application controls before constructing examiner leniency,
- estimate examiner effects in a first step with shrinkage/empirical Bayes and then use those effects as the instrument,
- require examiners to work across multiple firms/applicant types within cells,
- or use examiner-switch or examiner-entry variation if available.

Fourth, if the authors keep claim count as the treatment, the paper should materially improve its **measurement and interpretation**. At a minimum:
- separate independent and dependent claims,
- examine total words in claims, words per independent claim, number of independent claims, and claim hierarchy,
- test whether results are driven by numerous dependent claims, which often add little to practical breadth,
- and avoid repeatedly using “broader” or “scope” unless you can defend that equivalence.

My prior is that the number of **independent claims** would be much more defensible than total claim count. Results on dependent claims would also be informative: if all the action is in dependent claims, the “scope dividend” interpretation weakens substantially.

Fifth, the outcome measure—forward citations within five years of grant—needs more care. Citations are observable and standard, but they are an imperfect proxy for “follow-on innovation,” and their timing depends on grant date, examiner citation practices, and application lags of citing patents. Several improvements would help:
- use citations within fixed windows from **publication** as well as grant,
- separate applicant-added from examiner-added citations if possible,
- examine citation quality or later-stage outcomes such as citations from granted competitor patents only,
- and report results on counts using Poisson/PPML or quasi-Poisson models, not just log(1+x).

Because many patents have zero citations and the count distribution is skewed, the log-plus-one transformation may be fragile. A count model with fixed effects and IV is harder, but even reduced-form Poisson evidence would be useful.

Sixth, I would be much more cautious about the paper’s **mechanism claims**. The crowdedness result is interesting, but it does not cleanly distinguish signaling from blocking, design-around, or simply greater baseline citation intensity in dense fields. Also, the estimates reported in the table do not match the textual claim that the effect is “nearly twice as large”; 0.0072 vs. 0.0067 is not close to that. This should be corrected. More generally, mechanism analysis would be stronger if you could show heterogeneity by:
- technologies with more overlapping prior art,
- firms more likely to monitor patents,
- patents with broad market classes,
- or measures of design-around opportunities.

If feasible, citing-patent text or claim overlap could give sharper evidence on design-around versus simple salience.

Seventh, the sample restriction to **granted patents only** should be brought front and center and, ideally, addressed empirically. If application-level data are available, I would recommend a two-margin design closer to the manifest:
1. examiner grant propensity for the extensive margin of grant;
2. examiner-induced narrowing among granted applications for the intensive margin of scope.

Even if you cannot fully estimate a control-function selection model, you can at least show whether the “scope leniency” instrument is correlated with examiner grant rates and whether the estimated effects differ across cells with high versus low grant propensity.

Eighth, some straightforward presentational changes would improve the paper a lot:
- report actual 2SLS tables rather than only scaled ratios in text;
- include first-stage distributions and examiner-cell variation plots;
- provide examiner-level and cell-level summary statistics;
- show robustness to clustering at Art Unit and two-way clustering if feasible;
- clarify whether citations are measured from filing, publication, or grant and why;
- and harmonize terminology throughout (“Art Group,” “Art Unit,” “USPC,” “technology class”).

Finally, I would urge the authors to **moderate the policy conclusion**. The paper currently concludes that aggressive claim reduction has a “hidden cost” because broader patents promote innovation. That is far too strong given the current treatment measure and identification concerns. Even under the most favorable reading, the evidence would show that examiner-induced increases in claim count are associated with more subsequent citations among granted patents. That is interesting, but it is not yet sufficient to recommend more permissive examination. A narrower, more careful conclusion would make the paper more credible.

In short: the question is important, the scale is impressive, and the examiner-based approach could work. But the current paper would be much stronger if it re-centered on prosecution-induced narrowing, clarified the assignment process, addressed selection into grant, and treated claim count as an imperfect proxy rather than as patent scope itself.
