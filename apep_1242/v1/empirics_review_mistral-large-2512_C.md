# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-04-01T13:12:52.094655

---

### 1. Idea Fidelity

The paper largely adheres to the original idea manifest but makes several notable deviations and omissions:

**Hits:**
- The core research question—whether companies strategically engineer ownership structures to avoid the 25% disclosure threshold—is faithfully pursued.
- The "equal-split puzzle" (4 shareholders at ~25% each) is a clever operationalization of the bunching concept for discrete ownership data, aligning with the manifest’s focus on configuration anomalies.
- The foreign-ownership and sector heterogeneity channels are explored, as promised.
- The paper uses the PSC bulk snapshot data, though it samples only 5 of 31 chunks (16%) rather than the full universe.

**Misses:**
- **Natural experiments underutilized:** The manifest emphasizes two natural experiments (April 2016 PSC launch and 2023 ECCTA enforcement tightening) for difference-in-bunching analysis, but the paper relies almost entirely on cross-sectional data. There is no pre/post analysis of the 2016 or 2023 reforms, which weakens causal identification.
- **Zero-PSC companies ignored:** The manifest highlights excess mass of companies with *zero* PSC records (all shareholders <25%) as a primary outcome, but this is not analyzed. This is a major omission, as it directly tests the dilution avoidance mechanism.
- **Corporate-layering mechanism:** The manifest mentions testing for interposed corporate entities, but the paper’s analysis of corporate PSCs is cursory (e.g., no formal tests of whether corporate PSC usage increases post-2016).
- **Incorporation rate test:** The manifest proposes comparing incorporation rates of 4-shareholder firms pre/post-2016, but this is not attempted.

**Verdict:** The paper delivers on the *descriptive* goal of documenting the equal-split anomaly but fails to exploit the temporal variation central to the manifest’s identification strategy. The cross-sectional approach limits the paper’s ability to claim causal effects of the PSC regime.

---

### 2. Summary

This paper documents a striking anomaly in UK company ownership structures: among firms with exactly four individual shareholders, 34.2% have all four in the 25–50% ownership band (i.e., each holds ~25%), compared to an expected 1.3% under random assignment. The anomaly is 26 times larger than chance and is concentrated among firms with foreign beneficial owners, suggesting strategic avoidance of the 25% disclosure threshold. The paper argues this reveals a design flaw in global beneficial ownership regimes, which use the same 25% threshold.

---

### 3. Essential Points

**1. Causal identification is weak.**
- The paper relies on cross-sectional data and a model-free configuration test, which is elegant but cannot distinguish strategic avoidance from pre-existing ownership patterns. The manifest promised difference-in-bunching analysis using the 2016 and 2023 reforms as natural experiments, but these are not leveraged. Without pre/post comparisons, the paper cannot rule out that the equal-split configuration is driven by unobserved heterogeneity (e.g., family firms, joint ventures) rather than the PSC regime.
- **Fix:** Use the 2016 PSC launch and 2023 ECCTA enforcement tightening as before/after shocks. Test whether:
  - The equal-split rate increases post-2016 (and post-2023) relative to pre-2016.
  - Zero-PSC companies (all shareholders <25%) become more prevalent post-2016.
  - Corporate PSC usage rises post-2016, especially in high-risk sectors.

**2. The magnitude of avoidance is overstated.**
- The 26:1 ratio is eye-catching but misleading. The "expected" rate (1.3%) assumes independent band assignment, which is unrealistic: ownership shares are inherently correlated (e.g., founders often hold similar stakes). A better benchmark would compare the equal-split rate to firms with *non-equal* splits (e.g., 30-30-20-20) or use a permutation test that preserves within-firm correlation.
- The paper acknowledges this in robustness (permutation test) but downplays its implications. The permutation p-value (0.001) is still significant, but the effect size shrinks dramatically if the null distribution accounts for realistic ownership structures.
- **Fix:** Report the ratio relative to a more plausible counterfactual, such as the rate among firms with 4 shareholders where *not all* are in the 25–50% band (e.g., 3 in 25–50%, 1 in 50–75%). This would isolate the "all at threshold" effect.

**3. The economic significance is unclear.**
- The paper claims the 25% threshold creates a "design failure," but it does not quantify the *cost* of avoidance. How many firms restructure? How much does this undermine the PSC regime’s goals? The 1,930 equal-split firms represent only 0.11% of the sample, and the paper acknowledges this is a lower bound (dilution to 5+ shareholders is unobservable).
- The foreign-ownership effect (0.33pp increase in equal-split probability) is statistically significant but economically small (50% increase over a 0.69% baseline). The paper does not discuss whether this is large enough to matter for AML enforcement.
- **Fix:** Estimate the *total* avoidance rate by combining:
  - Equal-split firms (1,930).
  - Zero-PSC firms (all shareholders <25%; analyze this!).
  - Firms with corporate PSCs (131,256; test if this rises post-2016).
  - Firms with 5+ shareholders (2,279; test if this rises post-2016).
  Compare this to the total number of firms with potential beneficial owners (e.g., those with 1–4 shareholders pre-2016).

---

### 4. Suggestions

#### **A. Strengthen Identification**
1. **Exploit the 2016 and 2023 reforms:**
   - **2016 PSC launch:** Compare firms incorporated *before* April 2016 (no PSC requirement at incorporation) to those incorporated *after* (PSC required at incorporation). Test whether post-2016 firms are more likely to have:
     - Zero PSCs (dilution).
     - 4 equal-split shareholders.
     - Corporate PSCs.
   - **2023 ECCTA enforcement:** Use a difference-in-differences design to compare high-risk sectors (more affected by ECCTA) to low-risk sectors (less affected) before/after 2023. Test whether equal-split rates rise more in high-risk sectors post-2023.

2. **Use a regression discontinuity design:**
   - For firms with 4 shareholders, compare those with ownership shares just below 25% (e.g., 24.9%) to those just above (e.g., 25.1%). If the PSC regime causes avoidance, firms just below 25% should be more likely to have equal splits or corporate PSCs.

3. **Leverage the manifest’s incorporation rate test:**
   - Test whether the share of new firms with exactly 4 shareholders rises post-2016, relative to firms with 3 or 5 shareholders.

#### **B. Improve the Counterfactual**
1. **Alternative benchmarks for the equal-split rate:**
   - Compare to firms with 4 shareholders where *not all* are in the 25–50% band (e.g., 3 in 25–50%, 1 in 50–75%). This isolates the "all at threshold" effect.
   - Use a multinomial logit model to predict the probability of the equal-split configuration based on sector, age, and other covariates, then compare observed vs. predicted rates.

2. **Account for ownership correlation:**
   - The permutation test should preserve within-firm correlation (e.g., permute ownership bands *within* firms, not across all PSCs). This would yield a more realistic null distribution.

#### **C. Quantify the Economic Significance**
1. **Estimate the total avoidance rate:**
   - Combine equal-split firms, zero-PSC firms, corporate PSC firms, and 5+ shareholder firms. Report this as a share of all firms with potential beneficial owners (e.g., those with 1–4 shareholders pre-2016).
   - For zero-PSC firms, test whether their prevalence rises post-2016.

2. **Link to AML outcomes:**
   - Merge PSC data with suspicious activity reports (SARs) or sanctions lists. Test whether equal-split firms are more likely to be involved in money laundering or sanctions evasion.
   - Compare the foreign-ownership effect to the cost of compliance (e.g., legal fees for restructuring). Is the 0.33pp increase large enough to justify policy changes?

3. **Discuss the policy trade-offs:**
   - The paper argues for lowering the threshold to 15%, but this would increase compliance costs for legitimate firms. Quantify the trade-off: how many additional disclosures would a 15% threshold generate, and how many avoidance cases would it prevent?
   - Discuss alternative designs, such as tiered disclosure (e.g., 15% threshold for basic info, 25% for full disclosure).

#### **D. Address Data Limitations**
1. **Use the full PSC snapshot:**
   - The paper samples 5 of 31 chunks (16%). Replicate the analysis on the full dataset to ensure the results are not driven by sampling variation.

2. **Exploit finer ownership data:**
   - The PSC register reports bands (25–50%, etc.), but Companies House may have exact ownership percentages in other filings. If available, use these to test for bunching *within* the 25–50% band (e.g., spikes at 25.01% vs. 24.99%).

3. **Analyze dissolved firms:**
   - The merge rate with company metadata is only 53%. Many unmerged firms may be dissolved or overseas entities. Test whether these are more likely to have avoidance structures (e.g., zero PSCs, corporate PSCs).

#### **E. Clarify the Contribution**
1. **Distinguish from Dharmapala (2023):**
   - The paper cites Dharmapala’s work on SOX bunching but does not clearly explain how this paper differs. Emphasize that:
     - Dharmapala studies a *continuous* running variable (firm size), while this paper studies a *discrete* configuration (4 equal shareholders).
     - This paper focuses on *organizational* avoidance (restructuring ownership), while Dharmapala focuses on *financial* avoidance (under-reporting size).

2. **Engage with the AML literature:**
   - The paper cites Findley et al. (2015) and Johannesen et al. (2020) but does not discuss how its findings fit into the broader debate on AML effectiveness. For example:
     - Does the 25% threshold create a "cliff effect" that undermines the PSC regime’s goals?
     - How does the UK’s experience compare to other countries (e.g., EU, US) with the same threshold?

3. **Discuss alternative explanations:**
   - The paper dismisses "innocent coincidence" but does not seriously consider other explanations for the equal-split anomaly, such as:
     - **Joint ventures:** Firms with 4 equal partners may naturally arise in certain industries (e.g., real estate).
     - **Family firms:** Siblings or cousins may split ownership equally.
     - **Tax optimization:** Equal splits may minimize tax liabilities in some cases.
   - Test these alternatives by:
     - Comparing equal-split rates in industries where joint ventures are common (e.g., construction) vs. uncommon (e.g., retail).
     - Using name matching to identify family firms (e.g., same surname among PSCs).

#### **F. Improve Presentation**
1. **Clarify the configuration test:**
   - The paper’s central test (observed vs. expected equal-split rate) is intuitive but could be explained more clearly. Add a figure showing:
     - The ownership band distribution for all PSCs.
     - The expected vs. observed equal-split rates for 2–6 shareholders.
     - A histogram of the permutation test results.

2. **Report effect sizes more transparently:**
   - The foreign-ownership effect is reported as a 0.33pp increase, but the baseline rate (0.69%) is buried in the notes. Report the baseline in the main text and discuss whether a 50% increase is economically meaningful.
   - Use standardized effect sizes (as in the appendix) in the main text to help readers assess magnitude.

3. **Simplify the robustness section:**
   - The polynomial sensitivity analysis (Table 7) is important but overly technical for the main text. Move it to the appendix and focus on the key takeaway: the configuration test is more robust than distributional bunching.

---

### Final Verdict

This is a **promising but incomplete** paper. The equal-split puzzle is a novel and compelling finding, but the paper’s cross-sectional design limits its ability to claim causal effects. The authors must:
1. Exploit the temporal variation in the PSC regime (2016 launch, 2023 ECCTA) to strengthen identification.
2. Address the counterfactual’s unrealistic independence assumption and provide a more plausible benchmark.
3. Quantify the economic significance of avoidance and link it to AML outcomes.

With these changes, the paper could make a strong contribution to the literature on beneficial ownership transparency and regulatory avoidance. As it stands, the results are suggestive but not conclusive.
