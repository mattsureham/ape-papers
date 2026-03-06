# Research Idea Ranking

**Generated:** 2026-03-06T11:47:00.592384
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Generative AI as Seniority-Biased Techno... | PURSUE (70) | — | PURSUE (70) |
| Did AI-Exposed Industries Hollow Out Ent... | CONSIDER (56) | — | CONSIDER (55) |
| Earnings Call Signals and Junior Employm... | SKIP (43) | — | SKIP (44) |
| Idea 2: Did AI-Exposed Industries Hollow... | — | CONSIDER (52) | — |
| Idea 1: Generative AI as Seniority-Biase... | — | SKIP (42) | — |
| Idea 3: Earnings Call Signals and Junior... | — | SKIP (32) | — |

---

## GPT-5.4 (A)

**Tokens:** 7819

### Rankings

**#1: Generative AI as Seniority-Biased Technological Change: Evidence from SEC Filings and Occupational Employment Data**
- **Score:** 70/100
- **Strengths:** This is the most interesting and best-aligned idea in the batch: the hypothesis is clear, the treatment is observable at scale, and the outcome directly matches the claim about entry-level versus senior jobs. The all-public data stack is a real advantage, and the industry × occupation structure gives room for a persuasive causal chain: GenAI diffusion → occupational composition shift → weaker entry-level ladders.
- **Concerns:** The core treatment is still endogenous: firms disclose AI adoption when they expect investors to care, which may coincide with broader industry restructuring rather than cause it. Also, the post period is very short, and OEWS annual estimates are smoothed over multiple survey panels, which weakens timing-based inference right when timing is doing most of the work.
- **Novelty Assessment:** The broader “AI and labor demand” area is already crowded, and the specific seniority-bias hypothesis is no longer brand new. But this exact public-data test using SEC disclosure intensity plus government occupational employment data still feels meaningfully fresher than a standard exposure-based AI paper.
- **Top-Journal Potential:** **Medium.** A top field journal could be interested if the paper is framed around career-ladder erosion and backed by strong placebo tests and validation that 10-K mentions proxy real adoption. For a top-5, the short horizon and disclosure endogeneity probably make it difficult unless the mechanism evidence is unusually sharp.
- **Identification Concerns:** Industry-level GenAI mentions may proxy underlying demand shifts, offshoring, or restructuring that already favored senior workers. The triple-diff helps, but you would need strong pre-trend evidence, negative-control occupations, and some validation that disclosures move with actual GenAI implementation rather than hype.
- **Recommendation:** **PURSUE (conditional on: validating 10-K GenAI mentions against real adoption; explicitly addressing OEWS timing/smoothing; building strong opponent-killer placebos and negative controls)**

---

**#2: Did AI-Exposed Industries Hollow Out Entry-Level Jobs? Evidence from QCEW Payroll Records**
- **Score:** 56/100
- **Strengths:** QCEW is excellent data—large, high-frequency, and well suited to a clean event-study around late 2022. If the goal were simply to ask whether high-AI-exposure industries saw different post-ChatGPT employment or wage paths, this would be feasible and easy to execute.
- **Concerns:** The biggest problem is outcome mismatch: QCEW does not observe entry-level jobs, so the paper leans on CPS age/tenure proxies that are both noisy and conceptually imperfect. On top of that, using AIOE exposure rather than actual adoption makes this feel like a familiar “high-vs-low exposure” design in a literature that is already getting saturated.
- **Novelty Assessment:** Low to moderate. There are already many papers using occupation-based AI exposure measures to study labor market outcomes, and this version risks reading as another exposure DiD with a new dataset rather than a new idea.
- **Top-Journal Potential:** **Low-Medium.** This could become a competent AEJ: Policy / labor-field paper if the estimates are tight and the heterogeneity is clean. But as currently framed, it lacks the novelty and mechanism depth that top journals now expect from AI-labor papers.
- **Identification Concerns:** High-AIOE industries differ systematically from low-AIOE industries in digitization, remote work, cyclicality, and post-pandemic adjustment. The age-based CPS decomposition adds ecological measurement error and does not cleanly isolate “entry-level” work.
- **Recommendation:** **CONSIDER (conditional on: finding a direct measure of junior hiring or occupational composition rather than age proxies; showing robust pre-trends and falsification tests against other digital-exposure margins)**

---

**#3: Earnings Call Signals and Junior Employment: Do Firms That Talk About AI Hire Fewer Beginners?**
- **Score:** 43/100
- **Strengths:** There is some appeal in trying to use higher-frequency firm signals and geographic heterogeneity rather than annual industry averages. If done well, the paper could capture perceived adoption earlier than backward-looking annual filings.
- **Concerns:** This is the weakest design in the set: the key data are not securely in hand, the treatment is “talk” rather than adoption, and the shift-share layer adds another major assumption rather than solving the endogeneity problem. It is too complicated relative to the likely credibility of the resulting causal claim.
- **Novelty Assessment:** Moderate at best. The exact combination of earnings-call AI mentions, local exposure, and junior employment is not standard—but mostly because it is hard to make convincing, not because it is an obvious unstudied opportunity.
- **Top-Journal Potential:** **Low.** Reviewers will likely see this as an endogenous speech measure embedded in a fragile Bartik design with diffuse outcomes. Unless the paper is reframed as a measurement exercise rather than a causal one, it is unlikely to clear the bar.
- **Identification Concerns:** Firms talk more about AI when they face changing demand, investor pressure, or expected productivity gains, so “AI mentions” are deeply endogenous. The local occupation-share shift-share design also inherits standard Bartik concerns, especially when local occupational mix is correlated with underlying MSA trends.
- **Recommendation:** **SKIP**

### Summary

This is a decent batch, but all three ideas face the same fundamental challenge: GenAI adoption is diffuse, endogenous, and observed over a very short post period. **Idea 1** is the clear first choice because it has the best combination of novelty, outcome alignment, and feasible public data; **Idea 2** is serviceable but likely incremental; **Idea 3** is too fragile on both data and identification to prioritize.

---

## Gemini 3.1 Pro

**Tokens:** 8174

Here is my evaluation of the research proposals. As requested, I have applied a highly critical lens, grounding my assessments in the empirical realities of top-journal editorial preferences and the mechanical realities of the proposed datasets. 

### Rankings

**#1: Idea 2: Did AI-Exposed Industries Hollow Out Entry-Level Jobs? Evidence from QCEW Payroll Records**
- **Score**: 52/100
- **Strengths**: Using the QCEW provides a true high-frequency, universe-level administrative payroll count, which allows for a precise event study around the November 2022 shock. Moving away from job postings/résumés to actual payrolls is the correct instinct for measuring real economic impacts.
- **Concerns**: The CPS sample sizes within industry-by-age cells will be extremely thin and noisy for quarterly triple-diff estimates. More importantly, the treatment is perfectly confounded by concurrent macroeconomic shocks.
- **Novelty Assessment**: Very Low. Interacting occupational AI exposure scores (Felten/Eloundou) with CPS or QCEW data pre/post-ChatGPT is currently the most saturated, over-crowded trade in labor economics. 
- **Top-Journal Potential**: Low. As noted in the editorial patterns, "another ATE" with standard exposure scores reads as "competent but not exciting." It lacks a surprising mechanism, and top-5 reviewers will immediately flag the macro confounder.
- **Identification Concerns**: High-AIOE industries (tech, finance, professional services) were disproportionately hit by the 2022-2023 interest rate hikes and the subsequent "white-collar recession." This concurrent shock will severely violate parallel trends when compared to low-AIOE industries (hospitality, healthcare) that were booming during the same period. 
- **Recommendation**: SKIP (or CONSIDER conditional on: finding a credible placebo or separation strategy that isolates AI adoption from the 2022-2023 tech/interest-rate cycle).

**#2: Idea 1: Generative AI as Seniority-Biased Technological Change: Evidence from SEC Filings and Occupational Employment Data**
- **Score**: 42/100
- **Strengths**: Using 10-K filings attempts to provide a firm-driven measure of actual adoption rather than just theoretical exposure. Attempting to validate the seniority-bias hypothesis with public administrative data is a good scientific impulse.
- **Concerns**: The proposal demonstrates a fatal misunderstanding of the BLS OEWS data architecture. Furthermore, 10-K mentions of "AI" in 2023-2024 suffer from severe "AI-washing" (cheap talk to boost stock valuations), making it a highly noisy treatment variable.
- **Novelty Assessment**: Low/Medium. The specific hypothesis was just published (Hosseini Maasoum & Lichtinger), and while the data is different, the theoretical contribution is marginal.
- **Top-Journal Potential**: Low. The editorial patterns explicitly punish "bad measurement/proxy outcomes." Reviewers at top labor or general interest journals will instantly reject the paper based on the OEWS data mechanics alone.
- **Identification Concerns**: The BLS OEWS uses a 3-year rolling sample methodology (six semi-annual panels). This means the 2023 and 2024 "post-treatment" data mechanically include survey responses from 2021 and 2022. It is mathematically impossible to evaluate a sharp Q4 2022 event study using OEWS data, as the pre/post periods are completely blurred.
- **Recommendation**: SKIP

**#3: Idea 3: Earnings Call Signals and Junior Employment: Do Firms That Talk About AI Hire Fewer Beginners?**
- **Score**: 32/100
- **Strengths**: Looking at separations versus hiring freezes via the CPS displaced worker supplement is an excellent, policy-relevant mechanism test that goes beyond a simple net-employment ATE.
- **Concerns**: This proposal stacks multiple fatal flaws: it relies on the same rolling-average OEWS data as Idea 1, requires expensive proprietary data that fails the feasibility check, and proposes a highly questionable shift-share design.
- **Novelty Assessment**: Low. Shift-share designs using text-based tech adoption signals are standard (e.g., Acemoglu et al. on automation), and applying it to the already-crowded GenAI space does not move the needle.
- **Top-Journal Potential**: Low. It falls into the classic trap of using a convoluted empirical design to mask bad data. Top journals prefer simple, transparent designs with excellent data over complex instruments applied to noisy, endogenous text proxies.
- **Identification Concerns**: The shift-share design lacks exogenous shocks. Firm-level "AI talk" on earnings calls is highly endogenous to firm performance, management style, and macro-economic exposure, violating the exclusion restriction. 
- **Recommendation**: SKIP

### Summary

This batch of proposals is generally weak, suffering from a combination of a highly crowded literature ("AI exposure" papers are currently flooding journal submission queues) and severe data or identification flaws. None of these ideas are ready for prime time in their current state, primarily because they fail to separate the November 2022 AI shock from the concurrent 2022-2023 macroeconomic tightening cycle. If forced to salvage one, Idea 2 has the most reliable data infrastructure (QCEW), but it would require a major pivot in the identification strategy to be viable for a top journal.

---

## GPT-5.4 (B)

**Tokens:** 8384

### Rankings

**#1: Generative AI as Seniority-Biased Technological Change: Evidence from SEC Filings and Occupational Employment Data**
- **Score:** 70/100
- **Strengths:** This is the only proposal that is tightly aligned with a clear mechanism: GenAI diffusion → changes in occupational composition → relative decline in entry-level vs senior roles. The industry × occupation-seniority design is more compelling than a simple high-vs-low exposure comparison, and the specific “seniority-biased” angle is still relatively fresh.
- **Concerns:** The treatment is not cleanly exogenous: 10-K GenAI mentions may capture hype, investor-relations strategy, or broader white-collar restructuring rather than true adoption. Also, OEWS is a relatively slow-moving/constructed occupation dataset with only two post years, so the design may look sharper on paper than it is in practice.
- **Novelty Assessment:** **Moderately novel.** The broader AI-and-labor space is already crowded, but this exact question—whether GenAI is *seniority-biased* rather than just skill-biased, using public administrative/disclosure data—is not yet saturated.
- **Top-Journal Potential:** **Medium.** The topic is hot and the claim could matter if it convincingly shows GenAI is closing the bottom rung of career ladders. But with a short post period and an endogenous adoption proxy, this currently looks more like a strong **AEJ: Economic Policy / top field** paper than a top-5 paper.
- **Identification Concerns:** The main threat is that industries with more GenAI mentions are also the ones experiencing other 2023–24 shocks (tech correction, remote-work reorganization, cost cutting). The paper needs strong “opponent-killer” placebos and validation that filing mentions track real deployment, not just discourse.
- **Recommendation:** **PURSUE (conditional on: addressing OEWS rolling-sample limitations; validating 10-K mentions as actual adoption; adding strong within-industry placebo tests and sensitivity to public-firm coverage)**

**#2: Did AI-Exposed Industries Hollow Out Entry-Level Jobs? Evidence from QCEW Payroll Records**
- **Score:** 55/100
- **Strengths:** The data are excellent in scale and frequency, and the long quarterly pre-period is useful for event-study diagnostics. For an institute report, QCEW gives broad coverage and credible descriptive patterns quickly.
- **Concerns:** The outcome is poorly matched to the question: QCEW has no occupational or entry-level measure, and using young workers in CPS as a proxy for “entry-level” is conceptually weak and empirically noisy. The exposure design—precomputed AI exposure scores interacted with post-ChatGPT—is also now quite standard.
- **Novelty Assessment:** **Low to moderate.** The exact data combination may be somewhat new, but the underlying design and question have already been studied repeatedly with AI exposure scores, job postings, and worker-level data.
- **Top-Journal Potential:** **Low.** This risks reading as a competent but incremental exposure-DiD paper on a heavily trafficked topic, without a sharp mechanism or a newly measured object. That is exactly the kind of paper that often tops out below the very best outlets.
- **Identification Concerns:** High-AI-exposure industries were also the ones hit by contemporaneous shocks unrelated to GenAI adoption, especially post-pandemic normalization and the tech-sector pullback. Since all industries are “treated” at once and only exposure varies, the design is vulnerable to differential-trend stories.
- **Recommendation:** **CONSIDER** — useful as a secondary project, policy brief, or robustness exercise, but not the best flagship paper.

**#3: Earnings Call Signals and Junior Employment: Do Firms That Talk About AI Hire Fewer Beginners?**
- **Score:** 44/100
- **Strengths:** There is some real novelty here, and in principle the paper could connect firm-level AI salience to local labor-market outcomes in a way that is narratively attractive. If measured well, quarterly firm signals could be powerful.
- **Concerns:** As written, the proposal is overcomplicated and underpowered relative to its ambitions. The key data source (earnings call transcripts) is not fully available, the proposed substitutes are noisy, and the shift-share architecture adds another layer of identifying assumptions on top of already endogenous treatment.
- **Novelty Assessment:** **Moderately novel, but not uniquely so.** There is growing work on AI mentions in calls/filings and on local labor-market exposure designs; this combines them, but not in a way that currently solves the core credibility problem.
- **Top-Journal Potential:** **Low.** There is some upside if redesigned around much better firm-level hiring data, but in its current form it would likely strike referees as fragile and overly engineered. That combination usually does not survive top-journal review.
- **Identification Concerns:** “Talking about AI” is likely endogenous to business conditions, expected restructuring, or investor pressure. The shift-share component then inherits standard concerns about endogenous local shares, and the CPS supplement outcomes are too sparse/timed too poorly to cleanly separate separations from hiring freezes.
- **Recommendation:** **SKIP**

### Summary

This is a timely batch, but all three ideas share the same structural weakness: a very short post-2022 horizon and treatment measures that are not clearly exogenous. **Idea 1** is the best of the set because it has the clearest mechanism, the most interesting substantive claim, and the best chance of becoming more than “another AI exposure DiD.” **Idea 2** is serviceable as a report or supporting paper; **Idea 3** needs a major redesign and better data before it is worth pursuing.

