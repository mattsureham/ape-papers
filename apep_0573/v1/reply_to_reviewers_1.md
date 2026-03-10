# Reply to Reviewers — apep_0573/v1

## Reviewer 1 (GPT-5.4 R1): REJECT AND RESUBMIT

### 1.1 Treatment timing misalignment (legal transposition vs. actual implementation)
**Response:** We acknowledge this is the most serious limitation. We have added a new first limitation in Section 6.4 explicitly discussing the gap between legal transposition and actual implementation dates. We now characterize our results as "reduced-form associations with transposition timing" rather than structural effects of specific reform provisions. This reframing appears throughout the abstract, introduction, and conclusion.

### 1.2 Pre-trends rejection (p<0.001) undermines causal interpretation
**Response:** We have revised the paper to be more honest about this concern. We no longer claim pre-trends "evolve in parallel" — instead we note the formal test rejects while arguing the magnitudes are small. We have replaced "precisely estimated null" language with more cautious framing throughout. The Rambachan-Roth bounds are now highlighted alongside the baseline CIs. We have also softened the RI language from "strongest possible confirmation" to "strong supplementary evidence" and added explicit caveats that RI does not fix treatment mismeasurement.

### 1.3 Compressed treatment timing / no never-treated units
**Response:** We acknowledge this limitation in the discussion. The 10 effective C-S groups (down from 28 dates) reflect the compressed adoption window. We note this limits identifying variation.

### 1.4 First-stage evidence missing
**Response:** We attempted to test whether procedure type composition changed with transposition, but the TED data field for procedure type was not usable in our extract. We acknowledge this gap in the limitations section and note that "the design identifies the reduced-form association between legal transposition timing and competition outcomes rather than the structural effect of specific reform provisions."

### 1.5 Claims too strong
**Response:** We have substantially recalibrated claims throughout. The abstract now says "reduced-form association" and "consistent with structural entry barriers dominating procedural ones, though the design cannot rule out that transposition timing is a noisy proxy for actual implementation." The conclusion similarly uses more cautious language.

## Reviewer 2 (GPT-5.4 R2): REJECT AND RESUBMIT

### 2.1 Treatment timing: award dates vs. notice dates
**Response:** This is a valid concern. We have added this as part of the first limitation in Section 6.4, noting that "contracts awarded after transposition may have been initiated under the old regime" and that this "could attenuate estimates toward zero."

### 2.2 "Precisely estimated null" vs. Rambachan-Roth wide bounds
**Response:** Resolved. We now present the Rambachan-Roth bounds alongside the baseline CIs in the main results section and note that "readers should interpret the precision of this null conditional on the validity of the parallel trends assumption."

### 2.3 Pairs bootstrap mislabeled as "Wild Cluster Bootstrap"
**Response:** Fixed. Section renamed to "Pairs Cluster Bootstrap" with correct description and Cameron et al. (2008) citation.

### 2.4 RI misapplied / over-interpreted
**Response:** We have added explicit caveats: "RI tests a sharp null conditional on the design and does not address treatment mismeasurement or endogenous timing."

### 2.5 C-S vs. TWFE: different estimands due to weighting
**Response:** We now provide cohort-level decomposition of the C-S SME result, showing it is driven by a single cohort (2017Q1: CY, FI, HR, LV, SE). This helps explain the TWFE/C-S divergence.

## Reviewer 3 (Gemini-3-Flash): MAJOR REVISION

### 3.1 SME result conflict between TWFE and C-S
**Response:** Resolved. Added cohort-level decomposition showing the aggregate C-S SME ATT of -0.202 is driven almost entirely by the 2017Q1 cohort (ATT = -0.495, SE 0.152). No other cohort is individually significant.

### 3.2 Pre-trend F-test
**Response:** Addressed throughout the paper with more honest framing. See response to 1.2 above.

### 3.3 Procedure type endogeneity
**Response:** Unable to test due to data limitation in the TED extract. Noted as limitation.
