# Research Plan: Do Miners Vote with Their Feet? MSHA Inspections and Mine-Level Employment Dynamics

## Research Question

Do workers reduce employment at mines revealed to have serious safety violations through mandatory MSHA inspections? This tests the worker information channel of compensating differentials theory at the establishment level.

## Identification Strategy

**Stacked event-study DiD** at the mine × quarter level.

- **Treatment:** Regular (E01) MSHA inspection finding ≥3 Significant & Substantial (S&S) violations (severe revelation)
- **Control:** Regular (E01) inspection finding 0 S&S violations (clean bill of health) in the same quarter
- **Unit:** Mine × calendar quarter
- **Estimator:** Stacked DiD with mine FE + state × quarter FE
- **Event window:** 4 quarters pre, 8 quarters post
- **Clustering:** Mine level (or state level for robustness)

## Exposure Alignment

The treatment (inspection revealing severe violations) directly affects the specific mine where violations are found. Workers at that mine learn about safety conditions through publicly posted violation citations. The outcome (employment at the same mine) is perfectly aligned with treatment exposure — no cross-unit spillover concern at the establishment level.

## Expected Effects and Mechanisms

1. **Worker information channel:** Inspection reveals pre-existing hazardous conditions → workers update risk beliefs → reduce labor supply at that mine (quit, transfer, reduce hours)
2. **Expected sign:** Negative (employment falls at mines with severe inspection findings)
3. **Expected magnitude:** 5-15% decline in employment over 4-8 quarters, based on the compensating differentials literature
4. **Heterogeneity:** Larger effects at underground mines (higher baseline risk), coal mines (more S&S violations per inspection)

## Primary Specification

Y_{mt} = α_m + γ_{s(m),t} + Σ_k β_k × 1[t - E_m = k] + ε_{mt}

Where:
- Y = average employee count at mine m in quarter t
- α_m = mine fixed effects
- γ_{s(m),t} = state × quarter fixed effects
- E_m = quarter of the severe-findings inspection event
- k = event time relative to inspection (-4 to +8 quarters)
- SE clustered at mine level

## Data Sources

All from MSHA Open Government Data (arlweb.msha.gov/OpenGovernmentData/):
1. **Inspections.zip** (72 MB): 1.14M records. Key: EVENT_NO, MINE_ID, INSPECTION_BEGIN_DT, ACTIVITY_CODE
2. **Violations.zip** (119 MB): 3.06M records. Key: EVENT_NO, SIG_SUB flag, PROPOSED_PENALTY
3. **MinesProdQuarterly.zip** (56 MB): 2.71M mine-quarter records. Key: MINE_ID, AVG_EMPLOYEE_CNT, HOURS_WORKED

## Placebo Tests

1. Spot inspections (E02) triggered by accidents/complaints — endogenous, should show DIFFERENT pre-trend pattern
2. Balanced pre-trends for severe vs clean regular inspections
3. Dose-response by S&S violation count and proposed penalty amount
