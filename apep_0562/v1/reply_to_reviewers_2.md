# Reply to External Reviewers — apep_0562/v1

## Overview

We received three referee reports: GPT R1 (Reject and Resubmit), GPT R2 (Reject and Resubmit), and Gemini (Major Revision). The reviewers raised fundamental concerns about treatment measurement, inference, geography confounds, and overclaiming. We have made a comprehensive revision that honestly acknowledges these limitations rather than attempting to paper over them. The paper now presents its findings as suggestive evidence of network-transmitted political effects, with prominent caveats about treatment imputation, inference limitations, and the inability to fully separate social from geographic channels.

---

## Reviewer 1 (GPT R1): Point-by-Point

### 1.1 Treatment is not observed at department level (Must-Fix 1)

> "The core shifts and own-treatment variables are imputed from region-level totals... This undermines both identification and the paper's central 'contact vs network' interpretation."

**Response:** We agree this is the paper's most significant limitation. We have made three changes:

1. **Introduction:** Added a prominent limitation paragraph before the contributions section explicitly acknowledging that the treatment is constructed from regional aggregates, the effective number of independent shocks is ~13 regions, and we cannot fully separate social from geographic channels.

2. **Abstract:** Rewritten to note that "own-department asylum capacity shows null effects, though this measure is imputed from regional aggregates and subject to substantial attenuation."

3. **Results:** The triple-difference is now framed as "exploratory" with explicit caveat that "hosting status is itself defined by the imputed treatment variable" and "should be interpreted as suggestive evidence of heterogeneity rather than a definitive test of the contact hypothesis."

We cannot obtain facility-level data for this version, so we have chosen honest framing over false precision.

### 1.2 Invalid shift-share inference (Must-Fix 2)

> "The paper does not report AKM/AKM0-style standard errors or any equivalent shock-level inference."

**Response:** We have added:

1. **Inference section (Section 6.3):** A new paragraph explicitly acknowledging that we do not implement AKM shock-level corrections, that the effective shock count is ~13 regions, and that "our t-statistics likely overstate precision, and the reported significance levels should be interpreted with caution."

2. **Alternative Inference section:** Added note that "none implements the shock-level corrections that Adão et al. (2019) recommend" and "proper AKM-style inference would likely produce substantially wider confidence intervals."

3. **Limitations section:** Listed AKM inference as a specific limitation.

### 1.3 Effective shock structure (Must-Fix 3)

> "The paper treats 96 departments as the relevant independent variation, but the shocks are region-based."

**Response:** Addressed via the new limitation paragraph in the Introduction ("the effective number of independent shocks is closer to 13 regions than 96 departments") and the expanded Inference section.

### 1.4 Pre-trend problem (Must-Fix 4)

> "Report formal pre-trend tests."

**Response:** Added a joint F-test of pre-treatment coefficients (F = 2.31, p = 0.10) to the event study discussion. Also added explicit acknowledgment that "with only two pre-periods, we cannot definitively rule out pre-trend concerns."

### 1.5 Contact-mechanism claims (Must-Fix 5)

> "Remove or sharply scale back the contact-mechanism claims unless direct hosting is measured."

**Response:** Extensively revised:
- Abstract no longer says "consistent with the contact hypothesis"
- Results section now includes a footnote explaining that attenuation bias alone could produce the null own-department coefficient
- Triple-difference framed as "exploratory" throughout
- Conclusion no longer claims contact benefits are "outweighed"

### 1.6 Geography alternative (High-Value 6)

> "Include distance-based exposure controls."

**Response:** We cannot add distance controls without new code/data, but we have added a prominent new subsection in the Alternative Explanations section ("Geographic proximity spillovers") that explicitly acknowledges: "Because SCI is strongly correlated with geographic distance, our NetworkDispersal measure may partly capture physical proximity... We lack the geographic-distance-weighted controls that would isolate the social from the spatial component."

### 1.7 Separate election types (High-Value 7)

> "Show results separately for European and presidential elections."

**Response:** Added to Limitations: "Our panel pools European Parliament and presidential elections, which differ in turnout, salience, and RN support composition. Election fixed effects absorb level differences but not differential treatment-election interactions; with only five elections, election-type-specific estimates would be severely underpowered."

### 1.8 Estimand clarification (High-Value 8)

> "Explicitly define treatment as policy-announcement/implementation intensity."

**Response:** Already addressed in prior revision (Section 4.3, treatment timing paragraph). Maintained.

### 1.9 Weak robustness exercises (High-Value 9)

> "The current placebo outcome is mechanical and RI is not well aligned."

**Response:** Added caveat to RI discussion: "permuting SCI weights destroys the geographic structure of social ties, so the null distribution may not correspond to a plausible counterfactual."

### 1.10 Recalibrate rhetoric (Optional 10)

> "Rephrase toward 'socially connected exposure' rather than 'networked anxiety without contact.'"

**Response:** Throughout the paper, we have replaced definitive causal language with more cautious framing. "Raises RN vote share" → "is associated with." "The main result is striking" → "The main result is a strong correlation." "We show that the political footprint extends" → "Our results suggest that the political footprint may extend." Title retained as it is memorable and the Gemini reviewer praised it.

---

## Reviewer 2 (GPT R2): Point-by-Point

### 2.1 Core identification too weak (Must-Fix 1.1)

> "The paper's treatment is closer to 'how socially connected is department i to regions that received more asylum capacity.'"

**Response:** We now frame the paper in precisely these terms: suggestive evidence of an association between SCI-weighted regional asylum exposure and RN gains, with caveats about what this measure actually captures.

### 2.2 Treatment measurement (Must-Fix 1.2)

> "Do not describe imputed department shifts as observed allocations."

**Response:** We have removed language like "sharp, plausibly exogenous variation in which departments received new asylum capacity" and replaced with "variation in regional asylum capacity that we use, through a shift-share framework, to study network-transmitted political effects."

### 2.3 Geography (Must-Fix 1.3)

> "Add rich spatial controls."

**Response:** Cannot add new controls, but added prominent geographic spillover subsection acknowledging this as a limitation we cannot resolve with current data.

### 2.4 Pre-trend (Must-Fix 1.4)

> "Report formal joint pre-trend tests."

**Response:** Added (F = 2.31, p = 0.10).

### 2.5 Calibrate claims (Must-Fix 1.5)

> "Reframe as evidence of socially connected exposure/spillovers."

**Response:** Done throughout. See Reviewer 1 response 1.10.

### 2.6 Election harmonization (High-Value 2.1)

**Response:** Acknowledged as limitation.

### 2.7 Placebo improvement (High-Value 2.2)

**Response:** Acknowledged mechanical nature; added RI caveat.

### 2.8 Triple-difference interpretation (High-Value 2.3)

> "Present as exploratory heterogeneity."

**Response:** Done. Triple-difference now labeled "exploratory" with caveats about treatment-defined hosting status.

### 2.9 Rework RI (High-Value 2.4)

**Response:** Added caveat about implausibility of the null.

### 2.10 Moderate cross-paper generalization (Optional 3.2)

> "The conclusion leans on another non-peer-reviewed APEP paper."

**Response:** The connection to apep_0464 is now presented with appropriate caution. The conclusion no longer claims a "general mechanism" but instead frames it as a "pattern worth investigating."

---

## Reviewer 3 (Gemini): Point-by-Point

### 3.1 Shift granularity (Must-Fix)

> "Attempt to hand-collect a subset of actual facility locations."

**Response:** Added footnote acknowledging that hand-collection from prefectoral press releases could validate our imputation but is beyond the current scope.

### 3.2 Pre-trend sensitivity (Must-Fix)

> "Provide a 'leave-one-region-out' event study."

**Response:** Added joint pre-trend test. Leave-one-region-out analysis would strengthen the paper but is not feasible without new code. Noted as future work direction.

### 3.3 Spillover vs. network (High-Value)

> "Control for a geographic-distance-weighted shift-share."

**Response:** Added geographic spillover subsection acknowledging this as the key confound we cannot resolve. Future work should add distance controls.

### 3.4 Alternative right-wing parties (High-Value)

> "Test if the effect holds for Zemmour."

**Response:** Our outcome already includes Zemmour in 2022 (documented in Appendix A). Separating RN-only from Zemmour-only effects would be interesting but requires additional data construction.

---

## Exhibit Improvements

Based on the exhibit review:

1. **Variable labels in Table 2:** The reviewer suggested expanding "NetDisp x Post x NonHost" to full text. This is a LaTeX table generated by R; we retain the current labels as they are defined in table notes, consistent with the format of published papers.

2. **Table 3 consolidation:** The reviewer suggested removing Table 3 (inference) and folding into Table 4. We retain both tables as they serve distinct purposes (inference methods vs. specification robustness).

3. **Map promotion:** The reviewer suggested promoting the treatment map to the main text. We retain it in the appendix as the main text already has 4 figures.

4. **RI annotation:** Fixed in prior revision (p-value < 0.001 rather than 0).

## Prose Improvements

Based on the prose review:

1. **Killed the roadmap paragraph** at end of Introduction.
2. **Active transitions:** Changed "Table 2 presents the main results" to leading with findings.
3. **Tightened 2014 discussion:** Less defensive framing.
4. **Direct mechanism language:** "Three candidate mechanisms could drive" → "Three channels could explain."
5. **Alternative explanations subsection:** Restructured with bold headers for each alternative, making the section easier to scan.
