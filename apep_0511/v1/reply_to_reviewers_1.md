# Reply to Reviewers — apep_0511/v1

## Reviewer 1 (GPT-5.2)

### 1.2 Panel RDD is not a validated RD estimator
**Response:** We agree that the panel specification imposes stronger parametric assumptions than the nonparametric rdrobust. We have substantially revised the paper to:
- Frame the panel as a "parametric complement" rather than the primary specification
- Explicitly discuss the linearity assumption and wide bandwidth (±10pp vs 3.3pp optimal)
- Acknowledge that the gain from p=0.82 to p=0.028 raises model dependence concerns
- Add a panel binned scatter (Figure 9) showing the visual discontinuity in year-demeaned data
- Report number of clusters (706) alongside N for all panel specifications
- Soften all claims throughout (abstract, introduction, discussion, conclusion)

### 1.3 "Ever-treated" definition
**Response:** We now explicitly discuss the misclassification concern for the 5% of hospitals (143/2,712) that cross the threshold between years, noting that averaged outcomes partly reflect pre-treatment periods, potentially attenuating the estimate. We clarify that 95% of hospitals maintain stable treatment status.

### 1.4 Running variable timing
**Response:** Added a "Timing alignment" discussion in the HCRIS section explaining that fiscal year/calendar year misalignment attenuates but does not generate spurious discontinuities.

### 1.5 Manipulation/sorting
**Response:** We acknowledge the desirability of testing DSH components separately and testing for institutional audit effects. We note that Bai et al. (2021) evidence on strategic behavior was concentrated at higher thresholds (25%) rather than 11.75%.

### 2.1 Main inference hinges on panel specification
**Response:** This is now explicitly acknowledged as a limitation. The abstract, introduction, and conclusion all frame the evidence as "suggestive" rather than definitive.

### 3.1 Crosswalk validation
**Response:** Added crosswalk validation diagnostics: Table (Appendix) showing match rates by DSH bin (comparable above/below threshold: 85.5% vs 87.7%), discussion of the 20% NPI-sharing rate across CCNs, and the attenuation-bias argument for measurement error.

### 3.3 Medicare comparison is not commensurate
**Response:** We now explicitly discuss the limitations of the ZIP-level physician Medicare outcome as an imperfect proxy and note that hospital-level OPPS drug data would strengthen the comparison. We add caveats that the null Medicare result is "necessary but not sufficient" evidence for the duplicate discount channel.

---

## Reviewer 2 (Grok-4.1-Fast)

### Validate CCN-NPI crosswalk
**Response:** Added Appendix Table showing match rates by DSH bin and discussion of linked vs unlinked balance (Section 4.4). Match rates are comparable across the threshold.

### Bolster cross-sectional power
**Response:** We acknowledge the power limitation throughout and frame the panel as supplementary. We note that as T-MSIS data quality improves and more years become available, the cross-sectional estimates will gain precision.

### Mechanism: carve-in/carve-out split
**Response:** We agree this would be a high-value test but note it requires state-year level policy classification data that varies frequently and is not readily available in a standardized format. We flag this explicitly as the most important direction for future work.

### T-MSIS data quality
**Response:** We discuss DQ variation and note that state FEs absorb state-level quality differences. The key identifying variation is cross-sectional within states.

---

## Reviewer 3 (Gemini-3-Flash)

### Share/Absolute contradiction
**Response:** We substantially expanded the cross-payer comparison section to address this. Three explanations: (1) the share RDD has identical power limitations (59/57 effective N); (2) the share is a ratio where small changes in numerator and denominator can offset, especially when ZIP-level Medicare spending dominates; (3) the panel specification cannot be replicated for the share because Medicare is not time-varying.

### State policy heterogeneity
**Response:** We acknowledge the state FE attenuation as both supporting evidence for and a limitation of the baseline result. We explicitly frame the carve-in/carve-out heterogeneity test as the most important future work.

### Panel specification refinement
**Response:** Added panel binned scatter (Figure 9) showing the visual discontinuity in year-demeaned data. Point sizes reflect observation counts per bin.

---

## Summary of Changes

1. **Claims calibration:** Abstract, introduction, discussion, and conclusion all rewritten to frame evidence as "suggestive" rather than definitive
2. **Panel specification:** Now explicitly framed as parametric complement with discussion of model dependence concerns
3. **Cross-payer/share:** Expanded discussion of share null result with three reconciling explanations
4. **Medicare caveats:** Added explicit limitations of ZIP-level physician proxy
5. **Crosswalk validation:** New appendix table (match rates by DSH bin) and discussion of NPI-sharing
6. **Timing alignment:** New subsection discussing HCRIS fiscal year vs T-MSIS calendar year
7. **Ever-treated:** Explicit discussion of misclassification concern for threshold-crossers
8. **Panel binned scatter:** New Figure 9 providing visual evidence for the panel specification
9. **Cluster counts:** Added to all panel specification tables
10. **Limitations:** Substantially expanded with separate subsections for power, crosswalk, Medicare proxy, and mechanism identification
