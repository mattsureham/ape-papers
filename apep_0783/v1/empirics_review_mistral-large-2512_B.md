# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-23T10:18:17.711698

---

### 1. **Idea Fidelity**
The paper closely adheres to the original idea manifest. It leverages the POStPlan’s dose-response variation (2/4/6-hour reductions) to estimate causal effects on rural business formation using Census BFS county-level data, as proposed. Key elements—such as the AWEL-based assignment, continuous treatment DiD, and rural vs. urban heterogeneity—are all preserved. The paper even expands on the manifest by incorporating additional robustness checks (e.g., state-by-year fixed effects, placebo tests) and secondary outcomes (e.g., money order volume, though not fully explored). No critical deviations from the original design are evident.

---

### 2. **Summary**
This paper exploits the 2012–2015 USPS POStPlan—a policy reducing operating hours at 13,387 rural post offices—to estimate its causal impact on business formation. Using a dose-response difference-in-differences (DiD) design, the authors find that affected counties experienced a 7.7% decline in business applications, with effects growing over time and scaling with the intensity of hour reductions. The results are robust to state-by-year fixed effects and placebo tests, suggesting that physical postal infrastructure remains a binding constraint on rural entrepreneurship despite digital alternatives.

---

### 3. **Essential Points**
The paper is methodologically sound and makes a compelling contribution, but three critical issues must be addressed to solidify its causal claims:

1. **Confounding from AWEL-Based Targeting**
   The POStPlan’s assignment mechanism (AWEL scores) is correlated with office size and community economic health. While the authors argue that dose-response variation *within* treated counties mitigates this, the paper must:
   - **Explicitly test for balance** on pre-treatment covariates (e.g., population, income, broadband access, bank branches) across dose groups. If AWEL is predictive of these covariates, the parallel trends assumption may be violated.
   - **Include controls for pre-treatment trends** in these covariates (e.g., interacted with year fixed effects) to rule out differential shocks.

2. **Ecological Inference and Treatment Heterogeneity**
   The county-level treatment measure (average hours lost per PO) aggregates heterogeneous effects. The paper should:
   - **Disaggregate treatment to the ZIP level** (where possible) to test whether effects are concentrated in areas with higher reliance on post offices (e.g., ZIPs with fewer bank branches or lower broadband access).
   - **Clarify the mechanism** by testing whether the effect is driven by specific services (e.g., PO box issuance, certified mail) using auxiliary data (e.g., USPS money order volume, FDIC branch exits).

3. **State-by-Year Fixed Effects Attenuation**
   The inclusion of state-by-year fixed effects reduces the estimate by ~50% (from -7.7% to -3.3%), suggesting that much of the variation is between states. The authors should:
   - **Justify why state-by-year FE are necessary** (e.g., are there state-specific policies that confound the results?) and discuss whether the remaining within-state variation is plausibly exogenous.
   - **Report event studies with state-by-year FE** to ensure parallel trends hold under this stricter specification.

---

### 4. **Suggestions**

#### **Conceptual and Theoretical Improvements**
1. **Mechanism Clarity**
   - The paper posits that reduced hours limit access to PO boxes, certified mail, and money orders, but it does not test these channels directly. Suggestions:
     - **Leverage USPS money order data** (mentioned in the manifest but unused in the paper) to test whether declines in money order volume correlate with business formation drops.
     - **Use FDIC branch exit data** to test whether post office hour reductions have larger effects in ZIPs with fewer bank branches (a proxy for financial service access).
     - **Add a theoretical model** (even a simple one) to formalize how postal hour reductions increase transaction costs for entrepreneurs.

2. **Heterogeneity Analysis**
   - The paper focuses on rural vs. urban heterogeneity but could explore other dimensions:
     - **Industry composition**: Are effects larger in sectors reliant on physical mail (e.g., e-commerce, legal services)?
     - **Broadband access**: Do effects attenuate in counties with high broadband penetration (using ACS data)?
     - **Population density**: Test whether effects are nonlinear in density (e.g., using a spline or binscatter).

3. **External Validity**
   - The POStPlan’s geographic concentration (Great Plains/Mountain West) limits generalizability. The authors should:
     - **Discuss whether similar effects would be expected in other regions** (e.g., Appalachia, the South) with different economic structures.
     - **Compare to other postal service contractions** (e.g., UK’s post office closures) to contextualize the magnitude.

#### **Empirical and Robustness Improvements**
4. **Alternative Specifications**
   - **Dynamic DiD**: The event study shows growing effects, but the main specification assumes a static treatment effect. Estimate a dynamic DiD (e.g., Callaway & Sant’Anna 2021) to account for staggered adoption and heterogeneous effects over time.
   - **Synthetic Control**: For high-dose counties (e.g., North Dakota), construct synthetic controls to validate the DiD results.
   - **Wild Bootstrap**: Given the small number of state clusters (51), report wild bootstrap p-values for the main results.

5. **Data and Measurement**
   - **Treatment Definition**: The county-level dose measure (average hours lost) may obscure heterogeneity. Consider:
     - **Alternative aggregations**: e.g., total hours lost per capita or per square mile.
     - **Binary treatment at the ZIP level**: Estimate effects for ZIPs with at least one treated PO (if data permits).
   - **Outcome Definition**: Business applications include non-employer firms. Test whether effects differ for employer vs. non-employer applications (if data is available).

6. **Placebo and Falsification Tests**
   - **Alternative Placebos**: The paper uses a 2009 placebo date but could also:
     - **Test for effects on unrelated outcomes** (e.g., agricultural employment, which should not be affected by postal hours).
     - **Use unaffected POs as placebos**: Compare counties with only Level 18 (unaffected) POs to those with no POStPlan POs.
   - **Lead-Lag Tests**: Extend the event study to include more pre-treatment leads (e.g., 10 years) to further assess parallel trends.

7. **Presentation and Transparency**
   - **Table Clarity**:
     - In Table 1, report standard deviations for all dose groups (currently missing for low/medium/high).
     - In Table 3 (event study), add a figure to visualize the coefficients (e.g., using `coefplot`).
   - **Replication Package**: Ensure the GitHub repository includes:
     - Cleaned datasets (POStPlan, BFS, FDIC SOD).
     - Code for all robustness checks (including those not reported in the paper).
     - A README with step-by-step replication instructions.

8. **Policy Implications**
   - **Cost-Benefit Analysis**: The paper notes that POStPlan saved $500M annually but does not quantify the economic cost of reduced business formation. Suggestions:
     - **Estimate the lost tax revenue** from fewer businesses (using IRS SOI data on average business tax contributions).
     - **Compare to other rural development policies** (e.g., broadband subsidies) to contextualize the magnitude.
   - **Heterogeneous Effects by Political Geography**: Test whether effects differ in counties with higher support for USPS funding (e.g., using election data) to inform policy debates.

#### **Minor Suggestions**
- **Abstract**: Clarify that the 7.7% decline is relative to *unaffected* counties (not pre-treatment levels).
- **Introduction**: Add a sentence on why digital alternatives (e.g., online certified mail) are imperfect substitutes (e.g., legal requirements, unbanked populations).
- **Discussion**: Address whether the COVID-era surge in home-based businesses (mentioned in the event study) biases the results. Consider restricting the sample to pre-2020 for a cleaner analysis.
- **Appendix**: Include a map of treatment intensity by county to help readers visualize geographic variation.

---

### **Final Assessment**
This is a strong paper with a novel identification strategy and policy-relevant findings. The core results are robust, but the three essential points above must be addressed to rule out confounding and strengthen causal claims. With these revisions, the paper would make a significant contribution to the literature on rural entrepreneurship and infrastructure. **Revise and resubmit.**
