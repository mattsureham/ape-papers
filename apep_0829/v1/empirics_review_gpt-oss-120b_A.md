# V1 Empirics Check — openai/gpt-oss-120b (Variant A)

**Model:** openai/gpt-oss-120b
**Variant:** A
**Date:** 2026-03-23T15:39:19.698973

---

**Referee Report – “The Scope Dividend: Broader Patents Attract More Follow‑On Innovation”**  

*American Economic Review: Insights (submission)*  

---

### 1. Idea Fidelity  

The manuscript sets out to test whether examiner‑driven variation in **patent claim narrowing** (measured in *words per claim*) causally affects follow‑on innovation, exploiting a **two‑stage examiner design**:  

1. **Extensive‑margin stage** – a leave‑one‑out (LOO) examiner grant‑rate predicts whether a application is granted at all.  
2. **Intensive‑margin stage** – a LOO examiner *average claim‑narrowing* (words removed/added during prosecution) predicts the *scope* of the granted patent, which in turn influences forward citations.  

The posted paper departs from this blueprint in three substantial ways:

| Manifest element | Paper’s implementation | Comment |
|------------------|------------------------|---------|
| **Scope measure** – *words per claim* (claim‑narrowing) | Uses *number of claims at grant* (a count) | The count is a coarser proxy; it does not capture how much each claim is narrowed, which was the core source of quasi‑random variation in the original idea. |
| **Two‑stage design** – first‑stage LOO **grant‑rate** → grant probability; second‑stage LOO **claim‑narrowing** → scope | Omits the extensive‑margin stage entirely; analysis is restricted to granted patents only. | By conditioning on grant, the paper cannot separate the effect of “getting a patent” from the effect of “how broad it is,” contrary to the manifest’s intention. |
| **Data on pre‑grant claim revisions** (PAIR / pre‑grant publication) | Uses only granted‑claim counts; no information on claim revisions or word‑level changes. | The manuscript cannot exploit the 91‑word spread among examiners that the manifest highlights. |

Overall, the paper captures the *spirit* of the question (examiner‑induced scope → citations) but **misses the key identification device** (claim‑word narrowing) and the **extensive‑margin stage** that were central to the original proposal. Consequently, the results are less directly linked to the policy‑relevant mechanism (examiner‑driven claim narrowing) and rely on a weaker instrument whose exogeneity is more doubtful.

---

### 2. Summary  

The author estimates a causal effect of patent “scope” on forward citations by instrumenting the number of claims granted with a leave‑one‑out examiner‑average of claims within USPC‑class × filing‑year cells. The first‑stage is strong (F ≈ 3,560), and the 2SLS results suggest that each examiner‑induced claim raises five‑year forward citations by roughly 2 percent, with larger effects in crowded technology fields. The paper interprets this as evidence for a “scope dividend” — broader patents signal valuable technology and stimulate follow‑on innovation rather than block it.

---

### 3. Essential Points  

1. **Identification Concern – Exogeneity of the Claim‑Count Instrument**  
   The leave‑one‑out *average number of claims* for an examiner is likely correlated with unobserved application quality. Examiners who see many high‑complexity applications (e.g., biotech, software) will on average grant more claims *because* those applications are inherently richer, not because the examiner is more lenient. The manuscript’s balance tests are limited to “grant lag”; they do not address pre‑grant observable quality (e.g., number of prior‑art citations, inventor‑experience, assignee size). Without convincing evidence that the instrument is orthogonal to these determinants, the exclusion restriction is tenuous.  

2. **Measurement of Scope – Number of Claims vs. Claim‑Word Narrowing**  
   Using only claim counts conflates two distinct dimensions of breadth: (i) *vertical breadth* (how many distinct inventions are protected) and (ii) *horizontal breadth* (how wide each claim is). The manifest highlights **words per claim** as the source of quasi‑random variation; word‑level narrowing captures the examiner’s willingness to carve out narrower legal boundaries while holding the underlying invention constant. A count of claims is a noisy, potentially endogenous measure that may reflect strategic claim‑crafting by applicants. Consequently, the paper does not test the policy question about the optimal degree of **claim narrowing**.  

3. **Sample Selection – Conditioning on Granted Patents Only**  
   By excluding denied applications, the analysis implicitly conditions on the extensive margin. If examiner leniency simultaneously raises both the probability of grant and the number of claims, the observed citation effect may capture a combination of (i) “being granted” and (ii) “having more claims.” Without the first‑stage grant‑rate instrument, the paper cannot disentangle these channels, contrary to the two‑stage design proposed in the original idea. This selection bias could upward‑bias the estimated scope effect.  

If the authors cannot convincingly address these three points, the paper should be **rejected** in its current form.

---

### 4. Suggestions  

Below are concrete, non‑essential recommendations that, if incorporated, would strengthen the paper substantially. The list is organized by theme; you need not implement every item, but addressing the most salient points will markedly improve the manuscript.

#### A. Strengthening the Identification Strategy  

1. **Augment Balance Tests**  
   - Regress the instrument on rich pre‑grant observables: number of cited prior‑art references, number of inventors, firm size (assignee employee count or prior patent portfolio), technology‑specific fixed effects (e.g., subclass), and filing‑month dummies.  
   - Present a “balance table” analogous to Table 2 in Sampat & Williams (2020) showing negligible predictive power (t‑stats < 1).  

2. **Include Applicant‑Level Fixed Effects**  
   - If a given assignee files multiple applications within the same cell, including assignee‑by‑year fixed effects can soak up systematic quality differences.  
   - Run a specification with both examiner‑level and assignee‑by‑year dummies; compare IV coefficients.  

3. **Instrument Robustness Checks**  
   - Construct alternative instruments: (i) LOO *average claim‑word count* (if data are available), (ii) examiner *grant‑rate* (first‑stage from the manifest) and use a two‑stage‑least‑squares‑with‑two‑instruments (GMM) framework.  
   - Perform a weak‑instrument test for each and report the Kleibergen‑Paap rk statistic.  

4. **Over‑identification Test**  
   - If you can generate at least two independent examiner‑level measures (claims count and grant‑rate), run a Hansen J‑test to assess whether the instruments are jointly valid.  

#### B. Improving the Measurement of Patent Scope  

1. **Incorporate Claim‑Word Information**  
   - The PatentsView `pgpub_document_stats` table (pre‑grant publications) contains claim‑text lengths. Compute the *change in words per claim* between pre‑grant and granted versions for each patent.  
   - Use the LOO examiner average of this *claim‑word change* as the primary instrument, directly matching the original idea.  

2. **Control for Claim Complexity**  
   - Include the *average length of granted claims* (words) to capture horizontal breadth, alongside claim count. This helps separate vertical vs. horizontal scope effects.  

3. **Consider Patent Family Size**  
   - International patent families often reflect underlying invention value. Include family size as a control or interact it with the instrument to see if the scope effect varies with the underlying market importance.  

#### C. Addressing the Extensive‑Margin Issue  

1. **Two‑Stage Design (Grant‑Rate → Scope → Citations)**  
   - Replicate the first‑stage: regress the binary grant indicator on the LOO examiner grant‑rate (or examiner “strictness” measured by rejection rates).  
   - In the second stage, use the predicted grant probability as an additional endogenous variable together with the scope instrument. This yields three‑stage IV estimates (or a control function approach) that separate the “grant” effect from the “scope” effect.  

2. **Sample Including Denied Applications**  
   - Even if citation data are unavailable for denied applications, you can treat “zero citations” as the natural outcome for non‑granted patents and include them in a Tobit or hurdle model.  
   - Alternatively, perform a “selection‑adjusted” IV regression where the first stage predicts grant, and the second stage predicts citations conditional on grant, using a control function (Heckman‑type) to correct for selection bias.  

3. **Alternative Outcome Windows**  
   - The five‑year citation window may truncate the citation life‑cycle, especially for slow‑moving technologies (e.g., pharmaceuticals). Report results for 8‑year and 10‑year windows where data permit, and test whether the scope effect attenuates or amplifies over time.  

#### D. Empirical Robustness & Sensitivity  

1. **Clustering and Multi‑Way Errors**  
   - Current standard errors are clustered at the examiner level. Because assignment is also nested within technology class–year cells, consider two‑way clustering (examiner × class‑year) following Cameron, Gelbach & Miller (2011).  

2. **Placebo Tests**  
   - Run the same IV regressions using *pre‑grant* citations (e.g., citations received by the published application before grant) as a placebo outcome. No effect should be observed if the instrument truly works through post‑grant scope.  

3. **Heterogeneity Beyond Crowdedness**  
   - Explore heterogeneity by (i) patent age (early‑ vs. late‑filing within the sample), (ii) technological intensity (high‑tech vs. low‑tech subclasses), and (iii) assignee type (corporate vs. university). This can reveal where the scope dividend is strongest.  

4. **Non‑Linear Effects**  
   - Test whether the effect of additional claims is diminishing. Include the instrument and its square, or interact the instrument with the baseline claim count.  

#### E. Presentation & Transparency  

1. **Clarify the Policy Question**  
   - The introduction should frame the trade‑off between “claim narrowing for legal certainty” and “broader patents for signaling,” making explicit that the policy lever is the *extent of examiner‑induced claim narrowing*.  

2. **Data Availability**  
   - Provide a reproducible Stata/R/Python script that builds the LOO examiner variables from the raw PatentsView tables, along with a DOI for the dataset.  

3. **Tables & Figures**  
   - Add a histogram of the **instrument** (LOO claim‑word change) to illustrate the 90‑10 spread (≈ 90 words) that the manifest emphasizes.  
   - Include a scatter plot of the first‑stage relationship with fitted line and confidence band.  

4. **Citation Measurement**  
   - Explain why self‑citations are kept separate, and discuss potential “strategic citation” behavior (e.g., firms citing their own patents to build a citation network).  

5. **Discussion Section**  
   - Expand the “Mechanism” subsection to explicitly link the three channels (signal of value, boundary clarity, combinatorial fertility) to observable predictions that could be tested (e.g., citation lag, citation diversity across assignees).  

---

### Concluding Remarks  

The manuscript tackles an important question: how examiner‑driven patent scope influences downstream innovation. The current implementation, however, deviates from the original, more precise design that leveraged **claim‑word narrowing** and a **two‑stage examiner IV**. Because the instrument (examiner‑average claim count) is plausibly less exogenous, and because the extensive‑margin is omitted, the causal interpretation is weakened.  

If the authors can (i) re‑construct the claim‑word narrowing instrument, (ii) incorporate the grant‑rate stage (or otherwise address selection on the extensive margin), and (iii) provide more exhaustive balance and robustness checks, the paper would make a valuable contribution to the patent‑breadth literature and to USPTO policy discussions. In its present form, the paper does not meet the evidentiary standard for an AER‑Insights publication.  

**Recommendation:** *Major revision* (address the three essential points above; otherwise reject).  
