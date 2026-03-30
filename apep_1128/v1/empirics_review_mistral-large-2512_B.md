# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-30T11:12:33.013635

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest. It successfully implements the proposed triple-difference (now quadruple-difference) design using QWI race-by-county-by-quarter data to evaluate the staggered state non-compete bans. The core research question—whether non-compete bans differentially affect Black and White workers in knowledge-intensive sectors—is preserved, as are the key outcomes (separation rates, earnings) and the identification strategy (staggered adoption, Callaway-Sant’Anna for inference). The manifest’s emphasis on racial heterogeneity (rather than education-based heterogeneity) is faithfully executed, and the use of NAICS 72 as a placebo sector aligns with the original plan.

Two minor deviations are noted:
1. The paper expands the design to a *quadruple*-difference (adding race as a fourth dimension) rather than the manifest’s triple-difference. This is a justified improvement, as it directly estimates the racial interaction of interest.
2. The manifest mentions county-level data, but the paper aggregates to the state level. This sacrifices granularity but is likely necessary for statistical power given the small number of treated states. The trade-off is reasonable but should be acknowledged as a limitation.

### 2. Summary

This paper exploits staggered state-level non-compete bans (2020–2023) to test whether these policies reduce racial gaps in earnings and mobility for Black workers in knowledge-intensive industries. Using a quadruple-difference design with QWI administrative data, the authors find that bans raise Black workers’ earnings by 3.8% relative to White workers in treated sectors but do not affect the racial gap in separation rates. The results suggest that non-compete bans improve Black workers’ bargaining power (via credible outside options) without triggering actual job-switching, highlighting a "bargaining dividend" distinct from mobility gains. The paper contributes novel evidence on racial heterogeneity in policy effects and separates wage and mobility channels of labor market inequality.

---

### 3. Essential Points

**Point 1: Identification with Few Treated Clusters**
The paper’s key limitation is the small number of treated states (5). While the quadruple-difference design is theoretically sound, inference with few clusters is fragile. The authors address this by:
- Reporting cluster-robust standard errors (baseline) and Callaway-Sant’Anna estimates (robustness).
- Showing placebo tests (fake treatment in 2018, NAICS 72 placebo sector) yield null results.

*However*, the Callaway-Sant’Anna estimates for separation rates are imprecise (SE = 0.052), and the wild cluster bootstrap (recommended for few clusters) is not implemented. **The authors must**:
- Report wild cluster bootstrap p-values for the main DDDD coefficients (e.g., using the `boottest` or `fwildclusterboot` packages in R/Stata).
- Clarify whether the null separation-rate result is robust to alternative inference methods or reflects low power. If the latter, temper claims about the absence of mobility effects.

**Point 2: Mechanism and Interpretation**
The paper’s central claim—that bans improve Black workers’ bargaining power without increasing mobility—is plausible but requires stronger justification. The authors cite theoretical work (Shi 2023) and racial disparities in enforcement costs (Butler 2023), but the empirical evidence is indirect. **The authors must**:
- Explicitly test for *within-job* wage growth (e.g., by examining earnings changes for workers who do *not* separate). The QWI’s cell-level data precludes this, but the authors should discuss this limitation more prominently and propose future work (e.g., using LEHD microdata) to validate the mechanism.
- Address whether the earnings effect could reflect compositional changes (e.g., lower-wage Black workers leaving the sector post-ban). The null hire-rate result suggests this is unlikely, but the authors should rule it out more formally (e.g., by checking employment levels by race in treated sectors).

**Point 3: Heterogeneity by Ban Type**
The manifest notes that bans vary in scope (e.g., income thresholds in OR/WA/CO vs. complete bans in MN). The paper pools these treatments, which may obscure heterogeneity. **The authors must**:
- Split the sample by ban type (income-threshold vs. complete) and report results separately. If power is insufficient, acknowledge this as a limitation and discuss how differential coverage might bias estimates (e.g., income thresholds may exclude higher-earning Black workers, attenuating earnings effects).
- Test whether the earnings effect is concentrated in states with broader bans (e.g., MN) or those with income thresholds (which may cover more Black workers).

---

### 4. Suggestions

#### **Conceptual and Theoretical**
1. **Clarify the "Bargaining Dividend" Mechanism**:
   - The paper’s key contribution is distinguishing wage and mobility channels. To strengthen this, add a simple theoretical model (e.g., a Nash bargaining framework) showing how non-competes can suppress wages without affecting turnover if workers’ outside options are constrained but not eliminated. This would help readers understand why the earnings effect might emerge without a mobility effect.
   - Cite empirical work on racial differences in bargaining power (e.g., Card et al. 2018 on gender/racial wage gaps in unionized settings) to contextualize the results.

2. **Discuss Alternative Explanations**:
   - Could the earnings effect reflect *employer* responses (e.g., firms raising wages to retain Black workers preemptively)? This would still align with the bargaining story but should be acknowledged.
   - Could the null separation result reflect offsetting effects (e.g., bans increase Black workers’ *voluntary* separations but decrease *involuntary* separations)? The QWI’s separation rate aggregates both, so this cannot be tested, but the authors should note it as a caveat.

3. **Policy Implications**:
   - The paper argues that NCA bans are a "partial equity tool." Expand this discussion to compare the earnings effect (3.8%) to other interventions (e.g., minimum wage increases, anti-discrimination enforcement) in terms of cost-effectiveness and scalability.
   - Discuss whether the earnings effect is likely to persist or fade over time (e.g., as firms adjust hiring practices or workers’ outside options equilibrate).

#### **Empirical and Methodological**
4. **Improve Inference**:
   - Implement wild cluster bootstrap p-values for all main results (not just Callaway-Sant’Anna). This is critical for credibility given the small number of treated states.
   - Report event-study plots for the DDDD coefficients (e.g., using the `eventstudyinteract` package). These would show whether effects emerge immediately post-ban or with a lag, and whether pre-trends are parallel.

5. **Address Data Limitations**:
   - The QWI’s cell-level data preclude tracking individual workers. Acknowledge this more prominently and discuss how future work with LEHD microdata could validate the mechanism (e.g., by showing that Black workers who *do not* separate see wage gains post-ban).
   - The paper drops always-treated states (CA/OK/ND). Consider including them as a robustness check (e.g., by interacting with a "long-run ban" indicator) to test whether effects persist over time.

6. **Explore Heterogeneity**:
   - **By Industry**: The paper pools NAICS 51 and 54. Test whether effects differ between these sectors (e.g., tech vs. professional services), as non-compete prevalence and enforcement may vary.
   - **By State**: Report results separately for states with income thresholds (OR/WA/CO) vs. complete bans (IL/MN). If power is low, use a single heterogeneity test (e.g., interacting the DDDD coefficient with a "broad ban" indicator).
   - **By Worker Characteristics**: The QWI includes sex and education (E0). Test whether the earnings effect is larger for Black women or less-educated Black workers, who may face compounded barriers.

7. **Robustness Checks**:
   - **Alternative Placebo Sectors**: Test a second placebo sector (e.g., NAICS 62, Healthcare) to confirm that results are not driven by idiosyncratic trends in NAICS 72.
   - **Dynamic Effects**: The paper drops COVID quarters (2020 Q2–Q4) but does not test whether effects vary by post-ban duration. Report results for 1-year vs. 2-year post-ban windows to assess persistence.
   - **Synthetic Control**: Given the small number of treated states, consider a synthetic control approach (e.g., Abadie 2021) for the earnings outcome, using a weighted average of control states to match pre-trends.

8. **Presentation and Transparency**:
   - **Table 1 (Summary Statistics)**: Add a column showing the *difference* between ban and control states for each race group (e.g., "Ban - Control" for Black workers). This would help readers assess parallel trends.
   - **Table 2 (Main Results)**: Clarify that the DDDD coefficients in columns (3)–(5) are the *triple* interaction terms (Post × Knowledge × Black), not the quadruple interaction. The notation in Equation (1) is correct, but the table could be clearer.
   - **Appendix**: Include a table showing the timing of bans by state and the share of Black workers covered by income thresholds (for OR/WA/CO). This would help readers understand the treatment variation.

9. **Literature Context**:
   - The paper cites Starr et al. (2021) and Marx et al. (2015) but does not engage with recent work on non-competes and inequality (e.g., Lipsitz and Starr 2022 on low-wage workers, or Balasubramanian et al. 2022 on mobility). Update the literature review to reflect the latest evidence on heterogeneous effects.
   - Discuss how the paper’s findings relate to the broader literature on racial wage gaps (e.g., Neal and Johnson 1996, Lang and Lehmann 2012). For example, does the 3.8% earnings effect close a meaningful portion of the racial wage gap in knowledge sectors?

10. **Writing and Clarity**:
    - The abstract and introduction are well-written, but the empirical sections could be more concise. For example:
      - Move the detailed discussion of QWI data sources to the appendix.
      - Shorten the institutional background section (Section 2) by focusing only on aspects directly relevant to the racial heterogeneity hypothesis (e.g., enforcement disparities).
    - Define "bargaining dividend" more clearly in the introduction. The term is catchy but could be confused with other mechanisms (e.g., union bargaining).
    - The discussion of limitations (Section 6) is strong but could be expanded to address the small number of treated states more explicitly. For example: "With only five treated states, our estimates may not generalize to other contexts, and the null separation-rate result may reflect low power rather than a true zero effect."

#### **Broader Impact**
11. **External Validity**:
    - The paper focuses on knowledge-intensive sectors. Discuss whether similar effects might emerge in other industries (e.g., healthcare, where non-competes are also common) or for other marginalized groups (e.g., Hispanic workers, who are not analyzed here).
    - Speculate on why the mobility effect is null. Is this likely to hold in other contexts, or might it reflect the specific labor market conditions of 2020–2023 (e.g., tight labor markets reducing the need for job-switching)?

12. **Future Research**:
    - Propose specific follow-up studies, such as:
      - Using LEHD microdata to track individual workers and test the within-job wage growth mechanism.
      - Examining whether NCA bans affect racial gaps in entrepreneurship (e.g., Black-owned business formation in knowledge sectors).
      - Testing whether the earnings effect persists in states with weaker enforcement of bans (e.g., those with fewer labor department resources).

---

### Final Assessment
This is a well-executed paper with a compelling research design and novel findings. The quadruple-difference approach effectively isolates the racial heterogeneity of interest, and the results—particularly the earnings effect—are robust to multiple checks. The paper’s key limitation (few treated states) is acknowledged but not fully addressed; implementing wild cluster bootstrap inference and exploring heterogeneity by ban type would strengthen the analysis. The mechanism is plausible but requires further validation with microdata. With these improvements, the paper would make a strong contribution to the literature on non-competes, racial labor market inequality, and policy evaluation.
