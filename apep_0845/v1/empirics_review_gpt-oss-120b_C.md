# V1 Empirics Check — openai/gpt-oss-120b (Variant C)

**Model:** openai/gpt-oss-120b
**Variant:** C
**Date:** 2026-03-24T15:34:33.791963

---

**1. Idea Fidelity**

The paper follows the manifest closely. It uses the same policy shock (the 2013/55/EU professional‑qualifications reform), the same treatment intensity (pre‑reform count of regulated professions, 88–415), and the same outcome variables (over‑qualification gaps from Eurostat lfsa_eoqgan, plus the secondary occupational‑category and immigration measures). The identification strategy – a continuous‑treatment DiD with country‑year FE and a placebo on non‑EU foreigners – is exactly what the idea proposes. The only minor departure is that the manuscript drops three EU countries because of missing data (the manifest already noted a few missing observations). Overall, the authors have faithfully executed the original research design.

---

**2. Summary**

This paper evaluates whether the 2013 modernization of the EU Professional Qualifications Directive reduced the over‑qualification gap between mobile EU‑qualified professionals and native workers. Exploiting cross‑country variation in the number of regulated professions as a continuous treatment intensity, the authors estimate a two‑way fixed‑effects DiD model on country‑year aggregates of Eurostat’s over‑qualification rates. The estimated effect is statistically indistinguishable from zero (≈ +1.5 pp per SD of regulatory intensity), and a placebo on non‑EU migrants yields a similar coefficient, suggesting that the reform did not affect professional mobility.

---

**3. Essential Points**

1. **Parallel‑trend assumption is not convincingly demonstrated.**  
   The event‑study (Table 4) shows large and sometimes significant pre‑trend coefficients up to five years before the reform (e.g., \(t=-4\) significant at 10 %). Those early pre‑trend deviations raise serious doubts that the “treated” (high‑regulation) and “control” (low‑regulation) groups would have followed parallel paths absent the reform. Without a credible parallel‑trend justification, the DiD estimates cannot be interpreted as causal.

2. **Treatment intensity measurement is too crude.**  
   Counting the *total* number of regulated professions ignores two important dimensions: (i) the *distribution* of those professions across sectors that are actually mobile (e.g., health vs. engineering), and (ii) the *volume* of recognition applications per profession. A country with many regulated professions but few cross‑border applications in those fields receives little “dose” of the reform. This mis‑measurement likely attenuates the estimated effect and also generates the implausible pre‑trend pattern.

3. **Inference is under‑powered and standard errors are mis‑specified.**  
   The sample contains only 24 countries (17 clusters after dropping the three missing), yet the baseline regressions report conventional cluster‑robust SEs. Although the authors supplement with wild‑cluster bootstrap and randomization inference, the bootstrap p‑values (≈ 0.27) are far from the conventional 0.05 threshold, indicating limited power. The paper nevertheless interprets the null as “no effect” rather than “inconclusive”. A power calculation based on observed variance suggests the minimum detectable effect is roughly 2.5 pp, which is sizable relative to the observed gap; the study may simply be too small to detect the modest impact that a procedural reform would plausibly have.

---

**4. Suggestions**

Below are concrete recommendations that, if addressed, would substantially strengthen the paper.

---

**A. Strengthen the Parallel‑Trend Evidence**

1. **Visual Event‑Study Plot** – Include a graph of the event‑study coefficients with confidence bands. A visual check often makes it easier for readers (and reviewers) to assess trend similarity.

2. **Pre‑Trend Sub‑samples** – Restrict the sample to a narrower pre‑treatment window (e.g., 2009–2015) where the gap appears flatter, and re‑estimate the main DiD. If the coefficient changes dramatically, this signals sensitivity to pre‑trend violations.

3. **Placebo “Fake” Reform Dates** – Run DiD models with artificial treatment years (e.g., 2010, 2012) to see whether similar coefficients appear. Significant placebo effects would further question identification.

4. **Include Time‑varying Controls** – Add country‑specific trends or controls for macro variables that might affect over‑qualification (e.g., GDP per capita, unemployment, sectoral composition of employment). Such controls can absorb divergent pre‑trend dynamics.

---

**B. Refine the Treatment Variable**

1. **Weight by Expected Mobility** – Construct a “potentially mobile” index that gives higher weight to regulated professions with historically high cross‑border flows (e.g., nurses, pharmacists). Eurostat’s cross‑border worker statistics or the European Commission’s profession‑specific mobility reports could be used.

2. **Use Application‑Level Data** – If feasible, obtain the number of recognition applications submitted via the Internal Market Information system (IMI) or the European Professional Card per country. This would directly capture the intensity of procedural change rather than the static count of regulated professions.

3. **Instrumental Variable Check** – As a robustness exercise, treat the raw count of regulated professions as an instrument for the *actual* number of electronic recognitions, provided the exclusion restriction is plausible. This would illuminate how much attenuation bias arises from measurement error.

---

**C. Improve Statistical Power and Inference**

1. **Exploit Within‑Country Variation** – Instead of aggregating at the country‑year level, consider a micro‑level dataset (individual‑level LFS) that includes citizenship, education, occupation, and possibly the specific profession. A difference‑in‑differences at the individual level would dramatically increase the effective sample size and allow for richer heterogeneity analysis.

2. **Bootstrap the Full Model** – Report confidence intervals from the wild‑cluster bootstrap (percentile or BCa) rather than only p‑values. This gives a clearer sense of the uncertainty around the point estimate.

3. **Power Calculations** – Present a formal power analysis showing the detectable effect size given the current sample, and discuss what size of effect would be policy‑relevant. If the detectable effect is large, acknowledge that the study may be under‑powered to detect modest but economically meaningful changes.

---

**D. Expand the Economic Interpretation**

1. **Heterogeneity by Profession Type** – Even with aggregate data, you can interact the treatment intensity with dummy variables for “high‑skill” versus “medium‑skill” regulated professions (if such classification is available). This could reveal whether the reform mattered for certain sectors.

2. **Link to Labor‑Market Outcomes** – Over‑qualification is a useful proxy, but the policy’s ultimate goal is to increase the *employment* of qualified professionals in their field. If the LFS provides occupational codes, report whether the share of EU‑foreign workers in “professional/technical” occupations changed differentially.

3. **Policy Simulation** – Using the estimated (non‑significant) coefficient, simulate the counterfactual reduction in the over‑qualification gap that would be required to achieve a target (e.g., 50 % reduction). This helps readers gauge the magnitude of a “meaningful” effect.

---

**E. Minor Presentation and Technical Corrections**

1. **Consistent Terminology** – The paper sometimes uses “foreign” vs. “EU‑foreign” vs. “non‑EU foreign”. Define these clearly early and keep the labels uniform throughout tables and text.

2. **Table Formatting** – In Table 2 the column headings are cramped (e.g., “For. Gap (Cont.)”). Consider clearer labels such as “All‑foreign gap (continuous treatment)”.

3. **Standard Errors** – When reporting SEs, specify whether they are conventional cluster‑robust or bootstrap‐derived. A footnote can clarify this.

4. **Reference Updates** – Add the European Court of Auditors 2024 report to the bibliography and cite it directly where the “sparse use” of the EPC is discussed.

5. **Robustness Table** – Include the bootstrap p‑value and the randomization‑inference p‑value in the same row for easier comparison.

---

**Conclusion**

The paper tackles an important and under‑explored question: whether EU‑wide administrative simplification translates into real labor‑mobility gains for professionals. The research design is well aligned with the original idea, and the data sources are appropriate. However, the credibility of the causal claim is weakened by (i) evident pre‑trend violations, (ii) a blunt treatment measure that likely attenuates effects, and (iii) limited statistical power. Addressing the points above—particularly strengthening the parallel‑trend evidence and enriching the treatment variable—will either restore confidence in the null result or reveal a modest effect that the current specification cannot detect. With those revisions, the paper would make a valuable contribution to the literature on credential recognition and cross‑border labor mobility.
