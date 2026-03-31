# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-03-31T15:00:21.362614

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest. It leverages the STATENT establishment-by-employment decomposition to test whether municipal corporate tax cuts (Steuerfuss reductions) attract real economic activity or letterbox companies. The identification strategy—municipality-level panel DiD with staggered treatment—is faithfully implemented, and the key outcomes (employment per establishment, sectoral decomposition) align with the manifest. The placebo test (natural-person Steuerfuss) and triple-difference (sector × time) are partially addressed, though the latter could be more explicitly formalized. The paper’s focus on cantons Zurich and Basel-Landschaft is narrower than the manifest’s implied scope (2,137 municipalities), but this is a reasonable feasibility trade-off. No critical elements of the original idea are missed.

---

### 2. Summary

This paper exploits within-municipality variation in Swiss corporate tax rates to test whether tax cuts attract real firms or letterbox entities. Using STATENT data, it finds that a ≥5pp Steuerfuss cut increases establishments by 2.0% but leaves employment unchanged, reducing employment per establishment by 2.1%. The effect is concentrated in the tertiary sector (–6.6%), where letterbox companies cluster, and absent in manufacturing. Placebo tests, dose-response patterns, and event studies support a causal interpretation. The results suggest subnational tax competition partly operates as a zero-sum relabeling of paper entities.

---

### 3. Essential Points

**1. Identification and Parallel Trends**
The paper’s DiD design hinges on the parallel trends assumption, but the event study (Figure not shown in the LaTeX) is described only in text. The authors must:
- **Show the event study graph** for tertiary employment per establishment, with 95% confidence intervals, to visually confirm no pre-trends. The text mentions "clean pre-trends," but this is unconvincing without visual evidence.
- **Test for differential pre-trends formally** (e.g., joint significance of pre-treatment coefficients). The current description is hand-wavy.

**2. Magnitude and Economic Meaningfulness**
The 2.1% reduction in employment per establishment is statistically significant but economically modest. The authors should:
- **Quantify the aggregate effect**: If a municipality gains 2% more establishments (e.g., 10 new firms) but loses 0.12 workers per firm, the net employment change is negligible. Is this consistent with the "zero-sum relabeling" claim? The paper needs a back-of-the-envelope calculation to contextualize the welfare implications (e.g., fiscal cost per job "created").
- **Clarify the counterfactual**: The tertiary-sector effect (–6.6%) is large, but the paper does not explain why this is meaningful. Is a 6.6% reduction in employment intensity for tertiary firms a smoking gun for letterbox companies, or could it reflect other mechanisms (e.g., outsourcing, automation)?

**3. Generalizability and External Validity**
The sample is limited to two cantons (Zurich and Basel-Landschaft), which may not represent Switzerland’s 2,100+ municipalities. The authors must:
- **Acknowledge and justify the sample restriction**: Why these cantons? Are they outliers in tax competition or establishment composition? The paper should compare summary statistics (e.g., employment per establishment, Steuerfuss levels) to national averages.
- **Discuss potential heterogeneity**: The dose-response table (Table 4) includes a ≥10pp cut with only 2 treated municipalities. This is underpowered and risks overfitting. The authors should either drop this threshold or explicitly label it as exploratory.

---

### 4. Suggestions

**A. Strengthening the Identification**
1. **Staggered DiD Concerns**: The paper uses a binary "PostCut" indicator, which can bias estimates in staggered designs (de Chaisemartin & D’Haultfœuille, 2020). The authors should:
   - Re-estimate using **event-study coefficients** (interaction of treatment with relative year dummies) to avoid bias from heterogeneous treatment effects.
   - Alternatively, use **Callaway & Sant’Anna (2021)** or **Sun & Abraham (2021)** estimators for staggered DiD.

2. **Dynamic Effects**: The event study description suggests effects grow over time (–13.9% at t=5). The authors should:
   - **Plot the dynamic effects** to show whether the effect stabilizes or continues to grow. If the latter, this could reflect gradual relocation or mean reversion.
   - **Test for persistence**: Does the effect fade after 5 years, or is it permanent? This informs whether tax cuts have lasting or temporary impacts.

3. **Placebo Tests**: The natural-person Steuerfuss placebo is a strength, but the authors could:
   - **Add a second placebo**: Test for effects on outcomes unrelated to tax cuts (e.g., population growth, residential property taxes). This would further rule out confounding trends.
   - **Report the placebo event study**: Show that natural-person tax cuts have no pre- or post-trends.

**B. Improving Economic Interpretation**
1. **Mechanism Clarity**: The paper argues that tertiary-sector firms are letterbox companies, but this is asserted rather than proven. The authors should:
   - **Provide descriptive evidence**: Show the distribution of employment per establishment in the tertiary sector (e.g., % of firms with <5 employees). This would help readers assess whether the –6.6% effect is driven by extreme outliers (e.g., 0-employee firms).
   - **Link to profit-shifting literature**: Compare the Swiss municipal effects to cross-country estimates (e.g., Tørsløv et al., 2023). Are the magnitudes similar, or is subnational competition less severe?

2. **Fiscal Costs**: The paper claims tax cuts are "zero-sum," but this ignores the fiscal trade-off. The authors should:
   - **Estimate the net fiscal effect**: Calculate the revenue loss from cutting rates on existing firms versus the revenue gain from new registrations. This would clarify whether municipalities are net winners or losers.
   - **Discuss spillovers**: Do tax cuts in one municipality reduce employment in neighboring municipalities? A spatial analysis (e.g., including neighboring Steuerfuss as a control) could test for leakage.

3. **Sectoral Heterogeneity**: The tertiary-sector effect is the paper’s strongest result, but the sectoral decomposition is coarse. The authors should:
   - **Disaggregate the tertiary sector**: Financial services, holding companies, and IP vehicles may respond differently to tax cuts. A finer sectoral breakdown (e.g., NACE 2-digit) could sharpen the mechanism.
   - **Test for firm size effects**: Are the new tertiary establishments small (consistent with letterbox firms) or large (consistent with real activity)? The authors could interact treatment with firm size dummies.

**C. Robustness and Sensitivity**
1. **Alternative Specifications**: The paper relies on log-linear models, which assume constant elasticities. The authors should:
   - **Test linear models**: Report results for employment per establishment in levels (not logs) to check sensitivity to functional form.
   - **Include controls for economic conditions**: Add cantonal GDP growth or unemployment rates to rule out confounding macro trends.

2. **Sample Restrictions**: The paper excludes municipalities with missing Steuerfuss data. The authors should:
   - **Describe the missingness**: How many municipalities are excluded, and why? Are excluded municipalities systematically different (e.g., smaller, rural)?
   - **Test for selection bias**: Compare pre-treatment trends for included vs. excluded municipalities.

3. **Standard Errors**: The paper clusters at the canton level (2 clusters), which is conservative but may over-reject. The authors should:
   - **Report wild bootstrap p-values**: Given the small number of clusters, wild bootstrap (Cameron et al., 2008) would provide more reliable inference.
   - **Discuss power**: With only 25 treated municipalities, the paper may be underpowered for some tests (e.g., secondary-sector effects). The authors should acknowledge this limitation.

**D. Presentation and Clarity**
1. **Tables and Figures**:
   - **Add a map**: Show the geographic distribution of treated municipalities and Steuerfuss levels. This would help readers assess spatial clustering.
   - **Improve Table 1**: The summary statistics table should include pre- and post-treatment means for treated municipalities to highlight balance.
   - **Label dose-response thresholds clearly**: Table 4’s "≥10pp" cut has only 2 treated municipalities. This should be flagged as exploratory.

2. **Writing**:
   - **Clarify the "letterbox" definition**: The paper uses "letterbox" loosely. Define it explicitly (e.g., firms with <X employees, no physical presence) and justify the threshold.
   - **Tighten the discussion**: The discussion of OECD Pillar Two is speculative. The authors should either (a) drop it or (b) provide a concrete link (e.g., "Our results suggest Pillar Two should consider subnational minimum taxes").

3. **Appendix**:
   - **Include robustness checks**: The appendix should report results for alternative bandwidths (e.g., ≥4pp, ≥6pp cuts) and additional placebo tests.
   - **Show balance tests**: Report pre-treatment differences between treated and control municipalities for key covariates (e.g., population, sectoral composition).

**E. Extensions and Future Work**
1. **Nationwide Analysis**: The paper’s biggest limitation is its narrow geographic scope. The authors should:
   - **Outline a path to broader data**: Contact cantonal statistical offices to obtain Steuerfuss data for all 26 cantons.
   - **Discuss heterogeneity**: Would the effect differ in rural vs. urban cantons? In cantons with different tax base rules?

2. **Firm-Level Data**: STATENT provides establishment-level data, but the paper aggregates to the municipality. The authors could:
   - **Exploit establishment-level variation**: Estimate a firm-level DiD to test whether tax cuts attract new firms or induce existing firms to relocate.
   - **Test for profit shifting**: Link to tax return data to see if tax cuts increase reported profits (consistent with profit shifting) or employment (consistent with real activity).

3. **Policy Counterfactuals**: The paper could simulate the effects of policy changes, such as:
   - **Harmonizing Steuerfuss**: What would happen if all municipalities set the same corporate tax rate?
   - **Minimum tax rules**: How would a subnational minimum tax (analogous to Pillar Two) affect establishment composition?

---

### Final Assessment

This is a **promising and well-executed paper** that addresses an important gap in the literature. The identification strategy is sound, the data are rich, and the results are economically meaningful. However, the paper’s credibility hinges on three critical fixes:
1. **Visual and formal tests of parallel trends** (essential for DiD validity).
2. **Clearer economic interpretation** of the magnitudes (e.g., fiscal costs, welfare implications).
3. **Acknowledgment of limitations** (e.g., sample restrictions, power, generalizability).

With these improvements, the paper could make a **strong contribution** to the tax competition and profit-shifting literatures. The core finding—that subnational tax cuts attract letterbox companies—is novel and policy-relevant, but the current draft leaves room for skepticism about its robustness and significance.
