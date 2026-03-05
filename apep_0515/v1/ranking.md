# Research Idea Ranking

**Generated:** 2026-03-05T10:08:09.865661
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| The Minimum Wage as a Hidden Tax on Elde... | PURSUE (76) | — | — |
| Empty Homes, Full Wallets? Council Tax P... | PURSUE (70) | — | — |
| Did the Apprenticeship Levy Subsidize th... | CONSIDER (60) | — | — |
| Priced Out of Patrol: Austerity PCSO Cut... | CONSIDER (56) | — | — |
| Does Enforcement Deterrence Shape the Wo... | SKIP (44) | — | — |
| Idea 1: The Minimum Wage as a Hidden Tax... | — | PURSUE (88) | — |
| Idea 3: Did the Apprenticeship Levy Subs... | — | PURSUE (72) | — |
| Idea 5: Empty Homes, Full Wallets? | — | CONSIDER (64) | — |
| Idea 2: Priced Out of Patrol: Austerity ... | — | SKIP (55) | — |
| Idea 4: Does Enforcement Deterrence Shap... | — | SKIP (38) | — |
| Idea 1: The Minimum Wage as a Hidden Tax... | — | — | PURSUE (82) |
| Idea 5: Empty Homes, Full Wallets? Counc... | — | — | PURSUE (75) |
| Idea 2: Priced Out of Patrol: Austerity ... | — | — | CONSIDER (70) |
| Idea 3: Did the Apprenticeship Levy Subs... | — | — | CONSIDER (62) |
| Idea 4: Does Enforcement Deterrence Shap... | — | — | SKIP (55) |

---

## GPT-5.2

**Tokens:** 7169

### Rankings

**#1: The Minimum Wage as a Hidden Tax on Elderly Care: National Living Wage Bite and Care Home Closures in England**
- **Score: 76/100**
- **Strengths:** Strong “first-order stakes + legible channel”: a large, repeated wage shock in a labor-cost-dominant, publicly funded sector with direct welfare implications (access/quality of elderly care). The CQC universe-style administrative panel on openings/closures/ratings is unusually compelling and enables mechanism tests (capacity vs. quality vs. market exit).
- **Concerns:** “Bite” is mechanically higher in lower-wage (often lower-growth) areas, so differential pre-trends and correlated shocks (local authority adult social care budgets, demographic aging, provider mix, COVID) are serious risks. LA-level ASHE for SOC 6145 can be noisy/sparse, potentially weakening the treatment measure.
- **Novelty Assessment:** **Moderately high.** Minimum wage effects are heavily studied, but *care-home closures/quality using CQC administrative data and NLW bite* is much less covered than standard employment/wage outcomes; this looks meaningfully new if executed well.
- **Top-Journal Potential: Medium-High.** More likely **AEJ: Economic Policy / JPubE** than a top-5 unless you can (i) nail identification, (ii) show a clear causal chain (NLW → wages/staffing → closures/quality → access), and (iii) deliver welfare-relevant counterfactuals (beds lost, travel distance, quality deterioration).
- **Identification Concerns:** Key threat is non-parallel trends between high-bite and low-bite areas driven by long-run regional divergence and funding regimes; you’ll need aggressive diagnostics (pre-trend event studies, stacked designs around each uprating, rich controls for care funding/demand, and sensitivity/bounding).
- **Recommendation:** **PURSUE (conditional on: strong pre-trend balance; credible “first stage” showing wage pass-through in care; explicitly handling adult social care funding + COVID period robustness; exploring alternative bite measures and inference with ~150 clusters).**

---

**#2: Empty Homes, Full Wallets? Council Tax Premiums and Housing Reactivation in England**
- **Score: 70/100**
- **Strengths:** Clean-looking policy variation (staggered adoption across ~300 authorities) with high policy salience and interpretable outcomes (vacancy stock, transactions, prices). If the adoption timing is plausibly idiosyncratic after conditioning on trends, this is a strong, scalable DiD setting.
- **Concerns:** Adoption is likely endogenous to local housing stress, fiscal pressure, and pre-existing vacancy trends—exactly what you’re trying to affect—so “staggered adoption” does not automatically buy you exogeneity. Annual outcome frequency limits dynamics/anticipation tests and may blur timing (decisions vs implementation).
- **Novelty Assessment:** **High.** There’s broad vacancy-tax literature internationally, but I’m not aware of a well-known *English empty homes premium* causal evaluation in mainstream econ outlets; most UK evidence is indeed descriptive.
- **Top-Journal Potential: Medium.** Stronger chance in **AEJ: Economic Policy / JUE** than top-5 unless you can add a belief-changing mechanism (e.g., why penalties fail/succeed due to enforcement capacity, avoidance, or landlord type) and produce credible welfare/counterfactual implications (net housing supply vs reallocation).
- **Identification Concerns:** The main risk is policy endogeneity (reverse causality) plus heterogeneous adoption correlated with unobservables; you’ll want an “opponent-killer” design element (e.g., border discontinuities, political/institutional instruments, or compelling pre-trend/lead tests + adoption-on-trends modeling).
- **Recommendation:** **PURSUE (conditional on: a serious strategy for endogenous adoption—at minimum strong lead tests and robustness to authority-specific trends; ideally a border/pair design or IV-like variation; and careful treatment timing/announcement effects).**

---

**#3: Did the Apprenticeship Levy Subsidize the Privileged? Training Displacement and Equity After England’s Payroll Tax**
- **Score: 60/100**
- **Strengths:** First-order policy question with a clear distributional narrative (youth/basic training down; degree/older up). Large geographic panel can give power, and heterogeneity by level/age is a natural mechanism map.
- **Concerns:** Area exposure based on large-firm employment share is plausibly correlated with local labor-market trajectories and changing occupational structure, threatening parallel trends. Apprenticeship measurement/policy definitions and concurrent reforms (funding rules, standards vs frameworks, provider constraints) complicate attribution to the levy.
- **Novelty Assessment:** **Medium.** The levy has been discussed extensively in policy circles (CVER/IFS-style work) and some academic work exists; the *equity/displacement causal angle* is less saturated but not virgin territory.
- **Top-Journal Potential: Medium-Low.** Likely a solid policy paper if identification is credible, but it risks reading as “competent DiD confirming widely believed compositional shifts” unless you can isolate mechanisms (firm behavior vs provider supply constraints) and quantify welfare/training human capital impacts.
- **Identification Concerns:** Treatment intensity may proxy for “big-city/large-employer” areas with their own trend breaks; you may need stronger design elements (industry×area exposure, firm-level linked data, or policy rule discontinuities around the £3M threshold if accessible).
- **Recommendation:** **CONSIDER (best if you can obtain firmer exposure measures or microdata and pre-register a tight set of outcomes/mechanisms; otherwise it may underwhelm on novelty/excitement).**

---

**#4: Priced Out of Patrol: Austerity PCSO Cuts and the Geography of Property Crime in England**
- **Score: 56/100**
- **Strengths:** Clear mechanism test (visible patrol presence) with granular monthly crime data and natural placebos by crime type. Policy relevance is obvious, and decomposing by offense category strengthens interpretability.
- **Concerns:** Police staffing changes are deeply endogenous to local budget shocks, leadership priorities, and crime trends; isolating PCSOs from broader policing changes is hard. The effective number of clusters (43 forces) is small for modern DiD with staggered intensity, and crime recording/reporting shifts plus the 2020 shock are major pitfalls.
- **Novelty Assessment:** **Medium-Low.** Police presence and crime is a very crowded literature; “PCSOs specifically” is a niche twist, but reviewers may see it as an incremental re-parameterization of policing inputs.
- **Top-Journal Potential: Low-Medium.** More plausible in a good field journal if you can convincingly separate PCSOs from other staffing and show a distinctive deterrence pattern; top-5 seems unlikely given saturation and identification skepticism.
- **Identification Concerns:** Confounding from simultaneous changes in officer counts, deployment, and local conditions; small-cluster inference and spillovers across force borders (criminal activity displacement) will be central critiques.
- **Recommendation:** **CONSIDER (conditional on: a credible strategy to net out overall policing and funding; transparent small-cluster inference; pre-2019 primary window to avoid COVID; and displacement/spillover checks).**

---

**#5: Does Enforcement Deterrence Shape the Workplace? Employment Tribunal Fees and Employer Conduct in England**
- **Score: 44/100**
- **Strengths:** The policy shock is sharp and reversible (introduction + abolition), and the deterrence logic is intellectually coherent. If the right outcome existed close to the margin of tribunal-enforced rights, this could be powerful.
- **Concerns:** The proposed outcomes (injuries, zero-hours, self-employment) are multiple steps removed from the tribunal channel and are plausibly dominated by other contemporaneous forces (macro recovery, regulatory changes, sectoral shifts). Cross-sectional “intensity” based on baseline claims risks reflecting unobserved workplace culture/industry composition rather than exposure to deterrence changes.
- **Novelty Assessment:** **Medium.** Tribunal fees and access-to-justice effects are known; downstream employer-behavior effects are less studied, but the difficulty is making them credibly measurable/attributable.
- **Top-Journal Potential: Low.** Absent a tight outcome directly tied to tribunal-enforced margins (e.g., wage theft complaints, settlements, HR policy changes, firm-level dispute behavior), this is likely to be viewed as diffuse and under-identified.
- **Identification Concerns:** Interrupted time series with many confounds and indirect outcomes is vulnerable; the “two breaks” help descriptively but don’t solve attribution without a much tighter cross-sectional design and outcome selection.
- **Recommendation:** **SKIP (unless you can redesign around a closer-to-enforcement margin outcome and a stronger cross-sectional contrast, ideally at firm/establishment level).**

---

### Summary

This is a strong batch in terms of policy relevance and administrative data access, but only two ideas look both *distinctly novel* and *publishable with credible identification*: the **NLW–care homes** project and the **empty homes premium** evaluation. I would start with **Idea 1** (highest upside if you can neutralize regional-trend critiques and show a clear causal chain), while advancing **Idea 5** in parallel if you can build a convincing case that adoption timing is not simply a response to worsening vacancies.

---

## Gemini 3.1 Pro

**Tokens:** 8007

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in the empirical realities of top-tier editorial preferences.

### Rankings

**#1: Idea 1: The Minimum Wage as a Hidden Tax on Elderly Care**
- **Score**: 88/100
- **Strengths**: This brilliantly links a well-understood shock (minimum wage) to an under-explored, high-stakes welfare margin (elderly care quality/capacity). The built-in internal replication (multiple wage hikes) and clean placebos (NHS/high-wage sectors) provide a highly credible design.
- **Concerns**: The "bite" measure relies on pre-2016 ASHE data, which can be noisy at the local authority level for specific occupations. You will need to prove that high-bite and low-bite LAs weren't already on divergent trajectories due to broader austerity cuts to local government funding.
- **Novelty Assessment**: High. The minimum wage literature is massively saturated regarding employment effects, but applying it to the market structure and quality of a publicly-funded, monopsonistic sector is highly novel and addresses a first-order policy puzzle.
- **Top-Journal Potential**: High. This perfectly fits the "trade-off discovery" pattern that top-5 journals love (a policy designed to help low-wage workers inadvertently harms vulnerable elderly populations). It offers a highly legible A→B→C causal chain (wage shock → cost shock → closure/quality drop) with clear welfare implications.
- **Identification Concerns**: The primary threat is that LAs with a high NLW bite (poorer areas) also suffered the most severe cuts to their central government social care grants during the 2010s austerity period, potentially confounding the closure rates.
- **Recommendation**: PURSUE (conditional on: controlling rigorously for LA-level social care budget changes over the panel period).

**#2: Idea 3: Did the Apprenticeship Levy Subsidize the Privileged?**
- **Score**: 72/100
- **Strengths**: It tackles a major, under-evaluated policy and frames it around a compelling "equity paradox" (a tax meant to boost basic skills instead subsidized MBAs for existing managers). The differential exposure design using firm-size distribution is clever and feasible.
- **Concerns**: LA-level firm-size distribution is not randomly assigned; areas dominated by large firms (cities) have fundamentally different macroeconomic and educational trends than SME-dominated areas (rural/coastal). 
- **Novelty Assessment**: Medium-High. Descriptive work exists, but causal evaluation of the Levy's distributional impacts is largely absent from the top-tier literature.
- **Top-Journal Potential**: Medium. It has strong AEJ: Economic Policy potential due to the clear policy relevance and equity framing. To hit a Top-5, it would need to be framed as a broader theoretical contribution about the incidence and distortionary effects of payroll-tax-funded training mandates.
- **Identification Concerns**: The "bite" (share of employment in >250 employee firms) might correlate with urban agglomeration trends or post-Brexit economic shocks that independently shifted training incentives.
- **Recommendation**: PURSUE (conditional on: establishing strict parallel trends and perhaps finding a tighter geographic or sector-level variation than just LA-level firm size).

**#3: Idea 5: Empty Homes, Full Wallets?**
- **Score**: 64/100
- **Strengths**: It utilizes a very clean staggered adoption design across ~300 units, which is ideal for modern CS-DiD estimators. The data is highly reliable, administrative, and easily accessible.
- **Concerns**: The adoption of the premium is likely endogenous; councils adopt the tax precisely when empty homes become a severe local political issue or when municipal budgets are in crisis. 
- **Novelty Assessment**: Medium. Housing taxes are well-studied, but this specific premium lacks a rigorous causal evaluation. 
- **Top-Journal Potential**: Low-Medium. This risks falling into the "competent but not exciting" bucket. While technically sound, it is a standard DiD on a somewhat niche policy. Unless it can be framed as a boundary test for broader housing market frictions or tax incidence, it is destined for a field journal (e.g., Journal of Urban Economics).
- **Identification Concerns**: Endogenous treatment timing. If councils implement the premium at the peak of a local housing crisis, mean reversion could masquerade as a treatment effect.
- **Recommendation**: CONSIDER (as a safe, quick-turnaround field-journal paper, but do not expect it to be a flagship institute output).

**#4: Idea 2: Priced Out of Patrol: Austerity PCSO Cuts**
- **Score**: 55/100
- **Strengths**: PCSOs offer a unique test of the "deterrence-through-visibility" hypothesis since they lack arrest powers, isolating the patrol channel.
- **Concerns**: The literature on police numbers and crime is incredibly saturated, and 43 police forces provide a borderline number of clusters for robust inference. 
- **Novelty Assessment**: Low. We have dozens of high-quality papers on police numbers and crime. While isolating PCSOs is a neat twist, it does not fundamentally change how the field thinks about the economics of crime.
- **Top-Journal Potential**: Low. This is the modal Top-5 rejection: "technically competent but not exciting." It is a standard DiD yielding an unsurprising sign (fewer patrols = more crime) without a novel mechanism decomposition.
- **Identification Concerns**: Severe endogeneity. The pace and depth of PCSO cuts were driven by local police budget constraints, which are highly correlated with local economic deprivation—which independently drives crime. Controlling for total officers does not solve the endogeneity of the *rate* of cuts.
- **Recommendation**: SKIP.

**#5: Idea 4: Does Enforcement Deterrence Shape the Workplace?**
- **Score**: 38/100
- **Strengths**: The symmetric design (introduction and subsequent abolition of fees) provides a theoretical opportunity for internal replication.
- **Concerns**: The causal chain is far too long and tenuous (fees → fewer claims → employers feel emboldened → workplaces immediately become physically more dangerous → higher injury rates). 
- **Novelty Assessment**: High (the employer moral hazard channel is rarely tested this way), but it is unstudied because it is nearly impossible to identify cleanly with this data.
- **Top-Journal Potential**: Low. Referees will immediately attack the identification. Papers with long, speculative causal chains and weak reduced-form links are routinely rejected.
- **Identification Concerns**: Fatal flaws. Interrupted Time Series is generally weak for top economics journals. Furthermore, using historical claim rates as a cross-sectional intensity measure is highly endogenous; high-claim sectors (e.g., construction, hospitality) have entirely different cyclical injury and employment dynamics than low-claim sectors.
- **Recommendation**: SKIP.

### Summary

Overall, this is a standard mixed batch of policy proposals: one genuine star, one solid contender, and several that suffer from common empirical pitfalls. **Idea 1 (Care Homes)** is by far the strongest and should be your institute's top priority; it combines a highly legible causal shock with a counter-intuitive, high-stakes welfare trade-off that top journals actively look for. **Idea 3 (Apprenticeship Levy)** is also worth pursuing as a strong field-journal paper if the equity paradox can be proven cleanly, while the others suffer from either saturated literatures (Idea 2), endogenous adoption (Idea 5), or fatal identification flaws (Idea 4).

---

## Grok 4.1 Fast

**Tokens:** 6323

### Rankings

**#1: Idea 1: The Minimum Wage as a Hidden Tax on Elderly Care: National Living Wage Bite and Care Home Closures in England**
- Score: 82/100
- Strengths: Exceptionally novel causal test of minimum wage effects in a monopsonistic care sector using clean continuous-treatment variation and administrative closure data, with a compelling welfare trade-off for elderly care access; strong policy relevance amid aging populations and multiple internal replications from annual wage hikes.
- Concerns: Care sector labor costs are high but publicly subsidized, so pass-through to prices or quality downgrades could confound closures; post-2020 COVID effects on care homes need careful exclusion or robustness checks.
- Novelty Assessment: High—existing NLW studies are aggregate employment/wages (e.g., IFS/LPC reports); no prior causal DiD on LA-level bite using CQC closures/quality, making this the first rigorous market structure analysis.
- Top-Journal Potential: High—fits editorial winners with "trade-off discovery" (wage floor boosts monopsony rents but shrinks elderly care supply via closures), legible causal chain (bite → closures → quality/beds), universe admin data (CQC/NOMIS), long horizon (14 years), and belief-changing pivot on min wage welfare in care markets.
- Identification Concerns: Parallel trends need strong pre-tests given regional wage disparities; continuous bite assumes no spillovers (e.g., migration of care workers), though placebos (NHS, high-wage sectors) mitigate.
- Recommendation: PURSUE (conditional on: robust COVID exclusion; event-study pre-trends passing at p<0.10)

**#2: Idea 5: Empty Homes, Full Wallets? Council Tax Premiums and Housing Reactivation in England**
- Score: 75/100
- Strengths: Clean staggered DiD across 300 LAs with genuine adoption variation, using comprehensive admin data on empty homes and housing markets; highly novel as the first causal evaluation of a major housing tool, with clear policy stakes for supply shortages.
- Concerns: Outcomes like house prices may reflect broader market trends (e.g., post-2016 Help to Buy); distinguishing reactivation from new supply or demolition requires careful coding of MHCLG stats.
- Novelty Assessment: High—no published causal studies despite policy prominence; only descriptive LGA/Shelter reports exist.
- Top-Journal Potential: Medium—strong on scale (300 LAs, Land Registry universe) and internal replication (staggered + multiple premium hikes), but housing supply ATE lacks a counter-intuitive mechanism or field-level puzzle unless framed as a "hidden tax offset" test with welfare bounds on vacancy elasticities.
- Identification Concerns: Staggered design risks recentering bias under CS-DiD if early adopters differ systematically; anticipation from 2013 guidance needs pre-2013 placebos.
- Recommendation: PURSUE (conditional on: CS-DiD diagnostics passing; mechanism tests for reactivation vs. price effects)

**#3: Idea 2: Priced Out of Patrol: Austerity PCSO Cuts and the Geography of Property Crime in England**
- Score: 70/100
- Strengths: Novel isolation of patrol visibility deterrence using cross-force PCSO cuts, with crime-type mechanisms and placebos; good policy relevance for austerity-era policing trade-offs.
- Concerns: Only 43 forces borderline for reliable DiD inference (RI tests may fail); total officer controls may not fully capture substitution if PCSOs crowded in sworn officers.
- Novelty Assessment: Medium-high—builds on Mello (2019) and Kirchmaier (2021) but first on PCSO-specific patrol channel with cross-force variation.
- Top-Journal Potential: Medium—legible channel (patrol cuts → visibility drop → property crime) as a "boundary test" for deterrence, with placebos, but small N and "another police DiD" risks "competent but not exciting" without a large, precise trade-off (e.g., violence offset).
- Identification Concerns: Differential cut timing may violate SAT assumptions; COVID crime spike (2020+) confounds post-period, requiring truncation.
- Recommendation: CONSIDER

**#4: Idea 3: Did the Apprenticeship Levy Subsidize the Privileged? Training Displacement and Equity After England's Payroll Tax**
- Score: 62/100
- Strengths: Interesting equity substitution angle (youth/basic → older/degree apprenticeships) using LA exposure variation; timely for training policy debates.
- Concerns: Area-level aggregation obscures firm behaviors (e.g., levy evasion via subcontracting); short post-period (2017+) limits long-run employment effects.
- Novelty Assessment: Medium—CVER descriptives well-known, but causal DiD on distributional shifts novel; some related work on levy incidence emerging.
- Top-Journal Potential: Low—diffuse outcomes (starts by age/level/sector) without tight welfare chain or counter-intuitive pivot; reads as "broad rollout → many outcomes" per editorial losses, unlikely to excite top-5 without stronger mechanisms.
- Identification Concerns: Pre-2017 firm-size shares may correlate with LA training demand, biasing trends; scraping DfE data risks inconsistencies.
- Recommendation: CONSIDER

**#5: Idea 4: Does Enforcement Deterrence Shape the Workplace? Employment Tribunal Fees and Employer Conduct in England**
- Score: 55/100
- Strengths: Novel moral hazard channel with symmetric ITS (intro + abolition); policy-relevant for labor enforcement.
- Concerns: Long causal chain (fees → fewer claims → lax conduct → injuries/contracts) indirect and hard to falsify; multiple outcomes dilute focus.
- Novelty Assessment: High—claim volumes studied (Adams & Prassl), but no causal tests of employer behavior changes.
- Top-Journal Potential: Low—indirect identification and "multi-step chain" without universe data or precise bounds fits "important but diffuse" losses; symmetric design helps but unlikely top-5 without tighter outcomes.
- Identification Concerns: ITS vulnerable to concurrent shocks (e.g., 2013 auto-enrolment); cross-sectional intensity (pre-claim rates) endogenous to misconduct prevalence.
- Recommendation: SKIP

### Summary
This is a strong batch with two genuinely promising ideas (1 and 5) leveraging clean admin DiD designs on understudied UK policies, fitting editorial preferences for scale, trade-offs, and replication—pursue Idea 1 first for its elderly welfare stakes and monopsony pivot. Ideas 2-3 are competent but risk underpowered or diffuse results, while Idea 4's weak ID makes it unviable without major redesign. Overall quality exceeds typical proposals, with high feasibility across UK open data sources.

