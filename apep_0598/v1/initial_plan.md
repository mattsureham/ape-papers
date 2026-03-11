# Initial Research Plan: Forced Into the Light

## Research Question

Did Greece's 2015 capital controls — which shut banks for three weeks and capped ATM withdrawals at EUR 60/day while exempting card transactions — permanently shift economic activity from cash to electronic payments, inadvertently formalizing a significant portion of the shadow economy?

## Identification Strategy

### Method 1: Synthetic Control Method (Primary)

Construct synthetic Greece from 14 EU donor countries (Portugal, Spain, Italy, Ireland, Cyprus, Bulgaria, Romania, Croatia, Slovakia, Slovenia, Lithuania, Latvia, Estonia, Malta) using monthly retail trade turnover indices (Eurostat STS_TRTU_M).

- **Pre-treatment:** January 2010 – May 2015 (65 months)
- **Treatment:** June 28, 2015 (bank closure; capital controls effective June 29)
- **Post-treatment:** July 2015 – December 2019 (54 months, through full control removal)
- **Inference:** Placebo-in-space permutation tests (RMSPE ratios), leave-one-out robustness, augmented SCM (Ben-Michael et al. 2021)

### Method 2: Cross-Sector Intensity DiD (Complementary)

Within Greece, exploit variation in pre-treatment cash dependence across NACE retail subsectors.

Y_st = α_s + γ_t + β(CashIntensity_s × Post_t) + ε_st

- s indexes NACE 3-digit retail sectors, t indexes months
- CashIntensity_s = share of transactions conducted in cash in sector s as of 2014
- Sectors: G473 (fuel, highest cash), G472 (food/beverages, medium), G471 (non-specialized, lowest)
- Pre-trend: CashIntensity_s × YearMonth_t interactions for 2013–2015H1

## Expected Effects and Mechanisms

1. **Immediate contractionary effect:** Sharp drop in retail turnover, concentrated in high-cash sectors (fuel > food > general retail). Expected magnitude: 7–15% drop in fuel, 5–8% in food, 2–5% in non-specialized.

2. **Persistence/hysteresis:** Payment infrastructure investments (POS terminals) are sunk costs. Once installed, the shift persists even after controls are relaxed. The SCM gap should narrow but not close completely after 2019.

3. **Accidental formalization:** If capital controls forced shadow-economy transactions onto electronic rails:
   - VAT revenue should grow faster in high-cash sectors post-2015
   - The VAT gap (estimated 34% in 2014) should narrow
   - Card transaction volumes should show permanent level shift

## Primary Specification

SCM with aggregate retail turnover (G47). Donor pool: 14 EU countries. Matching on pre-treatment turnover trajectory, GDP growth, unemployment, trade openness, government debt/GDP, household consumption expenditure.

## Planned Robustness Checks

1. Placebo-in-space: SCM for each of 14 donors as if treated
2. Leave-one-out: Drop each donor country and re-estimate
3. Placebo-in-time: Treatment at arbitrary pre-period dates
4. Augmented SCM (Ben-Michael et al. 2021)
5. Cross-sector DiD with continuous cash-intensity measure
6. Subsector heterogeneity within retail
7. VAT revenue mechanism test

## Exposure Alignment

- **Who is actually treated?** All Greek economic agents conducting transactions — consumers, businesses, and retailers — were subject to capital controls beginning June 29, 2015. The controls affected the entire Greek economy, not a subset.
- **Primary estimand population:** Greek retail sectors (SCM: aggregate G47 retail; DiD: three subsectors G471, G472, G473). The treatment intensity varies by pre-existing cash dependence.
- **Placebo/control population:** SCM: 14 EU donor countries unaffected by capital controls. DiD: lower-cash-intensity retail subsectors within Greece serve as relative controls.
- **Design:** Cross-country SCM (Greece vs synthetic counterfactual) + within-country continuous-treatment DiD (cash intensity × post). The DiD is not a standard binary treatment — it exploits continuous variation in cash share across sectors.

## Power Assessment

- SCM: 1 treated unit, 14 donors, 65 pre-periods, 54 post-periods
- Effect magnitude: 7.3% aggregate drop (very large for SCM)
- Sector DiD: 3+ sectors × 120 months, continuous intensity treatment
- Pre-treatment RMSPE expected to be small given long pre-period
