# Reply to Reviewers — Round 1

## Reviewer 1 (GPT-5.4 R1)

### 1a. Redesign around within-court variation or radically reframe
**Response:** We agree this is the fundamental limitation. The paper is already framed as a diagnostic/methodological contribution documenting *why* the cross-sectional design fails, not as delivering a causal estimate. We have further sharpened this framing throughout. Obtaining case-level EOIR data is beyond the scope of this paper but is explicitly proposed as the primary avenue for future research (Section 7.2).

### 1b. Panel is effectively cross-sectional
**Response:** Agreed and addressed. We now explicitly state throughout that the effective identifying variation comes from 44 cross-sectional court values, not 720 panel observations (Sections 5.2, 6.0 caveat). The panel structure provides repeated outcome measurements but no new instrument variation.

### 1c. Controls change both specification and sample
**Response:** Agreed. We now explicitly acknowledge that the controlled specification changes both controls and sample (720→500), and that part of the coefficient attenuation may reflect sample composition rather than confound removal (Section 6.2). A same-sample decomposition is noted as a priority for future work.

### 1d. Strengthen inference for small-cluster design
**Response:** Acknowledged as a limitation. Wild-cluster bootstrap and permutation inference would require new R analysis beyond the scope of this revision, but we have strengthened the discussion of the 44-court cross-sectional nature of inference.

### 1e-1f. Case-mix contamination and falsification
**Response:** We have added case-mix contamination as a third fundamental reason for design failure in Section 7.1, with detailed discussion of how nationality composition, detained/non-detained dockets, and representation rates confound the lifetime grant rate instrument.

### 1g. Duplicated county
**Response:** Already documented in Section 4.4; acknowledged as a limitation throughout.

### 1i. Reposition contribution more sharply
**Response:** The contribution is now more tightly framed around three lessons: (1) cross-sectional judge composition measures fail, (2) case-mix contamination is a distinct threat, (3) case-level within-court data are necessary.

### 1j. Tone down monotonicity and upper bound
**Response:** Done. Section 6.7 now says "consistent with monotonicity" rather than "satisfied." Section 7.3 removes the "upper bound" language and replaces it with a qualified discussion of the likely direction of bias without making a formal bounding claim.

---

## Reviewer 2 (GPT-5.4 R2)

### 2a. Reframe as 44-court cross-section
**Response:** Addressed. See response to 1b above. Explicit language added in Sections 5.2 and 6.0.

### 2b. Rework inference
**Response:** Partially addressed through framing (effective 44-court variation). Full cross-sectional regression and wild bootstrap left for case-level redesign.

### 2c. Same-sample confound
**Response:** Addressed. See response to 1c above.

### 2d. Duplicated county
**Response:** Acknowledged in Section 4.4.

### 2e. Tone down monotonicity/upper bounds
**Response:** Done. See response to 1j above.

### 2f. Predetermined outcome falsification
**Response:** Noted as high-value future work. Current data limitations prevent this without new analysis.

### 2g. Reduced-form more prominent
**Response:** The paper already frames 2SLS as a "diagnostic exercise." We agree reduced-form presentation would be more transparent and note this for the case-level redesign.

### 2h-2j. Alternative geography, court-type heterogeneity, case composition
**Response:** These are valuable suggestions for the case-level redesign. Case composition contamination is now discussed as a third fundamental failure reason (Section 7.1).

### Literature additions
**Response:** Added citations to Frandsen, Lefgren, and Leslie (2023), Bhuller et al. (2020), Borusyak, Hull, and Jaravel (2022), Goldsmith-Pinkham, Sorkin, and Swift (2020), Amuedo-Dorantes and Antman (2020), and Orrenius and Zavodny (2015). The shift-share/exposure design connection is now discussed in Section 7.1.

---

## Reviewer 3 (Gemini-3-Flash)

### Exclusion restriction violation
**Response:** Fully acknowledged as the paper's central finding. The cross-sectional design does not support causal inference.

### Failed placebo tests
**Response:** We have softened "built-in placebo" to "sector-heterogeneity diagnostic" throughout, acknowledging that general-equilibrium demand spillovers could in principle affect all sectors. The diagnostic power comes from the comparable magnitudes across treatment and placebo sectors, not a strict zero prediction.

### Endogenous sorting
**Response:** Addressed with case-mix contamination as a third failure mechanism.

### Must-fix: Case-level EOIR data
**Response:** We agree this is the path forward. Obtaining FOIA data is beyond the scope of the current paper but is the primary recommendation in Section 7.2.

### Look-ahead bias
**Response:** Acknowledged throughout as a secondary concern with quantitative bounds on practical contamination (Section 4.1).

### Magnitudes
**Response:** The "each grantee creates 1,000 jobs" framing is now introduced earlier in the paper (introduction) to make the impossibility vivid from the start.

---

## Summary of Changes Made

1. **Monotonicity (Section 6.7):** "Satisfied" → "consistent with"; acknowledged that aggregate positive slopes do not verify individual-level monotonicity
2. **Upper bound (Section 7.3):** Removed formal bounding claim; replaced with qualified discussion of likely bias direction
3. **Placebo language:** "Built-in placebo" → "sector-heterogeneity diagnostic" throughout (abstract, conceptual framework, threats, results, conclusion, SDE table)
4. **Cross-sectional framing:** Explicit statements that 44 courts are the effective identifying variation (Sections 5.2, 6.0)
5. **Same-sample concern:** Acknowledged in Section 6.2 that controls specification changes both controls and sample
6. **Case-mix contamination:** Added as third fundamental failure reason in Section 7.1
7. **Literature:** Added 7 new citations (Frandsen et al., Bhuller et al., Borusyak/Hull/Jaravel, Goldsmith-Pinkham/Sorkin/Swift, Amuedo-Dorantes/Antman, Orrenius/Zavodny)
8. **Exposure design connection:** New paragraph in Section 7.1 connecting to shift-share literature
9. **Prose improvements:** Removed roadmap paragraph; Shleifer-style results preview in intro; improved data section opening
10. **Figure promotion:** Judge variation boxplot (Figure 1) promoted to main text (Section 2.2)
