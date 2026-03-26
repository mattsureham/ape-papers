# Research Plan: apep_1029

## Research Question

Do regulatory size thresholds in the UK Companies Act 2006 cause private firms to distort their reported size? If so, how large are the implied compliance costs at each threshold?

## Policy Setting

The Companies Act 2006 (ss.382, 465, 466) defines four size categories for private limited companies — micro, small, medium, and large — using three dimensions: turnover, balance sheet total, and number of employees. Each boundary triggers escalating regulatory obligations:

1. **Micro → Small (10 employees / £632K turnover):** Strategic report requirement, additional disclosure
2. **Small → Medium (50 employees / £10.2M turnover):** Mandatory statutory audit (s.477 exemption lost), IR35 off-payroll rules (April 2021), enhanced filing
3. **Medium → Large (250 employees / £36M turnover):** Modern Slavery Act reporting, gender pay gap reporting, full directors' report

A firm must exceed two of the three thresholds for two consecutive years to be reclassified upward ("two-of-three rule").

## Identification Strategy

**Multi-cutoff bunching** (Chetty et al. 2011; Kleven 2016). The key insight: if thresholds impose real costs, firms will bunch just below them and there will be a "hole" just above. The magnitude of bunching reveals the cost firms are willing to bear to stay below the threshold.

### Internal Replication
The Small→Medium threshold (50 employees, mandatory audit + IR35) should show *greater* bunching than the Micro→Small threshold (10 employees, disclosure only), because audit costs are an order of magnitude larger than disclosure costs. This ordered bunching pattern is the paper's key test.

### Estimation
- Standard polynomial bunching estimator (Chetty et al. 2011): fit polynomial to counterfactual density excluding the bunching region, estimate excess mass
- Bootstrap standard errors (1,000 replications)
- Bandwidth selection: test sensitivity from ±5 to ±20 bins around each threshold
- Convert excess mass to implied cost using Kleven-Waseem (2013) structural formula

## Expected Effects

1. **Small→Medium (50 employees):** Largest bunching — audit costs £5K-£30K/year, plus IR35 compliance
2. **Micro→Small (10 employees):** Moderate bunching — strategic report is modest cost
3. **Medium→Large (250 employees):** Moderate-to-large bunching — Modern Slavery and gender pay gap reporting

## Primary Specification

For each threshold k:
- Estimate counterfactual density using 7th-degree polynomial on employee counts, excluding [k-2, k+2]
- Excess mass b_k = (observed - counterfactual) / counterfactual in bunching region
- Standard errors via bootstrap

## Data Source and Fetch Strategy

**Companies House Accounts Bulk Data Product**
- Free download, no authentication
- XBRL/iXBRL filings with turnover, employee counts, balance sheet totals
- ~8,600 daily filings, ~1.3M company-year observations over 18 years (2008-2025)
- Will download daily zip files and parse iXBRL for relevant XBRL tags

**BasicCompanyData CSV** — 468MB monthly snapshot with SIC codes, incorporation date, company status for universe of UK companies

## Robustness Plan

1. Vary polynomial degree (5th, 7th, 9th)
2. Vary bunching window width
3. Placebo thresholds at round numbers away from regulatory boundaries
4. Industry-level heterogeneity (manufacturing vs. services)
5. Time-series: did bunching increase after IR35 reform (April 2021)?
