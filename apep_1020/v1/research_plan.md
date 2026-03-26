# Research Plan: Bunching Migration at the Tax Threshold

## Research Question

When stamp duty thresholds move, does bunching migrate? The UK's April 2025 SDLT reversion — simultaneously shifting 4+ kinks in the marginal-rate schedule — provides a rare opportunity to test whether price bunching is a stable structural feature or an artifact of specific threshold placement.

## Identification Strategy

**Multi-kink difference-in-bunching.** The April 1, 2025 reversion shifted:
- Standard nil-rate: £250K → £125K (new 2pp kink created)
- Standard 2%→5%: stays at £250K (kink shrinks from 5pp to 3pp)
- FTB nil-rate: £425K → £300K (kink migrates)
- FTB cap: £625K → £500K (kink migrates)
- Unchanged: £925K (5%→10%) and £1.5M (10%→12%) — placebos

**Key predictions:**
1. Bunching appears at £125K post-reversion (new kink)
2. Bunching at £250K shrinks (kink attenuates from 5pp to 3pp)
3. Bunching disappears at £425K (FTB kink removed)
4. Bunching appears at £300K (new FTB kink)
5. No change at £925K or £1.5M (placebo)

**Geographic placebo:** Scotland uses LBTT (different thresholds, no April 2025 change). Wales uses LTT (also different). England-only treatment.

## Expected Effects and Mechanisms

If bunching migrates as predicted by standard theory (Kleven & Waseem 2013), this validates structural interpretation of bunching estimates globally. The elasticity of taxable income implied by bunching magnitude should be similar across old and new thresholds if the structural model is correct.

If bunching does NOT migrate (or migrates slowly), this challenges the standard model and suggests bunching may reflect behavioral anchoring, salience, or market friction rather than optimal tax response.

## Primary Specification

Bunching estimator following Chetty et al. (2011) and Kleven (2016):
- Fit counterfactual distribution using polynomial outside exclusion region
- Excess mass = (observed - counterfactual) / counterfactual at each kink
- Difference-in-bunching: Δb = b_post - b_pre at each threshold
- Cross-kink comparison: test that Δb is proportional to Δτ (change in marginal rate)

## Data Source and Fetch Strategy

**Primary:** HM Land Registry Price Paid Data
- Annual bulk CSVs: pp-2023.csv, pp-2024.csv, pp-2025.csv
- URL pattern: `http://prod.publicdata.landregistry.gov.uk.s3-website-eu-west-1.amazonaws.com/pp-{year}.csv`
- Columns: price, date, postcode, property type, new/old, freehold/leasehold

**Pre-period:** Jan 2023 – Mar 2025 (under £250K nil-rate regime)
**Post-period:** May 2025 – Dec 2025 (under £125K nil-rate regime)
**Anticipation window:** Oct 2024 – Mar 2025 (announced → effective)

**Geographic linkage:** postcodes.io API to map postcodes to country (England vs Scotland/Wales)
