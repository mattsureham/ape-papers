# Reply to Reviewers — apep_0496 v1

## Response to GPT-5.2 (Reject and Resubmit)

### 1. Running variable is not a defensible proxy for treatment assignment
**Response:** We agree this is the paper's central limitation. The revised paper explicitly reframes from "boundary RDD identifies causal label effect" to "price gradient at equidistance loci" (Abstract, Section 1). We add prominent caveats throughout that the equidistance locus is a proxy, not the true carte scolaire boundary. True catchment boundary data would strengthen the analysis but is not publicly available.

### 2. RDD assumptions violated
**Response:** Acknowledged transparently. The McCrary test (T=31.3) and covariate balance failures are reported and interpreted as evidence that the design measures an equilibrium gradient, not a locally randomized treatment effect. We cite Cattaneo et al. (2020) on interpreting RDD under violated assumptions.

### 3. Commune FE does not identify label effect
**Response:** We agree commune FE absorbs much variation and may over-control. The Column 5 result (coefficient = -0.000) is presented as one specification in a progressive series, not as the definitive causal estimate. The parametric progression (Columns 1-5) shows how much of the raw gap is geographic sorting vs. residual.

### 4. Spatial inference concerns
**Response:** Valid concern. Commune-level clustering is the natural unit given the institutional structure (communes set local taxes, zoning). More granular spatial HAC would be valuable future work.

### 5. Donut/placebo results undermine discontinuity
**Response:** We interpret these as evidence of a smooth gradient rather than a sharp discontinuity, consistent with our descriptive framing.

---

## Response to Grok-4.1-Fast (Major Revision)

### 1. Proxy running variable unvalidated
**Response:** Same as GPT response above. We add explicit discussion of this limitation in Sections 4.2 and 7.3.

### 2. Commune FE overcontrol concern
**Response:** We present Column 5 as the most demanding specification but acknowledge overcontrol risk. The key finding is the monotone progression from -14.2% to 0%, not any single coefficient.

### 3. Placebo discontinuities at ±250m
**Response:** Reported transparently as evidence against a sharp label effect. Consistent with smooth spatial gradient interpretation.

### 4. Private school mechanism — continuous robustness
**Response:** Added continuous interaction (count × REP_side) in addition to binary split (Section 6.5 and code 03_main_analysis.R).

---

## Response to Gemini-3-Flash (Major Revision)

### 1. Validate proxy boundary
**Response:** Acknowledged as valuable future work. True carte scolaire data is not publicly available. The paper is transparent about this limitation.

### 2. Interaction with school quality (IPS)
**Response:** IPS scores are available at the school level but the precise thresholds used for REP designation are not publicly documented. An IPS-based RDD would complement this analysis.

### 3. Temporal trends mechanisms
**Response:** We discuss multiple hypotheses (COVID housing dynamics, dédoublement, credit tightening, mean reversion) but note they cannot be sharply distinguished in the data.

---

## Changes Made in This Revision

1. **Reframed narrative:** "price gradients at equidistance loci" not "boundary RDD identifies causal label effect" (Abstract, Introduction)
2. **Added commune FE (Column 5):** Coefficient = -0.000, SE = 0.008, R² = 0.611
3. **Added continuous private school interaction** in addition to binary split
4. **Clarified sample sizes:** Explicit reconciliation of 4.6M cleaned → 1.7M boundary → 1.12M parametric
5. **Labeled 2025 as partial** in Figure 2
6. **Added DVF publication lag explanation** (6-12 months)
7. **Updated all significance stars and coefficient claims** for consistency
