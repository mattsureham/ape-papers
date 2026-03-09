# Research Idea Ranking

**Generated:** 2026-03-09T09:48:26.149917
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Stranded by the Label? Energy Performanc... | PURSUE (72) | PURSUE (88) | PURSUE (74) |
| Who Captures a Tax Cut? Property Price C... | PURSUE (64) | CONSIDER (58) | CONSIDER (67) |
| Does Mandatory Social Housing Change Nei... | SKIP (52) | SKIP (42) | SKIP (51) |

---

## GPT-5.4 (A)

**Tokens:** 9928

### Rankings

**#1: Stranded by the Label? Energy Performance Bans and Property Values in France**
- **Score:** 72/100
- **Strengths:** This asks a live, first-order policy question at the intersection of housing and climate policy, with hard outcomes and potentially sharp institutional thresholds. If executed well, it could say something broader than “green homes sell for more”: namely, whether regulation against low-efficiency rentals materially reprices housing assets.
- **Concerns:** The 2021 reform bundled several changes at once—new calculation rules, legal enforceability, and future rental bans—so the information-vs-regulation decomposition is less clean than the pitch suggests. The DVF–DPE link and any post-reform gaming of grades near thresholds are serious practical risks.
- **Novelty Assessment:** **Moderately novel.** Energy labels and housing prices are already a crowded literature, and threshold designs are not new. But the French setting with progressive rental bans is still meaningfully less studied than the generic EPC premium question.
- **Top-Journal Potential:** **Medium.** A top field journal is very plausible. A top-5 would require a very crisp design showing that **regulatory bite**, not just improved information or relabeling, drives the effect.
- **Identification Concerns:** A simple pre/post comparison is not enough because the reform changed the measurement technology itself. The strongest version would be a difference-in-discontinuities or similar design around grade cutoffs, with density/manipulation tests and clear evidence on rental-market exposure.
- **Recommendation:** **PURSUE** *(conditional on: high-quality DVF–DPE linkage; strong anti-manipulation evidence near DPE thresholds; a design that isolates regulatory effects from the 2021 methodology change)*

---

**#2: Who Captures a Tax Cut? Property Price Capitalization of France's Taxe d'Habitation Abolition**
- **Score:** 64/100
- **Strengths:** Very large fiscal shock, highly policy relevant, and paired with excellent transaction-level data. The incidence angle—whether an occupant-side tax cut is capitalized into owner-side prices—is economically interesting and more distinctive than a standard property-tax paper.
- **Concerns:** The proposal leans heavily on comparing primary and secondary residences, but I am not convinced DVF cleanly identifies residence status at the transaction level. If that comparison is unavailable, the design collapses into a cross-commune dose-response DiD where pre-reform tax rates are correlated with many local characteristics and trends.
- **Novelty Assessment:** **Moderately novel in setting, not in question.** The exact French reform is unusual and likely not saturated in the literature, but property-tax capitalization is a classic, well-studied topic.
- **Top-Journal Potential:** **Medium.** There is clear field-journal potential, especially if the paper can convincingly answer “who captures the tax cut?” But absent a sharp within-commune comparison or a stronger mechanism, it risks reading as a competent but familiar capitalization study.
- **Identification Concerns:** Pre-reform TH rates are not plausibly random, and four pre-years is not a lot for validating continuous-treatment parallel trends. Treatment intensity is also imperfectly measured because the tax depended on cadastral values and household eligibility, not just commune tax rates.
- **Recommendation:** **CONSIDER** *(best pursued only if you can credibly observe property tax-status/use and implement the primary-vs-secondary triple-difference as advertised)*

---

**#3: Does Mandatory Social Housing Change Neighborhoods? Evidence from France's Loi SRU**
- **Score:** 52/100
- **Strengths:** The policy question is important and politically salient, and the underlying debate is real: whether mandated social housing harms private property values or improves neighborhood quality. In principle, threshold-based assignment could have made this attractive.
- **Concerns:** As proposed, the design is weaker than it appears. SRU coverage depends on more than crossing a population cutoff, compliance is gradual and incomplete, and the main reform dates long predate the available transaction data, so the mapping from “threshold exposure” to actual treatment is loose.
- **Novelty Assessment:** **Modestly novel.** The France-specific institutional setting is interesting, but social-housing mandates/inclusionary-zoning effects on neighborhood outcomes and prices are already a reasonably populated area.
- **Top-Journal Potential:** **Low.** Right now this looks like a local policy evaluation with a fuzzy treatment, long lags, and no especially sharp mechanism. That is usually not enough for a top-5 and may struggle even at a top field journal unless the design is substantially tightened.
- **Identification Concerns:** The RDD is likely fuzzy because legal applicability also depends on agglomeration status and exemptions, not just population. Near-threshold communes may have thin transaction volume, and with DVF starting in 2014, you lack a convincing pre-period around the key policy changes.
- **Recommendation:** **SKIP**

---

### Summary

This is a solid batch, but only **Idea 2** currently looks close to being worth serious development. **Idea 1** is interesting and policy relevant, but it hinges on a key data feature I do not think is securely available in the proposed setup. **Idea 3** is the weakest because the treatment assignment and timing do not line up cleanly with the available data.

---

## Gemini 3.1 Pro

**Tokens:** 8274

Here is my evaluation of the research proposals, ranked from most to least promising. 

### Rankings

**#1: Stranded by the Label? Energy Performance Bans and Property Values in France**
- **Score**: 88/100
- **Strengths**: Directly tackles a first-order policy question (climate transition risk and stranded assets) while elegantly separating the information effect from the regulatory effect. The combination of an RDD at the energy-consumption threshold and a DiD around the announcement date provides a highly credible, multi-pronged identification strategy.
- **Concerns**: Address matching between the DVF and DPE databases is notoriously noisy and could attenuate the results. Additionally, the owner-occupied placebo is imperfect, as owner-occupiers may still discount G-rated properties if they anticipate selling to a buy-to-let investor in the future.
- **Novelty Assessment**: High. While the UK EPC literature is saturated, almost all existing papers suffer from the inability to disentangle the informational value of the label from the regulatory bite of minimum energy standards. France's timeline perfectly isolates the regulatory channel.
- **Top-Journal Potential**: High. This perfectly matches the appendix's winning formula of "first-order stakes + one sharp channel." By explicitly decomposing information vs. regulation, it frames itself as "resolving an active confusion in the literature," which is a strong predictor of top-tier editorial success. 
- **Identification Concerns**: The primary threat is manipulation of the running variable. Because the stakes of a G vs. F rating became massive after 2021, energy assessors likely faced immense pressure to manipulate the kWh/m2/year estimates to push properties just over the threshold into the F category. 
- **Recommendation**: PURSUE

**#2: Who Captures a Tax Cut? Property Price Capitalization of France's Taxe d'Habitation Abolition**
- **Score**: 58/100
- **Strengths**: Leverages a massive-scale natural experiment with excellent administrative data and a highly credible built-in placebo (secondary residences). The continuous dose-response design exploiting pre-reform rate variation is intuitively appealing.
- **Concerns**: Tax capitalization is a very mature, saturated literature, making it incredibly hard to clear the novelty bar for top general-interest journals. Furthermore, because this is such an obvious and large French reform, it is highly likely that multiple local research teams are already circulating working papers on this exact topic.
- **Novelty Assessment**: Low. While the specific policy is a large shock, the core economic question (do local tax cuts capitalize into housing prices?) has been studied exhaustively for decades. 
- **Top-Journal Potential**: Low. As the appendix notes, "technically competent but not exciting" papers usually lose. Estimating "another average treatment effect" for tax capitalization, without revealing a counter-intuitive mechanism or challenging conventional wisdom, will struggle to excite a top-5 or top field journal.
- **Identification Concerns**: High-TH and low-TH communes likely have fundamentally different local economies, demographics, and housing market trajectories. This threatens the parallel trends assumption, even when using modern staggered DiD estimators.
- **Recommendation**: CONSIDER (conditional on: pivoting the outcome to a genuinely novel mechanism beyond standard price capitalization; verifying you have not already been scooped by existing French working papers).

**#3: Does Mandatory Social Housing Change Neighborhoods? Evidence from France's Loi SRU**
- **Score**: 42/100
- **Strengths**: Addresses a highly relevant policy debate (NIMBYism and the effects of forced social mixing) using a seemingly clean population threshold and excellent transaction-level data.
- **Concerns**: The 3,500 population threshold in France triggers multiple other institutional rules, severely confounding the RDD. Furthermore, the Loi SRU has already been extensively studied by urban economists.
- **Novelty Assessment**: Low. The Loi SRU and its 3,500 threshold have been heavily mined by French researchers for over a decade to study segregation, construction, and voting patterns. 
- **Top-Journal Potential**: Low. The identification is fatally flawed due to compound treatments at the threshold. Furthermore, it lacks a surprising mechanism, reading more like a standard subgroup slice of the neighborhood-effects literature rather than a paper that changes how we think about urban economics.
- **Identification Concerns**: Fatal exclusion restriction violation. In France, the 3,500 population threshold historically determined major municipal regulations, most notably a shift in the electoral system from majority voting to proportional representation. Any discontinuity at this threshold cannot be cleanly attributed to social housing mandates alone.
- **Recommendation**: SKIP

### Summary

This batch presents three empirically feasible projects using excellent French administrative data, but they vary wildly in their conceptual novelty and identification validity. Idea 2 is a standout proposal that elegantly solves a major identification problem in the climate economics literature (information vs. regulation) and should be pursued immediately. Ideas 1 and 3 suffer from being overly familiar or having fatal identification flaws, respectively, and should be deprioritized to avoid producing papers that are merely "competent but not exciting."

---

## GPT-5.4 (B)

**Tokens:** 9860

### Rankings

**#1: Stranded by the Label? Energy Performance Bans and Property Values in France**
- **Score: 74/100**
- **Strengths:** This has the best combination of novelty and journal upside. The key contribution is not “another green premium paper,” but potentially a clean separation of **information** from **regulation** in housing markets, which is exactly the kind of confusion top journals like papers to resolve.
- **Concerns:** The design is more fragile than it looks. The 2021 reform changed both legal consequences and the DPE methodology, so pre/post comparisons can mix regulation effects with remeasurement/reclassification; and the proposed owner-occupier placebo is only useful if tenure status is actually observed.
- **Novelty Assessment:** The broader EPC/DPE literature is already substantial, and there is a lot on energy labels and housing prices. But the **French shift from largely informational labels to legally consequential rental bans** is much less mined and could support a genuinely new paper if framed correctly.
- **Top-Journal Potential: High.** If the paper can convincingly show that discounts near the bad-rating thresholds reflect **regulatory bite rather than generic preferences for efficiency**, this is the kind of sharp A→B→C story that could land in AEJ:EP and potentially travel higher. Without that separation, it becomes a narrower “bad energy ratings lower prices” paper, which is much less exciting.
- **Identification Concerns:** The main threat is that the reform changed the assignment technology itself, so “near-threshold before vs after” is not obviously apples-to-apples. The RDD also needs a credible forcing variable, manipulation tests, and a clear strategy for the fact that grades may be determined by multiple criteria rather than one simple scalar cutoff.
- **Recommendation:** **PURSUE (conditional on: validating high-quality DPE–DVF matching; showing boundary density/manipulation tests; finding a credible rental-exposure heterogeneity or placebo that is actually observable in the data)**

---

**#2: Who Captures a Tax Cut? Property Price Capitalization of France's Taxe d'Habitation Abolition**
- **Score: 67/100**
- **Strengths:** Big policy, universe-scale transactions, and an economically legible outcome. The incidence question is genuinely interesting because the tax was paid by occupants, so the paper could speak to whether housing markets transfer benefits from residents to owners.
- **Concerns:** The core question is classic, not new; tax capitalization is one of the most studied topics in urban/public economics. More importantly, the proposal overstates how clean the design is: pre-reform TH rates are endogenous to local fiscal/political conditions, actual tax savings depend on household income and cadastral values, and I am not convinced DVF alone cleanly identifies primary vs secondary residence.
- **Novelty Assessment:** The **specific French reform** is novel and important. But the underlying question—whether local tax cuts capitalize into house prices—has a very large existing literature, so novelty is moderate rather than high.
- **Top-Journal Potential: Medium.** This could be a strong AEJ:EP or top field paper if it becomes a paper about **who captures tax relief** rather than just another capitalization estimate. For top-5, it likely needs a sharper mechanism and cleaner within-market identification than a national dose-response DiD on tax rates.
- **Identification Concerns:** The nationwide reform leaves you relying on variation in treatment intensity, and high-TH communes may already have different price trends, amenities, or fiscal trajectories. The proposed triple-difference is attractive in principle, but only if residence status is truly observed and comparable within commune; otherwise the placebo arm may collapse.
- **Recommendation:** **CONSIDER**  
  *(I would upgrade this to PURSUE if you can verify residence-status observability, construct a more precise treatment measure, and preferably add tighter spatial comparisons—e.g., border designs or repeat-sales.)*

---

**#3: Does Mandatory Social Housing Change Neighborhoods? Evidence from France's Loi SRU**
- **Score: 51/100**
- **Strengths:** The policy question is important and politically salient. An administrative threshold is the right instinct, and there is clear policy demand for evidence on whether social-housing mandates depress or improve nearby private-market values.
- **Concerns:** As written, this is not yet a strong causal design. The SRU treatment is slow-moving, fuzzy, and layered with exemptions, enforcement variation, and long implementation lags; the local RDD around 3,500 inhabitants is likely to identify effects for small borderline communes, not for the affluent suburban places where the policy debate is most intense.
- **Novelty Assessment:** There is a sizable literature on social housing, inclusionary mandates, and property values. The **French SRU setting** is less saturated than US inclusionary-zoning work, but it is not blank-slate novel.
- **Top-Journal Potential: Low.** In current form, this looks more like a competent policy paper than a field-shaping one. The likely output is a local reduced-form effect around a population threshold, not a sharp general lesson about social-mixing policy.
- **Identification Concerns:** The threshold is not the whole treatment rule; SRU applicability depends on broader urban-area conditions, compliance is imperfect, and other population-based institutions may also change near 3,500. The biggest practical issue is timing: the law began long before DVF microdata, so the proposal lacks a convincing pre/post structure for the main treatment.
- **Recommendation:** **SKIP**  
  *(Unless redesigned around entry into obligation over time, project-level social-housing siting, or a cleaner source of quasi-random exposure.)*

---

### Summary

This is a decent batch with **one genuinely promising project** and **one plausible field-journal project**. I would pursue **Idea 2 first** because it has the best chance to produce a sharp, novel contribution on **regulation versus information**; **Idea 1** is worth keeping alive but needs a more credible treatment/placebo strategy; **Idea 3** is currently too fuzzy and local to justify first-pass investment.

