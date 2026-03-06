# Internal Review - Round 1

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

**Strengths:** The paper's core methodological contribution — demonstrating the TWFE vs CS-DiD divergence — is well-executed and clearly explained. The boundary DiD design is standard, and the paper is honest about its limitations. The CS-DiD implementation correctly excludes always-treated cities (Paris, Grenoble) and clearly defines the treatment/control assignment at the commune level.

**Concerns:**
- The event study uses TWFE with commune FE, which itself may suffer from the same staggered treatment bias the paper diagnoses. Consider presenting the CS-DiD dynamic effects as the primary event study.
- With only 7 cities in the CS-DiD (after excluding Paris and Grenoble), the effective number of treatment cohorts is small. This limits the precision and generalizability of the CS-DiD estimate.
- The "Post" indicator for always-treated cities (Paris, Grenoble) equals 1 throughout the sample in the TWFE regressions. Their contribution to the TWFE estimate is purely cross-sectional (inside vs. outside), not temporal. This is noted but could be more prominent.

### 2. Inference and Statistical Validity

- Standard errors clustered at commune level throughout — appropriate given the number of cities.
- CS-DiD uses multiplier bootstrap — standard.
- RI p-value of 0.08 is borderline; the interpretation (most TWFE signal is non-causal) is fair but could note that 0.08 is not far from conventional significance.
- The CI for CS-DiD (±5%) is tight enough to rule out large effects but not small ones (2-3%).

### 3. Robustness and Alternative Explanations

- Bandwidth sensitivity, donut hole, commercial placebo, RI, city heterogeneity — comprehensive set.
- The commercial placebo showing a significant positive effect is compelling evidence of confounding.
- Missing: A repeat-sales or property-level panel approach would strengthen identification but is acknowledged as infeasible with current data.

### 4. Contribution and Literature

- First study of LEZ housing capitalization with admin data — clear gap.
- Methodological cautionary tale is valuable for the broader boundary DiD literature.
- Literature positioning is solid (Chay & Greenstone, Currie et al., Black, Gehrsitz, etc.).

### 5. Results Interpretation

- The null result interpretation is careful and balanced — multiple explanations offered.
- Policy implications are proportional to evidence.
- The paper correctly avoids over-claiming.

### 6. Actionable Revision Requests

**Must-fix:**
1. None remaining — previous rounds addressed the major issues.

**High-value:**
1. Present the CS-DiD dynamic effects figure more prominently (currently Figure 2 on page 15).
2. Discuss the power of the CS-DiD more explicitly — with 7 cities and commune-quarter aggregation, what is the MDE?

**Optional:**
3. A map figure showing ZFE boundaries would enhance the paper.
4. The air quality spaghetti plot (Figure 8) could be replaced with an event study.

### 7. Overall Assessment

**Key strengths:** Honest null result, methodological contribution, comprehensive diagnostics, clean prose.

**Critical weaknesses:** Small number of treatment cohorts in CS-DiD (7 cities); limited pre-treatment period; the TWFE-vs-CS-DiD comparison is the paper's main contribution but the CS-DiD itself has limited power.

**Publishability:** Strong candidate for AEJ: Economic Policy or JEEM with current analysis. The methodological contribution (TWFE vs CS-DiD divergence in boundary designs) adds value beyond the policy finding.

DECISION: MINOR REVISION
