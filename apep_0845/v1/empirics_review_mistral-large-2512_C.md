# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-03-24T15:34:59.494916

---

### 1. Idea Fidelity
The paper adheres closely to the original idea manifest. It exploits cross-country variation in the number of regulated professions as a continuous treatment intensity to estimate the effect of the 2013 EU Professional Qualifications Directive on overqualification rates among EU mobile professionals. The identification strategy (continuous DiD), data sources (Eurostat LFS), and research question (whether cutting red tape moves workers) are all faithfully executed. The paper even includes the suggested placebo test (non-EU foreign workers) and robustness checks (wild cluster bootstrap, randomization inference), which strengthen the credibility of the null result.

One minor deviation: the manifest mentions 27 countries, but the paper uses 24 due to data limitations. This is understandable but should be flagged more prominently in the abstract and introduction.

---

### 2. Summary
This paper evaluates the 2013 EU Professional Qualifications Directive, which aimed to reduce administrative barriers to cross-border professional mobility. Using a continuous difference-in-differences design with country-level variation in the number of regulated professions as treatment intensity, the authors find no evidence that the reform reduced overqualification among EU mobile professionals. The null result is robust to multiple inference methods and placebo tests, suggesting that cultural and linguistic frictions dominate administrative barriers in limiting professional mobility.

---

### 3. Essential Points
**1. Interpretation of the Null Result**
The paper’s central claim—that the reform "produced no detectable reduction in overqualification"—is well-supported by the data, but the discussion overreaches in concluding that administrative barriers are irrelevant. The null result could reflect:
- **Implementation failure**: The European Court of Auditors (ECA) found the reform was "used sparsely and inconsistently." If the treatment (streamlined recognition) was not actually delivered, the null is unsurprising. The paper should explicitly acknowledge this as a key limitation and discuss whether the regulated professions count is a valid proxy for *actual* procedural reform.
- **Measurement error**: The outcome (overqualification gap) is noisy and may not capture the reform’s intended effects. For example, the reform might have increased *mobility* (more professionals moving) without reducing *overqualification* (those who move still end up in mismatched jobs). The paper should test secondary outcomes (e.g., immigration flows, employment in regulated professions) to distinguish between these mechanisms.

**2. Parallel Trends Assumption**
The event study (\Cref{tab:eventstudy}) shows pre-trends are noisy, with some coefficients (e.g., $t = -4$) statistically significant. While the authors argue these dissipate near the reform, the pattern suggests differential trends in overqualification gaps across high- and low-regulation countries. This undermines the parallel trends assumption. The paper should:
- Show the event study graphically (not just in a table) to better assess pre-trends.
- Report a formal test for pre-trend differences (e.g., joint significance of pre-2016 coefficients).
- Consider alternative specifications (e.g., including country-specific linear trends) to address this concern.

**3. Power and Effect Size**
The paper notes it can rule out effects larger than 2.6 percentage points per standard deviation of regulatory intensity (18% of the pre-reform gap). This is a meaningful bound, but the discussion should clarify whether this is economically significant. For example:
- If the reform only affected a subset of professions (e.g., those covered by the European Professional Card), the aggregate effect might be diluted. The paper should explore heterogeneity by profession or regulation intensity.
- The standardized effect sizes (\Cref{tab:sde}) are small to moderate, but the paper does not discuss whether these are plausible given the reform’s scope. For instance, if the EPC was used in only 16,000 cases (as per the ECA), the aggregate effect would likely be undetectable in country-level data.

---

### 4. Suggestions

#### **Conceptual and Theoretical Improvements**
1. **Clarify the Mechanism**
   The paper argues that cultural/linguistic frictions dominate administrative barriers, but this is speculative. Alternative explanations include:
   - **Employer discrimination**: Foreign credentials may be systematically undervalued, regardless of recognition.
   - **Self-selection**: The reform might have induced *more* mobile professionals to move, but these new migrants could be lower-skilled (e.g., those previously deterred by red tape), offsetting any reduction in overqualification.
   - **Partial equilibrium effects**: If the reform increased labor supply in regulated professions, wages might have fallen, leading to *more* overqualification (e.g., professionals taking jobs below their skill level to avoid unemployment).
   The paper should discuss these alternatives and suggest ways to test them (e.g., using profession-level data or wage outcomes).

2. **Engage with the Occupational Licensing Literature**
   The paper cites Kleiner and Blair & Chung but does not engage with their findings on the magnitude of licensing effects. For example:
   - Blair & Chung (2019) find that licensing increases wages by 8–15% and reduces labor supply by 17–27%. If the EU reform had similar effects, the overqualification gap should have narrowed by ~2–4 percentage points (assuming a linear relationship). The paper’s null result suggests either (a) the reform was ineffective, or (b) cross-border frictions are an order of magnitude larger than within-country licensing barriers. This comparison should be made explicit.

3. **Discuss External Validity**
   The EU is a unique case due to its deep integration (free movement, single market). The paper should discuss whether the results generalize to other contexts (e.g., US interstate licensing, ASEAN MRAs). For example:
   - In the US, licensing barriers are lower (e.g., mutual recognition for some professions), but cultural/linguistic frictions are less salient. Would the same null result hold?
   - In ASEAN, MRAs exist but are rarely used due to lack of enforcement. The EU’s experience might inform whether harmonization alone is sufficient.

#### **Empirical Improvements**
4. **Address Data Limitations**
   - **Missing countries**: The paper excludes 3 countries (11% of the EU) due to missing data. This could bias results if the excluded countries are systematically different (e.g., newer member states with lower regulation). The paper should:
     - List the excluded countries and discuss potential bias.
     - Consider imputation or bounding exercises to assess sensitivity.
   - **Outcome measurement**: Overqualification is a crude proxy for labor market integration. The paper should:
     - Test alternative outcomes (e.g., employment in regulated professions, wages, or occupational mismatch using ISCO codes).
     - Use individual-level LFS data (if available) to control for compositional changes (e.g., education, age, or profession of migrants).

5. **Improve the Event Study**
   - The event study (\Cref{tab:eventstudy}) is hard to interpret without a graph. The paper should:
     - Plot the coefficients with 95% confidence intervals, using $t = -1$ as the reference year.
     - Include a vertical line at the transposition deadline (2016) and adoption date (2013) to assess anticipation effects.
   - The coefficients for $t = 0$ and $t = +1$ are negative and significant, which contradicts the main result. The paper should reconcile this or acknowledge the inconsistency.

6. **Explore Heterogeneity**
   - The reform’s bite varied by profession (e.g., the European Professional Card covered only 3 professions). The paper should:
     - Test whether effects are larger for professions covered by the EPC or with common training frameworks.
     - Use profession-level data (if available) to estimate effects for specific occupations.
   - The paper could also explore heterogeneity by:
     - Country pairs (e.g., effects might be larger for migration from low- to high-regulation countries).
     - Language barriers (e.g., effects might be smaller for migrants moving to non-native-language countries).

7. **Robustness Checks**
   - **Alternative treatment definitions**: The regulated professions count is a noisy proxy for treatment intensity. The paper should:
     - Use alternative measures (e.g., the number of recognition applications per country, or the share of professions covered by the EPC).
     - Test a binary treatment (e.g., above/below median regulation) to assess sensitivity to functional form.
   - **Alternative inference methods**: The paper uses wild cluster bootstrap and randomization inference, which is appropriate given the small number of clusters. However:
     - The randomization inference should permute *country-year* treatment assignments (not just country-level), as the treatment is time-varying.
     - The paper should report the distribution of placebo coefficients from the randomization inference to assess how unusual the main result is.

8. **Power Analysis**
   - The paper notes it can rule out effects larger than 2.6 percentage points, but this is based on the *pre-reform* standard deviation of the outcome. The paper should:
     - Report the *post-reform* standard deviation, as this may have changed due to the reform or other trends.
     - Calculate the minimum detectable effect (MDE) for the EU-foreign gap (which has fewer observations) and discuss whether the study is adequately powered for this subgroup.

#### **Writing and Presentation**
9. **Clarify the Abstract and Introduction**
   - The abstract states the overqualification gap is "14 percentage points wider" for foreign workers, but the text later reports a pre-reform gap of 13.3 percentage points. This inconsistency should be fixed.
   - The introduction frames the reform as a test of whether "cutting red tape moves workers," but the outcome (overqualification) is only indirectly related to mobility. The paper should clarify that the reform could have increased mobility *without* reducing overqualification (e.g., if new migrants were lower-skilled).

10. **Improve Table and Figure Readability**
    - **Tables**: The main results table (\Cref{tab:main}) is dense. The paper should:
      - Highlight the key coefficients (e.g., bold the all-foreign gap result).
      - Move the placebo test (non-EU gap) to a separate table or figure for clarity.
    - **Figures**: The paper lacks visualizations. It should include:
      - A map of regulated professions by country to show treatment variation.
      - A graph of the overqualification gap over time, split by high/low regulation countries.
      - The event study plot (as suggested above).

11. **Discuss Policy Implications More Carefully**
    - The paper concludes that administrative reform is "necessary but not sufficient," but this is not directly supported by the null result. The reform might have been *unnecessary* (if cultural frictions dominate) or *insufficient* (if it was poorly implemented). The paper should:
      - Distinguish between these interpretations.
      - Discuss whether the reform’s failure reflects a design flaw (e.g., lack of enforcement) or a fundamental limit of administrative harmonization.

---

### Final Assessment
This is a well-executed paper with a clear research question, credible identification strategy, and robust null result. The authors have done an admirable job addressing potential threats to validity (e.g., placebo tests, alternative inference methods). However, the paper’s interpretation of the null result is overly confident, and several empirical improvements (e.g., event study visualization, heterogeneity analysis) would strengthen its contribution.

**Recommendation**: Revise and resubmit. The core result is publishable, but the paper needs to:
1. Better address the parallel trends assumption.
2. Explore alternative mechanisms and heterogeneity.
3. Improve the presentation of results (e.g., graphs, clearer tables).
4. Tone down the causal language around cultural frictions, which are not directly tested.
