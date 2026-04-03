# Research Plan: The 1,000-Kilogram Cliff — Hazardous Waste Generator Thresholds and Strategic Pollution Reduction

## Research Question

Do firms strategically reduce reported hazardous waste to avoid costly regulatory thresholds? RCRA classifies generators into three tiers at 100 kg/month and 1,000 kg/month, where crossing 1,000 kg/month halves permitted storage time, triggers mandatory training, contingency plans, and biennial reporting. Using the universe of EPA-regulated hazardous waste generators, I estimate the compliance elasticity at the SQG/LQG threshold via bunching estimation.

## Portable Mechanism: The Characterization Margin

Standard regulatory compliance assumes firms reduce pollution (real abatement) or evade detection. But at hazardous waste thresholds, firms have a third margin: strategic characterization. "Hazardous waste" is defined by a complex regulatory taxonomy (40 CFR 261) involving listed wastes, characteristic wastes, and mixture rules. A firm at 1,050 kg/month can legitimately reclassify 100 kg by adjusting solvents, running TCLP tests, or changing process inputs. The compliance elasticity thus measures real abatement plus strategic characterization — analogous to the taxable income elasticity decomposing into real labor supply and avoidance.

## Identification Strategy

**Design:** Bunching estimation (Kleven & Waseem 2013, Chetty et al. 2011) at the 1,000 kg/month SQG/LQG threshold.

**Running variable:** Monthly hazardous waste generation (kg), reported biennially to EPA via RCRAInfo.

**Excess mass:** Count distribution of generators near the threshold. Excess mass below 1,000 kg/month (and missing mass above) identifies the behavioral response.

**Counterfactual:** Polynomial fit to the density excluding the manipulation region, following standard bunching methods.

**Complementary design:** The 2016 Generator Improvements Rule (effective May 2017) changed SQG requirements (new emergency procedures, re-notification). This rule change provides a before/after comparison of bunching intensity as a robustness check.

## Expected Effects

- **Excess mass below 1,000 kg/month:** Positive (firms bunch below to avoid LQG requirements)
- **Compliance elasticity:** Moderate — regulatory costs are substantial but characterization margins are limited
- **Heterogeneity:** Larger bunching in industries with more waste classification flexibility (chemicals, manufacturing vs. mining, utilities)

## Primary Specification

Bunching estimator: estimate excess mass b = (B_observed - B_counterfactual) / f_0(z*) where B is the count of generators in the bunching region and f_0 is the counterfactual density at the threshold.

Report the compliance elasticity e = b / (z* * f_0(z*)) measuring the fraction of generators who strategically position below the threshold.

## Robustness

1. Vary polynomial order (5th to 9th) for counterfactual density
2. Vary bunching window width
3. McCrary (2008) density test as supplementary diagnostic
4. Placebo threshold tests at round numbers (500 kg, 2000 kg) where no regulatory notch exists
5. Industry-specific bunching (NAICS 2-digit) to test characterization margin hypothesis
6. Before/after 2016 Generator Improvements Rule comparison

## Data Sources

1. **EPA ECHO RCRA** (112MB ZIP): Universe of hazardous waste handlers — 29,176 LQGs, 102,757 SQGs, 273,570 VSQGs. Handler ID, location, NAICS, waste quantities.
2. **RCRAInfo Biennial Reports** (EPA/data.gov): Actual waste generation quantities for LQGs and SQGs every 2 years (2001-2023). 11 waves × ~130,000 generators.
3. **EPA ECHO Enforcement**: Compliance evaluations and violations for mechanism analysis (do firms near threshold get more scrutiny?).

## Data Fetch Strategy

Download ECHO RCRA bulk files (CSV format, direct HTTP download from EPA). Parse biennial report flat files for waste quantity distributions. All public domain, no API key needed.
