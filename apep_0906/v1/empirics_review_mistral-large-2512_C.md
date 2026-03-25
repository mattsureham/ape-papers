# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-03-25T11:57:00.595284

---

### 1. Idea Fidelity

The paper largely adheres to the original idea manifest but deviates in two critical ways:

- **Treatment Intensity**: The manifest proposed a **continuous treatment intensity** measure (change in Neo-Panamax vessel port calls from AIS data) as the core identification strategy. The paper instead uses a **binary DiD** (East/Gulf vs. West Coast), relegating the continuous intensity measure to a secondary robustness check (Table 2, Column 2). This is a missed opportunity—the AIS data was the novel contribution, and its underutilization weakens the paper’s claim to methodological innovation. The binary DiD is standard; the continuous intensity approach would have been a true advance.

- **Data Scope**: The manifest promised **20 port counties** (15 East/Gulf + 5 West Coast) with **80 quarters** of data (2000–2020). The paper uses **26 counties** (22 East/Gulf + 4 West Coast) and **56 quarters** (2010–2023). The shorter panel is defensible (pre-trends are flat), but the exclusion of one West Coast county (e.g., San Diego) without explanation is odd. The manifest’s "smoke test" showed LA County employment growing 20.2% post-expansion, but the paper’s summary stats show West Coast growth from 56,911 to 74,522 (+30.9%). This discrepancy suggests either a coding error or a change in sample composition that needs justification.

### 2. Summary

The paper exploits the 2016 Panama Canal expansion as a natural experiment to test whether the redirection of trans-Pacific trade from West to East/Gulf Coast ports affected local transport employment. Using a binary DiD design with Census QWI data, it finds **counterintuitive results**: East/Gulf Coast ports experienced **13.7% lower employment growth**, **29.1% fewer new hires**, and **8.3% lower earnings growth** relative to West Coast ports post-expansion. The results are robust to pre-trend tests, leave-one-out analysis, and placebo industry checks. The paper argues that logistics network lock-in, West Coast automation, and transit time advantages explain the persistence of West Coast dominance despite the canal’s expanded capacity.

### 3. Essential Points

**1. Magnitudes Are Implausibly Large and Economically Puzzling**
   - A **13.7% relative decline** in transport employment at East/Gulf ports is **too large** given the modest expected traffic diversion (5–10% market share shift, per USACE 2012). The paper’s own summary stats show East/Gulf employment *grew* post-expansion (15,632 → 19,936), just slower than West Coast (56,911 → 74,522). A 13.7% *relative* decline implies East/Gulf ports would have needed to grow **~45% faster** to match West Coast growth—a wildly unrealistic counterfactual.
   - The **29.1% drop in new hires** is even harder to reconcile with the narrative. If East/Gulf ports were expanding capacity (e.g., Savannah’s harbor deepening), why would hiring *fall*? The paper suggests automation at West Coast ports as a mechanism, but this should manifest as slower employment growth, not outright declines in hiring.
   - **Suggestion**: Re-estimate the DiD using **absolute employment levels** (not logs) to assess whether the relative decline masks modest absolute growth. Also, plot the raw employment trends for treated vs. control ports to visually assess the plausibility of the effect size.

**2. The Binary DiD Is Too Coarse; Continuous Treatment Intensity Is Underused**
   - The manifest’s key innovation was a **Bartik-style continuous treatment** based on AIS vessel data. The paper buries this in Column 2 of Table 2, where the coefficient is positive but insignificant. This is a **major omission**:
     - The AIS data could measure **actual Neo-Panamax port calls** (not just potential access), allowing a test of whether ports with *higher* post-expansion traffic saw *larger* employment effects.
     - The binary DiD assumes all East/Gulf ports were equally "treated," but ports like Savannah (major investments) and Brunswick (minor) likely experienced different traffic shifts. The continuous measure would capture this heterogeneity.
   - **Suggestion**: Make the AIS-based intensity measure the **primary specification**. Show event studies for high- vs. low-intensity ports. If the effect is driven by a few ports (e.g., Savannah), the binary DiD is misleading.

**3. The West Coast "Control Group" Is Problematic**
   - The paper treats West Coast ports as controls, but they were **not unaffected** by the canal expansion. The manifest notes that West Coast ports **automated in response to the threat** of competition. If automation reduced labor demand, the DiD’s "control" group is contaminated, biasing the estimate toward finding a negative effect for East/Gulf ports.
   - **Suggestion**:
     - Test for **pre-trends in automation-related outcomes** (e.g., capital investment, productivity) at West Coast ports. If automation accelerated post-2016, the control group is invalid.
     - Use **inland counties** (as mentioned in the manifest) as an alternative control group. These counties were exposed to the same macroeconomic trends but not to port-specific shocks.

### 4. Suggestions

**A. Improve the Empirical Strategy**
1. **Prioritize the AIS-based continuous treatment**:
   - Construct a **port-level measure of Neo-Panamax traffic** (e.g., share of port calls by vessels >32.3m beam) using AIS data. Merge this with QWI data at the county level.
   - Estimate a **Bartik-style specification**:
     \[
     \log(Y_{ct}) = \alpha_c + \gamma_t + \beta (\text{PreShare}_{c} \times \Delta \text{NeoPanamax}_{ct}) + \varepsilon_{ct}
     \]
     where \(\text{PreShare}_{c}\) is the port’s pre-2016 share of US container traffic, and \(\Delta \text{NeoPanamax}_{ct}\) is the change in Neo-Panamax calls post-2016. This captures the idea that ports with higher pre-existing capacity were better positioned to benefit from the expansion.
   - Show **event studies for high- vs. low-intensity ports** to assess heterogeneity.

2. **Address control group contamination**:
   - Test whether West Coast ports **automated more post-2016** (e.g., using capital expenditure data or productivity measures). If so, the control group is invalid.
   - Use **inland counties** (e.g., counties in the Midwest with no port activity) as an alternative control group. These counties were exposed to the same macroeconomic trends but not to port-specific shocks.

3. **Clarify the unit of analysis**:
   - The paper treats **counties** as the unit of analysis, but some counties contain multiple ports (e.g., LA County includes Long Beach). This could bias results if the county’s employment is dominated by a single port. Consider **port-level analysis** (though QWI data is county-level, so this may not be feasible).
   - Alternatively, **weight observations by port throughput** to ensure larger ports drive the results.

**B. Strengthen the Mechanisms**
1. **Test the automation hypothesis directly**:
   - Obtain data on **automation investments** at West Coast ports (e.g., from port authority reports or news articles). If automation accelerated post-2016, this supports the paper’s mechanism.
   - Estimate a **triple-difference** specification:
     \[
     \log(Y_{ct}) = \alpha_c + \gamma_t + \beta (\text{EastGulf}_c \times \text{Post}_t) + \delta (\text{Automation}_{ct} \times \text{Post}_t) + \varepsilon_{ct}
     \]
     where \(\text{Automation}_{ct}\) is a measure of automation at port \(c\) in quarter \(t\). If \(\delta\) is negative, it suggests automation reduced labor demand at West Coast ports, biasing the DiD estimate.

2. **Assess logistics network lock-in**:
   - Use **rail freight data** (e.g., from the Surface Transportation Board) to test whether East/Gulf ports saw **slower growth in intermodal rail connections** post-2016. If so, this supports the lock-in mechanism.
   - Survey **supply chain managers** (or use trade press articles) to document switching costs for rerouting imports from West to East Coast.

3. **Examine transit time trade-offs**:
   - Use AIS data to calculate **actual transit times** from Shanghai to East vs. West Coast ports pre- and post-expansion. If all-water routes through the canal are slower, this could explain why importers stuck with West Coast ports for time-sensitive goods.

**C. Address Plausibility Concerns**
1. **Reconcile effect sizes with traffic data**:
   - Obtain **port throughput data** (e.g., from the Bureau of Transportation Statistics) to compare employment trends with actual container volumes. If East/Gulf ports saw **modest traffic growth** but **large employment declines**, this suggests productivity gains (e.g., automation) rather than a failure of the canal expansion.
   - Plot **employment per TEU** over time for treated vs. control ports. If the ratio falls for East/Gulf ports, it suggests they became more labor-efficient post-expansion.

2. **Check for coding errors**:
   - The manifest’s "smoke test" showed LA County employment growing 20.2% post-expansion, but the paper’s summary stats show 30.9% growth. This discrepancy suggests a **sample composition issue** (e.g., inclusion/exclusion of certain counties or time periods). Recheck the data construction.
   - Verify that the **log transformation** is appropriate. With employment counts, a **Poisson or negative binomial model** may be more suitable than OLS on logs.

3. **Clarify the counterfactual**:
   - The paper’s interpretation hinges on the idea that East/Gulf ports "should have" grown faster. But if West Coast ports were **already operating at capacity**, the canal expansion may have simply **relieved congestion** at West Coast ports, allowing them to grow faster. This would explain the relative decline in East/Gulf employment without implying the expansion "failed."
   - Test this by examining **congestion measures** (e.g., vessel wait times) at West Coast ports pre- and post-expansion.

**D. Improve Presentation**
1. **Add a map**:
   - Include a **map of US port counties** with treatment/control labels and pre/post employment growth rates. This would help readers visualize the geographic variation.

2. **Show raw trends**:
   - Plot **raw employment trends** for treated vs. control ports (with 95% CIs) to visually assess the DiD parallel trends assumption. The event study is good, but raw trends are more intuitive.

3. **Clarify the "null result" framing**:
   - The paper frames the results as a "null" (i.e., the expansion didn’t work), but the effects are **statistically significant and large**. A better framing might be: "The canal expansion had **unexpected distributional consequences**, benefiting West Coast ports despite the redirection of traffic."

4. **Discuss external validity**:
   - The paper’s results contrast with studies like Feyrer (2019) and Brancaccio et al. (2020), which find large effects of trade infrastructure on economic outcomes. Discuss why the Panama Canal case might differ (e.g., US ports are already highly developed, so marginal capacity expansions have smaller effects).

### Final Verdict

The paper’s **core finding**—that the Panama Canal expansion did not redistribute port employment as expected—is **economically important** and **methodologically sound** in its current form. However, the **effect sizes are implausibly large**, the **binary DiD is too coarse**, and the **control group is contaminated**. With revisions to address these issues (especially the continuous treatment intensity and control group concerns), the paper could make a **strong contribution** to the literature on trade infrastructure and local labor markets.

**Recommendation**: Revise and resubmit, with the following priorities:
1. Make the AIS-based continuous treatment the **primary specification**.
2. Address control group contamination (e.g., by using inland counties or testing for automation at West Coast ports).
3. Reconcile the effect sizes with traffic data and raw employment trends.
