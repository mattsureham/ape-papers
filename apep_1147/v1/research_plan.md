# Research Plan: Rejected and Relocated

## Research Question

Does patent rejection cause inventors to relocate across state lines, and does this examiner-driven geographic reallocation systematically redistribute knowledge workers away from innovation-intensive states?

## Identification Strategy

**Examiner-leniency instrumental variable (Lemley & Sampat 2012; Sampat & Williams 2019 QJE).** USPTO assigns patent applications quasi-randomly to examiners within art units. Examiners vary substantially in grant propensity (within-art-unit SD = 0.156, IQR 0.50–0.80). The instrument is the leave-one-out examiner grant rate within art-unit × filing-year cell.

**First stage:** Stricter examiners → higher rejection probability.

**Reduced form:** Among inventors with sequential applications, stricter examiners are associated with higher interstate mobility rates (smoke test: 13.4% moved for strictest quintile vs 10.3% for most lenient — monotonically decreasing).

**Exclusion restriction:** Conditional on art unit × filing year, examiner identity affects inventor location only through the grant/reject decision. Examiners do not select applications based on inventor geography.

## Expected Effects and Mechanisms

1. **Direct mobility effect:** Patent rejection reduces the inventor's attachment to their current employer/region, increasing interstate moves. Expected SDE: small positive (0.01–0.05).

2. **Destination sorting:** Rejected inventors may systematically move toward states with stronger innovation ecosystems (agglomeration pull) or away from states where their specific technology has less demand.

3. **Heterogeneity:** Effect should be larger for (a) solo inventors vs. team inventors (less firm attachment), (b) first-time applicants (less established), (c) inventors in states with weaker innovation ecosystems (less to hold them).

## Primary Specification

```
Moved_{i,t+k} = α + β · Rejected_i + X_i'γ + δ_{au,fy} + ε_i
```

Instrumented by leave-one-out examiner grant rate within art-unit × filing-year. `Moved_{i,t+k}` = 1 if inventor i's next application is from a different state. Controls: number of prior applications, team size, art-unit FE × filing-year FE. Cluster SEs at examiner level.

## Data Sources

1. **BigQuery `patents-public-data.uspto_oce_pair`:**
   - `application_data`: examiner_id, disposal_type, filing_date, art_unit (~9.8M apps)
   - `all_inventors`: inventor state, application number (~12.1M records, ~990K unique inventors)
   - Link: inventor × application → sequential apps reveal state changes

2. **Construction:**
   - Merge inventor records to application data on application_number
   - Order inventor's applications chronologically
   - Code `moved = 1` if state differs between consecutive applications
   - Compute leave-one-out examiner grant rate within art-unit × filing-year

## Key Risks

1. **Inventor identity:** BigQuery inventor records may not have persistent IDs — need name+state matching or inventor_id field. If unavailable, use inventor name within art unit.
2. **State code completeness:** Not all inventor records may have state codes.
3. **Selective attrition:** Rejected inventors may stop patenting entirely (not just relocate). Address via bounds and attrition analysis.
4. **Timing:** Need sufficient gap between applications to observe moves (typically 2-4 years).
