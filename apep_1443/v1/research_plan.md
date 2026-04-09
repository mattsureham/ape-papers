# Research Plan: Lock-In or Cash-Out?

## Research Question
How do holding-period capital gains tax notches affect housing transaction timing and prices? Taiwan's 2021 Consolidated Housing Tax 2.0 created steep notches at 2-year and 5-year marks (45%→35%→20%), generating sharp incentives to delay sales.

## Identification Strategy
**Multi-notch bunching** (Kleven & Waseem 2013). The running variable is holding period in days, measured from acquisition to sale. Tax notches at:
- 730 days (2 years): 45% → 35% (10pp drop)
- 1825 days (5 years): 35% → 20% (15pp drop)
- 3650 days (10 years): 20% → 15% (5pp drop)

**Key identification features:**
1. **Pre/post reform comparison:** Tax 1.0 (2016-2021) had notch at 365 days; Tax 2.0 shifted it to 730 days. The bunching should move with the notch.
2. **Grandfather clause placebo:** Properties acquired before Jan 1, 2016 are exempt — no bunching expected.
3. **Multiple notches of different sizes** allow estimation of behavioral elasticity at each margin.

## Expected Effects
- Excess mass of transactions just after 730-day and 1825-day thresholds
- Missing mass just before these thresholds
- Larger bunching at the 5-year notch (15pp) than the 2-year notch (10pp)
- Price effects: sellers crossing the notch may accept lower prices to transact sooner

## Primary Specification
Bunching estimator following Chetty et al. (2011) and Kleven & Waseem (2013):
- Fit polynomial to counterfactual density excluding bunching region
- Estimate excess mass b = (B - B̂)/B̂ where B is observed count and B̂ is counterfactual
- Bootstrap standard errors

## Data Source and Fetch Strategy
Taiwan Ministry of Interior, Actual Price Registration System (實價登錄):
- URL: https://plvr.land.moi.gov.tw/DownloadOpenData
- Bulk CSV downloads by quarter and municipality
- Fields: transaction date, construction date, total price, district, building type, area
- Coverage: 2012Q3-present, ~100K+ transactions per quarter island-wide
- Holding period computed from acquisition date to sale date within repeat-sale pairs

## Method Note
This is a bunching design (Kleven & Waseem 2013), not a difference-in-differences. Treatment exposure is determined by the tax regime (acquisition date determines which tax schedule applies). All properties acquired under Tax 2.0 face the same notch schedule; variation comes from where in the holding-period distribution each transaction falls.

## Key Risks
1. Acquisition date may not always be available — need to verify field coverage
2. Quarterly data granularity may smooth bunching near notch
3. COVID (2020-2021) overlaps with reform timing — need careful controls
