# Research Plan: The Inadequate Cliff — CQC Special Measures and Care Home Exit

## Research Question

Does the CQC "Inadequate" rating — which triggers automatic Special Measures placement — cause care home closures, or does it merely label homes that would have exited anyway? What is the mechanism: demand-side (families flee the label) or supply-side (regulatory compliance costs)?

## Identification Strategy

**Fuzzy RDD** at the Inadequate/Requires Improvement boundary. CQC assigns overall ratings based on a deterministic aggregation of 5 domain ratings (Safe, Effective, Caring, Responsive, Well-Led), each scored 1-4. The composite score determines overall rating. Homes just below vs. just above the Inadequate threshold face categorically different regulatory regimes (Special Measures vs. standard monitoring).

Key assumption: care homes near the threshold cannot precisely manipulate their composite score — the multi-inspector, multi-domain assessment creates genuine noise at the boundary. McCrary density test required.

## Running Variable Construction

The CQC aggregation rule: Overall = Inadequate if the provider receives Inadequate in any "key question" (typically Safe or Well-Led) OR if multiple domains are rated Inadequate. I will construct a scalar running variable from the 5 domain ratings:
- Each domain: Outstanding=1, Good=2, RI=3, Inadequate=4
- Sum of 5 domains = composite score (range 5-20)
- Threshold: empirically determined from the data (where Inadequate overall probability jumps)

## Data Sources

1. **CQC Bulk Ratings** — ODS download with all current ratings + historical snapshots
2. **CQC API** — Individual location details including registration status, deregistration dates
3. **CQC Historical Ratings** — Monthly snapshots (2014-2026) via CQC data archives

## Outcomes

- **Primary:** Care home deregistration (closure) within 12 months of inspection
- **Secondary:** Rating improvement at re-inspection (recovery vs. exit)

## Primary Specification

```
Closure_i = α + β·SpecialMeasures_i + f(CompositeScore_i) + ε_i
```

First stage: `SpecialMeasures_i = γ + δ·1(CompositeScore_i ≥ T) + g(CompositeScore_i) + η_i`

Using `rdrobust` for optimal bandwidth selection, bias-corrected estimates, and robust confidence intervals.

## Robustness

- McCrary density test at threshold
- Donut RDD (exclude observations exactly at threshold)
- Varying bandwidths (50%, 75%, 150% of CCT optimal)
- Placebo thresholds
- Covariate balance at threshold (home size, ownership type, region)

## Expected Effects

Homes placed in Special Measures face a "regulatory cliff" — the label is public, families can see it, and the 6-month improvement deadline creates existential pressure. I expect:
- Higher closure rates just above the threshold (5-15 pp)
- Effect concentrated in smaller, independent homes (less capacity to absorb compliance costs)
- Demand-side mechanism: occupancy drop post-label → financial distress → closure
