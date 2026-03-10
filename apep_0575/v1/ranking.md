# Research Idea Ranking

**Generated:** 2026-03-10T11:26:35.945741
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Importing What You Used to Make: Energy-... | PURSUE (69) | PURSUE (84) | PURSUE (66) |
| Bail-In Risk and Household Deposit Struc... | CONSIDER (61) | SKIP (52) | CONSIDER (60) |
| Paying on Time Saves Firms: The EU Late ... | SKIP (48) | SKIP (38) | SKIP (45) |

---

## GPT-5.4 (A)

**Tokens:** 9533

### Rankings

**#1: Importing What You Used to Make: Energy-Cost-Driven Import Substitution in European Manufacturing After the 2022 Gas Shock**
- **Score: 69/100**
- **Strengths:** This has the clearest “big shock → production loss → import substitution” causal chain, and the outcome is economically legible. If you can show persistence after gas prices normalized, the paper becomes much more interesting than a standard short-run shock study.
- **Concerns:** The 2022 gas shock is already a crowded literature, so the exact contribution must be the *import reallocation/persistence* margin, not just another output-effect paper. The design could also be confounded by sanctions exposure, general demand shifts, and pre-existing industrial specialization in high-Russian-gas countries.
- **Novelty Assessment:** **Moderate.** There are already many papers on the European gas shock, energy-intensive production, and competitiveness. The specific “reverse import substitution” channel is less studied, but I would not treat it as a blank-slate topic.
- **Top-Journal Potential:** **Medium.** This could make a strong AEJ/field-journal paper, and possibly stretch higher if the core result is that a temporary energy shock caused persistent import dependence/deindustrialization. If the punchline is only “imports rose where production fell,” that is too intuitive for top-5.
- **Identification Concerns:** The key threat is that pre-war Russian gas dependence proxies for many other country characteristics. You need strong pre-trend evidence, controls for Russia-related trade/sanctions exposure, and ideally show the import response comes from non-Russian suppliers and is concentrated where domestic production actually collapsed.
- **Recommendation:** **PURSUE (conditional on: strong pre-trend evidence; non-Russian source decomposition; a tight mapping from domestic production losses to subsequent import growth/persistence)**

**#2: Bail-In Risk and Household Deposit Structure: How BRRD Transposition Reshuffled European Savings**
- **Score: 61/100**
- **Strengths:** This is the most novel idea in the batch conceptually: the household deposit channel of bail-in policy is much less studied than bond spreads, CDS, or wholesale funding. The policy question is real and important for banking-union design and financial stability.
- **Concerns:** The main problem is measurement: BRRD changes risk for **uninsured deposits by account size**, but the proposed outcomes are **aggregate household deposits by maturity type**, which is only loosely connected to the treated margin. The treatment timing is also blurred by EU-wide anticipation, Cyprus precedent, and the staggered/legal transposition versus actual perceived enforceability.
- **Novelty Assessment:** **Fairly high.** I know a substantial literature on BRRD/bail-ins and market discipline, but much less on household deposit reallocation. Still, depositor-discipline questions are not entirely unstudied, so the novelty is “high within a known area,” not completely new.
- **Top-Journal Potential:** **Low-Medium.** With account-size or bank-level deposit exposure data, this could become a compelling finance-policy paper. With the current aggregate maturity outcomes, it risks reading as indirect and hard to interpret, which will cap general-interest appeal.
- **Identification Concerns:** National transposition dates may not capture when households actually updated beliefs about bail-in risk. With only about 25 countries and heavy contemporaneous ECB/macroeconomic changes, inference is fragile, and parallel trends may be hard to defend.
- **Recommendation:** **CONSIDER**

**#3: Paying on Time Saves Firms: The EU Late Payment Directive and Small Firm Survival**
- **Score: 48/100**
- **Strengths:** The mechanism is intuitive and policy relevant: faster public payment could relax liquidity constraints for small firms. Policymakers do care about payment delays and SME fragility.
- **Concerns:** This feels incremental relative to an existing literature, and the identification is weak in its current form. The directive was largely a common EU shock, the size-class comparison is a noisy exposure proxy, and annual survival outcomes with very few pre-periods make this hard to sell causally.
- **Novelty Assessment:** **Low to moderate.** Late payment, trade credit, and firm outcomes have already been studied, including causal work on this directive. The proposed angle is a new margin/outcome, not a new question.
- **Top-Journal Potential:** **Low.** Even with clean execution, this is likely to read as “competent but not exciting.” It would need much sharper exposure data—ideally invoice/payment or procurement-linked administrative records—to become more than a modest policy paper.
- **Identification Concerns:** Cross-country “payment culture” is not exogenous treatment; it is a treatment-intensity proxy that could correlate with many differential trends. The 3-year survival outcome also creates timing complications, and Belgium’s delayed transposition alone is not enough to anchor the design.
- **Recommendation:** **SKIP**

### Summary

This is a mixed batch: one clearly usable idea, one interesting but under-measured idea, and one that I would drop. I would pursue **Idea 2** first, because it has the best combination of first-order stakes, plausible design, and publishable narrative. **Idea 1** is worth revisiting only if you can get data closer to the actual treated margin—uninsured deposits, bank-level exposure, or account-size structure.

---

## Gemini 3.1 Pro

**Tokens:** 7445

Here is my evaluation of the research proposals, ranked from most to least promising. 

### Rankings

**#1: Importing What You Used to Make: Energy-Cost-Driven Import Substitution in European Manufacturing After the 2022 Gas Shock**
- **Score**: 84/100
- **Strengths**: This addresses a massive, first-order policy question (European deindustrialization) using a very clean triple-difference design with high-quality, high-frequency administrative trade data. The mechanism (import substitution) is economically legible, highly relevant, and directly tied to the shock.
- **Concerns**: HS2 product-level data is too aggregated and will suffer from compositional effects; you need to use HS4 or HS6 to cleanly isolate energy-intensive products. You also need to ensure you can separate this shock from concurrent post-COVID supply chain normalizations.
- **Novelty Assessment**: High. While the 2022 gas shock has been heavily studied in macro models (e.g., Bachmann et al.), empirical micro-trade papers on the actual reallocation are still emerging. The "reverse import substitution" framing is a fresh, compelling angle on a widely discussed topic.
- **Top-Journal Potential**: High. This perfectly fits the editorial preference for "first-order stakes + one sharp channel." If the paper can demonstrate hysteresis—showing that imports stayed elevated even after gas prices normalized, implying permanent supply chain scarring—it would be highly competitive for a top-5 or top field journal (like *AEJ: Economic Policy*).
- **Identification Concerns**: The main threat is that countries with high pre-war Russian gas dependence (e.g., Germany, Italy) might have different baseline import/export dynamics due to other concurrent macroeconomic shocks (e.g., the economic slowdown in China affecting German manufacturing). 
- **Recommendation**: PURSUE (conditional on: using HS4/HS6 level data instead of HS2; adding controls for country-specific macro trends and global demand shocks).

**#2: Bail-In Risk and Household Deposit Structure: How BRRD Transposition Reshuffled European Savings**
- **Score**: 52/100
- **Strengths**: Attempts to link a major, complex financial regulation to legible household behavior, utilizing a staggered rollout across Europe. 
- **Concerns**: Country-level aggregate data (N=25) is far too coarse for credible causal inference in modern applied microeconomics. Furthermore, the mechanism is slightly confused: bail-in applies to all uninsured deposits, so it is unclear why households would shift *maturity* types rather than simply splitting accounts across multiple banks to stay under the €100k limit.
- **Novelty Assessment**: Low to Medium. Bail-in and depositor discipline is a very crowded literature. While looking at household deposit maturity is a slightly new angle, it is an incremental addition rather than a fundamental shift in our understanding of banking regulation.
- **Top-Journal Potential**: Low. Top journals routinely reject country-level panel DiDs with N=25 unless the shock is perfectly exogenous and the data is groundbreaking. Even if executed perfectly, this reads as "technically competent but not exciting."
- **Identification Concerns**: Endogenous transposition timing is a fatal flaw here. Countries with fragile banking systems and high NPLs (e.g., Italy) intentionally delayed BRRD transposition. Therefore, treatment timing is highly correlated with unobserved banking sector stress, severely violating the parallel trends assumption.
- **Recommendation**: SKIP.

**#3: Paying on Time Saves Firms: The EU Late Payment Directive and Small Firm Survival**
- **Score**: 38/100
- **Strengths**: Focuses on a real, legible problem for SMEs (liquidity and late payments) and attempts to use a triple-difference design to isolate the effect across different firm sizes.
- **Concerns**: The macroeconomic timing of this study is disastrous for the proposed identification strategy. The data relies on Eurostat business demography, which is notoriously patchy and subject to structural breaks across countries.
- **Novelty Assessment**: Low. The Late Payment Directive has been studied, and the "payment culture" angle is somewhat dated. Using firm size class as a variation is standard, but in this context, it introduces massive confounding variables.
- **Top-Journal Potential**: Low. The fatal confounding with the Eurozone crisis makes this unpublishable in a top journal. Reviewers will immediately see this as a flawed identification strategy rather than a clean causal test. It violates the rule of having a "clean design with unusual data."
- **Identification Concerns**: Massive omitted variable bias. The 2011-2013 transposition period perfectly coincides with the peak of the European Sovereign Debt Crisis. This crisis caused a severe credit crunch in Southern Europe (the "bad payment culture" group) exactly when the directive was implemented, and credit crunches kill small firms much faster than large firms. Your triple-diff is just measuring the Eurozone crisis.
- **Recommendation**: SKIP.

### Summary

This batch presents a mix of one highly promising idea and two fatally flawed ones. **Idea 2 (Gas Shock)** is a standout that you should pursue immediately; it offers a clean identification strategy for a first-order macroeconomic shock, perfectly aligning with top-journal preferences for high stakes and sharp mechanisms. Ideas 1 and 3 suffer from severe identification threats—specifically endogenous policy timing and massive macroeconomic confounding—and rely on overly aggregated data, making them unviable for top-tier publications or credible policy evaluation.

---

## GPT-5.4 (B)

**Tokens:** 7897

### Rankings

**#1: Importing What You Used to Make: Energy-Cost-Driven Import Substitution in European Manufacturing After the 2022 Gas Shock**
- **Score:** 66/100
- **Strengths:** This asks a first-order question with a very legible outcome: did the gas shock force Europe to replace domestic production with imports? The story can be packaged as a compelling causal chain—gas exposure × energy intensity → production collapse → import substitution → possible persistence/deindustrialization.
- **Concerns:** The design risks conflating energy-cost effects with sanctions, demand shifts, supply-chain normalization, and national subsidy responses. HS2 trade categories are quite coarse, so “imports rose” may not cleanly map to “countries imported what they stopped making.”
- **Novelty Assessment:** **Moderately novel.** There is already a fast-growing literature on the 2022 gas shock and European manufacturing, but the specific import-reallocation/reverse-import-substitution channel is less saturated than production, prices, or export competitiveness.
- **Top-Journal Potential:** **Medium.** A top field journal is plausible if the paper sharpens the mechanism and shows persistence tied to plant shutdowns or supply-chain reorganization. In current form, it is probably not top-5 ready because the design is still somewhat reduced-form and the product aggregation is coarse.
- **Identification Concerns:** Pre-war Russian gas dependence is predetermined, but not obviously exogenous to broader industrial structure and trade trends. You would need strong pre-trend evidence, non-Russian import measures, and ideally tighter product/sector matching so the import response can be linked directly to domestic production shortfalls.
- **Recommendation:** **PURSUE (conditional on: using quantities or deflated values rather than nominal imports; excluding Russia-specific trade-disruption channels; moving to finer product/sector concordances and showing clear pre-trends)**

**#2: Bail-In Risk and Household Deposit Structure: How BRRD Transposition Reshuffled European Savings**
- **Score:** 60/100
- **Strengths:** This is the most novel idea in the batch: the BRRD household-depositor channel is much less studied than bond, CDS, or bank funding effects. If transposition materially changed household deposit composition or cross-border flows, that would be a meaningful contribution to banking regulation and depositor-discipline debates.
- **Concerns:** The main outcome is not tightly matched to the policy. Household deposit maturity buckets are a noisy proxy for uninsured deposits above €100,000, so any true effect may be heavily diluted in aggregate country data.
- **Novelty Assessment:** **High on the exact question, moderate in the broader area.** There is a substantial literature on depositor discipline and BRRD-related market pricing, but much less on household deposit restructuring induced by bail-in rules across Europe.
- **Top-Journal Potential:** **Low-Medium.** This feels like a solid banking-policy paper, but not an obvious top-5 paper unless it uncovers a surprisingly large retail flight/cross-border sorting margin with clear welfare stakes. With current data, AEJ: Economic Policy or a strong finance/banking field journal seems more realistic than AER/QJE/JPE.
- **Identification Concerns:** The policy was likely anticipated at the EU level before national transposition, so transposition dates may be a weak or contaminated treatment margin. With only about 25 country clusters and a short adoption window, inference is fragile, and adoption timing may correlate with national banking stress or administrative capacity.
- **Recommendation:** **CONSIDER**  
  *(I would upgrade this to PURSUE if you can get direct measures of uninsured deposits, bank-level balance data, or convincing evidence that national transposition—not EU-level adoption—was the relevant expectation shock.)*

**#3: Paying on Time Saves Firms: The EU Late Payment Directive and Small Firm Survival**
- **Score:** 45/100
- **Strengths:** The policy question is important: payment discipline and SME survival are highly policy-relevant. Survival and exit are also stronger outcomes than attitudes or compliance rates, and the cross-country institutional heterogeneity is real.
- **Concerns:** The identification is the weakest of the three. Since transposition was nearly simultaneous across countries, the design is effectively driven by heterogeneous exposure, not clean policy timing, and size class is a very blunt proxy for who is actually exposed to late public payments.
- **Novelty Assessment:** **Low-Moderate.** The exact outcome/design may be somewhat new, but late payments, SME liquidity constraints, and the directive itself are already well-trodden topics. This does not feel like an unstudied policy margin.
- **Top-Journal Potential:** **Low.** Even a well-executed version likely reads as “competent policy evaluation” rather than a paper that changes how the field thinks. Without micro data on invoicing or procurement exposure, it is hard to see this clearing a top general-interest bar.
- **Identification Concerns:** The key threat is differential trends: high-delay countries and small firms were already on different recovery paths after the euro-area crisis. With only annual size-class aggregates and almost no timing variation, the triple-diff is vulnerable to generic SME recovery, insolvency-regime changes, and other country-level shocks.
- **Recommendation:** **SKIP**  
  *(Unless you can obtain invoice-level or firm-level procurement/payment data that directly measures exposure to public-sector late payment.)*

### Summary

This is a decent batch, but none are currently “obvious top-5” ideas. I would **pursue Idea 2 first** because it has the best mix of first-order stakes, reasonably workable design, and a publishable causal chain; **Idea 1 is the most novel but needs much better exposure measurement**; **Idea 3 should be deprioritized unless the data become much more micro and policy-linked**.

