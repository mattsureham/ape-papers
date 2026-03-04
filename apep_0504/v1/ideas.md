# Research Ideas

## Idea 1: Does Naming Work? Mandatory Food Hygiene Rating Display and Restaurant Market Discipline

**Policy:** Food Hygiene Rating (Wales) Act 2013 — made display of food hygiene rating stickers mandatory in Wales from November 28, 2013. Northern Ireland followed in October 2016. England remains voluntary (69% display rate vs. 92% in Wales). This is a textbook information disclosure intervention with cross-country variation.

**Outcome:** Universe of food establishment dynamics from Companies House (incorporation and dissolution dates for restaurant/café/pub SIC codes: 56.10, 56.21, 56.30, 47.11). Food hygiene rating distribution from FSA FHRS API (586K establishments across England/Wales/NI, no API key needed). Property values from Land Registry PPD (24M+ transactions) for neighborhood spillovers.

**Identification:** Two-cohort staggered DiD. Cohort 1: 22 Welsh unitary authorities (treated Nov 2013). Cohort 2: 11 NI district councils (treated Oct 2016). Control: ~300 English local authorities (never treated). Triple-diff: Treated country × post-treatment × food businesses (vs. non-food businesses in same LAs). Border design robustness: restrict to Welsh border LAs vs. adjacent English border LAs.

**Why it's novel:** Despite the FHRS being in place for 10+ years, no rigorous causal study exists using modern DiD methods. The FSA conducted only descriptive before/after studies. This is a clean test of whether information disclosure reshapes market structure — a fundamental question in information economics.

**Feasibility check:** Confirmed: FSA FHRS API returns 58,243 Welsh establishments and 494,148 English establishments (tested). Companies House bulk download confirmed working (468 MB CSV with incorporation/dissolution dates). 22 Welsh LAs exceed the ≥20 treated units threshold. Pre-treatment period from Companies House: 2008-Nov 2013 (5+ years). Post-treatment: Nov 2013-2025+ (12 years). Not in APEP list. Google Scholar shows limited economics literature — mostly food science and public health journals.

**Multi-margin design:**
1. Food business exit rate (market discipline — do low-quality firms die faster?)
2. Food business entry rate (does disclosure deter entry of low-quality operators?)
3. Average hygiene rating (quality upgrading — do surviving firms improve?)
4. Rating distribution (share rated 0-2 vs. 5 — cleaning up the bottom)
5. Neighborhood property values near food establishments (amenity capitalization)

**Built-in placebo:** Non-food businesses in the same Welsh LAs (shouldn't respond to FHRS mandate). Also: food manufacturers/wholesalers (B2B, no consumer-facing rating display).


## Idea 2: The Great Revaluation: Business Rates Shocks and Commercial Vitality in England

**Policy:** 2017 Non-Domestic Rating Revaluation — after a 7-year freeze (2010-2017, the longest gap in modern history), all commercial property rateable values were updated in April 2017. London and the South East saw average increases of 10-40%+ while Northern regions saw decreases, creating massive geographic redistribution of the commercial property tax burden.

**Outcome:** Companies House bulk data (5M firms with SIC codes, incorporation dates, dissolution dates, registered addresses). NOMIS BRES (Business Register and Employment Survey) for employment by LA. Land Registry PPD for residential property capitalization effects. VOA Rating Lists for 2010 and 2017 (confirmed downloadable) to construct treatment intensity.

**Identification:** Continuous-intensity DiD. Treatment: log change in average rateable value at the LA level between 2010 and 2017 lists. Pre-period: 2013-March 2017. Post-period: April 2017-2023+. Event study specification with leads and lags, accounting for transitional relief phase-in (5-year schedule). Callaway & Sant'Anna estimation treating each intensity quartile as a cohort.

**Why it's novel:** The 2017 revaluation is one of the largest property tax shocks in modern UK history, yet no rigorous DiD paper exists in the economics literature. IFS provided descriptive analysis of distributional impacts. The policy question — does commercial property taxation affect real economic activity or just capitalization? — remains unresolved empirically.

**Feasibility check:** Confirmed: VOA rating list downloads for both 2010 and 2017 available at voaratinglists.blob.core.windows.net. Companies House bulk CSV confirmed working. NOMIS confirmed working. All LAs in England experienced the revaluation, with continuous intensity variation. Not in APEP list. Pre-treatment parallel trends testable with 4 years of Companies House data.

**Built-in placebo:** Small businesses below the Small Business Rate Relief (SBRR) threshold. These firms pay zero business rates regardless of revaluation, so the revaluation should not affect them. This is a powerful falsification test.


## Idea 3: The Fiscal Externalities of Poverty: Council Tax Support Cuts and Neighborhood Spillovers

**Policy:** Council Tax Support Localization (April 2013). Central government abolished national Council Tax Benefit and delegated scheme design to 326 English local authorities, simultaneously cutting funding by 10%. LAs designed wildly different schemes: 264 introduced minimum payments (5-40% of liability), while 36 maintained full support. Pensioners were centrally protected (exempt from cuts).

**Outcome:** Land Registry PPD (property values at LSOA level, 2008-2025). NOMIS ASHE and APS (employment and earnings at LA level). ONS Recorded Crime statistics at Community Safety Partnership level (mapping to LAs). Council tax collection rates from DCLG/DLUHC statistics.

**Identification:** Continuous-intensity DiD using the minimum payment percentage (0-40%) as treatment intensity across 326 English LAs. Pre-period: 2010-March 2013. Post-period: April 2013-2025. Event study with pre-trends. Triple-diff: areas with high working-age CTS claimant share (high exposure) vs. low share (low exposure) × high-cut LAs vs. low-cut LAs × pre/post.

**Why it's novel:** The IFS (Adam, Joyce, Pope 2019) did a policy report on CTS localization focusing on claimant take-up and financial outcomes. No top-journal economics paper examines the SPILLOVER effects — crime, property values, local authority fiscal stress. The "fiscal externalities of poverty" framing is novel: did LA savings on CTS get offset by increased costs in policing, debt recovery, and neighborhood decline?

**Feasibility check:** Partially confirmed: counciltaxreduction.org has scheme data for all 326 LAs (2013-2018). Land Registry and NOMIS confirmed working. Challenge: constructing the CTS treatment variable requires structured download of scheme characteristics. 326 LAs >> 20 treated units threshold. Pre-treatment data available.

**Built-in placebo:** Pensioners (centrally protected from CTS cuts); high-value properties whose owners are not CTS claimants. Also: LAs that maintained full support (36 LAs) serve as never-treated controls.


## Idea 4: Planning Deregulation and the Office-to-Residential Conversion Shock

**Policy:** Permitted Development Rights (PDR) expansion (May 30, 2013). The government allowed office-to-residential conversion without planning permission across England. However, ~28 local authorities received Article 4 exemptions blocking PDR (mostly central London boroughs, plus Manchester, Bristol, and others). These exemptions expired and were renewed at different times.

**Outcome:** Land Registry PPD for residential property prices and new-build indicators. Companies House bulk data for office-sector firm dynamics (SIC codes for professional services, finance, tech). NOMIS for employment in affected sectors.

**Identification:** DiD comparing LAs where PDR applied (treated, ~300 LAs) vs. LAs with Article 4 exemptions (control, ~28 LAs). Triple-diff: PDR-exposed LAs × post-May 2013 × high-office-stock areas (vs. low-office areas within same LAs). Alternative: Bartik-style intensity design using pre-existing office stock share as exposure.

**Why it's novel:** MHCLG commissioned a descriptive housing quality study (Clifford et al. 2020), but no rigorous causal paper examines the COMMERCIAL side — does PDR hollow out office space and harm remaining businesses? The "office death spiral" framing (agglomeration loss from office conversion) is untested.

**Feasibility check:** Partially confirmed: Land Registry and Companies House confirmed working. Article 4 exemption list is documented in government publications and parliamentary briefings. Challenge: Article 4 LAs are systematically different (expensive, dense, London-heavy), creating selection concerns. Matching or border-discontinuity approaches needed.

**Built-in placebo:** Manufacturing and non-office commercial sectors in the same LAs (shouldn't be affected by office-to-residential PDR).
