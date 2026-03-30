# Research Plan: The Persistence Penalty

## Research Question

Does the FCA's persistent debt rule (September 2018) reduce consumer credit card indebtedness, or does it merely ration credit and push borrowers toward alternative products? The rule requires lenders to intervene when credit card customers have paid more in interest/charges than they have repaid in principal over 18 months, with escalating actions at 18, 27, and 36 months.

## Named Mechanism

**The Persistence Penalty**: The rule creates an implicit cost for lenders who allow persistent debt, changing both lender behavior (preemptive account closures, limit reductions) and borrower behavior (faster repayment, product switching).

## Identification Strategy

**Cross-product difference-in-differences** with multiple treatment events:

- **Treatment group**: Credit card products (subject to CONC 6.7.27-6.7.40)
- **Control group**: Personal loans and overdrafts (same lenders, same consumers, NOT subject to the persistent debt rule)
- **Key assumption**: Absent the rule, credit card and personal loan series would have moved in parallel

**Three treatment events**:
1. **September 2018**: Rule takes effect (18-month clock starts)
2. **February 2020**: FCA warns against blanket account suspensions (moderating signal)
3. **March 2020**: COVID emergency suspends persistent debt letters (treatment-OFF)

The COVID suspension provides a natural treatment-reversal test. If the rule caused the divergence, we should see convergence when letters were suspended.

## Expected Effects

- **Credit card balances**: Decline relative to personal loans post-Sep 2018
- **Credit card write-offs**: Initial increase (forced recognition of bad debt), then decline
- **Personal loan balances**: May increase (substitution from credit cards)
- **FCA complaints**: Credit card complaints may spike at 18/27/36 month triggers
- **Net consumer credit**: Ambiguous — depends on whether the rule reduces total borrowing or redirects it

## Primary Specification

Δ(CC_t − PL_t) = α + Σβ_k · Event_k + γ · trend + ε_t

Where CC_t and PL_t are credit card and personal loan series (normalized), and Event_k are indicators for each policy event. Implementation via OLS on the cross-product gap with Newey-West HAC standard errors.

Robustness: synthetic control on credit cards using pre-2018 personal loan/overdraft donor pool; interrupted time series; permutation inference.

## Data Sources

1. **BoE Bankstats A5.6** (monthly):
   - VZRJ: Credit card outstanding amounts
   - B4TS: Other consumer credit outstanding
   - VZQO: Credit card gross lending
   - Write-offs: RPQTFHE (quarterly)

2. **FCA complaint data** (biannual):
   - Product-level complaint volumes (credit cards vs personal loans vs current accounts)
   - Firm-level complaint rates

3. **UK Finance** (monthly):
   - Card spending volumes
   - Repayment rates

## Fetch Strategy

BoE data: Direct CSV download from Bank of England Statistical Interactive Database.
FCA data: Published complaint returns (CSV).
UK Finance: Published monthly statistics.

All publicly available, no API key required.
