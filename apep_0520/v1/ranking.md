# Research Idea Ranking

**Generated:** 2026-03-05T14:16:05.459656
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Does Coverage Create Capacity? Section 1... | PURSUE (76) | — | — |
| Opioid Settlement Fund Disbursements and... | CONSIDER (66) | — | — |
| Nurse Practitioner Full Practice Authori... | CONSIDER (58) | — | — |
| State Cannabis Legalization and Medicaid... | SKIP (55) | — | — |
| Medicaid Managed Care Mandates and Provi... | SKIP (45) | — | — |
| Idea 1: Does Coverage Create Capacity? S... | — | PURSUE (88) | PURSUE (82) |
| Idea 4: Opioid Settlement Fund Disbursem... | — | CONSIDER (62) | CONSIDER (70) |
| Idea 2: Nurse Practitioner Full Practice... | — | SKIP (55) | SKIP (52) |
| Idea 3: State Cannabis Legalization and ... | — | SKIP (48) | CONSIDER (62) |
| Idea 5: Medicaid Managed Care Mandates a... | — | SKIP (40) | SKIP (45) |

---

## GPT-5.2

**Tokens:** 6128

### Rankings

**#1: Does Coverage Create Capacity? Section 1115 SUD Waivers and the Supply of Behavioral Health Providers**
- Score: **76/100**
- Strengths: Clear first-order policy lever (IMD exclusion relaxation) with a tight, legible mechanism (“payment permission → provider entry/participation → access”), and unusually rich administrative data that can measure supply on multiple margins. The “supply-side response” angle is meaningfully less saturated than the utilization/enrollment literature.
- Concerns: “Approval date” may not equal real operational change (implementation, contracting, IMD capacity, and billing practice changes can lag), and 2018-start T‑MSIS limits pre-trends for early adopters and complicates anticipation. T‑MSIS provider taxonomy/H-code comparability and state-specific reporting changes can masquerade as “entry.”
- Novelty Assessment: **Moderately novel**—1115 SUD waivers are studied, but *provider supply/capacity* effects using T‑MSIS are much less covered and could be a real contribution if executed well.
- Top-Journal Potential: **Medium**. Could rise toward high if you package it as a boundary test of “insurance expansions fail when supply is inelastic” *and* show a credible first-stage on IMD/residential capacity plus downstream access/welfare implications (not just claims counts).
- Identification Concerns: Key threats are endogenous timing (states seek waivers amid worsening opioid crises), differential COVID-era shocks, and measurement/definition changes in T‑MSIS. You’ll need strong diagnostics (state-specific trends, event-study pre-trends, reporting-quality controls, negative controls) and ideally a “bite” measure (e.g., actual IMD/residential claim share jumps).
- Recommendation: **PURSUE (conditional on: validating treatment timing with an implementation/billing “first-stage”; restricting to cohorts with adequate pre-period and stable T‑MSIS reporting; pre-registering a placebo/negative-control battery and RI/cluster-robust inference)**

---

**#2: Opioid Settlement Fund Disbursements and Behavioral Health Treatment Capacity**
- Score: **66/100**
- Strengths: Very high policy salience and plausibly new: the field has not yet produced much credible evidence on whether settlement dollars translate into on-the-ground treatment capacity. If disbursement timing/amounts are credibly measured, the shock-to-capacity link is conceptually direct.
- Concerns: Data construction is the project—state/local disbursement timing, pass-through, and earmarking are heterogeneous and often opaque, and “funds received” may be weakly related to “funds spent on capacity.” The post window (mostly 2022–2024) is short for capacity formation, and confounding from ARPA/HCBS and other opioid-era initiatives is severe.
- Novelty Assessment: **High**—especially linking settlements to provider supply/MAT prescribing in Medicaid admin data.
- Top-Journal Potential: **Medium**. Could be exciting if you can credibly show (i) when/where money actually hit providers, (ii) a strong first stage, and (iii) a persuasive counterfactual; otherwise it risks reading as “important but diffuse + short window.”
- Identification Concerns: Timing of disbursements/spending is not plausibly exogenous absent a strong design (e.g., formula-driven variation, predetermined payment schedules, or litigation/administrator constraints). Without that, DiD will struggle to separate “money causes capacity” from “worse states both get/accelerate funds and expand services.”
- Recommendation: **CONSIDER (conditional on: building auditable disbursement/obligation data with dates and amounts; leveraging predetermined formula/payout schedules as the main variation; extending outcomes through at least 2026 or using faster-moving intermediate outcomes like contracting/credentialing/claims acceptance)**

---

**#3: Nurse Practitioner Full Practice Authority and the Structure of Medicaid Billing**
- Score: **58/100**
- Strengths: The measurement idea is sharp: scope-of-practice reform should mechanically re-map billing/servicing NPI patterns, and T‑MSIS+NPPES can uniquely observe that “organizational dependence → independent billing” margin in Medicaid. If it works, it’s a clean “policy → regulated margin” first-stage that many SOP papers infer indirectly.
- Concerns: Too few treated states in 2018–2024 for credible staggered DiD at the state level; inference will be fragile under any modern robust DiD/cluster corrections. Also risks being viewed as a “billing mechanics” paper unless you connect the billing shift to access, prices, or physician market power in a compelling chain.
- Novelty Assessment: **Moderate**—scope-of-practice is heavily studied (especially Medicare), but this specific Medicaid billing-structure measurement is less explored.
- Top-Journal Potential: **Low-to-Medium**. A top field journal might like it if you (i) broaden treatment variation (partial reforms, temporary orders, supervisory ratio changes) and (ii) tie the billing reallocation to access/quality and market structure in a belief-changing way.
- Identification Concerns: Small number of treated clusters plus potentially endogenous adoption (states liberalize when provider shortages worsen). Without additional quasi-experimental leverage (border discontinuities, within-state rollouts, or richer policy coding), effects will be hard to defend.
- Recommendation: **CONSIDER (conditional on: expanding the policy series beyond “full” FPA to increase treated events; using border-county designs or stacked county-level exposure; pre-specifying randomization-inference / wild-cluster methods for few treated states)**

---

**#4: State Cannabis Legalization and Medicaid Behavioral Health Spending**
- Score: **55/100**
- Strengths: Large, salient policy with staggered adoption and the possibility of an interesting sign ambiguity (increased CUD treatment vs substitution away from opioids). T‑MSIS could add Medicaid-specific evidence and potentially detect distributional effects among low-income populations.
- Concerns: This is a very crowded literature, and the causal channel to *provider supply/capacity* is indirect and slow-moving. Legalization coincides with many other changes (opioid policy, policing, Medicaid expansions, COVID) that make clean attribution difficult, and “effective dates” vs market opening dates vary.
- Novelty Assessment: **Low-to-Moderate**—cannabis legalization effects on health/utilization are extensively studied; the Medicaid/provider-supply angle is incremental unless you uncover a striking mechanism.
- Top-Journal Potential: **Low**. Likely to be judged as another legalization DiD unless you bring a genuinely new mechanism test (e.g., opioid-treatment substitution within tightly defined service categories with strong pre-trends and falsification tests).
- Identification Concerns: Policy timing is plausibly endogenous to evolving social/health trends; parallel trends are often shaky; and treatment is multi-dimensional (possession legality, retail opening, product potency, local opt-outs). A single treatment indicator risks attenuation and confounding.
- Recommendation: **SKIP (unless you can reframe around a sharper shock—e.g., retail opening dates/local opt-in discontinuities—and a narrowly specified mechanism with strong falsification tests)**

---

**#5: Medicaid Managed Care Mandates and Provider Market Consolidation**
- Score: **45/100**
- Strengths: The market-structure question is important, and using billing/servicing structure to proxy organizational consolidation is a creative use of claims metadata. If there were clean mandate shocks, the welfare implications (access, bargaining, administrative burden) could be meaningful.
- Concerns: During 2018–2024 there are few genuinely clean, large MCO-mandate expansions left—most states’ big transitions happened earlier—so identifying variation is thin and likely endogenous. The outcome (Type 1 vs Type 2 NPI billing) may reflect billing intermediaries and reporting practices more than true consolidation, creating serious measurement risk.
- Novelty Assessment: **Moderate**—managed care is heavily studied; “consolidation via NPI billing structure” is newer but may be viewed as a proxy outcome without clear welfare mapping.
- Top-Journal Potential: **Low**. Without a sharp, high-stakes policy discontinuity and a validated consolidation measure linked to prices/quality/access, it will read as “competent but not exciting.”
- Identification Concerns: Selection into managed care expansions correlates with fiscal stress, provider network issues, and political changes; and missing pre-period for earlier reforms undermines event studies. Measurement error in “consolidation” could generate spurious changes at reform dates.
- Recommendation: **SKIP (unless you can find a truly sharp, well-documented mandate expansion with long pre-trends and externally validate consolidation using independent ownership/group datasets)**

---

### Summary

This batch has one clearly fundable lead project: **Idea 1** is the best combination of novelty, scale, and a tight causal channel, with credible design possibilities if treatment timing and T‑MSIS reporting stability are handled rigorously. **Idea 4** is the most “high-upside but data-heavy” option—worth considering only if you can build a defensible disbursement/spending timeline and extend the post period or focus on fast-moving intermediate outcomes. The remaining ideas are either underpowered (Idea 2) or too saturated/diffuse (Ideas 3 and 5) to be top-priority for a policy research institute aiming for publishable causal evidence.

---

## Gemini 3.1 Pro

**Tokens:** 8320

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in empirically observed editorial preferences at top economics journals.

### Rankings

**#1: Idea 1: Does Coverage Create Capacity? Section 1115 SUD Waivers and the Supply of Behavioral Health Providers**
- **Score**: 88/100
- **Strengths**: Addresses a massive, first-order policy question (the reversal of a 50-year federal payment ban) with a highly legible causal channel (funding → provider entry). The use of T-MSIS to measure the supply-side capacity response is genuinely novel and fills a critical gap in the literature.
- **Concerns**: The staggered rollout overlaps with the COVID-19 pandemic and telehealth expansions, which could confound supply-side changes if not carefully handled. 
- **Novelty Assessment**: High. While the demand-side of SUD waivers has been studied, the supply-side response remains a black box. Using T-MSIS for provider-level analysis is a cutting-edge application of the data.
- **Top-Journal Potential**: High. This perfectly fits the "first-order stakes + legible causal channel" archetype. Proving that lifting a payment ban actually creates physical treatment capacity (rather than just shifting rents) provides a compelling A→B→C causal chain that would excite top general interest or top field journals (e.g., AEJ: Policy).
- **Identification Concerns**: The primary threat is concurrent state-level shocks (e.g., opioid crisis severity driving both waiver timing and provider entry). However, the proposed built-in placebos (dental, personal care) are exactly the kind of "opponent-killer" diagnostics that referees reward.
- **Recommendation**: PURSUE

**#2: Idea 4: Opioid Settlement Fund Disbursements and Behavioral Health Treatment Capacity**
- **Score**: 62/100
- **Strengths**: Evaluates a massive, highly salient $50B+ policy shock that policymakers care deeply about right now. Linking settlement dollars directly to physical treatment infrastructure is exactly the kind of accountability research the field needs.
- **Concerns**: The post-period is far too short (2022–2024), and isolating settlement funds from ARPA or state general funds will be extremely difficult.
- **Novelty Assessment**: High. The policy is so new that there is virtually no rigorous econometric literature on its supply-side impacts yet.
- **Top-Journal Potential**: Medium. While the stakes are high, the editorial patterns are clear: long horizons dominate short post windows. A 1-2 year post-period for a slow-moving infrastructure investment will be viewed by editors as underpowered and premature.
- **Identification Concerns**: Disbursement timing is likely endogenous to state administrative capacity, and it will be nearly impossible to isolate settlement funds from concurrent ARPA HCBS investments. 
- **Recommendation**: CONSIDER (conditional on: extending the data window to at least 2025/2026; securing precise, exogenous variation in disbursement timing).

**#3: Idea 2: Nurse Practitioner Full Practice Authority and the Structure of Medicaid Billing**
- **Score**: 55/100
- **Strengths**: Uses a novel dataset (T-MSIS + NPPES) to look at the micro-structure of Medicaid billing, which is a fresh angle on a well-known topic.
- **Concerns**: Only 5–8 states adopted FPA during the study window, which is insufficient for a credible staggered DiD design.
- **Novelty Assessment**: Low/Medium. NP FPA is one of the most heavily studied topics in health economics. While the Medicaid billing angle is new, the core policy variation is thoroughly mined.
- **Top-Journal Potential**: Low. This is the modal loss: "technically competent but not exciting." It applies a standard DiD to a saturated topic without a belief-changing pivot or a major welfare counterfactual. 
- **Identification Concerns**: With only ~5–8 treated states, the design is severely underpowered for a staggered DiD. It cannot credibly rule out state-specific idiosyncratic shocks, and expanding the definition to partial scope changes will introduce fatal noise.
- **Recommendation**: SKIP

**#4: Idea 3: State Cannabis Legalization and Medicaid Behavioral Health Spending**
- **Score**: 48/100
- **Strengths**: Connects a high-profile state policy to Medicaid administrative data, attempting to measure spillover effects on behavioral health infrastructure.
- **Concerns**: The causal channel from recreational cannabis legalization to Medicaid behavioral health provider supply is highly diffuse, indirect, and likely confounded by the opioid epidemic.
- **Novelty Assessment**: Medium. Cannabis legalization is heavily studied, though looking at Medicaid provider supply is a slightly new twist.
- **Top-Journal Potential**: Low. This violates the "legible causal channel" rule. Top journals heavily discount "broad rollout → many outcomes" papers where the mechanism (cannabis → SUD provider supply) is diffuse and speculative.
- **Identification Concerns**: Massive omitted variable bias. The causal link is too weak to separate from massive concurrent confounders like the fentanyl wave and COVID-19. Any results would likely collapse under robust placebo testing.
- **Recommendation**: SKIP

**#5: Idea 5: Medicaid Managed Care Mandates and Provider Market Consolidation**
- **Score**: 40/100
- **Strengths**: Attempts to measure market consolidation and organizational structure using administrative billing data, which is a clever use of T-MSIS entity types.
- **Concerns**: There is almost no clean policy variation during the 2018–2024 window, as most states had already transitioned to managed care long before this period.
- **Novelty Assessment**: Medium. MCO mandates are well-studied, though the specific focus on provider consolidation via billing NPIs is somewhat novel.
- **Top-Journal Potential**: Low. Without a sharp, well-powered quasi-experiment, this reads as a descriptive data exercise rather than a causal evaluation of a policy shock.
- **Identification Concerns**: The fatal flaw is the lack of variation; with most MCO mandates predating 2018, there is no viable identification strategy to separate the policy from secular consolidation trends.
- **Recommendation**: SKIP

### Summary

Overall, this batch contains one outstanding proposal (Idea 1) and several fundamentally flawed or underpowered ones. Idea 1 is a rare combination of a massive, unstudied policy shock and a novel dataset that can actually measure the supply-side mechanism, giving it a very high ceiling. I strongly recommend putting all immediate institute resources into Idea 1, while keeping Idea 4 on the backburner until more post-period data becomes available to solve its horizon problem.

---

## Grok 4.1 Fast

**Tokens:** 5326

### Rankings

**#1: Idea 1: Does Coverage Create Capacity? Section 1115 SUD Waivers and the Supply of Behavioral Health Providers**
- Score: 82/100
- Strengths: Exceptional novelty in shifting focus to supply-side effects using newly feasible T-MSIS provider data, paired with strong staggered DiD on 30+ states and built-in placebos for robust identification; directly addresses a first-order policy gap (coverage expansion without capacity risks collapse) with universe-scale data and multi-margin outcomes.
- Concerns: Potential spillovers across state borders or anticipation effects pre-CMS guidance; results must clearly link supply growth to welfare (e.g., access for underserved) to avoid "competent ATE" trap.
- Novelty Assessment: High—existing waiver studies (e.g., Maclean et al.) focus solely on demand/utilization; no published supply-side analysis with T-MSIS H/J-codes.
- Top-Journal Potential: High—fits editorial winners with "policy lever → regulated margin (capacity) → welfare" chain, universe T-MSIS scale as scientific content, and trade-off potential (e.g., coverage paradox if no supply response); challenges conventional wisdom on IMD waivers.
- Identification Concerns: Staggered DiD credible with long pre-periods and placebos (e.g., unrelated T-codes), but must validate no pre-trends and handle event-study heterogeneity per Callaway-Sant'Anna.
- Recommendation: PURSUE (conditional on: robust event-study diagnostics and mechanism tests for access/welfare; ≥2-year post windows for most states)

**#2: Idea 4: Opioid Settlement Fund Disbursements and Behavioral Health Treatment Capacity**
- Score: 70/100
- Strengths: High novelty as first provider-level test of whether $50B settlements build SUD infrastructure; full 50-state staggered variation offers scale, with clear policy stakes on fund efficacy.
- Concerns: Disbursement dates hard to compile precisely and separate from confounders (ARPA, state funds); very short post-period (2022–2024) risks underpowered nulls or ambiguity per editorial patterns.
- Novelty Assessment: High—no linked evidence on settlements to T-MSIS supply; timely as funds ongoing.
- Top-Journal Potential: Medium—exciting if uncovers offset/substitution (e.g., funds crowd out other investments), but diffuse channel and short horizon may read as "broad rollout → many outcomes" without tight mechanism map.
- Identification Concerns: Endogeneity of state spending priorities confounds; needs opponent-killers like non-SUD placebos and first-stage verification of fund bite on providers.
- Recommendation: CONSIDER (conditional on: compiling reliable dates and extending post-period if possible)

**#3: Idea 3: State Cannabis Legalization and Medicaid Behavioral Health Spending**
- Score: 62/100
- Strengths: Adds supply-side angle to cannabis literature using T-MSIS; ~15 states provide decent variation for staggered DiD on a timely policy.
- Concerns: Indirect channel (legalization → BH supply?) invites confounders (opioids, COVID, other reforms); marginal treated units risk RI instability in DiD.
- Novelty Assessment: Medium—cannabis-health well-studied (utilization, crime), but Medicaid provider supply underexplored.
- Top-Journal Potential: Low—lacks tight causal chain or belief pivot; reads as "important but diffuse" shock-to-outcome without substitution discovery or welfare deliverable.
- Identification Concerns: Concurrent policies and national trends (e.g., opioid decline) violate parallel trends; needs strong placebos but channel too vague for clean inference.
- Recommendation: CONSIDER

**#4: Idea 2: Nurse Practitioner Full Practice Authority and the Structure of Medicaid Billing**
- Score: 52/100
- Strengths: Clever use of T-MSIS/NPPES to measure billing transitions; novel Medicaid focus vs. Medicare-heavy literature.
- Concerns: Critically underpowered with only 5–8 treated states, violating staggered DiD best practices; expanding to partial changes adds noise.
- Novelty Assessment: Medium—FPA extensively studied, but provider billing structure new for Medicaid.
- Top-Journal Potential: Low—niche outcome (billing patterns) unlikely to excite top journals without broader access/welfare chain; "competent but not exciting" DiD.
- Identification Concerns: Few clusters make estimator unreliable (e.g., heterogeneous effects dominate); no mention of pre-trends or placebos.
- Recommendation: SKIP

**#5: Idea 5: Medicaid Managed Care Mandates and Provider Market Consolidation**
- Score: 45/100
- Strengths: Innovative billing NPI structure for concentration measures; policy-relevant consolidation angle.
- Concerns: Very few mandate changes in 2018–2024 window (most pre-date data); weak variation dooms identification.
- Novelty Assessment: Medium-low—managed care market effects studied, billing-based HHI new but incremental.
- Top-Journal Potential: Low—standard ATE on saturated topic without counterintuitive mechanism or scale; fits "modal loss" of unexciting DiD.
- Identification Concerns: Scarce treated events preclude credible DiD; no staggered power for inference.
- Recommendation: SKIP

### Summary
This batch has one standout (Idea 1) with top-journal promise due to novelty, clean ID, and editorial-fit framing, while others suffer from weak variation, short horizons, or diffuse channels—typical of competent but non-exciting proposals. Pursue Idea 1 immediately as it leverages T-MSIS scale for a supply-capacity puzzle with welfare bite; consider Idea 4 if data hurdles clear, but skip the rest unless redesigned for more treated units. Overall quality is solid for policy work but only marginally publishable in top outlets.

