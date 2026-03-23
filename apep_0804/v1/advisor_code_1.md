# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-23T12:37:19.092537

---

**Idea Fidelity**

The paper closely follows the original manifest. It exploits the staggered adoption of autism insurance mandates across 46 states (2001–2015) using ACS PUMS 2008–2019 data, constructs a triple-difference design comparing mothers of children with and without cognitive difficulty, and pursues maternal employment, hours, and earnings as outcomes. The DREM proxy for ASD, household linkage via SERIALNO, and the focus on treatment generosity heterogeneity and subgroup analyses are all faithfully retained. The paper does not explicitly explore generosity heterogeneity (caps or age limits) beyond brief mentions, which was flagged as a potential source of richer variation in the manifest, but this omission does not undermine the core identification strategy.

---

**Summary**

The paper investigates whether state autism insurance mandates—evenly phased in across 46 states—unlock maternal labor supply by reducing out-of-pocket costs for intensive ASD therapies. Using a triple-difference design (state × time × child disability status) on ACS microdata linked within households, it finds precisely estimated null effects on employment, hours worked, labor force participation, and wages for mothers of children with cognitive difficulty. Flat pre-trends, subgroup breakdowns, and a physical-disability placebo bolster the claim that the caregiving employment penalty does not respond to insurance coverage alone.

---

**Essential Points**

1. **Measurement of the treated group (DREM) likely includes many children without ASD, but the paper lacks a tight calibration of how large this dilution is and how it affects external validity.** Because DREM captures a broad set of cognitive difficulties, the treated group may mix autism with other conditions unaffected by the mandate, potentially biasing the estimate toward zero beyond the “attenuation” noted in passing. The authors should quantify the likely share of DREM = 1 children who truly have ASD (drawing on existing prevalence estimates or linked administrative data) and, if possible, conduct a bounding exercise or sensitivity analysis (e.g., via simulation) to assess whether the null remains interpretable for the autism population of interest.

2. **The triple-difference hinges critically on the assumption that, absent the mandate, the employment gap between DREM and non-DREM mothers would have evolved similarly across states, but the paper provides limited evidence beyond the event study.** Concerns remain about other simultaneous policy changes (e.g., Medicaid waivers, special education expansions, ESSA implementation) that might differentially affect mothers of children with disabilities in adopter versus non-adopter states. More falsification tests are needed—for instance, using other household outcomes (e.g., fathers’ employment, siblings’ outcomes) or alternative control groups (e.g., mothers of children with other disabilities unaffected by the mandate) to demonstrate that the DREM gap is the only one flat around adoption. Additionally, exploring whether states that adopted mandates early differ systematically in pre-trends and including leads of the treatment in the main specification would strengthen the credibility of the identifying assumption.

3. **Policy relevance depends on whether mandates meaningfully changed the effective price faced by the mothers in the sample, but the paper cannot observe mandate take-up or whether mothers had plans subject to the mandate.** Many families are covered by self-insured employer plans exempt from state mandates (ERISA) or enrolled in public insurance, so the sample of mothers with private, in-scope coverage is ambiguous. The authors should provide evidence (e.g., from the ACS or CPS on insurance coverage type) that the treated group indeed faces the mandate and consider bounding exercises that restrict the sample to mothers with private, non-ERISA plans or with income/high enough to plausibly have employer-sponsored coverage. Without establishing that the policy reached the target population, the null could simply reflect a policy that never applied to these mothers.

---

**Suggestions**

- **Clarify and quantify the mapping from DREM to ASD.** Provide references or auxiliary data on the positive predictive value of ACS cognitive difficulty for an autism diagnosis, perhaps citing medical or school-based screening comparisons. Alternatively, consider constructing a tighter “ASD proxy” by combining cognitive difficulty with indicators such as receiving special education services (e.g., EDHSP) or parental reports of developmental delay, which would reduce contamination from unrelated conditions. Present robustness checks restricting the treated group to children with multiple indicators of developmental impairment.

- **Strengthen the placebo and falsification strategy.** In addition to the DPHY placebo, consider using other parental outcomes (e.g., paternal employment, siblings’ school attendance) or outcomes that should not change with a mandate (e.g., maternal employment for households with children aged 0–4, where ABA services are less likely) to rule out spurious state-level time shocks. Present event studies stratified by mandate generosity (e.g., capped versus uncapped) to show that even the “strongest” mandates do not produce effects, which helps interpret the null.

- **Diagnose policy penetration and heterogeneity in exposure.** Use ACS insurance variables (e.g., INSURANCE, PUBCOV, EMPSTAT) to construct a sample of mothers most likely affected by the mandate—e.g., those reporting private insurance, particularly employer-based, who lack Medicaid/CHIP. Alternatively, combine the mandate data with data on self-insured plan prevalence (from the Kaiser Family Foundation employer survey) to weight states by policy reach. Compare results when limiting the control group to mothers in never-treated states with similar insurance coverage profiles to rule out compositional confounding.

- **Explore mechanism proxies.** Since therapy usage cannot be observed, examine intermediate outcomes that signal whether mandates relaxed the financial constraint—e.g., medical spending (if available), home health aide hours, or school service receipt. If such proxies are unavailable in the ACS, discuss in more detail why the null is not simply a story of non-take-up: for example, link to external studies showing mandates led to increased ABA spending or therapy receipt, and explain why such gains did not materialize in maternal employment. This helps make the case for the alternative mechanism (complementarity of time).

- **Discuss statistical power and minimum detectable effects more explicitly.** While the confidence interval rules out effects larger than ~1 percentage point, translating that into economic significance for different subpopulations (e.g., unmarried mothers) would contextualize the null. Consider computing minimum detectable effects for the key subgroups and clarifying whether the precision is sufficient to rule out policy-relevant changes.

- **Document treatment timing exclusions more transparently.** The sample excludes states with mandates before 2008 because of missing pre-trends, but these states include Indiana, South Carolina, and Texas. Explain how excluding them affects generalizability and robustness (e.g., would including them with placebo pre-periods change results?). Also, clarify whether states that adopted mandates late (e.g., 2014–2015) are well covered in the post-treatment period or whether limited post observations blunt the design; the event study nominally goes out only five years, but explicitly discuss whether attenuation due to late treatment matters.

- **Consider complementary specification checks.** The DDD specification is saturated, but presenting more parsimonious specifications (e.g., two-way fixed effects with state × year and group × year) and showing that estimates remain null would reassure readers that the result is not sensitive to overfitting or weak variation. Additionally, report a simple DiD comparing states that adopted early versus late on aggregated aggregates (e.g., state-level maternal employment gaps) to show the null persists at higher aggregation levels.

These refinements would not only enhance the credibility of the null finding but also help interpret its policy implications more clearly.
