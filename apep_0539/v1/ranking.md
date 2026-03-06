# Research Idea Ranking

**Generated:** 2026-03-06T14:14:50.075066
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| The Economic Integration Lottery: How Im... | PURSUE (76) | SKIP (35) | CONSIDER (65) |
| The Symmetric Tax Shock: Housing Capital... | CONSIDER (67) | PURSUE (85) | SKIP (57) |
| Less Cash, Less Crime? The Nationwide Ef... | SKIP (59) | SKIP (55) | PURSUE (73) |

---

## GPT-5.4 (A)

**Tokens:** 9290

### Rankings

**#1: The Economic Integration Lottery: How Immigration Judge Leniency Shapes Local Labor Markets**
- **Score: 76/100**
- **Strengths:** This asks a first-order policy question with unusually strong quasi-random variation: judge assignment offers a rare way to separate legal status from immigrant selection. If executed well, the paper has a sharp causal chain—judge leniency → asylum grants/legal work authorization → local labor supply and wage/employment effects.
- **Concerns:** The design is only as good as the geographic linkage. Random assignment within court is powerful for individual outcomes, but turning that into credible county-level labor-market effects is not automatic, and aggregate effects may be too diffuse to detect.
- **Novelty Assessment:** **High on the exact design, moderate on the broader question.** Immigration judge leniency is a well-known instrument, and immigration/labor-market effects are heavily studied, but using judge quasi-randomness to estimate local economic spillovers appears genuinely underexplored.
- **Top-Journal Potential: High.** This is the kind of question top journals care about: large policy stakes, a clean institutional source of variation, and the potential to shift beliefs about legalization versus immigration itself. But it needs a compelling market-exposure design and results that go beyond a noisy aggregate ATE.
- **Identification Concerns:** You need applicant residence or a defensible local exposure measure, plus leave-one-out leniency constructed within court-time cells. The main threats are ecological slippage between courts and labor markets, spillovers across counties, and the possibility that grant effects are too geographically dispersed for county outcomes to cleanly capture.
- **Recommendation:** **PURSUE (conditional on: applicant residence/county can be observed or reliably imputed; county-year exposure is built from quasi-random judge assignment rather than raw grant rates; the analysis prioritizes asylum-exposed sectors/noncitizen outcomes before jumping to aggregate county wages)**

**#2: The Symmetric Tax Shock: Housing Capitalization of the SALT Deduction Cap and Its Reversal**
- **Score: 67/100**
- **Strengths:** The “same places treated twice” framing is clever and potentially important: reversibility is a real conceptual question in capitalization and public finance. Data access is excellent, and the policy is economically meaningful.
- **Concerns:** The 2018 SALT cap is already well studied, so most of the novelty comes from the 2025 reversal. That reversal is very recent, and any short-run housing response will be hard to interpret if expectations about permanence are weak or if other tax changes moved at the same time.
- **Novelty Assessment:** **Moderate.** The core incidence/capitalization question is well worked-over; the reversal and formal symmetry test are the new elements.
- **Top-Journal Potential: Medium.** If you find strong asymmetry—or surprisingly fast full reversibility—that could be field-leading and maybe stretch higher. If the paper mostly produces another within-metro capitalization estimate, it will feel incremental rather than field-changing.
- **Identification Concerns:** Pre-reform SALT exposure is correlated with income, housing demand, and neighborhood trends, so raw exposure measures are not enough. You would want a tax-simulation-based exposure measure, careful treatment of concurrent TCJA/2025 provisions, and a credible expectations story about why a price response should appear quickly.
- **Recommendation:** **CONSIDER**

**#3: Less Cash, Less Crime? The Nationwide Effect of Electronic Benefit Transfer on Property Crime**
- **Score: 59/100**
- **Strengths:** The mechanism is intuitive and appealing: replacing liquid paper food stamps with PIN-protected cards plausibly shrinks theft and black-market resale. The data are easy to obtain, the rollout is nationwide, and there is enough pre-period for standard event-study diagnostics.
- **Concerns:** This is likely to read as a national extension of an existing idea rather than a new one. More importantly, annual state-level property crime is a blunt outcome for a mechanism that is probably local, offense-specific, and intertwined with broader welfare-reform and state-governance changes.
- **Novelty Assessment:** **Moderate to low.** A national staggered-adoption paper may be new, but the EBT-crime hypothesis itself has already been explored in narrower settings and adjacent literatures.
- **Top-Journal Potential: Low.** The channel is clever, but the likely editorial reaction is “competent scale-up of prior work” rather than “belief-changing paper.” This feels more like a solid field-journal project if the estimates are clean and sizable.
- **Identification Concerns:** EBT timing may proxy for broader welfare modernization, anti-fraud efforts, or administrative capacity, all of which may correlate with crime trends. With only 51 state units and broad annual UCR outcomes, it will be hard to tightly isolate the underground-currency mechanism from other concurrent state changes.
- **Recommendation:** **SKIP**

### Summary

This is a decent batch, but only one idea looks clearly worth pushing hard. I would pursue the immigration-judge project first because it combines high novelty, big policy stakes, and the possibility of a compelling legal-status-to-labor-market causal chain. The SALT reversal idea is worth keeping alive as a second-best option if you can sharpen identification; the EBT-crime project feels publishable but not especially exciting.

---

## Gemini 3.1 Pro

**Tokens:** 7330

Here is my evaluation of the research proposals, ranked from most to least promising, based on the criteria and editorial patterns provided.

### Rankings

**#1: The Symmetric Tax Shock: Housing Capitalization of the SALT Deduction Cap and Its Reversal**
- **Score**: 85/100
- **Strengths**: This proposal brilliantly elevates a standard policy evaluation into a test of a fundamental public finance question: the reversibility of tax capitalization. The data is high-frequency, highly granular (zip-level), and readily available.
- **Concerns**: The macroeconomic environment of 2018 (low interest rates, pre-COVID) is vastly different from 2025 (higher rates, remote work), which could confound the symmetry test if housing demand elasticities have fundamentally changed.
- **Novelty Assessment**: High. While the 2018 SALT cap has been studied, the 2025 reversal is unstudied. More importantly, framing this as a "symmetric experiment" to test reversibility is a highly novel conceptual object that pushes the literature forward.
- **Top-Journal Potential**: High. Top-5 journals love papers that use specific policy shocks to crack general economic puzzles. As noted in the appendix, "first-order stakes + one sharp causal channel" wins. Housing wealth is economically legible and welfare-relevant, and the symmetry test provides a compelling narrative arc beyond a simple Average Treatment Effect (ATE).
- **Identification Concerns**: Anticipation effects are the primary threat; housing markets are forward-looking, so prices may capitalize the 2025 reversal well before the law actually passes, requiring careful event-study timing. Additionally, remote-work-driven migration out of high-tax states during COVID must be rigorously controlled for, as it overlaps with SALT exposure.
- **Recommendation**: PURSUE (conditional on: establishing a clean strategy to separate the 2025 SALT reversal from post-COVID remote work migration trends).

**#2: Less Cash, Less Crime? The Nationwide Effect of Electronic Benefit Transfer on Property Crime**
- **Score**: 55/100
- **Strengths**: The mechanism—a welfare technology upgrade destroying an underground black-market currency—is economically fascinating and tells a great causal story. The staggered rollout provides a textbook setup for modern DiD estimators.
- **Concerns**: Moving to state-level crime data is a massive step backward in granularity, making the outcome data incredibly noisy. Furthermore, the core mechanism has already been proven in a published paper (Wright et al., 2017).
- **Novelty Assessment**: Low. The "underground currency" mechanism is already established in the literature. Simply applying a newer estimator (CS-DiD) to a broader but coarser geographic level (states instead of counties) is an incremental update, not a paradigm shift.
- **Top-Journal Potential**: Low. This is the poster child for the "competent but not exciting" penalty mentioned in the appendix. It does not change beliefs or overturn a benchmark; it merely confirms an existing finding using a national, albeit coarser, dataset. 
- **Identification Concerns**: 51 states over a 10-year period is a small N for reliable cluster-robust inference. More importantly, state-level crime trends in the late 90s and early 00s were driven by massive macro factors (the waning crack epidemic, major policing shifts) that could easily correlate with a state's administrative capacity to roll out EBT.
- **Recommendation**: SKIP

**#3: The Economic Integration Lottery: How Immigration Judge Leniency Shapes Local Labor Markets**
- **Score**: 35/100
- **Strengths**: The UJIVE design is a highly credible, proven identification strategy, and the EOIR dataset offers a massive sample size with a genuinely strong first stage at the individual level.
- **Concerns**: There is a fatal scale mismatch between the micro-treatment and the macro-outcome. Asylum grants are a statistical drop in the bucket of county-level labor markets, meaning aggregate QCEW data will never detect this shock.
- **Novelty Assessment**: Medium. Using judge IVs is standard practice, but applying it to local labor market aggregates is technically "new"—likely because researchers realize it mechanically will not work.
- **Top-Journal Potential**: Low. As the appendix notes, the outcome must be aligned with what the policy actually changes. A micro-shock (a few hundred asylum grants in a county) cannot plausibly drive macro-outcomes (county-wide wages) in a detectable way. The signal-to-noise ratio would be near zero.
- **Identification Concerns**: While the instrument is strong at the *individual* level, aggregating it to instrument for a *county's* immigrant share will result in a severely weak instrument. Furthermore, asylum seekers are highly mobile; they do not necessarily stay in the county where their court is located, violating the exclusion restriction for localized economic effects.
- **Recommendation**: SKIP

### Summary

This batch contains one outstanding proposal and two fundamentally flawed ones. **Idea 3 (SALT Cap Reversal)** is a top-tier idea that should be pursued immediately; it perfectly aligns with editorial preferences by using a sharp, first-order policy shock to test a broader theoretical concept (symmetric capitalization). Ideas 1 and 2 should be discarded—Idea 1 is an unexciting replication of an existing mechanism using overly aggregated data, and Idea 2 suffers from a fatal ecological mismatch between a micro-instrument and macro-outcomes.

---

## GPT-5.4 (B)

**Tokens:** 8433

### Rankings

**#1: Less Cash, Less Crime? The Nationwide Effect of Electronic Benefit Transfer on Property Crime**
- **Score:** 73/100
- **Strengths:** This has a sharp and policy-legible mechanism: replacing a tradable paper benefit with a PIN-protected card plausibly removes a black-market currency and should map most directly into burglary/larceny/robbery. The national staggered rollout gives real external validity beyond the existing Missouri evidence.
- **Concerns:** The main risk is that adoption timing is not as exogenous as it sounds: EBT rollout may proxy for broader welfare modernization, anti-fraud efforts, or state administrative quality that also correlate with crime declines in the late 1990s. State-level annual UCR data are also fairly coarse, and with only 51 units, the design is credible only if the pre-trends and mechanism tests are exceptionally clean.
- **Novelty Assessment:** Moderately novel. There is related work on EBT, benefit timing, and crime, and at least one well-known paper on Missouri counties, so this is not a blank-slate topic. But a convincing nationwide staggered-adoption design with modern DiD methods and strong mechanism tests would still add meaningful new evidence.
- **Top-Journal Potential:** **Medium-High.** The best version is not “EBT reduced crime” but “payment technology can destroy an illicit exchange medium, with downstream crime effects.” That is a compelling A→B→C story and could land in a top field journal; top-5 would require especially persuasive mechanism evidence and a result large enough to change how economists think about benefit delivery design.
- **Identification Concerns:** CS-DiD fixes estimator problems, not identification problems. You need to show adoption was not preceded by differential crime trends or bundled with other welfare/crime reforms, and I would want crime-category placebos plus SNAP-intensity heterogeneity as core, not auxiliary, evidence.
- **Recommendation:** **PURSUE (conditional on: strong event-study diagnostics; explicit tests for correlation between adoption timing and pre-existing crime/welfare trends; mechanism-focused outcomes rather than only total property crime)**

**#2: The Economic Integration Lottery: How Immigration Judge Leniency Shapes Local Labor Markets**
- **Score:** 65/100
- **Strengths:** The substantive question is first-order and important: isolating the effect of legal status from the effect of immigration itself is a very attractive contribution. The judge-leniency variation is genuinely powerful at the case level, and the policy relevance is obvious.
- **Concerns:** As proposed, the design moves too far away from the randomization. Judge assignment is random within court, but the outcomes are county labor markets; asylum seekers move, courts do not map cleanly to local labor markets, and aggregate effects may be too diluted to detect or interpret. This could end up as a technically sophisticated but unconvincing reduced-form exercise.
- **Novelty Assessment:** Quite novel in combination, but not methodologically novel. There is already a substantial immigration-judge leniency literature and a large immigration/local labor market literature; the fresh part is using judge quasi-randomness to isolate legal status and trace local economic spillovers.
- **Top-Journal Potential:** **Medium.** In principle this is the highest-upside idea in the batch because immigration/legal status/labor markets is a top-tier question. In practice, top journals will be skeptical unless the outcomes are brought much closer to the treated population or the paper can convincingly show a sizable local equilibrium effect.
- **Identification Concerns:** The exclusion restriction is not the main problem; alignment is. Random case assignment identifies effects on applicants, but not cleanly on county labor markets if residence, employment, and court location diverge. I would also worry that changes in filing composition and migrant settlement patterns contaminate court- or county-level grant-rate measures.
- **Recommendation:** **CONSIDER**  
  *(I would upgrade this substantially if the team can get outcomes on the applicants themselves—earnings, employment, benefit use, firm attachment, or mobility—rather than county-level labor market aggregates.)*

**#3: The Symmetric Tax Shock: Housing Capitalization of the SALT Deduction Cap and Its Reversal**
- **Score:** 57/100
- **Strengths:** The “same places treated twice” framing is clever, and the reversibility question is genuinely interesting for public finance and housing capitalization. The data are rich, high-frequency, and geographically detailed.
- **Concerns:** This literature is already crowded, and the 2025 reversal is probably too recent to support a persuasive paper yet. Exposure to the SALT cap is deeply entangled with high-income, supply-constrained, rate-sensitive housing markets, so differential trends are a major threat even with metro-by-year fixed effects.
- **Novelty Assessment:** Moderately novel but in a crowded area. Many papers have already studied the 2018 SALT cap and related capitalization questions; the main new element is the 2025 reversal and the symmetry test, not the underlying policy domain.
- **Top-Journal Potential:** **Low-Medium.** As written, this risks reading like another competent capitalization paper. To break through, it would need a striking asymmetry result—e.g., incomplete reversal due to salience, liquidity constraints, expectations, or political uncertainty—not just another price elasticity estimate.
- **Identification Concerns:** Pre-2017 SALT exposure is not quasi-random; it is a proxy for a bundle of neighborhood attributes that evolved very differently through the pandemic, interest-rate cycle, and remote-work shock. The reversal is also likely anticipated and bundled with other federal tax changes, which muddies a clean before/after interpretation.
- **Recommendation:** **SKIP**  
  *(Or revisit later, once there are 2–3 years of post-reversal data and a sharper mechanism beyond “did prices move back?”)*

### Summary

This is a decent batch with one clear lead, one high-upside but currently misspecified idea, and one clever but premature project. I would pursue **Idea 1** first, and I would only invest seriously in **Idea 2** if the team can shift from county labor markets to applicant-level or employer-linked outcomes; **Idea 3** is the easiest to execute but the least likely to feel new or persuasive right now.

