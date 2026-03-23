# Research Plan: The Walking Dead of the Nonprofit Sector

## Research Question

Does mass de-registration of dormant ("zombie") nonprofits create creative destruction — freeing resources for new, active organizations — or collateral damage — disrupting local charitable ecosystems? The Pension Protection Act of 2006 required all tax-exempt organizations to file annually with the IRS, with automatic revocation after three consecutive years of non-filing. The first massive wave (~275,000 revocations) hit in June 2011. We exploit cross-county variation in revocation intensity to estimate effects on new nonprofit formation, charitable giving, and nonprofit-sector employment.

## Identification Strategy

**Design:** Continuous-treatment difference-in-differences.

**Treatment variable:** County-level revocation intensity = (number of nonprofits auto-revoked in 2011) / (number of registered nonprofits pre-2010). This creates a continuous dose measure ranging from near-zero to >50% in some counties.

**Fixed effects:** County FE + Year FE. County FE absorb time-invariant county characteristics (size, demographics, wealth). Year FE absorb national trends (recession recovery, giving trends).

**Clustering:** Standard errors clustered at the county level.

**Pre-period:** 2006–2010 (4 years). **Post-period:** 2011–2020 (10 years, stopping before COVID-era disruption to nonprofit filing patterns).

**Key threat:** Counties with more zombie nonprofits may differ systematically. We address this via:
1. Pre-trend tests (interaction of revocation intensity × year dummies)
2. Controls for county population, income, poverty rate
3. Placebo test using revocation intensity on outcomes in pre-period
4. Robustness to dropping top/bottom decile of revocation intensity

## Expected Effects and Mechanisms

**Creative destruction hypothesis (positive):** Revocation removes paper organizations that crowd donor attention, grant eligibility lists, and IRS processing queues. New entrants face less competition and form at higher rates. Net effect: more new formations, maintained/higher giving, potentially higher employment per organization.

**Collateral damage hypothesis (negative):** Some revoked organizations were merely filing-delinquent, not truly inactive. Loss of tax-exempt status forces genuine small nonprofits to cease operations. Donors lose recognized giving targets. Net effect: fewer formations, lower giving, reduced employment.

**Likely direction:** Creative destruction, especially for new formations (reduced barrier to entry from less crowded sector). Giving effects may be null or small positive (donor behavior primarily responds to active solicitation, not sector size). Employment effects uncertain.

## Primary Specification

$$Y_{ct} = \alpha_c + \gamma_t + \beta \cdot \text{RevocationIntensity}_c \times \text{Post}_t + X_{ct}'\delta + \varepsilon_{ct}$$

Where:
- $Y_{ct}$: outcome in county $c$, year $t$
- $\alpha_c$: county fixed effects
- $\gamma_t$: year fixed effects
- $\text{RevocationIntensity}_c$: share of pre-2010 nonprofits revoked
- $\text{Post}_t$: indicator for $t \geq 2011$
- $X_{ct}$: time-varying controls (population, per capita income)

**Event study:** Replace $\beta \cdot \text{Post}_t$ with year-specific coefficients $\sum_k \beta_k \cdot \text{RevocationIntensity}_c \times \mathbb{1}[t = k]$ for $k \in \{2006, \ldots, 2020\}$.

## Data Sources and Fetch Strategy

1. **IRS Auto-Revocation List** — `https://www.irs.gov/charities-non-profits/automatic-revocation-of-exemption-list` (bulk CSV download). Contains EIN, organization name, city, state, ZIP, revocation date, exemption type. ~800K records.

2. **IRS Exempt Organizations Business Master File (EO BMF)** — `https://www.irs.gov/charities-non-profits/exempt-organizations-business-master-file-extract-eo-bmf`. Monthly extracts. Ruling date = proxy for formation. Available as bulk CSV by region.

3. **IRS Statistics of Income (SOI) County Data** — `https://www.irs.gov/statistics/soi-tax-stats-county-data`. Annual county-level aggregates including charitable deductions (amounts, number of returns claiming).

4. **Census QWI (Quarterly Workforce Indicators)** — Via Census API. NAICS 813 (Religious, Grantmaking, Civic, Professional Organizations). County-quarter employment and earnings.

5. **Census County Population Estimates** — Via Census API. Annual county population for controls.

## Outcome Variables

| Outcome | Source | Unit | Measure |
|---------|--------|------|---------|
| New nonprofit formations | EO BMF ruling dates | County-year | Count of new rulings per 10K population |
| Charitable giving | SOI county data | County-year | Charitable deductions per return ($) |
| Nonprofit employment | QWI NAICS 813 | County-year | Average quarterly employment |
| Nonprofit earnings | QWI NAICS 813 | County-year | Average quarterly earnings per worker |
