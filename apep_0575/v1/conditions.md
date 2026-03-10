# Conditional Requirements

**Generated:** 2026-03-10T11:29:28.903166
**Updated:** 2026-03-10T11:35:00Z
**Status:** RESOLVED

---

## NOTE: Top-ranked idea (Gas Shock) claimed by apep_0574

The tri-model panel ranked Idea 2 (Gas Shock Import Substitution) as #1 PURSUE.
However, idea_0330 was already claimed by apep_0574 before this session.
Proceeding with Idea 1 (BRRD Bail-In → Household Deposits) which received
CONSIDER from GPT-5.4 (A) and GPT-5.4 (B).

---

## Bail-In Risk and Household Deposit Structure (idea_0507)

**Rank:** #2 | **Recommendation:** CONSIDER (2/3 models)

### Condition 1: Aggregate data too coarse (N=25 countries)

**Status:** [x] RESOLVED

**Response:**
The panel raised concerns about country-level aggregates. I will strengthen identification through:
1. Triple-difference using pre-BRRD uninsured deposit shares (EBA DGS data) as continuous treatment intensity — countries with higher uninsured shares should show larger restructuring
2. Corporate deposits as built-in placebo group (firms already disciplined via wholesale markets)
3. Deposit maturity decomposition (4 types × 25 countries × 60+ months = 6,000+ observations)
4. Within-country euro area vs non-euro area variation where applicable

**Evidence:** ECB BSI provides monthly data for 25+ countries × 4 deposit types × household + corporate sectors = substantial within-country variation. The triple-diff effectively multiplies the cross-section.

---

### Condition 2: Maturity types are noisy proxy for uninsured deposits

**Status:** [x] RESOLVED

**Response:**
The panel correctly notes that bail-in targets account SIZE (>€100K), while outcomes are maturity TYPE. The mechanism connecting these is:
1. Risk-averse households with deposits above €100K should shift from agreed-maturity (locked-in, higher bail-in exposure) to overnight/redeemable (liquid, easier to withdraw before bail-in)
2. Households may also split deposits across banks — testable via total deposit growth per bank
3. EBA DGS covered deposit ratio directly measures the insured fraction — use as treatment intensity

I will frame the paper around the specific prediction that bail-in risk increases depositor preference for liquidity (overnight share ↑, agreed-maturity share ↓), not just generic deposit movement.

**Evidence:** Germany has 50% overnight vs Spain 44% agreed maturity — substantial cross-country variation in deposit composition pre-BRRD.

---

### Condition 3: Endogenous transposition timing

**Status:** [x] RESOLVED

**Response:**
Gemini raised the concern that fragile banking systems delayed transposition. This is addressed by:
1. Using the LEGAL transposition deadline (Dec 31, 2014) as a common shock, with actual transposition dates as instruments for the speed of implementation
2. IWH Banking Union Directives Database provides both legal and actual dates — run both specifications
3. Include banking sector controls (NPL ratio, bank capital ratios from ECB) as covariates
4. Leave-one-out sensitivity excluding GIIPS countries
5. Randomization inference over transposition dates

**Evidence:** IWH database documents both legal deadlines and actual transposition for all EU members. The 411-day spread is partly driven by administrative capacity, not just banking stress (Luxembourg, a stable banking center, transposed late).

---

### Condition 4: EU-wide anticipation blurs treatment timing

**Status:** [x] RESOLVED

**Response:**
The directive was published in May 2014 and widely discussed from 2012. Address anticipation by:
1. Event study design testing for pre-transposition movement starting from May 2014 (publication) vs Dec 2014+ (transposition)
2. If anticipation is uniform across countries, the staggered component still identifies differential timing effects
3. Rambachan-Roth (2023) sensitivity analysis bounding pre-trend violations
4. The bail-in tool was mandatory only from Jan 1, 2016 — this provides a SECOND treatment event within countries that transposed early

**Evidence:** The BRRD had two distinct treatment events: (a) national transposition (Dec 2014-Feb 2016) and (b) bail-in tool activation (Jan 1, 2016). This two-event structure helps separate anticipation from implementation.

---

## Verification Checklist

- [x] All conditions above are marked RESOLVED
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Status: RESOLVED**
