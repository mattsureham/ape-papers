# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-13T17:49:17.090228

---

### 1. Idea Fidelity

The paper largely adheres to the original idea manifest but deviates in one critical dimension: it focuses **exclusively on property values** (HM Land Registry data) and does not analyze **firm dynamics** (Companies House data), which was a core component of the proposed research question. The manifest explicitly framed the paper as examining "how environmental traffic charges affect firm entry, exit, and property values at zone boundaries," with firm registration data as a primary outcome. The omission of firm-level analysis weakens the paper's contribution relative to its original ambition, as the multi-cutoff spatial RDD design was intended to exploit heterogeneity in charge classes to study both housing and business outcomes.

The paper otherwise faithfully executes the proposed identification strategy (difference-in-discontinuities at CAZ boundaries) and uses the specified data sources (Land Registry, postcodes.io, OSM boundaries). The dose-response analysis across charge classes (B, C, D) is well-aligned with the manifest’s emphasis on regulatory stringency.

---

### 2. Summary

This paper exploits the staggered introduction of Clean Air Zones (CAZs) in seven UK cities (2021–2023) to estimate the causal effect of emission charges on residential property values at zone boundaries. Using a difference-in-discontinuities design on 50,158 transactions, the authors find that Class C zones (charging commercial vehicles but exempting private cars) generate a 6.9% property premium, while Class D zones (which additionally charge private cars) show no net effect. The results suggest that the amenity benefits of cleaner air are fully offset by direct transport costs when residents bear the burden of compliance.

---

### 3. Essential Points

The authors must address the following **three critical issues** to strengthen the paper’s credibility:

#### (1) **Pre-trend reversal and identification**
The pre-period placebo test (Table 4) reveals a statistically significant *negative* discontinuity (-5.7%) one year before CAZ implementation, implying that inside-boundary properties were *declining* relative to outside properties prior to treatment. The authors interpret this as strengthening identification, arguing that the post-treatment effect represents a "reversal" of a pre-existing trend. However, this interpretation is problematic:
   - The diff-in-disc design assumes that, absent treatment, the *gap* at the boundary would remain constant. A pre-trend reversal violates this assumption and suggests that the boundary itself may have been evolving dynamically (e.g., due to anticipation, sorting, or other confounders).
   - The authors must rule out alternative explanations for the pre-trend, such as:
     - **Anticipation effects**: If buyers/sellers anticipated the CAZ, prices may have adjusted before implementation. Test for effects in the announcement-to-launch window.
     - **Sorting**: If lower-income households or businesses were relocating *into* the CAZ boundary (e.g., due to lower pre-CAZ prices), this could explain the negative pre-trend. The authors should examine pre-trends in property characteristics (e.g., share of flats, tenure) or buyer demographics (if available).
     - **Boundary-specific shocks**: Were there other policies (e.g., road expansions, zoning changes) or economic shocks (e.g., post-pandemic recovery) that differentially affected inside vs. outside properties?
   - **Recommendation**: The authors should explicitly model the pre-trend (e.g., by interacting `Inside` with a linear time trend) and show that the post-treatment effect is robust to controlling for it. If the pre-trend is not addressed, the diff-in-disc estimate may conflate CAZ effects with pre-existing dynamics.

#### (2) **Heterogeneity by charge class: sample size and power**
The dose-response analysis by charge class (Table 3) is the paper’s most novel contribution, but the results hinge on small samples:
   - **Class B (Portsmouth)**: Only 7,964 transactions (16% of the sample). The point estimate (0.020) is imprecise (SE = 0.027), and the authors cannot rule out meaningful effects.
   - **Class D (Birmingham, Bristol, Sheffield)**: 24,388 transactions, but the pooled estimate (0.010, SE = 0.030) is noisy. The authors conclude that "the transport cost penalty exactly offsets the amenity gain," but this is based on a null result with wide confidence intervals. The power to detect small effects (e.g., 2–3%) may be limited.
   - **Recommendation**:
     - Report power calculations for each charge class to assess whether the sample sizes are sufficient to detect policy-relevant effects.
     - Pool Class B and C zones (both exempt private cars) to test whether the amenity effect is robust to excluding Class D. If the pooled estimate is significant, it would strengthen the claim that exempting private cars drives the premium.
     - Discuss whether the lack of precision for Class B/D is a limitation or if the point estimates are economically meaningful (e.g., the Class D estimate is close to zero, which may support the offsetting-channels story).

#### (3) **Boundary measurement error and functional form**
The paper uses circular approximations for CAZ boundaries where OpenStreetMap polygons are unavailable. This introduces measurement error in the running variable (distance to boundary), which can bias RDD estimates. The authors acknowledge this but do not quantify its impact.
   - **Recommendation**:
     - Validate the circular approximations by comparing them to official boundary maps (e.g., from local authority websites) for at least one city (e.g., Birmingham). Report the share of properties misclassified due to approximation.
     - Test sensitivity to alternative boundary definitions (e.g., using Voronoi diagrams or buffering official maps).
     - The authors should also justify the choice of local linear polynomials. Given the sharp discontinuities at ring roads, higher-order polynomials or nonparametric methods (e.g., Calonico-Cattaneo-Titiunik) may better capture the relationship between distance and prices.

---

### 4. Suggestions

#### (1) **Strengthen the theoretical framework**
- The paper’s key insight—that Class C zones generate a premium while Class D zones do not—is compelling but would benefit from a clearer theoretical model. The authors should:
  - Formalize the two offsetting channels (amenity benefits vs. transport costs) in a simple hedonic pricing framework. For example, derive how the net effect depends on the share of car-owning households, the elasticity of demand for clean air, and the compliance cost.
  - Discuss why Class B zones (which charge only HGVs/buses) show no significant effect. Is this due to limited air quality improvements (since fewer vehicles are targeted) or low statistical power?
- The discussion of external validity (Section 5.2) should address whether the UK’s ANPR enforcement (which is stricter than German LEZs) drives the results. Would the same asymmetry between Class C and D emerge in cities with lower compliance?

#### (2) **Improve robustness checks**
- **Falsification tests**:
  - Test for discontinuities at "fake" boundaries (e.g., 500m inside/outside the true boundary) to rule out spatial sorting unrelated to the CAZ.
  - Test for effects on property characteristics (e.g., share of flats, new builds) to assess whether the CAZ induced sorting.
- **Alternative specifications**:
  - Estimate event-study models to assess dynamic effects (e.g., whether the premium emerges immediately or grows over time).
  - Use a donut-hole specification with varying inner radii (e.g., 25m, 50m, 100m) to test sensitivity to boundary measurement error.
- **Heterogeneity analysis**:
  - Examine whether effects vary by property type (e.g., flats vs. detached homes) or neighborhood income (e.g., using LSOA-level deprivation indices). This could reveal whether the premium is concentrated among wealthier households or urban renters.
  - Test for heterogeneity by city size or pre-CAZ pollution levels. For example, do Class C effects scale with baseline NO₂ concentrations?

#### (3) **Address omitted outcomes**
- The manifest proposed analyzing **firm dynamics** (entry/exit) using Companies House data, but this is entirely absent from the paper. While the property value analysis is valuable, the omission weakens the paper’s contribution. The authors should either:
  - Add a brief analysis of firm outcomes (even if exploratory) to the appendix, or
  - Acknowledge the omission as a limitation and explain why the property value results are sufficient for a standalone contribution.
- If firm data are included, the authors should test whether the property premium in Class C zones is driven by improved commercial activity (e.g., retail turnover) or purely residential amenities.

#### (4) **Clarify policy implications**
- The paper’s policy takeaway—that Class C is the "Goldilocks" charge class—is provocative but requires nuance:
  - The authors should discuss whether Class C zones achieve sufficient air quality improvements. For example, do NO₂ reductions in Class C zones match those in Class D? If not, the trade-off between air quality and property values may not be worth it.
  - The £14,300 premium for Class C is large, but the authors should contextualize it relative to the cost of compliance (e.g., the annualized cost of upgrading a non-compliant vehicle). Is the premium justified by the air quality gains?
  - The paper focuses on short-run effects. Discuss whether the premium is likely to persist or fade as vehicle fleets turn over and compliance costs decline.

#### (5) **Data and replication**
- The paper relies on circular approximations for CAZ boundaries. To improve transparency:
  - Release the exact boundary definitions used (e.g., as shapefiles or coordinates) in the replication package.
  - Document the share of properties affected by circular approximations and the potential bias from misclassification.
- The authors should clarify how they handle transactions with missing postcodes or geocoding failures. Report the share of transactions dropped due to missing data.

#### (6) **Presentation and tables**
- **Table 2 (summary statistics)**:
  - Add a column showing the *difference* between inside and outside properties (e.g., mean price inside minus outside) to highlight pre-existing gaps.
  - Include a row for NO₂ concentrations (from EEA data) to show pre-CAZ pollution levels.
- **Table 3 (charge class heterogeneity)**:
  - Report the number of transactions *per city* within each class to highlight sample size imbalances (e.g., Bath has only 3,726 transactions, while Bristol has 11,293).
  - Add a column for the *combined* Class B+C estimate to test whether exempting private cars drives the premium.
- **Figure suggestions**:
  - Add a map of CAZ boundaries (even a simple schematic) to help readers visualize the spatial discontinuity.
  - Plot the pre- and post-treatment discontinuities (e.g., using binned means) to visually demonstrate the reversal in the gap.

#### (7) **Discussion of limitations**
- The paper’s limitations section (5.3) is thorough but could be expanded:
  - **Long-run effects**: The authors note that the analysis captures short-run capitalization. Discuss whether the premium is likely to grow (as air quality improves) or fade (as compliance costs decline).
  - **General equilibrium effects**: Could the property premium in Class C zones lead to gentrification or displacement? The authors should discuss whether the premium reflects a transfer from renters to landlords or a net welfare gain.
  - **Commercial property**: The paper focuses on residential transactions. Discuss whether commercial property values (e.g., retail rents) might respond differently to CAZs.

#### (8) **Broader context**
- The paper’s introduction frames CAZs as a European-wide policy, but the analysis is UK-specific. To strengthen external validity:
  - Compare the UK’s charge classes to those in other countries (e.g., Germany’s LEZs, which use windshield stickers and exempt private cars).
  - Discuss whether the UK’s ANPR enforcement (which is stricter than in many European cities) drives the results. Would the same asymmetry between Class C and D emerge in cities with lower compliance?
- The authors should cite recent work on LEZs in other contexts, such as:
  - \citet{percoco2013} on Milan’s congestion charge and property values.
  - \citet{de2021} on the economic effects of LEZs in Germany.

---

### Final Assessment

This is a **strong and policy-relevant paper** that makes a novel contribution to the literature on environmental regulation and property values. The difference-in-discontinuities design is well-suited to the research question, and the dose-response analysis across charge classes is compelling. However, the paper’s credibility hinges on addressing the **pre-trend reversal**, **sample size limitations for charge classes**, and **boundary measurement error**. If these issues are resolved, the paper would be a strong candidate for publication in *AER: Insights*.

**Recommendation**: Revise and resubmit, with particular attention to the three essential points above. The authors should also consider adding a brief analysis of firm dynamics (even in the appendix) to align with the original manifest.
