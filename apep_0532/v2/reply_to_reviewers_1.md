# Reply to Reviewers — Round 1

## Response to GPT-5.4 (R1): MAJOR REVISION

**1. Inference with few clusters**
We agree this was the most serious issue. We implemented wild cluster bootstrap (WCB) inference using Rademacher weights. The WCB p-values are dramatically wider than CRVE: high-internet interaction goes from p=0.04 to p=0.45, monsoon from p=0.047 to p=0.32. We report these honestly and no longer rely on subsample p-values. Instead, we emphasize the continuous triple interaction (Temp × Ag × Internet, p=0.049) which uses all 21 clusters.

**2. Weather measurement at centroid**
We acknowledge this limitation. A full state-average aggregation from multiple grid cells would require rebuilding the entire data pipeline. We discuss this as a limitation and direction for future work.

**3. Outcome measurement (English terms)**
We acknowledge this as a measurement limitation in the paper. Future work should include Hindi and regional-language terms.

**4. Ex post heterogeneity**
We restructured the paper to lead with the continuous triple interaction rather than the median split. The triple interaction is more principled and uses all clusters.

**5. Delhi leverage**
We added a complete leave-one-state-out analysis showing that 20/21 states maintain the negative sign. Only Delhi flips. We discuss this honestly and note the dependence on Delhi for cross-sectional variation.

## Response to GPT-5.4 (R2): REJECT AND RESUBMIT

**1-3. Same inference/measurement/weather concerns as R1**
Addressed as above.

**4. Google Trends construction**
We acknowledge the need for better documentation. The current data section describes the construction but we agree a full retrieval appendix would strengthen the paper.

**5. Claims recalibration**
Extensively revised. Abstract, introduction, discussion, and conclusion all rewritten to match evidence strength. "Robust" removed from conclusion. Policy implications explicitly speculative.

## Response to Gemini-3-Flash: MAJOR REVISION

**1. Wild Cluster Bootstrap**
Implemented. Results reported in new robustness subsection.

**2. Delhi outlier strategy**
LOSO analysis added. Triple interaction avoids median-split sensitivity.

**3. Multiple hypothesis testing**
We adopt the convergent-evidence approach rather than formal multiple testing adjustment, acknowledging this as a limitation.
