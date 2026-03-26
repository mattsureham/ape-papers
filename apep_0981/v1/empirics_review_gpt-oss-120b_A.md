# V1 Empirics Check — openai/gpt-oss-120b (Variant A)

**Model:** openai/gpt-oss-120b
**Variant:** A
**Date:** 2026-03-26T13:32:28.244297

---

**Referee Report**

---

### 1. Idea Fidelity  

The original manifest proposed to exploit the staggered adoption of Good Samaritan Laws (GSLs) to examine *down‑stream treatment entry* by using **TEDS‑A admission counts** and, in particular, the *referral‑source* decomposition (health‑care vs. criminal‑justice referrals). The authors should therefore estimate a reduced‑form effect of GSLs on opioid‑treatment admissions and, ideally, a triple‑difference that isolates the “health‑care referral” channel.

The submitted manuscript departs from this plan in several substantive ways:

1. **Outcome change** – The paper uses **Medicaid State Drug Utilization Data (SDUD)** (buprenorphine vs. opioid‑pain‑killer prescriptions) rather than TEDS‑A admissions. While still a treatment‑entry measure, it captures *prescriptions* rather than *first‑time treatment episodes* and is limited to the Medicaid population. This shift narrows the policy relevance (the GAO gap was about *treatment admissions* for all payers) and introduces new identification concerns (e.g., changes in Medicaid eligibility, formulary decisions, and the effect of the 2014 Medicaid expansion).

2. **Mechanism test** – The original design relied on the *referral‑source* variable to demonstrate that the effect runs through the emergency‑department referral channel. The current paper replaces this with a *within‑state comparison of two drug categories* (buprenorphine vs. oxycodone/hydrocodone). This “built‑in placebo” is clever but does not directly verify the emergency‑call → ED referral pathway; it could be picking up any policy that differentially affects treatment‑vs‑pain prescribing (e.g., the 2000 DATA waiver, patent expirations).

3. **Policy scope** – The manifest emphasized heterogeneity by *immunity strength* (arrest vs. charge vs. prosecution) and interaction with *naloxone‑access laws*. The manuscript includes only a binary GSL indicator and a crude naloxone control; no analysis of immunity‑type heterogeneity is presented.

4. **Treatment timing** – The manifest noted the need for a pre‑trend test and a DDD using non‑opioid admissions as a placebo. The paper supplies an event‑study for the prescription outcome, but does not present a placebo outcome (e.g., alcohol‑related admissions) or a DDD using non‑opioid prescriptions.

In short, the manuscript **fails to follow the original research design** and therefore does not directly address the question promised in the manifest. The new question—whether GSLs shift the Medicaid prescription mix—is interesting, but it is **a different empirical exercise** that would merit its own proposal and a clear justification for the departure.

---

### 2. Summary  

The paper estimates the effect of state‑level Good Samaritan overdose‑immunity laws on Medicaid‑paid buprenorphine prescriptions relative to opioid‑pain‑killer prescriptions using a Callaway‑Sant’Anna staggered DIﬀerences‑in‑Differences design. The authors find a large triple‑difference estimate (≈ 2.6 log points) indicating a compositional shift toward medication‑assisted treatment, especially in Medicaid‑expansion states.

---

### 3. Essential Points  

1. **Identification Mismatch** – The shift from TEDS‑A admissions to Medicaid prescriptions changes the causal pathway and introduces confounding from Medicaid expansion, eligibility changes, and formulary reforms. The authors must either (a) re‑align the analysis with the original admission‑based outcome (or convincingly argue why the prescription measure is a valid substitute) and (b) demonstrate that the timing of GSL adoption is orthogonal to Medicaid‑policy dynamics.

2. **Mechanism Verification** – The current DDD compares two drug categories but does not directly test the hypothesized emergency‑call → ED referral channel. Without a referral‑source variable or a comparable placebo outcome, the “treatment‑door” story remains speculative. The authors should (i) incorporate a referral‑source or ED‑visit outcome (e.g., TEDS‑A health‑care referrals) as a robustness check, or (ii) use an external measure of 911‑call volume to link the policy to the treatment pipeline.

3. **Policy Heterogeneity & Controls** – The paper treats GSLs as a homogeneous binary treatment and includes only a crude naloxone‑law control. The manifest called for exploiting variation in immunity strength and interacting with other harm‑reduction policies. Ignoring this heterogeneity may mask differential effects and raises concerns about omitted‑variable bias. The authors need to (i) code the immunity dimensions (arrest‑only vs. arrest + charge + prosecution), (ii) interact GSLs with Medicaid‑expansion status and naloxone‑law adoption, and (iii) present results for these subsamples.

Given these three fundamental shortcomings, **the paper cannot be accepted in its current form**. It would require substantial revisions to either bring the analysis back in line with the original idea or to reframe the contribution with appropriate justification and additional robustness.

---

### 4. Suggestions  

Below are concrete, non‑essential recommendations that will improve the paper irrespective of the major revisions above.

#### A. Clarify the Research Question and Its Relevance  
* Explicitly state why buprenorphine prescriptions are an acceptable proxy for “treatment entry” when the original intent was to study admissions. Discuss the coverage of Medicaid relative to the total treatment market and any potential bias this induces.  
* Position the contribution relative to the GAO’s “first‑stage outcomes” gap—explain how your prescription‑level analysis fills (or does not fill) that gap.

#### B. Strengthen the Identification Strategy  
1. **Parallel‑Trends Diagnostics**  
   * Present event‑study plots for both buprenorphine and pain‑killer prescriptions side‑by‑side, with confidence bands, to make the pre‑trend evidence transparent.  
   * Conduct a formal test (e.g., joint F‑test) of pre‑trend coefficients.

2. **Placebo Outcomes**  
   * Add a placebo outcome that should be unaffected by GSLs, such as Medicaid prescriptions for non‑opioid chronic‑pain drugs (e.g., NSAIDs) or admissions for alcohol‑related conditions. Show the DDD coefficient is null.

3. **Alternative Control Groups**  
   * Use the “not‑yet‑treated” states as the primary control (as you already do) but also present a “synthetic control” for a few early adopters (e.g., New Mexico) to verify robustness.  
   * Consider a “leave‑one‑out” exercise removing the largest cohort (2015) to assess sensitivity to cohort weighting.

4. **Address Medicaid Expansion Endogeneity**  
   * Implement an event‑study that includes an interaction term between GSL and Medicaid‑expansion timing, allowing for a flexible dynamic effect of each policy.  
   * Explore a “difference‑in‑differences‑in‑differences” where the triple‑difference isolates the GSL effect *after* controlling for the Medicaid‑expansion *trend* within the same states.

#### C. Refine the Triple‑Difference Specification  
* The current DDD stacks buprenorphine and pain‑killer observations and adds a drug‑type fixed effect. Verify that the error structure is appropriate (e.g., cluster at the state level, allow for heteroskedasticity across drug types).  
* Report the DDD estimate in levels (e.g., additional buprenorphine prescriptions per 100 k population) to aid interpretation for policymakers.

#### D. Exploit Policy Heterogeneity  
* **Immunity Strength** – Code the three dimensions (arrest, charge, prosecution) as separate binary variables; estimate separate ATTs or an interaction model.  
* **Naloxone‑Access Laws** – Since many states adopted both policies contemporaneously, consider using an “intention‑to‑treat” design where GSL *alone* vs. *GSL + naloxone* are distinguished.  
* **Timing of DATA‑2000 Waiver Expansion** – Include a control for the number of waivered physicians per state (available from SAMHSA) to ensure that observed buprenorphine growth is not simply due to supply‑side changes.

#### E. Data Quality and Construction  
* Provide a short replication appendix (e.g., Stata/ R code) that documents the string‑matching algorithm for drug identification, the handling of zeros, and the aggregation steps.  
* Discuss any potential misclassification (e.g., buprenorphine products used for pain) and how you mitigate it (e.g., excluding formulations without naloxone).

#### F. Presentation and Interpretation  
* The headline estimate “2.6 log points” is large; convert it to a more intuitive metric (≈ 13‑fold increase) and discuss whether this magnitude is plausible given observed trends.  
* In the discussion, acknowledge alternative channels (e.g., reduced stigma, increased provider awareness) that could also generate a compositional shift, and suggest future work to disentangle them.  
* Clarify why the simple GSL coefficient on buprenorphine becomes near zero after controlling for Medicaid expansion, while the DDD remains huge—this is a teaching point about the power of within‑state comparators.

#### G. Minor Technical Points  
* In Table 1, report the median and inter‑quartile range for prescription counts; the mean is heavily skewed.  
* Align the naming of variables across sections (e.g., “GSL” vs. “Good Samaritan Law”).  
* Ensure footnotes cite the PDAPS dataset correctly and include a URL.  
* When referencing the Callaway‑Sant’Anna estimator, briefly explain the “not‑yet‑treated” logic for readers unfamiliar with the method.

---

**Conclusion** – The paper tackles an important policy question and leverages a solid staggered‑DiD framework. However, the departure from the original admission‑based design and the lack of a direct test of the hypothesized emergency‑call → treatment pathway undermine the stated contribution. Substantial re‑orientation of the empirical strategy (or a transparent justification for the new focus) and additional robustness work are required before the manuscript can be considered for publication.
