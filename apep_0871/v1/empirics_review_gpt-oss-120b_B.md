# V1 Empirics Check — openai/gpt-oss-120b (Variant B)

**Model:** openai/gpt-oss-120b
**Variant:** B
**Date:** 2026-03-24T21:06:32.112554

---

**1. Idea Fidelity**  
The manuscript follows the original idea closely. It exploits the 50‑employee threshold created by the EU NIS2 Directive and the staggered national transposition dates to identify the causal impact of the regulation on firms’ cybersecurity investments. The author uses the Eurostat ICT‑security survey (waves 2019, 2022, 2024) and retains the same three size classes (10‑49, 50‑249, ≥250) that were specified in the manifest. The identification strategy – a size‑based DiD plus a “DDD” that interacts the DiD with a transposition‑by‑deadline indicator – is exactly what the manifest called for. All key elements (policy description, data source, treatment and control groups, parallel‑trend test, dosage test with large firms) are present. No substantial deviation from the proposed design is observed.

**2. Summary**  
The paper provides the first causal evidence on the EU NIS2 cybersecurity directive by using the 50‑employee eligibility cut‑off and cross‑country variation in the timing of national transposition. In a pooled DiD the regulation shows no aggregate effect on medium‑sized firms’ security‑practice index, but a triple‑difference reveals a 3–4‑percentage‑point increase in the six countries that transposed the law by the October‑2024 deadline. The gain is driven by both technical measures and staff‑training, whereas in non‑transposed countries firms only adopt the cheapest, most auditable measure (training), suggesting that enforcement, not mere announcement, drives substantive investment.

**3. Essential Points**  

| Issue | Why it matters | What to do |
|------|----------------|------------|
| **a) Limited statistical power & inference** | The sample consists of only 27 country‑size cells per wave (162 observations). With clustering at the country level, standard errors are large and the DiD estimate is imprecise. The DDD result (β≈3.35, SE=1.19) is only modestly significant (p≈0.009) and would not survive a more conservative inference method (e.g., wild‑cluster bootstrap). | Re‑estimate using a randomization or wild‑cluster bootstrap (Cameron, Gelbach & Miller, 2008) and report confidence intervals. Consider aggregating at the sector‑level (if feasible) or applying a Bayesian shrinkage estimator to improve precision. |
| **b) Possible contamination of the control group (spillovers)** | NIS2’s supply‑chain obligations may force larger firms to require security practices from their smaller partners, biasing the control group downward (i.e., attenuating the treatment effect). The paper mentions this only qualitatively. | Test for spillovers by (i) examining whether small firms in transposed countries show any upward move in the training/compliance indices; (ii) using a “far‑from‑threshold” control group (e.g., firms with 5‑9 employees, if data are available) and comparing results; (iii) adding an interaction with a supply‑chain intensity variable (e.g., share of exports) to see if spillovers differ. |
| **c) Lack of robustness to alternative definitions of the treatment window** | The treatment is defined as “post‑2024” (the survey wave after the transposition deadline). However, firms may have started compliance earlier (anticipation) or later (delayed implementation). The binary post indicator conflates heterogeneous timing across countries. | Exploit the exact month of transposition where available (e.g., Belgium in Oct 2024, Croatia in Jul 2024) and construct a continuous “months since transposition” variable. Estimate event‑study style leads/lags to verify that the effect materialises only after the law becomes enforceable. |
| **d) Outcome measurement concerns** | The security index aggregates a heterogeneous set of measures (some merely documentary). The headline effect could be driven by a single indicator (e.g., training). Moreover, the index is based on self‑reported percentages, which could be subject to reporting bias that differs across countries. | Provide (i) robustness using alternative aggregations (e.g., unweighted average, principal‑component index); (ii) a “strict‑technical” index that excludes purely documentary items; (iii) a falsification test using a non‑security outcome from the same survey (e.g., use of cloud services) to check for spurious correlation. |
| **e) External validity / relevance to actual cyber‑risk** | The paper cannot link the observed practice changes to actual breach outcomes, limiting policy relevance. | Discuss the possibility of linking to the Eurostat “ICT security incidents” dataset (isoc_cisce_ic) or to publicly reported breach counts, even at a country‑level, to see whether the observed practice gains correlate with fewer incidents. A modest correlation would strengthen the claim that the regulation improves real security. |

If any of these issues cannot be addressed satisfactorily, the contribution remains modest given the limited power and potential contamination.

**4. Suggestions**  

1. **Inference and Power**  
   *Implement robust inference*: Apply the wild‑cluster bootstrap (or the “cluster‑wild” method) with a sufficient number of replications (e.g., 10 000). Report both conventional cluster‑robust SEs and bootstrap p‑values. This will reassure readers that the DDD significance is not an artefact of the small‑N clustering.  
   *Power calculations*: Include a post‑hoc power analysis showing the minimum detectable effect size given the existing design. If the detectable effect is larger than the estimated point estimate, discuss the implications for interpretation.

2. **Event‑Study / Dynamic Effects**  
   *Lead‑lag analysis*: Rather than a single post dummy, estimate a set of leads (2019, 2022) and lags (2024, 2025 if a 2025 wave becomes available) to visualise the timing of the effect. This will also test the parallel‑trend assumption more rigorously and help to detect anticipation.  
   *Continuous timing*: If the exact month of transposition is known, construct a treatment intensity variable (months since transposition) and run a flexible dose‑response model (e.g., quadratic or spline) to see how quickly firms respond after the law becomes enforceable.

3. **Spillover / Contamination Checks**  
   *Alternative control groups*: Identify a “pure” control group that should be unaffected by supply‑chain obligations, such as firms in sectors with minimal upstream/downstream dependencies (e.g., pure‑service firms) or firms with 5‑9 employees if the survey includes them. Compare results to the baseline control (10‑49).  
   *Supply‑chain intensity*: Merge sector‑level data on the proportion of sales that are B2B versus B2C. Interact this with the treatment to see whether small firms that are heavily embedded in supply chains of medium firms exhibit any upward trend, indicating spillovers.

4. **Outcome Construction and Sensitivity**  
   *Alternative indices*: Compute a principal‑components–based security index (PC1) using the 15 measures; compare its treatment effect to the simple average. Also construct a “technical‑only” index that excludes compliance/documentation items, and a “training‑only” index. This will clarify whether the DDD effect is driven by substantive technical upgrades or merely documentation.  
   *Weighting*: Test robustness to weighting by the share of enterprises in each size class within a country (the survey reports percentages, but the underlying number of firms varies). Weighted regressions could better reflect the economic magnitude of changes.  
   *Reporting bias*: Use the “self‑assessment” variable that Eurostat sometimes provides (e.g., “confidence in data”) to control for systematic differences in reporting accuracy across countries.

5. **External Validity – Linking to Cyber‑Incidents**  
   *Aggregated breach data*: Obtain country‑level breach statistics (e.g., ENISA “Threat Landscape” reports, or the “Cybersecurity Incident Statistics” dataset from Eurostat). Regress changes in breach counts on the DDD interaction to see whether the observed practice improvements are associated with fewer incidents. Even a weak negative correlation would bolster the policy relevance.  
   *Alternative outcomes*: Examine whether NIS2 affects other IT‑related outcomes (e.g., cloud adoption, IT spending) that could be extracted from the same Eurostat surveys, providing a broader view of digital transformation.

6. **Mechanism Exploration**  
   *Cost heterogeneity*: If data on firm‑level turnover are available (even in aggregate form), test whether the effect is larger for firms with higher turnover (i.e., where the €10 M threshold is also binding).  
   *Sector heterogeneity*: NIS2’s scope varies by sector. Run separate DDD analyses for “high‑risk” sectors (e.g., manufacturing, energy) versus “low‑risk” sectors to check whether the effect is concentrated where the regulation is more stringent.  
   *Policy awareness*: Incorporate a proxy for media coverage or policy‑talk (e.g., Google Trends for “NIS2” by country) to see if heightened awareness predicts the training‑only response in non‑transposed countries.

7. **Presentation and Clarity**  
   *Figure of the identification*: Include a simple schematic (treatment vs. control, pre/post, transposition status) to help readers visualise the DDD design.  
   *Event‑study plots*: Plot coefficients for each wave (or month) with confidence bands.  
   *Table of parallel trends*: Show the pre‑trend coefficients for each outcome side‑by‑side, rather than only reporting a single number in the text.  
   *Discussion of external validity*: Expand the concluding paragraph to discuss how the findings might generalise to other jurisdictions (e.g., US CIRCIA) and what institutional factors (e.g., enforcement agencies) are likely to matter.

8. **Minor Corrections**  
   *Typographical*: In the abstract “NIS2 Directive, which requires cybersecurity investments from enterprises with 50 or more employees while exempting smaller firms” – “exempting firms with fewer than 50 employees” would be clearer.  
   *References*: Some citations lack full author year (e.g., “\citet{cameron2008bootstrap}” – ensure correct bibliography entry).  
   *Notation*: Equation (1) uses “Post” but the post period is 2024 only; clarify that “Post” = 1 for 2024, 0 otherwise.  
   *Standard errors*: Mention the number of clusters (27) in the footnote of each table.  
   *Data availability*: State explicitly where the compiled dataset (country‑size‑year panel) is deposited (e.g., a public GitHub repository) to facilitate replication.

**Overall assessment**  
The paper tackles a novel and policy‑relevant question with a clever quasi‑experimental design that aligns with the original concept. The data are appropriate, the identification strategy is well motivated, and the findings – that enforcement matters for real cybersecurity investment – are potentially important for the design of future regulations. However, the current submission suffers from limited statistical power, possible spillover contamination, and reliance on a single binary post‑indicator. Addressing the essential points above (especially robust inference, dynamic timing, and spillover checks) would considerably strengthen the credibility of the causal claims and the paper’s contribution to the literature. If the authors can incorporate these revisions, the manuscript should be suitable for publication in the AER Insights format.
