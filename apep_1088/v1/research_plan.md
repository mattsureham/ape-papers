# Research Plan: The Compliance Ceiling

## Research Question

Did the 2010 IRS threshold increase (from $100K to $200K for Form 990-EZ eligibility) causally unlock revenue growth for nonprofits that had been bunching below the old $100K threshold to avoid full Form 990 disclosure?

## Background

Before 2010, nonprofits with gross receipts above $100K had to file the full 12-page Form 990 (with schedules on compensation, governance, programs). Organizations below $100K could file the simpler 4-page Form 990-EZ. The literature documents significant bunching just below $100K, suggesting disclosure avoidance. IRS Notice 2009-86 raised the EZ threshold to $200K effective tax year 2010, freeing organizations in the $100K-$200K range from full disclosure requirements.

## Identification Strategy

**Difference-in-differences with bunching identification:**

1. **Treatment group:** Nonprofits that bunched below $100K in the pre-period (2006-2009), identified by having gross receipts consistently in the $80K-$100K range with suspicious clustering at round numbers. These are the organizations whose growth was plausibly constrained by the disclosure threshold.

2. **Control group:** Nonprofits in the $60K-$80K range (below the manipulation window but same size class) that had no incentive to suppress revenue. Also: organizations in the $40K-$60K range as a second control.

3. **Treatment timing:** Tax year 2010 (IRS Notice 2009-86, announced late 2009).

4. **Estimand:** Post-reform revenue growth trajectories for bunchers vs non-bunchers.

## Expected Effects and Mechanisms

- **Primary:** Bunchers should show accelerated revenue growth after 2010 as the constraint is removed (positive, moderate SDE)
- **Mechanism — Revenue reporting:** Some "growth" is simply honest reporting (was suppressing, now reports truthfully)
- **Mechanism — Real growth:** Organizations may invest in fundraising/programs once no longer constrained
- **Decomposition test:** Compare revenue growth with program expense growth. If real growth, both should increase. If just reporting, revenue rises but expenses stay flat.

## Primary Specification

```
Y_{it} = α_i + δ_t + β(Buncher_i × Post_t) + ε_{it}
```

Where Y is log(gross receipts), Buncher_i is an indicator for orgs in the $80K-$100K manipulation window pre-reform, and Post_t is an indicator for tax years 2010+. Organization and year fixed effects absorbed. Cluster SEs at organization level.

## Data Source and Fetch Strategy

1. **IRS 990 Electronic Filing Index** — AWS S3 bucket `s3://irs-form-990` contains XML index files (2011-2023). Each row maps an EIN to a filing URL.
2. **ProPublica Nonprofit Explorer API** — `https://projects.propublica.org/nonprofits/api/v2/organizations/{ein}.json` returns revenue panel by year for individual organizations.
3. **IRS Exempt Organizations Business Master File (EO BMF)** — Quarterly extract with all registered tax-exempt orgs, their NTEE codes, and filing requirements.

**Strategy:**
- Download EO BMF to get universe of 501(c)(3) organizations
- Use IRS 990 index to identify Form 990 vs 990-EZ filers in 2006-2009
- Identify bunchers: orgs filing 990-EZ with gross receipts in $80K-$100K range
- Track same orgs forward through 2010-2020 using the XML index
- Pull revenue/expense panel from ProPublica API for treatment and control groups

## Exposure Alignment

Treatment and outcome are measured at the same unit (organization-year). The "constrained" group consists of organizations whose revenue places them near the $200K Form 990-EZ threshold — they are directly exposed to the compliance cost discontinuity. Controls are organizations in the $120K-$160K range who face no imminent threshold crossing. Both groups are observed at the same frequency (annual) and from the same source (IRS electronic filings via ProPublica). The treatment operates at the organizational level (filing requirement depends on individual organization's gross receipts), and the outcome (revenue, expenses) is measured at the same level.

## Key Risks

1. Data: IRS XML data starts electronically in 2011 — pre-period data from SOI extracts or e-filing index
2. Attrition: Some orgs may close post-reform (address with bounds)
3. Composition: New orgs entering post-reform could confound (restrict to orgs existing pre-2010)
