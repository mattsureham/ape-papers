# Reply to Reviewers — apep_0543 v1

## Common Concerns Across All Three Reviewers

### 1. Result concentrated in Bordeaux
**Response:** We reframe the abstract, introduction, and conclusion to explicitly foreground heterogeneity. The abstract now states: "Bordeaux drives the result... The evidence suggests capitalization where regulation binds severely, but cannot establish a general effect."

### 2. Randomization inference does not reject null
**Response:** We now report RI for both uncontrolled (p=0.46) and controlled (p=0.65) specifications. We are transparent that RI does not reject, noting this reflects limited power with 5 treated groups rather than absence of effect. The abstract now mentions RI non-rejection.

### 3. Controls sensitivity (room count overlaps with investment classification)
**Response:** We added a surface-only controls specification (no room count): -0.094, p=0.015—nearly identical to the full-controls result (-0.093, p=0.017). This demonstrates the improvement with controls reflects within-type size variation, not mechanical reclassification.

### 4. Stacked DDD only validated uncontrolled specification
**Response:** We now report stacked DDD with controls: -0.100, p=0.016, confirming the controlled headline is robust to TWFE bias.

### 5. Pre-trend evidence is weak / event study is by type not DDD
**Response:** We acknowledge the short pre-treatment window limits pre-trend testing. We add clarification that k=-2 is populated only by later cohorts. A DDD event study would be valuable but the short pre-period makes it uninformative (only one pre-period bin for the triple difference).

### 6. Clustering at commune level may overstate precision
**Response:** We acknowledge this concern. The 42 commune clusters include only 5 independent treatment groups. The RI exercise, while underpowered, provides an alternative inference approach that does not depend on cluster count.

## Specific Reviewer Responses

### GPT R1 — Specific Points Not Addressed Above
- **Control group construction ad hoc:** Valid concern for future revision. Currently use all untreated cities >100K.
- **Paris/Lille estimates should be demoted:** We already present these as "supplementary" and "suggestive," and added explicit note that Post×Treated for always-treated cities is identified only from cross-sectional variation.

### GPT R2 — Specific Points Not Addressed Above
- **Treated × Invest lower-order interaction:** Commune FE absorb the Treated_c main effect; Investment_i is included. The Treated × Invest interaction could be added but is partially collinear with commune × investment interactions. We note this as a future improvement.

### Gemini — Specific Points Not Addressed Above
- **Direct measure of regulatory "bite":** Would strengthen the paper substantially. Requires Observatoire des Loyers data not currently available.
- **Lille anomaly investigation:** Already discussed in city-by-city section (COVID confounds).
