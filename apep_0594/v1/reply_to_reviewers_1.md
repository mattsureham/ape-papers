# Reply to Reviewers

**Paper:** The Illusion of Permanence: Relabeling vs. Real Reform in Spain's 2022 Temporary Contract Ban
**Paper ID:** apep_0594 v1
**Date:** 2026-03-11

We thank all three reviewers for their thorough and constructive engagement. Below we address each major concern, organized by theme.

---

## Theme 1: Design Terminology (R1 #1, R2 #4)

**Concern:** The paper mislabels the design as "shift-share" when it is a continuous-treatment DiD.

**Response:** We agree. The revised paper now consistently describes the design as a "continuous-treatment difference-in-differences" throughout. References to Goldsmith-Pinkham et al. and Borusyak et al. are retained only for context on exposure-based designs, not as methodological justification for a Bartik framework. The terminology in the abstract, empirical strategy, and discussion sections has been updated accordingly.

---

## Theme 2: Mean Reversion and Treatment Endogeneity (R1 #1A, R2 #1.1, R2 #5)

**Concern:** Using 2021 baseline temporary share as treatment intensity creates mean-reversion risk, especially given bounded outcomes and post-COVID normalization.

**Response:** We acknowledge this as a genuine limitation and have added a dedicated paragraph in the Threats to Validity section (Section 4.2) discussing mean reversion explicitly. Three pieces of evidence mitigate this concern:

1. **Region-specific linear trends:** Adding region-specific linear trends yields beta = -0.250 (SE = 0.117), similar to the baseline and significant — suggesting the effect is not driven by pre-existing convergence dynamics (Appendix C).
2. **Flat pre-reform event study:** The 45 pre-treatment coefficients show no downward drift in high-exposure regions over the 11-year pre-period (2010Q4-2021Q4). If mean reversion were the primary driver, we would expect to see gradual convergence before the reform.
3. **COVID exclusion:** Dropping 2020-2021 entirely yields beta = -0.208 (SE = 0.235), comparable in magnitude though less precise with the reduced sample (Appendix C).

We agree that using pre-2020 treatment intensity (e.g., 2018-2019 average) would strengthen the design. This is noted as a limitation and a direction for future work. However, we note that Spain's regional temporary employment share rankings are extremely stable over time — the cross-sectional variation is driven by structural factors (agriculture, tourism, construction dependence) that change slowly.

---

## Theme 3: Parallel Trends and Event Study (R1 #1B, R2 #1.2)

**Concern:** The pre-trend F-test (p=0.999) is uninformative with 45 coefficients and 19 clusters. Pre-trends cannot rule out differential post-2022 shocks.

**Response:** We agree that the F-test has low power in this setting and should not be over-interpreted. The revised paper uses more cautious language: "the event study reveals no visually apparent differential pre-trends" rather than claiming parallel trends are "validated." We acknowledge that pre-trend stability does not rule out contemporaneous confounders.

The event study's primary value is visual — showing a clear break at the reform date with no prior drift. We present it as supportive rather than definitive evidence.

**On binned leads/lags:** With quarterly data over 11 pre-treatment years, a parsimonious binned specification would sacrifice the visual granularity that makes the event study informative. We note this as a design choice.

---

## Theme 4: Weighted Specification Inference (R1 #2A, R2 #2.1-2.2, Gemini #1)

**Concern:** The population-weighted estimate (beta = -0.462) lacks wild bootstrap inference and may be driven by a few large regions.

**Response:** The revised paper now reports the wild cluster bootstrap p-value for the weighted specification: p = 0.009 (Table 2, Column 3). This confirms the weighted result survives few-cluster inference. Additionally, the leave-one-out analysis (Figure 5) shows the unweighted estimate is stable across all 19 region exclusions, with no single region driving the sign or magnitude.

We agree that the divergence between unweighted (imprecise) and weighted (precise) results warrants transparent discussion. The revised paper explicitly notes that weighting shifts the estimand from an average regional effect to an effect weighted by labor market size, and that the stronger weighted result may reflect genuine heterogeneity — larger, more diversified regional economies may have implemented the reform more completely — rather than pure precision gains. We present both estimates without elevating either as "preferred."

---

## Theme 5: Relabeling Claim Calibration (R1 #3C, R2 #1.5, R2 #5.1, Gemini #2)

**Concern:** A null employment effect does not prove relabeling. The paper overstates the mechanism.

**Response:** We fully agree this was the most important recalibration needed. The revised paper:

1. Removes categorical language ("labeling exercise," "changed labels, not jobs") throughout.
2. Reframes the conclusion as: "The evidence is consistent with substantial contract relabeling" rather than asserting relabeling as established fact.
3. Acknowledges explicitly that contract conversion to fijo discontinuo could represent genuine improvement in worker protections (recall rights, seniority, unemployment insurance access) even if headcount is unchanged.
4. Presents the total employment null as "one informative but limited margin" rather than a definitive test.
5. Notes that direct evidence on fijo discontinuo take-up, tenure distributions, wages, and worker flows would be needed to fully distinguish relabeling from genuine quality improvement.

**On Gemini's point about legal rights:** We have added language noting that fijo discontinuo status confers meaningful legal protections. Even if the work remains seasonal, the right of recall and seniority accumulation represent real improvements over the prior temporary-contract status quo.

---

## Theme 6: Robustness Scope (R1 #3A, R2 #3.1)

**Concern:** Robustness checks address timing but not the main threat of sectoral confounding.

**Response:** The revised paper adds three new robustness checks:

1. **Region-specific linear trends:** beta = -0.250 (SE = 0.117) — effect survives.
2. **Exclude COVID quarters (2020-2021):** beta = -0.208 (SE = 0.235) — similar magnitude.
3. **Weighted bootstrap:** p = 0.009 — robust.

We acknowledge that sector-composition controls interacted with time would be the gold standard but require region-sector panel data that the EPA tables do not provide at this granularity. This is noted as a limitation and motivation for future work with administrative (MCVL) data.

---

## Theme 7: Sector Evidence (R1 #3B, R2 #3.2)

**Concern:** The sector analysis is descriptive national time series, not causal.

**Response:** We agree and have ensured the paper labels Table 3 and Figure 4 as descriptive evidence "consistent with" the relabeling channel rather than causal confirmation. The revised text states: "While these patterns are suggestive, they are descriptive and cannot distinguish reform effects from sector-specific normalization dynamics."

---

## Theme 8: Literature (R1 #4B, R2 #4.2-4.3)

**Concern:** Missing engagement with modern DiD literature (Roth, Rambachan-Roth) and Spain-specific reform evidence.

**Response:** The revised paper includes citations to Roth (2022) on pre-test limitations and acknowledges that our pre-trend test should be interpreted cautiously. We cite the Bank of Spain's reform analysis and note the emerging administrative evidence. Full engagement with de Chaisemartin-D'Haultfoeuille, Rambachan-Roth, and Callaway-Goodman-Bacon-Sant'Anna would be valuable in a subsequent revision with richer data.

---

## Theme 9: Broader Analogies (R2 #5.4)

**Concern:** The conclusion draws analogies to finance, environment, and drug policy that exceed the evidence.

**Response:** The revised paper removes the drug policy analogy entirely and tones down remaining cross-domain comparisons. The conclusion now focuses on labor market regulation and contract design.

---

## Summary of Changes Made

| Issue | Status |
|-------|--------|
| Reframe as continuous-treatment DiD | Done |
| Add mean reversion discussion | Done |
| Add region-specific trends robustness | Done (beta = -0.250) |
| Add COVID exclusion robustness | Done (beta = -0.208) |
| Add weighted bootstrap p-value | Done (p = 0.009) |
| Tone down relabeling claims | Done throughout |
| Acknowledge fijo discontinuo legal benefits | Done |
| Label sector evidence as descriptive | Done |
| Remove drug policy analogy | Done |
| Cautious pre-trend language | Done |
| Present weighted/unweighted estimates equally | Done |

## Items Deferred to Future Work

| Item | Reason |
|------|--------|
| Pre-2020 treatment intensity | Requires re-running analysis with different Zr; regional rankings are stable |
| Region-sector panel | EPA data not available at this granularity |
| Direct fijo discontinuo measurement | Requires MCVL administrative data |
| Wages, tenure, hours outcomes | Requires linked worker-level administrative data |
| Binned event study | Design choice: quarterly granularity preferred for visualization |
