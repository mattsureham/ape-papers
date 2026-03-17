# Research Plan: Nonprofit Disclosure Cost Bunching

## Research Question
Do tax-exempt organizations strategically manipulate reported gross receipts to avoid the compliance burden of IRS Form 990, and what does the observed bunching imply about the implicit cost of nonprofit financial disclosure?

## Identification Strategy
Standard bunching estimation (Chetty et al. 2011; Kleven 2016) at the $200,000 gross receipts threshold separating Form 990-EZ (4 pages) from Form 990 (12+ pages with mandatory schedules).

**Three validation tests:**
1. **$50,000 placebo**: Form 990-N vs 990-EZ threshold. Minimal compliance cost difference (e-Postcard vs 4-page form). Absence of bunching validates the mechanism: organizations respond to disclosure burden, not mere filing requirements.
2. **2010 reform migration**: Threshold raised from $100K to $200K for tax year 2010. If bunching migrated from $100K to $200K, this confirms behavioral response to the specific threshold.
3. **Cross-state heterogeneity**: States with additional audit thresholds near $200K should show amplified bunching (stacking federal + state incentives).

## Expected Effects and Mechanisms
- **Primary**: Excess mass just below $200K — organizations underreport or constrain revenue to avoid full Form 990 filing.
- **Mechanism 1 (Compliance cost)**: Form 990 requires detailed schedule attachments (compensation, governance, lobbying). Small nonprofits may lack accounting infrastructure.
- **Mechanism 2 (Transparency avoidance)**: Full Form 990 is publicly available and scrutinized by donors, media, state AGs. Some organizations may prefer opacity.
- **Heterogeneity**: Expect stronger bunching among (a) organizations without paid staff, (b) smaller asset bases, (c) organizations in categories with governance sensitivity (e.g., foundations vs. public charities).

## Primary Specification
Following Kleven (2016):
- Bin revenue in $1,000 bins around $200K threshold
- Fit 7th-degree polynomial to bins outside excluded region [180K, 220K]
- Estimate excess bunching mass b = (actual count - counterfactual count) in bunching region
- Bootstrap SE via resampling bin counts
- Convert to implied elasticity of reported revenue with respect to disclosure threshold

## Data Source and Fetch Strategy
**Primary**: IRS Exempt Organizations Business Master File (EO BMF)
- Four regional CSV files: eo1.csv through eo4.csv
- URL: https://www.irs.gov/charities-non-profits/exempt-organizations-business-master-file-extract-eo-bmf
- Fields: EIN, STATE, NTEE_CD, FILING_REQ_CD, REVENUE_AMT, INCOME_AMT, ASSET_AMT
- ~1.9M organizations total; ~555K with positive revenue

**Note**: EO BMF is a cross-sectional snapshot (current quarter). For the 2010 reform analysis, we need historical snapshots. The National Center for Charitable Statistics (NCCS/Urban Institute) archived EO BMF extracts. If unavailable, we use the cross-sectional design at $200K as the primary analysis and note the panel limitation.
