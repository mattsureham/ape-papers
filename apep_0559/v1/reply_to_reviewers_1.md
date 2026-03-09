# Reply to Reviewers

## Overview of Changes

This revision addresses feedback from three referees (GPT R1, GPT R2, Gemini), the exhibit review, and the prose review. The major changes are:

1. **Language calibration**: Systematic softening of causal claims throughout (abstract, introduction, mechanisms, discussion, conclusion). Replaced "irreversible" with "persistent," "clean identification" with "suggestive evidence," and similar recalibrations.
2. **RI validity caveat**: Added explicit discussion of exchangeability limitation (Section 8.5).
3. **Mechanism separation**: Renamed Section 7 to "Interpretations and Mechanisms" with explicit evidence-hierarchy disclaimer.
4. **Figure consolidation**: Merged old Figures 2-4 into multi-panel Figure 3; moved hysteresis bar chart to Appendix A.
5. **Table improvements**: Added RI p-values for all 4 outcomes in Table 2; added pre-cap mean row; restructured Table 5.
6. **Limitations expansion**: Section 9 now covers 5 explicit limitations including compositional change, COVID overlap, and RI exchangeability.
7. **Post-repeal reframing**: Distinguishes stock vs. flow adjustment; frames post-2020 as "consistent with persistence" not "proof of deepening."

---

## GPT-5.4 (R1): Revise and Resubmit

### 1.1 Identifying variation too weak for causal claim

**Response:** We agree the claims were too strong relative to the design. The revision systematically recalibrates: "clean identification" → removed; "unambiguous" → removed; "first evidence that credit rationing is irreversible" → "first evidence that credit rationing effects may persist well beyond the policy's removal." The abstract, introduction, and conclusion now frame findings as "suggestive evidence of persistent effects" from a "rare natural policy experiment" rather than definitive causal evidence. We acknowledge the design is closer to a small-N comparative time series than a standard bank-level DiD (Section 9).

### 1.2 Compositional change in Tier 3

**Response:** Section 9 now explicitly discusses the decline from 22 to 16 Tier 3 banks as a first-order concern, acknowledging that the direction of bias is ambiguous. We note that bank-level microdata would resolve this but is not publicly available from CBK. The limitation is stated candidly rather than dismissed.

### 1.3 Timing / stock-flow issues

**Response:** Section 7 now distinguishes stock vs. flow outcomes. The post-repeal interpretation acknowledges that "balance-sheet ratios reflect both repeal and the legacy stock of loans originated under the cap" and that existing contracts remained capped through maturity. Post-2020 coefficients are described as "consistent with persistence" rather than clean evidence of deepening.

### 1.4 Alternative confounders (COVID)

**Response:** Section 8.4 now notes that year fixed effects absorb common shocks but cannot rule out differential COVID exposure across tiers. The pre-COVID robustness check (2010-2019 only) confirms the cap-period effect is unchanged. Post-repeal interpretation explicitly notes COVID as a confounder that prevents clean attribution (Section 9).

### 2.1 RI exchangeability assumption

**Response:** Added Section 8.5 with explicit discussion: "the RI procedure treats tier labels as exchangeable within each year, whereas tier assignment is a persistent structural characteristic. The test is therefore best interpreted as evidence against the sharp null that tier identity is irrelevant to the outcome conditional on fixed effects—i.e., that no permutation of the 'Tier 3' label produces effects as large as observed. It does not provide exact inference under a randomized assignment mechanism, because assignment was not randomized." Citations to Cameron & Miller (2015) and Conley & Taber (2011) added.

### 3.4 Mechanism claims exceed evidence

**Response:** Section 7 renamed "Interpretations and Mechanisms" with opening paragraph establishing evidence hierarchy: portfolio rebalancing = "directly supported by regression evidence"; relationship destruction = "interpretation consistent with reduced form"; digital credit = "descriptive correlation, not causal." Each mechanism subsection now states its evidentiary basis explicitly.

### 5. Overclaiming causality/irreversibility

**Response:** Comprehensive language revision throughout:
- Abstract: "credit rationing did not reverse but deepened" → "the differential contraction persisted and deepened rather than reversing"
- Conclusion: "The answer is no" → "The evidence presented here suggests it may not"
- "permanent costs" → "long-lasting costs"
- "Government securities crowded in permanently" → "Government securities holdings remained elevated"
- Cross-country: "reinforces the within-Kenya results" → "provides suggestive corroboration"

---

## GPT-5.4 (R2): Revise and Resubmit

### 1.1-1.3 Design concerns (aggregation, parallel trends, treatment intensity)

**Response:** Same as R1 above. The core response is language recalibration rather than design change, since bank-level data is not publicly available from CBK. The paper now explicitly acknowledges these as limitations (Section 9) rather than dismissing them.

### 1.4 Stock-flow timing

**Response:** Addressed in the post-repeal reframing (see R1 §1.3 above).

### 1.5 Compositional change

**Response:** Discussed explicitly in Section 9 with acknowledgment that the direction of bias is ambiguous. Year-by-year bank counts are in Table 1.

### 2.1 RI validity

**Response:** See R1 §2.1 above. New Section 8.5 added.

### 2.3 RI reported for all outcomes

**Response:** RI p-values now computed and reported for all 4 main outcomes (loan/asset ratio, govt securities/asset, NPL ratio, log loans). All show p < 0.001. Table 2 updated with RI brackets for every column.

### 3.3 Mechanism separation

**Response:** See R1 §3.4 above.

### 5 Overclaiming

**Response:** See R1 §5 above.

---

## Gemini-3-Flash: Minor Revision

### 1. COVID-symmetry check

**Response:** Section 8.4 strengthened. Pre-COVID subsample (2010-2019) confirms the cap-period effect is unchanged. Post-repeal interpretation explicitly caveats COVID overlap. Cross-country comparison (Section 6.4) shows peer countries did not experience similar tier-based divergence, providing suggestive (not definitive) evidence that Kenya's pattern reflects cap-specific dynamics.

### 2. Dynamic selection / compositional change

**Response:** The decline from 22 to 16 Tier 3 banks is discussed in Section 9. We acknowledge this is a limitation and note that bank-level data would resolve it. The direction of bias argument is presented more carefully.

### 3. Interest rate persistence

**Response:** Section 7.2 now discusses whether depressed post-repeal lending reflects sticky pricing or permanent capacity loss. The evidence is consistent with the latter (organizational "competence traps" in SME lending), but we frame this as interpretation rather than established fact.

---

## Exhibit Review

### Figure consolidation

**Response:** Old Figures 2-4 (individual tier panels for loan/asset, govt securities, NPL) merged into multi-panel Figure 3 using patchwork + cowplot with shared legend and cap-period shading. Hysteresis bar chart moved to Appendix Figure A1. Figure numbering updated throughout paper.

### Table improvements

**Response:** Table 2 now includes: (1) RI p-values for all 4 columns, (2) pre-cap dependent variable mean row, (3) note explaining event study uses a different specification with wider CIs. Table 5 restructured: removed significance stars (inappropriate with 3 clusters), added inline RI p-values for baseline and pre-COVID rows.

---

## Prose Review

### Opening hook

**Response:** First paragraph rewritten to lead with the policy experiment: "In September 2016, Kenya capped interest rates on all bank loans at four percentage points above the Central Bank Rate..." — concrete, vivid, immediately engages.

### Results-first phrasing

**Response:** Section 6 revised to lead with findings and magnitudes before discussing specifications. Key result sentence: "Tier 3 banks reduced their loan-to-asset ratio by 4.04 percentage points relative to Tier 1 during the cap period."

### Mechanism language

**Response:** Mechanisms section now separates evidence quality explicitly (see above). Digital credit discussion hedged: "While I cannot establish a causal link between the cap and digital credit growth with the available data..."
