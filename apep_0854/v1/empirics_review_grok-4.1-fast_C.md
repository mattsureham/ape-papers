# V1 Empirics Check — x-ai/grok-4.1-fast (Variant C)

**Model:** x-ai/grok-4.1-fast
**Variant:** C
**Date:** 2026-03-24T16:59:15.950810

---

### 1. Idea Fidelity
The paper deviates substantially from the original idea manifest. The manifest promised an RDD at EIP quota thresholds using block-level binding constraints (treatment: constrained blocks with restricted buyer pools) and a running variable defined as distance between subzone ethnic proportions and EIP limits, drawing on 226,800 resale transactions (2017-2026) matched to Census 2020 *subzone* ethnic composition across 332 subzones. It explicitly aimed to test convergence of Wong's (2013) 3-5% minority discount toward zero via temporal extension. Instead, the paper aggregates to 24-26 coarse planning areas, relies primarily on hedonic OLS with planning-area minority share (no distance-to-threshold running variable), mentions an RDD at the Indian 10% threshold but does not tabulate results or validate it properly, and omits direct block-level identification or Wong comparisons. The core research question on EIP-eroded preferences via quota-binding is diluted into a generic hedonic gradient without exploiting policy variation.

### 2. Summary
This paper estimates a large negative hedonic price gradient with respect to planning-area minority (Malay+Indian+Others) share in Singapore's HDB resale market using 219k transactions (2017-2026), finding a ~33% decline in the gradient's magnitude over time ($p=0.004$ trend test). It interprets partial convergence as evidence for the contact hypothesis eroding ethnic preferences after 35 years of EIP-mandated mixing. A supplementary RDD at the Indian quota threshold is referenced but not fully executed, leaving identification reliant on planning-area fixed effects and controls.

### 3. Essential Points
1. **Implausibly large magnitudes undermine credibility.** The baseline $\beta \approx -1.3$ implies a 100pp rise in minority share cuts prices by 130% (or 13% per 10pp), far exceeding Wong's (2013) 3-5% benchmark and economic intuition—comparable to losing half the city's housing stock. Standardized effect sizes ($|$SDE$|>3.7$) are off-the-charts large relative to log-price SD(0.34), suggesting omitted variables (e.g., school quality, CBD proximity) correlated with ethnic composition rather than causal preferences. Authors must rescale interpretations (e.g., explicitly compute per-10pp effects) and benchmark against Wong or include spatial fixed effects (e.g., subzone FE) to bound omitted bias.

2. **Unreliable standard errors with only 24 clusters.** Clustering at the planning-area level (24 clusters) severely underpowers inference: effective df $\approx 23$, inflating Type I errors and rendering $p$-values meaningless without wild cluster bootstrap (e.g., Radelet-Wooldridge). Year-specific estimates exacerbate this (fewer obs/clusters per year). Must re-estimate all SEs via wild bootstrap (500+ reps) or collapse to block-level with more clusters; failure to do so invalidates all significance claims, including the $p=0.004$ trend.

3. **Missing core RDD implementation and block-level variation.** The manifest's key ID—RDD at block quota thresholds—is absent; the paper's "RDD" at planning-area Indian share (10%) uses coarse geography (26 areas, few near cutoff), lacks density/manipulation tests beyond text, and shows no results table/graph. Hedonics cannot credibly isolate EIP constraints from sorting/amenities. Must implement block-level RDD (feasible with data.gov.sg block IDs and ~33% constrained blocks) or explicitly motivate why planning-area aggregates suffice, with McCrary/Density tests.

### 4. Suggestions
**Data and Measurement Improvements (Priority High):** 
- Disaggregate to subzone (332) or block level per manifest/Census 2020—planning areas (24) average ~10km², too coarse for "neighborhood" effects; match transactions' block/street to subzones via geocoding (e.g., OneMap API) for precise ethnic shares and quota distances. Compute *block-specific* constraint status (e.g., dummy for binding Chinese/Malay/Indian quotas using HDB quota rules) and interact with minority share.
- Construct running variable as |subzone ethnic share - EIP limit| (e.g., for Indians: |Indian% - 0.10|), binning transactions into "near-threshold" samples for RDD. Validate with ~75k "treated" transactions in constrained blocks as pre-registered.
- Harmonize with Wong (2013): Replicate her 3-5% discount using 2017-2026 data (e.g., via name-matching if feasible) for direct pre/post-EIP comparison; plot evolution from 1990s to now.
- Add time-varying ethnic shares: Census 2020 is static; interpolate via prior censuses (2010, 2000) or annual SingStat estimates to capture EIP-induced demographic shifts.

**Empirical Strategy Enhancements:**
- **Hedonic Extensions:** Saturate with subzone FE (or planning subzone×year FE) to absorb all time-invariant/mean-reverting unobservables; add quadratic distance-to-CBD, MRT access, school rankings (public data), and green space % to proxy amenities. Test functional form: spline minority share or separate Malay/Indian gradients (heterogeneous prejudice).
- **RDD Execution:** Fully tabulate rdrobust results (local poly order 1-3, MSE/CV bandwidths, bias-reduced linear); plot binned scatter/Density/McCrary with planning areas weighted by transaction volume. Use block-level Indian share for finer RDD (more mass at 10%). Cluster at block or wild bootstrap.
- **Convergence Test Refinements:** Replace year-specific OLS with fully interacted model: $\beta_y = \beta_0 + \beta_1 \cdot (y-2017)$; test $\beta_1 >0$ via clustered SEs or bootstrap. Split sample pre/post-2020 (COVID effects?) and by flat age/child-relevant sizes.
- **Placebo/IV Checks:** Placebo RDD at fake cutoffs (8%,12%); instrument minority share with historical (pre-1989) composition to isolate EIP effects.

**Robustness and Presentation:**
- Fix artifacts: Table \ref{tab:hedonic} duplicated 9+ times with incoherent R² (0.8 to 3.1>1—likely log-level error); consolidate to one clean table. Tabulate RDD prominently; add graphs (e.g., year-trend plot with CIs, RDD scatter).
- **Power/Balance:** Report planning-area balance table (means of controls pre/post-Indian cutoff); power calculations for trend test (e.g., via simulation). With 219k obs, underpowered inference is the real issue—leverage it for precise nulls.
- **Economic Interpretation:** Translate all β to S$ (e.g., at mean price S$524k, 10pp minority → -S$64k); compare to other amenities (e.g., floor area elasticity). Discuss channels: decompose via constrained-block subsample (prices lower?) vs. non-constrained.
- **Broader Polish:** Shorten intro/discussion (AER:Insights is 3k-5k words); cite recent lit (e.g., Bryan et al. 2023 on Singapore EIP); pre-register on AEA (manifest helps). For SDE table, adopt Cohen's d conventions consistently.

Overall, the paper has a compelling setting and data but needs block-level ID and credible SEs to deliver a publishable result. With fixes, it could credibly test EIP's long-run preference effects—revise and resubmit.
