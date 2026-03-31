# Research Plan: Rejected and Relocated

## Research Question

Does patent rejection cause inventors to relocate across states? We exploit quasi-random examiner assignment at the USPTO to estimate the causal effect of patent rejection on inventor interstate mobility, revealing a "brain drain" channel through which patent policy redistributes human capital across regions.

## Identification Strategy

**Examiner leniency IV** (Lemley & Sampat 2012; Sampat & Williams 2019 QJE):
- USPTO assigns patent applications to examiners quasi-randomly within art units
- Examiners vary substantially in grant propensity (within-AU SD = 0.156, IQR: 0.50–0.80)
- Instrument: leave-one-out examiner grant rate within art-unit × filing-year cell
- First stage: strict examiners reject more applications (F >> 10)
- Exclusion restriction: examiner identity affects mobility only through the grant/reject decision

**Key identifying assumption:** Conditional on art unit × filing year, examiner assignment is as-good-as-random. This is well-established in the literature.

## Expected Effects and Mechanisms

1. **Rejection → relocation (primary):** Rejected inventors are more likely to move states. Mechanism: lost IP protection reduces location-specific rents, and rejection signals may trigger job search.
2. **Heterogeneity by inventor type:** Solo inventors (less tied to firm location) should show larger effects than team inventors.
3. **Direction of flows:** Rejected inventors may move toward innovation hubs (agglomeration pull) or away from high-cost areas (cost push).

## Primary Specification

**Stage 1 (inventor-level):**
```
Moved_{i,t} = α + β·Rejected_{i,t} + γ·X_{i} + δ_{au,t} + ε_{i,t}
```
Where `Moved_{i,t}` = 1 if inventor i's next application is from a different state, instrumented by leave-one-out examiner grant rate. Art-unit × filing-year FE absorb technology-time trends.

**Reduced form:**
```
Moved_{i,t} = α + π·ExaminerLeniency_{-i,au,t} + γ·X_{i} + δ_{au,t} + ε_{i,t}
```

## Data Sources

1. **USPTO PAIR via BigQuery** (`patents-public-data.uspto_oce_pair`):
   - `application_data`: 9.8M applications with examiner_id, disposal_type
   - `all_inventors`: 12.1M US inventor-application records with state codes
   - Link applications to examiners and track inventor state changes

2. **USPTO Office Actions via BigQuery** (`patents-public-data.uspto_oce_office_actions`):
   - 4.4M office actions with rejection codes (for robustness)

## Fetch Strategy

1. Query BigQuery for inventor-application-examiner linked panel
2. Construct leave-one-out examiner leniency within art-unit × year
3. Identify movers (inventors with applications from 2+ states)
4. Build analysis dataset with controls (team size, prior grants, art unit)

## Robustness Checks

- First-stage diagnostics (F-statistic, examiner balance)
- Reduced form across leniency quintiles (replicating smoke test monotonicity)
- Placebo: examiner leniency → pre-application state change (should be null)
- Heterogeneity: solo vs team inventors, technology fields, inventor experience
- Sensitivity to art-unit × year cell size thresholds
- Alternative mobility definitions (any move vs. long-distance move)
