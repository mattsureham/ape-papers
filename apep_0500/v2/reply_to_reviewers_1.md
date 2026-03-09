# Reply to Reviewers — apep_0500 v2

## Round 1 External Reviews

### GPT-5.4 (R1) — Major Revision

**Key concerns addressed:**

1. **Effective sample caveat (Section 1.1)**: Added explicit framing in abstract and introduction that the DDD is identified from 12 states (6 treated, 6 control) with mixed pastoral/non-pastoral composition. The estimate is described as "local to mixed-composition states" rather than a national average.

2. **Pastoral classification endogeneity (Section 1.2)**: Acknowledged more explicitly in limitations. The geography-only classification collinearity is documented. The conflict-only robustness check (positive, insignificant) is presented as informative but not dispositive. Future work with spatially granular livestock density data is noted as the path forward.

3. **DDD identifying assumption tests (Section 1.3)**: The DDD event study (Figure 7) is maintained as the relevant diagnostic. A formal joint pre-trends test remains infeasible due to singular covariance with few cohorts; this limitation is stated explicitly.

4. **Treatment definition (Section 1.4)**: Added explicit language throughout (empirical strategy, conclusion) that the treatment is a reduced-form effect of adoption timing, bundling the law with subsequent enforcement and political signaling.

5. **Inference concerns (Section 2.1)**: The RI p-value of 0.183 is presented more honestly, with the structural centering explanation maintained but the discrepancy with cluster-robust SEs acknowledged as a genuine limitation rather than dismissed.

6. **Mechanism over-claiming (Section 3.6)**: Substantially revised. "Rules out displacement" replaced with "inconsistent with large-scale displacement on tested margins." "Unambiguous" replaced with "consistent with deterrence." Added explicit caveat that evidence is indirect.

7. **Policy over-claiming**: Revised conclusion to use "associated with" rather than "can reduce," and added conditionality to policy recommendations.

### GPT-5.4 (R2) — Major Revision

**Key concerns addressed:**

1. **Same effective sample, inference, and classification issues as R1** — addressed as above.

2. **Displacement specification ambiguity (Section 3.3)**: Equation 2 now explicitly shows staggered structure with $D_{s(i),t}$ notation.

3. **"Precise null" language (Section 3.5)**: Removed "precise null" throughout, replaced with "null" or "no detectable effect."

4. **Claim calibration (Section 5)**: All major claims recalibrated. Displacement described as "not detected on tested margins" rather than "ruled out."

### Gemini-3-Flash — Minor Revision

**Key concerns addressed:**

1. **RI discrepancy (Item 1)**: RI p-value harmonized to 0.183 throughout (was inconsistently reported as 0.034 in some locations from v1 artifacts).

2. **Enclosure framework (Item 2)**: Added Hornbeck (2010) reference and enclosure/property-rights framing in the literature contribution paragraph.

3. **TWFE bias discussion (Item 3)**: The DDD structure's protection against negative weighting is already noted in the methodology discussion.

## Changes Not Made

- **Violence-free pastoral classification**: Requires GLW4 cattle density raster data that was unavailable (Harvard Dataverse redirect). Noted as priority for future revision.
- **Monthly/quarterly panel**: UCDP GED supports finer temporal resolution but would require re-running the entire analysis pipeline. Noted for future work.
- **Actor-coded farmer-herder events**: UCDP actor coding does not cleanly separate farmer-herder from other non-state violence. Acknowledged in limitations.
- **State-by-state leverage decomposition**: Would require custom influence diagnostics beyond standard fixest output. The effective sample table partially addresses this.
