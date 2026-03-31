# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant C)

**Model:** moonshotai/kimi-k2.5
**Variant:** C
**Date:** 2026-03-31T02:52:37.543961

---

 **Review of "The Conviction Lottery: Judge Assignment, Drug Classification, and Mass Incarceration in Brazil"**

---

### 1. Idea Fidelity

The paper delivers a coherent but narrower version of the original manifest. The manifest proposed a full judge-leniency IV design estimating causal effects of trafficking classification on *incarceration length, recidivism, and formal employment*. The delivered paper correctly pivots to a reduced-form documentation of the "conviction lottery" itself, acknowledging that causal claims require linking to RAIS data (unavailable here) and that the "bundle" problem (conflation of conviction with pretrial detention and case management) invalidates the exclusion restriction for downstream outcomes. This is an honest and defensible scope reduction, though the paper would benefit from explicitly tabulating the bundled margins (detention, duration) that motivate the reduced-form framing. The DataJud source and institutional setting match the manifest exactly, and the 87,757-case sample is reasonably close to the projected scale (though restricted to multi-vara comarcas, yielding 47,820 analysis cases).

---

### 2. Summary

This paper exploits the electronic lottery (*sorteio*) that randomly assigns drug trafficking cases to criminal courtrooms (*varas*) in São Paulo to document massive arbitrariness in conviction outcomes. The authors construct a leave-one-out vara leniency instrument and demonstrate a 37.5 percentage-point spread (P90–P10) in conviction rates across varas—rising to 47.1pp within the São Paulo Central courthouse alone—establishing that Brazil’s vague drug classification standards (Lei 11.343/2006) generate a conviction lottery of profound magnitude.

---

### 3. Essential Points

**1. The "Conviction" Outcome Conflates Provisional and Final Dispositions.**  
The paper defines conviction as the presence of a *Procedência* movement (code 219) in the first-instance record. However, Brazilian criminal procedure allows for extensive appeals, and first-instance convictions are frequently reversed. The paper mentions *Trânsito em julgado* (code 848) as the finality marker but does not verify whether the vara-level dispersion persists for final convictions. If high-conviction varas differ systematically in appeal rates or reversal probabilities—perhaps because they produce lower-quality evidentiary records—the documented lottery may overstate or understate the arbitrariness in ultimate sanctions. **Requirement:** Report results using *Trânsito em julgado* as the primary outcome, or at minimum demonstrate that the P90–P10 spread is similar for final dispositions.

**2. Missing First-Stage Regression Evidence.**  
The paper claims the leave-one-out instrument "strongly predicts individual conviction" and references a "strong first stage," but no table reports the first-stage coefficient, standard error, or F-statistic. The reader cannot assess instrument strength, the slope of the leniency-conviction relationship, or whether the first stage is driven by outliers. **Requirement:** Include a table regressing individual conviction on the LOO instrument (with assignment pool × year FE), reporting the coefficient, clustered SE, and Kleibergen-Paap F-statistic. Given that some specifications rely on only 31 varas (Central), report wild cluster bootstrap p-values to account for few clusters.

**3. The "Bundle" Claim Lacks Empirical Substantiation.**  
The authors invoke Hull (2025) to justify a reduced-form approach, arguing that varas bundle conviction with pretrial detention and case duration, violating the exclusion restriction. This is theoretically compelling but empirically unsubstantiated—the paper does not tabulate reduced-form effects on detention (code 12140) or duration despite mentioning them as secondary outcomes. Without showing that lenient varas also detain less or process faster, the bundling justification remains speculative. **Requirement:** Report reduced-form regressions of pretrial detention and case duration on vara leniency to validate that the exclusion restriction fails because varas differ on these margins, not solely because of conviction propensity.

---

### 4. Suggestions

**A. Strengthen Balance Tests and Address Individual-Level Selection.**  
Table 4 reports vara-level correlations (N=200) between leniency and filing month/sorteio rate. This is ecological and underpowered. Construct individual-level balance tables regressing pre-determined characteristics (filing month indicators, case format indicators) on quartiles of the leniency instrument, controlling for assignment-pool × year FE. If case-level drug quantities or defendant demographics are available in DataJud (even partially), test balance on those covariates to bolster the claim that the *sorteio* randomizes defendant severity.

**B. Quantify the Incarceration Consequences.**  
The abstract and introduction emphasize the 5-year minimum sentence cliff, but the paper never converts the conviction lottery into expected incarceration time. Using the first-stage coefficient and the statutory minimum sentence, compute the Local Average Treatment Effect (LATE) or, given the bundling concerns, provide bounds on the expected months of incarceration induced by assignment to a P90 versus P10 vara. This bridges the gap between the procedural lottery and the 920,000 prisoner statistic cited in the abstract.

**C. Robustness to Alternative Sample Definitions and Many-Instrument Bias.**  
The split-sample jackknife (Table 5, column 5) is mentioned in the text but not detailed. Report the first-stage coefficient from each half-sample explicitly to demonstrate stability. Additionally, the LOO instrument with 200 varas may induce many-instrument bias (Hull 2025). Compute the split-sample IV estimator (Angrist & Pischke 2009) as a robustness check: use varas in half-sample A to construct the instrument for cases in half-sample B, and vice versa. This addresses the mechanical correlation between case outcomes and the LOO mean.

**D. Heterogeneity by Comarca Characteristics.**  
The within-Central spread (47.1pp) is remarkably large compared to smaller comarcas. Explore whether the variance in vara outcomes is larger in high-volume urban comarcas (where judges specialize less) versus smaller jurisdictions. This speaks to whether the lottery is worse in precisely the jurisdictions processing the most defendants.

**E. Documentation of Missing Data.**  
Table 1 reports pretrial detention rates as "—" (missing). Clarify whether this is a data limitation (API restrictions) or a cleaning decision. If detention data are available but noisy, report the measurement error explicitly. Similarly, discuss the attrition rate from the full 87,757 cases to the 47,820 multi-vara sample—are single-vara comarcas systematically different (rural, smaller caseloads)?

**F. Policy Counterfactual Simulation.**  
To directly inform the RE 635659 deliberation mentioned in the introduction, simulate the effect of imposing a bright-line quantity threshold. If quantity data are unavailable, calibrate a simple model assuming that a threshold would eliminate the discretionary margin for X% of cases, and calculate the implied reduction in the conviction-rate variance. This transforms the descriptive evidence into a concrete policy metric.

**G. Precision of Language on Causality.**  
The abstract states that defendants face conviction probabilities "based on which courtroom number appears on a screen" and that the system "produces substantive injustice." While compelling, these claims imply causal effects of assignment on outcomes. Given the reduced-form approach, temper the language slightly to emphasize that the paper documents *association* between assignment and conviction conditional on randomization, reserving "causal" for the LATE interpretation if/when exclusion restriction evidence is provided. Alternatively, frame the descriptive variance as a measure of "horizontal equity" (unequal treatment of equals) rather than causal impact, which sidesteps the bundling issue entirely while maintaining policy relevance.

**H. Clustering and Inference.**  
With 200 varas, conventional cluster-robust inference is acceptable, but for the Central-only specification (31 varas), rely on wild cluster bootstrap (Cameron, Gelbach & Miller 2008) or report p-values from a permutation test randomly reallocating vara assignments within comarcas. This addresses concerns that the Central results are driven by a few outlier judges.
