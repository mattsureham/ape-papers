# Research Plan: Rejection as Redirection

## Research Question

Does patent examiner strictness redirect the direction of pharmaceutical innovation? Specifically, do applicants who receive 103 (obviousness) rejections shift toward more novel technological space, while those receiving 112 (indefiniteness) rejections narrow their claims within the same space?

## Identification Strategy

**Instrument:** Examiner leniency, defined as the leave-one-out grant rate of the assigned examiner within the same art unit and year. USPTO assigns applications to examiners quasi-randomly within art units (confirmed by balance on small-entity status: 22.6% vs 21.1% across strict/lenient halves).

**First stage:** Examiner leniency → patent grant (expected F > 100 given 24.4pp gap across 181K applications).

**Second stage (direction outcomes):**
1. Technological distance of next filing (USPC class transition from rejected application)
2. Continuation vs new application behavior after rejection
3. Filing persistence (time to next filing, probability of abandoning the technology)

**Key variation:** Within the IV framework, distinguish 103 (obviousness) from 112 (indefiniteness) rejections as different "steering signals." 103 says "this isn't novel enough" → should push toward new technology. 112 says "your claims are unclear" → should push toward refinement within the same space.

## Expected Effects and Mechanisms

- Strict examiners reduce grant probability (mechanical first stage)
- 103 rejections redirect applicants toward more distant technological classes (positive distance effect)
- 112 rejections redirect applicants toward refinement/continuation within the same class (negative distance effect)
- Net effect on innovation direction depends on rejection type composition
- Small entities may be more responsive (resource constraints amplify redirection)

## Primary Specification

```
Grant_i = α + β·Leniency_j(i) + γ·X_i + δ_a + ε_i     [First stage]
Direction_i = α + β·Ĝrant_i + γ·X_i + δ_a + ε_i        [Second stage]
```

Where: i = application, j = examiner, a = art unit × filing year FE.
Direction_i = technological distance of applicant's next filing (Jaffe cosine distance in USPC space).
X_i = small entity indicator, application type, number of claims.

## Data Source and Fetch Strategy

**Source:** Google BigQuery (free tier, ADC auth already configured)
- `patents-public-data.uspto_oce_pair.application_data` — 9.8M applications, grant outcomes, examiner IDs, art units
- `patents-public-data.uspto_oce_office_actions.office_actions` — 4.4M office actions with rejection codes

**Fetch plan:**
1. Query TC 17 (chemical/pharmaceutical) applications filed 2008-2012
2. Join with office actions to get rejection types (101/102/103/112)
3. Construct examiner leniency (leave-one-out within art unit × year)
4. Track applicant's subsequent filings for direction outcomes
5. Export to CSV for R analysis

## Key Risks

1. **Selection into next filing:** Rejected applicants may not file again → Heckman-style selection correction or bounding
2. **Art unit reassignment:** If strict examiners push applications to different art units, within-AU comparison is contaminated → verify with continuation data
3. **Temporal variation in leniency:** If examiner strictness changes over time, leave-one-out must be time-specific
4. **USPC class granularity:** Too coarse → Jaffe distance is noisy; too fine → sparse transitions

## Exposure Alignment

Treatment (examiner assignment) operates at the application level, exactly where outcomes are measured. Each application gets one examiner quasi-randomly within its art unit. The outcome (direction of next filing) is measured for the same applicant. No aggregation mismatch.
