# Research Idea Ranking

**Generated:** 2026-03-10T13:36:06.219330
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Follow the Money or Follow the Crime? Po... | PURSUE (74) | PURSUE (85) | PURSUE (72) |
| Can Shorter Workweeks Save Fertility? So... | CONSIDER (64) | CONSIDER (62) | CONSIDER (66) |
| Does Legal Sports Betting Cannibalize St... | CONSIDER (58) | SKIP (52) | SKIP (58) |

---

## GPT-5.4 (A)

**Tokens:** 9454

### Rankings

**#1: Follow the Money or Follow the Crime? Police Resource Reallocation After Civil Asset Forfeiture Reform**
- **Score:** 74/100
- **Strengths:** This has a sharp and policy-relevant mechanism: if forfeiture really distorts police incentives, reform should shift enforcement away from revenue-generating drug activity and toward other crime categories. The multi-state rollback angle is meaningfully more novel than the existing “forfeiture expansion increased drug arrests” literature.
- **Concerns:** The usable sample is narrower than it first appears because clean UCR arrest data effectively end around the NIBRS transition; many reforms after 2020 will be hard to study. Arrests are also an indirect proxy for police effort and can be confounded by contemporaneous marijuana reforms, reporting changes, and broader criminal-justice shifts.
- **Novelty Assessment:** **Moderately high.** There is prior work on forfeiture incentives and at least one paper on the expansion era, but the reverse question—whether rolling back forfeiture causes measurable police reallocation across crime types at scale—looks substantially under-studied.
- **Top-Journal Potential:** **Medium.** If the paper can show a full causal chain—reform reduces drug-enforcement incentives, which reallocates policing toward more socially valuable enforcement/clearance—it could be a strong AEJ:EP or better paper. If it only shows “drug arrests fell,” it will read as a narrower policing ATE.
- **Identification Concerns:** Reform states may already have been on different trends in drug enforcement, especially given overlapping marijuana liberalization and prosecutorial reform. The treatment is also porous unless the paper explicitly handles federal equitable-sharing loopholes and heterogeneous reform intensity.
- **Recommendation:** **PURSUE** *(conditional on: restricting the core analysis to clean pre-NIBRS years; demonstrating stable reporting and pre-trends; and making substitution toward serious-crime enforcement/clearances central rather than relying only on drug-arrest effects).*

**#2: Can Shorter Workweeks Save Fertility? South Korea's 52-Hour Reform and the Marriage-Birth Response**
- **Score:** 64/100
- **Strengths:** This is the most conceptually novel question in the batch and addresses a first-order global policy problem: whether labor-market regulation can move family formation in an ultra-low-fertility setting. The firm-size rollout gives real structure for a quasi-experimental design, and marriage is a sensible near-term margin.
- **Concerns:** COVID severely damages waves 2 and 3, so the design may collapse onto one short pre/post window around the 2018 large-firm rollout. Province-level marriage/birth outcomes are only loosely tied to the treated workers, while KLIPS may be underpowered for fertility and subgroup event studies.
- **Novelty Assessment:** **High.** The fertility literature is crowded, but this exact channel—statutory work-hour reduction affecting marriage and fertility in Korea—appears much less studied than the other proposals.
- **Top-Journal Potential:** **Medium.** A clean result here would matter because governments are pouring money into pronatal policy with limited success, and a labor-supply lever is genuinely interesting. But top journals will want a very clear first stage on hours and a much tighter design than is currently described.
- **Identification Concerns:** Large and medium firms likely differ in underlying marriage and fertility trends, making untreated-firm-size comparisons nontrivial. Births are also a slow-moving outcome with a short clean observation window, so the main outcome probably needs to be marriage or conception timing rather than completed births.
- **Recommendation:** **CONSIDER** *(conditional on: centering the paper on wave 1; establishing a strong hours first stage; and treating births as secondary unless better individual-level or administrative data can be obtained).*

**#3: Does Legal Sports Betting Cannibalize State Lottery Revenue? Staggered Legalization and Fiscal Substitution**
- **Score:** 58/100
- **Strengths:** This is highly policy-relevant and very feasible: the treatment is widespread, the outcome is economically legible, and the data are mostly public. The online-versus-retail margin offers a useful way to move beyond a simple treated/untreated comparison.
- **Concerns:** As currently framed, this looks like a competent but not especially exciting substitution paper. With annual state-level revenue data, it will be hard to separate cannibalization from broader gambling-market expansion, advertising booms, pandemic shocks, and simultaneous gaming-policy changes.
- **Novelty Assessment:** **Moderate to low.** The general question of substitution across gambling products is already well studied, and the post-PASPA version has enough state-specific and working-paper evidence that a national panel alone is not a big conceptual advance.
- **Top-Journal Potential:** **Low.** A top field journal might care if the paper uncovers a surprisingly large fiscal offset or strong heterogeneity by online access, but in its current form it lacks the sharp mechanism or puzzle resolution that usually elevates these papers. This is much more “useful policy evaluation” than “field-changing result.”
- **Identification Concerns:** States legalize sports betting for endogenous political and fiscal reasons, and the post-2018 period is full of concurrent shocks that threaten parallel trends. Coarse annual data also make dynamic adjustment and short-run substitution hard to identify cleanly.
- **Recommendation:** **CONSIDER** *(conditional on: obtaining higher-frequency or product-level lottery data; exploiting online rollout more sharply; and linking the revenue effects directly to education-funding consequences).*

### Summary

This is a solid batch, but only **Idea 1** clearly crosses the threshold for immediate pursuit. **Idea 3** is more novel than **Idea 2** and could become important with a tighter pre-COVID design, while **Idea 2** is the easiest to execute but currently looks more like a good institute report than a top-tier academic contribution.

---

## Gemini 3.1 Pro

**Tokens:** 6757

Here is my evaluation and ranking of the research proposals, applying the criteria and editorial patterns provided.

### Rankings

**#1: Follow the Money or Follow the Crime? Police Resource Reallocation After Civil Asset Forfeiture Reform**
- **Score**: 85/100
- **Strengths**: Tests a clear, first-order economic mechanism (financial incentives driving state coercion) using a comprehensive multi-state panel. The "revealed preference" angle on police behavior provides a complete, compelling causal narrative.
- **Concerns**: UCR data quality can be notoriously noisy at the agency level, and state-level reforms might be endogenous to local crime trends or political shifts.
- **Novelty Assessment**: Very high. While the *expansion* of forfeiture has been studied (e.g., Kantor et al.), the staggered rollback is a largely untapped natural experiment for testing police resource reallocation. 
- **Top-Journal Potential**: High. This fits the "first-order stakes + one sharp channel" archetype perfectly. It challenges assumptions about policing by showing how financial incentives distort justice, which appeals heavily to top general-interest journals.
- **Identification Concerns**: The primary threat is the endogenous timing of state reforms (e.g., did states reform because drug crime was already falling?). You will need to rigorously test pre-trends and likely control for state-level political or budgetary covariates.
- **Recommendation**: PURSUE

**#2: Can Shorter Workweeks Save Fertility? South Korea's 52-Hour Reform and the Marriage-Birth Response**
- **Score**: 62/100
- **Strengths**: Addresses a massive global policy question (fertility collapse) with a specific, high-stakes policy lever (work hours). The multi-cutoff firm-size design theoretically provides excellent built-in placebos.
- **Concerns**: The COVID-19 pandemic completely destroys the identification strategy for waves 2 and 3, and leaves an impossibly short window for wave 1 births.
- **Novelty Assessment**: High. The link between this specific reform and fertility is understudied, and East Asian fertility policy is highly relevant but underrepresented in top Western journals.
- **Top-Journal Potential**: Medium. A clean design showing work hours increase fertility would be a top-5 paper, but the fatal COVID confound downgrades this. Top journals demand pristine identification, and the timing here is empirically cursed.
- **Identification Concerns**: Fatal confounding from COVID-19 starting in Jan 2020. Since births require a 9-month lag, Wave 1 (July 2018) only yields observable treated births from April 2019 to Jan 2020—just 9 months of data before the pandemic shock ruins the control group comparisons.
- **Recommendation**: CONSIDER (conditional on: pivoting the outcome to immediate marriage rates or individual-level time-use/dating behavior, abandoning births as the primary outcome due to the COVID confound).

**#3: Does Legal Sports Betting Cannibalize State Lottery Revenue? Staggered Legalization and Fiscal Substitution**
- **Score**: 52/100
- **Strengths**: Highly feasible data collection and a straightforward, textbook staggered DiD design.
- **Concerns**: Reads as a standard, uninspired substitution exercise. It is technically competent but not exciting.
- **Novelty Assessment**: Low. The sports betting space is rapidly becoming saturated with working papers, and lottery substitution is a standard, somewhat tired angle in gambling economics.
- **Top-Journal Potential**: Low. This is a classic "another average treatment effect" paper. It lacks a deeper mechanism, a surprising puzzle, or a counter-intuitive finding. It would likely land in a solid field journal (e.g., National Tax Journal) but not a top-5 or top-tier general interest journal.
- **Identification Concerns**: Relatively clean, though states legalizing sports betting might be simultaneously changing other fiscal or gaming policies, and lottery revenues are inherently noisy.
- **Recommendation**: SKIP

### Summary

This batch presents a clear winner, a flawed but interesting runner-up, and a mundane third option. Idea 1 is the standout, offering a compelling mechanism and high top-journal potential by examining how financial incentives distort law enforcement. I strongly recommend pursuing Idea 1 immediately, while Idea 3 could only be salvaged by pivoting away from fertility to faster-moving outcomes that avoid the COVID-19 confound. Idea 2 should be discarded as it lacks the narrative ambition required for top-tier publication.

---

## GPT-5.4 (B)

**Tokens:** 8595

### Rankings

**#1: Follow the Money or Follow the Crime? Police Resource Reallocation After Civil Asset Forfeiture Reform**
- **Score: 72/100**
- **Strengths:** This is the strongest mix of novelty and plausible identification in the batch. The core question—whether removing forfeiture revenue incentives changes police behavior—is important, under-studied, and can be framed as a clean mechanism paper on bureaucratic incentives.
- **Concerns:** The biggest practical issue is that the clean UCR arrest series effectively ends around 2020, which truncates exposure to later reforms and creates measurement problems during the NIBRS transition. Reform timing may also be bundled with broader criminal justice or drug-policy changes, so simple staggered DiD could over-attribute shifts in drug arrests to forfeiture reform.
- **Novelty Assessment:** Fairly novel. There is some existing work on forfeiture expansion and policing, but the reverse-margin, multi-state reform/reallocation question still looks lightly studied.
- **Top-Journal Potential: Medium.** This could be a strong AEJ: Economic Policy / JPubE-type paper, and it has some top-5 upside if the paper shows a compelling chain like forfeiture incentives → drug-enforcement intensity → reallocation toward socially valuable policing. If it stops at arrest shares, it risks feeling narrower than the best policing papers.
- **Identification Concerns:** Heterogeneous treatment intensity is tricky, and state reform timing is not obviously exogenous. I would want the paper centered on the sharpest margins (abolition/conviction requirement/equitable-sharing closure), strong event studies, and explicit controls for marijuana legalization and other contemporaneous policing reforms.
- **Recommendation:** **PURSUE (conditional on: focusing on reforms observable cleanly in the pre-NIBRS era or building compatible post-2020 measures; emphasizing welfare-relevant outcomes like violent/property crime clearances, not just arrests; using pre-reform forfeiture dependence or equitable-sharing exposure as a mechanism/intensity test)**

---

**#2: Can Shorter Workweeks Save Fertility? South Korea's 52-Hour Reform and the Marriage-Birth Response**
- **Score: 66/100**
- **Strengths:** This is the highest-upside question conceptually: extremely important policy stakes, very strong novelty, and a policy that directly maps into a plausible mechanism for marriage and fertility. If done well, it could speak to one of the biggest policy failures in advanced economies.
- **Concerns:** The proposed design is substantially weaker than the question. COVID contaminates waves 2 and 3, leaving a short clean window, and births are a hard outcome to identify credibly in that horizon; province-level exposure designs also feel too coarse for such a behavioral outcome.
- **Novelty Assessment:** Very novel. I am not aware of a well-identified causal paper on this reform’s marriage/fertility effects.
- **Top-Journal Potential: Medium.** The topic is top-journal worthy in principle, because fertility is a first-order policy issue and the mechanism is intuitive. But top outlets will demand much cleaner evidence than a broad regional DiD with COVID in the background.
- **Identification Concerns:** Firm size is not random, so treated and later-treated workers may have different trends even absent reform. To be credible, this needs a wave-1-centric design, ideally with stronger microdata on actual hours changes and possibly a threshold-based strategy around the 300-worker cutoff.
- **Recommendation:** **CONSIDER**

---

**#3: Does Legal Sports Betting Cannibalize State Lottery Revenue? Staggered Legalization and Fiscal Substitution**
- **Score: 58/100**
- **Strengths:** Feasible, policy-relevant, and well matched to available state-level data. The outcome is economically legible, and the online-vs-retail distinction gives a sensible treatment-intensity margin.
- **Concerns:** This feels like the classic “competent but not exciting” paper. Even with clean execution, the main contribution is likely a substitution elasticity in gambling products, which is useful but unlikely to change how the field thinks about public finance or household behavior.
- **Novelty Assessment:** Moderately novel for sports betting specifically, but the broader cannibalization/substitution question in gambling markets has already been studied a fair amount.
- **Top-Journal Potential: Low.** This is more likely a solid field-journal or policy-institute paper than a top-5 contender. To travel farther, it would need to show unexpectedly large fiscal or welfare consequences, not just modest lottery substitution.
- **Identification Concerns:** State adoption is endogenous to politics, fiscal needs, and preexisting gambling ecosystems. Concurrent changes in iGaming, casinos, lottery product design, and COVID-era betting behavior make attribution difficult even with staggered DiD.
- **Recommendation:** **SKIP**

### Summary

This is a decent batch, but only one idea looks ready to push hard right now. **The forfeiture-reform project is the best combination of novelty, tractability, and publishability**, while the **Korea workweek/fertility idea is high-upside but currently underpowered and identification-fragile**. The sports-betting idea is feasible and policy-relevant, but it reads more like a useful institute report than a standout academic paper.

