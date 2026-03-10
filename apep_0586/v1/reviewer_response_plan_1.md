# Reviewer Response Plan

## Synthesis of Feedback

All three reviewers converge on the same core issue: the paper's strongest contribution is **diagnostic** (showing that a third census decade reveals pre-trend contamination in the conventional WWII design), but the paper currently overclaims it as a **causal** paper about returns to military service. The reframing is the primary revision.

### Must-Fix (All 3 reviewers agree)

1. **Reframe as diagnostic/methodological contribution** — Title, abstract, intro, conclusion overclaim causal "returns to military service." Strongest contribution = pre-trend contamination revealed by third decade. (R1 §1A, R2 §§1A,5A,6.1, Gemini supports)

2. **Demote trend-adjusted specification** — Present as exploratory/illustrative, not preferred corrected estimate. Assumptions (linear trends, different control set) are too strong. (R1 §1, R2 §§1D,5C,6.2)

3. **Soften mechanism language** — "Career disruption" interpretation stronger than evidence supports. Reduced form bundles multiple channels. (R1 §1B, R2 §§3C,5A,6.8)

4. **Reframe pre-trend test** — It's a powerful falsification, not a parallel-trends test in the textbook sense (different age margins 1930-40 vs 1940-50). (R2 §§1C,6.5)

5. **Add estimand discussion** — Clarify what β₁ identifies (reduced-form state×cohort exposure, not service returns per se). (R2 §6.12)

### High-Value (≥2 reviewers)

6. **Linkage selection discussion** — More substantive treatment of survivorship/linkage bias. (R2 §§1F.2,6.4, Gemini §6.2)

7. **Control group contamination** — Older controls had nonzero service probability. More cautious discussion. (R1 §1C, R2 §§1F.3,6.9)

8. **Acknowledge need for richer controls** — Paper reveals pre-trends but doesn't try to model/absorb them. Discussion of what additional analysis would strengthen identification. (R1 §1B, R2 §§3A,6.3)

9. **First-stage transparency** — Discuss inability to estimate first stage more explicitly. (Gemini §6.1)

10. **Inference refinements** — Describe RI design more precisely, acknowledge wild-cluster bootstrap as desirable complement. (R2 §§2B,6.6)

### Optional/Polish

11. Move LOO/RI figures to appendix (exhibit review)
12. Reduce emphasis on heterogeneity (R2 §6.11)
13. Sample-size note on pre-trend table (R2 §2C)
14. Age-placebo power caveat (R2 §2E)

## Execution Plan

All revisions are textual (reframing, softening claims, adding caveats/discussion). No re-running R code needed — reviewer concerns are about interpretation, not analysis.

### Changes to Make

**Title:** Change to emphasize diagnostic contribution: "The Hidden Pre-Trend: How a Third Census Decade Exposes Identification Failure in WWII Service-Return Estimates"

**Abstract:** Rewrite to lead with methodological/diagnostic framing. Demote trend-adjusted. Remove "consistent with career disruption" as a headline claim.

**Introduction:**
- Keep hook (already strong per prose review)
- Reframe contribution paragraphs: lead with diagnostic finding, present causal interpretation as secondary/suggestive
- Add explicit estimand statement
- Soften Collins & Zimran comparison

**Section 5.1 (Main Results):**
- Soften "sign reversal reveals that observable selection accounts for more than 100%"
- Soften college interpretation
- Add estimand caveat

**Section 5.2 (Pre-Trend):**
- Reframe as "falsification test" not "parallel trends test"
- Add caveat about different age margins
- Keep the finding but be more precise about what it tests

**Section 5.3 (Trend-Adjusted):**
- Demote to exploratory/illustrative
- Add explicit caveats about linearity assumption
- Remove "consistent with career disruption" framing

**Section 6 (Heterogeneity/Mechanisms):**
- Soften all mechanism language to "suggestive" / "one interpretation consistent with"
- Add explicit statement about what reduced form can and cannot identify
- Reframe college result more cautiously

**Section 7 (Robustness):**
- Add more detail on RI design
- Acknowledge wild-cluster bootstrap as desirable complement
- Note pre-trend table N consistency
- Add power caveat for age placebo

**Section 8 (Discussion):**
- Complete rewrite of 8.1 to lead with estimand clarification
- Add subsection on linkage selection (expanded from limitations)
- Add discussion of what richer controls would look like
- Soften WWII-Vietnam reconciliation language
- Rewrite conclusion to emphasize methodological lesson

**Conclusion:** Reframe as diagnostic contribution first, suggestive causal evidence second.

### What Won't Change
- Data and analysis (no R code changes)
- Tables and figures (already validated)
- Institutional background section
- Data section
- Core regression specifications
