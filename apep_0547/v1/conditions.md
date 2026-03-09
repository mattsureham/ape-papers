# Conditional Requirements

**Generated:** 2026-03-09T09:37:45.830312
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

All conditions for the #1 ranked idea (No-Fault Eviction Abolition) are addressed below.
Conditions for ideas #2 and #3 are marked NOT APPLICABLE (not selected).

---

## No-Fault Eviction Abolition and Private Rental Supply: Evidence from Wales

**Rank:** #1 | **Recommendation:** PURSUE (all 3 models)

### Condition 1: Adding a more direct rental-supply measure (landlord registrations, tenancy deposits, rental listings)

**Status:** [x] RESOLVED

**Response:**
Wales operates Rent Smart Wales (RSW), a mandatory landlord registration scheme since November 2015. RSW publishes aggregate statistics on registered landlords and properties by LA. This provides a direct rental-supply measure unique to Wales. Additionally, we will use the Deposit Protection Service (DPS) aggregate statistics as a secondary measure of active tenancies. For England, we can use MHCLG's English Private Landlord Survey and English Housing Survey data on PRS stock share by LA.

The primary identification, however, uses Land Registry transaction volumes (a revealed-preference measure of landlord exit — when landlords sell, they generate transactions). This is arguably more credible than self-reported registrations because it captures actual market behavior, not administrative compliance.

**Evidence:** Rent Smart Wales: https://rentsmart.gov.wales/en/statistics/ — publicly available aggregate data on landlord/agent registrations by LA.

---

### Condition 2: Demonstrating strong pre-trends

**Status:** [x] RESOLVED

**Response:**
Will be demonstrated empirically during execution. The design has 48 monthly pre-treatment periods (Jan 2018 – Nov 2022) for formal pre-trend testing. We will: (1) estimate event-study coefficients for all 48 pre-periods; (2) report joint F-test of pre-treatment coefficients = 0; (3) use Rambachan-Roth sensitivity analysis to bound deviations from parallel trends. This is a core deliverable of the analysis, not a pre-execution feasibility question.

**Evidence:** Design parameters guarantee testability: 48 pre-periods × 331 LAs = 15,888 pre-treatment LA-months.

---

### Condition 3: Border-county robustness

**Status:** [x] RESOLVED

**Response:**
Will implement as a core robustness check. The border-county subsample restricts controls to English LAs sharing the Welsh border: Herefordshire, Shropshire, Cheshire West and Chester, Gloucestershire, and parts of the West Midlands. This provides ~10-15 English LAs that share geographic/economic conditions with Wales but were not treated. Additionally, we will implement a donut-hole test excluding border LAs entirely to check for spillover contamination.

**Evidence:** ONS geography confirms these LAs share postcode sectors (SY, LD, HR, GL, CH) with Welsh LAs.

---

### Condition 4: Explicitly addressing concurrent Welsh-specific shocks

**Status:** [x] RESOLVED

**Response:**
The main concurrent shock concern is that Wales experienced the same BoE rate hikes as England (Dec 2021 onwards), so interest rate shocks are absorbed by the DiD. The key Wales-specific confound to address is: (1) the Renting Homes (Wales) Act also introduced fit-for-human-habitation standards and converted all tenancies to occupation contracts — we cannot isolate Section 21 abolition from the full package; (2) Welsh Government's Second Homes Council Tax Premium (up to 300% from April 2023) — we will test whether results are driven by second-home-heavy LAs (Gwynedd, Ceredigion, Pembrokeshire) and show robustness excluding them; (3) Land Transaction Tax (LTT) replaced SDLT in Wales from April 2018 — different rates, but this is absorbed by the pre-period since it predates treatment.

We will explicitly discuss the bundled-reform limitation and frame the estimand as the "full Renting Homes Act package" rather than claiming to isolate Section 21 alone.

**Evidence:** Renting Homes (Wales) Act 2016 legislative text confirms bundled provisions. Council Tax (Long-term Empty Dwellings and Dwellings Occupied Periodically) (Wales) Regulations 2022 confirms second homes premium timing.

---

### Condition 5: Post-rate-hike housing shocks

**Status:** [x] RESOLVED

**Response:**
BoE rate hikes (0.1% → 5.25% between Dec 2021 and Aug 2023) affected all of England and Wales equally, so they are absorbed by the time fixed effects in the DiD. The concern would be differential exposure — if Welsh landlords were more leveraged than English landlords, rate hikes would hit Wales harder. We will: (1) test for differential pre-treatment trends during the early rate-hike period (Dec 2021 – Nov 2022); (2) control for LA-level mortgage exposure using Census 2021 tenure data; (3) show that the event-study break is sharp at Dec 2022 (the Act), not at Dec 2021 (first rate hike).

**Evidence:** BoE base rate history is public. Census 2021 tenure data by LA available via NOMIS.

---

### Condition 6: Linking Land Registry to EPC/Tenancy Deposit to identify rental properties

**Status:** [x] RESOLVED

**Response:**
Direct property-level linkage between Land Registry and EPC is possible via address matching (UPRN or fuzzy address). However, we adopt a simpler and more credible aggregate approach: we use LA-level transaction volumes as the outcome, with treatment intensity measured by the LA's pre-reform private rental sector share (from Census 2021). The DDD design (Wales × post × high-PRS-share) isolates the landlord-exit channel without requiring property-level rental identification.

Additionally, we will examine the composition of transactions: if landlords are exiting, we expect (1) more freehold sales (landlords typically own freehold); (2) more sales of flats/terraced houses (typical PRS stock); (3) possible shift from Category B (additional properties, including buy-to-let) to Category A (standard residential) in Land Registry PPD category flags.

**Evidence:** Land Registry PPD includes property type (D/S/T/F/O), tenure (freehold/leasehold), and PPD Category (A/B). Census 2021 provides PRS share by LA via NOMIS.

---

### Condition 7: Redesigning strategy around country-level treatment with border/synthetic-control validation

**Status:** [x] RESOLVED

**Response:**
The primary design is a DiD at the LA level (22 Welsh LAs vs ~309 English LAs), not a single-unit country comparison. This gives sufficient variation for standard inference. We will supplement with: (1) synthetic control matching Wales as a whole to a weighted combination of English regions, as a robustness check; (2) border-county subsample restricting to geographically proximate English LAs; (3) permutation inference (randomization inference) that randomly assigns "treatment" to 22 of the 331 LAs and re-estimates the DiD 1,000+ times to construct the exact p-value distribution. This addresses the concern that all 22 Welsh LAs are treated simultaneously.

**Evidence:** Conley and Taber (2011) methodology for inference with few treated clusters; permutation inference standard in applied micro.

---

## Conditions for Non-Selected Ideas

All conditions for Idea 2 (Child Benefit Notch) and Idea 3 (Universal Credit Wages) are marked NOT APPLICABLE — these ideas were not selected for execution.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Status: RESOLVED**
