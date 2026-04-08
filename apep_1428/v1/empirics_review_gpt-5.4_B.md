# V1 Empirics Check — openai/gpt-5.4 (Variant B)

**Model:** openai/gpt-5.4
**Variant:** B
**Date:** 2026-04-08T17:22:10.982143

---

## 1. Idea Fidelity

The paper does **not** fully pursue the original idea in the manifest. The manifest proposed a design centered on **staggered state adoption of horizontal parity relative to vertical parity** across 2015–2021, using this institutional variation to study whether legal candidacy parity translated into financial parity. That design would have exploited differential treatment timing across states and directly linked the mechanism—horizontal parity forcing women into top municipal slots—to party funding behavior.

Instead, the paper pivots to a much weaker design: a **two-period comparison (2018 vs. 2021)** around the 2019 national reform, combined with a **within-candidate income-source DDD** comparing party transfers to sympathizer donations. This is a materially different research design and substantially narrows the contribution. It also leaves out an important part of the original data ambition: the manifest emphasized broader state coverage and staggered timing, whereas the realized sample covers only the states holding elections in 2018 and 2021, with no use of the richer 2015–2021 adoption variation. The core question remains similar, but the identification strategy is notably less compelling than the one originally proposed.

## 2. Summary

This paper asks whether Mexico’s legal gender parity in nominations led parties to equalize campaign resources for female mayoral candidates. Using INE candidate-level finance disclosures for 2018 and 2021, it finds large gender gaps in party transfers and reports that these gaps narrowed somewhat after the 2019 parity reform, but not by more than the change observed in other funding sources.

The topic is important, and the data are potentially valuable. However, in its current form the paper does **not** convincingly identify a causal effect of parity policy on party resource allocation, because the empirical strategy relies on a doubtful counterfactual and uses only a limited slice of the available institutional variation.

## 3. Essential Points

1. **The identification strategy does not support a strong causal claim.**  
   The key assumption is that sympathizer donations provide a valid counterfactual trend for party transfers. That is a strong and insufficiently defended assumption. Party transfers and private donations are different objects with different determinants, and the reform could plausibly affect both through candidate composition, expected competitiveness, municipality assignment, and donor perceptions. More fundamentally, a two-period national before/after design cannot separate the parity reform from contemporaneous shocks, including COVID-era campaign changes and shifting party competition. As written, the design supports a descriptive comparison, not a persuasive causal estimate.

2. **The paper does not adequately handle compositional change in who is nominated and where.**  
   The reform likely changed the set of women running for mayor, the municipalities in which they ran, and the parties fielding them. That is not a nuisance—it is the mechanism through which horizontal parity may operate. Yet the paper lacks municipality-level controls, competitiveness measures, prior vote share, or any way to show whether women were disproportionately placed in weak races. Without addressing selection into candidacies and placements, the interpretation of the funding gap is ambiguous: are women underfunded conditional on comparable races, or are parties funding less competitive races less, regardless of candidate gender?

3. **The data construction and scope need much more validation.**  
   The paper hinges on comparability of finance categories across years, but the 2018 and 2021 transfer variables are not obviously identical in institutional content. The treatment of failed currency parsing as zero is also concerning. In addition, inference with state-clustered standard errors and roughly two dozen clusters is fragile, and the sample excludes many state-years by election calendar. Before any substantive conclusion, the authors need a fuller validation of the harmonization, sample inclusion, missingness, and robustness of inference.

## 4. Suggestions

This is a promising project, but I would strongly encourage the authors to rethink it around the stronger institutional variation that motivated the paper in the first place. The current version has an interesting descriptive message—legal parity did not mechanically generate funding parity—but it falls short of an AER: Insights-style causal contribution. Below are suggestions that would make the paper much stronger.

**First, return to the staggered state adoption design if at all possible.**  
This seems clearly superior to the current national two-period setup. The institutional background itself emphasizes that horizontal parity was adopted at different times across states. That variation is much better aligned with the causal question than comparing 2018 to 2021 nationally. A state-by-year panel using all local election cycles from 2015 onward, with event-study plots and careful handling of staggered adoption, would directly test whether party-controlled transfers to female mayoral candidates changed when horizontal parity became binding. If the authors can recover that design, the paper’s contribution would be much more credible.

**Second, if the authors keep the current DDD design, they should sharply scale back the causal language.**  
At present the paper often writes as though it estimates the effect of the 2019 reform. I do not think the evidence justifies that. A more accurate framing would be: after legal parity expanded, female candidates still received less party funding, and the narrowing in the party-transfer gap was not statistically distinguishable from changes in other income sources. That is still useful, but it is a descriptive or quasi-descriptive result unless the counterfactual is much better defended.

**Third, test directly whether women were placed in systematically weaker races after parity.**  
This is crucial substantively and would help explain the negative “placebo” result for sympathizer donations. The paper already mentions strategic placement, but currently this is speculative. The linked election returns data should allow the authors to measure municipality-level party strength, prior vote share, incumbency, competitiveness, urbanization, or whether the municipality was historically winnable for the party. Then ask:
- Were post-reform female nominees more likely to be assigned to weak municipalities within party-state cells?
- Conditional on party strength and municipality competitiveness, does the funding gap remain?
- Did the gap narrow more in competitive municipalities than in unwinnable ones?

This would greatly improve both interpretation and policy relevance.

**Fourth, move closer to a candidate-race level design rather than relying mainly on source-type comparisons.**  
The source-type DDD is clever, but it is doing too much work. The paper would be more convincing if it estimated gender gaps in party transfers conditional on rich race-level covariates: municipality fixed effects where feasible, party-by-state-by-year controls, previous party performance, coalition status, incumbency, and office-specific spending caps. If data permit, matching or reweighting women and men within party-state-election cells by observed race quality could be very informative.

**Fifth, validate the finance variables much more carefully.**  
The harmonization between 2018 and 2021 needs a fuller institutional appendix. Are “transferencias de recursos federales/locales” in 2018 truly comparable to 2021 “transferencias de concentradoras”? Do these categories include the same flows, or did reporting rules change? If some of the increase from 2018 to 2021 reflects reporting differences, the main finding is difficult to interpret. Likewise, treating parse failures as zero is potentially dangerous; I would strongly recommend reporting how many such cases there are by year and source, manually auditing them, and showing that excluding them does not matter.

**Sixth, improve the treatment of zeros and skewness.**  
Given the very high incidence of zero transfers, a single log-plus-one model is not enough. Consider a two-part analysis:
1. probability of receiving any party transfer;  
2. amount conditional on positive transfer.  
This would be substantively appealing. Parties may discriminate either by excluding women from transfers entirely or by giving them smaller positive amounts. A hurdle model or extensive/intensive-margin decomposition would help distinguish these mechanisms.

**Seventh, revisit inference.**  
With clustering at the state level and a limited number of clusters, conventional cluster-robust standard errors may be unreliable. Reporting wild-cluster bootstrap p-values would be better. The statement that HC1 errors are “similar” is not very informative because HC1 addresses a different problem. For a paper hinging on a null effect, inference choices matter a lot.

**Eighth, use the linked electoral returns to connect the finance gap to outcomes.**  
Even a compact result showing whether women convert party transfers into votes at similar rates would enrich the contribution. If women are equally productive per peso, underfunding is particularly consequential. If not, that also informs the interpretation. I do not think the paper needs a full campaign-finance production function, but some connection between transfers and electoral performance would help motivate why the “funding gate” matters.

**Ninth, clarify the policy environment around women-targeted public funds.**  
The paper notes that parties were required to direct a minimum share of public campaign funds to women, but it is not fully clear how this interacts with the measured transfer category. If some party transfers are pass-throughs of regulated public funds, then “party-controlled” is less clean than suggested. The paper should carefully distinguish: what exactly was legally constrained, what remained discretionary, and how that maps into the observed categories.

**Tenth, tighten the interpretation of the null.**  
The paper currently calls this a “well-executed null result,” but I do not think it is yet well-executed enough for that claim. A null can be very informative, but only when the identifying variation is strong and the confidence interval is substantively meaningful. Here the confidence interval is wide, and the design is vulnerable. The paper should present the implied confidence interval in economically interpretable units and be candid that the evidence is consistent with both modest improvement and no improvement.

**Eleventh, improve the state heterogeneity analysis.**  
The current state table is descriptive but hard to interpret because many entries are noisy and some states appear in only one year. If retained, the paper should either:
- formalize heterogeneity using observable state characteristics, or
- present shrinkage/precision-adjusted estimates, not raw changes in means.  
Otherwise, the heterogeneity section risks over-interpreting noise.

**Twelfth, simplify and sharpen the contribution.**  
The strongest version of this paper is probably not “the first economics paper to use these data,” but rather: “Candidate-level finance data reveal that nomination parity did not automatically eliminate party funding disparities.” That is a useful insight. To make it land, the paper should spend less space on broad claims and more on measurement credibility, institutional detail, and what exactly can be learned from the observed patterns.

Overall, I think the project has real potential because the question is important and the data are promising. But the current paper is better seen as a **strong descriptive first pass** than as a convincing causal estimate of the effect of parity policy. The most important next step is to exploit the richer state-by-year policy variation the project originally envisioned; absent that, the claims should be narrowed considerably.
