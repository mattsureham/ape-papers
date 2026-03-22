# Research Plan: The Emergency Room Tax — GP Practice Closures and A&E Utilization in England

## Research Question

Does the closure of GP practices in England's NHS cause increased emergency department (A&E) utilization at nearby hospital trusts? If so, what is the magnitude of this primary-to-emergency care substitution, and does it disproportionately affect deprived communities?

## Motivation

Between 2013 and 2024, over 1,400 GP practices closed or merged across England, driven by GP retirements, funding pressures, and NHS consolidation policies. These closures are often framed as efficiency-improving: merging small practices into larger units should exploit economies of scale. But if displaced patients — unable to secure timely GP appointments — turn to emergency departments for care that could have been managed in primary care, the fiscal logic reverses. A&E visits cost the NHS 5-10× more than GP consultations. The "efficiency" saving from consolidation may create a hidden emergency care tax.

Despite the policy stakes, no causal study of GP closures on A&E utilization exists. The only published study (Munro et al., BJGP 2023) is descriptive and cross-sectional. This paper fills that gap using 1,400+ staggered closure events and modern difference-in-differences methods.

## Identification Strategy

**Design:** Staggered difference-in-differences with Callaway-Sant'Anna (2021) estimator.

**Unit of analysis:** NHS Trust × month (approximately 130 major A&E trusts × 108 months = ~14,000 trust-months).

**Treatment definition:** A trust becomes "treated" in the first month when a GP practice within 10km of its A&E department closes. Subsequent closures increase treatment intensity but do not change the initial treatment date (for the binary DiD).

**Why this works:** GP closure timing is staggered across England and driven primarily by GP partner retirements, lease expirations, and CQC (Care Quality Commission) interventions — factors that are plausibly exogenous to short-run A&E demand trends at the trust level. The key identifying assumption is parallel trends: absent GP closures, treated and not-yet-treated trusts would have experienced similar A&E attendance trajectories.

**Validation:**
- Event-study plots showing flat pre-trends (12 months pre-closure)
- Placebo test: GP mergers (practice code changes without capacity loss) should show no effect
- Robustness to different distance thresholds (5km, 15km, 20km)
- Bacon decomposition showing clean treated vs. not-yet-treated variation

## Expected Effects and Mechanisms

**Primary effect:** Positive — GP closures should increase Type 1 A&E attendances as displaced patients substitute emergency for primary care.

**Magnitude prior:** A practice with ~5,000 patients closing in an area with ~200,000 trust catchment population should increase A&E demand by ~2.5% if even a small fraction (5-10%) of displaced patients shift to A&E. This maps to a moderate positive SDE.

**Mechanisms:**
1. Direct substitution: Patients without a GP visit A&E for conditions manageable in primary care
2. Capacity strain: Surviving practices absorb displaced patients → longer wait times → more A&E use
3. Continuity loss: Patients with chronic conditions lose continuity of care → worse management → more acute episodes

## Primary Specification

```
log(AE_Type1_{it}) = α_i + δ_t + β × PostClosure_{it} + ε_{it}
```

Where:
- i = NHS Trust, t = month
- α_i = trust fixed effects
- δ_t = month fixed effects
- PostClosure_{it} = 1 if any GP within 10km closed before month t
- Cluster SEs at trust level

Using Callaway-Sant'Anna: group = first closure month, time = calendar month.

## Secondary Outcomes

1. **Emergency admissions via A&E** (more severe consequences of delayed primary care)
2. **4-hour wait target performance** (% seen within 4 hours — capacity pressure indicator)
3. **Type 3 attendances** (minor injury units — potential substitution away from A&E)

## Heterogeneity

- IMD deprivation of trust catchment area (expect larger effects in deprived areas)
- Distance to nearest surviving GP practice
- Urban vs. rural trusts
- Number of closures (dose-response)

## Data Sources

1. **NHS ODS (Organisation Data Service):** GP practice file (epraccur.csv) listing all practices with status (Active/Closed), open/close dates, postcodes. Download from NHS Digital.
2. **NHS England A&E Statistics:** Monthly trust-level A&E attendances by type (1, 2, 3), emergency admissions, 4-hour wait performance. Published as CSV/XLS on NHS England statistics page.
3. **postcodes.io API:** Free geocoding of postcodes to lat/lon for distance calculations.
4. **NHS Trust locations:** Trust main site postcodes from ODS for A&E department geocoding.

## Exposure Alignment

**Who is actually affected by treatment?** When a GP practice closes, the direct exposure falls on the closed practice's registered patients (typically 3,000-15,000). These patients must re-register elsewhere or use alternative care pathways. The A&E trust-level analysis captures this through the geographic mapping: trusts within 10km of a closure are assumed to receive displaced patients who cannot secure timely GP appointments. The exposure is indirect --- trust-level A&E attendances aggregate over all patients, not just the displaced cohort. This attenuation is a known limitation: the treatment affects a fraction of the trust's catchment population, so the trust-level effect will be smaller than the patient-level effect. The 10km radius is chosen to balance coverage (most urban patients travel <10km to A&E) against noise from distant closures.

## Feasibility Assessment

- **Data availability:** All datasets confirmed publicly available (Phase A sources from UK country skill)
- **Sample size:** ~130 trusts × 108 months ≈ 14,000 observations; ~1,400 closure events
- **Pre-periods:** 12+ months before first closure for most trusts
- **Statistical power:** With 130+ trusts and large attendance counts, power is strong for moderate effects
- **Key risk:** Geographic mapping quality — need accurate trust-to-closure assignment via postcodes
