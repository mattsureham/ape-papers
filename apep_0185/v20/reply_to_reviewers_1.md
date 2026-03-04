# Reply to Reviewers — v20

## Response to GPT-5.2 (Major Revision)

**1. AKM / shock-level inference:** We report state-clustered SEs following Adao et al. (2019), which is the standard clustering level for shift-share designs where shocks occur at the state level. Our 51 state clusters exceed typical thresholds. We additionally report two-way clustering (state + quarter), network clustering, Anderson-Rubin weak-IV robust inference, and 2,000-draw permutation tests (Table 5). All confirm significance at conventional levels. We agree that explicitly implementing BHJ-style shock inference would strengthen the paper and note this for future work, but the current inference battery exceeds what most published shift-share papers provide.

**2. Origin-state policy bundles:** This is a substantive concern. Our GDP and employment placebos address general economic spillovers; the industry heterogeneity (high-bite vs low-bite null) specifically addresses the policy bundle concern — if correlated policies (EITC, Medicaid, paid sick leave) drove results, we would expect effects across all sectors, not concentrated in MW-relevant industries. The null in professional services and finance is inconsistent with a generic "progressive policy bundle" confound. We acknowledge this as a limitation and note it explicitly.

**3. Dynamic/lead tests:** Our pre-treatment balance trends (Figure 6) show parallel trends by IV quartile before 2014. The Rambachan-Roth sensitivity analysis in the appendix confirms robustness. A formal distributed-lag model is a valuable suggestion for future work.

**4. Employment magnitude:** We added a back-of-envelope calibration (Section 11) in this revision that decomposes the 9% into a 36% upper-bound response rate among MW-relevant workers, consistent with search elasticity literature (Faberman et al. 2022). We tempered abstract language from "The channel is information transmission" to "The evidence is consistent with information transmission."

**5. Population vs employment weighting:** We use pre-treatment (2012-2013) average QWI employment, which is time-invariant and predetermined. We acknowledge the reviewer's point about Census population as an alternative and note this for robustness.

## Response to Grok-4.1-Fast (Minor Revision)

**1. Pre-treatment balance:** Figure 6 shows parallel trends; balance tests (Table 4) show non-monotonic patterns absorbed by county FE. We agree that a formal event-study plot and explicit Rambachan-Roth bounds in the main text would strengthen the paper.

**2. SCI timing:** We cite Bailey et al.'s validation against historical migration (ρ > 0.85 with 2000 Census). Distance-restricted results strengthening is inconsistent with endogenous network formation.

**3. Magnitudes:** We expanded the calibration in Section 11 with the back-of-envelope exercise.

**4. Missing citations:** Dustmann et al. (2022) is already cited in the job flows section. Monras (2020) is cited in the bibliography.

## Response to Gemini-3-Flash (Minor Revision)

**1. QWI suppression bias:** The 25% suppression affects disproportionately small counties. Our main results (Table 1) use the full non-suppressed employment/earnings sample (99.2% coverage). The mechanism results (Table 6) use the smaller sample. We note this limitation in the text.

**2. LATE characterization:** Table 10 shows complier characteristics. High-complier counties have lower employment — consistent with rural counties along major migration corridors (e.g., Texas border counties connected to California).

**3. Announcement effects:** We agree that a lead/lag event-study specification would strengthen the timing evidence. The pre-2014 parallel trends and the pre-COVID subsample (larger coefficient) are consistent with effects operating through actual wage changes rather than anticipation.
