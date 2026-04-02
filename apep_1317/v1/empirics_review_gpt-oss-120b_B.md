# V1 Empirics Check — openai/gpt-oss-120b (Variant B)

**Model:** openai/gpt-oss-120b
**Variant:** B
**Date:** 2026-04-02T13:28:44.696040

---

**Referee Report – “The Conscription Tax: Wartime Military Service and Academic Achievement in Colombia”**  
*Insights, AER*  

---

### 1. Idea Fidelity  

The original manifest (Idea 0612) proposed exploiting **Colombia’s municipal‑level draft lottery (the “sorteo”)** as a *random* instrument for actual military service, and then estimating the causal impact of *wartime* conscription on earnings, formal employment, and broader human‑capital outcomes using DANE’s GEIH labor‑force surveys.  

**What the paper actually does**  

* Uses a **triple‑difference (DDD)** design based on gender (male vs female), geographic conflict intensity (high‑ vs low‑homicide departments), and a pre‑/post‑peace‑deal cohort distinction.  
* Relies on **administrative test‑score data (Saber 11 and Saber Pro)** rather than the GEIH labor‑force survey.  
* **Never uses the draft lottery** as an instrument, nor does it measure actual service take‑up, compliance, or the random share of eligible men selected in each municipality.  

**Assessment**  

The paper departs substantially from the manifest. It retains the broad research question (“does wartime conscription hurt human capital?”) but drops the key identification device (the lottery) and replaces it with a more conventional difference‑in‑differences strategy that hinges on *parallel‑trend* assumptions rather than a clearly exogenous random assignment. Consequently, the contribution is **different** from what was promised: it no longer provides a *clean natural experiment* for conscription, nor does it address earnings or formal‑employment outcomes.  

---

### 2. Summary  

The paper exploits gender, spatial conflict intensity, and pre‑/post‑peace cohort variation to examine whether the prospect of wartime conscription reduced Colombian students’ standardized test scores. Using a triple‑difference framework on Saber 11 and Saber Pro exams, it finds modest but statistically significant penalties for males in high‑conflict departments who faced the draft before the 2016 peace agreement, with larger effects at the university level. Placebo tests on females give null results, supporting the gender‑specific channel.

---

### 3. Essential Points  

1. **Identification Mis‑alignment with the Original Natural Experiment**  
   *The draft lottery is never used.* Because the lottery provides true random variation in service, dropping it removes the strongest source of exogenous variation. The DDD design now relies on the assumption that, absent conscription, the gender gap would evolve identically across conflict intensities and cohorts—a claim that is **not convincingly demonstrated**. The paper must either (a) revert to the lottery instrument (e.g., construct municipality‑year “lottery share” variables and instrument actual service) or (b) explicitly re‑frame the contribution as a *difference‑in‑differences* study and tone down the “causal” language accordingly.

2. **Timing of the Outcome Relative to Service**  
   Saber 11 is taken at age 16‑17, *before* the legal draft age (18). The paper interprets the negative coefficient as “anticipatory disinvestment,” but this interpretation is **fragile** without direct evidence that the cohort actually expected to be conscripted (e.g., survey data on expectations, or analysis of enrollment in “pre‑military” preparatory programs). Moreover, the DDD effect could be driven by other gender‑specific shocks (e.g., labor‑market demand for male adolescents, or differential violence exposure) that also affect test performance. More rigorous falsification—e.g., using non‑cognitive outcomes, alternative subjects, or cohorts that turned 18 after 2016—would be needed.

3. **Limited Scope of Outcomes and Policy Relevance**  
   The original idea promised to assess *earnings and formal‑employment*—outcomes of direct interest to policymakers. Test scores, while informative about human capital, are an indirect proxy. The paper should either (i) broaden the outcome set to include labor‑market variables (perhaps by linking the test‑score data to the GEIH or census) or (ii) acknowledge that the contribution is limited to *educational* effects and clarify the welfare implications.

If the authors cannot incorporate the lottery or provide convincing evidence for the DDD assumptions, the paper should be **rejected** in its current form.

---

### 4. Suggestions  

Below are concrete, non‑essential recommendations that would substantially improve the paper **if** the authors decide to keep the DDD approach, or guide a rewrite that returns to the lottery design.

#### A. Align the paper with the original natural experiment  

| Step | Action | Reason |
|------|--------|--------|
|1| **Construct the lottery variable**: Using the publicly available “sorteo” records (municipality‑year draws), compute the fraction of eligible men selected. | Provides a truly exogenous instrument for service. |
|2| **Merge lottery data with the GEIH labor‑force survey** (or with census microdata) to obtain earnings, employment, and sector outcomes. | Restores the promised contribution on earnings and formal‑employment. |
|3| **Instrument actual service** (or “probability of service”) with the lottery share in a two‑stage least squares framework. | Allows an IV estimate of the causal effect of *served* wartime conscription, not just the threat. |
|4| **Check first‑stage strength** (F‑stat > 10) and conduct over‑identification tests if alternative instruments are available (e.g., municipality‑level ‘batida’ intensity). | Demonstrates relevance and robustness. |

If the above is feasible, the paper would directly fulfill the manifest and join a small but growing literature on draft‑lottery IV designs.

#### B. Strengthening the DDD identification (if keeping the current design)

1. **Parallel‑trend validation**  
   * Plot male‑female score gaps over time for high‑ and low‑conflict departments *before* 2010 (if earlier Saber data exist) to visually assess pre‑trends.  
   * Perform event‑study regressions with leads and lags of the triple interaction; non‑significant leads would bolster the parallel‑trend claim.

2. **Alternative falsification outcomes**  
   * Use non‑cognitive test components (e.g., reading comprehension, language) that are less likely to be affected by the conscription threat.  
   * Examine outcomes that should be gender‑neutral (e.g., school attendance rates, dropout rates) for both sexes.

3. **Placebo geographic units**  
   * Randomly assign “high‑conflict” status to a subset of low‑conflict departments and re‑estimate the DDD; the coefficient should disappear.

4. **Address selective migration more directly**  
   * Use internal migration registers (if available) to test whether high‑conflict departments experienced gender‑specific out‑migration of school‑age males around the cohort cut‑off.  
   * Include department‑year population controls to absorb such flows.

5. **Robustness to alternative conflict measures**  
   * Replace homicide rates with battle‑death counts, displacement figures, or the UCDP “battle‑related deaths” variable.  
   * Report results using a **continuous** conflict intensity interacted with gender and cohort, as already done, but also try a *non‑linear* specification (e.g., splines) to ensure the effect is not driven by a few extreme departments.

#### C. Expanding outcome relevance  

* **Link test scores to later labor‑market performance**: If individual identifiers allow, attach GEIH earnings data to the Saber 11 cohort (e.g., via unique identification numbers). Estimate whether the DDD penalty on scores translates into earnings gaps.  
* **Consider secondary outcomes**: school‑year progression, grade repetition, high‑school graduation rates, university enrollment. These are likely available in the ICFES or Ministry of Education datasets and would strengthen the policy story.

#### D. Clarify the “anticipatory” mechanism  

* **Survey evidence**: Even a small supplemental survey of a subset of students (or use existing youth opinion polls) could show that males in high‑conflict areas perceived a higher likelihood of being drafted.  
* **Alternative channels**: Discuss and test whether differential **psychological stress** (e.g., exposure to violence) could explain the gender‑specific gap, perhaps by including a measure of local homicide rates *lagged* by a year to capture stress effects.  

#### E. Presentation and Technical Details  

1. **Standard errors** – With only 27 department clusters, standard errors may be downward‑biased. Consider **wild‑cluster bootstrap** (Cameron, Gelbach, Miller 2008) or **block‑bootstrap** across departments to ensure inference is reliable.  
2. **Multiple hypothesis testing** – The paper reports several outcomes (math, English, quantitative reasoning). Apply a **Bonferroni or Westfall‑Young** correction to guard against false positives.  
3. **Effect‑size interpretation** – Translate point estimates into more intuitive units (e.g., “equivalent to X months of schooling” or “reduces the probability of university admission by Y%”).  
4. **Data documentation** – Provide an appendix with a data‑access guide (ICFES download URLs, variable definitions, cleaning steps) to facilitate replication.  

#### F. Writing and Framing  

* Re‑position the paper’s contribution: if the lottery is not used, the title *“Conscription Tax”* may be misleading. A more accurate title could be *“The Threat of Wartime Conscription and Academic Achievement in Colombia”*.  
* Explicitly state the **limitations** of the DDD approach (no direct measurement of service, reliance on parallel trends) in the conclusion, and outline future work that could exploit the lottery for a cleaner design.  

---

### Bottom Line  

The manuscript investigates an important question but **fails to deliver on the original, highly credible natural experiment** that the idea manifest promised. As it stands, the identification rests on untested parallel‑trend assumptions, the outcome precedes actual service, and the policy relevance is narrowed to test scores. To become a genuine contribution worthy of the *Insights* format, the authors should either (i) rebuild the analysis around the **draft lottery instrument** and labor‑market outcomes, or (ii) substantially bolster the DDD strategy with the robustness, falsification, and inference checks outlined above, while clearly reframing the paper’s scope. Without such revisions, the paper should be **rejected**.
