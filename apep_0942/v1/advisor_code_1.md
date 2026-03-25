# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-25T15:43:08.137151

---

**Idea Fidelity**

The submitted paper is faithful to the manifest. It studies the Dominican Republic’s MIPYME set-aside mandate using the DGCP awards, processes, and supplier registries; it leverages the August 2020 administrative change and resultant cross-agency compliance variation; and it focuses on whether enforcement expands the supplier base or merely relabels incumbents. The agency-quarter panel, continuous treatment (ΔMIPYME), outcomes (unique suppliers, HHI, first-time winners, contract values), and supplier decomposition are all present. The paper adheres closely to the proposed research question and identification strategy, so I have no fidelity concerns.

**Summary**

This paper exploits the Dominican Republic’s sudden enforcement of a dormant 20% MIPYME procurement set-aside to assess whether compliance expands small-firm participation or primarily relabels incumbents. Using a generalized difference-in-differences with agency-quarter fixed effects and continuous treatment intensity, it finds that agencies that increased their MIPYME share most actually saw fewer unique suppliers, concentrated in large agencies, while the share of MIPYME-certified winners rose. A decomposition of awards shows that “relabeled” incumbents drove the gains, not genuinely new entrants.

**Essential Points**

1. **Causal Interpretation of Continuous Treatment.** The key identifying assumption is that pre‐post change in MIPYME share (ΔMIPYME) captures exogenous variation in enforcement intensity rather than agency decisions responding to unobserved shocks to supplier structure. Yet ΔMIPYME is mechanically influenced by the outcome (e.g., firms win more contracts and the share increases) and by agency-level shocks that could also affect supplier counts. The paper should more rigorously justify the exclusion restriction: why is the change in share orthogonal to contemporaneous shocks to outcomes? One approach would be to instrument ΔMIPYME with an exogenous proxy for enforcement pressure (e.g., assignment of oversight personnel, political alignment indicators, or pre-transition compliance signals). At minimum, further evidence is needed showing that agencies with large compliance shifts did not also experience demand-side shocks (e.g., budgetary surges or policy mandates) that could explain supplier dynamics.

2. **Mechanism Timing and Reverse Indicators.** The paper’s narrative is that enforcement after August 2020 induced certification by incumbent suppliers (“relabeling”) rather than entry. Yet the main specification interacts ΔMIPYME with a post‐period indicator that is itself defined after the enforcement change. If certification is endogenous to outcomes, it could reverse causally be driven by supplier outcomes (i.e., agencies that experienced declining supplier diversity could have pushed managerial attention toward certification). The paper should better demonstrate temporal ordering: did certification enrollments spike immediately after the transition (before supplier disappearance), and are relabeled firms’ certification dates plausibly exogenous to the outcomes? A more convincing strategy would track timing at a finer granularity (monthly) to show that certification precedes the supplier contraction, ruling out simultaneous responses.

3. **Interpretation of Supplier Decomposition.** The decomposition relies on matching awards to registry data and identifying “new” versus “relabeled” suppliers. However, the definitions hinge on firm creation dates or prior contracting, which might be noisy. For instance, a supplier might have contracted before but under a different identifier, or a “new” firm might be an existing entity undergoing reorganization. Without robustness to these classification errors, the conclusion—relabeled incumbents dominate—could be overstated. The authors should describe the matching quality (match rates, potential duplicates) and conduct sensitivity checks (e.g., require multiple pre-period awards to classify a “relabeled” firm, exclude firms with ambiguous creation dates) to ensure the decomposition is not driven by data artefacts.

If these issues cannot be resolved satisfactorily, the paper’s causal claims are weakened. However, they appear addressable without rejecting the paper outright.

**Suggestions**

1. **Strengthen the Identification Narrative.**  
   - Explicitly characterize the source of variation in compliance. For instance, did political pressure differ systematically by agency visibility or political alignment with the new administration? If so, why would those characteristics not simultaneously affect supplier outcomes? Incorporating agency-level controls for political alignment (e.g., whether the agency head was appointed by the new president) or budget changes during the transition could help.  
   - Consider an instrumental variables approach: use pre-determined proxies for compliance pressure (e.g., agencies with higher media visibility, agencies subject to incumbent-level audits) to instrument ΔMIPYME. This would address concerns about endogeneity of the treatment intensity.  
   - Alternatively, reframe ΔMIPYME as a first-stage outcome of an exogenous “enforcement push” and estimate a two-stage model where the second stage uses predicted ΔMIPYME. Documenting the magnitude and plausibility of the push will make the narrative more tractable.

2. **Further Examine Timing and Dynamics.**  
   - Move beyond the binary pre/post indicator by estimating event-time coefficients at quarterly (or monthly) frequency around the August 2020 transition. This would demonstrate whether the supplier contraction occurs simultaneously with or after the certification surge.  
   - Plot the evolution of certification rates (new MIPYME certifications per quarter) alongside supplier counts and ΔMIPYME per agency. This visual will help readers understand the dynamic interplay and support the relabeling story.  
   - Explore whether agencies with sudden spikes in ΔMIPYME experienced immediate reductions in suppliers, or whether the effect lagged (consistent with incumbents taking time to certify). This would bolster the claim that certification choices drive supplier outcomes rather than vice versa.

3. **Address Measurement and Sample Selection.**  
   - Provide detailed matching statistics: what fraction of awards could not be linked to the supplier registry, and how might this affect the decomposition? Are missing matches concentrated in certain agencies or periods?  
   - Assess whether ΔMIPYME is correlated with sample attrition (e.g., agencies dropping out of the sample due to missing data). Such correlations could bias the results if high-response agencies are also the ones with complete data.  
   - Explore alternative normalization for outcomes. The log unique suppliers is sensitive to small counts; consider a Poisson or negative binomial estimator, or report results in levels with controls for total procurement volume.  
   - Since the treatment is measured at the agency level but awards/responses can vary by contract size, consider weighting outcomes by contract value to see if the effects persist. Large contracts might be more prone to relabeling because incumbents target them, so value-weighted outcomes could reveal additional nuance.

4. **Clarify the Mechanism.**  
   - The decomposition currently divides firms into four categories, but the policy relevance hinges on whether new firms face barriers. Consider augmenting the analysis with a profile of relabeled incumbents versus new MIPYMEs (size, location, sector). Are relabeled firms systematically larger or more connected?  
   - Investigate whether relabeled firms disproportionately win larger contracts or specific procurement modalities (works vs. goods). This would help assess whether the certification premium is sector-specific and whether the mandate merely reshuffles money within certain modalities.  
   - Examine whether the relabeling effect persisted beyond the initial enforcement surge—do high compliance agencies continue to rely on the same relabeled firms, or do new entrants eventually appear? A longer horizon could reveal whether relabeling is a short-run adjustment or a durable equilibrium.

5. **Robustness to Alternative Definitions.**  
   - Define treatment intensity using other metrics (e.g., change in MIPYME-directed contract value share, or count of MIPYME processes) and compare results.  
   - Run the main specification on a narrower sample (e.g., only competitive bidding processes) to check whether the effect is driven by procurement modalities that are easier to relabel.  
   - Test whether the effect holds when excluding the top and bottom deciles of ΔMIPYME to ensure that extreme agencies are not driving the findings. The leave-one-out analysis helps, but trimming the sample provides an alternative lens.

6. **Policy Implications and External Validity.**  
   - Discuss how these findings relate to enforcement intensity in other contexts. For example, is relabeling more likely when certification costs are moderate and incumbent firms can easily obtain them?  
   - Suggest practical remedies for policymakers (e.g., targeted training for new firms, stricter eligibility verification, periodic rotation of certified suppliers) and clarify how the data could monitor compliance beyond the nominal share (e.g., track entry rates or adjust the mandate based on the share of first-time suppliers).

By addressing the causal concerns, fleshing out the relabeling mechanism, and expanding robustness checks, the paper will more convincingly demonstrate that procurement set-aside mandates can fall victim to compliance without inclusion.
