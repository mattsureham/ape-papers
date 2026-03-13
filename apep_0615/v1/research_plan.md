# Research Plan: Pricing Under the Spotlight

## Research Question

Do pharmaceutical price transparency laws induce strategic threshold avoidance by drug manufacturers? Specifically, do manufacturers bunch their annual wholesale acquisition cost (WAC) increases just below state-specific reporting thresholds?

## Policy Setting

21 U.S. states enacted drug price transparency laws between 2016-2024, each requiring manufacturers to report and justify price increases exceeding a state-specific threshold. Key thresholds:

- **10%:** Oregon (2018), New Mexico (2020), New York (2020)
- **15-16%:** California (2017, 16% over 2 years), Colorado (2021), Texas (2021)
- **20%+:** Connecticut (2019, 20%), Maine (2019)
- **Launch price:** Vermont (2016), Nevada (2017)

Because WAC is set nationally, the binding constraint is the LOWEST threshold across all active states. The binding threshold shifted from 16% (2017, California) to 10% (2018+, Oregon) — creating a testable prediction about where bunching should appear.

## Identification Strategy

**Bunching estimation** (Kleven & Waseem 2013; Chetty et al. 2011; Saez 2010):

1. Compute annual WAC changes for each brand drug NDC from NADAC weekly data
2. Estimate counterfactual smooth density using polynomial fit excluding the manipulation window
3. Measure excess mass below thresholds and missing mass above
4. Test for temporal shift in bunching location as binding threshold changed (16% → 10%)

**Cross-threshold identification:** Bunching should appear at each threshold only after the corresponding state adopts. The shift from 16% to 10% provides a falsification: post-2018, bunching at 16% should attenuate as 10% becomes binding.

**Staggered DiD extension:** Define drug-year "treatment intensity" based on number of active transparency states and test whether bunching increases monotonically with law count.

## Expected Effects and Mechanisms

- **H1 (Strategic avoidance):** Excess mass just below reporting thresholds, with corresponding missing mass above
- **H2 (Threshold shift):** Bunching location shifts from 16% to 10% when Oregon adopts in 2018
- **H3 (Drug heterogeneity):** Bunching concentrated among high-revenue brand drugs (higher reporting costs)
- **Alternative (focal point):** Laws may INCREASE prices for drugs that would have had smaller increases by creating a salient focal point just below the threshold

## Primary Specification

For each NDC-year, compute annual WAC change. In narrow bins (0.5pp width) around each threshold:
- Estimate counterfactual density with polynomial (order 7-9) fit
- Report excess mass b = (B - B_counterfactual) / B_counterfactual
- Standard errors via bootstrap (200 replications)

## Data Source and Fetch Strategy

- **NADAC:** CMS National Average Drug Acquisition Cost (data.medicaid.gov), weekly prices 2013-2025, ~1.3M rows/year. Filter to brand drugs (classification = "B"). API endpoint via SODA.
- **Policy data:** Compile state adoption dates and thresholds from NASHP Drug Pricing Laws database and primary legislation.
- **SDUD:** State Drug Utilization Data for market share weighting (optional extension)

## Tables Plan (V1: max 5, zero figures)

1. **Summary Statistics:** Brand drug pricing landscape (NDCs, prices, annual changes)
2. **Bunching Evidence:** Excess mass at 10% and 16% thresholds, pre vs post adoption
3. **Threshold Shift:** Bunching at 16% (2017) shifts to 10% (2018+)
4. **Heterogeneity:** By drug revenue quintile, therapeutic class, generic competition
5. **Robustness:** Placebo thresholds (5%, 25%, 30%), alternative bin widths, donut estimates

Plus SDE appendix table (tabF1_sde.tex).

## Key Risks

1. NADAC reflects pharmacy acquisition cost, not WAC directly — but tracks WAC closely for brand drugs
2. National pricing means all drugs face the same threshold, limiting cross-drug variation
3. Pre-existing round-number bunching at 10% could confound — addressed by pre/post comparison
