# V1 Empirics Check — openai/gpt-5.4 (Variant C)

**Model:** openai/gpt-5.4
**Variant:** C
**Date:** 2026-04-01T12:33:55.185286

---

## 1. **Idea Fidelity**

The paper only partially pursues the original idea in the manifest, and it misses the most important pieces of the proposed design.

First, the manifest’s core identification strategy was **county-level cumulative Hill-Burton funding (1947–1971)**, ideally exploiting **within-state variation from county bed deficiency and project placement**. The paper instead uses **inverse 1950 state per-capita income** as the instrument. That is a much weaker and much less credible design. It collapses the proposed historical policy variation to a single state-level proxy and abandons the key “within-state” component that was supposed to make the design plausible.

Second, the manifest proposed constructing hospital concentration from **hospital service area/discharge-based market shares**. The paper instead uses a very crude **county-level equal-share HHI = 10,000/N**. That is not really a hospital market concentration measure in the antitrust or industrial organization sense; it is essentially a transformed hospital count. It ignores cross-county patient flows, hospital size, system membership, and actual market shares.

Third, the manifest framed the contribution as a causal estimate of the effect of concentration on Medicare spending. The paper itself ultimately concedes that the instrument is badly imbalanced and should be read only as “bounding the direction of bias.” That is a substantial retreat from the original question.

So: the paper follows the broad topic, but not the original empirical design. In my view, that matters a lot here, because the substitutions made are exactly the ones that undermine credibility.

## 2. **Summary**

This paper studies whether more concentrated hospital markets have higher Medicare spending per beneficiary. Using county-level cross-sectional data for 2019, it finds a negative OLS relationship between concentration and spending, but a positive 2SLS relationship when concentration is instrumented with inverse 1950 state income, interpreted as a proxy for Hill-Burton-era hospital construction.

The main value of the paper is diagnostic rather than causal: it shows that naive cross-sectional correlations are likely contaminated by strong rural selection. However, the IV strategy is not credible enough, and the market structure measure is too coarse, for the paper to deliver a clear, economically meaningful estimate suitable for AER: Insights in its current form.

## 3. **Essential Points**

1. **The IV is not credible as implemented.**  
   The instrument is state-level historical income, not county-level Hill-Burton placement or funding. It is strongly correlated with current poverty, race, and health risk, and the paper openly acknowledges this. At that point, the exclusion restriction is not “threatened”; it is largely unpersuasive. Moreover, because the instrument varies at the state level, the identifying variation is between states, exactly where long-run differences in medical practice, provider mix, public health, and demographics are most severe. This is the central problem.

2. **The concentration measure is too crude to support the claims.**  
   Equal-share county HHI is not a serious measure of hospital concentration. It is mostly a nonlinear transformation of the number of hospitals in the county, and counties are not hospital markets. The paper excludes zero-hospital counties, includes CAHs and VA hospitals as equivalent competitors, and ignores actual discharge shares and patient travel. The result is that the treatment is poorly measured, making magnitudes hard to interpret economically.

3. **Inference and interpretation are not appropriate for a state-level instrument.**  
   The IV standard errors should be clustered at the level of instrument variation, i.e. the state. Heteroskedasticity-robust county-level SEs are not appropriate when the regressor of interest is instrumented with a state-level variable. With roughly 48–51 effective clusters, the paper should report state-clustered or wild-cluster-bootstrap inference throughout the IV analysis. More broadly, the paper cannot claim a causal effect and then fall back to “bounds the direction of bias” while still emphasizing the 3.1 percent elasticity as a substantive result.

## 4. **Suggestions**

The paper has an interesting question, and there is likely a publishable paper somewhere in this neighborhood, but it needs a major redesign. My suggestions are below.

**1. Go back to the original Hill-Burton design.**  
This is the most important recommendation. If you want this paper to work, you need the actual Hill-Burton exposure measure: county-level projects, dollars, beds added, or some pre-period deficiency-based predicted allocation. The manifest was right to focus on the **Project Register** and on **within-state allocation rules tied to bed shortages**. That is the promising source of quasi-exogenous variation. A state-level inverse-income proxy is simply too blunt.

A strong version of the design would look something like:
- construct cumulative Hill-Burton project intensity by county, 1947–1971;
- distinguish new hospitals from renovations/additions;
- normalize by pre-period population or perhaps predicted need;
- control flexibly for 1940/1950 county characteristics;
- exploit within-state variation, ideally with state fixed effects;
- show that Hill-Burton exposure predicts persistent hospital presence/capacity today.

If you can recover the statutory formula and county deficiency measures, even a shift-share or “predicted Hill-Burton funding” design would be much more compelling than current state income.

**2. Replace the equal-share county HHI with a real market concentration measure.**  
This is a second-order issue only relative to the IV problem; it is still crucial. The current HHI is not convincing. You should use actual hospital market shares based on discharges, admissions, or patient flows. The CMS Hospital Service Area file or AHRQ market files mentioned in the manifest are much better suited for this. At minimum:
- define markets using HSAs, HRRs, or patient-flow-based catchments rather than counties;
- calculate HHI from actual discharge shares;
- consider system-adjusted concentration, since common ownership matters;
- report the relationship between your equal-share HHI and a true share-based HHI to show how much error you are introducing.

Right now, “10 percent increase in HHI” is not very meaningful because the underlying measure is so stylized. The fact that the median county has one hospital already tells you the measure is basically encoding rurality.

**3. Re-think the unit of observation and the sample restriction.**  
Excluding zero-hospital counties is consequential and not innocuous. Those counties are a meaningful part of the equilibrium: patients travel out of county, and local hospital absence is itself part of market structure. By dropping them, you induce a selected sample whose interpretation is unclear. If you move to HSAs or commuting zones, this issue becomes much less severe. If you stay with counties, you need to discuss selection explicitly and show how results change when assigning residents to nearest-hospital markets rather than dropping counties.

**4. Fix the inference throughout the IV analysis.**  
Because the instrument varies at the state level, the default should be:
- state-clustered SEs for all IV specifications;
- ideally wild-cluster-bootstrap p-values given the small number of clusters;
- discussion of effective degrees of freedom.

The current first-stage F-statistic of 28.2 is also not the whole story. With clustered inference and highly aggregated instrument variation, weak-instrument diagnostics can look quite different. Please report the relevant Kleibergen-Paap or Montiel Olea–Pflueger diagnostics under the actual covariance structure used for inference.

**5. Be much more disciplined about interpretation of magnitudes.**  
The paper’s own estimates signal that the design is not isolating a plausible causal effect. The binary IV estimate implying that moving from monopoly to “competitive” reduces Medicare spending by **46 percent** is not just “strains credulity”; it essentially tells you the design is picking up broad regional differences rather than hospital competition. Even the preferred elasticity of 0.311 deserves more scrutiny. Given the outcome is price-standardized Medicare spending, the implied mechanism must be utilization, coding intensity, site-of-service shifts, or composition of providers. You should quantify whether a 3 percent spending increase from a 10 percent HHI increase is consistent with known effects in the Medicare competition literature. As written, the paper gestures at mechanisms without showing they can plausibly generate the observed magnitude.

A useful discipline would be to benchmark your estimate against:
- Kessler-McClellan style competition effects for Medicare populations;
- merger studies examining quantity or coding responses under Medicare;
- descriptive gradients in outpatient site-of-service spending.

If the implied effects are much larger than those literatures, say so clearly.

**6. The “bounds” language is too loose and should be tightened or dropped.**  
The paper repeatedly says OLS is a lower bound and IV an upper bound. That is not established. For that statement to be meaningful, you need signed assumptions on both OLS and IV biases. The paper provides intuition, but not an identification argument. In particular, once the instrument is correlated with long-run state characteristics affecting spending, the sign of IV bias is not obvious enough to justify “upper bound” language as a formal claim. I would recommend rewriting this as: *the sign reversal is suggestive of substantial negative selection in OLS, but the IV estimate is not interpretable as a credible upper bound without stronger assumptions.*

**7. The controls deserve more thought.**  
Some controls may themselves be downstream of the historical instrument. Current poverty, dual share, and HCC risk are not obviously “safe” controls in a seventy-year historical IV design. Conditioning on them may remove part of the very channel through which historical underdevelopment affects current health care supply and spending, while leaving other correlated channels intact. I would like to see a sequence of specifications:
- parsimonious historical controls only;
- addition of predetermined county covariates from 1940/1950;
- then contemporary controls as sensitivity checks, not as baseline.

That would make the design more coherent.

**8. Use more informative falsification and mechanism tests.**  
The placebo exercise is a good instinct, but not yet persuasive. DME and home health are not ideal placebos if broader regional medical practice styles also affect them. Better falsifications would exploit outcomes less tied to hospital competition but measured in the same data environment. If you obtain true Hill-Burton exposure, I would also want:
- pre-trend or event-study style evidence on hospital entry/persistence;
- effects on number of beds, occupancy, or hospital presence;
- heterogeneous first-stage effects by county baseline bed deficiency;
- stronger effects on hospital-intensive Medicare categories than on physician-only categories.

**9. Clean up several internal inconsistencies.**  
A few details weaken confidence:
- The paper says Hill-Burton funded “nearly 6,800” facilities, while the manifest said around 11,000 projects; that discrepancy should be resolved.
- The first stage sign discussion is confused.
- Column (5) “over-ID” uses log 1950 income in addition to its inverse; these are not conceptually distinct instruments. Over-identification here is not informative.
- The outcome is 2019 spending, but hospital data are from 2024. You argue little changed, but you should verify that, especially after COVID-era closures and consolidations.

These are fixable, but they matter.

**Bottom line:** the topic is good, and the sign reversal is interesting, but the current paper does not yet deliver a credible, economically interpretable result. The promising path is to return to the original idea: actual Hill-Burton county exposure, within-state variation, and a genuine patient-flow-based concentration measure. Without that, the paper reads more like a cautionary note about cross-sectional rural selection than a persuasive IV study of hospital concentration and Medicare spending.
