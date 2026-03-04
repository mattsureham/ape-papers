# Research Ideas — UK Local Government Policy and Housing Markets

## Idea 1: The Hidden Costs of Devolved Austerity — Council Tax Support Localization and Household Distress

**Policy:** In April 2013, the UK government abolished the national Council Tax Benefit (CTB) and devolved responsibility to English Local Authorities, simultaneously cutting the budget by ~10%. Each LA designed its own Council Tax Support (CTS) scheme, choosing minimum payment rates from 0% to 30%+ that working-age claimants must pay. Crucially, pensioners were protected by law under a national scheme with identical entitlements.

**Outcome:** Council Tax collection rates and arrears by LA (DLUHC annual statistics via https://www.gov.uk/government/collections/council-tax-statistics); Property prices (HM Land Registry PPD via http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/); Crime by LA (data.police.uk monthly CSV archive); Claimant counts (NOMIS API via https://www.nomisweb.co.uk/api/v01/)

**Treatment:** CTS expenditure per working-age claimant by LA (DLUHC/DWP statistics) — pre-reform nationally uniform, post-reform diverged. IFS Report R153 (Adam & Browne 2014) provides 2013/14 minimum payment rates for all 326 LAs.

**Identification:**
- Continuous-treatment DiD: Y_{lt} = α_l + γ_t + β(CutIntensity_l × Post_t) + X_{lt}δ + ε_{lt}
- Treatment intensity = relative change in CTS expenditure per working-age claimant from 2012/13 to 2013/14 (varies 0% to 100% across LAs)
- Pre-period (2008-2013): CTB was national → all LAs had identical generosity → parallel trends nearly by construction
- Post-period (2013-2024): 11 years of differential treatment
- Built-in placebo: Pensioners (exempt from all changes — same LAs, same time, different group)

**Why it's novel:**
- No peer-reviewed economics journal article uses modern causal inference on this reform
- IFS Report R153 (Adam, Joyce, Pope 2019) is the closest work but uses basic regression, predates Callaway-Sant'Anna/de Chaisemartin-D'Haultfoeuille revolution, and was never published in a journal
- Multi-outcome welfare analysis (collection rates + arrears + crime + property prices) is unexplored
- Trade-off discovery: fiscal savings from devolution vs. increased household debt, enforcement costs, and downstream social costs

**Feasibility check:**
- Variation: 326 English LAs with continuous treatment intensity. Well above 20-unit threshold.
- Data access: DLUHC CTS statistics (verified on gov.uk), Land Registry PPD (verified, CSV download), Police API archives (verified), NOMIS (verified with API key)
- Pre-periods: 5+ years of pre-reform data (2008-2013)
- Not overstudied: IFS reports only, no top-journal causal inference paper

**Design strengths for tournament:**
- Built-in pensioner placebo (cf. EPC paper's owner-occupier placebo — ranked #3)
- Multi-margin welfare narrative (debt + crime + property prices + fiscal)
- 2.4M affected working-age households = first-order stakes
- Trade-off/substitution discovery (fiscal savings offset by social costs)
- 11-year post-period (long horizon preferred by judges)

---

## Idea 2: Taxing Vacancy — Council Tax Empty Homes Premiums and Housing Supply

**Policy:** From April 2013, English LAs could charge a 50% Council Tax premium on homes empty for 2+ years. Parliament authorized escalation: 100% (April 2019), 200% for 5+ year empties (April 2020), 300% for 10+ year empties (April 2021), and reduced the threshold to 1+ year empty (April 2024). LAs had discretion over whether and when to adopt each tier.

**Outcome:** Long-term empty dwelling counts by LA (DLUHC CTB1 annual data via https://www.gov.uk/government/collections/council-taxbase-statistics); Property prices (HM Land Registry PPD via S3 bulk download); Net additional dwellings (DLUHC housing supply statistics by LA); Planning permissions (DLUHC live tables)

**Treatment:** Premium rates by LA by year (DLUHC CTB1 forms record number of dwellings charged premiums and premium levels). 292 of 296 billing authorities now charge a premium, with staggered adoption of higher tiers.

**Identification:**
- Staggered dose-response DiD: Multiple policy shocks (2013, 2019, 2020, 2021, 2024) with LA-level variation in adoption timing and premium level
- Callaway-Sant'Anna or de Chaisemartin-D'Haultfoeuille for heterogeneous treatment timing
- Control: LAs that adopted premium later or at lower levels

**Why it's novel:**
- NO existing causal evaluation of UK empty homes premiums (zero academic papers)
- Seguin (2019, Journal of Public Economics) studied French vacancy tax (Taxe sur les Logements Vacants) — found 13% vacancy reduction — providing clean comparison and framing
- Fills gap: does vacancy taxation bring homes back into use, or just trigger reclassification?

**Feasibility check:**
- Variation: 296 billing authorities, staggered across 5 policy shocks. Exceeds 20-unit threshold.
- Data access: DLUHC CTB1 (verified on gov.uk), Land Registry PPD (verified), DLUHC housing supply (verified)
- Pre-periods: Premiums enabled April 2013, data from ~2010 onward
- Not overstudied: No causal evaluation exists

---

## Idea 3: The Rent Squeeze — Local Housing Allowance Freezes and Tenant Welfare

**Policy:** Local Housing Allowance (LHA) rates, which cap Housing Benefit for private renters, were frozen from 2016-2020. Because market rents continued rising, the gap between LHA and actual rents grew differentially across Broad Rental Market Areas (BRMAs). In March 2020, LHA was temporarily reset to the 30th percentile of rents (COVID relief), then re-frozen from April 2021.

**Outcome:** Homelessness statistics by LA (DLUHC quarterly via https://www.gov.uk/government/collections/homelessness-statistics); Private rents (ONS IPHRP via https://api.beta.ons.gov.uk/); Housing Benefit caseloads (DWP Stat-Xplore by LA); Eviction/possession claims (Ministry of Justice by county court)

**Treatment:** LHA rates by BRMA (Valuation Office Agency, published annually). Treatment intensity = cumulative gap between LHA rate and 30th percentile market rent during the 2016-2020 freeze period.

**Identification:**
- Dose-response DiD: BRMAs where rents grew faster experienced a bigger squeeze
- Double shock: freeze (2016) → relief (2020) → re-freeze (2021) provides built-in placebo test (relief period should show reversal)
- ~150 BRMAs in England provide adequate cross-sectional variation

**Why it's novel:**
- LHA freeze discussed extensively in policy advocacy but never rigorously evaluated with DiD
- Double shock (freeze-relief-refreeze) provides rare internal replication
- Multi-outcome (homelessness + evictions + rents + caseloads) enables welfare narrative
- Direct policy relevance (LHA rates are a live policy lever)

**Feasibility check:**
- Variation: ~150 BRMAs with continuous treatment intensity. Adequate.
- Data access: VOA LHA rates (public), ONS rents (public), DLUHC homelessness (public), DWP Stat-Xplore (public)
- Pre-periods: LHA set at 30th percentile 2012-2016 → 4 pre-freeze years
- Literature: Policy reports only, no peer-reviewed causal evaluation

---

## Idea 4: Licensing Landlords — Selective Licensing and Housing Market Outcomes

**Policy:** Under the Housing Act 2004, LAs can require all private landlords in designated areas to obtain a license. Adoption is staggered: ~46 LAs by 2019, 100+ by 2024, with varying geographic scope (borough-wide vs. ward-specific).

**Outcome:** Property prices and transaction volumes (HM Land Registry PPD via S3 bulk download); Rents (ONS IPHRP via ONS API); Crime (data.police.uk monthly CSV archives); Housing conditions (EPC data via https://epc.opendatacommunities.org/)

**Treatment:** Adoption dates from Petersen & Alexiou (2026, Environment & Planning B) documenting all 309 English LAs 2006-2019. Post-2019 adoptions from LA websites / DLUHC notifications.

**Identification:**
- Staggered DiD: LAs adopting licensing at different times vs. never-adopters
- Built-in placebo: Owner-occupied properties (not subject to licensing requirements)
- Callaway-Sant'Anna with never-treated comparison group

**Why it's novel:**
- Existing DiD evaluation (LSHTM/BMJ Open 2022) focused on health outcomes in Greater London only
- Housing market outcomes (rents, property prices, landlord exit) unstudied nationally
- Quality-rent trade-off: does licensing improve housing quality at the cost of higher rents?
- National sample with modern heterogeneity-robust estimators fills clear gap

**Feasibility check:**
- Variation: 46+ treated LAs by 2019, 100+ by 2024. Meets 20-unit threshold.
- Data access: Land Registry PPD (verified), Police API archives (verified), ONS rents (verified)
- Key risk: Treatment timing data requires contacting Petersen et al. or independent FOI collection
- Moderate literature: Health outcomes studied, housing market outcomes not studied
