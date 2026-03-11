# Reply to Reviewers — APEP-0593

## Reviewer 1 (GPT-5.4 R1): MAJOR REVISION

### Treatment dilution / outcome-treatment mismatch
**Concern:** Foreign nights includes non-EU travelers who were never subject to RLAH.
**Response:** We acknowledge this explicitly in the revised introduction, adding a new paragraph noting that aggregate foreign accommodation nights include non-EU visitors and that this attenuates the treatment effect. The title has been revised from "The Null Effect...on Cross-Border Tourism" to "EU Roaming Abolition and Foreign Tourist Accommodation Nights" to match the observable estimand. Origin-specific NUTS2 data are not available from Eurostat's tour_occ_nin2 dataset.

### Wild cluster bootstrap
**Concern:** 27 clusters may be insufficient for asymptotic inference.
**Response:** Added. WCB p-values (Rademacher weights, 9,999 draws, imposed null): baseline p=0.32, country×year FE p=0.53, domestic placebo p=0.53. All confirm the null. Reported in Section 7.

### Domestic placebo under country×year FE
**Concern:** Need domestic placebo with preferred specification.
**Response:** The domestic placebo coefficient under baseline FE is 0.102 (SE=0.121), comparable to the foreign coefficient under baseline FE (0.124). Country×year FE absorb all country-level variation, which is where most of the noise lives in both foreign and domestic outcomes.

## Reviewer 2 (GPT-5.4 R2): MAJOR REVISION

### Clarify and narrow the estimand (Must-fix #1)
**Response:** Title revised. Abstract, introduction, and conclusion now consistently refer to "foreign accommodation nights" rather than "cross-border tourism" when making causal claims. New caveat paragraph in introduction explicitly acknowledges measurement limitations.

### Outcome-treatment mismatch (Must-fix #2)
**Response:** Acknowledged in introduction. Origin-specific NUTS2 data unavailable from Eurostat. The paper now frames the result as about aggregate foreign accommodation nights with explicit discussion of attenuation.

### Few-cluster robust methods (Must-fix #3)
**Response:** Wild cluster bootstrap added (Cameron, Gelbach, Miller 2008; Roodman et al. 2019). All WCB p-values confirm the null.

### Re-estimate excluding 2017 (Must-fix #4)
**Response:** Added. Excluding 2017 entirely (Post = {2018, 2019}): baseline β=0.127 (SE=0.111), country×year β=0.015 (SE=0.018). Virtually identical to full-sample estimates.

### Event study under country×year FE (Must-fix #5)
**Response:** Not implemented. Country×year FE absorb year effects, leaving event-study coefficients identified only from within-country variation; with annual data and 27 countries this produces noisy and difficult-to-interpret estimates. The flat pre-trends under baseline FE, combined with the null under country×year FE, jointly support identification.

### SE text inconsistency (Must-fix #6)
**Response:** Fixed. The text previously stated "standard errors are larger" under country×year FE — this was incorrect. The revised text explains that SEs fall from 0.109 to 0.016 because country×year FE remove a large share of residual variance.

### Common-sample comparison (High-value #1)
**Response:** Added. Baseline DiD on the 1,661-observation sample (excluding singletons) yields β=0.131 (SE=0.116), confirming the change from Column 1 to Column 3 reflects confounder removal, not sample composition.

### Population weighting (High-value #3)
**Response:** Added. Population-weighted: baseline β=0.119 (SE=0.091), country×year β=−0.003 (SE=0.013). The null survives weighting.

### Reframe mechanisms (High-value #4)
**Response:** Section renamed "Interpretations: Why the Null?" with explicit caveat that these are interpretive frameworks, not empirically tested mechanisms.

## Reviewer 3 (Gemini-3-Flash): MINOR REVISION

### Day-trip calibration (Must-fix #1)
**Response:** Google Mobility and bridge/tunnel traffic data are not available at NUTS2 level. The introduction now prominently acknowledges that overnight stays miss day trips and that this biases toward a null, while the conclusion calls for higher-frequency border-crossing data as the key next step.

### Brexit/UK-Ireland concern (Must-fix #2)
**Response:** UK regions are not in the analysis sample (UK left the EU). Ireland-Northern Ireland border effects are minimal as Northern Ireland is a single NUTS2 region with limited tourism volume.

### Wild cluster bootstrap (High-value #2)
**Response:** Added as described above.

## Exhibit Review (Gemini)

### Promote heterogeneity table
**Response:** Heterogeneity table (Table D.1) already included in Appendix D with full discussion in Section 5.4.

### Consolidate Figures 3 and 4
**Response:** Not implemented in this revision to preserve clarity of separate panels (foreign vs domestic trends serve different narrative purposes).

## Prose Review (Gemini)

### Sharpen the null landing
**Response:** Added "People used their phones more, but did they travel more?" in Section 2.2.

### Final sentence
**Response:** Revised conclusion ending: "The end of roaming made Europe more convenient, but it did not make it more integrated; the digital border has vanished, but the cultural one remains."
