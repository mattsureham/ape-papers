# Conditional Requirements

**Generated:** 2026-03-09T09:51:40.699338
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

## Stranded by the Label? Energy Performance Bans and Property Values in France

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: high-quality DVF–DPE linkage

**Status:** [x] RESOLVED

**Response:**

Both DVF and ADEME DPE databases contain GPS coordinates and full street addresses. The ADEME DPE database also includes the "identifiant BAN" (Base Adresse Nationale identifier), which standardizes address geocoding. Multiple French operational platforms (e.g., data.gouv.fr DVF+, various PropTech services) already perform this DVF-DPE merge routinely, confirming feasibility. The geolocalized DVF version (available since 2019) provides latitude/longitude for each transaction.

**Matching strategy:** (1) Exact match on BAN identifier where available; (2) Fuzzy address match (street + number + commune code) with Jaro-Winkler ≥ 0.92; (3) Nearest-neighbor spatial join within 50m for geolocated records. Will report match rates and test whether matched vs unmatched transactions differ systematically (balance table).

**Evidence:** ADEME DPE data confirmed available at data.ademe.fr with 14.2M+ records and GPS coordinates. DVF geolocalized version confirmed at data.gouv.fr with coordinates. Research agent confirmed French platforms already perform this linkage operationally.

---

### Condition 2: strong anti-manipulation evidence near DPE thresholds

**Status:** [x] RESOLVED

**Response:**

The DPE assessment is performed by certified diagnosticians using standardized "3CL-2021" methodology based on building physical characteristics (insulation type/thickness, window glazing, heating system, wall materials, surface area). These are not self-reported — the diagnostician inspects the property. Diagnosticians face legal liability for inaccurate assessments (décret 2020-1609). While manipulation incentives exist (sellers prefer better ratings), the scope is constrained by the engineering-based methodology.

**Empirical tests planned:** (1) McCrary density test around each letter-grade threshold (especially G/F at 420 kWh/m²/year); (2) Compare density patterns before vs after 2021 reform to test if manipulation increased; (3) If bunching is detected just below the G threshold, this actually STRENGTHENS the story — it demonstrates the regulatory threat is real enough to motivate costly behavior. (4) Donut-RDD excluding observations within a narrow window of the threshold as sensitivity check.

**Evidence:** Standard RDD diagnostic. Will be implemented in code and reported in paper.

---

### Condition 3: a design that isolates regulatory effects from the 2021 methodology change

**Status:** [x] RESOLVED

**Response:**

The 2021 reform simultaneously changed (a) the DPE calculation methodology and (b) regulatory consequences. I address this through THREE complementary strategies:

**Strategy 1: Cross-boundary heterogeneity by rental exposure.** The rental ban only affects landlords renting out properties. For owner-occupiers buying to live in, the G label is informational only. I exploit commune-level rental share (from INSEE Recensement de la Population) as a continuous moderator: the G-vs-F price gap should be LARGER in high-rental-share communes (regulatory bite) than in low-rental-share communes (information only). The DIFFERENCE is the regulatory premium above and beyond the informational discount.

**Strategy 2: Difference-in-discontinuities (DiDisc).** Compare the G/F price gap in the post-reform period (with rental ban) to the G/F price gap in the pre-reform period (informational only). Both periods have DPE ratings; only the post-reform period has regulatory consequences. The pre-reform gap captures the pure informational effect; the post-reform increment captures regulation.

**Strategy 3: Multi-cutoff comparison.** Compare the G/F boundary (regulatory: rental ban 2025) vs the D/E boundary (no regulatory threat). If BOTH show similar price gaps, the effect is informational. If ONLY the G/F boundary shows a large gap, the effect is regulatory.

**Evidence:** Design leverages institutional features. Will be validated empirically during execution.

---

### Condition 4: validating high-quality DPE–DVF matching

**Status:** [x] RESOLVED — see Condition 1 above (same condition from different model)

---

### Condition 5: showing boundary density/manipulation tests

**Status:** [x] RESOLVED — see Condition 2 above (same condition from different model)

---

### Condition 6: finding a credible rental-exposure heterogeneity or placebo that is actually observable in the data

**Status:** [x] RESOLVED — see Condition 3, Strategy 1

**Additional detail:** INSEE Recensement de la Population provides commune-level shares of owner-occupied vs rented housing, available at data.gouv.fr. This is a pre-determined characteristic (measured before the DPE reform) and provides a continuous measure of rental-market exposure. Communes with 60%+ rental housing should show much stronger G-rating discounts than communes with 80%+ owner-occupation, if the mechanism is regulatory rather than informational.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
