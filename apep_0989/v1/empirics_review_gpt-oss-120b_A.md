# V1 Empirics Check — openai/gpt-oss-120b (Variant A)

**Model:** openai/gpt-oss-120b
**Variant:** A
**Date:** 2026-03-26T15:30:45.947624

---

**1. Idea Fidelity**  
The paper set out to exploit the Czech “Electronic Records of Sales” (EET) rollout as a staggered, sector‑by‑sector natural experiment, using municipality‑quarter data (CZSO) and supplementary Eurostat series to estimate the policy’s impact on business dynamics and tax revenues. The submitted manuscript departs from this original design in several important ways:

* **Data source** – Instead of the rich quarterly, municipality‑level CZSO registers (the “primary” outcome in the manifest), the author works with annual, 2‑digit NACE‑division counts from Eurostat’s Structural Business Statistics. This reduces the granularity of the treatment variation (the original idea relied on within‑municipality sector composition) and eliminates the possibility of using the municipality‑level “formal‑versus‑destruction” decomposition that the manifest highlighted.

* **Identification strategy** – The manifest proposed a **cross‑sectional, municipality‑level staggered DiD (CS‑DiD)** that leverages pre‑existing sector shares across municipalities, along with a set of mechanism tests (entry/exit splits, sole‑proprietor vs. legal entity, VAT revenue). The paper instead implements a **cross‑country DiD** that compares Czech treated sectors with five neighbouring economies. While the phased rollout still provides staggered timing, the crucial within‑Czech variation is largely discarded, and the author must rely on country‑level controls for parallel trends.

* **Research question** – The original question centred on *how the EET affected small‑business survival and tax compliance* at the local level, with an emphasis on the formalisation vs. destruction mechanism. The submitted version narrows the focus to *aggregate enterprise counts* and treats the “formalisation mirage” as a methodological contribution rather than testing the underlying micro‑level mechanisms.

Overall, the paper does not follow the manifest’s concrete identification plan and data set. It still addresses an interesting policy, but the departure is substantial enough to merit a comment in the review.

---

**2. Summary**  
The article investigates the impact of the Czech Republic’s 2016‑2018 Electronic Records of Sales (EET) tax‑compliance system. Using a staggered, cross‑country difference‑in‑differences approach with Eurostat Structural Business Statistics, the author finds that a naïve TWFE specification suggests a 19 % drop in enterprises, but after accounting for pre‑existing convergence trends (unit‑specific linear trends, Sun‑Abraham event study, placebo and permutation tests) the sign flips to an 8 % increase. The paper introduces the notion of a “formalisation mirage,” arguing that cross‑country DiD designs can mistakenly attribute catch‑up growth to policy effects in transition economies.

---

**3. Essential Points**  

1. **Identification Weakness – Inadequate Parallel‑Trend Control**  
   * The cross‑country design treats all non‑Czech units as controls, yet the pre‑trend diagnostics reveal systematic divergence: Czech sectors were already converging toward their neighbours long before EET. Adding unit‑specific linear trends is a blunt fix that may also soak up any genuine treatment effect, especially given the short post‑treatment window (2‑3 years). A more credible strategy would retain the municipality‑level, within‑Czech variation that the original idea promised, or at least exploit a synthetic‑control construction using only Slovakian data (the most comparable economy) with a rigorous pre‑trend matching procedure.

2. **Outcome Measurement and Mechanism Tests Are Mis‑matched**  
   * The manuscript relies on log‑enterprise counts at the 2‑digit NACE‑division level, which masks entry‑vs‑exit dynamics, sole‑proprietor behaviour, and sector‑specific cash intensity—all central to the formalisation‑destruction story. Consequently, the “formalisation mirage” claim is not directly tested. The paper would be substantially stronger if it (i) used the quarterly, municipality‑level CZSO data to decompose gross entries and exits; (ii) distinguished between sole‑proprietors and incorporated firms; and (iii) linked the enterprise dynamics to VAT revenue at the same sector‑municipality granularity.

3. **Event‑Study Specification and Interpretation**  
   * The Sun‑Abraham event study shows large positive pre‑treatment coefficients stretching back a decade. This pattern is interpreted as “convergence,” but the paper does not formally test whether the pre‑trend is linear, exponential, or driven by other macro‑shocks (e.g., EU structural funds, labour‑market reforms). Moreover, the event window stops only three years post‑treatment, making it impossible to separate a short‑run shock from a longer‑run adjustment. The reversal test around the 2023 abolition is under‑powered and reports a non‑significant coefficient without a confidence‑interval plot.

*Given the severity of these three issues, the paper cannot be accepted in its current form.*

---

**4. Suggestions**  

Below are concrete, constructive recommendations that could transform the manuscript into a compelling contribution. I separate them into “high‑impact” (addressing the essential flaws) and “enhancements” (non‑essential but valuable).

---

### A. Strengthening Identification  

1. **Return to the municipality‑level staggered DiD**  
   * Re‑construct the panel using CZSO quarterly counts (the original 6,200 ORP municipalities) and assign each municipality a treatment intensity equal to the share of its employment (or number of firms) that lies in an EET‑covered sector. This yields a *continuous* treatment variable and leverages within‑Czech variation while still preserving the phased timing.  
   * Estimate the model with municipality fixed effects, quarter fixed effects, and optionally municipality‑specific linear trends. The latter can be tested via an event study that includes leads and lags up to 8 quarters before and after each phase.  

2. **Synthetic‑Control / Matching with Slovakia**  
   * If the cross‑country approach is retained, construct a synthetic control for the Czech treated sectors using Slovakian NACE‑division trends (perhaps augmented with Poland and Hungary as donors). Pre‑treatment fit should be assessed with RMSPE; the treatment effect is the post‑treatment gap. This reduces reliance on linear trends and provides a visual validation.

3. **Placebo Treatments on Random Cohorts**  
   * Expand the permutation test to 5,000–10,000 draws and report the full distribution of estimated β’s, the 95 % confidence band, and the exact p‑value. Also conduct *in‑time* placebo tests (e.g., assign treatment to 2014) to ensure that no spurious “effects” appear before the actual rollout.

4. **Address Anticipation**  
   * Test for pre‑treatment effects up to two quarters before each phase. If coefficients are not flat, consider redefining the treatment date to the start of the *announcement* period (e.g., June 2016) and include a short anticipation window.

---

### B. Aligning Outcomes with the Formalisation Mechanism  

1. **Entry‑Exit Decomposition**  
   * Use the Eurostat business demography dataset (births and deaths) to compute net, entry, and exit rates at the municipal‑sector level. Report whether the post‑EET increase in enterprises is driven by more registrations (entries) or fewer closures (exits).  

2. **Sole‑Proprietor vs. Legal Entity**  
   * CZSO distinguishes between “živnost” (sole‑proprietor) and “společnost” (legal entity). Estimate differential effects; theory predicts a larger positive effect for sole‑proprietors (they face the highest marginal compliance cost).  

3. **VAT Revenue Linkage**  
   * Match the quarterly VAT collections at the municipality level (if available) or at least at the NACE‑section level, and test whether any increase in enterprises corresponds to a measurable rise in VAT. A simple difference‑in‑differences in logs of VAT per capita can be added as a secondary outcome.  

4. **Robustness to COVID‑19**  
   * The data stop in 2020, but the pandemic may have altered reporting behaviour. Verify that the results are robust when excluding 2020 entirely, and discuss any potential bias.

---

### C. Presentation and Transparency  

1. **Event‑Study Plots**  
   * Provide a graphical Sun‑Abraham event study with confidence bands, clearly marking the treatment year for each cohort. Visual evidence is far more persuasive than a table of coefficients.  

2. **Standardised Effect Sizes**  
   * The SDE table is useful; however, report the effect in absolute terms (e.g., “≈ 100,000 additional firms”) to aid intuition for policymakers.  

3. **Parallel‑Trend Diagnostics**  
   * Show pre‑trend balance tables for the treated vs. control groups (both at the country‑division level and, if feasible, at the municipality level). Include covariates such as average wage, employment density, and distance to major cities to convince readers that the treated Czech sectors were not already on a different trajectory for observable reasons.  

4. **Code and Replication Package**  
   * The manuscript references a GitHub repo but does not provide a DOI or a clear replication guide. A minimal reproducible package (data import scripts, treatment assignment, estimation code) would substantially increase credibility, especially given the unconventional data sources.

---

### D. Extending the “Formalisation Mirage” Narrative  

1. **Broader Literature Integration**  
   * The “mirage” concept is interesting, but the paper should more explicitly discuss how it relates to the growing literature on staggered DiD bias (e.g., Borusyak, Jaravel & Spiess 2022; Callaway & Sant’Anna 2021) and on convergence bias in cross‑country panels (e.g., Roodman 2011).  

2. **Simulation Exercise**  
   * A short Monte‑Carlo simulation showing how a converging trend can generate spuriously negative DiD estimates would solidify the theoretical claim.  

3. **Policy Implications**  
   * Outline concrete recommendations for future electronic‑receipt rollouts (e.g., complementary easing of registration costs, targeted subsidies for sole‑proprietors) rather than stopping at the methodological caution.

---

### E. Minor Technical Issues  

* **Standard Errors** – Cluster at the *municipality* (or division) level; clustering at the country‑division level may be too coarse given the limited number of clusters.  
* **Treatment Coding** – The current binary treatment lumps together sectors that entered in 2017 and 2018, potentially obscuring heterogeneity. Consider separate indicators for each phase.  
* **Citation Formatting** – Some references (e.g., “\citet{sun2021}”) lack full bibliographic entries; ensure the bibliography is complete.  
* **Tables** – Provide the number of observations after each sample restriction directly in the caption; avoid “N = 4190” in notes only.  

---

### Overall Assessment  

The paper raises an important methodological point about cross‑country DiD designs in transition economies and tackles a policy that attracted considerable public debate. However, by moving away from the rich municipality‑level data and the within‑Czech staggered design originally proposed, the manuscript loses the ability to credibly answer the central question: *Did the EET cause firms to formalise or to exit?* The current identification relies on a very coarse cross‑country comparison that is heavily contaminated by structural convergence, and the “trend‑adjusted” specification may be over‑correcting.

**Recommendation:** **Reject with invitation to resubmit** after a major revision that (i) re‑uses the municipality‑quarter data to exploit the original CS‑DiD design, (ii) implements robust parallel‑trend checks and mechanism‑specific outcome measures, and (iii) presents the “formalisation mirage” argument with clearer theoretical and simulation support. If the authors can address the points above, the paper would make a valuable contribution to both the tax‑compliance and causal‑inference literatures.
