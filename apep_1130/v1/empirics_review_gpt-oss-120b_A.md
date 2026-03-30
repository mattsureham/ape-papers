# V1 Empirics Check — openai/gpt-oss-120b (Variant A)

**Model:** openai/gpt-oss-120b
**Variant:** A
**Date:** 2026-03-30T11:26:14.676634

---

**1. Idea Fidelity**  

The paper follows the original manifest closely: it exploits the staggered, NAICS‑specific timing of SBA size‑standard increases, uses USAspending county‑by‑NAICS contract data, and asks whether expanding eligibility “crowds‑out” the smallest firms by concentrating procurement geographically.  The identification strategy is presented as a staggered Difference‑in‑Differences (DiD) à la Callaway & Sant’Anna (2021) with never‑treated sectors as controls, exactly as proposed.  The data sources (USAspending API, SBA size‑standard tables, QCEW employment, ACS metropolitan classification) are all described and match the manifest.  The research question – geographic redistribution of set‑aside dollars – is also intact.  

However, a few departures from the manifest merit comment:

* **Granularity of treatment** – The manifest envisions using *200+* six‑digit NAICS codes with sector‑specific timing.  The paper aggregates to the 19 two‑digit sectors, thereby losing much of the cross‑sectional variation and reducing the sample to 247 sector‑year observations.  This simplification departs from the original design and dramatically lowers statistical power.  

* **Magnitude of the size‑standard change** – The manifest suggests weighting exposure by the size of the threshold change (e.g., revenue vs. employee increase).  The paper treats treatment as a binary “post‑change” indicator and does not exploit heterogeneity in the size of the threshold shift.  

* **Geographic concentration metric** – The original idea mentions “geographic redistribution” broadly, while the paper focuses on two specific measures (Herfindahl‑Hirschman Index and number of counties receiving any set‑aside).  This is acceptable, but the manuscript could also examine alternative concentration indices (e.g., top‑5 county share) as a robustness check, which is only briefly mentioned in the appendix.  

Overall, the core idea is preserved, but the execution diverges in ways that weaken identification and precision.

---

**2. Summary**  

The paper investigates whether SBA “size‑standard” hikes, which broaden the definition of a small business, lead to a geographic concentration of federal set‑aside contracts.  Using a staggered DiD design across 19 two‑digit NAICS sectors (2013‑2016 reforms) and county‑level contract data from USAspending, the author finds that treated sectors lose about 85 counties from their small‑business procurement base and exhibit a modest increase in the Herfindahl‑Hirschman Index of county‑level spending.  These results suggest that newly eligible mid‑sized firms displace truly small firms in peripheral counties, concentrating procurement in more urban locations.

---

**3. Essential Points**  

1. **Identification Concerns – Insufficient Variation and Parallel‑Trends Test**  
   * The aggregation to 19 two‑digit sectors yields only three treatment cohorts and 247 observations, making the Callaway‑Sant’Anna estimator prone to bias and low power.  The paper presents an event‑study but offers no formal pre‑trend test (e.g., visualizing cohort‑specific trends or reporting placebo leads).  With such a small N, any violation of the parallel‑trends assumption could drive the results.  

2. **Treatment Definition – Ignoring Heterogeneous Threshold Changes**  
   * Not all size‑standard revisions are equally large; some involve modest revenue adjustments, others large employee‑count jumps.  By coding treatment as a simple post‑indicator, the analysis discards this richness and treats sectors with tiny changes the same as those with substantial expansions.  This may attenuate or exaggerate the estimated effects and makes it impossible to assess dose‑response relationships.  

3. **Outcome Measurement – Limited Robustness of the Geographic Concentration Findings**  
   * The main geographic result (‑85 counties) is statistically significant, but the accompanying HHI increase is modest and not significant in the TWFE specification.  Moreover, the robustness section shows that the log‑procurement effect is highly sensitive to dropping a single cohort.  The paper relies on a single concentration metric (HHI) without sufficient alternative specifications (e.g., Gini coefficient, top‑5 county share, spatial autocorrelation).  The evidence for genuine “crowding‑out” is therefore fragile.  

Given these three critical issues, the manuscript cannot be accepted in its current form.  I recommend a **major revision**.

---

**4. Suggestions**  

Below are concrete, non‑essential (but highly valuable) recommendations that can guide the authors toward a stronger, publishable paper.

| Area | Recommendation |
|------|----------------|
| **a. Exploit the full NAICS granularity** | Return to the original design that uses the 200+ six‑digit NAICS codes.  This will (i) increase the number of treated units dramatically, (ii) generate multiple staggered cohorts (the timing varies even within a two‑digit sector), and (iii) allow a more precise construction of an “exposure intensity” variable (e.g., share of establishments in a county that cross the new threshold).  With a richer panel, the Callaway‑Sant’Anna estimator will have enough variation to identify heterogeneous effects and to perform reliable pre‑trend checks. |
| **b. Construct a continuous treatment variable** | Rather than a binary post‑indicator, define exposure as the *size of the threshold increase* (e.g., Δemployees or Δrevenue) multiplied by the pre‑treatment share of contracts in the affected NAICS‑county cell.  This yields a continuous “eligibility expansion” measure that can be entered into the DiD framework (e.g., via interacted treatment intensity) and permits a dose‑response analysis. |
| **c. Strengthen the parallel‑trends assessment** | Plot sector‑specific trends in the outcome variables for treated and control groups over at least three pre‑treatment years.  Implement formal tests on leads (e.g., Wald tests for coefficients on pre‑treatment leads in the event‑study).  If leads are significant, consider alternative specifications (e.g., synthetic‑control‑based DiD or matching on pre‑trend characteristics). |
| **d. Enrich the geographic concentration toolkit** | • **Alternative indices**: Gini coefficient of county‑level spending, Theil index, top‑k share (k=5,10) to capture tail effects.  <br>• **Spatial econometrics**: Compute Moran’s I for the county‑level contract vector to test for increased spatial clustering.  <br>• **County‑level heterogeneity**: Interact treatment with baseline “distance to metropolitan hub” or with county‑level employment concentration to see if peripheral counties are disproportionately affected. |
| **e. Address potential confounders** | The SBA review schedule may coincide with sector‑specific shocks (e.g., trade tariffs, industry‑wide downturns).  Include sector‑specific time‑varying controls such as: (i) sectoral output growth from BEA, (ii) industry‑level employment changes from QCEW, (iii) lagged federal procurement volumes, (iv) CPI‑adjusted revenue trends for service sectors.  Conduct placebo tests using outcomes that should be unaffected (e.g., procurement of unrelated Federal programs). |
| **f. Refine the metropolitan classification** | The current 50 k population cutoff is a rough proxy.  Use the official OMB Metropolitan Statistical Area (MSA) delineations or RUCC codes directly.  Test robustness to alternative cutoffs (e.g., 10 k, 100 k) and to using “metro‑core vs. peripheral” classifications. |
| **g. Power calculations and clustering** | With only 19 clusters, conventional cluster‑robust SEs are unreliable.  Apply wild cluster bootstrap or the “cluster‑by‑sector and year” two‑way clustering approach.  Report effective number of clusters and, if feasible, conduct Monte‑Carlo power simulations to show that the enlarged six‑digit sample attains adequate power. |
| **h. Presentation and Transparency** | • Provide a supplemental data dictionary that maps each NAICS code to its treatment date and magnitude of change.  <br>• Release the constructed panel (county‑NAICS‑year) as a replication package.  <br>• Include a flow chart of the data‑processing pipeline (API queries, aggregation, treatment assignment). |
| **i. Economic Interpretation** | Quantify the welfare relevance of the concentration effect: estimate how many jobs or tax revenues are lost in counties that drop out, perhaps by linking to QCEW employment or local‑tax data.  This will strengthen the policy relevance of the “crowding‑out gradient.” |
| **j. Minor Stylistic Points** | – The abstract mentions “19 NAICS sectors (2008‑2020)” whereas the manifest covered 200+ codes and 2010‑2023; align dates/coverage. <br>– In Table 2, the TWFE “Post” coefficient for Log SB procurement is negative but not significant; explain why the two estimators diverge (heterogeneous treatment effects). <br>– Ensure consistent citation style (e.g., Callaway & Sant’Anna 2021). |

By addressing the three essential concerns—expanding the cross‑sectional variation, refining the treatment definition, and bolstering the evidence on geographic concentration—the paper will more convincingly demonstrate that SBA size‑standard changes have a spatial crowding‑out effect.  The suggested robustness checks and richer descriptive work will also pre‑empt reviewer criticisms about limited power and identification.  

**Recommendation:** *Major revision*.  The question is important and the data are uniquely suited to answer it, but the current specification falls short of the methodological rigor needed for an AER‑Insights article.  Implementing the above suggestions should yield a paper that meets the journal’s standards for credible identification and compelling empirical contribution.
