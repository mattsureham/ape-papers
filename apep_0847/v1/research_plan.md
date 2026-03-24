# Research Plan: Penny Wise, Lung Foolish

## Research Question

Did cuts to stop smoking services in England after 2015 causally reduce quit rates and worsen respiratory health outcomes (COPD admissions, lung cancer mortality)?

## Background

In April 2013, public health responsibilities transferred from the NHS to England's 152 upper-tier local authorities (LAs), funded by a ring-fenced public health grant. From 2015/16, the Treasury imposed real-terms cuts averaging 28% per capita by 2024. LAs had discretion over how to allocate these cuts across public health functions. Stop smoking services were disproportionately cut: national spending fell 36%, and CO-validated quit rates collapsed from 2,710 per 100k (2013/14) to 365 per 100k (2022/23).

## Identification Strategy

**Bartik (shift-share) IV:**
- **Share (Zi):** LA's 2013/14 baseline per-capita public health grant allocation. This was formula-based (determined by population health needs at that point in time), creating cross-sectional variation in exposure to subsequent cuts.
- **Shift (Zt):** National-level year-on-year change in total public health grant budget (set by HM Treasury). This is plausibly exogenous to any individual LA's smoking trends.
- **Instrument:** Predicted_Grant_it = Share_i × National_Total_t
- **First stage:** Predicted grant → Actual stop smoking service spending per capita
- **Second stage:** Actual stop smoking service spending → quit rates, smoking prevalence, COPD admissions

**Key identifying assumption:** Baseline grant shares are uncorrelated with differential trends in smoking/respiratory outcomes, conditional on controls. This is plausible because the formula was based on broad population health needs (not smoking-specific) and was set before the austerity cuts began.

**Falsification test:** No effect on non-smoking health outcomes (sexual health clinic visits, indicator 91735).

## Expected Effects and Mechanisms

- Larger cuts → fewer quit attempts → fewer successful quits → slower decline in smoking prevalence
- Downstream: higher COPD admissions and lung cancer mortality (with lag)
- Mechanism: stop smoking services provide behavioral support + pharmacotherapy access; without services, smokers lack structured cessation pathways

## Primary Specification

```
Y_it = β * SSS_Spending_it + X_it'γ + α_i + δ_t + ε_it
```

Instrumented by: `Predicted_Grant_it = BaselineShare_i × NationalTotal_t`

Where:
- Y = quit rate / smoking prevalence / COPD admission rate
- SSS_Spending = stop smoking service spending per capita
- X = time-varying controls (IMD decile, population, age structure)
- α_i = LA fixed effects, δ_t = year fixed effects

Clustered at LA level (~150 clusters).

## Data Sources

1. **Fingertips API (OHID):**
   - Smoking prevalence 18+ (indicator 92443): ~52K rows, 2011-2024
   - CO-validated quit rate (indicator 1211): ~1.7K rows, 2013/14-2022/23
   - COPD emergency admissions 35+ (indicator 92302): ~21K rows, 2010/11-2023/24
   - Lung cancer mortality (indicator 1203): ~28K rows, 2001-03 to present
   - Sexual health clinic attendance (indicator 91735): falsification

2. **Public health grant allocations:** DHSC published allocations by LA, 2013/14-2024/25

3. **Stop smoking service spending:** Local authority public health spending data (Section 251 returns / OHID local authority health profiles)

## Fetch Strategy

- Use `fingertipsR` R package for indicators
- Web-scrape or download DHSC grant allocation tables
- Merge on LA code (E-codes)
