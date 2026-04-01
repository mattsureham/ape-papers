# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-04-01T22:55:11.870440

---

**Idea Fidelity**

The submitted paper hews closely to the original idea manifest. It interrogates whether WWI conscription accelerated structural transformation by forcing farm boys into non-agricultural occupations, leverages the linked IPUMS MLP 1910–1920 data, and centers identification on the nativity-based draft exemption interacting with draft-age eligibility. The implementation respects the proposed treatment definition, outcome measures (farm exit, occupational income score, migration), and heterogeneity (agricultural counties, race). The paper’s decision to downplay the age-based RD in favor of the nativity DiD is explained transparently and aligns with the manifest’s emphasis on the nativity comparison as the workhorse design. No key element of the original design appears omitted.

**Summary**

The paper studies whether the Selective Service Act of 1917 precipitated a measurable farm-to-factory transition by comparing draft-exposed native-born men to draft-exempt foreign-born men using linked 1910–1920 census data. The core finding is that draft exposure raised farm exit rates by 1.6 pp and occupational income scores by 5.3 points (≈0.43 SD), with amplified effects in high-agriculture counties and among Black men, while leaving inter-county migration unchanged. The author interprets these results as evidence that forced disruption (“inertia break”) coaxed men out of agricultural attachment and into higher-paying occupations.

**Essential Points**

1. **Selection into the Nativity Comparison:** The key identifying assumption is that, absent the draft, nativity-based occupational transitions would be parallel across draft-eligible and ineligible cohorts. Yet the summary statistics reveal substantial baseline differences between native- and foreign-born men (e.g., 44.8% vs. 23.1% farm residence; different occscore trajectories). The paper relies on a simple linear age control and state fixed effects but does not demonstrate that the DiD control group convincingly captures the counterfactual for native-born men. The authors should present evidence (e.g., pre-trends or placebo DiDs using earlier censuses such as 1900–1910, or by estimating whether the same nativity × age interaction predicts outcomes for cohorts too young to ever face the draft) to buttress parallel trends. Without this validation, concerns of differential life-cycle mobility or immigrant selection remain and threaten identification.

2. **Potential Contamination from Naturalization and Treatment Intensity:** The treatment is defined as draft eligibility combined with citizen status, but the draft also applied to “declarant aliens” who had filed for naturalization, and the 1918 registrations gradually lifted some nativity restrictions. If a nontrivial fraction of foreign-born men naturalized or otherwise entered the draft pool during follow-up, the contrast between native and foreign-born men attenuates and complicates interpretation. The authors should quantify how many foreign-born men in the sample were likely declarant aliens or subsequently drafted, and ideally restrict the control group to individuals whose draft-exempt status is more certain (e.g., those who remained non-declarant immigrants) or correct for such contamination via bounding exercises.

3. **Mechanism and Exposure Measurement:** The paper assumes draft exposure is the operative shock, yet no individual-level indicator of actual induction is observed—only eligibility. The assumption that native-born men were uniformly drafted while foreign-born men were not is too coarse, particularly since only ~2.8 million of ~10 million registrants were inducted. If eligible native-born men differ systematically (e.g., health, farm size, remoteness) from the average foreign-born counterpart, the treatment may proxy for other forces. The authors should exploit variation in induction probability (e.g., enrollment type, draft board priorities, or county-level call-up rates) to show that results scale with likely treatment intensity and not merely eligibility. Failing that, the interpretation as the causal effect of military service on occupational transformation remains tenuous.

**Suggestions**

- **Strengthen Parallel Trends Evidence:** Incorporate checks using the linked 1900–1910 MLP panel (mentioned in the manifest as available) to estimate the nativity × age interaction on outcomes prior to 1917. If the interaction is insignificant before the draft, this bolsters the DiD assumption. Alternatively, use cohorts too old to be affected (e.g., men aged 25–29 in 1910) as an additional placebo group to assess whether the same nativity-age differential occurs absent treatment.

- **Control for Potential Confounders More Fully:** While age and state fixed effects are included, nativity groups may differ along literacy, marital status, or regional settlement patterns that evolve differently with age. Adding pre-treatment controls and their interactions with draft eligibility (or estimating the DiD within narrower cells, such as county-by-nativity strata) could reduce bias. The manifest references a sample of 2,865 counties—leveraging county-by-age fixed effects or allowing differential linear trends could help.

- **Explore Dose-Response and Local Treatment Variation:** If some counties had higher induction rates (e.g., due to local demand for soldiers or draft board aggressiveness), interact native-born status with county-level induction intensity to see if the occupational shifts scale with draft pressure. This would also speak to the mechanism: stronger effects where service was more likely would lend credibility to the “military service disrupted inertia” story.

- **Clarify the Role of Migration:** The null finding on inter-county migration is intriguing but requires nuance. Were drafted men prevented from migrating post-service due to reintegration policies or economic constraints? Presenting descriptive statistics on urbanization shares or linking to city-level employment opportunities could contextualize the null. Additionally, consider city/rural heterogeneity in outcomes to test whether the occupational gains occurred in rural areas or nearby cities.

- **Address Treatment Timing:** The draft unfolded over multiple registrations, yet the paper treats all age-eligible native-born men through 1920 as homogeneously treated. Discuss how exposure timing (e.g., early registrants versus late ones) might affect outcomes, and whether the 1920 census captures a follow-up period short enough to isolate the draft’s effect from other economic shocks (e.g., post-war recession). If possible, limit the sample to men who were 21–23 in 1917 to minimize variation in exposure duration.

- **Better Communicate External Validity Limits:** The inertia-break mechanism is compelling, but emphasize that the comparison is between native-born and foreign-born men, not drafted versus non-drafted natives. Clarify what subset of the population is represented and how generalizable the findings are to broader structural transformation debates. This will temper overstatement while keeping the policy intuition intact.

- **Pre-Analysis Plan or Multiple Hypothesis Adjustment:** Given the multiple outcomes and heterogeneity tests, mention (briefly) how statistical inference accounts for multiple comparisons, or justify why the selected outcomes are of primary interest. The manifest indicates a large data exercise—given that, even small effect sizes can be significant. Explicitly state whether outcomes were pre-specified or if the design was exploratory.

- **Data Access Transparency:** The manifest noted Azure access; the paper should briefly describe how other researchers could replicate the study (e.g., by referencing IPUMS access procedures or sharing code). This is particularly important for novel linked census analyses.

Implementing these suggestions will sharpen the paper’s empirical claim that the WWI draft constituted an “inertia break” for agricultural labor, and will reassure readers that the observed occupational gains indeed stem from forced draft exposure rather than confounding nativity-age dynamics.
