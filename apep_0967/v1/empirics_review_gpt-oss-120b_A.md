# V1 Empirics Check — openai/gpt-oss-120b (Variant A)

**Model:** openai/gpt-oss-120b
**Variant:** A
**Date:** 2026-03-25T22:17:31.234196

---

**Referee Report – AER: Insights**

---

### 1. Idea Fidelity  

The manuscript follows the original idea closely. It uses the 2017 Ordonnances Macron as a source of ex‑ante variation in “worker voice” and exploits commune‑level exposure (the pre‑reform share of establishments with ≥ 50 employees) to test whether dismantling formal representation increased support for the Rassemblement National (RN). The identification strategy (cross‑sectional intensity DID) and the data sources (INSEE Sirene establishment stock, commune‑level presidential election results) are exactly those outlined in the manifest. The only deviation is that the paper expands the scope of robustness checks beyond the manifest (e.g., placebo outcomes, alternative weighting), which is a welcome addition. Overall, the authors stay true to the proposed research question and design.

---

### 2. Summary  

The paper investigates whether the 2017 French labour‑law reform that merged three worker‑representation bodies into a single Comité Social et Économique (CSE) – cutting elected representatives by roughly half in firms with ≥ 50 employees – altered the electoral fortunes of the far‑right RN. Using a continuous‑treatment difference‑in‑differences design at the commune level, the authors find essentially zero impact on RN first‑round vote share between 2012‑2017 (pre‑reform) and 2022 (post‑reform), with clean pre‑trends and a suite of robustness checks. The result challenges the “voice‑displacement” narrative linking labour‑institution erosion to right‑wing populism.

---

### 3. Essential Points  

1. **Treatment Measurement Timing and Attenuation Bias** – The treatment variable is constructed from the 2026 Sirene stock (size brackets as of 2026) rather than the 2017 distribution. This likely introduces classical measurement error because firms may have crossed the 50‑employee threshold between 2017 and 2026. The authors acknowledge the problem in the appendix but do not quantify its impact. A measurement‑error correction (e.g., using the 2015–2018 Sirene snapshots, or an instrumental‐variables approach) is needed to show that the null is not simply an attenuation artifact.

2. **Parallel‑Trends Test Limited to One Pre‑Treatment Period** – The DID relies on a single pre‑treatment observation (2012) relative to the reference year 2017. With only two pre‑periods, the parallel‑trends assumption is weakly identified. The manuscript should provide a more convincing test, such as a two‑way event‑study using additional elections (e.g., the 2007 presidential first‑round) or municipal elections, and should report the joint F‑test of pre‑trend coefficients.

3. **Ecological Inference and Potential Heterogeneous Effects** – The analysis is entirely ecological. It is possible that workers employed in large firms shifted toward RN while other residents (e.g., self‑employed, public‑sector employees) moved in the opposite direction, netting a zero aggregate effect. The paper should explore this by (i) interacting treatment with proxies for the share of the local labour force employed in the large firms (e.g., sectoral employment data), or (ii) conducting a within‑commune analysis using individual‑level survey data (e.g., French “Grande Enquête Travail”). Without such checks, the conclusion that “voice dismantling does not fuel the far right” may be overstated.

**Given these concerns, I recommend **revision** rather than outright rejection. The core idea and data are valuable, but the three points above must be addressed for the identification to be credible.**

---

### 4. Suggestions  

#### A. Strengthening the Treatment Variable  

1. **Use contemporaneous establishment size data** – The INSEE provides yearly “Sirene” extracts. Construct the share of ≥ 50‑employee firms for each year 2012, 2015, 2017 (or the closest available) and use the 2017 snapshot as the true exposure. If yearly data are unavailable, request the 2017‑2018 periodic release from INSEE; a short data‑use agreement may be sufficient.

2. **Measurement‑error correction** – If only the 2026 file can be used, implement a simulation‑extrapolation (SIMEX) or a reliability‑ratio correction using an auxiliary sample (e.g., a subset of communes where firm‑size histories are known). Report corrected estimates and confidence intervals to demonstrate that attenuation does not explain the null.

3. **Alternative exposure measures** – Consider using the *number* of affected seats removed (available from the Ministry of Labour’s implementation tables) rather than the simple share of establishments. This would align the treatment more directly with the reduction in elected representatives.

#### B. More Robust Parallel‑Trends Evidence  

1. **Add pre‑treatment elections** – The 2007 presidential first‑round and the 2002 municipal elections are publicly available at the commune level. Including these yields three pre‑treatment periods, allowing a graphical event‑study and a formal test that all pre‑trend coefficients are jointly zero.

2. **Placebo outcomes beyond Melenchon** – The authors already show Melenchon and turnout; adding another outcome (e.g., vote share for the Socialist Party or abstention rates) can reinforce that the treatment does not affect unrelated political behaviour, strengthening the causal claim.

3. **Falsification using a “pseudo‑treatment”** – Randomly assign treatment intensity using the 2012 share of establishments and re‑estimate the model. The distribution of fake treatment coefficients should be centered at zero; this provides a sanity check on the estimation routine.

#### C. Addressing Ecological Bias and Heterogeneity  

1. **Interaction with local labour‑force composition** – Merge the commune‑level “Emploi du Temps” or “Filosofi” labour‑force survey to obtain the proportion of workers employed in firms ≥ 50 employees. Interact this share with the treatment to see whether the effect is concentrated among those directly affected.

2. **Subsample of “large‑firm communes”** – The authors already restrict to communes with < 10 k voters and find a marginal positive effect. Extend this by focusing on communes where a single large employer accounts for ≥ 30 % of total employment; this will capture settings where the CSE reform likely mattered most.

3. **Individual‑level validation** – If feasible, link the Sirene data to the “Enquête Emploi” panel (or the 2018/2022 “EMPLOY” modules) to see whether workers in affected firms changed self‑reported political orientation or voting intention. Even a small subsample can provide suggestive evidence that the aggregate null is not masking heterogeneous responses.

#### D. Econometric Refinements  

1. **Cluster Robustness** – With only 94 departmental clusters, the usual asymptotic justification for clustered SEs is borderline. Employ the wild cluster bootstrap (Cameron, Gelbach, Miller, 2008) or the `kmc` correction (Bell & Miller, 2021) to verify the inference.

2. **Spatial Correlation** – Worker‑voice reforms could have spillovers across neighboring communes (e.g., workers commuting to a nearby large firm). Test for spatial autocorrelation in the residuals (Moran’s I) and, if present, consider spatial lag models or include a spatially lagged treatment variable.

3. **Alternative Functional Forms** – The linear interaction may be inappropriate given the skewness of the treatment distribution. Estimate the model using a log‑transformed share (adding a small constant) or a semi‑parametric (local polynomial) approach to check for non‑linear dose‑response patterns.

#### E. Presentation and Transparency  

1. **Provide replication package** – Deposit the curated Sirene‑treatment file, the election dataset, and the Stata/R code on a public repository (e.g., OSF). Include a README with steps to reconstruct the main tables.

2. **Clarify the “Post” definition** – The paper treats 2022 as the sole post‑reform period. Since the reform became mandatory in Jan 2020, consider using the 2020 European Parliament election as an additional post‑treatment observation (if data are available) to increase power and test robustness to timing.

3. **Discuss potential “policy anticipation”** – Workers and firms may have altered behaviour already after the September 2017 announcement but before implementation. A dynamic specification allowing a gradual treatment effect (e.g., interacting treatment with a “years since announcement” variable) would help assess anticipatory responses.

4. **Expand the theoretical framing** – The introduction mentions Hirschman’s “voice‑exit” model, but a more detailed discussion of why the CSE reform should affect political voice (e.g., mechanisms through collective bargaining, workplace safety, or union density) would make the causal story tighter and guide the heterogeneity analysis.

#### F. Minor Issues  

- **Table Formatting** – Some tables (e.g., Table 1) display empty cells for 2012/2022 treatment variables; consider filling with “–” for clarity.  
- **Reference Consistency** – Several citations (e.g., “Algan et al. (2026)”) appear to be placeholders; verify that all references are published or in‑press.  
- **Typographical Errors** – “Mélenc’hon” should be “Mélenc’hon” throughout; check accent encoding.  
- **Footnote Placement** – The note on measurement error in the appendix could be moved to the main text for greater visibility.

---

### Overall Assessment  

The paper tackles a novel and policy‑relevant question with a clever identification strategy. The data are high‑quality, and the baseline results are transparently reported. However, the credibility of the null hinges on (i) accurate measurement of the treatment, (ii) a convincing parallel‑trends test, and (iii) ruling out ecological masking of heterogeneous individual responses. Addressing the three “essential points” and incorporating the suggested robustness and heterogeneity analyses will substantially strengthen the manuscript and make the conclusion that “weakening formal worker voice does not fuel far‑right voting” robust to criticism. I look forward to a revised version that resolves these issues.
