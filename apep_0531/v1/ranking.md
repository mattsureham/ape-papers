# Research Idea Ranking

**Generated:** 2026-03-05T17:18:03.697269
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Soft Power and Crime: The Effect of Poli... | PURSUE (71) | PURSUE (82) | PURSUE (82) |
| Public Space Protection Orders and the D... | CONSIDER (64) | CONSIDER (55) | CONSIDER (68) |
| Universal Credit and Crime: A Modern Dif... | CONSIDER (58) | SKIP (45) | CONSIDER (62) |
| When It Rains, Crime Pours: Rainfall Sho... | SKIP (45) | SKIP (40) | SKIP (55) |
| The Price of Police Precepts: Locally-Se... | SKIP (41) | SKIP (30) | SKIP (48) |

---

## GPT-5.2

**Tokens:** 6302

### Rankings

**#1: Soft Power and Crime: The Effect of Police Community Support Officer Cuts on Neighbourhood Safety in England**
- Score: **71/100**
- Strengths: High-value policy question with unusually large, long-run variation in a specific policing input (PCSOs) and clean, public administrative data. The “type of policing” angle (community presence vs. sworn capacity) can generate a mechanism story beyond a generic police–crime elasticity.
- Concerns: The key threat is **endogenous austerity re-optimization**: forces that cut PCSOs most may also be those facing different crime trends, political priorities, or broader budget shocks that affect crime through multiple channels. Force-level aggregation (43 units) limits power for flexible dynamics and makes inference sensitive to a few influential forces.
- Novelty Assessment: **Moderately high**. There is a large police–crime literature and UK austerity policing work, but **national causal evidence specifically on PCSOs as a distinct input** is thin.
- Top-Journal Potential: **Medium**. Stronger if you can (i) convincingly isolate PCSO cuts from broader policing/budget changes and (ii) document a distinctive mechanism (visibility/trust/intelligence) rather than “fewer staff → more crime.”
- Identification Concerns: Parallel trends may fail if PCSO-heavy forces were on different pre-2010 trajectories; “controlling for sworn officers” may not solve omitted variables if budgeting reallocations co-move with unobserved enforcement strategy. A design upgrade would be to use **grant formula shocks / centrally-driven funding changes** as an instrument or a shift-share-style predictor of PCSO cuts.
- Recommendation: **PURSUE (conditional on: a credible exogeneity strategy for PCSO cuts beyond TWFE/CS-DiD; strong pre-trend/placebo battery; sensitivity to influential forces and clustered inference)**

---

**#2: Public Space Protection Orders and the Displacement of Anti-Social Behaviour**
- Score: **64/100**
- Strengths: Substantively important and plausibly **under-studied**, with a built-in “surprising mechanism” angle (spatial displacement vs true reductions) that policymakers care about. The LSOA geography is well-suited to directly test displacement rings/adjacency patterns rather than just LA averages.
- Concerns: Data feasibility is the major risk: without a reliable, dated adoption register (and ideally the **geographic boundaries** of PSPO coverage), the project can stall or devolve into measurement error that biases estimates toward zero. Adoption is also likely endogenous (PSPOs enacted in response to rising ASB), making a vanilla staggered DiD fragile.
- Novelty Assessment: **High**. Despite widespread use, rigorous causal evaluations of PSPOs (especially displacement) are not prominent in the economics/credible policy eval literature.
- Top-Journal Potential: **Medium**. A top field journal could care if you (i) build a high-quality policy dataset and (ii) show a clear displacement vs deterrence pattern with tight spatial/event-time evidence and welfare implications.
- Identification Concerns: Selection into adoption is first-order; you’ll need an “opponent-killer” approach—e.g., exploiting **boundary-level contrasts** (treated LSOAs just inside vs just outside PSPO polygons), strong event-study diagnostics, and/or instruments based on legal/political constraints rather than contemporaneous ASB.
- Recommendation: **CONSIDER (conditional on: constructing a defensible adoption+boundary dataset—ideally via FOI/London Gazette plus GIS; an identification strategy stronger than LA-level staggered DiD)**

---

**#3: Universal Credit and Crime: A Modern Difference-in-Differences Analysis at Fine Geographic Scale**
- Score: **58/100**
- Strengths: Large sample, rich outcomes, and a credible staggered rollout setting where modern estimators and diagnostics (CS-DiD, HonestDiD) can materially improve credibility. The LSOA granularity allows sharper heterogeneity (e.g., deprivation, baseline benefit reliance) and mechanism-consistent crime-type patterns.
- Concerns: The core question (UC rollout → crime, especially property crime) is **already in the literature**, so the incremental contribution risks reading as “better DiD mechanics” rather than a new economic insight. Mapping Jobcentre rollout to LSOAs/LAs can introduce nontrivial treatment timing misclassification (and spillovers across boundaries).
- Novelty Assessment: **Low-to-moderate**. Welfare reform and crime is well-studied; UC specifically has now been analyzed, and a published paper already exists with the main claim.
- Top-Journal Potential: **Low-to-Medium**. Could reach a strong field outlet if you contribute something conceptually new (e.g., pin down the 5-week wait/channel with auxiliary administrative measures, or deliver tight welfare-relevant bounds/counterfactuals), but top-5 is unlikely on method upgrades alone.
- Identification Concerns: Rollout was not purely random (early sites/pilots, operational capacity, local admin conditions), so you must show robust pre-trends and address **anticipation/partial treatment** (legacy claimants vs new claimants, varying exposure intensity).
- Recommendation: **CONSIDER**

---

**#4: When It Rains, Crime Pours: Rainfall Shocks and Criminal Activity in England**
- Score: **45/100**
- Strengths: High-frequency weather variation is plausibly exogenous, and the indoor/outdoor decomposition is a clean test of routine activity predictions. Data are plentiful and the design can be transparent (rich fixed effects, event-time around storms).
- Concerns: This is not tightly tied to a policy lever, and the weather–crime relationship has a **large existing literature**; the marginal contribution is mainly “England + finer rainfall,” which may not clear the excitement bar. Also, interpreting rainfall as an IV for “activity/mobility” requires a strong first stage (and ideally independent mobility data).
- Novelty Assessment: **Low**. Many papers already connect weather shocks to crime/violence; England-specific granularity is a data improvement, not a new question.
- Top-Journal Potential: **Low**. More plausible as a solid applied/methods paper or as a component/auxiliary design within a larger policy project.
- Identification Concerns: Weather is exogenous, but inference can be fragile if crime reporting/measurement changes with storms, and spatial matching (gauges→LSOAs) plus multiple-hypothesis issues can generate false precision without careful aggregation and pre-registration-style discipline.
- Recommendation: **SKIP (unless bundled into a broader policy paper where rainfall provides auxiliary identification of routine-activity mechanisms)**

---

**#5: The Price of Police Precepts: Locally-Set Policing Levies and Crime in England**
- Score: **41/100**
- Strengths: Clear policy relevance—local fiscal discretion for policing is a real decision margin, and the counterfactual (“what does +£X per household buy in crime reduction?”) is inherently interesting.
- Concerns: The endogeneity is severe: precepts respond to crime, politics, and local economic conditions, and simple FE models will not be credible. The proposed “cap” quasi-experiment often delivers limited identifying variation (few binders, strategic bunching, and simultaneous changes in central grants).
- Novelty Assessment: **Moderate**. Police spending and crime is heavily studied; this is a UK institutional twist, but not an uncharted question.
- Top-Journal Potential: **Low** without a design breakthrough (e.g., a truly compelling instrument or discontinuity that generates exogenous precept changes with adequate power).
- Identification Concerns: Reverse causality and omitted variables dominate; “cap-binding vs not” can itself be endogenous (PCC strategy), and any instrument based on caps risks weak-IV and local-to-cap external validity.
- Recommendation: **SKIP (unless you can credibly exploit an exogenous rule change or discontinuity with sufficient treated units and clear first-stage power)**

---

### Summary

This batch has **one genuinely high-upside policy evaluation** (PCSOs) and **one potentially very novel policy dataset/build project** (PSPOs) that could become publishable if the identification and measurement are elevated beyond standard staggered DiD. If choosing where to invest first, I’d start with **Idea 1** (fast feasibility, strong policy stakes) while doing a short, time-boxed “data reality check” sprint on **Idea 4** to see if the PSPO adoption/boundary data can be made research-grade.

---

## Gemini 3.1 Pro

**Tokens:** 8219

Here is my evaluation of the proposed research ideas, ranked from most to least promising. As a policy institute, we must prioritize research that combines first-order policy stakes with credible identification and a compelling narrative arc, avoiding projects that are merely "competent but not exciting" or fatally confounded.

### Rankings

**#1: Soft Power and Crime: The Effect of Police Community Support Officer Cuts on Neighbourhood Safety in England**
- **Score**: 82/100
- **Strengths**: This exploits a massive, unstudied austerity shock with a long horizon (2007-2024) to test a distinct theoretical mechanism (procedural justice/visible presence vs. arrest capacity). By decomposing the police workforce into "type" rather than just "quantity," it moves beyond the standard police-crime literature.
- **Concerns**: The 43 police force clusters sit on the lower boundary for reliable inference. Furthermore, local Police and Crime Commissioner (PCC) budget allocations might be endogenous to local crime trends.
- **Novelty Assessment**: High. The specific policy (PCSO cuts) is unstudied at scale. Moving from a single-city RCT to a national dose-response panel provides a major external validity contribution.
- **Top-Journal Potential**: High. This fits the "first-order stakes + one legible causal channel" winning pattern perfectly. It challenges conventional wisdom on police funding and offers a long horizon, which editors explicitly prefer over short 1-2 year windows. 
- **Identification Concerns**: The variation in cuts is partly driven by local PCC decisions, which could be correlated with unobserved local crime trajectories. You will need an IV (e.g., central funding formula shocks) or a very convincing placebo/pre-trend analysis to defend the exogeneity of the cuts.
- **Recommendation**: PURSUE (conditional on: establishing an instrument or strict exogeneity for the force-level variation in cuts; verifying sufficient power with 43 clusters).

**#2: Public Space Protection Orders and the Displacement of Anti-Social Behaviour**
- **Score**: 55/100
- **Strengths**: Addresses a highly visible, unstudied local policy with a clear focus on spatial displacement—a classic mechanism of interest in urban and crime economics. It directly answers a question policymakers are actively debating.
- **Concerns**: The lack of a central registry makes data collection highly risky. If adoption dates cannot be reliably scraped or FOIA'd, the project dies on the vine.
- **Novelty Assessment**: Medium-High. PSPOs are widely used in the UK but lack rigorous causal evaluation, and the displacement angle is a great theoretical hook.
- **Top-Journal Potential**: Medium. It's a solid *AEJ: Economic Policy* paper if the displacement mapping is sophisticated. However, it might read as a "niche setting" without a broader theoretical hook unless framed around the general equilibrium welfare effects of localized spatial bans.
- **Identification Concerns**: Local Authorities likely adopt PSPOs precisely when ASB becomes a severe political issue (Ashenfelter's dip). Defending parallel pre-trends will be very difficult without a matching strategy or a localized boundary-discontinuity design.
- **Recommendation**: CONSIDER (conditional on: a successful 1-week pilot scraping/FOIA-ing a random sample of 20 LAs to prove data feasibility).

**#3: Universal Credit and Crime: A Modern Difference-in-Differences Analysis at Fine Geographic Scale**
- **Score**: 45/100
- **Strengths**: Uses highly granular LSOA data and modern, robust DiD estimators (Callaway-Sant'Anna) to evaluate a major welfare reform. The data is readily available and the empirical strategy is technically sound.
- **Concerns**: The core finding (Universal Credit increases property crime) has already been published in a respected journal (d'Este and Harvey, 2024). This is an incremental methodological update, not a conceptual leap.
- **Novelty Assessment**: Low. Applying a newer estimator and finer geographic data to an already-published finding does not constitute a novel economic contribution.
- **Top-Journal Potential**: Low. The editorial appendix explicitly notes that "technically competent but not exciting" papers (standard DiD + unsurprising sign) are modal losses. The lack of a new puzzle or mechanism surprise kills its chances at a top-5.
- **Identification Concerns**: CS-DiD handles heterogeneous treatment effects well, but mapping Jobcentre rollout schedules to LSOAs might introduce spatial measurement error if catchment areas are fuzzy.
- **Recommendation**: SKIP.

**#4: When It Rains, Crime Pours: Rainfall Shocks and Criminal Activity in England**
- **Score**: 40/100
- **Strengths**: Leverages incredibly granular (15-minute) exogenous environmental shocks to test routine activity theory. The data infrastructure proposed is impressive.
- **Concerns**: Weather-crime is a heavily saturated literature, and this does not evaluate a policy, making it a poor fit for a policy research institute. 
- **Novelty Assessment**: Low. The weather-crime link has been studied exhaustively (e.g., Jacob et al., 2007). The 15-minute granularity is a neat data trick, not a new economic question.
- **Top-Journal Potential**: Low. This reads like an "instrument looking for a paper." Top journals demand a puzzle or a policy counterfactual, not just high-frequency confirmation of known phenomena.
- **Identification Concerns**: While rainfall is exogenous, using it as an IV for "outdoor mobility" requires a strong exclusion restriction. Rain likely affects police deployment, response times, and psychological moods, violating the exclusion restriction.
- **Recommendation**: SKIP.

**#5: The Price of Police Precepts: Locally-Set Policing Levies and Crime in England**
- **Score**: 30/100
- **Strengths**: Asks a highly relevant fiscal federalism question about local taxation and public safety. The data is easily accessible.
- **Concerns**: Fatal endogeneity. PCCs raise the policing precept specifically when they need more resources to fight rising crime, completely confounding the treatment effect.
- **Novelty Assessment**: Medium. Local police funding is studied extensively in the US (e.g., COPS grants), but the UK precept mechanism is less explored.
- **Top-Journal Potential**: Low. The editorial appendix warns that "Identification failure you already document" is a decisive loss. Reviewers will immediately flag the reverse causality, and the paper will not survive peer review.
- **Identification Concerns**: Severe reverse causality. Without a central government capping rule that binds quasi-randomly (allowing for an RDD), the continuous DiD is hopelessly confounded by local crime trends.
- **Recommendation**: SKIP.

### Summary

This batch contains one standout idea (Idea 1: PCSO Cuts) that perfectly aligns with top-journal preferences for long-horizon, mechanism-driven evaluations of major policy shocks, provided the endogeneity of local cuts can be managed. The rest of the batch suffers from fatal flaws: Idea 4 has severe data feasibility issues, Idea 2 is already published, Idea 3 is a non-policy data exercise, and Idea 5 is hopelessly endogenous. I strongly recommend allocating our resources to developing Idea 1, with a brief feasibility pilot for Idea 4 if time permits.

---

## Grok 4.1 Fast

**Tokens:** 6119

### Rankings

**#1: Soft Power and Crime: The Effect of Police Community Support Officer Cuts on Neighbourhood Safety in England**
- Score: 82/100
- Strengths: Exceptionally novel exploitation of national cross-force variation in PCSO cuts to test community-oriented vs. traditional policing, with clean dose-response design and strong data availability; directly addresses a first-order policy question on police composition with clear mechanisms (visible deterrence vs. procedural justice).
- Concerns: Reliance on police-recorded crime could suffer from reporting biases that vary by force; simultaneous austerity changes (e.g., court funding) might confound if not fully controlled.
- Novelty Assessment: Highly novel—only one prior causal study (Ariel et al. 2016 RCT in one city); no national evidence on PCSO-specific effects or type-of-policing decomposition.
- Top-Journal Potential: High. Challenges conventional wisdom that police quantity alone matters (vs. composition), with a compelling causal chain (PCSO cuts → reduced visible presence/trust → crime rise by type) and national-scale external validity to a micro-RCT; fits editorial preference for mechanism surprises and policy counterfactuals on workforce allocation.
- Identification Concerns: Variation plausibly exogenous via funding formulas/PCC decisions uncorrelated with local trends, with good pre-trends (2007-09) and sworn officer controls; but staggered dose requires CS-DiD to handle heterogeneous effects, and force-level aggregation might mask spillovers.
- Recommendation: PURSUE (conditional on: robust sensitivity to TWFE/CS-DiD and spillovers; mechanism tests via ASB/intelligence proxies)

**#2: Public Space Protection Orders and the Displacement of Anti-Social Behaviour**
- Score: 68/100
- Strengths: Untapped policy tool (PSPOs) with high novelty and direct test of displacement mechanism, highly policy-relevant for local ASB enforcement; LSOA granularity enables sharp spatial tests.
- Concerns: Data collection on adoption dates is labor-intensive and incomplete (no central registry), risking selection bias in sample; short post-2014 window limits long-horizon effects prized by editors.
- Novelty Assessment: Very novel—PSPOs widely used since 2014 but no rigorous causal evaluations exist, per my knowledge.
- Top-Journal Potential: Medium. Addresses policy-relevant displacement trade-off (ASB suppression vs. shifting), with potential causal chain (PSPO → local ASB drop → adjacent rise); exciting for field journal like AEJ:EP, but niche UK tool and diffuse outcomes reduce top-5 appeal without broader framing.
- Identification Concerns: Staggered DiD feasible if dates obtained, with LA FEs handling fixed differences; but adoption likely endogenous to ASB trends, needing pre-trends validation and border controls for spillovers.
- Recommendation: CONSIDER (conditional on: feasible PSPO date assembly via scraping/FOIA; power checks for ≥100 adopters)

**#3: Universal Credit and Crime: A Modern Difference-in-Differences Analysis at Fine Geographic Scale**
- Score: 62/100
- Strengths: Strong identification via staggered CS-DiD at high granularity (~33k LSOAs), building credible mechanisms (5-week wait → property crime); excellent data feasibility.
- Concerns: Incremental over d'Este & Harvey (2024), which already established core UC-crime link, making it read as methodological polish rather than conceptual advance; top journals dismiss "competent but unsurprising" updates.
- Novelty Assessment: Moderately novel—core finding (UC raises property crime) recently published (d'Este & Harvey 2024); gains from scale/methods/CS-DiD but not transformative.
- Top-Journal Potential: Low. Methodological improvements (CS-DiD, granularity) are solid but editors prioritize new puzzles over estimator tweaks; lacks belief-changing pivot beyond confirming prior ATE with mechanisms.
- Identification Concerns: Jobcentre rollout plausibly exogenous with 3+ pre-years and HonestDiD checks; fine scale reduces spillovers, but heterogeneous effects across LAs could bias TWFE remnants.
- Recommendation: CONSIDER

**#4: When It Rains, Crime Pours: Rainfall Shocks and Criminal Activity in England**
- Score: 55/100
- Strengths: Granular rainfall-crime link tests routine activity theory via indoor/outdoor split, with high-freq data enabling tight event studies.
- Concerns: Not a policy evaluation (pure natural experiment), diluting relevance for a policy institute; weather-crime literature exists, framing as "niche boundary test" needed but weak here.
- Novelty Assessment: Moderately novel—weather-crime studied extensively (e.g., US Jacob et al. 2007, Jacob & Lefgren 2003), but England's 15-min gauge + LSOA novelty adds granularity.
- Top-Journal Potential: Low. Mechanism decomposition appealing, but lacks policy stakes or causal chain tied to decisions; editors favor policy-first questions over general theory tests without first-order welfare implications.
- Identification Concerns: Rainfall exogenous conditional on geography/season, but IV first-stage might be weak for non-extreme events; spatial matching risks ecological bias without individual mobility data.
- Recommendation: SKIP

**#5: The Price of Police Precepts: Locally-Set Policing Levies and Crime in England**
- Score: 48/100
- Strengths: Tests local fiscal discretion in centralized policing, with available precept/crime data.
- Concerns: Severe reverse causality (PCCs raise precepts responding to crime), undermining identification without a strong instrument; reads as competent but endogenous, per editorial pitfalls.
- Novelty Assessment: Low—police funding-crime links well-studied (e.g., Levitt 1997, many UK studies on total spending); precept margin not transformative.
- Top-Journal Potential: Low. Endogenous variation fails "credible ID" threshold; no mechanism surprise or policy pivot beyond unsurprising elasticity.
- Identification Concerns: Precept changes clearly endogenous to crime (no exclusion via caps alone); FEs insufficient without IV, risking confounded ATE.
- Recommendation: SKIP

### Summary
This batch has one standout idea (Idea 1) with top-journal potential due to novelty, clean national ID, and mechanism challenge to policing debates, warranting pursuit. Ideas 2 and 3 offer solid technical foundations but lack excitement or policy focus, while 4's novelty is offset by data hurdles and 5's fatal endogeneity. Prioritize Idea 1, with Idea 2 as a strong backup if PCSO data reveals issues.

