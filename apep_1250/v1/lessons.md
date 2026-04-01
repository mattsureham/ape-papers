## Discovery
- **Idea selected:** `idea_2177` — the question was novel, directly policy-relevant, and testable with public court data even if the treatment proxy turned out weaker than hoped.
- **Data source:** Ministry of Justice possession claims zip plus FCA HCSTC regional lending data — the main surprise was that the usable local-authority panel lived inside the zip rather than the headline ODS, and the FCA regional exposure was only public post-cap.
- **Key risk:** treatment measurement and inference both lived at the region level, creating a design that could only support a disciplined null unless stronger pre-cap exposure data appeared.

## Execution
- **What worked:** the private-minus-mortgage design gave a cleaner within-place comparison than the original landlord-only idea and helped turn a noisy question into a coherent paper.
- **What didn't:** a silent region-name mismatch dropped Yorkshire and the Humber until debugging caught it, and repeated table reruns exposed a reproducibility bug in the `etable()` writer that had to be fixed.
- **Review feedback adopted:** I tightened the paper's claim around post-cap exposure and few-cluster inference, treated permutation and trend-robust checks as decisive, expanded discussion of renter-specific confounders, and made the robustness table show p-values directly.
