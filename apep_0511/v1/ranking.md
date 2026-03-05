# Research Idea Ranking

**Generated:** 2026-03-05T10:03:50.564848
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Does 340B Drug Pricing Crowd Out Medicai... | PURSUE (74) | — | — |
| Cross-Payer Spillovers at Medicare Payme... | PURSUE (67) | — | — |
| Does Federal “Underserved” Designation A... | CONSIDER (62) | — | — |
| The Hidden Cost of Hospital Consolidatio... | CONSIDER (58) | — | — |
| Nurse Practitioner Full Practice Authori... | SKIP (52) | — | — |
| Idea 1: Does 340B Drug Pricing Crowd Out... | — | PURSUE (84) | — |
| Idea 4: Cross-Payer Spillovers at Medica... | — | CONSIDER (65) | — |
| Idea 2: MUA Designation and Medicaid Hom... | — | SKIP (52) | — |
| Idea 3: NP Full Practice Authority Borde... | — | SKIP (46) | — |
| Idea 5: 340B Consolidation and Medicaid ... | — | SKIP (40) | — |
| Idea 1: Does 340B Drug Pricing Crowd Out... | — | — | PURSUE (78) |
| Idea 3: Nurse Practitioner Full Practice... | — | — | CONSIDER (68) |
| Idea 4: Cross-Payer Spillovers at Medica... | — | — | CONSIDER (64) |
| Idea 5: The Hidden Cost of Hospital Cons... | — | — | SKIP (60) |
| Idea 2: Does Federal "Underserved" Desig... | — | — | SKIP (54) |

---

## GPT-5.2

**Tokens:** 8042

### Rankings

**#1: Does 340B Drug Pricing Crowd Out Medicaid Patients? Cross-Payer RDD Evidence from Provider-Level Claims**
- Score: 74/100
- Strengths: Tight, policy-relevant mechanism (duplicate-discount prohibition → payer reallocation) in a live reform area, with a credible quasi-experiment (DSH cutoff) and a clever cross-payer outcome (Medicaid-to-Medicare billing) that sharpens interpretation. Strong “internal diagnostics” potential (categorical-eligibility placebo group; non-drug placebos; carve-in/out heterogeneity).
- Concerns: The DSH threshold has known bunching/manipulation risk; if sorting is severe, the RDD may be attacked even with donuts/sensitivity. T‑MSIS drug/encounter reporting quality varies by state and could differentially affect Medicaid measurement near the cutoff (especially if 340B status correlates with managed-care penetration or reporting).
- Novelty Assessment: **Moderate**—340B at the 11.75% cutoff is studied (e.g., Nikpay et al.; follow-on work), but the *Medicaid-specific* channel using T‑MSIS linked to Medicare is meaningfully less covered and directly targeted to the duplicate-discount mechanism.
- Top-Journal Potential: **Medium-High.** Not “new policy,” but potentially belief-changing if you can show a clear substitution channel (not just “340B increases drug use”) and quantify implications for Medicaid access. Best shot is a tight causal chain: eligibility → payer-specific administration shifts → downstream access/cost.
- Identification Concerns: Main threats are (i) endogenous manipulation of DSH % around 11.75%, (ii) compositional changes (hospital service line changes) that mechanically shift billing, and (iii) Medicaid measurement error correlated with hospital type/state. You’ll need strong density/continuity tests, donut/bandwidth robustness, and balance checks on pre-period outcomes.
- Recommendation: **PURSUE (conditional on: convincing no-manipulation case after donuts; demonstrating a strong first-stage—eligibility actually changes 340B participation; documenting T‑MSIS state-quality screens don’t drive results)**

---

**#2: Cross-Payer Spillovers at Medicare Payment Boundaries: Do Medicare Rate Cuts Starve the Medicaid Safety Net?**
- Score: 67/100
- Strengths: A “first-order stakes + legible channel” question (Medicare payment generosity → provider time allocation → Medicaid participation) with lots of internal replication across many within-state county borders. Linking Medicare PUF and T‑MSIS at the provider level is a real comparative advantage.
- Concerns: Treatment intensity may be small at many borders (few-percent GPCI differences), risking weak first-stage and “precise zero that isn’t informative” unless you focus on large discontinuities. Locality borders may coincide with metro/rural transitions (input costs, provider density trends) that affect Medicaid supply even absent Medicare pricing differences.
- Novelty Assessment: **Moderate-High**—there’s broad literature on Medicare payment and provider behavior, but *border-based Medicare price variation used to identify Medicaid spillovers at the provider level* is much less common, especially with modern administrative linkage.
- Top-Journal Potential: **Medium.** Could rise to top-field (AEJ:EP) if you (i) show economically meaningful reallocations for dual-billers and (ii) translate to access metrics or welfare-relevant scarcity (e.g., participation/availability), not just volume.
- Identification Concerns: Key threats are (i) border counties differing in unobservables correlated with locality assignment (even within state), (ii) sorting of providers across counties (practice addresses vs service locations), and (iii) spatially correlated shocks. Strong border-pair fixed effects, covariate continuity, and falsification boundaries (pseudo-borders) would be essential.
- Recommendation: **CONSIDER (upgrade to PURSUE if: you can pre-specify a “large discontinuity” sample; show clear first-stage in Medicare billings; and validate provider location measurement)**

---

**#3: Does Federal “Underserved” Designation Actually Attract Medicaid Home Care Providers? RDD at the MUA Threshold**
- Score: 62/100
- Strengths: High policy salience (designation drives multiple federal programs) and plausibly large stakes; a credible RDD *in principle* would be genuinely informative because policymakers treat the cutoff as meaningful. Medicaid HCBS supply is a good, understudied margin for these place-based designations.
- Concerns: The biggest risk is that this isn’t truly a sharp cutoff design in practice: MUA designation often reflects applications, updates/redesignations, and administrative discretion; “reconstructing IMU for all areas” may not match the score used in designation decisions (especially for sub-county MUAs). Also, one IMU component is physician supply, which is mechanically tied to local healthcare labor markets—raising concerns about continuity and interpretation even if HCBS is a different workforce.
- Novelty Assessment: **High**—surprisingly little clean causal work on whether MUA status actually changes provider supply on Medicaid-relevant margins (most discussion is descriptive/GAO-style).
- Top-Journal Potential: **Medium.** Could be exciting if you can show the designation is largely symbolic (or highly effective) *and* convincingly address the “designation is discretionary / not truly threshold-driven” critique. Otherwise it risks reading as a technical exercise in a messy institutional setting.
- Identification Concerns: (i) “Cutoff” may not govern assignment (fuzzy/administrative discretion), (ii) running variable measurement error (county proxies for non-county MUAs), and (iii) endogenous boundary definitions of MUAs. If it’s fuzzy, you’ll need an explicit FRD with documented compliance and strong first stage.
- Recommendation: **CONSIDER (conditional on: verifying that observed IMU at decision time predicts designation with a strong discontinuity; restricting to county MUAs where IMU is well-measured; and showing continuity of pre-trends in HCBS supply proxies)**

---

**#4: The Hidden Cost of Hospital Consolidation: 340B Eligibility and the Vertical Integration of Medicaid Drug Services**
- Score: 58/100
- Strengths: Uses the same credible quasi-experiment as Idea 1 but shifts to an organizational mechanism (site-of-care / billing integration) that is directly tied to spending and market power. T‑MSIS billing vs servicing NPI structure is a genuinely useful measurement angle.
- Concerns: This risks being viewed as “incremental extension” of an already-known 340B consolidation result (from Medicare) unless you can show something distinctly Medicaid-specific (e.g., access deterioration, shifting to hospital outpatient departments that changes cost-sharing/availability). Entity type and billing/servicing patterns can also reflect billing conventions and managed-care encounter idiosyncrasies rather than true vertical integration.
- Novelty Assessment: **Moderate-Low**—the consolidation angle around 340B is well-trodden; the Medicaid application is new-ish but may be perceived as a parallel replication unless the paper delivers a sharper mechanism or welfare consequence.
- Top-Journal Potential: **Low-Medium.** More likely a solid field-journal paper than top-5 unless you connect integration to a first-order welfare margin (waiting times, discontinuities in access for Medicaid, or strong spending pass-through).
- Identification Concerns: Same DSH manipulation threat as Idea 1 plus an added “construct validity” risk: the outcome (org vs individual NPI share; billing/servicing splits) may not cleanly map to ownership/integration without auxiliary validation (e.g., SK&A/IQVIA ownership data, PECOS group practice links, or hospital-physician affiliation files).
- Recommendation: **CONSIDER (conditional on: validating the integration measure against an external ownership/affiliation dataset; and pre-specifying an access/spending consequence beyond organizational shares)**

---

**#5: Nurse Practitioner Full Practice Authority and the Medicaid HCBS Workforce: A Border Discontinuity Design**
- Score: 52/100
- Strengths: Uses a large, policy-important regulatory lever with multiple borders (internal replication) and targets a relatively neglected outcome margin (HCBS/behavioral health billing on Medicaid). Good placebo logic (physicians; non-HCBS NP billing).
- Concerns: NP scope-of-practice is already a saturated literature; reviewers may see “yet another scope-of-practice paper,” especially if effects are unsurprising. Identification is also harder than it sounds: border comparisons are cross-state and confounded by big differences in Medicaid HCBS program design, reimbursement, and managed-care contracting; and several “new” FPA adoptions are post-2024, outside your outcome window, limiting clean event-study leverage.
- Novelty Assessment: **Low-Medium**—the *HCBS-specific* angle is novel, but the policy lever (FPA) has many existing quasi-experimental papers, making it harder to clear the novelty bar.
- Top-Journal Potential: **Low.** Without a sharp timing design (clean reforms within 2018–2024) or a truly surprising mechanism, this is likely to be viewed as competent-but-incremental.
- Identification Concerns: (i) cross-state confounding at borders (Medicaid generosity, licensing environment, HCBS waivers), (ii) provider location mismeasurement (NPPES address vs service location), and (iii) thin samples for NP HCBS billing near borders leading to weak precision and fragile inference.
- Recommendation: **SKIP (unless you can redesign around within-state timing shocks in 2018–2024 or obtain data that directly measure supervision/collaboration frictions rather than inferring them from billing)**

---

### Summary

This is a strong batch in terms of data ambition (T‑MSIS linkage ideas are a real asset) and mechanism thinking, but two proposals (MUA and NP-FPA) have substantial “institutional messiness / saturation” risk. If you can only start one immediately, start with **Idea 1** (most coherent mechanism + credible design + live policy debate), and keep **Idea 4** as the next-best scalable project if you can verify economically meaningful GPCI discontinuities and a strong first stage.

---

## Gemini 3.1 Pro

**Tokens:** 10093

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in empirically observed editorial preferences for top economics journals.

### Rankings

**#1: Idea 1: Does 340B Drug Pricing Crowd Out Medicaid Patients? Cross-Payer RDD**
- **Score**: 84/100
- **Strengths**: Tests a highly credible, first-order cross-payer substitution mechanism (the duplicate discount prohibition) using a massive new linked dataset. The proposed falsification tests (categorically eligible hospitals, non-drug billing) are perfectly tailored to kill the most likely confounders.
- **Concerns**: The Medicaid-to-Medicare billing ratio could be noisy at the provider-month level, and the known bunching at the 11.75% threshold requires careful econometric handling.
- **Novelty Assessment**: High. While the 340B RDD is well-known, the Medicaid-specific crowd-out channel is entirely unstudied and represents a major "trade-off discovery."
- **Top-Journal Potential**: High. This fits the winning editorial pattern of linking a specific policy shock to a concrete welfare margin (Medicaid access) via a legible causal channel. It fundamentally changes how the field views the "benefits" of the 340B program by exposing a hidden tax on the safety net.
- **Identification Concerns**: Density manipulation (bunching) at the DSH threshold is a known threat; the donut RDD must be robust and the McCrary test must pass cleanly.
- **Recommendation**: PURSUE (conditional on: passing McCrary density tests with the donut specification; demonstrating a clear first stage in 340B participation).

**#2: Idea 4: Cross-Payer Spillovers at Medicare Payment Boundaries**
- **Score**: 65/100
- **Strengths**: Asks a massive, policy-relevant question about cross-payer spillovers using a spatial RDD that offers internal replication across over 100 boundaries. 
- **Concerns**: GPCI payment differences across adjacent counties are often minuscule (1-2%), which may fail to induce a measurable behavioral response, leading to an uninterpretable, underpowered null.
- **Novelty Assessment**: Medium-High. The theoretical mechanism is widely discussed, but large-scale, provider-level causal evidence is scarce.
- **Top-Journal Potential**: Medium. If the first stage has bite and you find a substitution effect, it's a top-tier paper. However, if the payment shock is too small, it will fall into the "underpowered null" trap that editors routinely reject.
- **Identification Concerns**: County borders frequently align with MSA or labor market boundaries, meaning unobserved local economic shocks could easily confound the spatial RDD.
- **Recommendation**: CONSIDER (conditional on: verifying that GPCI payment differences at the chosen borders are economically large enough to plausibly shift provider behavior).

**#3: Idea 2: MUA Designation and Medicaid Home Care Providers**
- **Score**: 52/100
- **Strengths**: Attempts to evaluate a multi-billion dollar, under-studied federal designation using a sharp RDD on a continuous index.
- **Concerns**: Reconstructing the historical IMU score is notoriously difficult, and the index itself includes provider supply, creating mechanical endogeneity.
- **Novelty Assessment**: Medium. MUA evaluations exist, though the Medicaid HCBS angle is relatively fresh.
- **Top-Journal Potential**: Low. This reads as a standard RDD on a broad rollout. Without a surprising mechanism or a tight causal chain, it will likely be viewed as "competent but not exciting."
- **Identification Concerns**: Severe circularity risk because the running variable (IMU) is partially constructed from the outcome concept (provider supply), plus fuzzy treatment application due to grandfathered MUAs.
- **Recommendation**: SKIP

**#4: Idea 3: NP Full Practice Authority Border RDD**
- **Score**: 46/100
- **Strengths**: Uses a border discontinuity design to isolate state-level regulatory shocks on a specific, under-studied workforce (Medicaid HCBS).
- **Concerns**: Scope of practice is a heavily saturated literature, and border RDDs for occupational licensing often suffer from severe SUTVA violations (providers commuting across borders).
- **Novelty Assessment**: Low. The HCBS angle is new, but the NP FPA shock has been studied to death.
- **Top-Journal Potential**: Low. This is a classic "technically competent but not exciting" paper. It delivers another ATE on a saturated topic without revealing a new theoretical mechanism.
- **Identification Concerns**: Cross-border spillovers (NPs living in restricted states commuting to FPA states) will bias the estimates and violate SUTVA.
- **Recommendation**: SKIP

**#5: Idea 5: 340B Consolidation and Medicaid Drug Services**
- **Score**: 40/100
- **Strengths**: Uses a proven identification strategy (DSH RDD) and novel T-MSIS billing/servicing NPI linkages to observe organizational structure.
- **Concerns**: This is essentially a pure replication of Nikpay et al. (2018) but swapping Medicare data for Medicaid data.
- **Novelty Assessment**: Very Low. The exact mechanism (340B inducing hospital-physician consolidation) is already established in a top medical journal.
- **Top-Journal Potential**: Low. Economics journals heavily discount papers that merely replicate known mechanisms on new subpopulations without a new theoretical insight or welfare reversal.
- **Identification Concerns**: Same bunching concerns as Idea 1, but without the novel cross-payer substitution angle to justify the effort.
- **Recommendation**: SKIP

### Summary

This batch contains one outstanding proposal (Idea 1) that perfectly aligns with top-journal preferences for legible causal channels and trade-off discoveries. Idea 4 is a high-risk, high-reward alternative that hinges entirely on the size of the first-stage payment shock, making it worth a preliminary data exploration. The remaining ideas (2, 3, and 5) suffer from either saturated literatures, fatal identification flaws, or a lack of theoretical novelty, and should be discarded to focus institute resources on the 340B cross-payer project.

---

## Grok 4.1 Fast

**Tokens:** 6591

### Rankings

**#1: Idea 1: Does 340B Drug Pricing Crowd Out Medicaid Patients? Cross-Payer RDD Evidence from Provider-Level Claims**
- Score: 78/100
- Strengths: Uncovers a novel Medicaid-specific crowding-out mechanism in a hot policy debate using universe-level cross-payer claims data (T-MSIS + Medicare PUF), with strong RDD design including falsification tests and manipulation diagnostics. Clear substitution channel (duplicate discount prohibition → payer shift) that fits editorial preferences for trade-off discovery and legible causal chains.
- Concerns: Bunching near cutoff (even with donut hole) could still bias if strategic behavior persists; post-2018 window misses earlier dynamics.
- Novelty Assessment: High—Nikpay (2018) hit total drugs/consolidation, but no prior work on Medicaid channel or cross-payer NPI linkage.
- Top-Journal Potential: High—top-5 potential via "substitution offset" in familiar policy (340B reform), universe data scale, and mechanism map (incentive → payer mix → access trade-off); echoes winners like ransomware pass-through or crime pricing.
- Identification Concerns: Threshold manipulation (Bai 2021) addressed but not eliminated; needs robust pre-trends on Medicaid/Medicare ratio despite multi-period data.
- Recommendation: PURSUE (conditional on: strong first-stage on non-Medicaid drugs; powered nulls on placebos)

**#2: Idea 3: Nurse Practitioner Full Practice Authority and the Medicaid HCBS Workforce: A Border Discontinuity Design**
- Score: 68/100
- Strengths: Targets unstudied Medicaid HCBS angle on NP FPA with internal replication across multiple borders and clean placebos (physicians, non-HCBS); T-MSIS exclusivity adds measurement value for constrained workforce.
- Concerns: Thin NP billing in border counties risks underpower; recent FPA adoptions (2024-2026) limit pre/post windows and invite anticipation bias.
- Novelty Assessment: High—no papers link FPA to Medicaid HCBS supply via NPs; prior lit is patient-focused or Medicare.
- Top-Journal Potential: Medium—exciting boundary test for scope-of-practice puzzle if supply shift → access chain emerges, but "competent RDD on employment analog" risks modal loss without counterintuitive welfare pivot.
- Identification Concerns: Border counties not perfectly comparable (e.g., urban/rural mismatch); spatial sorting of NPs could confound distance running variable.
- Recommendation: CONSIDER

**#3: Idea 4: Cross-Payer Spillovers at Medicare Payment Boundaries: Do Medicare Rate Cuts Starve the Medicaid Safety Net?**
- Score: 64/100
- Strengths: Tests theorized cross-payer mechanism (Medicare opportunity cost → Medicaid participation) with multiple boundaries for replication and novel T-MSIS/PUF linkage.
- Concerns: GPCI diffs at borders often trivial (few %), yielding weak first-stage; spatial error correlation demands careful clustering.
- Novelty Assessment: Medium-high—cross-payer spillovers theorized but untested at provider level with admin data.
- Top-Journal Potential: Medium—legible channel (payment → dual-provider behavior) with policy stakes, but small bite and "border RDD on billing" may read as technically sound but unsurprising without large effects.
- Identification Concerns: Locality boundaries administrative but may proxy market differences; needs placebo on single-payer providers.
- Recommendation: CONSIDER (conditional on: meaningful GPCI gaps at ≥20% of borders; verified first-stage)

**#4: Idea 5: The Hidden Cost of Hospital Consolidation: 340B Eligibility and the Vertical Integration of Medicaid Drug Services**
- Score: 60/100
- Strengths: Leverages same clean RDD as Idea 1 for Medicaid extension of Nikpay consolidation, using T-MSIS billing/servicing NPI structure for organizational insight.
- Concerns: Less novel piggyback on existing RDD/paper; Medicaid consolidation may not differ enough from Medicare to excite.
- Novelty Assessment: Medium—direct extension of Nikpay (2018) to Medicaid; mechanism studied but payer-specific unstudied.
- Top-Journal Potential: Low—solid but "another ATE on 340B consolidation" without belief-changing pivot; risks "competent but not exciting" dismissal despite trade-off.
- Identification Concerns: Same strong RDD as Idea 1, but outcome (entity type shift) may lag eligibility, inviting dynamics issues.
- Recommendation: SKIP

**#5: Idea 2: Does Federal "Underserved" Designation Actually Attract Medicaid Home Care Providers? RDD at the MUA Threshold**
- Score: 54/100
- Strengths: First causal evidence on MUA effects despite billions spent; policy-direct for HRSA methodology review.
- Concerns: IMU circularity (includes providers) undermines exogeneity; geographic units messy, uncertain density at cutoff risks underpower.
- Novelty Assessment: High—truly first causal on MUA provider supply.
- Top-Journal Potential: Low—niche designation test lacks first-order stakes or substitution punch; "does threshold work?" risks underpowered null without scale or chain.
- Identification Concerns: Endogenous running variable (IMU embeds outcome population); non-county MUAs complicate aggregation and inference.
- Recommendation: SKIP

### Summary
This is a strong batch overall, with multiple clean designs exploiting T-MSIS for Medicaid innovation and cross-payer mechanisms that align with editorial wins on substitutions/trade-offs. Pursue Idea 1 first for its novelty, identification, and top-journal excitement on 340B crowding out; Ideas 3 and 4 warrant consideration if diagnostics confirm power and bite.

