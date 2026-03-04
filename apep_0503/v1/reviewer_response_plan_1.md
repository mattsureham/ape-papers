# Reviewer Response Plan

## Summary of Reviews
- **GPT-5.2:** REJECT AND RESUBMIT — Core concern: ecological RD (aggregate outcome), invalid inference, sign inconsistency
- **Grok-4.1-Fast:** MAJOR REVISION — Sign inconsistency, F/E McCrary, aggregate outcome defense
- **Gemini-3-Flash:** MAJOR REVISION — Sign reconciliation, commune-level aggregation, heterogeneity failure

## Grouped Concerns and Responses

### Workstream 1: Aggregate Outcome & Inference (Critical)
**Concerns:** GPT §1.1 (ecological RD), §2.1 (duplicated outcome SEs); Gemini §2 (commune averages); Grok §1 (aggregate weakens localness)

**Response:**
- Add paragraph to §4.3 (Data Linkage) reporting the number of distinct commune×year×type cells (~X cells) vs 841,704 observations
- Add discussion that commune-level clustering already accounts for within-commune correlation
- Strengthen the measurement-error-in-Y defense (attenuates toward zero, cannot create spurious discontinuity)
- Acknowledge candidly in Limitations that individual-level matching would be preferable
- Frame aggregate merge as conservative (bias toward zero), not as optimal

### Workstream 2: Sign Inconsistency Resolution (Critical)
**Concerns:** GPT §3.1, Grok §5 flags 1, Gemini §2 (sign discrepancy)

**Response:**
- Expand the bandwidth sensitivity diagnostic paragraph in §6.2
- Add explicit statement that the paper's CENTRAL claim is not about the sign or magnitude at G/F, but about the EXISTENCE of a discontinuity uniquely at the regulatory cutoff
- Reframe: pooled γ₂ captures the average regulatory premium across the full ±40 window; local polynomial captures the very local effect. Both detect a discontinuity at G/F.
- Note that the sign inconsistency is itself informative: it suggests local positive selection among G-rated sellers near the threshold

### Workstream 3: Multiple Testing (Moderate)
**Concerns:** GPT §2.4, Grok §3 optional

**Response:**
- Add Bonferroni adjustment discussion: with 6 cutoffs at α=0.05, Bonferroni threshold is 0.05/6=0.0083. G/F p=0.023 does not survive Bonferroni but survives Holm (only 1 of 6 significant). Note this.
- B/A at p=0.085 is clearly insignificant under any correction.

### Workstream 4: F/E McCrary & Placebo Concerns (Moderate)
**Concerns:** GPT §3.2, §3.3; Grok §6 fix 2; Gemini §3

**Response:**
- Expand F/E McCrary discussion: assessor manipulation without price effect is INFORMATIVE (shows differential market processing speed)
- Address 90 kWh placebo more thoroughly: in A/B range where new construction creates non-linearities; report effective N
- Note that 2 of 3 placebos are insignificant, supporting identification

### Workstream 5: Exhibits (Structural)
**From exhibit review:**
- PROMOTE to main text: Figure 2 (DPE distribution/timeline), Figure 3 (RDD bin-scatters), Figure 5 (coefficient plot), Covariate Balance table
- MOVE to appendix: Table 5 (pre/post, weak N)
- REMOVE: redundant Appendix Table 6 (McCrary full, duplicates Table 3)

### Workstream 6: Prose Polish
**From prose review:**
- Remove roadmap paragraph (end of Introduction)
- Sharpen §6.4.2 opening per Glaeser style
- Active voice in §5.4
- Consider moving option value point higher in intro

### Workstream 7: Missing Citations
**From Grok:**
- Add discussion of multiple testing literature
- Reference housing anticipation literature in F/E null discussion

## Execution Order
1. Exhibits (structural changes to paper.tex)
2. Aggregate outcome defense (§4.3, §5.4)
3. Sign inconsistency expansion (§6.2)
4. Multiple testing (§6.2)
5. F/E and placebo (§6.3)
6. Prose polish (throughout)
7. Recompile and verify
