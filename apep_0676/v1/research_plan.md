# Research Plan: Compliance Cost Bunching in the UK Charitable Sector

## Research Question

Do UK charities manipulate their reported income to avoid audit and independent examination thresholds, and if so, how large is this distortion?

## Institutional Background

The Charities Act 2011 establishes two key compliance thresholds:
- **£25,000**: Charities with gross income above this must obtain an independent examination (~£500–£2,000 cost)
- **£1,000,000**: Charities above this must obtain a full statutory audit (~£5,000–£20,000+)

The Charities Act 2022 raised the independent examination threshold from £25,000 to £40,000, creating a natural experiment.

Scotland (OSCR) operates under separate legislation with different thresholds, providing a placebo test.

## Identification Strategy

**Bunching estimation** following Kleven and Waseem (2013):

1. **Primary analysis**: Estimate excess mass at £25K and £1M thresholds using the Charity Commission register (170K+ charities, exact income in pounds)
2. **Reform test**: Did bunching at £25K migrate to £40K after the Charities Act 2022 reform?
3. **Dose-response**: Is bunching larger at £1M (higher compliance cost) than at £25K?
4. **Scotland placebo**: Do OSCR-registered charities bunch at the same nominal thresholds despite different regulatory regime?

## Expected Effects

- Significant excess mass just below £25K and £1M thresholds
- Migration of bunching mass from £25K to £40K after the 2022 reform
- Larger bunching at £1M (proportional to compliance cost differential)
- No bunching at English thresholds for Scottish charities

## Primary Specification

Estimate counterfactual density using polynomial fit excluding the bunching region. Calculate excess bunching mass (b) and implied elasticity of reported income.

## Data Sources

1. **Charity Commission for England and Wales**: Full register download (15 datasets, daily updates)
   - `charity_annual_return_history`: Exact income, expenditure, reserves per year
   - `charity_classification`: Subsector codes for heterogeneity analysis
   - URL: https://register-of-charities.charitycommission.gov.uk/sector-data/top-10-charities

2. **OSCR (Scotland)**: Separate register download for placebo analysis
   - URL: https://www.oscr.org.uk/about-charities/search-the-register/charity-register-download

## Analysis Plan

1. Download Charity Commission register data (annual return history)
2. Construct income distribution in fine bins (£500 bins near thresholds)
3. Estimate counterfactual density via polynomial fitting
4. Calculate excess mass, standard errors via bootstrap
5. Test for reform-induced migration (pre/post 2022)
6. Run Scotland placebo
7. Heterogeneity by charity subsector (education, health, religion, etc.)

## Key Risks

- Data availability: Register may not have sufficient historical depth for reform analysis
- The £25K→£40K reform is recent (2022), so post-reform observations may be limited
- Need to ensure income variable is gross income (not net), matching statutory definition
