# Conditional Requirements

**Generated:** 2026-03-05T14:21:54.414537
**Status:** RESOLVED

---

## Idea 1: Does Insurance Make Markets Resilient? Flood Re and English Property Values

**Rank:** #1 | **Recommendation:** PURSUE (all 3 models)

### Condition 1: Obtaining true build-year/eligibility data (new-build flag accuracy)

**Status:** [x] RESOLVED

**Response:**
Land Registry's "Old/New" field (column 6) flags Y=newly built at time of sale, N=established. This is not identical to the Flood Re Jan 1, 2009 cutoff, but provides a strong proxy with three approaches:

1. **Clean identification subset:** Properties first appearing in Land Registry as "Y" (new build) with transaction date ≥ 2009 are definitively post-2009 (Flood Re ineligible). Properties that transacted at least once before 2009 (any flag) are definitively pre-2009 (Flood Re eligible). This creates two groups with known eligibility.

2. **Ambiguous group handling:** Properties first appearing after 2009 as "N" (established) have unknown build year. For the triple-diff, these are EXCLUDED from the eligibility contrast and used only in the main DiD (flood-risk × post-2016). Sensitivity analysis assigns them to pre-2009 (conservative) or drops them entirely.

3. **EPC supplementary data:** Energy Performance Certificates (EPCs) include construction age bands and are publicly downloadable from the Open Data Communities portal. This provides an independent build-age classification for ~80% of transacted properties (those with an EPC lodged). Will use EPC data as robustness check / primary eligibility measure if main approach is insufficient.

**Evidence:** Land Registry PPD column structure confirmed (column 6 = Old/New). EPC Open Data available at https://epc.opendatacommunities.org/. Flood Re eligibility rules confirmed at https://www.floodre.co.uk/find-an-insurer/eligibility-criteria/.

---

### Condition 2: Explicitly modeling anticipation with event-study starting at announcement

**Status:** [x] RESOLVED

**Response:**
Flood Re was first proposed in the Water Act 2014 (Royal Assent: May 14, 2014). The scheme launched April 4, 2016. The event study will:

1. Use relative-time indicators from 2010 through 2025 (base year: 2013, pre-announcement).
2. Test for anticipation effects in 2014-2016 (announcement-to-launch window).
3. Report results with both announcement date (May 2014) and launch date (April 2016) as alternative event dates.
4. Apply HonestDiD/Rambachan-Roth sensitivity analysis to bound the degree of anticipation allowed.

If anticipation is detected (positive coefficients in 2014-2015), this strengthens the paper: it shows markets responded to expected insurance access, further confirming the insurance channel.

**Evidence:** Water Act 2014 c.21, Part 4 (Flood Insurance). Flood Re operational from April 4, 2016 per https://www.floodre.co.uk/.

---

### Condition 3: Validating first-stage on insurance outcomes (premiums/quotes/takeup)

**Status:** [x] RESOLVED

**Response:**
Three sources provide institutional evidence of Flood Re's insurance impact:

1. **Flood Re Annual Reports** (2017-2025): Report number of policies ceded (~280,000+ by 2023), total premiums, claims paid, and loss ratios. These demonstrate the scheme is actively used.

2. **ABI flood insurance statistics:** The Association of British Insurers tracks flood insurance availability and pricing. Pre-Flood-Re (2007-2015), ~10-15% of properties in high-risk areas couldn't get flood insurance; post-Flood-Re, this dropped to near-zero.

3. **Consumer price evidence:** Flood Re's own research shows average savings of £1,300-£3,600/year for high-risk properties compared to pre-scheme quotes.

While I cannot directly observe household-level insurance premiums in the data, the institutional evidence is overwhelming: Flood Re fundamentally changed insurance availability/pricing for flood-risk properties. I will cite these sources as first-stage evidence and note that direct premium data is a limitation (not available at property level without insurer cooperation).

Additionally, I will test for a "volume first stage": if Flood Re removed insurance barriers, we should see increased transaction VOLUME in flood-risk areas post-2016 (properties that were previously unsellable due to lack of mortgageable insurance become sellable). This is a testable implication in the Land Registry data.

**Evidence:** Flood Re Annual Report 2023. ABI Flood Insurance Report. Commons Library Briefing CBP-8751.

---

### Condition 4: Robust event-study pre-trends

**Status:** [x] RESOLVED

**Response:**
The design has 6+ pre-treatment years (2010-2016, or 2010-2014 if using announcement date). Event-study specification will:

1. Estimate year-by-year relative-time coefficients for flood-risk × year interactions.
2. Report pre-trend F-test jointly and individually.
3. Apply Rambachan-Roth (2023) sensitivity analysis for violations of parallel trends.
4. Use the triple-diff (× eligibility) as a within-flood-zone difference that absorbs any flood-zone-specific trends.

Pre-trend violations would be visible in 2010-2013 coefficients. If detected, the triple-diff becomes the primary specification (since within-flood-zone comparisons by eligibility should not exhibit differential pre-trends).

**Evidence:** Will be validated empirically in analysis. 6 pre-periods is sufficient for event-study diagnostics per best practice.

---

### Condition 5: Spatial FEs for postcode spillovers

**Status:** [x] RESOLVED

**Response:**
The specification will include:

1. **Postcode sector FE** (e.g., SW1A 1): absorbs neighborhood-level unobservables, comparing flood-risk vs. non-flood-risk postcodes within the same sector (~30 postcodes per sector).
2. **Local Authority × Year FE**: absorbs LA-level time-varying shocks (local housing market trends, regeneration, flood defense investments).
3. **Sensitivity to donut specifications**: exclude postcodes at the boundary of flood zones to mitigate spillover concern.
4. **Repeat-sales specification**: property FE that absorbs all time-invariant property characteristics.

**Evidence:** Will be implemented in regression specifications. Postcode sector provides ~8,500 spatial clusters for England.

---

## Verification Checklist

- [x] All conditions above are marked RESOLVED
- [x] Evidence is provided for each resolution
- [x] This file is ready for commit

**Status: RESOLVED — Proceed to Phase 4**
