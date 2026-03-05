# Research Idea Ranking

**Generated:** 2026-03-05T14:28:42.323648
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| The CROWN Act and Black Worker Outcomes:... | PURSUE (74) | — | — |
| Breaking the Anchor: Salary History Bans... | CONSIDER (60) | — | — |
| State Domestic Violence Leave Laws and F... | CONSIDER (54) | — | — |
| Cleared to Work: State Cannabis Employme... | SKIP (47) | — | — |
| Idea 1: The CROWN Act and Black Worker O... | — | PURSUE (82) | — |
| Idea 3: Breaking the Anchor: Salary Hist... | — | CONSIDER (58) | SKIP (55) |
| Idea 2: Cleared to Work: State Cannabis ... | — | SKIP (45) | — |
| Idea 4: State Domestic Violence Leave La... | — | SKIP (35) | CONSIDER (62) |
| Idea 1: The CROWN Act and Black Worker O... | — | — | PURSUE (82) |
| Idea 2: Cleared to Work: State Cannabis ... | — | — | CONSIDER (68) |

---

## GPT-5.2

**Tokens:** 6443

### Rankings

**#1: The CROWN Act and Black Worker Outcomes: Does Banning Hair Discrimination Reduce Racial Employment Gaps?**
- **Score: 74/100**
- **Strengths:** Genuinely novel policy lever with clear distributional stakes, and enough staggered state adoption to run credible modern DiD with rich heterogeneity (customer-facing vs not; gender). ACS/CPS scale makes it plausible to detect even modest effects and to map mechanisms (occupation/industry reallocation).
- **Concerns:** The post period is short for many states and overlaps major race-related shocks (2020) and broader DEI/anti-discrimination activity, making “what changed exactly” hard to isolate; effects may be concentrated in a small set of jobs, so aggregate ITT could be small. Biggest risk is a “clean but small/unsurprising” reduced form unless you convincingly show a first stage (employer behavior/complaints/policies) and a tight channel.
- **Novelty Assessment:** Very high—this is not a saturated economics topic; likely close to first economics-style causal evaluation of CROWN Acts.
- **Top-Journal Potential: Medium.** Could be AEJ:EP/top field if you (i) document bite (reduced hair-related screening or increased entry into customer-facing/professional roles), (ii) show sharp heterogeneity consistent with the discrimination channel, and (iii) translate into a clear welfare/distributional object. Top-5 is possible but not the base case unless the effect is large and belief-changing about discrimination frictions.
- **Identification Concerns:** Staggered adoption is fine with CS estimators, but the main threat is **differential contemporaneous shocks by race** (COVID sectoral exposure, 2020 racial reckoning, state policy bundles) that a Black-vs-White triple-diff may not fully absorb if shocks affect races differently within state. You’ll want strong pre-trend diagnostics, event-study shape, and ideally an additional “opponent-killer” (e.g., border-county design or job-posting evidence on grooming-language changes).
- **Recommendation:** **PURSUE (conditional on: demonstrating first-stage/bite using complaints, job postings, or HR policy text; pre-registering a small number of primary outcomes; showing robustness to dropping 2020 and to border-county comparisons).**

---

**#2: Breaking the Anchor: Salary History Bans and Worker-Firm Matching Efficiency**
- **Score: 60/100**
- **Strengths:** Better-than-average policy variation (many adoptions, earlier timing) and a potentially interesting pivot away from the well-trodden “gender wage gap ATE” toward a mechanism with broader implications (search/matching and wage-setting). If you can credibly measure match quality (post-switch tenure, wage growth on switches), it can become more than incremental.
- **Concerns:** This policy has an existing economics literature; novelty hinges on convincing the reader that “matching efficiency” is a distinct, first-order contribution rather than a relabeling of wage effects. CPS linked panels are thin/noisy for tenure and for precisely measuring job-to-job moves; you may end up underpowered or with measurement-error attenuation.
- **Novelty Assessment:** Medium—salary history bans are studied, but your proposed estimands are less studied; still, referees may view it as incremental without new data/measurement.
- **Top-Journal Potential: Low-to-Medium.** Top journals will want either (i) a new dataset (e.g., job postings/HR surveys showing inquiries fell) plus a clear theoretical link to matching, or (ii) a striking substitution result (e.g., less anchoring but more wage compression or lower vacancy filling). With CPS-only outcomes it risks “competent DiD on a known policy.”
- **Identification Concerns:** Adoption is plausibly endogenous to progressive labor-market trends; DiD needs especially careful pre-trends and perhaps border discontinuities. Also, “placebo within-firm promotions” is helpful but not definitive (promotions can respond to outside options that shift post-ban).
- **Recommendation:** **CONSIDER (conditional on: adding a direct first-stage measure—job postings with “salary history” language, recruiter surveys, or enforcement/complaint data; and tightening the matching object to 1–2 high-credibility measures).**

---

**#3: State Domestic Violence Leave Laws and Female Labor Force Attachment**
- **Score: 54/100**
- **Strengths:** Under-studied policy area with large staggered variation over a long horizon (a big plus vs the recent-policy/pandemic problem). Clear policy relevance if you can say something credible about job retention, earnings stability, or public assistance reliance.
- **Concerns:** The treated population is unobserved in CPS/ACS, so you are estimating a heavily diluted ITT on all women; realistic effects could be too small to detect or to interpret (a null won’t be informative). Policies differ widely (paid vs unpaid, eligibility, firm-size thresholds), and they may be bundled with other leave expansions—making treatment definition and comparability hard.
- **Novelty Assessment:** High in economics (surprisingly thin), but “thin literature” here partly reflects intrinsic identification/data difficulties.
- **Top-Journal Potential: Low.** Without individual-level victim identification or a sharp first-stage, this is likely to read as “important but diffuse.” A top field journal might bite only if you can pair the laws with administrative DV-service/provider data, court filings, or employer leave-takeup to show clear bite and then connect to labor outcomes.
- **Identification Concerns:** Parallel trends are fragile because DV leave laws may coincide with broader workplace protections and social-service expansions; triple-diff using men is not very diagnostic if shocks differentially affect women for reasons unrelated to DV leave. The main threat is an untestable policy-bundle story.
- **Recommendation:** **CONSIDER (conditional on: finding a dataset that better targets the treated group—e.g., linked administrative records from DV service providers/courts, or credible proxies with validated first-stage—and harmonizing policy strength into a transparent treatment index).**

---

**#4: Cleared to Work: State Cannabis Employment Testing Bans and Labor Market Tightness**
- **Score: 47/100**
- **Strengths:** The policy is timely and plausibly affects hiring frictions directly; the safety-sensitive exemption creates an intuitive within-state comparison, and adding injuries (OSHA) gives a meaningful trade-off margin (employment vs safety).
- **Concerns:** Too few treated states and extremely short post periods for many adoptions; inference will be fragile with cluster-robust SEs and sensitive to specification. Compliance/coverage is a major question (many employers may still test via exemptions or policy workarounds), so you risk weak or unverified first stage.
- **Novelty Assessment:** Medium-to-high—less studied than cannabis legalization, and the “testing ban” channel is not heavily mined, but the window is so recent that the design is not yet mature.
- **Top-Journal Potential: Low (for now).** This could become interesting later with longer panels and a strong first-stage measure of testing incidence. At present it is likely to be dismissed as underpowered/too early, especially given the editorial preference for longer horizons.
- **Identification Concerns:** Few treated clusters + short event time makes event-study diagnostics weak; legalization and other labor-market policies are strong confounders. “Legalized-but-no-testing-ban” placebo helps, but policy endogeneity (tight labor markets prompting bans) remains a core threat.
- **Recommendation:** **SKIP for now (revisit when there are ~3–5 post years and you can directly measure testing intensity from job postings, employer policy data, or vendor/test-panel data).**

---

### Summary

This is a strong batch on novelty, with one clear front-runner. **Idea 1 (CROWN Act)** is the best combination of novelty, feasible data, and a legible discrimination-to-allocation channel—worth pursuing first, but only if you can document policy “bite” and survive 2020-era confounds. **Idea 3** is novel but likely too diluted without better treated-group measurement; **Idea 2** is promising conceptually but premature given limited treated units and short post windows.

---

## Gemini 3.1 Pro

**Tokens:** 7440

Here is the evaluation and ranking of the research proposals, calibrated against the provided editorial patterns and evaluation criteria.

### Rankings

**#1: Idea 1: The CROWN Act and Black Worker Outcomes**
- **Score**: 82/100
- **Strengths**: This tackles a first-order policy question regarding racial employment gaps with a highly legible causal channel (removing a specific discrimination barrier). It is genuinely unstudied in economics, offering a rare chance to write the foundational paper on a widespread policy.
- **Concerns**: The 2019–2024 rollout heavily overlaps with the COVID-19 pandemic, and Black and White labor market dynamics diverged significantly during the recession and recovery. 
- **Novelty Assessment**: Extremely high. While sociological audit studies exist, there are zero economic evaluations of this legislation's causal impact on labor market outcomes.
- **Top-Journal Potential**: High. Top journals reward "first-order stakes + legible causal channels." If the paper can successfully map the mechanism (e.g., showing occupational upgrading into customer-facing roles) and survive COVID robustness checks, it has a compelling A→B→C narrative with clear welfare implications.
- **Identification Concerns**: The triple-difference strategy relies on White workers as a within-state control, which will fail if pandemic-era labor shocks (e.g., "essential worker" distributions, remote work capacity) affected Black and White workers differently in ways correlated with CROWN Act adoption timing.
- **Recommendation**: PURSUE (conditional on: proving parallel trends hold through the COVID shock; demonstrating a clear mechanism bite via occupational sorting rather than just aggregate employment).

**#2: Idea 3: Breaking the Anchor: Salary History Bans and Worker-Firm Matching Efficiency**
- **Score**: 58/100
- **Strengths**: It smartly pivots an existing, saturated literature (which focuses almost entirely on gender wage gaps) toward a fresh, interesting mechanism: matching efficiency and occupational sorting.
- **Concerns**: The CPS ASEC linked panels will yield a tiny effective sample size of job-switchers per state-year, leading to severe power issues and noisy measurements of occupational tenure.
- **Novelty Assessment**: Medium. The policy itself is heavily studied, making this an incremental contribution, even if the specific estimand (conditional wage growth on switching) is novel.
- **Top-Journal Potential**: Low to Medium. This risks falling into the modal rejection bucket: "technically competent but not exciting." It is another ATE on a known policy without the scale of "universe" admin data that top journals increasingly demand for matching/sorting papers.
- **Identification Concerns**: The small effective $N$ of job-switchers in CPS panels means any null will be underpowered, and any significant result might be fragile to wild bootstrap clustering or attrition bias in the CPS.
- **Recommendation**: CONSIDER (conditional on: abandoning the CPS and securing a massive administrative dataset—like LEHD, ADP payroll data, or universe tax records—to actually power the job-switching mechanism).

**#3: Idea 2: Cleared to Work: State Cannabis Employment Testing Bans**
- **Score**: 45/100
- **Strengths**: It isolates a specific, understudied mechanism (employer testing) rather than relying on the broad, diffuse shock of general cannabis legalization.
- **Concerns**: With only 10–12 treated states and very recent adoptions (2020–2024), the study will suffer from a severely truncated post-window and lack the statistical power to detect aggregate effects.
- **Novelty Assessment**: High novelty for this specific policy lever, though it sits adjacent to a very crowded and fatigued cannabis legalization literature.
- **Top-Journal Potential**: Low. The editorial appendix explicitly warns that "long horizons dominate short post windows" and penalizes papers where the "post extends into 2025/2026" as ambiguous. 
- **Identification Concerns**: With so few treated clusters and a short post-period overlapping with post-COVID labor market tightness, separating the testing ban effect from general macroeconomic trends will be nearly impossible.
- **Recommendation**: SKIP (revisit in 3–5 years when more states have adopted the policy and longer post-treatment windows are available).

**#4: Idea 4: State Domestic Violence Leave Laws and Female Labor Force Attachment**
- **Score**: 35/100
- **Strengths**: Addresses a highly important social issue with excellent policy variation (30+ states) over a long, clean time horizon (2004–2020).
- **Concerns**: There is a fatal mismatch between the policy's narrow target population (domestic violence victims) and the aggregate datasets proposed (CPS/ACS), guaranteeing an underpowered zero.
- **Novelty Assessment**: High novelty, as the broader labor market effects of these specific leave laws are largely unstudied in economics.
- **Top-Journal Potential**: Low. The editorial appendix notes that winning papers need a "verified bite/first stage." You cannot show a first stage for DV leave in aggregate female employment data, meaning any null result will be dismissed as an attenuation artifact.
- **Identification Concerns**: Extreme attenuation bias. Because DV victims are not identified in the CPS/ACS, the treatment effect is diluted across the entire female workforce, making it mathematically impossible to detect a plausible effect size.
- **Recommendation**: SKIP.

### Summary

Overall, this batch contains one standout idea (Idea 1) and three ideas that suffer from fatal data or power limitations. I strongly recommend pursuing **Idea 1 (The CROWN Act)**, as it is the only proposal that combines high novelty, first-order welfare stakes, and a legible causal channel, provided the authors can rigorously defend their design against COVID-19 confounding. Idea 3 is theoretically interesting but should only be pursued if the researchers can upgrade from public survey data to large-scale administrative data.

---

## Grok 4.1 Fast

**Tokens:** 5960

### Rankings

**#1: Idea 1: The CROWN Act and Black Worker Outcomes: Does Banning Hair Discrimination Reduce Racial Employment Gaps?**
- **Score**: 82/100
- **Strengths**: Extremely novel policy with zero prior economics papers, offering the first causal evidence on a timely anti-discrimination law; exceptional identification via triple-diff, multiple built-in placebos, mechanism decomposition, and robust inference on a large ACS/CPS sample, directly tying to racial employment gaps with clear welfare implications.
- **Concerns**: Potential small effects if hair discrimination is marginal for aggregate outcomes; COVID could still subtly confound despite triple-diff, though later adopters help.
- **Novelty Assessment**: Truly pathbreaking—zero economics studies on CROWN Act labor effects (only sociology/HR audits exist), confirmed by no Google Scholar hits for key terms.
- **Top-Journal Potential**: High. Challenges conventional wisdom on subtle discrimination channels with a "causal chain" (hair norms → occupational sorting → earnings), first-order racial gaps stakes, opponent-killer placebos (e.g., Black men/women, customer-facing), and welfare deliverable—fits editorial wins on niche policy as boundary test for discrimination mechanisms.
- **Identification Concerns**: Staggered DiD solid with 4+ pre-years and CS estimator, but rollout endogeneity (progressive states first) needs event-study checks; wild bootstrap addresses few early cohorts.
- **Recommendation**: PURSUE (conditional on: confirming no pre-trends in triple-diff event studies; piloting mechanism decomp for at least one clear substitution like occupational upgrading)

**#2: Idea 2: Cleared to Work: State Cannabis Employment Testing Bans and Labor Market Tightness**
- **Score**: 68/100
- **Strengths**: Novel isolation of testing-ban channel amid thin cannabis-employment lit; feasible CPS/QCEW data with triple-diff (safety-sensitive) and placebo (legalize-no-ban states) for credible mechanisms like hiring in tight markets.
- **Concerns**: Only 10-12 treated states risks underpowered DiD (below typical ≥20 threshold), with very short post-periods limiting dynamics; recent adoptions may lack power for injury/safety outcomes.
- **Novelty Assessment**: Thin but not zero—cannabis legalization well-studied, but no papers on employer testing bans specifically.
- **Top-Journal Potential**: Medium. Exciting cannabis policy angle with substitution potential (testing → hiring offsets), but few treated units and short horizons echo editorial losses on underpowered designs; needs tight welfare (e.g., pass-through to wages) to compete.
- **Identification Concerns**: Borderline treated units threaten reliable CS-2021 inference (wild bootstrap essential); safety-sensitive exemption may not perfectly proxy unaffected jobs.
- **Recommendation**: CONSIDER (if can stack with firm-level QCEW for scale and show MDE rules out small effects)

**#3: Idea 4: State Domestic Violence Leave Laws and Female Labor Force Attachment**
- **Score**: 62/100
- **Strengths**: Thin literature (only one narrow prior paper), ample staggered variation in 30+ states, and standard CPS/ACS data for female LF metrics with male triple-diff.
- **Concerns**: No DV victimization flag in data means fuzzy aggregate treatment (low-prevalence event dilutes power for small effects); hard to disentangle leave take-up from general shocks.
- **Novelty Assessment**: Very thin—one old economics paper on UI eligibility, nothing on broad leave laws and LF attachment.
- **Top-Journal Potential**: Medium-Low. Addresses female LF policy but lacks legible causal channel or bite verification (no first-stage leave usage); reads as "broad rollout → many outcomes" without trade-off discovery, per editorial patterns.
- **Identification Concerns**: Triple-diff helps but males imperfect control (spillovers possible); low prevalence risks imprecise nulls unable to rule out plausible magnitudes.
- **Recommendation**: CONSIDER (conditional on: linking to NCVS for victim subsample or bounds; prioritizing job retention mechanism)

**#4: Idea 3: Breaking the Anchor: Salary History Bans and Worker-Firm Matching Efficiency**
- **Score**: 55/100
- **Strengths**: Good variation (21+ states), creative estimand on matching efficiency via CPS panels, with within-firm placebo.
- **Concerns**: Builds on existing gender-gap papers, risking "incremental"; noisy CPS panels for tenure/wage growth limit precision.
- **Novelty Assessment**: Partial—multiple papers on bans and gaps (e.g., Bessen 2020), new angle on matching but not a fresh policy.
- **Top-Journal Potential**: Low. Competent DiD on saturated topic without belief-changing pivot or counter-intuitive mechanism; editorial losses flag "technically sound but unsurprising" without welfare novelty.
- **Identification Concerns**: Staggered timing clean, but job-switching conditional estimand vulnerable to sorting/composition; promotions placebo good but doesn't kill anticipation.
- **Recommendation**: SKIP

### Summary
This is a strong batch led by Idea 1, which stands out for pathbreaking novelty, top-tier identification, and top-journal excitement on racial discrimination—a rare combination. Pursue Idea 1 immediately as the clear winner; Idea 2 warrants a pilot for power, while 3 and 4 feel too incremental or fuzzy to prioritize over cleaner opportunities. Overall quality is above-average for policy proposals, with good feasibility across the board but variable novelty/ID rigor.

