# Research Idea Ranking

**Generated:** 2026-03-05T02:39:26.322126
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Pills and Diplomas — PDMP Mandates and C... | PURSUE (72) | — | PURSUE (78) |
| Endowment Shocks and Institutional Resil... | PURSUE (66) | — | SKIP (52) |
| High on Enrollment — Recreational Cannab... | CONSIDER (58) | — | CONSIDER (58) |
| Narcan on Campus — Naloxone Access Laws ... | CONSIDER (52) | — | PURSUE (72) |
| ACA Dependent Coverage and the 26th Birt... | SKIP (44) | — | CONSIDER (65) |
| Idea 1: Pills and Diplomas — PDMP Mandat... | — | PURSUE (82) | — |
| Idea 5: Endowment Shocks and Institution... | — | CONSIDER (65) | — |
| Idea 2: High on Enrollment — Recreationa... | — | SKIP (52) | — |
| Idea 3: Narcan on Campus — Naloxone Acce... | — | SKIP (40) | — |
| Idea 4: ACA Dependent Coverage and the 2... | — | SKIP (25) | — |

---

## GPT-5.2

**Tokens:** 7272

### Rankings

**#1: Pills and Diplomas — PDMP Mandates and College Completion**
- **Score:** 72/100  
- **Strengths:** Very high novelty: linking opioid supply-side regulation to higher-ed persistence/completion is genuinely new, and IPEDS gives near-universe coverage with a long panel. There’s an inherently “belief-changing” potential if you can document the substitution channel (prescription opioids ↓, fentanyl deaths ↑) and show corresponding educational impacts.  
- **Concerns:** Mandatory PDMP adoption is not plausibly random—states enacted amid worsening opioid conditions and bundles of contemporaneous policies (pill mill laws, naloxone, Medicaid expansion, marijuana, policing), so state-level confounding and differential trends are first-order threats. Institution outcomes may move for many unrelated reasons (state budgets, tuition policy), making “diffuse” mechanisms a risk unless you tightly map the causal chain.  
- **Novelty Assessment:** **High.** PDMP → prescribing/mortality/labor is well-trodden, but PDMP → college retention/completion is (to my knowledge) close to unstudied.  
- **Top-Journal Potential:** **Medium.** A top field journal (AEJ:EP) is plausible if you (i) show a strong first stage on opioid environment by age (15–24), (ii) isolate substitution to illicit opioids, and (iii) deliver a clear welfare-relevant margin (human capital loss) rather than a broad “IPEDS outcomes” sweep. Top-5 potential is there only if the substitution story is nailed and the design survives aggressive diagnostics.  
- **Identification Concerns:** Staggered DiD with state policies risks violations of parallel trends driven by pre-existing opioid trajectories and policy bundling; “never-treated” states may be systematically different. You’ll need an explicit policy-bundle strategy (controls, exclusions, or an interaction/DDD design) plus event-study pre-trend tests, and ideally a border-pair or within-region design as an internal replication.  
- **Recommendation:** **PURSUE (conditional on: explicit controls/strategy for contemporaneous opioid policies and state trends; a documented first stage on opioid outcomes; a pre-registered placebo/heterogeneity battery—e.g., older/graduate-heavy institutions, non-opioid mortality, and border comparisons).**

---

**#2: Endowment Shocks and Institutional Resilience — The 2008 Crash in University Finance**
- **Score:** 66/100  
- **Strengths:** Identification is comparatively strong: the aggregate crash is plausibly exogenous, and cross-institution exposure (endowment reliance/asset mix) can generate credible differential shocks. The mechanism chain can be made tight (endowment shock → aid/tuition/spending → enrollment/retention/graduation), which editors like.  
- **Concerns:** Novelty is only moderate—there is substantial work on endowment performance and some on institutional responses; the risk is landing as “competent but incremental” unless you produce a sharp new fact (e.g., distributional incidence on low-income students, or sectoral differences with a welfare framing). Data work is nontrivial: endowment measures in IPEDS can be noisy/inconsistent across public/private, and Form 990 coverage is uneven.  
- **Novelty Assessment:** **Medium.** The “shock to endowments” is a familiar setting; linking to student outcomes is less saturated but not entirely untouched.  
- **Top-Journal Potential:** **Medium.** Stronger for a top field journal if you can show a clear incidence result (who bears the shock) and a policy-relevant counterfactual (e.g., stabilization rules or endowment spending mandates). Top-5 is harder unless you uncover a striking, generalizable mechanism about institutional insurance and inequality.  
- **Identification Concerns:** “Exposure” (endowment size, spending rules, asset allocation) is endogenous to institutional type and student body; you must argue why differential changes post-2008 are not just mean reversion or correlated shocks (state appropriations, local labor markets). A design that leverages pre-2008 portfolio share in equities interacted with market returns is more defensible than levels-based dose-response.  
- **Recommendation:** **PURSUE (conditional on: a clean shock/exposure measure—ideally portfolio-based; careful separation of public vs. private funding shocks; and a tight mechanism/incidence narrative rather than many outcomes).**

---

**#3: High on Enrollment — Recreational Cannabis and College Composition**
- **Score:** 58/100  
- **Strengths:** Solid feasibility and policy relevance, with enough treated states and clear timing (legalization vs. retail sales). Composition effects are more interesting than “total enrollment,” and IPEDS supports rich subgroup cuts.  
- **Concerns:** Novelty is limited: cannabis legalization is heavily studied across many outcomes, and education spillovers risk reading as an unsurprising extension unless you have a sharp mechanism (e.g., migration of students, labor-market substitution, or differential effects by 2-year vs. 4-year tied to work-school choices). Policy endogeneity and coincident changes (tax policy, policing, labor demand) are serious concerns, and cross-border spillovers can blur treatment/control.  
- **Novelty Assessment:** **Medium-Low.** “Cannabis legalization effects” is crowded; “college composition via IPEDS” is less common but still at risk of being seen as derivative.  
- **Top-Journal Potential:** **Low-Medium.** Likely an AEJ:EP/ILRR-level contribution if you find a distinctive composition shift with a tight channel and credible robustness to spillovers; top-5 is unlikely absent a genuinely counterintuitive mechanism or a new measurement contribution.  
- **Identification Concerns:** Staggered adoption with few early adopters and strong regional clustering; spillovers (students living near borders) violate SUTVA. You’ll need border-distance designs or explicit spillover modeling, plus separating legalization from commercialization intensity (tax revenue/dispensaries) in a way that avoids bad-control problems.  
- **Recommendation:** **CONSIDER (best if reframed around a sharp mechanism like cross-border enrollment shifts, or commercialization intensity with credible instrumentation).**

---

**#4: Narcan on Campus — Naloxone Access Laws and College Retention**
- **Score:** 52/100  
- **Strengths:** High policy relevance and an intuitive welfare story (“lives saved → degrees earned”), with many adopting states and good external outcome data on overdoses. If effects exist, they are morally and politically salient.  
- **Concerns:** The key causal link is likely too weak at the institution-year level: overdose mortality among enrolled students is rare relative to IPEDS denominators, so detectable effects on retention/graduation may be very small (high risk of underpowered/null-but-uninformative results). Laws are also bundled with Good Samaritan provisions, PDMP reforms, and broader opioid responses, making clean attribution difficult.  
- **Novelty Assessment:** **Medium.** Naloxone laws are widely studied for health outcomes; the education margin is novel but may not be empirically “bitey.”  
- **Top-Journal Potential:** **Low-Medium.** Would require unusually compelling first-stage evidence (large survival changes in the college-age population tightly tied to naloxone access) and a design that convincingly separates naloxone from the broader policy bundle; otherwise it risks being seen as speculative mechanism-chasing.  
- **Identification Concerns:** Strong policy bundling/endogeneity (states respond to surges), and the relevant treated population (students) is not directly observed—IPEDS is an indirect proxy. Without microdata linking overdose events to enrollment trajectories, interpretation will be fragile.  
- **Recommendation:** **CONSIDER (conditional on: demonstrating a large, precisely-timed first stage for 18–24 overdose fatality reductions; and adding a design that better targets student exposure—e.g., campus naloxone mandates/program rollouts if data can be assembled).**

---

**#5: ACA Dependent Coverage and the 26th Birthday Cliff in College Completion**
- **Score:** 44/100  
- **Strengths:** The conceptual identification idea (DDD using prior state mandates × age × post-2010) is elegant, and the policy is first-order important. If you could observe outcomes tightly around age 26, the “cliff” framing could be compelling.  
- **Concerns:** With IPEDS, the age measurement is the likely deal-breaker: institutional enrollment/retention data are typically in coarse age bins (often 25–29), which cannot credibly identify a 26th-birthday discontinuity and weakens the entire “cliff” narrative. Also, ACA dependent coverage has an enormous literature and many DDD implementations—so absent sharp new data, novelty/top-journal upside is limited.  
- **Novelty Assessment:** **Low-Medium.** The ACA dependent-coverage design is extremely well-studied; the education outcome is less studied, but the core shock is not novel.  
- **Top-Journal Potential:** **Low.** Without individual-level data (ACS/CPS/NSC/state longitudinal data) to isolate age 26 precisely and track completion, it will read as an indirect, noisy proxy exercise rather than a clean “cliff” paper.  
- **Identification Concerns:** The proposed age-based DDD is not implementable cleanly with coarse IPEDS bins; any estimates would hinge on strong functional-form/aggregation assumptions. Parallel trends may also differ systematically between mandate and non-mandate states around the Great Recession/ACA era.  
- **Recommendation:** **SKIP (unless you can switch to individual-level microdata with exact age and schooling outcomes—then the idea becomes much more viable).**

---

### Summary

This is a strong batch in terms of ambition and dataset feasibility (IPEDS + long panels), but several ideas hinge on state-policy DiD where bundling and differential trends are the central threat. The two best bets are **PDMP → college outcomes** (highest novelty with real “trade-off/substitution” upside) and **endowment crash exposure → student impacts** (cleaner shock with a tighter mechanism chain). If you start one immediately, start with **Idea 1**, but only with an explicit plan to neutralize policy bundling and to document a clear first-stage on the opioid environment.

---

## Gemini 3.1 Pro

**Tokens:** 8968

Here is my evaluation of the proposed research ideas, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in empirically observed editorial preferences and the mechanical realities of the proposed data.

### Rankings

**#1: Idea 1: Pills and Diplomas — PDMP Mandates and College Completion**
- **Score**: 82/100
- **Strengths**: This brilliantly links a major health/regulatory shock to human capital accumulation via a counter-intuitive substitution mechanism (PDMPs restricting pill access $\rightarrow$ substitution to illicit fentanyl $\rightarrow$ human capital destruction). The inclusion of graduate-student institutions as a built-in placebo is a highly credible design feature.
- **Concerns**: The aggregate effect size on institution-level retention rates might be small, requiring careful power calculations and potentially precision-weighted estimators. 
- **Novelty Assessment**: High. The PDMP literature is heavily saturated regarding prescribing behavior and mortality, but linking this to higher education outcomes is entirely unstudied and bridges two distinct literatures.
- **Top-Journal Potential**: High. This perfectly fits the winning editorial pattern of "uncovering a substitution/offset that changes the interpretation of a familiar policy lever." If you can prove the causal chain (PDMP $\rightarrow$ illicit market $\rightarrow$ dropout/failure), a Top-5 journal would find the unintended welfare consequences compelling.
- **Identification Concerns**: You must prove the first stage (that college-aged populations actually experienced the substitution effect) and carefully control for concurrent state-level macroeconomic trends or other opioid policies (like pill mill laws) enacted simultaneously.
- **Recommendation**: PURSUE (conditional on: verifying the minimum detectable effect size is mathematically possible to observe in aggregate IPEDS retention data).

**#2: Idea 5: Endowment Shocks and Institutional Resilience — The 2008 Crash**
- **Score**: 65/100
- **Strengths**: Uses a sharp, plausibly exogenous financial shock with continuous treatment (dose) to test institutional pass-through to students. It asks a fundamental question about whether wealthy institutions insure their students against macro shocks.
- **Concerns**: The 2008 crash was a general equilibrium shock; it devastated parents' ability to pay (housing wealth) and state appropriations simultaneously, making it very difficult to isolate the *endowment* channel.
- **Novelty Assessment**: Medium. The 2008 endowment shock has been studied in finance and labor (e.g., Brown et al. 2014 looking at faculty hiring), but extending this to student welfare and completion is a logical and valuable next step.
- **Top-Journal Potential**: Medium. This reads as a solid field journal paper (e.g., *AEJ: Economic Policy*). To hit a Top-5, it would need to overcome the "technically competent but not exciting" hurdle by revealing a surprising mechanism about university behavior (e.g., hoarding wealth at the expense of student outcomes).
- **Identification Concerns**: The exclusion restriction for the IV is highly suspect—universities with high pre-crisis endowment/expenditure ratios likely have different unobservable trends and student demographics that react differently to a global recession.
- **Recommendation**: CONSIDER

**#3: Idea 2: High on Enrollment — Recreational Cannabis and College Composition**
- **Score**: 52/100
- **Strengths**: Features a clean, staggered rollout with 24+ treated states and clear effective dates, providing plenty of variation for a modern CS-DiD design.
- **Concerns**: This reads like a "broad rollout $\rightarrow$ many outcomes" fishing expedition without a tight theoretical channel or clear welfare implication. 
- **Novelty Assessment**: Low. Cannabis legalization is one of the most over-studied topics of the last decade. While the specific angle of college composition is slightly new, it feels incremental rather than paradigm-shifting.
- **Top-Journal Potential**: Low. This fits the modal loss pattern perfectly: standard DiD + unsurprising/ambiguous outcomes + narrow focus. Furthermore, it lacks a "first-order stakes" welfare deliverable.
- **Identification Concerns**: A massive wave of cannabis legalization occurred between 2020-2023. Your post-treatment window will heavily overlap with the COVID-19 pandemic, which drastically altered college enrollment. As noted in the appendix, papers where results are confounded by COVID routinely lose.
- **Recommendation**: SKIP

**#4: Idea 3: Narcan on Campus — Naloxone Access Laws and College Retention**
- **Score**: 40/100
- **Strengths**: The proposed mechanism ("lives saved $\rightarrow$ degrees earned") is visceral, highly legible, and speaks directly to a first-order policy crisis.
- **Concerns**: Fatal data/power mismatch. Overdose deaths among college students, while tragic, are statistically rare. Saving 1-2 lives per year at a university of 30,000 students will not detectably move the aggregate retention rate (which IPEDS reports in whole percentages).
- **Novelty Assessment**: Medium. Naloxone is well-studied regarding moral hazard and mortality, but the education link is novel (albeit mechanically untestable with this data).
- **Top-Journal Potential**: Low. This will be rejected as an "underpowered null that cannot rule out plausible magnitudes." You simply cannot detect micro-level survival effects in macro-level institutional aggregates.
- **Identification Concerns**: Naloxone access laws were almost universally bundled with or passed adjacent to other major opioid interventions (PDMPs, Good Samaritan laws, Medicaid expansion). Disentangling these with aggregate data is nearly impossible.
- **Recommendation**: SKIP

**#5: Idea 4: ACA Dependent Coverage and the 26th Birthday Cliff**
- **Score**: 25/100
- **Strengths**: The proposed Triple-Difference (DDD) design leveraging prior state mandates is theoretically elegant and would cleanly isolate the federal policy effect.
- **Concerns**: Fatal data flaw. IPEDS does not provide single-year age bins for enrollment (it uses coarse bins like 22-24 and 25-29). It is literally impossible to observe the 26th birthday cliff in the proposed dataset.
- **Novelty Assessment**: Low. ACA dependent coverage is arguably the most saturated topic in modern applied microeconomics (100+ papers). 
- **Top-Journal Potential**: Low. Overstudied policy combined with a dataset that cannot actually execute the proposed research design.
- **Identification Concerns**: Even if you had the correct data, the 2010 ACA rollout coincides exactly with the peak of the Great Recession's impact on counter-cyclical college enrollment, severely confounding the time-series variation.
- **Recommendation**: SKIP

### Summary

Overall, this batch contains one outstanding idea, one viable but challenging idea, and three ideas with fatal flaws in either data mechanics or novelty. I strongly recommend pursuing **Idea 1 (PDMP Mandates)**, as it leverages a highly credible design to uncover a dark, unintended substitution effect of a major policy, which is exactly the type of "belief-changing" paper top journals look for. **Idea 5** is worth keeping as a backup, provided you can convincingly isolate the endowment shock from the broader 2008 macroeconomic collapse.

---

## Grok 4.1 Fast

**Tokens:** 6209

### Rankings

**#1: Pills and Diplomas — PDMP Mandates and College Completion**
- Score: 78/100
- Strengths: Exceptionally novel link between PDMPs and college outcomes with a compelling substitution hypothesis (prescriptions to fentanyl) that could reveal counterintuitive worsening effects, supported by clean staggered DiD, strong pre-trends testing, built-in placebos, and high power from 7,000+ institutions. Aligns with editorial preferences for trade-off discovery and a tight causal chain (policy → prescribing → overdoses → retention/graduation).
- Concerns: Reliance on state-level clustering might mask institution-specific heterogeneity; post-2015 fentanyl surge could confound interpretation without careful decomposition.
- Novelty Assessment: Highly novel—no known papers link PDMPs to higher education outcomes (PDMP lit sticks to health/labor; ed lit ignores opioid policies).
- Top-Journal Potential: High. Challenges conventional wisdom on PDMP efficacy via substitution offset (per editorial pattern on "trade-off discovery"); visceral mechanism (health crisis → diplomas) with welfare implications for youth policy, packageable as A→B→C chain with placebos as skeptic-killers.
- Identification Concerns: Staggered DiD solid with never-treated controls and 5+ pre-years, but state-year shocks (e.g., recessions) could violate parallel trends—testable via event studies; sufficient treated units but needs robustness to CS assumptions.
- Recommendation: PURSUE (conditional on: event-study pre-trends diagnostics; fentanyl decomposition using Joker data)

**#2: Narcan on Campus — Naloxone Access Laws and College Retention**
- Score: 72/100
- Strengths: Novel "lives saved → degrees earned" chain with visceral policy relevance, leveraging same strong IPEDS/CDC data as Idea 1 and 40+ staggered states for power. Complements PDMP lit by flipping supply-reduction to lethality-reduction, enabling internal replication.
- Concerns: High concurrence with PDMPs/other opioid laws risks omitted variables; short post-periods for early adopters and weaker mechanism testability (hard to directly observe "saved lives" at institution level).
- Novelty Assessment: Very novel—naloxone studies focus on overdoses/moral hazard, none on educational attainment.
- Top-Journal Potential: High. Fits "first-order stakes + legible causal channel" (naloxone → survival → graduation) with clear welfare pivot; multi-policy context allows opponent-killer placebos (e.g., non-youth institutions), though less belief-changing than substitution twists.
- Identification Concerns: Staggered CS-DiD vulnerable to policy bundling (PDMPs often co-adopted)—needs triple-difference or controls for concurrent laws; parallel trends testable but never-treated states fewer than in Idea 1.
- Recommendation: PURSUE (conditional on: specification robustness to concurrent opioid policies; youth-specific CDC integration)

**#3: ACA Dependent Coverage and the 26th Birthday Cliff in College Completion**
- Score: 65/100
- Strengths: Clever DDD exploits prior state mandates for national policy shock, linking insurance cliff to dropout with downstream earnings via College Scorecard—strong causal chain and long IPEDS panel.
- Concerns: IPEDS age bins too coarse for sharp 26th-birthday discontinuity; ACA saturation means small marginal effects and competition from existing papers.
- Novelty Assessment: Moderately novel—ACA dependent coverage heavily studied (health/labor), but college completion angle unexplored.
- Top-Journal Potential: Medium. Good "cliff" framing as boundary test, but ACA too saturated for top-5 excitement (per patterns on familiar policies); competent DDD but lacks counterintuitive pivot or scale to change field views.
- Identification Concerns: DDD cleaner than DiD but assumes parallel trends across state mandate status and age groups—pre-2010 tests critical; low power for narrow age cliff if bins are 5-year aggregates.
- Recommendation: CONSIDER

**#4: High on Enrollment — Recreational Cannabis and College Composition**
- Score: 58/100
- Strengths: Composition angle (demographics, part-time shifts) adds nuance to enrollment effects using accessible IPEDS; tax revenue as intensity measure strengthens dose response.
- Concerns: Tangential working papers exist (Anderson et al.); manual tax data collection burdensome and state-level only.
- Novelty Assessment: Somewhat novel—cannabis-high school ed studied, college understudied but WPs touch it; no exact composition matches.
- Top-Journal Potential: Low. Standard DiD on unsurprising margin (enrollment) without tight mechanism or belief-changer; reads as "competent but diffuse" per editorial losses on broad outcomes without welfare pivot.
- Identification Concerns: Staggered CS-DiD fine but fewer treated states (24) than opioids; retail dates cleaner than legalization but anticipation effects untestable without longer pre-periods.
- Recommendation: CONSIDER

**#5: Endowment Shocks and Institutional Resilience — The 2008 Crash in University Finance**
- Score: 52/100
- Strengths: Cross-sectional variation in shock exposure with IPEDS finance data; COVID replication adds internal validity.
- Concerns: Not a policy shock (exogenous but not actionable); prior studies (Brown et al. 2014) on endowments require clear student-outcome differentiation; Form 990 API untested.
- Novelty Assessment: Low—endowment shocks and university finance studied (JFE, others); student links incremental at best.
- Top-Journal Potential: Low. Niche finance shock without policy stakes or counterintuitive channel; "technically competent but not exciting" modal loss, lacking first-order welfare or substitution discovery.
- Identification Concerns: IV (pre-ratio × market) risks weak instruments/endogeneity (asset allocation not exogenous); continuous DiD better but pre-trends hard with short panel around crisis.
- Recommendation: SKIP

### Summary
This is a strong batch overall, with Ideas 1-2 standing out for high novelty, clean identification, and top-journal excitement via opioid policy trade-offs and causal chains that fit editorial patterns on substitutions and welfare pivots. Pursue Idea 1 first for its belief-changing fentanyl twist and robustness features; Idea 3 as a natural complement if policy concurrence is addressed. Ideas 4-5 are competent but too saturated or non-policy to prioritize.

