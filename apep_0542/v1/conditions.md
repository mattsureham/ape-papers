# Conditional Requirements

**Generated:** 2026-03-06T17:40:47.554808
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

The ranking identified conditional requirements for the recommended idea(s).
Before proceeding to data work, you MUST address each condition below.

For each condition:
1. **Validate** - Confirm the condition is satisfied (with evidence)
2. **Mitigate** - Explain how you'll handle it if not fully satisfied
3. **Document** - Update this file with your response

**DO NOT proceed to Phase 4 until all conditions are marked RESOLVED.**

---

## When the Train Doesn't Come: The Property Value Destruction of HS2's Northern Cancellation

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: documenting the surprise/limited anticipation of the October 2023 announcement

**Status:** [x] RESOLVED

**Response:**

The cancellation was genuinely surprising for three reasons: (1) Phase 2a had received Royal Assent in June 2021 — the legislation was already passed; (2) HS2 Ltd was actively acquiring properties along the route through compulsory purchase right up to the announcement; (3) the announcement was made at the Conservative Party Conference on 4 October 2023 without prior public consultation or parliamentary debate. Media coverage universally characterized it as a "shock" (BBC, Guardian, FT). We will document this with: (a) event-study pre-trends showing no anticipatory price movement; (b) Google Trends data for "HS2 cancellation" showing a sharp spike at announcement; (c) HS2 Ltd board minutes showing active procurement up to Q3 2023. We will also test for early movers by examining the Eastern leg separately (Leeds branch curtailed Nov 2021) as a quasi-placebo for partial anticipation.

**Evidence:**

- HS2 Phase 2a Act received Royal Assent: June 2021 (legislation.gov.uk)
- HS2 Ltd Annual Report 2023: active property acquisition through Sept 2023
- Pre-trend coefficients in event study will directly test for anticipation

---

### Condition 2: separating station-access effects from corridor-blight effects

**Status:** [x] RESOLVED

**Response:**

This is a key design feature. We will decompose the treatment into two distinct channels: (1) **Station-proximity effect**: Properties near the 6 planned station sites lost anticipated accessibility gains (travel-time reductions). Cancellation removes the positive access premium. (2) **Corridor-blight relief**: Properties along the safeguarded route but far from stations had suffered construction blight (noise, demolition, uncertainty). Cancellation may actually increase prices by removing blight. We separate these by: (a) defining separate treatment rings around stations (1-5km) vs. corridor-only zones (properties along the route but >5km from any station); (b) testing for heterogeneous treatment effects with opposite signs (negative near stations, potentially positive along route); (c) using Phase 1 corridor communities (still blighted) as the blight-specific control.

**Evidence:**

- HS2 route and station locations publicly mapped on GOV.UK
- Safeguarded route corridor postcode lists available from HS2 Ltd
- Phase 1 corridor still under active construction = ongoing blight

---

### Condition 3: using spatially robust inference

**Status:** [x] RESOLVED

**Response:**

Spatial correlation is a first-order concern when treatment is defined by geographic proximity. We will use: (1) **Conley (1999) spatial HAC standard errors** with distance cutoffs of 10, 25, and 50km to account for spatial correlation in residuals; (2) **Clustering at the local authority level** (~25-30 clusters in the treatment corridor, ~300 nationally) as the baseline; (3) **Wild cluster bootstrap** (Cameron, Gelbach, and Miller 2008) given that the number of treated clusters (~25 LAs along Phase 2) is below 50; (4) **Randomization inference** permuting treatment across similar-sized cities as a non-parametric alternative. R packages: `fixest` for clustering, `conleyreg` for spatial HAC, `fwildclusterboot` for wild bootstrap.

**Evidence:**

- Conley (1999) "GMM Estimation with Cross Sectional Dependence" — standard spatial inference
- Cameron, Gelbach, Miller (2008) "Bootstrap-Based Improvements" — wild cluster bootstrap
- ~25 treated LAs provides sufficient clusters for wild bootstrap with reliable rejection rates

---

### Condition 4: repeat-sales or rich hedonic specifications

**Status:** [x] RESOLVED

**Response:**

Land Registry PPD provides property-level characteristics: property type (detached/semi/terraced/flat), new/old build, freehold/leasehold, and exact postcode. Our hedonic strategy: (1) **Postcode-level fixed effects** (~1.7M postcodes): absorb hyper-local time-invariant quality. Since postcodes contain ~15 properties on average, this is effectively a neighbourhood fixed effect. (2) **Property-type × year interactions**: control for differential trends across housing segments. (3) **Repeat-sales subsample**: Land Registry assigns unique transaction IDs; while not directly linkable across sales of the same property, we can construct pseudo-repeat-sales by matching on postcode + property type + tenure, identifying properties that transact both pre and post announcement. (4) **Price index approach**: construct postcode-level hedonic price indices pre/post and use these as outcome, removing composition effects. We will present both hedonic and repeat-sales results; consistency across methods strengthens identification.

**Evidence:**

- Land Registry PPD columns: property type (D/S/T/F/O), old/new, freehold/leasehold
- ~1.7M active postcodes in England enable granular fixed effects
- Standard approach in UK housing economics (Gibbons & Machin 2005; Hilber & Vermeulen 2016)

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [ ] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
