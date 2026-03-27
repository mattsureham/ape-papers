# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-27T10:22:28.665978

---

### 1. Idea Fidelity

The paper adheres closely to the original idea manifest. It exploits the staggered transposition of the EU Single-Use Plastics Directive (SUP) across 27 member states, using the Callaway-Sant’Anna difference-in-differences (DiD) estimator to assess causal effects on packaging waste. The core data sources (Eurostat `env_waspac` for outcomes, CELLAR SPARQL for transposition dates) and identification strategy (staggered DiD with not-yet-treated controls) are faithfully implemented. The paper even expands on the manifest by incorporating robustness checks (e.g., leave-one-out analysis, placebo outcomes) and addressing potential threats to validity (e.g., COVID-19, anticipation effects). The substitution illusion framing—highlighting the mismatch between product-level bans and material-level waste—is a novel and insightful contribution that aligns with the manifest’s emphasis on policy targeting.

---

### 2. Summary

This paper provides the first causal evaluation of the EU’s Single-Use Plastics Directive (2019/904), exploiting staggered transposition across 27 member states to estimate its effects on packaging waste. Using Eurostat data and a staggered DiD design, the authors find a precisely estimated null effect on plastic packaging waste per capita (ATT = +0.94 kg/person, 95% CI [-0.95, 2.82]), alongside a marginally significant increase in paper/cardboard packaging. The results suggest that banning specific plastic products (e.g., straws, cutlery) merely shifts waste composition without reducing aggregate plastic waste, a phenomenon the authors term the "substitution illusion." The findings have direct implications for the EU’s successor Packaging and Packaging Waste Regulation (PPWR), advocating for material-level rather than product-level interventions.

---

### 3. Essential Points

1. **Clarify the targeting mismatch**:
   The paper’s central claim—that the SUP Directive failed to reduce plastic waste due to a targeting mismatch—rests on the assumption that banned items (straws, cutlery, etc.) constitute a small fraction of total plastic packaging. While this is plausible, the paper does not quantify the share of banned items in total plastic waste. **The authors must provide evidence** (e.g., from Eurostat, industry reports, or Comtrade HS codes) on the tonnage or market share of banned products relative to total plastic packaging. Without this, the "substitution illusion" argument lacks empirical grounding.

2. **Address potential spillovers or general equilibrium effects**:
   The paper assumes that the ban’s effects are confined to the treated material (plastic) and its substitutes (paper). However, the directive’s other provisions (e.g., extended producer responsibility, consumption targets) may have indirect effects on plastic waste beyond the banned items. **The authors should discuss** whether these provisions could confound the estimated null effect or whether their exclusion biases the results. If possible, they should test for spillovers (e.g., effects on non-banned plastic packaging categories).

3. **Improve the discussion of anticipation effects**:
   The event-study results show a significant pre-trend at event time -1 (+3.79 kg/person), which the authors attribute to anticipation. However, this could also reflect noise or unobserved confounders. **The authors must**:
   - Rule out alternative explanations (e.g., COVID-19 disruptions, pre-existing trends).
   - Discuss whether anticipation effects could bias the ATT (e.g., if firms adjusted packaging before transposition, the post-treatment effect may understate the true impact).
   - Consider excluding the -1 period or using a dynamic specification that accounts for anticipation.

---

### 4. Suggestions

#### **Strengthening the Empirical Strategy**
1. **Heterogeneous effects by treatment intensity**:
   The manifest mentions "strictness of implementation" (ban-only vs. ban+EPR+consumption targets) as a potential moderator. The paper could exploit this variation by interacting treatment with an index of implementation strictness (e.g., based on the number of provisions transposed or the stringency of national laws). This would test whether the null effect holds uniformly or varies with policy ambition.

2. **Alternative comparison groups**:
   The paper uses not-yet-treated countries as controls, which is appropriate given universal eventual treatment. However, the authors could also:
   - Use non-EU countries (e.g., UK, Norway) as a placebo test, though data comparability may be an issue.
   - Compare outcomes for banned vs. non-banned plastic products (if product-level data are available).

3. **Dynamic effects and long-term trends**:
   The paper focuses on short-term effects (up to 3 years post-treatment). Given the directive’s long-term goals (e.g., 2025 evaluation), the authors should:
   - Extend the analysis to 2024 if data are available.
   - Discuss whether the null effect might reflect delayed compliance or enforcement lags.

#### **Data and Measurement**
4. **Validate the transposition dates**:
   The paper relies on CELLAR SPARQL for transposition dates, but enforcement may lag behind legal entry-into-force. The authors should:
   - Cross-check dates with national sources or the Commission’s transposition reports.
   - Test sensitivity to alternative coding (e.g., using enforcement dates instead of legal dates).

5. **Explore product-level data**:
   While the paper’s focus on material-level waste is justified, product-level data (e.g., Comtrade HS codes for banned items) could:
   - Quantify the share of banned products in total plastic waste (addressing the targeting mismatch).
   - Serve as a falsification test (e.g., if banned products decline but total plastic waste does not, this would support the substitution illusion).

6. **Address data limitations**:
   - Eurostat `env_waspac` data are self-reported by member states, which may introduce measurement error. The authors should discuss potential biases (e.g., underreporting, definitional changes) and their implications for inference.
   - The paper uses annual data, which may mask short-term adjustments. If higher-frequency data (e.g., quarterly) are available, the authors should explore them.

#### **Interpretation and Generalizability**
7. **Discuss external validity**:
   The paper’s findings are specific to the EU’s SUP Directive, but the "substitution illusion" may generalize to other product bans (e.g., plastic bag bans, microbead bans). The authors should:
   - Compare their results to studies of other plastic regulations (e.g., bag taxes, microbead bans).
   - Discuss whether the EU’s approach (product-level bans) is inherently flawed or whether context matters (e.g., market structure, consumer behavior).

8. **Clarify policy implications**:
   The paper argues that the PPWR’s material-level approach is superior to product-level bans. However, the PPWR also includes reuse quotas and reduction targets, which may interact with bans. The authors should:
   - Discuss whether the SUP Directive’s failure implies that product bans are ineffective or whether they should be combined with other instruments (e.g., taxes, reuse mandates).
   - Address potential trade-offs (e.g., paper substitutes may have higher carbon footprints).

9. **Improve the discussion of environmental trade-offs**:
   The paper notes that paper packaging is more resource-intensive than plastic, but it does not quantify the net environmental impact of the substitution. The authors should:
   - Cite lifecycle assessment (LCA) studies comparing plastic and paper packaging.
   - Discuss whether the directive’s environmental benefits (e.g., reduced marine litter) outweigh the costs of substitution.

#### **Presentation and Robustness**
10. **Enhance the event-study plot**:
    The paper describes the event-study results but does not include a figure. **The authors should add a plot** showing dynamic effects with 95% confidence intervals, including pre-trends and post-treatment coefficients. This would make the anticipation effects and null results more intuitive.

11. **Report standardized effect sizes**:
    The appendix includes standardized effect sizes (SDEs), but these should be integrated into the main text. The authors should:
    - Highlight that the SDE for plastic waste (0.092) is "moderate" but not statistically significant.
    - Discuss whether the SDE for paper packaging (0.067) is economically meaningful.

12. **Address multiple testing**:
    The paper tests multiple outcomes (plastic, paper, glass, metal, total waste). The authors should:
    - Adjust confidence intervals for multiple comparisons (e.g., using Bonferroni or false discovery rate corrections).
    - Clarify whether the marginally significant paper result (p = 0.10) survives such adjustments.

13. **Improve the robustness appendix**:
    The robustness checks (e.g., log outcomes, TWFE) are thorough but buried in the appendix. The authors should:
    - Move key robustness results (e.g., log outcomes, leave-one-out) to the main text.
    - Add a table comparing the main results to alternative estimators (e.g., Sun-Abraham, TWFE).

#### **Minor Suggestions**
14. **Clarify the abstract**:
    The abstract states that the directive "did not reduce plastic waste," but the results show a null effect, not a negative one. The authors should rephrase to avoid overstating the findings (e.g., "had no statistically significant effect on plastic waste").

15. **Discuss sample size**:
    The paper has 486 country-year observations, but the staggered design reduces effective sample size. The authors should:
    - Report the number of treated and control observations in each period.
    - Discuss power limitations (e.g., whether the study is powered to detect small effects).

16. **Improve the discussion of COVID-19**:
    The paper dismisses COVID-19 as a confounder because it affected all countries simultaneously. However, the pandemic may have interacted with transposition timing (e.g., countries transposing in 2020 may have faced different disruptions than those transposing in 2022). The authors should:
    - Test for heterogeneous effects by transposition year (e.g., 2020 vs. 2021 vs. 2022).
    - Discuss whether COVID-19 could have masked the directive’s effects (e.g., if reduced food-service activity offset plastic reductions).

17. **Cite relevant literature**:
    The paper could better situate its findings in the literature on:
    - Plastic bag taxes (e.g., Taylor and Villas-Boas 2016, Rivers et al. 2017).
    - Material substitution in environmental policy (e.g., Greenstone and Hanna 2014).
    - EU directive evaluation (e.g., Dechezleprêtre et al. 2022 on the EU ETS).

---

### **Conclusion**
This is a well-executed and policy-relevant paper that makes a genuine contribution to the literature on environmental regulation. The null finding is surprising and important, and the "substitution illusion" framing is insightful. With the three essential revisions (quantifying the targeting mismatch, addressing anticipation effects, and discussing spillovers), the paper would be suitable for publication in a journal like *AER: Insights*. The suggestions above are intended to strengthen the paper’s empirical grounding, robustness, and policy implications.
