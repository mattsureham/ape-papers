# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant C)

**Model:** deepseek/deepseek-v3.2
**Variant:** C
**Date:** 2026-03-22T23:05:20.240535

---

Here is my review as a seasoned econometrician.

### **1. Idea Fidelity**

The paper **deviates significantly from the original, more ambitious research design** outlined in the manifest. The core identification strategy has been fundamentally altered, weakening the causal claim.

*   **Original Plan:** A **spatial RDD** using the *geographic distance* from a school or residence centroid to the nearest estrato boundary polygon as the continuous running variable. This is a strong, modern design that compares units arbitrarily close to either side of a sharp geographic treatment threshold.
*   **Implemented Design:** A **discrete boundary design** using self-reported estrato (1-6) as a discrete running variable, with municipality fixed effects. This is essentially a series of cross-sectional comparisons between adjacent estratos *within the same municipality*. While it leverages the ordinal nature of estrato, it is not a regression discontinuity design in the conventional sense because there is no continuous forcing variable. The assumption is now that, conditional on municipality, assignment to estrato *k* vs. *k+1* is as-good-as-random. This is a much stronger and less credible assumption than the local continuity assumption of a spatial RDD.

The paper also does not deliver on several key elements promised in the manifest:
*   **Data:** Uses 1.2M student records from 5 cities, not the 7.1M national records with geocoded manzanas.
*   **Mechanism Tests:** The promised decomposition into school quality, peer composition, and household inputs is only partially addressed with a basic public/private school split and household controls. There is no analysis of teacher credentials, bilingual status, or peer composition using the linked data.
*   **Spatial Elements:** The "spatial" aspect is absent. There is no map, no discussion of bandwidth selection, no donut RDD as described (the donut test in the paper is about school composition, not geographic distance).

The paper pursues the core research question but with a weaker, simpler identification strategy than originally proposed.

### **2. Summary**

This paper provides novel descriptive evidence that Colombia's estrato system is associated with large, discontinuous differences in student test scores at administrative boundaries. The gradient is steepest where subsidy differences are largest and disappears at a boundary with no fiscal difference, suggesting the subsidy regime drives residential sorting that impacts education. However, the causal interpretation of these "boundary jumps" is compromised by the research design.

### **3. Essential Points**

The authors must address these three critical issues before the paper can be considered for publication.

**1. The identification strategy is mischaracterized and flawed.** Labeling the analysis a "Regression Discontinuity Design" is incorrect and misleading. There is no continuous running variable driving treatment assignment; treatment is determined by a discrete, self-reported estrato category. The appropriate framework is a **conditional independence assumption** (CIA) model within municipalities, where the key identifying assumption is that all relevant confounding variables vary smoothly *across estrato levels* within a city. The significant covariate imbalances in **Table 4** directly violate this assumption for important observables (assets, parental education). The authors must:
    *   Re-frame the entire empirical strategy section, dropping the RDD terminology and graphical apparatus (which is absent anyway).
    *   Explicitly state and defend the much stronger CIA assumption. Discuss the threat that unobservable family characteristics (e.g., parental motivation, social networks) likely also jump at these boundaries, as the observables do.
    *   Consider alternative approaches, such as using the geographic RDD originally planned (if data permits) or employing a boundary discontinuity design with geographic controls (e.g., latitude/longitude polynomials within municipality) to better approximate local comparisons.

**2. Standard errors are almost certainly underestimated.** Clustering at the municipality level is inappropriate when the treatment variation (estrato boundaries) and likely correlated errors (school quality, local policies) exist at a sub-municipality level. With only 5 cities (municipalities) in the sample, the effective number of clusters is far too small for reliable inference, making the t-distribution approximation poor. The reported standard errors are therefore not credible.
    *   The authors must cluster at a more granular level, such as school or a geographic unit like *comuna* or *localidad*. They should also report Conley spatial HAC standard errors or cluster by boundary segment to account for spatial correlation. They must show their main results are robust to these alternative, more conservative error structures.

**3. The magnitude and interpretation of the 5|6 "placebo" result is not convincing.** A null result at the 5|6 boundary is central to the argument that subsidies, not labels, drive the effect. However, the sample size for this comparison is very small (N=31,543 vs. >400,000 for other boundaries), leading to imprecise estimates (SE = 5.58). The point estimate of -3.5 is not statistically distinguishable from effect sizes of 7-13 points seen at other boundaries. Furthermore, the composition of Estratos 5 and 6 is qualitatively different (smaller, wealthier, more private school attendance), making the "placebo" not directly comparable.
    *   The authors must formally test for a *difference* in coefficients between the 5|6 boundary and the subsidized boundaries (e.g., 3|4). A failure to reject equality is not evidence of a null effect at 5|6.
    *   They should discuss whether the lack of a label effect is surprising given the sociological literature on stigma. Could the small sample and unique characteristics of the highest estratos be masking a real effect?

### **4. Suggestions**

**Empirical Analysis & Presentation:**
*   **Replicate Main Tables with Appropriate SEs:** The first priority is re-running all specifications with school-level or spatial clustering and reproducing **Tables 2, 4, and 5**. This may change inferences, particularly for the 4|5 boundary.
*   **Strengthen Mechanism Analysis:** The private vs. public school split is a start, but leverage the data more. As planned in the manifest, create a school-level dataset and test for discontinuities in observable school quality measures (e.g., teacher qualifications, infrastructure) at boundaries. Run a horse-race regression: after including household controls (`X_i`), add school fixed effects. If the boundary dummies become insignificant, it suggests the effect operates entirely through school sorting.
*   **Validate the "Forcing Variable":** If using self-reported estrato, demonstrate its high correlation with the official block-level estrato from the GIS data for a subsample where both are available. Discuss and quantify potential misreporting.
*   **Improve Transparency on Sample Construction:** The manifest mentions 7.1M records, the paper uses 1.2M. The reader needs a clear flow chart or section detailing the exact exclusion criteria (which cities? why only 5? what years? handling of missing data).
*   **Graphical Evidence:** Even without a continuous running variable, the paper would benefit from binned scatterplots showing mean test scores by estrato within municipalities, or plots of outcomes against a socioeconomic index, marking the estrato boundaries.

**Interpretation & Discussion:**
*   **Temper Causal Language:** Throughout the paper, replace definitive causal claims ("identifies", "causal effect") with more accurate language ("is associated with", "suggests", "consistent with").
*   **Policy Implications:** The discussion of phasing out the estrato system is too simplistic. The results suggest subsidies cause sorting. A reform that removes the subsidy but leaves the *label* (e.g., moving to a means-tested system that still publicly categorizes neighborhoods) might not address any potential label effects that could persist. Also, discuss the counterfactual: if the subsidy were removed, would high-performing families in estrato 3 move to estrato 4, or would they find other ways to sort (e.g., into private schools)?
*   **Generalizability:** Discuss the external validity of studying only the five largest cities. Are boundaries sharper and sorting stronger in dense, large metropolises compared to smaller towns?

**Writing & Structure:**
*   **Abstract & Introduction:** The abstract and introduction should immediately clarify the actual research design (comparison of adjacent estratos within cities) and not imply a geographic RDD was executed.
*   **Theory of Change:** Early in the paper, include a clear conceptual framework diagram outlining the hypothesized channels: Subsidy -> Residential Sorting -> (School Quality, Peer Effects, Household Investment) -> Test Scores.
*   **Limitations Section:** Expand significantly. Acknowledge the design shift from spatial RDD, the threat of unobserved confounding, the sample selection, and the measurement issues frankly.

**Conclusion:**
The paper identifies a compelling and policy-relevant gradient. With the current design, it is a **strong descriptive paper** that cleverly uses institutional variation to bound potential effects. To make a **causal claim**, the authors must either successfully implement the original spatial RDD design or provide much more robust evidence that their within-municipality, across-estrato comparisons are conditionally random. Addressing the standard error issue is non-negotiable. The project has immense potential, but the execution in this draft does not meet the high bar for causal identification set by the original idea.
