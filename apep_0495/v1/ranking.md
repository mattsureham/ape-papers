# Research Idea Ranking

**Generated:** 2026-03-03T19:40:59.932649
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| The Hidden Tax on School Quality: How VA... | PURSUE (79) | — | PURSUE (88) |
| Does Making Private School More Expensiv... | CONSIDER (61) | — | SKIP (58) |
| Crowding In or Pricing Out? Private Scho... | CONSIDER (57) | — | SKIP (45) |
| The Announcement Premium: How Fast Do Ho... | CONSIDER (52) | — | CONSIDER (65) |
| From Fees to Footfall: How Private Schoo... | SKIP (41) | — | SKIP (32) |
| Idea 1: The Hidden Tax on School Quality... | — | PURSUE (85) | — |
| Idea 3: Does Making Private School More ... | — | CONSIDER (60) | — |
| Idea 4: The Announcement Premium: How Fa... | — | SKIP (52) | — |
| Idea 2: Crowding In or Pricing Out? Priv... | — | SKIP (45) | — |
| Idea 5: From Fees to Footfall: How Priva... | — | SKIP (35) | — |

---

## GPT-5.2

**Tokens:** 6333

### Rankings

**#1: The Hidden Tax on School Quality: How VAT on Private Fees Reshapes England's State School Housing Premium**
- **Score: 79/100**
- **Strengths:** Novel, first-mover exploitation of a large, salient, nationally uniform education price shock with massive transaction data; the DDD design is well-aligned with the mechanism (state-school-quality capitalization) and naturally embeds placebos (low private-share areas; low-quality-school proximity). Clear “causal chain” potential: VAT → private demand shift → state-school demand/sorting → housing premiums.
- **Concerns:** Post-period is still short (14 months) for a slow-moving asset market; composition/selection in transactions (who sells/buys) could masquerade as price effects, and Land Registry lacks rich property attributes. A lot of correlated local shocks (rates, local development, school rebrokerage/catchment boundary behavior) could differentially load on private-school-share areas.
- **Novelty Assessment:** **High** for the policy shock (very new; few/no papers yet). **Medium** for the outcome concept (school quality capitalization is a large literature), but this “reverse-Fack/Grenet via private-sector price shock” angle is meaningfully distinct.
- **Top-Journal Potential: Medium-High.** This is plausibly AEJ:Policy/JPE-level if the design convincingly isolates the channel and you document mechanisms (e.g., private enrollment declines; state admissions pressure; migration/sorting proxies). Top-5 chance rises if you deliver a sharp theoretical implication and show general equilibrium effects, not just a premium shift.
- **Identification Concerns:** The key threat is **differential housing-market trends correlated with baseline private-school share** (London/SE vs elsewhere) interacting with “near good schools” areas; you’ll need strong pre-trends/event-study diagnostics, flexible geography×time controls, and composition checks (repeat-sales; property-type-by-area fixed effects; appraisal of transaction selection).
- **Recommendation:** **PURSUE (conditional on: (i) showing no differential pre-trends in the DDD contrast; (ii) addressing composition with repeat-sales/hedonic proxies and transaction-selection diagnostics; (iii) documenting a first stage—private enrollment/closures or state admissions pressure—to support the mechanism).**

---

**#2: Does Making Private School More Expensive Reduce Inequality? Evidence from England's VAT Shock**
- **Score: 61/100**
- **Strengths:** Good policy question with a clear theoretical hook (Tiebout sorting / “safety valve” removal) and uses the same rich housing data; within-LA dispersion measures are intuitive and communicable to policymakers (spatial inequality).
- **Concerns:** As scoped, it reads like a **secondary outcome** of Idea 1 rather than a standalone contribution; dispersion measures are mechanically sensitive to compositional change in transactions and to broader macro housing volatility. Also, “inequality” via housing dispersion is one step removed from household welfare/educational inequality, so top-journal reviewers may see it as indirect without a stronger welfare mapping.
- **Novelty Assessment:** **Medium.** Spatial house-price dispersion and school-quality premia are heavily studied; the VAT shock is new, but the “inequality via capitalization” framing will feel incremental unless tightly linked to sorting and access.
- **Top-Journal Potential: Medium.** Could land well in a top field journal if it delivers a surprising sign (e.g., policy intended to reduce inequality increases spatial inequality) and is tightly mechanism-backed, but it’s unlikely to beat the more direct capitalization paper as a main contribution.
- **Identification Concerns:** Aggregating to LA-level dispersion increases risk that results are driven by **macro shocks** differentially affecting high-private-share LAs (London/SE). You’ll need robust within-area controls, placebo outcomes, and a demonstration that dispersion changes are specifically around **top school proximity**, not general local price skew.
- **Recommendation:** **CONSIDER (best as a chapter/section within Idea 1, unless you can tie it to a clear sorting/access mechanism and a welfare-relevant counterfactual).**

---

**#3: Crowding In or Pricing Out? Private School VAT and State Sector Pressure in England**
- **Score: 57/100**
- **Strengths:** First-order policy relevance (government claim about pupil switching; fiscal and quality externalities on the state sector). Outcome is close to the actual mechanism policymakers care about (capacity, class size, PTR), and it provides a valuable “first-stage” complement to housing effects.
- **Concerns:** The proposal itself flags the core problem: **annual data with essentially one post period** (so DiD credibility is weak right now). Even with school-level microdata, there may be policy anticipation, staggered admissions timing, and delayed adjustment (capacity expansions), which makes short-run inference fragile.
- **Novelty Assessment:** **Medium-High** on the specific UK VAT shock (new), **medium** on the broader question (many papers on public/private substitution, class size, and crowd-out/in).
- **Top-Journal Potential: Medium (later), Low (now).** With 3–5 post years and strong design (plus heterogeneity by baseline spare capacity), this could be an AEJ:Policy/JPubE-type paper. In the current data window, it will look underpowered and under-identified.
- **Identification Concerns:** With only one post point, you can’t credibly validate dynamics/parallel trends; estimates will be highly sensitive to functional form and any contemporaneous school funding or demographic shocks correlated with private-school share.
- **Recommendation:** **CONSIDER (conditional on: waiting for additional post years or finding higher-frequency administrative admissions/capacity data; and pre-specifying an “equivalence/MDE” framework if the short run is the target).**

---

**#4: The Announcement Premium: How Fast Do Housing Markets Capitalize Education Policy?**
- **Score: 52/100**
- **Strengths:** Clever use of multi-stage information revelation; if feasible, it speaks to an interesting mechanism (expectations vs implementation) and could sharpen interpretation of Idea 1 (anticipation vs realization).
- **Concerns:** Feasibility is the binding constraint: effective “high-frequency” identification is weak with **thin weekly volumes** once you slice by proximity-to-good-schools × local private density. Also, prediction market odds may not cleanly map into local treatment probabilities, and multiple overlapping macro news shocks around elections/budgets contaminate event windows.
- **Novelty Assessment:** **Medium.** “Announcement effects” and housing capitalization timing are studied; the specific policy sequence is new, but the core question is not.
- **Top-Journal Potential: Low-Medium.** This is more likely a publishable add-on than a lead paper unless you can deliver a very clean, high-powered timing result that changes how people interpret housing market efficiency.
- **Identification Concerns:** Event-window contamination (other news), low power, and endogenous timing of transactions/listings around policy uncertainty make causal timing claims hard to defend.
- **Recommendation:** **SKIP as standalone; CONSIDER only as a robustness/interpretation module inside Idea 1 (using monthly event-study with careful window choice and power calculations).**

---

**#5: From Fees to Footfall: How Private School VAT Reshapes Local Economies**
- **Score: 41/100**
- **Strengths:** Broadly policy-relevant if effects exist (local multipliers; business dynamism), and administrative data sources are accessible.
- **Concerns:** High risk of the classic **treatment-to-outcome dilution/mismatch**: private-school spending is a small share of most local economies, so plausible effects on firm formation/employment are tiny relative to noise and concurrent macro shocks. Mechanisms are speculative and many confounders correlate with private-school prevalence (income, urbanization, sector mix), making it hard to get reviewers to believe the exclusion restriction.
- **Novelty Assessment:** **Medium.** Local multiplier papers are common; applying it to private schooling is less common, but not obviously a first-order new object.
- **Top-Journal Potential: Low.** Likely to read as “competent DiD on broad outcomes” with ambiguous interpretability and weak first-stage evidence.
- **Identification Concerns:** Continuous-intensity DiD with broad outcomes invites omitted-variable bias and negative-weight/style critiques; without a strong, directly measured first stage (enrollment/spending/employment at schools) the link is tenuous.
- **Recommendation:** **SKIP (unless you can obtain direct spending/employment exposure measures at the private-school level and show a large, local first stage).**

---

### Summary

This batch has one clear lead: **Idea 1** is the only proposal that combines a genuinely new policy shock, a mechanism-aligned outcome, and a design that can plausibly clear top-field-journal credibility thresholds soon. **Ideas 2–4** are best treated as complements/sections to strengthen Idea 1 (mechanisms, distributional implications, timing), while **Idea 5** is the most likely to fail on dilution and interpretability.

---

## Gemini 3.1 Pro

**Tokens:** 7267

Here is my evaluation of the research proposals, applying the rigorous standards of top-tier economics publishing and the empirical patterns of editorial decision-making.

### Rankings

**#1: Idea 1: The Hidden Tax on School Quality: How VAT on Private Fees Reshapes England's State School Housing Premium**
- **Score**: 85/100
- **Strengths**: This proposal combines a massive, high-quality administrative dataset ("universe" of housing transactions) with a highly credible Triple-Difference (DDD) design that builds in its own placebos. It tests a precise, counter-intuitive theoretical prediction (reversing Fack & Grenet 2010) and delivers a clear "causal chain" showing how an education tax creates general equilibrium effects in the housing market.
- **Concerns**: The post-treatment window is very short (14 months), which is a known editorial penalty for recent policies unless explicitly framed and powered as a "short-run anticipation and immediate realization" paper. Housing markets can be sticky, and transaction volumes might drop due to interest rates, adding noise.
- **Novelty Assessment**: High. The UK's 20% VAT on private schools is a globally unique, massive price shock to private education. No one has published on this yet, giving it a strong first-mover advantage.
- **Top-Journal Potential**: High. A top-5 journal (like *AER* or *AEJ: Policy*) would find this exciting because it takes a highly salient, first-order policy shock and uses it to reveal a surprising substitution effect (taxing private schools makes housing near good state schools less affordable). It perfectly fits the winning "Puzzle → Design → Mechanism → Quantified implication" architecture.
- **Identification Concerns**: The main threat is that the "pre-period" is contaminated by anticipation effects (the Labour manifesto and election). The design must explicitly model the anticipation phase (July-Dec 2024) separately from the realization phase (Jan 2025 onwards) to avoid attenuating the baseline.
- **Recommendation**: PURSUE (conditional on: explicitly framing this as a short-run/anticipation study to bypass the "short post-period" editorial penalty, and folding in the inequality metrics from Idea 3 as a mechanism check).

**#2: Idea 3: Does Making Private School More Expensive Reduce Inequality? Evidence from England's VAT Shock**
- **Score**: 60/100
- **Strengths**: Addresses a first-order welfare and political question—whether removing a private market "safety valve" paradoxically increases spatial inequality via Tiebout sorting. 
- **Concerns**: As a standalone paper, it risks reading as a derivative, single-outcome study. Measuring within-LA price dispersion robustly at high frequencies is statistically noisy.
- **Novelty Assessment**: Moderate. While the shock is new, the literature on school quality and spatial sorting is vast. 
- **Top-Journal Potential**: Medium-Low. On its own, this falls into the modal trap of being "technically competent but not exciting." It lacks the sharp mechanism decomposition of Idea 1. However, if packaged as the *welfare implication* section of Idea 1, it elevates that paper significantly.
- **Identification Concerns**: Defining the correct geographic boundary for dispersion is tricky; LAs are too large and heterogeneous, while LSOAs are too small to calculate meaningful P90/P10 ratios. 
- **Recommendation**: CONSIDER (conditional on: merging this into Idea 1 as the concluding welfare/counterfactual exercise rather than writing it as a standalone paper).

**#3: Idea 4: The Announcement Premium: How Fast Do Housing Markets Capitalize Education Policy?**
- **Score**: 52/100
- **Strengths**: Clever conceptual framing that exploits the multi-stage revelation of the policy (manifesto → election → budget) to test the efficient markets hypothesis in real estate.
- **Concerns**: Severe data feasibility issues. Housing transactions are simply too thin at the weekly/daily level within specific postcodes to run a precise high-frequency event study.
- **Novelty Assessment**: Moderate. Capitalization timing has been studied, though rarely with such a clean, multi-stage political shock.
- **Top-Journal Potential**: Low. Reviewers will immediately attack the statistical power. Papers that fail "hard constraints" diagnostics (like having enough density in the running variable or event window) are rejected at the desk stage.
- **Identification Concerns**: The primary threat is severe small-sample noise. A house takes 3-5 months to complete in the UK; the "transaction date" in the Land Registry often reflects a price agreed upon months prior, completely destroying the high-frequency identification strategy.
- **Recommendation**: SKIP (The data generating process of UK housing transactions is fundamentally incompatible with high-frequency event studies).

**#4: Idea 2: Crowding In or Pricing Out? Private School VAT and State Sector Pressure in England**
- **Score**: 45/100
- **Strengths**: Directly answers the most pressing, first-order political question regarding this policy: where do the displaced children go, and does it break state school capacity?
- **Concerns**: The data frequency is fatal. With annual school census data, there will only be one post-treatment observation (2025/26). 
- **Novelty Assessment**: High policy relevance, but methodologically standard.
- **Top-Journal Potential**: Low. Top journals require rigorous testing of pre-trends and dynamic treatment effects. A DiD with a single post-period is an automatic rejection in modern applied microeconomics unless it's a massive structural model.
- **Identification Concerns**: Fatal flaw. With only one post-treatment year, you cannot validate pre-trends against post-treatment dynamics, nor can you separate a temporary transition shock from a permanent equilibrium shift.
- **Recommendation**: SKIP (Revisit in 2027 or 2028 when 3+ years of post-treatment annual data are available).

**#5: Idea 5: From Fees to Footfall: How Private School VAT Reshapes Local Economies**
- **Score**: 35/100
- **Strengths**: Attempts to look beyond education to find a novel general equilibrium effect on local commercial activity.
- **Concerns**: This suffers from a massive "measurement mismatch" and dilution problem. The economic footprint of a private school is a tiny fraction of a Local Authority's aggregate economy.
- **Novelty Assessment**: Low. "Anchor institution" literature is established, and this is a weak application of it.
- **Top-Journal Potential**: Low. This is exactly the type of paper the editorial appendix warns against: "treatment on diluted outcome." It is underpowered by construction. Reviewers will penalize the speculative mechanism.
- **Identification Concerns**: The effect size of a few dozen families reducing local discretionary spending will be entirely swallowed by macroeconomic noise (inflation, interest rates, broader UK economic stagnation). You will get a precisely estimated null that reviewers will dismiss as simply being underpowered.
- **Recommendation**: SKIP.

### Summary

This batch contains one genuinely excellent proposal (Idea 1) and several weaker, derivative, or fatally flawed ideas. Idea 1 is a top-tier candidate because it combines a massive administrative dataset with a clean DDD design to test a surprising general equilibrium effect of a highly salient new policy. I strongly recommend pursuing **Idea 1**, but you should cannibalize the best elements of Idea 3 (inequality metrics) and Idea 4 (anticipation timing) to build out Idea 1's mechanism and welfare sections, creating a single, undeniable blockbuster paper rather than three mediocre ones.

---

## Grok 4.1 Fast

**Tokens:** 5860

### Rankings

**#1: The Hidden Tax on School Quality: How VAT on Private Fees Reshapes England's State School Housing Premium**
- Score: 88/100
- Strengths: Triple-difference design cleanly isolates the school-quality capitalization channel with built-in placebos (no-private areas) and anticipation tests, leveraging massive universe housing data (24M+ transactions) for high power; directly extends Fack & Grenet (2010) with a novel reverse prediction and traces a clear causal chain (VAT shock → private enrollment shift → state school demand → housing premium).
- Concerns: Post-treatment period is short (14 months by Feb 2026), risking underpowered nulls if effects are delayed; housing market responses could confound with broader economic shocks (e.g., interest rates).
- Novelty Assessment: Extremely high—first exploitation of this major 2025 policy shock anywhere; while state school capitalization is studied (e.g., Fack & Grenet), the private VAT attenuation/reversal mechanism in GE housing is unstudied.
- Top-Journal Potential: High—A top-5 journal would find this exciting as it challenges conventional wisdom on private schooling as a "safety valve" attenuating state quality capitalization, reveals counterintuitive GE welfare costs (hidden housing tax), and packages a compelling mechanism chain with universe data for definitive bounds, fitting editorial preferences for first-order policy stakes and belief-changing pivots.
- Identification Concerns: Parallel trends must hold across the three dimensions (private share × state quality × pre/post), with risk of LA-level confounders spilling over; anticipation effects help but require careful event-study decomposition to rule out pre-July 2024 creeps.
- Recommendation: PURSUE (conditional on: robust pre-trends visualization and placebo batteries in first draft; incorporate inequality/announcement as robustness sections)

**#2: The Announcement Premium: How Fast Do Housing Markets Capitalize Education Policy?**
- Score: 65/100
- Strengths: Multi-stage information shocks (manifesto → election → budget → implementation) enable a clean test of housing market efficiency with prediction market controls; builds on Idea 1 data for anticipation decomposition, adding a novel EMH angle.
- Concerns: Monthly Land Registry data limits high-frequency precision, with thin weekly transaction volumes in narrow postcodes risking noisy event studies; better as a subsection than standalone.
- Novelty Assessment: High for the multi-stage EMH test in policy context—no prior papers on housing capitalization speed for education shocks like this; announcement effects studied elsewhere but not with this granularity.
- Top-Journal Potential: Medium—top-5 might pass if framed as a "hard constraint" diagnostic on market efficiency with mechanism trace (info shocks → prices), but thin data and niche angle (vs. core policy stakes) make it more AEJ:Applied material unless effects sharply rule out delays.
- Identification Concerns: Sparse transactions around event dates could bias estimates toward zero; prediction market integration helps exogeneity but assumes uniform local awareness, vulnerable to heterogeneous anticipation.
- Recommendation: CONSIDER (as extension to Idea 1; skip standalone unless daily data sourcing succeeds)

**#3: Does Making Private School More Expensive Reduce Inequality? Evidence from England's VAT Shock**
- Score: 58/100
- Strengths: Clever Tiebout test of whether VAT removes a "safety valve" increasing spatial inequality via top-school premiums; reuses Idea 1's rich housing data for within-LA dispersion metrics.
- Concerns: Dispersion outcomes (Gini/P90-P10) are noisy and slow-moving, diluting power; lacks standalone bite as a secondary mechanism better folded into a primary capitalization paper.
- Novelty Assessment: Moderately high—inequality via education sorting is studied (e.g., Tiebout models), but VAT-induced reversal on spatial housing gaps is new due to policy timing.
- Top-Journal Potential: Low—competent event study but reads as "unsurprising ATE on narrow outcome" without strong mechanism chain or welfare pivot; editors penalize secondary effects without first-order stakes or field-changing implications.
- Identification Concerns: Within-LA dispersion could reflect general market volatility rather than policy; treatment intensity (private share) may correlate with baseline inequality, threatening exogeneity without finer controls.
- Recommendation: SKIP (incorporate as robustness in Idea 1)

**#4: Crowding In or Pricing Out? Private School VAT and State Sector Pressure in England**
- Score: 45/100
- Strengths: Directly tests government's 37k-pupil switch prediction with policy-relevant state capacity metrics; feasible school-level data.
- Concerns: Annual data yields only 1 post-2025 observation, preventing pre-trend validation or dynamics; severely underpowered for credible DiD.
- Novelty Assessment: Moderate—private-to-state enrollment shifts theorized (e.g., Epple et al.), but quantification of this specific VAT "absorption cost" is new.
- Top-Journal Potential: Low—short-run single-period DiD on administrative margins fits "recent policy with thin post-period" losses; no mechanism beyond raw ATE, lacking excitement or chain.
- Identification Concerns: Continuous treatment DiD vulnerable to LA confounders (e.g., migration unrelated to VAT); no post-dynamics means failed pre-trends invalidate everything.
- Recommendation: SKIP (wait for 2+ post-years or pivot to projections)

**#5: From Fees to Footfall: How Private School VAT Reshapes Local Economies**
- Score: 32/100
- Strengths: Explores understudied local multipliers of education anchors; accessible data sources.
- Concerns: Speculative chain (enrollment → spending → firm/employment) with tiny private school GDP shares predicts undetectable effects; classic "diluted outcome" mismatch.
- Novelty Assessment: Low—education multipliers studied peripherally (e.g., college impacts), but private K-12 local effects unstudied; still niche.
- Top-Journal Potential: Low—textbook editorial loss: treatment on diluted outcomes (VAT → Companies House/NOMIS noise) without bite, mechanism, or stakes; "competent but not exciting."
- Identification Concerns: DiD treatment intensity diluted across LAs; outcomes (firms/employment) mismatch treated pupils, risking zero power as flagged in appendix.
- Recommendation: SKIP

### Summary
This batch is strong overall due to a fresh, high-stakes 2025 policy shock enabling first-mover natural experiments with universe data, but only Idea 1 delivers top-journal excitement via clean ID, mechanism chain, and welfare pivot—others suffer dilution, thin data, or secondary status. Pursue Idea 1 immediately as the anchor paper (folding in #2/#3 elements), skip the rest unless resourced as extensions; no idea warrants standalone effort beyond #1.

