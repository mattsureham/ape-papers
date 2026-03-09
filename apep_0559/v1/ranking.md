# Research Idea Ranking

**Generated:** 2026-03-09T15:33:17.159864
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Cap On, Cap Off: The Symmetric Credit Ra... | PURSUE (69) | — | PURSUE (76) |
| Does Health System Capacity Determine Wh... | CONSIDER (55) | CONSIDER (54) | CONSIDER (55) |
| Constitutional Designation and Health Co... | SKIP (44) | SKIP (42) | SKIP (47) |
| Cap On, Cap Off: The Symmetric Credit Ra... | — | PURSUE (86) | — |

---

## GPT-5.4 (A)

**Tokens:** 8444

### Rankings

**#1: Cap On, Cap Off: The Symmetric Credit Rationing Experiment from Kenya's Interest Rate Ceiling (2016-2019)**
- **Score:** 69/100
- **Strengths:** This is the only idea with a potentially compelling causal chain that a broad audience can understand: interest-rate caps → bank portfolio reallocation → private credit contraction → borrower substitution into unregulated digital credit. The repeal is genuinely valuable and makes the setting more novel than the already-studied cap introduction alone.
- **Concerns:** The national policy itself has no untreated control group, so the design lives or dies on cross-bank heterogeneity, and “Tier 3 vs Tier 1” is a fairly blunt exposure measure. The repeal is also almost immediately followed by COVID, which makes the reversal test much less clean than advertised.
- **Novelty Assessment:** **Medium-high.** Kenya’s 2016 cap has definitely been studied, so this is not a fresh topic cluster. But the cap-plus-repeal symmetry, and especially the digital-credit substitution angle, do seem meaningfully less explored.
- **Top-Journal Potential:** **Medium.** This could be attractive for **AEJ: Economic Policy**, JDE, or a strong finance/development outlet if the paper convincingly shows one sharp mechanism. For a top-5, the identification would need to be tightened beyond coarse bank-tier comparisons, and the welfare consequences of substitution to high-cost digital credit would need to be front and center.
- **Identification Concerns:** The main threat is that bank size/tier proxies for many underlying differences in trends, risk, clientele, and macro sensitivity. Also, the repeal window is contaminated by the pandemic, so the “symmetric reversal” is not as close to a built-in placebo as it first appears.
- **Recommendation:** **PURSUE (conditional on: obtaining true bank-level supervisory data rather than tier aggregates; replacing tier DiD with a sharper pre-cap exposure measure; showing repeal results are not driven by COVID timing)**

---

**#2: Does Health System Capacity Determine Who Benefits from Free Maternity? County-Level Evidence from Kenya's 2013 Devolution**
- **Score:** 55/100
- **Strengths:** The outcome is first-order and policy-relevant, and the “implementation capacity determines who benefits” framing is substantively important for UHC debates. The DHS birth microdata plus facility registry give this idea much better empirical material than a typical county-level reform paper.
- **Concerns:** As stated, the design muddles two simultaneous national changes—devolution and free maternity—while using baseline capacity, an endogenous county characteristic, as treatment intensity. That is a hard sell causally unless the paper is substantially redesigned.
- **Novelty Assessment:** **Medium-low.** Free maternity in Kenya, devolution, and maternal service use are all well-trodden topics. The capacity-heterogeneity angle and longer horizon help, but this still reads more like a refinement than a new object.
- **Top-Journal Potential:** **Low.** In current form this is more likely a competent health/development field paper than a top-journal paper. It would become more interesting if reframed tightly around one reform margin and one implementation mechanism using the DHS birth histories to build a much sharper event-study design.
- **Identification Concerns:** High-capacity counties were likely already on different trajectories, so a continuous-treatment DiD may mostly recover differential trends. Without a convincing pre-trend strategy and cleaner separation of fee abolition from devolution, causal interpretation will remain weak.
- **Recommendation:** **CONSIDER**

---

**#3: Constitutional Designation and Health Convergence: Kenya's Equalization Fund and the Marginalization Gap**
- **Score:** 44/100
- **Strengths:** This is the most novel idea in the batch, and the constitutional designation is politically important. If identified credibly, it would speak to whether formula-based territorial equalization can narrow spatial health gaps.
- **Concerns:** The treatment is targeted by design, partial in intensity, and seemingly delayed/uneven in execution; that is a bad combination for DiD. With only 47 counties and essentially two county-level periods, the effective design is thin and vulnerable.
- **Novelty Assessment:** **High.** I do not know of a well-known causal paper on this exact Kenya equalization designation question. The problem is not novelty; it is credibility.
- **Top-Journal Potential:** **Low.** This risks reading as a narrow county-transfer evaluation with weak identification and modest fiscal stakes, which is exactly the kind of “competent but not exciting” paper that struggles. Without a sharper design—ideally based on a threshold or allocation rule—it is unlikely to travel.
- **Identification Concerns:** Marginalized counties were worse off by construction, so post-2010 convergence could reflect mean reversion, broader devolution, conflict dynamics, donor targeting, or other concurrent policies. Province-level pre-trends do not solve a county-level identification problem.
- **Recommendation:** **SKIP**

---

### Summary

This is a mixed batch: one clearly worth serious development, one salvageable with a major redesign, and one too thin to justify current effort. I would pursue **Idea 1** first, but only if you can secure genuinely bank-level data and shore up the repeal/COVID problem; **Idea 3** is the backup if it is reframed around a much sharper event-study design using birth histories.

---

## Gemini 3.1 Pro

**Tokens:** 6051

Here is my evaluation of the three research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessment of top-journal potential in empirically observed editorial preferences.

### Rankings

**#1: Cap On, Cap Off: The Symmetric Credit Rationing Experiment from Kenya's Interest Rate Ceiling**
- **Score**: 86/100
- **Strengths**: This proposal exploits a rare, symmetric policy shock (imposition and repeal) which provides a built-in reversal test, making the causal claim highly credible. Furthermore, it maps a complete causal chain from macro-regulation to bank portfolio rebalancing, all the way down to household substitution into predatory digital credit.
- **Concerns**: The Tier 3 vs. Tier 1 DiD assumes large and small banks would have had parallel credit growth trends absent the cap, which might be violated if macroeconomic conditions (like COVID-19 at the tail end) affected SME lending differently than corporate lending. 
- **Novelty Assessment**: High. While the 2016 cap introduction has been studied (mostly in policy working papers), the 2019 repeal and the specific substitution into unregulated M-Pesa digital credit (the 90% APR shadow market) is highly novel and elevates this from a standard banking paper to a household finance/welfare paper.
- **Top-Journal Potential**: High. This perfectly fits the editorial pattern of "first-order stakes + one sharp channel." It moves beyond a simple Average Treatment Effect (ATE) to deliver a compelling causal narrative (Regulation $\rightarrow$ Bank Rebalancing $\rightarrow$ Shadow Market Substitution) that challenges the conventional wisdom of consumer protection laws.
- **Identification Concerns**: The primary threat is that Tier 1 and Tier 3 banks serve fundamentally different client bases (corporate vs. SME), meaning their baseline credit growth trajectories might diverge due to underlying economic cycles rather than the rate cap. 
- **Recommendation**: PURSUE (conditional on: demonstrating parallel pre-trends between Tier 1 and Tier 3 banks prior to 2016, and successfully linking the macro bank data to the micro household substitution story).

**#2: Does Health System Capacity Determine Who Benefits from Free Maternity? County-Level Evidence from Kenya's 2013 Devolution**
- **Score**: 54/100
- **Strengths**: It asks a logical, policy-relevant question about whether supply-side constraints bind the effectiveness of demand-side subsidies (free maternity). The use of micro-level DHS data linked to administrative facility data is a solid, feasible approach.
- **Concerns**: Baseline health infrastructure is highly endogenous; counties with better infrastructure in 2013 are likely wealthier, more urban, and on fundamentally different development trajectories than lagging counties. A continuous DiD over a 9-year gap (2013-2022) will capture a massive amount of omitted variable bias.
- **Novelty Assessment**: Low to Medium. The 2013 free maternity policy has been extensively studied in public health and development literature. Using baseline capacity as a continuous treatment intensity is a slight methodological twist, but not conceptually groundbreaking.
- **Top-Journal Potential**: Low. This falls squarely into the "technically competent but not exciting" category. It lacks a sharp exogenous shock and ultimately just estimates another ATE of a diffuse policy, which editorial patterns show rarely survives top-tier review.
- **Identification Concerns**: Severe violation of the parallel trends assumption. "Pre-existing capacity" is not randomly assigned; it correlates heavily with local governance quality, urbanization, and wealth, all of which independently drive maternal health improvements over a decade.
- **Recommendation**: SKIP (or CONSIDER as a lower-tier field journal submission if the continuous DiD can be replaced with a sharper instrument for capacity).

**#3: Constitutional Designation and Health Convergence: Kenya's Equalization Fund and the Marginalization Gap**
- **Score**: 42/100
- **Strengths**: It attempts to evaluate a major, constitutionally mandated fiscal transfer program with clear equity goals. The distinction between access outcomes (converging) and preventive care (not converging) is an interesting descriptive finding.
- **Concerns**: The treatment assignment ("marginalized" status) is explicitly based on historical underdevelopment, meaning the treated and control groups are fundamentally incomparable. Furthermore, 47 counties is a very small N for a regional DiD, making inference fragile.
- **Novelty Assessment**: Medium. The specific Kenyan Equalization Fund is understudied, but the broader literature on regional fiscal transfers and health convergence is saturated. 
- **Top-Journal Potential**: Low. As noted in the appendix, "diffuse policy affects many things" stories usually lose to sharp, specific mechanisms. This reads as a standard program evaluation with weak identification and no novel economic mechanism.
- **Identification Concerns**: Fatal selection bias. Marginalized counties were designated *because* they were on different, lagging trajectories. A standard DiD or even Synthetic DiD cannot easily fix the fact that these 14 counties face entirely different geographic, institutional, and economic shocks than the other 33.
- **Recommendation**: SKIP.

### Summary

Overall, this batch presents one outstanding idea and two mediocre ones. **Idea 1 (Cap On, Cap Off)** is the clear winner and should be pursued immediately; it combines a rare symmetric natural experiment with a highly compelling, unintended-consequences mechanism (substitution to 90% APR digital loans) that top journals love. Ideas 2 and 3 suffer from classic endogeneity traps—using non-random baseline characteristics (infrastructure or historical marginalization) as treatment variables—and would likely be rejected by top journals as "competent but confounded" program evaluations.

---

## GPT-5.4 (B)

**Tokens:** 8224

### Rankings

**#1: Cap On, Cap Off: The Symmetric Credit Rationing Experiment from Kenya's Interest Rate Ceiling (2016-2019)**
- **Score:** 76/100
- **Strengths:** The on/off policy sequence is genuinely useful and much more interesting than a standard one-shot reform paper. The bank-level monthly supervisory data line up well with the proposed mechanism: cap → portfolio shift to government securities → reduced private credit, with possible borrower substitution into digital credit.
- **Concerns:** The policy hit all banks, so the design does not have a natural untreated control group; everything rests on differential exposure. The repeal window is also contaminated by COVID and other macro changes, so the “reversal test” is not as clean as advertised unless carefully handled.
- **Novelty Assessment:** Kenya’s 2016 cap has definitely been studied, so this is not a blank-slate topic. But the repeal, the symmetric on/off framing, and especially the link to digital-credit substitution are much less mined and likely novel enough to matter.
- **Top-Journal Potential:** **Medium.** This could plausibly become a strong **AEJ: Economic Policy** paper if it cleanly delivers a causal chain and welfare-relevant implications. For top-5, the current identification is probably too coarse unless the exposure design becomes sharper and the borrower-side consequences are convincingly linked.
- **Identification Concerns:** “Bank tier” is not exogenous exposure, and tier-specific trends could reflect many differences unrelated to the cap. I would want a bank-level continuous exposure design based on pre-cap securities holdings, SME orientation, or liability structure, plus event studies and a pre-COVID analysis of the repeal period.
- **Recommendation:** **PURSUE** *(conditional on: replacing tier-only DiD with bank-level exposure measures; showing convincing pre-trends; isolating the repeal effect from COVID; treating digital-credit evidence as mechanism unless stronger linkage is available)*

**#2: Does Health System Capacity Determine Who Benefits from Free Maternity? County-Level Evidence from Kenya's 2013 Devolution**
- **Score:** 55/100
- **Strengths:** The policy question is important and the mechanism is intuitive in a useful way: reforms may only work where delivery capacity exists. The combination of DHS microdata and baseline facility data is feasible and could support informative heterogeneity analysis.
- **Concerns:** As proposed, this is not a clean causal design so much as a “high-capacity counties improved more” paper. Since devolution and free maternity start nearly together, attribution is muddy, and baseline capacity is heavily correlated with pre-existing development trajectories.
- **Novelty Assessment:** There is already a meaningful literature on Kenya’s free maternity policy and on devolution. The “capacity as moderator” angle is new enough for a field-paper contribution, but it feels incremental rather than truly novel.
- **Top-Journal Potential:** **Low.** The likely headline result is fairly expected, and without a sharper source of exogenous heterogeneity it reads as competent policy evaluation rather than a paper that changes how the field thinks.
- **Identification Concerns:** Baseline capacity is endogenous and likely proxies for many omitted trends. This would be much more credible if the team exploited DHS birth histories to build a tighter pre/post design around 2013 and used more specific margins, such as public-vs-private delivery use.
- **Recommendation:** **CONSIDER** *(conditional on: using retrospective birth histories to create a true event-time design; sharpening attribution between devolution and fee abolition; stress-testing against county-specific trend confounding)*

**#3: Constitutional Designation and Health Convergence: Kenya's Equalization Fund and the Marginalization Gap**
- **Score:** 47/100
- **Strengths:** The topic is clearly policy-relevant and relatively under-studied. If one had project-level rollout or exogenous variation in actual disbursements, it could become a meaningful paper on place-based redistribution.
- **Concerns:** The proposed design is weak: the treated counties were chosen precisely because they were historically marginalized, so parallel trends is hard to believe. With only two county-level DHS waves and pre-data at the province level, the paper lacks a convincing causal backbone.
- **Novelty Assessment:** I know of little published causal work on this exact constitutional designation/fund, so the topic itself is fairly fresh. But this is a case where novelty is outweighed by identification problems.
- **Top-Journal Potential:** **Low.** The question is too narrow in its current form, and the design does not isolate a sharp margin that would travel beyond Kenya.
- **Identification Concerns:** Designation is not exogenous, disbursement was partial and delayed, and health outcomes are jointly shaped by many other county and national changes over the same period. Without better treatment-intensity data or quasi-random rollout, causal claims would be fragile.
- **Recommendation:** **SKIP**

### Summary

This is a decent batch, but only one idea stands out as worth serious investment now. **Idea 1** is the clear frontrunner: it has the best mix of novelty, policy importance, usable data, and a potentially compelling mechanism story, though it still needs a stronger identification strategy. **Idea 3** is a possible backup if substantially redesigned; **Idea 2** is too selection-driven in its current form.

