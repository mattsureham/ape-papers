# Reply to External Reviewers (Stage C)

## Reviewer 1 (GPT-5.2): MAJOR REVISION

### 1.1 Counterfactual credibility (B1 vs B2/C)
> B1 and B2/C are systematically different market types... the counterfactual can fail if B1 and B2/C respond differently to nationwide shocks.

**Response:** Added new paragraph to Section 4.1 discussing the limitation and noting région×year FE, employment-zone×year FE, and adjacency designs as valuable extensions. The border sample partially addresses geographic confounders but we are transparent that it is not a true boundary design.

### 1.2 Treatment coding: Post2018 vs Post2020
> Is the post-2020 coefficient incremental relative to 2018–2019, or relative to pre-2018?

**Response:** Added explicit language in Section 5.3: "Post2018 and Post2020 are coded as *mutually exclusive* indicators: Post2018 = 1 for 2018-2019 only, and Post2020 = 1 for 2020-2023 only."

### 1.3 SUTVA / spillovers estimand
> Your estimand is not clearly defined.

**Response:** Rewrote SUTVA paragraph to define estimand as the equilibrium effect inclusive of local demand reallocation. Noted spillover-distance event studies as future direction.

### 2.1 Spatial correlation inference
> Report Conley SEs, wild cluster bootstrap.

**Response:** Added discussion of Conley (1999) spatial HAC SEs and Bertrand et al. (2004) to Section 4.1. Acknowledged as valuable extension requiring commune coordinates.

### 2.2 Event-study pre-trend testing
> Report joint test statistic in main figures.

**Response:** Added F-test reference in Figure 3 notes. Added Roth (2022) citation on limitations of pre-trend tests.

### 2.3 Selection into price sample
> Major: N=8,033 vs 167,719.

**Response:** Added new "Selection into the price sample" paragraph in Section 4.3, discussing the concern and suggesting event studies on observation probability and higher-level aggregation.

### 2.4 VEFA underpowered
> N=596 is extremely small.

**Response:** Substantially revised Section 5.4: flagged <8% coverage, acknowledged selection bias, changed language to "suggestive rather than definitive." Abstract revised to include caveat.

### 3.1 Region×year FE
> Cannot implement without re-running analysis. Discussed as extension.

### 5.1 Welfare/incidence overclaiming
> PTZ is a loan subsidy; relevant amount is PV of interest savings.

**Response:** Rewrote Section 7.1 to use PV of interest savings (€5,000-€15,000) rather than loan principal. Capitalization rate becomes 12-35% — more meaningful. Added caveats about unobserved take-up.

### 5.2-5.3 Softened claims
**Response:** Changed mechanism language throughout from definitive to "consistent with" / "suggestive." Softened volume interpretation. Abstract revised.

---

## Reviewer 2 (Grok-4.1-Fast): MINOR REVISION

- **Pre-trend F-test:** Added reference in Figure 3 notes.
- **Missing cites:** Added Mense et al. (2023), Bertrand et al. (2004), Conley (1999).
- **B2 vs C heterogeneity:** Strengthened discussion in Section 5.6; noted formal interaction test as priority for future work.
- **VEFA limitations:** Addressed via expanded Section 5.4 discussion.

---

## Reviewer 3 (Gemini-3-Flash): MINOR REVISION

- **Heterogeneity table:** Noted as future work requiring re-analysis.
- **Commercial placebo:** Already honestly framed; maintained current discussion.
- **VEFA selection:** Added extensive discussion in Section 5.4.

---

## Exhibit Review Changes

- Moved Figures 5 (volume ES) and 7 (no-COVID ES) to appendix per recommendation
- Figures 2 (y-axis label) and 4 (colorblind patterns) require figure regeneration; flagged for future revision

## Prose Review Changes

- Sharpened opening hook with vivid tension framing
- Deleted roadmap paragraph
- Rewrote results sentences to lead with facts
- Active voice in Data and Background sections
- Added punchy section endings in mechanism and conclusion
