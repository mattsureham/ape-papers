# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-03-13T11:11:54.629884

---

### 1. Idea Fidelity

The paper closely adheres to the original manifest. It leverages the symmetric SALT cap shocks (2018 TCJA and 2025 OBBB) to test housing capitalization reversibility using a continuous-treatment DiD design at the zip-code level. Key elements from the manifest are preserved:
- **Data sources**: Zillow ZHVI (monthly, zip-level), IRS SOI (2017 SALT deductions), and robustness checks with FHFA and Redfin data.
- **Identification strategy**: Continuous-treatment DiD with pre-reform SALT exposure, metro×month fixed effects, and symmetry tests.
- **Novelty**: First study of the 2025 OBBB reversal and explicit test of asymmetric capitalization.

Minor deviations:
- The manifest mentions IRS SOI *migration flows* as a secondary outcome, but these are not used in the paper (likely due to timing; migration data lags by years).
- The manifest’s "smoke test log" is not replicated in the paper, but the data access claims are validated in the appendix.

### 2. Summary

This paper exploits the 2018 SALT deduction cap and its 2025 reversal to test whether housing capitalization is symmetric. Using a continuous-treatment DiD design across 25,303 zip codes, it finds:
1. The TCJA cap reduced log house prices by **0.0033 per $1,000 of SALT exposure** (≈6.6% for above-cap zip codes), with effects reaching **10.5% in the highest-exposure quintile**.
2. The OBBB reversal produced **no statistically significant price recovery** (p=0.68), rejecting symmetric capitalization. The asymmetry suggests permanent household sorting into/out of high-tax jurisdictions.

The paper’s key contribution is empirical: it provides the first evidence that tax-induced housing price declines may not reverse when the tax change is undone, challenging the theoretical prediction of symmetric capitalization.

---

### 3. Essential Points

#### **1. Magnitudes and Plausibility**
The estimated effects are **economically large but plausible**:
- A **6.6% price decline** for above-cap zip codes aligns with prior work (e.g., Kuminoff et al. 2020: 3–7%; Zoeckler & Sommer 2022: smaller effects). The dose-response gradient (up to 10.5%) is credible given the convexity of tax burdens in high-SALT areas.
- The **asymmetry** (no recovery post-OBBB) is striking but consistent with sorting hysteresis. However, the paper does not rule out alternative explanations:
  - **Expectations**: Buyers may doubt the OBBB’s permanence (the TCJA cap was "temporary" for 8 years). The paper mentions this but does not test it (e.g., by comparing price responses in 2025 vs. 2026, when the OBBB’s stability might be clearer).
  - **Lags**: The OBBB’s effects may take time to materialize. The paper uses only **14 months of post-OBBB data** (Jan 2025–Feb 2026), which is short for housing market adjustments. A longer post-OBBB window (e.g., 2–3 years) would strengthen the claim of irreversibility.

**Suggestion**: Acknowledge the short post-OBBB window as a limitation and discuss how future data might clarify the dynamics. Consider event-study plots for the OBBB period to visualize trends.

#### **2. Standard Errors and Clustering**
- **State-level clustering** is appropriate given the policy’s state-level variation, but the paper also reports **zip-level clustering** (Table 5, Column 4), which yields **4× tighter standard errors**. This discrepancy suggests potential spatial autocorrelation or heteroskedasticity.
- **Issue**: The zip-level SEs may be anti-conservative. The paper should justify why state-level clustering is preferred (e.g., cite Cameron & Miller 2015 on spatial correlation in housing data).

**Suggestion**: Report Conley (1999) standard errors (spatial HAC) as a robustness check, given the geographic nature of the treatment.

#### **3. Pre-Trends and Parallel Trends**
- The paper notes **positive pre-trends** (high-SALT zip codes appreciated faster pre-2018), which it argues makes the DiD estimate **conservative**. This is correct but requires clearer communication:
  - The event-study plot (not shown) should be included in the main text to visually confirm the pre-trend divergence and post-cap reversal.
  - The symmetry test (Table 3, Column 3) shows **β_OBBB < β_TCJA** (more negative), which is puzzling. If pre-trends were positive, why do prices continue to fall post-OBBB? This could reflect:
    - **Sorting hysteresis**: Out-migration continued even after the cap was lifted.
    - **Measurement error**: The OBBB’s phase-out (AGI > $500K) may not be fully captured by the continuous SALT exposure measure.
  - **Suggestion**: Test for differential trends by income (e.g., using IRS AGI data) to explore whether the OBBB’s phase-out drives the asymmetry.

---

### 4. Suggestions

#### **A. Strengthen the Mechanism Discussion**
The paper attributes asymmetry to **household sorting hysteresis**, but this is not directly tested. Suggestions:
1. **Migration data**: Use IRS SOI county-to-county migration flows (2017–2022) to show:
   - Out-migration from high-SALT zip codes post-2018.
   - Lack of return migration post-2025 (despite the OBBB).
2. **Heterogeneity by income**: The OBBB phases out for AGI > $500K. Test whether the asymmetry is driven by high-income households (who face the phase-out) vs. middle-income households (who benefit fully).
3. **Local amenities**: High-SALT areas often have high public goods (schools, transit). Test whether the asymmetry is stronger in zip codes with:
   - Higher school spending (NCES data).
   - Better transit access (e.g., walkability scores).

#### **B. Address Alternative Explanations**
1. **Expectations**: Survey data (e.g., University of Michigan Surveys of Consumers) could proxy for beliefs about the OBBB’s permanence. Alternatively, compare price responses in 2025 (when the OBBB was announced) vs. 2026 (when its stability might be clearer).
2. **Supply constraints**: High-SALT areas may have inelastic housing supply. Test whether the asymmetry is stronger in zip codes with:
   - Higher land-use regulation (e.g., Wharton Residential Land Use Regulatory Index).
   - Lower housing elasticity (Saiz 2010).
3. **Interest rates**: The post-2022 period saw rising mortgage rates, which may have disproportionately affected high-value homes. Control for zip-level mortgage rate exposure (e.g., using Freddie Mac data).

#### **C. Improve Robustness Checks**
1. **Longer post-OBBB window**: Extend the analysis to 2027–2028 (if data permits) to test for delayed recovery.
2. **Alternative treatment definitions**:
   - Use **marginal tax rates** (from NBER TAXSIM) to construct a zip-level "effective SALT burden" (accounting for the TCJA’s higher standard deduction).
   - Test a **binary treatment** based on whether the zip’s average SALT exceeds the OBBB’s $40K cap (to isolate zip codes unaffected by the phase-out).
3. **Falsification tests**:
   - Test for pre-trends in **housing quantity** (Redfin inventory) to rule out supply-side explanations.
   - Test for effects in **rental prices** (Zillow Rent Index) to isolate capitalization into owner-occupied housing.

#### **D. Clarify the Symmetry Test**
- The symmetry test (Table 3, Column 3) rejects **β_TCJA + β_OBBB = 0** (p=0.0002), but the reported p-value (0.548) seems to test **β_TCJA = β_OBBB**. Clarify the null hypothesis in the table note.
- The OBBB coefficient is **more negative** than the TCJA coefficient, which is counterintuitive. Discuss whether this reflects:
  - Continued out-migration post-OBBB.
  - Measurement error in the OBBB period (e.g., the phase-out).

#### **E. Data and Reproducibility**
1. **Data availability**: The paper claims all data are "publicly downloadable," but:
   - IRS SOI zip-code data requires a request (not a direct download).
   - Redfin data is proprietary (though the paper uses it only for robustness).
   - **Suggestion**: Provide a replication package with:
     - Cleaned Zillow ZHVI and IRS SOI data (or scripts to download them).
     - Code for all tables/figures.
2. **Sample restrictions**:
   - The paper drops 30% of zip codes due to ZHVI coverage gaps. Test whether the results are sensitive to this restriction (e.g., by imputing missing values or using FHFA data, which has broader coverage).
   - The IRS SOI suppresses zip codes with <20 returns. Test whether the results hold when including suppressed zip codes (e.g., by assigning them the state median SALT).

#### **F. Presentation Improvements**
1. **Figures**:
   - **Event-study plot** for the TCJA cap (showing pre-trends and post-cap divergence).
   - **Dose-response plot** (Table 4 as a figure with confidence intervals).
   - **Map** of SALT exposure and price changes (to visualize geographic patterns).
2. **Tables**:
   - Report **mean outcomes** (log ZHVI) pre/post-TCJA and pre/post-OBBB for treated vs. control zip codes (to contextualize the DiD estimates).
   - Include a **balance table** showing pre-2018 trends in covariates (e.g., income, homeownership rates) by SALT exposure quintile.
3. **Standardized effects**:
   - The standardized effect sizes (Table S1) are useful but should be discussed in the main text. For example:
     - The TCJA cap effect (SDE = -0.046) is "small" by Cohen’s (1988) benchmarks but large for housing markets (where 5% price changes are economically meaningful).

#### **G. Policy Implications**
The paper argues that the asymmetry implies **permanent wealth transfers** from high-SALT homeowners. To strengthen this:
1. **Quantify the wealth effect**: Multiply the price decline by the number of above-cap homes (e.g., using ACS data) to estimate the total wealth loss.
2. **Distributional analysis**: Use IRS SOI data to show how the wealth loss varies by income percentile (e.g., top 1% vs. top 10%).
3. **Counterfactuals**: Simulate what prices would have been if the OBBB had fully reversed the cap (e.g., using the TCJA estimate).

---

### Final Assessment
This is a **strong paper** with a **novel identification strategy** and **economically meaningful results**. The asymmetry finding is compelling and has important implications for tax capitalization theory. With the suggested improvements—particularly to the mechanism discussion, robustness checks, and presentation—it could be a **top-tier publication**.

**Key strengths**:
- Exploits a rare symmetric policy shock.
- Uses high-frequency, granular data (zip-level monthly prices).
- Robust identification (continuous treatment, within-metro FE, placebo tests).

**Key areas for improvement**:
- Address the short post-OBBB window and expectations channel.
- Test alternative mechanisms (sorting, supply constraints, interest rates).
- Improve reproducibility (replication package, data access details).

**Recommendation**: **Revise and resubmit** with the above suggestions addressed. The core result is likely to hold, but the paper would benefit from deeper exploration of the asymmetry’s drivers.
