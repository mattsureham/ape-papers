# Internal Review Round 1 — APEP-0500
## Legislating Peace? Anti-Open Grazing Laws and Farmer-Herder Violence in Nigeria

**Verdict: MINOR REVISION**

### Summary

Strong paper with a compelling question, credible DDD identification, and a battery of robustness checks. The writing is clear and well-organized. Main issues are around some specification details and minor presentation improvements.

### Strengths

1. **Novel causal question.** First paper to apply modern causal inference to anti-grazing legislation in Nigeria. This is a genuine gap in the literature.
2. **Triple-difference design.** The pastoral/non-pastoral within-state variation is a clever way to gain precision beyond the 14-state treatment. State×year FE absorb all state-level confounders.
3. **Multiple placebos.** State-based violence and one-sided violence both show precise nulls, strongly supporting the specificity of the finding.
4. **Randomization inference.** RI p = 0.026 with 1,000 permutations provides non-parametric validation beyond cluster-robust SEs.
5. **SGF sub-sample.** Using the quasi-exogenous 2021 collective adoption wave addresses endogeneity concerns about early adopters.
6. **Leave-one-out.** Tight range [-0.498, -0.385] shows no single state drives the result.

### Issues to Address

#### Methodology

1. **Wild cluster bootstrap.** The paper mentions WCB as a robustness approach but does not report results. Either note that the fixest `^` notation is incompatible with fwildclusterboot, or implement an alternative approach. Currently silent.

2. **Callaway-Sant'Anna interpretation.** The state-level CS ATT is positive (1.74) while the LGA-level DDD is negative (-0.472). The paper explains this well (power vs. precision), but the sign difference deserves more discussion.

3. **Pastoral zone classification.** Using pre-treatment violence as part of the classification creates a mechanical concern: LGAs with high pre-treatment violence are more likely to show regression to the mean, which could look like a treatment effect. The Middle Belt geography partially addresses this, but the paper should discuss this more explicitly.

#### Presentation

4. **Table 2 R² values.** The R² of 0.379 for the preferred spec (column 3 with state×year FE) is relatively low. Brief discussion of what drives the unexplained variance would help.

5. **Abstract word count.** At ~137 words, within the 150-word limit. Good.

6. **Minor: column labels in Table 2.** Columns 4-5 don't indicate which FE structure they use. Adding "State×Year FE" would clarify.

### Decision

**Minor Revision.** The identification is credible, the results are robust, and the writing is strong. Address the pastoral zone classification concern and WCB transparency. Proceed to external review after addressing these points.
