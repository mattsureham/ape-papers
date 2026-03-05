# Reply to Reviewers

## Reviewer 1 (GPT-5.2): MAJOR REVISION

### 1. Enrollment outcome construction
**Concern:** Full planned enrollment assigned to every state with a facility is mechanically duplicative.
**Response:** We now explicitly acknowledge this limitation in a footnote in Section 3.2, describing the measure as "trial-level enrollment exposure" rather than state-level enrollment. We have downgraded enrollment from a co-equal headline outcome to a secondary measure, with the trial site count serving as the primary outcome. The sign instability between CS (-0.063) and TWFE (+0.032) for enrollment, which we now discuss explicitly in Section 5.1, is consistent with the noisiness inherent in this construction.

### 2. Spillovers and SUTVA
**Concern:** Multi-state trials create interference across states; sponsors could reallocate sites.
**Response:** We have added a full paragraph to the Identification Assumptions section (Section 4.2) addressing SUTVA. We argue: (a) near-zero take-up means no behavioral impetus for reallocation; (b) site placement costs make rapid geographic substitution prohibitively expensive (DiMasi et al. 2016); (c) spillover-induced attenuation biases toward null, which is the substantive finding.

### 3. Robustness aligned with CS estimator
**Concern:** Table 3 robustness uses TWFE while CS is the primary estimator.
**Response:** We have added clarifying text explaining that the CS estimator IS the primary result (Table 2), and the TWFE robustness in Table 3 serves as cross-validation. The Bacon decomposition showing 61% clean weights justifies TWFE as informative for this purpose.

### 4. Adoption exogeneity
**Concern:** Need more evidence on adoption timing.
**Response:** The event study with 8 flat pre-treatment quarters is the standard and strongest evidence. We have strengthened the text in Section 4.2 noting that the Goldwater Institute's lobbying strategy was supply-driven (their organizational capacity) rather than demand-driven (state trial activity trends).

### 5. Multiple testing
**Concern:** Terminal effect p=0.09 highlighted without adjustment.
**Response:** We have added Holm-Bonferroni correction across the three primary outcomes. The adjusted p-value for terminal trials is 0.27, reinforcing the null interpretation. We have updated language in the abstract, introduction, and results accordingly.

### 6. Trial start date vs site activation
**Concern:** Global start date may mis-time site-level treatment effects.
**Response:** We have added a footnote in Section 3.2 explaining this limitation and arguing that the study start date is the more policy-relevant timing measure, since RTT effects would operate through planning-stage decisions.

### 7. Estimand clarity
**Concern:** Paper slides between "trial presence" and "total trial activity."
**Response:** We have clarified that the primary estimand is the effect on state-level trial site presence, which is the natural unit for a state-level policy intervention.

## Reviewer 2 (Grok-4.1-Fast): MINOR REVISION

### 1. Enrollment construction
**Concern:** Same as GPT — enrollment attribution inflates variance.
**Response:** See response to Reviewer 1, Point 1.

### 2. Short post-periods for late adopters
**Concern:** 2017 adopters have only 1-4 post-treatment quarters.
**Response:** Acknowledged in Section 7.4 (Limitations). The CS estimator handles this correctly by estimating group-time ATTs only for observed post-periods, then aggregating with group-size weights.

### 3. Terminal classification validation
**Concern:** Text-based terminal condition matching is arbitrary.
**Response:** Acknowledged as a limitation. The conditions list was constructed conservatively to capture diseases with high mortality rates where Right-to-Try would be most relevant.

## Reviewer 3 (Gemini-3-Flash): MINOR REVISION

### 1. Enrollment unit of analysis
**Concern:** Need weighted enrollment analysis.
**Response:** See response to Reviewer 1, Point 1. We have added the footnote and caveat.

### 2. Phase I completion interaction
**Concern:** Could interact treatment with share of Phase II/III trials.
**Response:** This is an interesting suggestion for future work but goes beyond the scope of the current analysis. The primary outcome already restricts to Phase II/III trials, which are the relevant population.

### 3. FDA Expanded Access comparison
**Concern:** Add time series of national FDA Expanded Access requests.
**Response:** While relevant context, FDA Expanded Access data is not available at the state-quarter level needed for our panel design. We discuss the 99% approval rate and near-zero RTT take-up in the Institutional Background section.
