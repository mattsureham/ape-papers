# Research Ideas

## Idea 1: No-Fault Eviction Abolition and Private Rental Supply: Evidence from Wales
**Policy:** The Renting Homes (Wales) Act 2016, implemented 1 December 2022, abolished Section 21 no-fault evictions and converted all tenancies to 'occupation contracts' with six-month minimum notice. Wales was three years ahead of England's equivalent Renters' Rights Act 2025. All 22 Welsh Local Authorities were treated simultaneously on 1 December 2022.
**Outcome:** Monthly residential transaction volumes from HM Land Registry Price Paid Data (24M+ transactions, England and Wales, 1995-present). Secondary: leasehold/freehold composition shifts (proxy for landlord exit), ONS Private Rental Market Statistics (quarterly median rents by LA).
**Identification:** Difference-in-Differences comparing 22 Welsh LAs (treated December 2022) against ~309 English LAs (control). Panel: January 2018 - December 2025, monthly frequency (96 periods, 48 pre-treatment). Callaway-Sant'Anna estimator. Built-in placebo: owner-occupied properties are unaffected by eviction reform. Border-county subsample (Herefordshire, Shropshire, Gloucestershire, Cheshire West) provides tight geographic control. Permutation inference for p-values given 22 treated clusters.
**Why it's novel:** No published academic paper uses this Act as a quasi-experiment. Welsh Government evaluation is qualitative only. Existing rent-regulation literature (Diamond et al. 2019, Autor et al. 2014) uses US contexts. This would be the first causal estimate of eviction reform on landlord supply response for any UK jurisdiction, directly informing England's ongoing Renters' Rights Act implementation.
**Feasibility check:** Confirmed — Land Registry bulk CSVs download with no authentication; Wales postcodes present (~29K Welsh records per 500K rows); exact statutory date known (1 Dec 2022); 48 months pre-period; all 309 English LAs as controls. MDE ~8-12% with 22 treated LAs and 48 pre-periods.

## Idea 2: Avoidance vs. Adjustment at the Child Benefit Notch
**Policy:** UK High Income Child Benefit Charge (HICBC) at £50,000 adjusted net income (January 2013), reformed April 2024 to £60,000 threshold.
**Outcome:** Income distribution from ONS ASHE (25M PAYE workers), pension contribution bunching, HMRC HICBC opt-out rates.
**Identification:** Bunching estimation at the notch; channel decomposition using self-employed vs PAYE differential frictions. 2024 threshold increase provides built-in falsification test.
**Why it's novel:** Clean notch structure with 11-year pre-reform window; 440K treated units; 2024 reform provides natural experiment within the natural experiment.
**Feasibility check:** Confirmed — NOMIS ASHE data accessible; HMRC statistics published annually. Novel bunching design for UK tax-benefit system.

## Idea 3: Universal Credit Full Service and the Bottom of the Wage Distribution
**Policy:** Universal Credit Full Service rollout (2015-2018), staggered by Local Authority. Replaces legacy benefits with 63% effective marginal taper rate on earnings.
**Outcome:** p10 and p20 of gross annual pay distribution from NOMIS ASHE (369 LAs, 2012-2020).
**Identification:** Staggered DiD (Callaway-Sant'Anna) exploiting LA-level rollout timing driven by DWP IT/operations scheduling, not local labor market conditions.
**Why it's novel:** Existing UC literature focuses on employment transitions (including APEP apep_0473). No published study examines wage distribution effects. 369 treated LAs with staggered timing provides excellent power.
**Feasibility check:** Confirmed — NOMIS ASHE accessible via API; UC rollout dates published by DWP. 2,952 LA-year cells, ~340 effective LAs.
