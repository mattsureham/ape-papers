# V1 Empirics Check — openai/gpt-oss-120b (Variant B)

**Model:** openai/gpt-oss-120b
**Variant:** B
**Date:** 2026-03-23T12:05:45.834352

---

**1. Idea Fidelity**  
The manuscript follows the broad thrust of the original manifest – estimating the economic cost of India’s district‑level internet shutdowns with night‑lights – but it departs from several key elements that were central to the proposed design:

| Manifest element | How the paper treats it |
|------------------|------------------------|
| **Monthly VIIRS data (2012‑2024)** | Uses **annual** VIIRS composites (2014‑2022) only.  The higher‑frequency panel that was meant to capture short‑run effects is absent. |
| **Cumulative shutdown‑hours** | Constructs “shutdown days” (and an intensity measure) rather than a true hour‑count.  This coarsens variation and may conflate duration with intensity of service restrictions. |
| **Event‑study/Dynamic effects** | No event‑study specification or visualization of pre‑trends beyond a simple placebo test.  The paper therefore cannot show the timing of the impact or test for anticipatory effects. |
| **Exam‑triggered shutdowns as an exogenous subsample** | Included, but the analysis treats them as a binary treatment rather than exploiting the **known calendar dates** to create a clean pre‑post design.  The short duration of these events (1‑2 days) makes them ill‑suited for detection with annual lights. |
| **Neighbour‑district placebo** | Not implemented.  A comparison with adjacent districts that experience the same conflict but no shutdown would strengthen the credibility of the identifying assumption. |
| **Service‑type heterogeneity (mobile‑only vs full blackout)** | Ignored; the dataset contains this information but it is never used. |
| **Baseline digital‑penetration interaction** | Not explored, despite the manifest’s plan to test whether more‑connected districts suffer larger losses. |
| **Spillovers to connected non‑shutdown districts** | Not examined. |
| **Sample period & coverage** | The manifest covered 2012‑2024 and 913+ shutdowns; the paper limits itself to 2016‑2022 and 1,978 events (≈ 2 k).  The earlier years and the most recent shutdowns are omitted without justification. |

Overall, the paper captures the spirit of the project but **omits a substantial portion of the identification strategy and richness of the data** that were presented as essential to establishing a credible causal estimate.  The resulting analysis is consequently more descriptive than causal.

---

**2. Summary**  
The paper studies the association between district‑level internet shutdowns in India (2016‑2022) and annual nighttime lights from VIIRS, finding a large negative effect in a basic two‑way fixed‑effects model (≈ 4 % lower lights) that disappears once state‑year fixed effects are added.  Using exam‑triggered shutdowns as a plausibly exogenous subsample and a dose‑response analysis, the authors argue that only prolonged shutdowns (> 30 days) generate measurable economic losses, while short, exam‑related blackouts are too brief to be detected at the annual frequency of the data.

---

**3. Essential Points**  

1. **Identification Strength – Insufficient Exploitation of Exogenous Variation**  
   The paper relies exclusively on a TWFE specification with district and state‑year fixed effects.  Without an event‑study, a neighbor‑district placebo, or a clean pre‑post design around exam dates, the key identifying assumption (shutdown timing orthogonal to district‑specific shocks) remains untested.  Consequently, the attenuation of the coefficient after adding state‑year FE could reflect omitted within‑state heterogeneity rather than genuine causal nulls.

2. **Measurement Mismatch – Annual Lights vs. Short‑Run Shutdowns**  
   Using annual night‑light averages to detect effects of shutdowns that often last only a few days (especially the exam‑triggered subsample) severely limits statistical power.  The manuscript acknowledges this but does not attempt to remedy it (e.g., by employing the monthly VIIRS data originally proposed).  As a result, the study cannot credibly answer the central question about the *economic cost of internet shutdowns*.

3. **Under‑utilisation of Available Data and Heterogeneity Analyses**  
   The shutdown database contains valuable information on service type, trigger, and digital‑penetration levels that are never used.  Ignoring these dimensions prevents the paper from delivering the richer mechanistic insight promised in the manifest (e.g., distinguishing mobile‑only blackouts, testing spillovers, or interacting with baseline internet usage).  The current heterogeneity checks are limited to coarse duration and trigger categories and remain statistically imprecise.

*Given these three fatal shortcomings, the manuscript does not yet deliver a convincing causal estimate of the economic impact of internet shutdowns.  I therefore recommend **major revisions** before the paper can be considered for publication.*

---

**4. Suggestions**  

Below are concrete, actionable recommendations that, if addressed, would substantially improve the paper’s credibility, relevance, and contribution.  The suggestions are grouped by theme and ordered roughly from essential to nice‑to‑have.

---

### A. Strengthen the Identification Strategy  

1. **Adopt the Monthly VIIRS Panel**  
   - Download the monthly VIIRS Black Marble (VNP46A1) composites for the full sample period (2012‑2024).  
   - Construct a **district‑month** panel.  This will dramatically increase the variation in treatment timing (many shutdowns occur within a single month) and allow you to detect short‑run effects.  
   - A monthly specification also permits an **event‑study** around the exact shutdown dates, showing pre‑trend dynamics and post‑shutdown recovery.

2. **Event‑Study with Leads and Lags**  
   - Estimate a flexible dynamic model:  
     \[
     \log(NTL_{dmt}) = \sum_{k=-K}^{L}\beta_k \, \mathbf{1}\{t = \text{shutdown month} + k\} + \alpha_d + \delta_{s(d),m} + \varepsilon_{dmt}
     \]  
   - Plot the coefficients to verify parallel trends and to assess how quickly the shock dissipates.  This visual evidence is now standard in AER‑Insights and will directly address the “pre‑trend” concern.

3. **Leverage Exam Calendars for a Clean RD/DiD**  
   - For each exam‑triggered shutdown, define the exact exam date as the **cut‑off** and use a **short‑window DiD** (e.g., three months before vs. three months after).  Because the exam schedule is predetermined and public, you can treat the shutdown as *as‑if* random within that narrow window.  
   - If possible, exploit the fact that some districts are selected for a shutdown while neighboring districts are not, creating a **spatial RD** around the administrative boundary.

4. **Neighbour‑District Placebo (Spatial Counterfactual)**  
   - Construct a “treated‑control” pair: a district that experiences a shutdown and its immediate neighbour that does **not**, but shares the same state‑year shock (e.g., same conflict intensity).  
   - Estimate the effect using a **matched difference‑in‑differences** or a **synthetic control** approach for each pair.  This will help isolate the shutdown effect from the underlying conflict.

5. **Alternative Fixed Effects Structures**  
   - In addition to state‑year FE, consider **state‑month** or **district‑trend** controls to soak up any gradual divergence across districts.  Test the robustness of results to these alternatives.

---

### B. Refine the Treatment Variable  

1. **Switch from “Shutdown Days” to “Shutdown Hours”**  
   - The source tracker provides start‑ and end‑times; aggregating to **hours** preserves variation, especially for short shutdowns (e.g., 6‑hour curfews).  
   - Create a continuous *intensity* measure (hours/ (30 days × 24 h)) that can be interacted with service‑type dummies.

2. **Distinguish Service Types**  
   - Separate **mobile‑only**, **broadband‑only**, and **full‑blackout** events.  Prior evidence suggests mobile data is the primary conduit for commerce; testing these categories will reveal which component drives the economic loss.

3. **Incorporate Baseline Digital Penetration**  
   - Use TRAI’s district‑level broadband and mobile subscription statistics (or mobile‑phone density from Censuses) as a baseline.  Interact shutdown intensity with this variable to test whether more‑connected districts suffer larger (or smaller) luminosity drops.

4. **Account for Over‑lapping Shutdowns**  
   - Some districts experience multiple overlapping events in a year.  Build a **cumulative exposure** variable that respects overlap (e.g., hours summed but capped at 24 × days in the month).

---

### C. Expand Heterogeneity and Mechanism Analyses  

1. **Dose‑Response with More Granular Bins**  
   - Instead of the coarse quartiles (1‑3, 4‑10, 11‑50, 50+ days), use bins that reflect the **monthly** distribution (e.g., 0‑1 day, 2‑7 days, 8‑30 days, > 30 days).  This will improve statistical power and interpretability.

2. **Spillover Effects**  
   - Identify districts that are **telecom‑connected** (e.g., via major highways or shared internet exchange points).  Test whether a shutdown in district *i* reduces night‑lights in neighboring *j* after controlling for *j*’s own shutdown status.

3. **Sectoral Sensitivity**  
   - If available, merge in district‑level economic structure variables (e.g., share of service sector, share of agriculture) from the Economic Census.  Interact these shares with shutdown intensity to see whether service‑heavy districts are more vulnerable.

4. **Alternative Outcome Measures**  
   - As a robustness check, supplement night‑lights with **high‑frequency economic proxies**:  
     - Real‑time transaction data (e.g., digital payments from RBI or private aggregators).  
     - Agricultural market price volatility (e‑NAM data).  
     - Mobile‑phone call detail records (CDR) for mobility changes (if accessible).  
   - Even a limited subsample can corroborate the night‑light findings for short shutdowns.

---

### D. Presentation and Technical Improvements  

1. **Clarify Sample Construction**  
   - Explain why the period starts in 2014 and not 2012, and why the analysis stops at 2022 when shutdown data extend to 2024.  If data for later years are unavailable for night‑lights, note it explicitly.

2. **Consistent Treatment Definition Across Tables**  
   - Table 1 mixes “any shutdown” (binary) and “shutdown intensity” (continuous) without a clear narrative.  Structure the results so that each specification builds on the previous one (e.g., binary → intensity → interaction → heterogeneity).

3. **Standard Errors and Clustering**  
   - Given the strong spatial correlation of both treatment and outcome, cluster at the **state** level (or use two‑way clustering: district and state) as a robustness check.  Report both sets of SEs.

4. **Placebo Tests**  
   - Extend the placebo test beyond a simple pre‑trend coefficient.  Run a “false‑treatment” exercise where you randomly assign shutdown dates to districts and verify that the estimated effect distribution centers on zero.

5. **Interpretation of Coefficients**  
   - Translate the log‑light changes into **percent changes in economic activity** using the elasticity from Henderson et al. (2012).  This will make the policy relevance more tangible.

6. **Discussion of External Validity**  
   - The paper should elaborate on how results from India may generalize (or not) to other settings where shutdowns are imposed under different legal frameworks or where baseline digital dependence is lower.

7. **Minor Formatting**  
   - Fix a few typographical inconsistencies (e.g., “J\&K” vs. “Jammu & Kashmir”).  
   - Ensure all tables report **Within R²** and **Number of clusters** for transparency.  
   - Provide a concise schematic (flowchart) of the identification strategy for the reader.

---

### E. Re‑framing the Contribution  

Given the substantial revisions above, the paper can more convincingly claim to provide the *first causal* estimate of the economic cost of internet shutdowns.  Emphasize that the **dose‑response relationship**, once identified with higher‑frequency data and stronger exogenous variation, directly informs the proportionality debate in the Supreme Court and offers a benchmark for cost‑benefit analyses worldwide.

---

**In sum**, the manuscript tackles an important and timely question, but as it stands it falls short of the rigorous causal design outlined in the original manifest.  By (i) adopting the monthly VIIRS panel, (ii) implementing event‑study and neighbour‑district analyses, (iii) exploiting the exogenous exam calendar more fully, and (iv) enriching the heterogeneity checks, the authors can transform the paper from a descriptive correlation exercise into a solid causal contribution worthy of AER‑Insights.  I look forward to a revised version that incorporates these suggestions.
