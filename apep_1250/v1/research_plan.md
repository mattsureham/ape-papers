# Research Plan: Possession and Desperation

## Research Question

Did the UK's January 2, 2015 high-cost short-term credit (HCSTC) price cap increase housing distress in high-payday-exposure areas of England and Wales? The motivating mechanism is consumption smoothing: if payday loans were used to bridge short-term rent shocks, removing them should raise landlord possession claims in places that depended more heavily on payday credit.

## Identification Strategy

The national policy has no staggered rollout, so the paper uses cross-area exposure interacted with the common post-2015 shock.

1. Treatment intensity:
   Regional HCSTC loans per 1,000 adults from the FCA's published Product Sales Data underlying tables. Public regional data are only available for July 2017 to June 2018, so this is a post-cap proxy for persistent payday-market intensity rather than a clean pre-cap dose.
2. Outcome:
   Local-authority-quarter possession claims from the Ministry of Justice statistical data zip.
3. Core specification:
   Continuous-treatment DiD with local-authority fixed effects and quarter fixed effects.
4. Preferred estimand:
   A stacked triple-difference style comparison that uses private landlord claims as the treated outcome and mortgage possession claims as a within-place comparison outcome. This absorbs common local housing-market shocks that should affect both tenants and owner-occupiers.
5. Inference:
   Cluster at the region level and add a permutation/randomization test because treatment varies at the regional level with only 10 effective England-and-Wales regions.

## Exposure Alignment

The people plausibly affected by the policy are financially stressed households that would otherwise have used high-cost short-term credit to smooth rent, mortgage, or bill payments. Public data do not identify those borrowers directly. Instead, the design observes:

1. Treatment variation at the region level:
   FCA loans per 1,000 adults by region, measured in 2017--18, which proxies for places where payday borrowing remained relatively common after the cap.
2. Outcomes at the local-authority-quarter level:
   Court possession claims filed against renters and mortgagors.

This means the estimating equation does not compare treated and untreated households. It compares local authorities embedded in regions with higher versus lower payday-market intensity, then asks whether private possession claims moved differently from mortgage claims after January 2015. The paper will state this alignment explicitly and treat the estimates as evidence on regional exposure, not individual borrower treatment effects.

## Why This Design Is Credible Enough To Try

- The MoJ data provide long pre-period coverage, allowing direct pre-trend inspection.
- The outcome is closer to the proposed mechanism than broader labor-market or insolvency aggregates.
- Mortgage claims provide a built-in comparison outcome from the same courts and local authorities.

## Main Threats

1. Treatment-outcome mismatch:
   Exposure is regional while outcomes are local-authority-quarter. This is the design's main weakness. The paper will be explicit that identification comes from differential regional exposure, even though outcomes are observed below the treatment level.
2. Post-cap treatment measurement:
   The public FCA regional series is observed after the cap, so it may reflect post-reform market sorting as well as persistent underlying demand.
3. Few effective treatment clusters:
   England and Wales contribute only 10 exposed regions. Standard clustered inference may over-reject, so the robustness section will report a permutation-based p-value and a region-specific trend specification.
4. Concurrent housing-policy changes:
   Other changes in the rental market could contaminate post-2015 trends. The private-versus-mortgage comparison is intended to difference out shocks that hit the local housing market broadly, but renter-specific reforms like Universal Credit rollout remain a concern.

## Expected Effects and Mechanisms

- Hypothesis from the manifest:
  Private landlord claims should rise in more exposed regions after the cap if payday credit had a rent-smoothing function.
- Alternative hypothesis:
  Claims do not rise, or even fall, if payday loans mainly deepened debt problems rather than preventing arrears.

## Primary Specification

At the local-authority-quarter level:

\[
\Delta \log(1+\text{PrivateClaims}_{it}) - \Delta \log(1+\text{MortgageClaims}_{it})
= \beta \, \text{HCSTCExposure}_{r(i)} \times \text{Post}_{t} + \alpha_i + \gamma_t + \varepsilon_{it}
\]

where:

- \(i\) indexes local authorities,
- \(t\) indexes quarters,
- \(r(i)\) maps each local authority to its FCA region,
- \(\alpha_i\) are local-authority fixed effects,
- \(\gamma_t\) are quarter fixed effects.

## Planned Robustness Checks

1. Region-specific linear trends.
2. Separate landlord-only and mortgage-only continuous DiD estimates.
3. Event-study table on the private-minus-mortgage differential.
4. Permutation inference by reshuffling regional exposure values across the 10 regions.
5. Short-window estimate limited to 2010--2019.

## Data Sources and Fetch Strategy

1. FCA HCSTC lending data:
   `https://www.fca.org.uk/publication/data/underlying-data-hcstc-consumer-credit-01-19.xlsx`
2. MoJ possession claims data zip:
   `https://assets.publishing.service.gov.uk/media/689b69807b0b51a850e940c1/Mortgage_and_landlord_statistical_data.zip`
3. MoJ release page for documentation:
   `https://www.gov.uk/government/statistics/mortgage-and-landlord-possession-statistics-april-to-june-2025`

## Method Notes

- This is a common-shock, continuous-intensity DiD rather than staggered adoption.
- Because treatment varies at the region level, the paper will avoid inflated claims from local-authority-level precision.
- If the region-trend and permutation checks overturn the baseline estimate, the paper will be written as a disciplined null.
- The contribution is therefore narrower than a fully causal household-treatment design: it tests whether regions with higher payday-market intensity saw larger post-cap changes in formal housing distress.
