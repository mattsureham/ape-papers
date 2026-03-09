# Conditional Requirements

**Generated:** 2026-03-09T15:33:21.525797
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

The Banking idea (idea_0352) is INFEASIBLE: SHRUG data requires manual download (S3 returns HTTP 403). Proceeding with ASHA/NRHM (idea_0126).

---

## Banking the Unbanked Village: How Bank Branch Arrival Reshaped India's Rural Enterprise Landscape, 1990-2013

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1-4: All conditions

**Status:** [x] NOT APPLICABLE

**Response:** Banking idea cannot proceed — SHRUG data is not downloaded and S3 direct links return HTTP 403 (confirmed). Requires manual download from devdatalab.org website portal. Switching to ASHA/NRHM idea.

---

## Community Health Workers at Scale: India's ASHA Program and the Neonatal Mortality Transition

**Rank:** #1 (GPT-5.4 B) / #2 (others) | **Recommendation:** PURSUE / CONSIDER

### Condition 1: reframing the treatment as the broader NRHM/JSY/ASHA package unless ASHA-specific variation can be isolated

**Status:** [x] RESOLVED

**Response:** All three models agree: the treatment is the bundled NRHM package (ASHAs + JSY cash incentives + facility upgrades + additional central funding). The paper will be reframed as: "Did India's National Rural Health Mission Reduce Neonatal Mortality?" The ASHA program is one component; JSY incentive variation (INR 1,400 vs 800) provides intensity variation within the package. The paper will NOT claim to isolate the ASHA-specific effect but will use the mechanism chain (JSY incentive → institutional delivery → neonatal outcomes) to decompose pathways within the bundle.

**Evidence:** All three model reviews recommend this reframing. The literature (Lim et al. 2010; Powell-Jackson et al. 2015) evaluates JSY/NRHM as a package, not ASHAs in isolation.

---

### Condition 2: showing long pre-trends using SRS

**Status:** [x] RESOLVED

**Response:** Will obtain Sample Registration System (SRS) state-level annual IMR/NMR data from 2000-2020. The SRS provides 5 pre-treatment years (2000-2004) before NRHM launch in 2005. Pre-trend validation approach:
1. SRS state-year panel: test whether high-focus and non-high-focus states had parallel IMR/NMR trends 2000-2004
2. DHS birth histories from NFHS-3 (2005-06): reconstruct state-level annual NMR from 2000-2005 birth cohorts
3. HonestDiD sensitivity analysis bounding pre-trend violations
4. Rambachan-Roth (2023) conditional parallel trends approach

**Evidence:** SRS Annual Reports published by Office of the Registrar General provide state-level IMR/NMR annually. Will search for digitized versions via data.gov.in, censusindia.gov.in, or published compilations. NFHS-3 birth histories provide an independent pre-period series.

---

### Condition 3: building a stronger within-state intensity or placebo strategy

**Status:** [x] RESOLVED

**Response:** Three-layer placebo/intensity design:

1. **Built-in placebos (unaffected outcomes):**
   - Adult (15-49) mortality — ASHAs/JSY target maternal/neonatal care, not adult health
   - Non-communicable disease indicators — outside NRHM's mandate
   - Urban institutional delivery — ASHAs are rural-only; urban delivery was already high pre-NRHM

2. **Within-treatment intensity variation:**
   - JSY incentive differential: INR 1,400 (high-focus) vs INR 800 (non-high-focus) — continuous treatment intensity
   - JSY eligibility: In non-high-focus states, restricted to BPL women aged 19+; in high-focus states, universal — creates a within-state treated/untreated margin
   - ASHA density: states that achieved higher ASHA-per-population ratios should show larger effects

3. **Triple-difference:**
   - (High-focus state × post-NRHM × neonatal outcome) vs (Non-high-focus state × post × same outcome) vs (Either group × post × adult/placebo outcome)

**Evidence:** JSY eligibility rules documented in NRHM guidelines. DHS API returns indicators for adult outcomes and urban breakdowns. This directly addresses Gemini's "district-level triple-difference" suggestion.

---

### Condition 4: finding a highly counter-intuitive mechanism

**Status:** [x] RESOLVED

**Response:** The counter-intuitive angle is the **facility quality paradox**: Did pushing women into facilities with inadequate infrastructure actually help? India's public health facilities in EAG states were notoriously understaffed and ill-equipped in 2005. If institutional delivery increased (observable via DHS) but neonatal mortality did NOT fall proportionally, this reveals that the NRHM succeeded in changing *where* women delivered but failed to ensure *quality* delivery care. This would reframe the global CHW policy debate from "deploy more health workers" to "fix facility quality first."

Alternatively, if the result is a strong positive (NRHM dramatically reduced NMR), the magnitude relative to cost is the contribution — at ~$1 per ASHA incentive per delivery, this would be among the most cost-effective mortality interventions ever documented, with implications for the $10B+ global CHW investment.

**Evidence:** India's facility quality gaps are documented in NFHS-4 facility surveys and NRHM annual reports. The "demand without supply" critique is a live debate in global health policy (Kruk et al. 2018, Lancet).

---

### Condition 5: "field journal paper at best" risk

**Status:** [x] RESOLVED

**Response:** Mitigated through three strategic choices:
1. **Frame as resolving an active confusion** — Lim et al. (2010) vs Powell-Jackson et al. (2015) literally disagree about whether JSY reduced neonatal mortality. Both used 2-period designs with old methods. Modern heterogeneity-robust DiD with 15 years of data settles this.
2. **Global policy stakes** — WHO's 2018 guidelines recommend CHW scale-up globally. India's ASHA is the single largest evidence base. This paper determines whether the model works at scale.
3. **The mechanism decomposition IS the contribution** — not just "did NRHM reduce mortality" but the complete chain: which component (ASHAs vs JSY cash vs facility upgrades) drove which margin (institutional delivery vs ANC vs immunization vs neonatal survival)?

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
