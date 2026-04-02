# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant B)

**Model:** deepseek/deepseek-v3.2
**Variant:** B
**Date:** 2026-04-02T21:15:58.254805

---

**Referee Report: "The Harvest Dividend: Marine Protected Areas and the Selective Recovery of Commercially Targeted Kelp Forest Fish"**

**1. Idea Fidelity**

The paper deviates significantly from the original research plan outlined in the Idea Manifest, which constitutes a major weakness. The manifest proposed a study leveraging the **staggered implementation** of the entire California MPA network (124 MPAs across three waves from 2007-2012) and the broad **Reef Check California (RCCA)** citizen-science monitoring dataset (>110 sites). The stated goal was to apply modern staggered DiD/TWFE methods to this large-scale, publicly funded panel.

In contrast, the submitted paper:
*   **Narrows the Scope:** It analyzes only the **2007 Central Coast wave**, ignoring the 2012 South and North Coast waves. This eliminates the staggered variation central to the proposed identification strategy and vastly reduces the treatment group from ~60 MPA sites to just 2.
*   **Changes the Primary Data Source:** It abandons the proposed RCCA data in favor of the **Santa Barbara Coastal LTER (SBC LTER)** dataset, which covers only 9 mainland sites in a single region. While high-quality, this dataset is not the "gold-standard monitoring data that CA taxpayers funded specifically for this purpose" as described in the manifest. The promised analysis of the RCCA's structured, statewide, paired-site design is absent.
*   **Simplifies the Empirical Strategy:** The promised "Staggered Spatial DiD" with heterogeneous treatment effects by MPA type (SMR vs. SMCA) and spillover tests is replaced by a standard, two-period DiD and a species-level triple-difference on a very small sample. The paper does not engage with the complexities of staggered adoption or modern estimators (e.g., Callaway and Sant'Anna, Sun and Abraham).
*   **Omits Key Proposed Elements:** There is no analysis of dose-response by MPA strictness, placebo tests on pelagic fish, spillover, or recreational fishing welfare (NOAA MRIP).

In summary, the paper pursues a related but distinct idea—a deep, causal case study of two MPAs using a high-frequency scientific dataset—rather than the broader, policy-evaluative study of the statewide MPA network using citizen-science data as originally proposed. This represents a fundamental shift in contribution, from assessing a large-scale policy rollout to providing a detailed ecological mechanism test on a tiny subset of that policy.

**2. Summary**

This paper provides novel quasi-experimental evidence that the establishment of two Marine Protected Areas (MPAs) in the Central California kelp forests led not to an increase in overall fish density, but to a selective "harvest dividend": a significant increase in the density of commercially targeted fish species and in species richness, coupled with a decrease in non-targeted species. The key methodological contribution is the use of a species-level triple-difference design to isolate the effect of reduced fishing mortality from confounding environmental trends.

**3. Essential Points**

The paper must address the following critical issues, which currently undermine its causal claims and policy relevance:

1.  **Severe Data and Inference Limitations:** The analysis rests on **2 treated sites** (Naples and Isla Vista reefs). The site-level DiD is therefore underpowered and highly vulnerable to idiosyncratic shocks at either site, as confirmed by the rejected pre-trend test (F=14.07, p=0.000). The permutation inference and triple-difference are necessary bandaids but do not remedy the fundamental problem: the estimated effects are driven by a maximum of two treated clusters. The authors must explicitly acknowledge that their design cannot reliably estimate an *average treatment effect* of the Central Coast MLPA, but rather provides a *case study* of two specific reefs. All causal language must be tempered accordingly, and the external validity of the "harvest dividend" conclusion must be critically discussed.

2.  **Unsubstantiated Causal Mechanism and Interpretations:** The central interpretation—that the negative effect on non-targeted species is due to competitive displacement or predation by recovering targeted species—is presented as the primary explanation but is not tested. This is a strong ecological claim. The paper must either:
    *   **Provide direct evidence:** Test for correlations between increases in key predators (e.g., sheephead) and declines in their known prey within sites over time.
    *   **Formally consider and rule out alternative mechanisms:** For example, could the MPAs have altered diver behavior or site usage in ways that affect counts of non-targeted (often smaller, cryptic) species? Could changes in kelp forest structure (e.g., from urchin barrens) coincident with MPA establishment differentially affect habitat for non-targeted species? A discussion of these possibilities is essential.
    *   **Tone down the mechanistic conclusion** to reflect that the triple-difference identifies a differential effect consistent with a harvest mechanism, but does not pin down the ecological cause of the decline in non-targeted species.

3.  **Lack of Policy Context and Connection to Original Question:** The paper fails to connect its findings to the larger policy question posed in the manifest: "inform whether MLPA should be replicated." Focusing on two sites from the first wave (2007) ignores the learning and potential design improvements in later waves (2012). A discussion is needed: Do these results suggest the MLPA's design was effective for targeted species? Does the lack of aggregate density increase imply a policy failure or a misunderstood metric? What do the results from these two, potentially unrepresentative, sites imply for the network of 124 MPAs? Without this, the paper feels like an isolated ecological analysis rather than a policy evaluation.

**4. Suggestions**

*   **Reframe Contribution:** The abstract and introduction should clearly frame the paper as an intensive **mechanism-testing case study** using a strong identification strategy (the triple-difference) on a unique long-term dataset, rather than an evaluation of the California MLPA network. Highlight the value of the long (18-year) panel and the species-level design for uncovering compositional shifts missed by aggregate analyses.
*   **Expand Data Discussion:**
    *   Justify the choice of SBC LTER over RCCA/PISCO. Acknowledge the trade-off: higher data quality/frequency vs. vastly reduced sample and spatial scope.
    *   In Table 1, show summary statistics separately for the two treated sites (Naples vs. Isla Vista). Their differing regulations (SMCA vs. no-take SMR) likely matter, and the leave-one-out analysis suggests heterogeneous effects.
    *   Discuss the representativeness of these nine Santa Barbara Channel sites for the broader California kelp forest ecosystem.
*   **Strengthen Empirical Presentation:**
    *   The event study graph (described in Table 2) should be a figure, not a table. Visually displaying the pre-trend violation and the noisy, delayed post-treatment path is crucial.
    *   For the triple-difference (Table 3), report the full set of two-way interactions (MPA x Post, Post x Targeted, MPA x Targeted) to aid interpretation. The note says "MPA x Post" is "NA"—clarify if it is omitted due to collinearity or absorbed by fixed effects.
    *   Given the few clusters, report wild cluster bootstrap or randomization inference p-values alongside the clustered SEs for all main specifications as a standard robustness check.
*   **Deepen the Discussion:**
    *   Discuss the ecological implications of the "harvest dividend" more thoroughly. Is the decline in non-targeted species ecologically concerning? Does it represent a return to a more "natural" state?
    *   Reconcile the finding of **no aggregate density effect** with the meta-analytic literature (e.g., Lester et al. 2009) which often finds biomass increases. Is this a question of timescale (18 years should be sufficient), ecosystem (kelp forest vs. coral reef), or MPA design?
    *   Discuss policy implications more nuancedly. If the goal is biodiversity (richness increased) and recovery of fished species (targeted density increased), the policy could be deemed a success even without aggregate gains. If the goal is overall fishery production or ecosystem biomass, it may be less so.
*   **Technical Corrections:**
    *   The sample size description is confusing. The text says 9 sites x ~25 years = 228 site-years, but Table 1 footnotes sum to 228 (15+36+51+126). This is correct, but the earlier mention of "67 sites" in Table 4 notes appears to be an error (likely 67 species?).
    *   In the abstract, "0.059 log points" is an unusual unit; consider expressing as a percentage ("approximately 6%").
    *   Ensure all citations in the bibliography are complete and match the text.

**Overall Assessment:** The paper contains a clever identification strategy (species-level triple-difference) applied to a valuable long-term dataset. It identifies a provocative and potentially important result—the selective "harvest dividend." However, in its current form, it is not a credible evaluation of the California MLPA's causal effects due to the extreme small-sample problem and the shift away from the planned, broader analysis. The paper can be substantially improved by reframing its contribution as a mechanistic case study, rigorously addressing the inferential limitations, and more deeply exploring the ecological and policy implications of its core finding.
