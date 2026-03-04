# Revision Plan 1

## Reviewer Consensus

All three reviewers identify the same core issues:
1. **Underpowered design** (N_right = 2-6 treated counties near cutoff)
2. **Running variable ≠ EPA designation** (decade average vs specific designation windows)
3. **Stock vs flow outcomes** (eGRID 2022 snapshot vs dynamic investment)
4. **Spatial spillovers** (untested SUTVA violations)
5. **Over-confident null interpretation** (wide CIs don't support strong claims)

## Actionable Revisions (within current data)

### 1. Add MDE/Power Analysis
Calculate and report Minimum Detectable Effects given the SEs and sample sizes. This honestly communicates what the design can and cannot detect.

### 2. Extensive Margin Analysis
Run binary outcome (has any fossil plant = 1/0) as additional test — addresses zero-inflation concern.

### 3. Tone Down Null Claims
Rewrite abstract, results, and conclusion to acknowledge low power more prominently. Replace "does not measurably reshape" with "cannot be detected with available statistical power."

### 4. Add Explicit Limitations for Running Variable
Already added in this round — the "Running variable vs EPA designation" paragraph addresses this directly. Strengthen further.

### 5. Note for Future Work
Explicitly identify EIA-860 panel data, actual designation records, and RTO-level analysis as improvements for future research.

## Items NOT Addressed (limitations of current data)
- Cannot obtain actual EPA designation panel within this session
- Cannot obtain EIA-860 generator additions/retirements panel
- Cannot aggregate to RTO/balancing authority level without geographic crosswalk
- Fuzzy RDD first stage would require matching EPA designation records to counties
