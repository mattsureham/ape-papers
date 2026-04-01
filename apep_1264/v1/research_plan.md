# Research Plan: The Growth Ceiling — Stacked Regulatory Thresholds and Firm Size Distortion in Switzerland

## Research Question

Do Swiss firms strategically constrain their size to avoid crossing regulatory thresholds? How costly is each regulation, and what is the marginal distortion from adding a new threshold?

## Institutional Setting

Switzerland imposes four size-dependent regulations at employee-count thresholds:

| Threshold | Regulation | Legal Basis | Since |
|-----------|-----------|-------------|-------|
| 20 | Collective dismissal notification | OR Art. 335d | 1993 |
| 50 | Employee participation rights | Mitwirkungsgesetz | 1994 |
| 100 | Gender pay equity audits | Gleichstellungsgesetz (GEA) | July 2020 |
| 250 | Ordinary audit requirement | Art. 727 OR | Long-standing |

The 2020 Gender Equality Act (GEA) revision is the key temporal shock: it imposed mandatory equal pay audits on firms with 100+ employees, effective July 1, 2020. This creates difference-in-bunching identification at the 100-employee threshold.

## Identification Strategy

### Primary: Difference-in-Bunching at 100

- **Treatment:** Firms near 100-employee threshold, post-July 2020
- **Control 1 (temporal):** Same firms, pre-2020
- **Control 2 (threshold):** Firms near 50-employee threshold (no policy change at 50 post-2020)
- **Estimand:** Change in excess mass below 100 after GEA introduction
- **Key advantage:** 250-employee threshold (no change) serves as additional control

### Secondary: Cross-Sectional Bunching at All Four Thresholds

- Static bunching analysis at each threshold using the full 2011-2023 panel
- Benchmark bunching elasticities across thresholds to map the "cost schedule" of size-dependent regulation

### Triple Difference

- Threshold × Time × Industry: Service-sector firms (where pay gaps are more salient) vs. manufacturing

## Data Sources

1. **BFS STATENT** (Structural Business Enterprise Statistics): Annual firm counts by size class and NOGA industry sector, 2011-2023. Available via BFS PXWeb API (no key needed).
   - Target: finest available size bins (ideally: 1-9, 10-19, 20-49, 50-99, 100-249, 250-499, 500+)

2. **Fedlex SPARQL**: Verify exact dateEntryInForce for all four regulations.

3. **BFS UDEMO** (Business Demography): Firm births and deaths by size class and canton, for entry/exit dynamics.

## Expected Effects

- **Cross-sectional:** Excess mass in bins just below each threshold (20-49 > expected, 50-99 > expected, etc.)
- **GEA shock:** Increase in 50-99 firm count relative to 100-249 after 2020, controlling for pre-trends and other thresholds
- **Heterogeneity:** Stronger response in service sectors (more exposed to gender pay scrutiny) than manufacturing
- **Null benchmark:** If no bunching increase at 100 post-2020, the GEA's compliance cost is small relative to existing regulatory burden

## Primary Specification

```
log(N_firms_{b,s,t}) = α + β₁(Below100_b × Post2020_t) + γ_b + δ_t + θ_s + ε_{b,s,t}
```

Where b indexes size bins around the 100-threshold, s is industry sector, t is year.

## Exposure Alignment

The treatment (GEA pay audits at 100+ employees) affects firms within the 50-249 bin that have 100 or more employees — approximately 40% of the bin based on KMU-HSG data. The remaining 60% (50-99 employees) face the Mitwirkungsgesetz at 50 but not the GEA. The control group (10-49 bin) faces only the collective dismissal threshold at 20. This exposure asymmetry means the DiD captures an intent-to-treat effect diluted by the share of truly treatment-eligible firms. The affected population is medium-sized firms with headcount near the 100-employee threshold who must decide whether to comply with the GEA or constrain growth. With approximately 40% exposure, the design can detect large-scale avoidance but has limited power for modest responses.

## Robustness

1. Placebo thresholds (test at 75, 125 where no regulation exists)
2. Cross-threshold comparison (did bunching at 50 or 250 change post-2020?)
3. Industry-specific trends
4. Donut-hole estimates excluding bins immediately adjacent to thresholds
5. McCrary-style density tests

## Mechanism Tests

1. **Composition vs. true bunching:** Do firms shrink to stay below 100, or do growing firms stop at 99? (Entry vs. incumbents using UDEMO births/deaths)
2. **Industry heterogeneity:** Service vs. manufacturing decomposition (GEA bite differs by sector)
3. **Canton variation:** Cantons with stronger gender equality norms → weaker avoidance?
