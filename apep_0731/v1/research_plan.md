# Research Plan: The Audit Cliff

## Research Question
Do state-mandated charitable audit thresholds create "compliance cliffs" that distort nonprofit revenue reporting? Using a multi-threshold bunching design across 33 US states with thresholds ranging from $100,000 to $2,000,000, I estimate the behavioral elasticity of reported revenue to audit requirements and quantify the implicit tax that audit mandates impose on nonprofit growth.

## Identification Strategy
**Multi-threshold bunching estimation** following Kleven and Waseem (2013):

1. **Within-state bunching:** For each of the 33 states with audit thresholds, estimate excess mass below the threshold using polynomial counterfactual density estimation. The key identifying assumption is that the counterfactual revenue distribution is smooth through the threshold.

2. **Cross-state difference-in-bunching:** Compare revenue distributions in states WITH audit thresholds to states WITHOUT (TX, FL, and ~17 others). This controls for any natural clustering at round numbers.

3. **Dose-response across thresholds:** The 33 states' thresholds span $100K to $2M, providing variation in the "audit cliff" height. Larger audit cost relative to revenue at lower thresholds should produce more bunching — testing the cost elasticity.

4. **Internal replication:** Each state-threshold pair is an independent bunching experiment, providing 33 replications of the same phenomenon.

## Expected Effects and Mechanisms
- **Primary:** Excess mass of nonprofits just below their state's audit threshold, with a corresponding "missing mass" just above. The magnitude should be proportional to audit costs relative to threshold level.
- **Mechanism:** Audit costs of $10K-$100K+ create an implicit tax on crossing the threshold. Nonprofits respond by (a) underreporting revenue, (b) timing donations, (c) splitting into multiple entities, or (d) genuinely constraining fundraising.
- **Dose-response prediction:** Higher thresholds (e.g., CA at $2M) should show less bunching in percentage terms because audit costs are smaller relative to revenue.

## Primary Specification
Bunching estimation using the `bunching` R package:
- Running variable: reported revenue (or contributions)
- Threshold: state-specific audit requirement level
- Bandwidth: ±30% of threshold
- Polynomial order: 7 (with robustness for 5-9)
- Excluded region: determined by visual inspection and convergence

## Data Source and Fetch Strategy
1. **IRS Exempt Organizations Business Master File (EO BMF):** Public CSV from IRS.gov containing ~1.9M tax-exempt organizations with REVENUE_AMT, state, NTEE classification, ruling date. Download directly from IRS.
2. **IRS Form 990 XML filings (2011-2023):** From apps.irs.gov, providing detailed revenue breakdowns (contributions vs. program service revenue vs. investment income). Use the AWS S3 index for bulk access.
3. **State threshold compilation:** Hand-coded from state charity registration statutes (33 states with thresholds, ~18 without).

## Key Risks
- Revenue amounts in EO BMF may be total revenue rather than contributions (some states threshold on contributions, others on total revenue)
- Some states have "review" vs. "full audit" tiers, creating multiple thresholds
- Filing compliance varies — some small nonprofits don't file
