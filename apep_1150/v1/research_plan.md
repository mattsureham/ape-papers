# Research Plan: The Regulatory Anatomy of US Hospitals

## Research Question

How do Medicare payment thresholds at 25, 50, and 100 hospital beds distort the US hospital size distribution, and which threshold causes the most capacity distortion per dollar of payment differential?

## Policy Background

Three distinct Medicare programs create sharp notches in the hospital bed distribution:

1. **Critical Access Hospital (CAH) at 25 beds**: Balanced Budget Act 1997, MMA 2003. Hospitals with ≤25 beds in rural areas receive 101% cost-based reimbursement instead of prospective payment. This is a massive financial incentive — cost-based reimbursement eliminates all downside risk.

2. **Rural Health Clinic/Rural Emergency Hospital at 50 beds**: Bipartisan Budget Act 2018. Provider-based RHCs at hospitals with <50 beds are exempt from per-visit payment caps. Rural Emergency Hospital (REH) conversion (CAA 2021) limited to hospitals with ≤50 beds.

3. **Disproportionate Share Hospital (DSH) at 100 beds**: 42 CFR 412.106. Hospitals with 100+ beds use the more generous large urban DSH adjustment formula.

## Identification Strategy

Multi-threshold bunching estimation following Kleven (2016) and Chetty et al. (2011).

**Core design**: For each threshold (25, 50, 100 beds), estimate excess mass relative to a counterfactual polynomial density. The counterfactual is constructed by fitting a polynomial to the empirical distribution excluding a manipulation window around each threshold.

**Key innovation**: Jointly decompose the observed bed distribution into:
- (a) Regulatory bunching at 25, 50, and 100 beds
- (b) Round-number heaping at every multiple of 5 and 10 beds

Heaping at non-regulatory round numbers (30, 40, 60, 70, 80) provides a heaping function predicting expected round-number spikes absent regulation. The regulatory-specific excess mass at 25, 50, and 100 is the total excess minus the predicted heaping component.

**Elasticity estimation**: Convert excess mass at each threshold into a behavioral elasticity — the responsiveness of hospital capacity decisions to the payment differential. Compare elasticities across programs.

**Placebos**:
- Pre-2003 CAH limit of 15 beds (historical placebo — should show bunching in early years only)
- Non-regulatory round numbers as placebo thresholds
- Non-CAH-eligible urban hospitals at 25 beds (should not bunch)

## Expected Effects and Mechanisms

- **25-bed CAH threshold**: Expect massive bunching. The incentive is enormous (101% cost-based vs. prospective payment). Hospitals should downsize or avoid growth beyond 25 beds. Elasticity should be largest here.
- **50-bed RHC/REH threshold**: Expect moderate bunching. The payment differential is smaller. Should see increasing bunching after 2018 BBA and 2021 CAA.
- **100-bed DSH threshold**: Expect upward bunching (hospitals growing to reach 100+). The incentive works in the opposite direction — larger hospitals benefit.
- **Round-number heaping**: Expect excess mass at multiples of 10 independent of regulation, reflecting cognitive/reporting biases.

## Primary Specification

For each threshold $t$:
1. Estimate counterfactual density using 7th-degree polynomial, excluding manipulation window $[t-w, t+w]$
2. Compute excess mass $B = \sum_{b \in [t-w, t]} (h_b - h_b^0)$ where $h_b$ is observed count and $h_b^0$ is counterfactual
3. Normalize: $b = B / \bar{h}^0$ (excess mass relative to average counterfactual height)
4. Standard errors via bootstrap (200 replications)
5. Estimate round-number heaping function from non-regulatory round numbers
6. Compute regulatory-specific bunching = total bunching - predicted heaping

## Data Source and Fetch Strategy

**Primary**: CMS Healthcare Cost Report Information System (HCRIS), Form 2552-10
- Download: data.cms.gov, 14 annual files (FY2010–FY2023)
- Variables: Hospital ID (provider number), bed count (Worksheet S-3, Part I, Line 14, Col 2), hospital type, geographic location, revenue/cost data
- ~6,000 hospitals per year, ~84,000 hospital-year observations

**Supplementary**: CMS Provider of Services (POS) file for CAH designation status and rural/urban classification.

**Fetch approach**:
1. Download HCRIS CSV files for FY2010-2023
2. Extract bed counts from the cost report line items
3. Merge with POS file for CAH status
4. Construct panel: hospital × fiscal year with bed count, CAH status, rural/urban, state

## Key Risks

1. **Bed count reporting**: Hospitals may report licensed vs staffed vs available beds differently. HCRIS reports "beds available" which is the economically relevant measure.
2. **CAH eligibility**: Not all ≤25-bed hospitals are CAH-eligible (must be rural, ≥35 miles from nearest hospital or designated as necessary). The bunching signal should be concentrated among rural hospitals.
3. **Round-number vs regulatory**: At 50 beds, both round-number and regulatory forces operate simultaneously. Decomposition relies on the heaping function estimated from non-regulatory multiples of 10.
