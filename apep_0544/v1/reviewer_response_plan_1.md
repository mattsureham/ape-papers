# Reviewer Response Plan — Round 1

**Paper:** apep_0544 v1 — Cutting the Pipeline
**Reviews:** GPT-5.4 (R1): MAJOR REVISION, GPT-5.4 (R2): MAJOR REVISION, Gemini: MAJOR REVISION
**Internal:** Claude Code: MINOR REVISION

---

## Key Themes Across All Reviewers

### 1. Over-claiming (ALL 3 reviewers)
"First causal evidence," "persistent de-industrialization," "hysteresis," "lower bound" language all too strong for β=-0.231, t=-0.54, RI p=0.58.

**Action:** Complete prose recalibration of abstract, introduction, results, discussion, and conclusion. Reframe as "reduced-form evidence" with "suggestive" patterns, not established causal effects.

### 2. "Lower bound" claim unidentified (ALL 3)
Cannot sign subsidy bias without data. Subsidies could create selection issues, not just attenuation.

**Action:** Remove "lower bound" from abstract. Replace throughout with weaker language: "subsidies may have attenuated the measured effect, but the direction and magnitude of resulting bias are not point-identified."

### 3. Hungary outlier (ALL 3)
LOO sign flip (+0.259 when Hungary excluded) is a "major warning sign." Result is not a general European phenomenon.

**Action:** Expand LOO discussion. Add explicit analysis of why Hungary has high leverage (highest gas dependence in sample at 85%, combined with distinctive industrial structure). Frame honestly as a limitation rather than dismissing it.

### 4. Placebo concerns (ALL 3)
March 2019 placebo (-0.345) cannot be dismissed by COVID. Both placebos larger than main estimate.

**Action:** Discuss March 2019 more carefully. Acknowledge it as a genuine limitation. Add caveat that the gas×intensity interaction may capture broader vulnerability to shocks.

### 5. Dynamic claims not formally tested (R1, R2)
β_2023 vs β_2022 difference not formally tested; "deepening" and "hysteresis" overinterpreted.

**Action:** Tone down dynamic narrative. Add explicit caveat that neither year-specific coefficient is individually significant and no formal equality test is reported. Replace "nearly doubled" with "point estimates become more negative."

### 6. Literature too thin (R1, R2)
Missing shift-share/exposure design references (Borusyak, Hull, Jaravel 2022; Goldsmith-Pinkham, Sorkin, Swift 2020).

**Action:** Add these citations and discuss how the design relates to exposure/Bartik frameworks.

### 7. Mechanism evidence weak (R1, R2)
Producer price null doesn't establish subsidy attenuation.

**Action:** Reframe mechanism section as "exploratory" rather than "evidence for the subsidy channel."

### 8. Estimand clarity (R1, R2)
Paper slips between gas-cutoff, gas-price, and war-exposure effects.

**Action:** Clarify that β captures the reduced-form differential effect of pre-war Russian gas exposure on manufacturing, not a clean gas-cutoff channel.

---

## Changes NOT Made (with rationale)

- **Wild cluster bootstrap:** Would require new R package installation and re-running analysis. The RI with p=0.58 already tells the same story — the result is not significant. Adding WCB would not change the conclusion.
- **Longer event study (2015+):** Data starts in 2015, but the event study specification with k=-24 to +22 is standard. Extending would require restructuring the entire analysis. The pre-COVID trend test (2015-2019, t=-0.14) already addresses this.
- **Exclude CZ/TR from baseline:** Already shown in appendix (β=-0.231, identical). Making this the preferred spec would not change any result.
- **NUTS-2 data / firm-level data:** Entirely different analysis beyond scope of revision.
- **Subsidy data interaction:** Would require new data collection beyond scope.

---

## Execution Plan

1. Rewrite abstract (remove "first causal," "lower bound," recalibrate claims)
2. Rewrite key introduction paragraphs (reduced-form framing, tone down causal language)
3. Revise results section (soften "deepening" narrative, add caveats about individual insignificance)
4. Revise discussion section (remove "lower bound," reframe mechanism, add caveats)
5. Rewrite conclusion (restrained claims, remove rare earths/semiconductors generalization)
6. Add shift-share literature citations
7. Expand Hungary discussion
8. Reframe placebo discussion
9. Add references.bib entries for new citations
10. Recompile and verify
