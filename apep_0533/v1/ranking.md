# Research Idea Ranking

**Generated:** 2026-03-05T19:27:41.332820
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Can't Ask, Won't Tell: Salary History Ba... | PURSUE (76) | PURSUE (88) | — |
| Does Legalizing Drug Checking Save Lives... | PURSUE (68) | CONSIDER (68) | — |
| Clean Energy Mandates and the Cost of El... | CONSIDER (60) | SKIP (52) | — |
| When Insurers Can't Discriminate: State ... | CONSIDER (54) | SKIP (45) | — |
| The Democratic Price of Convenience: Aut... | SKIP (45) | SKIP (35) | — |
| Idea 1: Can't Ask, Won't Tell: Salary Hi... | — | — | PURSUE (82) |
| Idea 2: Does Legalizing Drug Checking Sa... | — | — | PURSUE (75) |
| Idea 3: When Insurers Can't Discriminate... | — | — | CONSIDER (68) |
| Idea 5: Clean Energy Mandates and the Co... | — | — | CONSIDER (62) |
| Idea 4: The Democratic Price of Convenie... | — | — | SKIP (55) |

---

## GPT-5.2

**Tokens:** 6886

### Rankings

**#1: Can't Ask, Won't Tell: Salary History Bans, Hiring Wages, and the Gender Earnings Gap**
- **Score: 76/100**
- **Strengths:** The QWI “new-hire earnings vs continuing earnings” margin enables a genuinely sharp mechanism test (policy should bite at hire/negotiation, not for incumbents). With 20+ jurisdictions and long pre/post windows for early adopters, a modern staggered DiD/event-study can be well-powered and persuasive.
- **Concerns:** QWI cells are compositional averages—if bans change who gets hired (selection into employment/industry/firm types), “new-hire earnings” can move even without wage-setting changes. Salary history bans may also coincide with broader pay-equity packages (pay transparency, equal pay amendments), complicating attribution.
- **Novelty Assessment:** **Moderate-high novelty.** Salary history bans are studied, but not yet “100 papers”; using QWI new-hire earnings to build an internal placebo/DDD mechanism design is meaningfully differentiating.
- **Top-Journal Potential: Medium-High.** Could be AEJ:EP / top field if it delivers a clean causal chain (ban → hiring wage-setting → gender gap) with tight bounds and compelling heterogeneity (e.g., male-dominated industries). Less likely top-5 unless effects are large/surprising or it overturns prevailing views on negotiation vs monopsony/segmentation.
- **Identification Concerns:** The key threat is **differential compositional change** in new hires (and differential cyclical sensitivity of “new-hire wage premia” across states) that correlates with adoption; you’ll need pre-trend/event-study discipline, sectoral controls, and explicit composition checks (hire counts, worker mix proxies).
- **Recommendation:** **PURSUE (conditional on: explicit composition/selection diagnostics; careful accounting for contemporaneous pay-equity laws; pre-analysis plan for event-study and heterogeneity to avoid specification searching).**

---

**#2: Does Legalizing Drug Checking Save Lives? Fentanyl Test Strip Decriminalization and Drug-Specific Mortality**
- **Score: 68/100**
- **Strengths:** First-order stakes and a potentially very legible mechanism test using drug co-involvement (effects should concentrate in “unexpected fentanyl exposure” deaths). The policy is recent and rapidly spreading, so a careful, up-to-date causal evaluation could matter immediately.
- **Concerns:** Treatment timing is heavily bunched (2022–2023), outcomes are annual, and many overlapping opioid policies (naloxone access, PDMP changes, Medicaid expansion/1115s, Good Samaritan laws) move at similar times—this is a classic “policy bundle” confounding risk. Decriminalization is also a weak “first stage” for actual availability/usage of test strips.
- **Novelty Assessment:** **High novelty (in economics).** There are only a small number of causal papers so far; the proposed decomposition/placebo structure is a real value-add if credible.
- **Top-Journal Potential: Medium.** Big-policy relevance helps, and the mechanism decomposition could be publishable in AEJ:EP/JHE if executed cleanly; top-5 is harder because the identifying variation may look thin and policy bundling critiques are predictable.
- **Identification Concerns:** The main threats are **concurrent policy changes** and **endogenous adoption** (states hit hardest may legalize sooner), plus limited pre-trend testing with annual data. Without a strong strategy for bundled reforms (controls/event stacking/sensitivity/bounding), reviewers may not buy the causal claim.
- **Recommendation:** **CONSIDER (upgrade to PURSUE if you can: (i) build a credible “policy bundle” adjustment/stacked event-study design; (ii) document a first-stage proxy such as strip distribution/orders or harm-reduction funding shifts; (iii) show tight pre-trends on placebo outcomes).**

---

**#3: Clean Energy Mandates and the Cost of Electricity: State Renewable Portfolio Standards and Ratepayer Burden**
- **Score: 60/100**
- **Strengths:** The “ratchet-up” (intensive-margin) framing is better than initial adoption and directly targets the live policy question of incremental decarbonization costs and incidence across customer classes. Utility-level Form 861 data offers a path beyond coarse state averages if assembled carefully.
- **Concerns:** This is a crowded empirical area with many plausible confounders (fuel prices, grid congestion, wildfire hardening, interconnection queues, wholesale market design, extreme weather) that co-move with clean-energy policy. RPS ratchets themselves are plausibly endogenous to underlying cost trajectories and political economy.
- **Novelty Assessment:** **Low-moderate novelty.** RPS impacts on prices/costs have been studied extensively; “ratchet-ups + modern staggered DiD” is incremental rather than transformative.
- **Top-Journal Potential: Low-Medium.** More likely a solid field-journal contribution if it produces credible incidence estimates and transparent cost decomposition; top-5 is unlikely absent a surprising mechanism (e.g., price effects offset by merit-order/wholesale pass-through) or a sharp new design/data build.
- **Identification Concerns:** The big issue is **policy endogeneity and correlated shocks**; even with CS-DiD, the identifying assumption (parallel trends in prices absent ratchet-ups) is fragile. You’ll need aggressive robustness (fuel-price interactions, region×year shocks, bordering-market controls, pre-trend and placebo policy tests).
- **Recommendation:** **CONSIDER (conditional on: utility-level design and/or quasi-exogenous variation in compliance pressure; otherwise it risks reading as “another RPS-price DiD”).**

---

**#4: When Insurers Can't Discriminate: State Insulin Copay Caps and the Diabetes Burden**
- **Score: 54/100**
- **Strengths:** The policy is salient and expanding; there is a clear behavioral margin (affordability → adherence → acute events). A multi-state design could improve substantially on single-state pre/post studies if outcomes and affected populations are measured well.
- **Concerns:** Diabetes mortality is a slow-moving, noisy outcome and (critically) not well aligned with a policy affecting a subset of patients (commercially insured insulin users); CDC WONDER mortality can’t stratify by insurance, so any effect is mechanically diluted. BRFSS medication nonadherence measures are noisy and not consistently available for the relevant subgroup.
- **Novelty Assessment:** **Moderate novelty.** Copay caps are newer than many insurance regulations, but health-policy researchers are already publishing early evaluations; the “mortality” angle is less explored, yet may be infeasible/underpowered.
- **Top-Journal Potential: Low-Medium.** Could land in a good health economics/health policy outlet if you can show a strong first stage (insulin fills/out-of-pocket costs) and credible health impacts on nearer-term endpoints; top journals will likely view state-year mortality DiD as too blunt.
- **Identification Concerns:** The main threats are **attenuation and mis-targeting** (unable to isolate treated insured insulin users) plus contemporaneous diabetes/Medicaid policies and differential pandemic-era health shocks.
- **Recommendation:** **CONSIDER (but redesign).** If you can get claims (APCD, MarketScan, all-payer claims) or a strong utilization first stage with subgroup targeting, it becomes much more promising; with state-year mortality as the headline, it’s likely to disappoint.

---

**#5: The Democratic Price of Convenience: Automatic Voter Registration and the Turnout Paradox**
- **Score: 45/100**
- **Strengths:** The “registration-turnout gap” is a clean, interpretable object tied to a big conceptual claim (registration costs vs participation costs). AVR is widespread enough that a cross-state design is possible in principle.
- **Concerns:** The outcome data are too temporally sparse (biennial election-year snapshots), which cripples pre-trend testing and event-study credibility—exactly where staggered adoption designs get challenged. Substantial prior political science work already documents “registration up, turnout modest,” so the upside is limited unless you bring new administrative microdata or a novel mechanism.
- **Novelty Assessment:** **Low novelty.** AVR and turnout have been heavily discussed and studied (especially outside econ); a state-level CPS/EAC DiD is unlikely to be viewed as a frontier contribution.
- **Top-Journal Potential: Low.** Without richer administrative voter-file microdata (and ideally individual-level linkage to DMV encounters) or a sharp new design, this will read as “competent but not exciting,” with predictable identification objections.
- **Identification Concerns:** **Too few time periods** for credible parallel-trends diagnostics and heterogeneous timing methods; any estimated “paradox” risks being an artifact of measurement and election-specific shocks.
- **Recommendation:** **SKIP (unless you can pivot to high-frequency admin voter file data or a sharper within-state design around implementation mechanics).**

---

### Summary

This batch has two ideas with real upside: **#1 (salary history bans with QWI new-hire vs incumbent earnings)** is the most promising because the design naturally builds in a mechanism placebo and the data are unusually strong. **#2 (fentanyl test strip decriminalization)** is high-stakes and novel but will live or die on whether you can convincingly address policy bundling and weak first-stage concerns; I’d start with #1 while pressure-testing #2’s identification strategy in parallel.

---

## Gemini 3.1 Pro

**Tokens:** 8738

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in empirically observed editorial patterns at top economics journals.

### Rankings

**#1: Can't Ask, Won't Tell: Salary History Bans, Hiring Wages, and the Gender Earnings Gap**
- **Score**: 88/100
- **Strengths**: This proposal perfectly executes the "scale as scientific content" playbook by using universe-level QWI data to isolate the exact mechanism margin (new hires). The triple-difference design contains an "opponent-killer placebo" (continuing workers and male workers) that cleanly rules out concurrent state-level macro shocks.
- **Concerns**: The primary risk is that QWI data aggregates at the cell level (state $\times$ quarter $\times$ sex $\times$ industry), meaning you cannot control for individual-level covariates (like education or exact age) that might shift if the composition of new hires changes post-ban.
- **Novelty Assessment**: While Salary History Bans have been studied (e.g., Hansen & McNichols, Bessen et al.), existing papers rely on small survey samples (CPS) or job postings. The novelty here is not the policy, but the *definitive execution* using universe data and a mechanism-revealing DDD design that previous papers couldn't run.
- **Top-Journal Potential**: High. A top-5 journal would find this exciting because it addresses a first-order policy question (gender wage gap) with a highly legible causal chain (Ban $\rightarrow$ New Hire Wages $\rightarrow$ Gap closes, while Continuing Wages remain flat). It elevates a known topic to a definitive, boundary-testing standard.
- **Identification Concerns**: Very few. The main threat is compositional changes in *who* gets hired post-ban. If bans cause firms to hire more experienced women (shifting the composition), the wage effect is a composition effect, not a bargaining effect.
- **Recommendation**: PURSUE (conditional on: adding a test for compositional shifts in the QWI age/education cells to rule out hiring-pool changes).

**#2: Does Legalizing Drug Checking Save Lives? Fentanyl Test Strip Decriminalization and Drug-Specific Mortality**
- **Score**: 68/100
- **Strengths**: The mechanism decomposition (accidental cocaine/meth contamination vs. intentional opioid use) is a highly creative, high-upside narrative arc. It addresses a massive public health crisis with a clear, testable causal channel.
- **Concerns**: The rapid, bunched adoption of these laws (~30 states in a 24-month window) severely limits the clean "not-yet-treated" control group required for modern staggered DiD. Furthermore, coroner coding of specific drug combinations (T40.4 vs T40.5) is notoriously noisy and endogenous to state-level funding and testing protocols.
- **Novelty Assessment**: Moderate. The policy is beginning to be studied in working papers, but the specific drug-type decomposition to isolate accidental vs. intentional deaths is a clever, novel twist that elevates it above a standard ATE paper.
- **Top-Journal Potential**: Medium. The stakes are undeniably first-order, and the mechanism surprise (saving lives on the accidental margin) is exactly what editors like. However, the data quality and bunching issues will likely trigger fatal identification flags at the top-5 level, making it a better fit for a top field journal (e.g., AEJ: Policy or JHE).
- **Identification Concerns**: The bunching of treatment timing leaves very few clean post-periods. Additionally, if states that legalize FTS simultaneously increase funding for overdose toxicology screening, you will have a mechanical, endogenous increase in the detection of specific drug combinations.
- **Recommendation**: CONSIDER (conditional on: proving that state-level coroner testing protocols did not systematically change concurrently with FTS legalization).

**#3: Clean Energy Mandates and the Cost of Electricity: State Renewable Portfolio Standards and Ratepayer Burden**
- **Score**: 52/100
- **Strengths**: It asks a highly relevant distributional question (residential vs. industrial pass-through) about the energy transition. The data is highly feasible and publicly available.
- **Concerns**: This reads exactly as "competent but not exciting." Intensive margin DiD (ratchet-ups) is notoriously messy, as legislative ratchet-ups are highly endogenous to a state's current economic trajectory and existing renewable capacity.
- **Novelty Assessment**: Low. The cost of RPS has been heavily studied (most notably Greenstone & Nath, 2020, QJE). Shifting the focus to ratchet-ups and pass-through is an incremental extension, not a paradigm shift.
- **Top-Journal Potential**: Low. This falls into the modal loss category: standard DiD + narrow margin + heavily studied area. It lacks a belief-changing pivot or a structural counterfactual that would change how the field views RPS.
- **Identification Concerns**: Legislative ratchet-ups are not exogenous shocks; they are often passed *because* renewable costs have fallen in that specific region, or because the state is experiencing an economic boom. State $\times$ year fixed effects cannot be used if the treatment varies at the state-year level, leaving the design vulnerable to regional macro shocks (e.g., natural gas price spikes).
- **Recommendation**: SKIP (unless you can pair it with a structural model of utility rate-setting to generate novel welfare counterfactuals).

**#4: When Insurers Can't Discriminate: State Insulin Copay Caps and the Diabetes Burden**
- **Score**: 45/100
- **Strengths**: The policy is highly relevant, and the inclusion of a placebo (metformin) and a secondary federal shock (Medicare IRA) shows good strategic thinking for event-study validation.
- **Concerns**: There is a fatal mismatch between the proposed design and the data. The proposal suggests a DDD based on commercial insurance status, but explicitly notes that CDC WONDER mortality data *does not distinguish by insurance*. Furthermore, aggregate state-level diabetes mortality is far too slow-moving to detect a $35/month copay cap effect within a 1-3 year post-period.
- **Novelty Assessment**: Low. Insulin caps are heavily saturated in the health policy and medical literature. Moving the outcome to mortality is technically new, but only because it is empirically implausible.
- **Top-Journal Potential**: Low. Top journals explicitly punish "bad measurement/proxy outcomes" and "too short to move core outcomes." A 2-year window is insufficient to observe mortality changes from marginal medication adherence.
- **Identification Concerns**: The inability to isolate the commercially insured population in the mortality data destroys the DDD strategy. Without it, you are running a state-level DiD on a slow-moving outcome with massive concurrent health shocks (COVID-19 overlaps perfectly with the 2020-2023 rollout).
- **Recommendation**: SKIP.

**#5: The Democratic Price of Convenience: Automatic Voter Registration and the Turnout Paradox**
- **Score**: 35/100
- **Strengths**: The "turnout paradox" framing connects well to theoretical models of voting costs, and the policy is a major feature of modern election administration.
- **Concerns**: This proposal suffers from two fatal flaws: severe temporal sparsity in the data (biennial) and a lack of novelty. The finding that AVR increases registration but depresses the *conditional* turnout rate is already the standard, well-documented consensus in political science.
- **Novelty Assessment**: Very Low. Political scientists (e.g., McGhee et al., Grumbach & Hill) have already published extensively on this exact dynamic using voter file data.
- **Top-Journal Potential**: Low. The biennial nature of the CPS and EAC data means you will have, at most, 2-3 pre-treatment periods for many states. As noted in the Appendix, "severe underpowering at the core cutoff/design" and the inability to rigorously test parallel trends are treated as decisive losses.
- **Identification Concerns**: Biennial data masks exact treatment timing and destroys event-study precision. Furthermore, states that adopt AVR often bundle it with other voting conveniences (mail-in voting expansions, early voting), creating confounded treatment bundles with no separation strategy.
- **Recommendation**: SKIP.

### Summary

This batch contains one outstanding proposal, one high-risk/high-reward idea, and three that should be discarded. **Idea 1 (Salary History Bans)** is exceptionally strong and should be pursued immediately; it perfectly leverages universe-scale data and an "opponent-killer" placebo to definitively answer a first-order question. **Idea 2 (Fentanyl Test Strips)** is worth considering if the data quality and bunching issues can be mitigated, as the mechanism decomposition is highly compelling, but the remaining three ideas suffer from fatal data flaws or a lack of novelty and should be skipped.

---

## Grok 4.1 Fast

**Tokens:** 6239

### Rankings

**#1: Idea 1: Can't Ask, Won't Tell: Salary History Bans, Hiring Wages, and the Gender Earnings Gap**
- Score: 82/100
- Strengths: Universe-scale QWI data enables a clean triple-difference design that directly tests the hiring mechanism via new hire vs. continuing worker earnings, with strong pre-trends, many treated units, and industry heterogeneity; modern CS-DiD addresses flaws in prior TWFE papers.
- Concerns: Gender gap compression might be small in aggregate (QWI averages could mask negotiation dynamics), and male placebo assumes no spillover effects on male wages.
- Novelty Assessment: Moderately studied (3-4 papers on bans using CPS/job postings), but QWI's new-hire separation and scale make this the first mechanism-tested, universe-data evaluation.
- Top-Journal Potential: High (top-5 or AEJ:EP viable). Fits editorial patterns: universe admin data tightens bounds on a first-order policy (gender gaps), with legible causal chain (ban → new hires → gap compression) and opponent-killer placebo (continuing workers/males); challenges "just anchor bias" wisdom via industry tests.
- Identification Concerns: Statewide trends absorbed by DDD, but unobservables like negotiation norms or firm relocation could bias if they coincide with bans; needs robust event studies for early adopters.
- Recommendation: PURSUE (conditional on: industry-level event studies confirming parallel trends; male spillover falsification tests)

**#2: Idea 2: Does Legalizing Drug Checking Save Lives? Fentanyl Test Strip Decriminalization and Drug-Specific Mortality**
- Score: 75/100
- Strengths: Drug-type decomposition reveals counterintuitive mechanism (accidental vs. intentional deaths), building on one prior paper with CS-DiD and built-in placebo; massive stakes with 100K+ annual deaths.
- Concerns: Annual data and treatment bunching (2022-23 wave) limit event-study power and exacerbate staggered DiD biases, even with CS.
- Novelty Assessment: Minimally studied (one recent TWFE paper on overall mortality); decomposition is genuinely new.
- Top-Journal Potential: High (top-5 or AEJ:EP). Matches "first-order stakes + legible causal channel" (test strips → accidental contamination deaths) with mechanism surprise (substitution across drugs) and precise bounds via placebo; operational welfare (lives saved by contamination type).
- Identification Concerns: Bunching reduces clean variation; cocaine/meth deaths might reflect supply shifts or reporting changes, not just testing behavior.
- Recommendation: PURSUE (conditional on: sensitivity to bunching via synthetic controls; quarterly proxies if available)

**#3: Idea 3: When Insurers Can't Discriminate: State Insulin Copay Caps and the Diabetes Burden**
- Score: 68/100
- Strengths: Mortality outcomes elevate beyond utilization studies, with DDD placebo (non-insulin meds) and federal Medicare cap as validation; ~25 states provide decent N.
- Concerns: Key data (CDC mortality, BRFSS) lacks insurance stratification, so commercial-insured targeting is ecological; BRFSS inconsistency across states/years weakens adherence measures.
- Novelty Assessment: Lightly studied (2 single-state or pre-post papers on utilization); first multi-state mortality take, but not groundbreaking.
- Top-Journal Potential: Medium. Health stakes and causal chain (caps → adherence → mortality) appealing, but data mismatch prevents tight bounds or "universe-scale" credibility; reads more "competent ATE" than mechanism surprise without insurance-linked outcomes.
- Identification Concerns: Caps mainly hit commercial insured, but aggregate mortality conflates Medicare/Medicaid; federal 2023 cap confounds late adopters.
- Recommendation: CONSIDER (if linked claims data accessible for insurance-stratified outcomes)

**#4: Idea 5: Clean Energy Mandates and the Cost of Electricity: State Renewable Portfolio Standards and Ratepayer Burden**
- Score: 62/100
- Strengths: Ratchet-up intensive margin and DDD (residential vs. industrial pass-through) sidestep adoption confounders; policy-relevant for energy transition costs.
- Concerns: Electricity prices heavily influenced by gas/weather/grid factors, with state×year FE absorbing much signal; ratchet coding demands intensive legwork.
- Novelty Assessment: Well-studied (multiple papers on adoption/cross-sections); ratchets + CS-DiD incremental but not transformative.
- Top-Journal Potential: Low-Medium. Distributional angle fits welfare patterns, but lacks surprise/mechanism (expected pass-through not counterintuitive) and risks "competent but diffuse" rejection amid confounders; no scale or bounds-tightening edge.
- Identification Concerns: Ratchets may correlate with state green commitments or subsidies, violating exogeneity; industrial/residential split assumes no cross-elasticities.
- Recommendation: CONSIDER (if ratchet timing cleanly exogenous and MDEs rule out small effects)

**#5: Idea 4: The Democratic Price of Convenience: Automatic Voter Registration and the Turnout Paradox**
- Score: 55/100
- Strengths: "Turnout paradox" frames a theoretical puzzle (registration vs. motivation costs) with potential to challenge participation models.
- Concerns: Biennial data (≤5 periods) cripples pre-trend tests and event studies, underpowering staggered DiD fatally.
- Novelty Assessment: Moderately studied (several descriptive/multi-state papers on early adopters); CS-DiD not done, but paradox angle fresh.
- Top-Journal Potential: Low. Puzzle appealing, but temporal sparsity is a fatal flaw per appendix (undergowered core design); lacks scale/mechanism to elevate beyond "standard DiD null."
- Identification Concerns: Few pre-periods prevent parallel trends validation; biennial sparsity hides dynamics like opt-outs.
- Recommendation: SKIP

### Summary
This is a strong batch overall, with two ideas (1 and 2) genuinely top-journal contenders due to scale/mechanism fits with editorial patterns and clean identification on high-stakes policies—far better than the typical "competent but unexciting" proposals. Pursue Idea 1 first for its unmatched data/DDD rigor, then Idea 2 for overdose urgency; the rest suffer feasibility or confound issues dragging them below pursuit threshold.

