# Research Plan: Fear of Ten Billion — Bunching Estimation of Dodd-Frank Regulatory Costs in U.S. Banking

## Research Question

Do banks strategically constrain asset growth to avoid crossing the $10 billion Dodd-Frank regulatory threshold? If so, how large is the implied compliance cost, and did the 2018 EGRRCPA rollback reverse this behavior?

## Identification Strategy

**Bunching estimation (Kleven-Waseem 2013).** The $10 billion threshold in total consolidated assets triggers:
- CFPB supervisory authority
- Durbin Amendment interchange fee caps (~$8B annual industry cost)
- Enhanced stress testing and risk management requirements

Banks near the threshold face a discrete jump in regulatory burden, creating a **notch** in the effective cost schedule. If compliance costs are significant, we should observe excess mass of banks just below $10B and a corresponding hole just above.

**Three identification pillars:**
1. **Cross-sectional bunching:** Excess density below $10B in the post-Dodd-Frank distribution (2011-2017)
2. **Temporal counterfactual:** Pre-Dodd-Frank distribution (2001-2009) should show no bunching at $10B
3. **De-bunching test:** The 2018 EGRRCPA raised the stress test threshold to $250B, reducing (but not eliminating) regulatory burden at $10B. Durbin caps remain. Partial de-bunching expected.

**Placebo tests:**
- Test for bunching at $7B, $8B, $13B, $15B (no regulatory significance)
- Pre-period test: no bunching at $10B before 2010

## Expected Effects and Mechanisms

**Primary hypothesis:** Significant excess mass below $10B post-Dodd-Frank, concentrated among banks growing toward the threshold.

**Mechanisms:**
1. **Durbin channel:** ~40-50% reduction in debit interchange revenue for banks above $10B (Kay, 2023). Annual cost: $50-80M for a $10B bank.
2. **Compliance channel:** CFPB examination costs, enhanced BSA/AML, risk management staffing
3. **Stress testing channel:** Partially relaxed by EGRRCPA in 2018

**Implied cost:** The marginal buncher's distance from $10B reveals the minimum compliance cost that justifies forgoing growth.

## Primary Specification

Kleven-Waseem polynomial bunching estimation:
- **Running variable:** Log total assets (RCFD2170)
- **Bunching window:** $5B-$15B (or $7B-$13B for robustness)
- **Polynomial order:** 7th degree (robustness: 5th-9th)
- **Counterfactual:** Smooth polynomial fitted excluding the bunching region
- **Excess mass statistic:** b = (B_actual - B_counterfactual) / B_counterfactual
- **Standard errors:** Bootstrap (500 replications)

## Data Source and Fetch Strategy

**FFIEC Central Data Repository (CDR):**
- Quarterly Call Reports (FFIEC 031/041)
- Schedule RC: RCFD2170 (Total Assets)
- ~4,500 FDIC-insured institutions per quarter
- Available: 2001Q1 - 2025Q4
- Access: Bulk download from FFIEC CDR website

**Fetch approach:**
1. Download Schedule RC bulk files from FFIEC CDR
2. Extract total assets (RCFD2170) for all reporting institutions
3. Merge with FDIC institution metadata (charter type, state, holding company)
4. Construct quarterly panel: ~4,500 banks × ~100 quarters

**Alternative data source if CDR bulk fails:**
- FDIC BankFind Suite API (JSON, institution-level)
- FDIC Statistics on Depository Institutions (SDI) bulk download
