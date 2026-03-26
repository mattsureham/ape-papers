# Research Plan: Too Small to Comply

## Research Question

Did UK private-sector client firms strategically reduce their reported size to stay below the Companies Act 2006 "small company" threshold after IR35 off-payroll working rules were extended to the private sector in April 2021? If so, how large are the implied compliance costs?

## Policy Background

The UK's IR35 rules (ITEPA 2003, Chapter 10) determine whether a contractor working through a personal service company (PSC) should be treated as an employee for tax purposes. Originally, the contractor determined their own IR35 status. In April 2017, the responsibility shifted to the client for public-sector engagements. In April 2021 (delayed one year from 2020 due to COVID), this was extended to private-sector clients — but **only for medium and large companies**.

**Small company exemption:** Companies meeting 2 of 3 criteria under the Companies Act 2006 (s.382) are exempt:
- ≤50 employees
- ≤£10.2M annual turnover
- ≤£5.1M balance sheet total

Small companies continue to let contractors self-assess their IR35 status, avoiding compliance costs estimated at £500–£2,000 per contractor per year (HMRC estimates ~120,000 workers affected, £4.2B additional tax through March 2023).

## Identification Strategy

**Bunching-difference design** following Kleven (2016) and Kleven and Waseem (2013):

1. **Cross-sectional bunching:** Estimate the density of firms around the 50-employee threshold in the Companies House data. Under the null (no manipulation), the distribution should be smooth. Under the alternative, excess mass appears just below 50 after April 2021.

2. **Difference-in-bunching (DiB):** Compare the bunching ratio (below/above threshold) in:
   - **Time:** Pre-reform (2015–2020) vs. post-reform (2021–2024)
   - **Sector:** Contractor-intensive SICs (62, 70, 71, 74) vs. non-contractor SICs

3. **Built-in placebo:** The reform was announced for April 2020 but delayed to April 2021 due to COVID. The announcement year (2020) tests whether firms responded to anticipated vs. actual enforcement.

4. **Mechanism tests:**
   - Headcount reduction (firms at 51–55 moving to 48–50)
   - Subsidiary restructuring (splitting into multiple small entities)
   - Contractor-to-employee conversion (opposite direction)

## Expected Effects

- **Excess bunching** just below 50 employees in contractor-intensive sectors post-2021
- **Larger effect** in SIC 62 (computer programming/consultancy) where contractor usage is highest
- **Announcement effect** in 2020: partial anticipatory bunching before actual implementation
- **Implied compliance cost** recovered from the marginal buncher — the firm indifferent between staying small (and avoiding IR35) vs. growing (and bearing compliance costs)

## Primary Specification

Following Chetty et al. (2011) and Kleven (2016):
- Fit a counterfactual density using polynomial regression excluding the manipulation region [45, 55]
- Estimate excess mass B = (observed - counterfactual) in [45, 50] / counterfactual
- Standard errors via bootstrap (resample from observed distribution)
- DiB estimator: B_post,contractor - B_pre,contractor - (B_post,noncontractor - B_pre,noncontractor)

## Data Source and Fetch Strategy

**Primary:** Companies House Accounts Bulk Data
- Monthly bulk product: iXBRL-tagged annual accounts filed by all UK companies
- Extract: employee count (uk-core:AverageNumberEmployeesDuringPeriod), turnover, balance sheet
- ~5M active companies; ~1.3M company-years usable (with employee data)

**Secondary:** Companies House BasicCompanyData
- Monthly CSV snapshot: company number, SIC codes, incorporation date, company status
- Used to assign SIC codes and filter active companies

**Fetch approach:**
1. Download BasicCompanyData CSV for SIC code assignment
2. Use Companies House API (free, rate-limited at 600/5min) to query accounts for firms in the 20–80 employee range in target SIC codes
3. Build panel: company × filing-year with employee count, turnover, balance sheet

**Fallback:** If API rate limits are binding, use the FAME/ORBIS-equivalent free fields from Companies House or restrict to a subsample of SIC codes.

## Key Literature

- Kleven, H. (2016). "Bunching." Annual Review of Economics.
- Kleven, H. and M. Waseem (2013). "Using Notches to Uncover Optimization Frictions." QJE.
- Chetty, R. et al. (2011). "Adjustment Costs, Firm Responses, and Micro vs. Macro Labor Supply Elasticities." QJE.
- Adams, L., S. Moore, and A. Gore (2020). "Off-Payroll Working Rules." HMRC Research Report.
- Naomi Sherwood and Elke Sherwood (2022). "IR35 in the Private Sector." IFS Briefing Note.
