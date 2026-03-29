# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-29T20:59:37.223492

---

**Idea Fidelity**

The paper aligns well with the original manifest. The twin-study design exploiting continuation/divisional parent–child pairs within the same art unit is fully implemented, and the key datasets (PatEx continuity tables and office actions) are used as described. The identification strategy—quasi-random reassignment to different examiners conditional on art-unit × filing-year fixed effects—is the centerpiece of both the discordance analysis and the leniency regressions, just as in the manifest. The focus on examiner leniency and small-entity heterogeneity, the balance tests, and the emphasis on the regulatory-lottery framing all track precisely with the original idea. No major element of the stated research question, data source, or identification strategy is missing.

---

**Summary**

This paper exploits 97,922 continuation/divisional application pairs that were reassigned to different examiners within the same USPTO art unit to estimate how examiner identity affects patent outcomes. Reassignment raises parent-child discordance by 7.7 percentage points once art-unit × year fixed effects and parent outcomes are absorbed, and an examiner’s leave-one-out leniency predicts grant rates with an economically large slope (≈11.4 pp per standard deviation). Small entities face significantly greater excess discordance and are more sensitive to examiner leniency, suggesting the random draw of an examiner exacerbates inequality in patent access.

---

**Essential Points**

1. **Identification of Reassignment as Random within Art-Unit × Year**  
   The paper rests on the critical assumption that examiner reassignment within an art unit is as-good-as-random given art-unit×year FE. Beyond the stated balance tests (which report statistically significant but “economically small” correlations), more evidence is needed that there are no systematic differences in the continuations rerouted to other examiners. For example, are certain sub-technology areas, assignee types, or claim volumes more likely to be reassigned? If so, the discordance estimate may partly capture latent differences in case difficulty rather than examiner randomness. A stronger empirical validation—such as showing that observable predictors of difficulty (claims count, number of citations, specification length, or even prior art counts) do not predict reassignment conditional on AU×year—would greatly bolster the credibility of the key identification assumption.

2. **Interpretation of Leniency Effects and Potential Selection**  
   The leniency regressions isolate reassigned pairs, but the discussion in the limitations section acknowledges that assignment may not be perfectly random. If certain classes of continuations (e.g., more complex or contentious ones) are more likely to be reassigned to veteran examiners, the leave-one-out leniency measure could still be correlated with unobserved difficulty even after controlling for parent outcome and AU×year FE. This concern is especially salient because the leniency coefficient is interpreted as capturing examiner identity effects holding invention quality fixed. Without additional robustness—such as exploiting variation in examiner availability over time (e.g., examiners going on/off leave) or using within-examiner over-time fluctuations in leniency as an instrument—there remains the possibility of upward bias. The authors should address whether the 11.4 pp effect persists when conditioning on richer measures of application complexity or when using finer-grained parental controls (e.g., number of claims amended, number of office actions).

3. **Causal Claim about Small-Entity Penalty**  
   The triple-difference estimate shows that small entities have 3.2 pp additional excess discordance, but the mechanism needs clarification. Is the interaction driven by small entities being systematically reassigned to harsher examiners, by receiving poorer representation when arguing a continuation, or by being unable to refile? The current specification treats the differential as part of the regulatory lottery, but it could arise from non-random differences in prosecution strategy (e.g., large firms routinely request interviews or use appeal strategies more effectively). To substantiate the claim that examiner identity disproportionately harms small entities, the authors should explore whether small-entity continuations differ in observable features after reassignment and whether the Leniency × Small-Entity effect survives adding interactions between small-entity status and observable proxies for prosecution effort.

If more than three critical issues are necessary, the paper may be premature for publication in its current form.

---

**Suggestions**

1. **Enhance Balance and Randomization Evidence**  
   - Provide additional balance tests along dimensions that plausibly proxy for application difficulty (e.g., number of independent/dependent claims, claim length, number of examiner citations, applicant history). These can be run conditional on AU×year FE and should include both mean differences and variance comparisons between reassigned and non-reassigned continuations.  
   - If possible, document the administrative reassignment process in more detail (e.g., whether reassignment is driven by examiner retirements, case aging thresholds, or targeted workload balancing). Official documentation or interviews could strengthen the plausibility of randomness.  
   - Consider an IV-style test where reassignment is instrumented by exogenous features (e.g., when an examiner goes on leave, more reassignments occur). Such temporal shocks could validate the assumption that reassignment is unrelated to case quality.

2. **Extend Leniency Specification**  
   - Include examiner fixed effects (or random effects) to absorb time-invariant heterogeneity while exploiting within-examiner variation in day-to-day leniency.  
   - Explore heterogeneous leniency effects by tenure, workload, or previous grant rates, to demonstrate that the effect is not driven by a small set of extreme examiners.  
   - Report the first-stage or the direct relationship between the examiner’s recent grant rate (e.g., past quarter) and reassignment probability. If current-period leniency better predicts outcomes than career leniency, it would reduce concerns about attenuation bias due to measurement error.

3. **Clarify Policy and Economic Magnitude**  
   - The discussion cites Farre-Mensa et al. to translate the examination lottery into employment effects. It would be helpful to provide a table or figure that shows how many grants are shifted due to reassignment, the implied employment effects, and the share attributable to small entities. This quantification would ground the policy discussion.  
   - Since the analysis stops in 2015, consider testing whether the results hold in a more recent window (up to the latest available year). Even a smaller out-of-sample check could reassure that the lottery persists post-2015, given ongoing USPTO reforms.

4. **Strengthen Small-Entity Analysis**  
   - Introduce proxies for prosecutorial effort (e.g., attorney count, number of office actions) to see if the small-entity penalty persists after controlling for them.  
   - Investigate whether large entities are more likely to request interviews or use appeal routes when reassigned to lenient examiners, which could mechanically produce the differential.  
   - Consider decomposing the small-entity penalty across technology centers. If the interaction is concentrated in certain fields, that may suggest targeted reforms.

5. **Robustness to Alternative Discordance Measures**  
   - Instead of binary discordance, consider measuring the difference as the child issuance probability minus the parent’s. That is, use a continuous measure capturing the deviation from the parent's outcome probability.  
   - Explore whether examiner reassignment affects downstream measures such as time-to-grant, number of office actions, or claim scope, to illustrate that inconsistency extends beyond the binary grant/abandon outcome.

6. **Presentation Improvements**  
   - Clarify that the 97,922 reassigned pairs are a subset of the 702,490 same-art-unit pairs; the abstract currently suggests all pairs are reassigned.  
   - In Table 3 (leniency), explicitly annotate that column (3) interacts reassignment with leniency, as this is crucial for interpretation.  
   - Provide a figure showing the distribution of discordance across technology centers or time, which would make the “technology variation” anecdote more tangible.

These suggestions aim to reinforce the causal claims, enrich the policy narrative, and deepen the reader’s understanding of how examiner identity translates into real-world inequalities.
