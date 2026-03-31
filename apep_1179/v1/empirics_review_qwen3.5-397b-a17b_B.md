# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-31T10:10:40.310796

---

1. **Idea Fidelity**

The paper pursues the core objective of the original manifest—testing the Mauro (1998) hypothesis using China's anti-corruption campaign—but deviates significantly in identification strategy and outcome focus. The manifest specified a **staggered DiD** exploiting the *timing* of first investigations (Callaway-Sant'Anna), whereas the paper employs a **continuous treatment intensity** model (Post × Log(Investigations)). This shifts the causal question from "does enforcement *timing* affect spending?" to "does enforcement *severity* correlate with spending?" which introduces potential endogeneity (severity may reflect pre-existing corruption levels). Additionally, the manifest prioritized Education/Health vs. Infrastructure; the paper's headline result pivots to Science & Technology expenditure, though Infrastructure and Education are still reported. Finally, the manifest proposed county-level variation, but the paper aggregates to prefecture-level cities, reducing granularity. While the data sources (Wang 2020, Fiscal Yearbooks) align with the manifest, the empirical execution diverges from the proposed causal design.

2. **Summary**

This paper examines whether China's 2012 anti-corruption campaign altered the composition of local public spending, testing the hypothesis that corruption biases budgets toward extractable infrastructure. Using prefecture-level data on corruption investigations and fiscal expenditure (2007–2016), the authors find no evidence that enforcement reduced infrastructure spending shares or increased education shares. Instead, they document a "compliance shift": cities with higher enforcement intensity increased their share of science and technology expenditure and total fiscal spending levels. The authors argue this reflects local officials signaling alignment with central priorities rather than reducing rent-seeking opportunities.

3. **Essential Points**

1.  **Identification Strategy (Intensity vs. Timing):** The primary specification uses cumulative investigation intensity (2013–2016) as the treatment. This is likely endogenous: cities with more investigations likely had higher underlying corruption, which (per Mauro) correlates with higher infrastructure spending. The manifest proposed using the *timing* of inspections (staggered adoption) to isolate the enforcement shock. The current design conflates the *shock* with the *severity* of the underlying problem. You must either justify why intensity is exogenous conditional on fixed effects or revert to the staggered timing design promised in the feasibility check.
2.  **Outcome Measurement (FAI vs. Fiscal Capital):** You use Fixed Asset Investment (FAI)/GDP as a proxy for infrastructure spending. FAI includes private and corporate investment, not just local government fiscal expenditure. The Mauro hypothesis concerns *public budget allocation*. Using FAI conflates government policy with broader economic activity. You must use the specific fiscal line item for "Capital Construction" or "Infrastructure" from the Finance Statistics to validly test the fiscal composition hypothesis.
3.  **Mechanism Validation (The "Compliance Shift"):** The claim that Science & Technology spending is "auditable" and "centrally prioritized" is asserted but not evidenced. To support the "compliance shift" narrative, you need to demonstrate that Science spending faced different procurement rules or central targeting than Infrastructure during this period. Without this, the result could simply reflect a general trend in Chinese industrial policy unrelated to anti-corruption enforcement.

4. **Suggestions**

To strengthen the paper for publication, particularly within the *AER: Insights* format which demands high clarity on causal mechanisms, I recommend the following detailed improvements. These suggestions focus on refining the econometric design, improving data measurement, and deepening the mechanistic interpretation.

**A. Econometric Design and Identification**

*   **Revisit the Staggered Design:** The manifest highlighted the staggered timing of CCDI inspection rounds as a key source of exogenous variation. The current continuous intensity model (`Post × Log(Inv)`) risks reverse causality: the CCDI may have targeted cities *because* their spending patterns were already anomalous or corrupt. I strongly suggest reverting to a staggered DiD framework where treatment is defined by the *year of the first CCDI inspection round* in the prefecture. This aligns with the Callaway-Sant'Anna estimator mentioned in your robustness section. If the pre-trends in the CS estimator were problematic (as noted in Section 5.3), you need to address this transparently. Consider using the *assignment* of inspection rounds (which was often rotational or randomized across provinces) as an instrument for local investigation intensity, rather than using the realized count of investigations directly.
*   **Address Endogeneity of Intensity:** If you retain the intensity measure, you must argue why the *number* of officials investigated is exogenous to local fiscal trends. One approach is to control for pre-period corruption proxies (e.g., pre-2013 investigation counts, as you did in the placebo) more rigorously. Alternatively, interact the post-period with a measure of *central inspection presence* rather than local investigation outcomes. The central inspection teams were sent from Beijing; their arrival is more exogenous than the local outcome of how many people they jailed.
*   **Dynamic Effects:** Your event study shows effects building over 3–4 years. This is plausible for budgetary reallocation but requires discussion. Budgets are often sticky. Consider lagging the treatment variable or using a distributed lag model to better capture the gradual reallocation of fiscal resources. Ensure the event study graphs are visualized (currently only tables are provided) to allow readers to assess parallel trends visually, which is standard in modern DiD literature.

**B. Data and Measurement**

*   **Correct the Infrastructure Proxy:** Replace FAI/GDP with explicit fiscal expenditure categories. The China City Statistical Yearbook and Ministry of Finance data typically report "Expenditure on Capital Construction" (基本建设支出) or similar line items. This is the direct test of the Mauro hypothesis. FAI/GDP is too broad and includes private sector behavior that anti-corruption enforcement might affect through different channels (e.g., private investment confidence).
*   **Health Data Availability:** The manifest noted Health expenditure as a key outcome. The paper states health data is unavailable as a separate budget line. Please verify this with the *China Local Finance Statistics* (中国地方财政统计年鉴), which often disaggregates "Education," "Science," "Health," and "Social Security" more finely than the City Statistical Yearbook. If health data exists at the prefecture level, including it is crucial for a complete test of the Mauro hypothesis. If not, explicitly state the limitation in the data section rather than the discussion.
*   **Deflation and Real Terms:** Ensure all fiscal variables are deflated using local CPI or provincial GDP deflators. Nominal expenditure shares can shift due to price changes in construction materials vs. salaries. Reporting results in real per-capita terms would add robustness to the "levels" findings.

**C. Mechanism and Interpretation**

*   **Evidence for "Auditability":** The core novel claim is the "compliance shift" toward auditable categories. To substantiate this, cite specific policy documents from the 2013–2
