# Research Plan: Pipeline Scars — Does the PHMSA Significant Incident Label Make Pipelines Safer?

## Research Question
Does receiving PHMSA's "significant incident" label — which triggers public flagging, federal enforcement review, and civil penalty exposure — causally reduce subsequent pipeline safety incidents? This separates the *labeling* channel (name-and-shame) from the *substantive enforcement* channel.

## Identification Strategy
**Sharp RDD** using normalized total incident cost as the running variable. PHMSA classifies any pipeline incident with estimated total costs ≥ $50,000 in 1984 dollars as "Significant." The threshold is CPI-adjusted annually.

- **Running variable:** `norm_cost = TOTAL_COST_CURRENT / (50000 × CPI_year / CPI_1984)`
- **Cutoff:** `norm_cost = 1.0`
- **Treatment:** `SIGNIFICANT == 'YES'`
- **First stage:** ~15% significant below threshold → ~99% above (effectively sharp)

**Exclusion restriction:** Conditional on incident year, the exact cost value near the threshold is determined by physical damage and cleanup prices, not by operator reporting choices. Confirmed: cause codes (excavation, corrosion, equipment failure) distribute symmetrically across the threshold.

## Expected Effects and Mechanisms
- **Primary hypothesis:** Labeled operators reduce subsequent incident rates (deterrence via reputational/regulatory exposure)
- **Alternative:** Null effect if enforcement, not labeling, drives compliance
- **Mechanism tests:** (1) Publicly traded vs. private operators (reputational channel); (2) Operators with vs. without prior penalties (enforcement channel); (3) Future inspection intensity (regulatory scrutiny channel)

## Primary Specification
Local polynomial RDD using `rdrobust` with CCT-optimal bandwidth. Outcome: operator-level incident rate in t+1 to t+3, normalized by pre-incident rate. Cluster SEs by operator.

## Data Source and Fetch Strategy
1. **PHMSA All Pipeline Incidents:** From GitHub `jmceager/phmsa_clean` (CSV, 7,588 incidents 2010-2022)
2. **CPI data:** BLS API or FRED for annual CPI-U (1984 base)
3. **Operator-level panel:** Construct from incident data — operator × year panel with incident counts

## Key Robustness
- McCrary density test (no bunching)
- Bandwidth sensitivity (50%, 75%, 100%, 125%, 150% of CCT-optimal)
- Placebo thresholds at 0.7x, 0.85x, 1.15x, 1.3x
- Donut-hole RDD excluding ±5% of threshold
- Covariate balance: cause codes, fatality/injury indicators, geographic distribution
