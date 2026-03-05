# GPT-5.2 Review

**Role:** External referee review
**Model:** openai/gpt-5.2
**Paper:** paper.pdf
**Timestamp:** 2026-03-05T16:52:09.162555
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 20418 in / 4749 out
**Response SHA256:** 8aff1616bb22b4c3

---

## 1. Identification and empirical design (critical)

### What the paper is trying to identify
The paper has two distinct empirical objects:

1. **Cross-sectional “boundary discontinuity”** in high-income share at high-tax/low-tax state borders (Sections 5.1–5.2; Table 2; Figure 1–2).  
2. **Causal effect of the 2018 SALT cap on border sorting** via a triple-difference (DDD) that compares high- vs low-income shares on the high-tax vs low-tax side, pre/post 2018 (Sections 5.4–5.5; Table 3; Figures 3 and 8).

The paper is appropriately cautious that the *cross-sectional* discontinuity is not causal. The key question for publication readiness is whether the **DDD/SALT design** is credibly causal and whether the paper’s inferential and design choices support the causal claim (even a “modest upper bound”).

### Cross-sectional boundary RDD: not credible for causal tax effect (and you largely acknowledge this)
- The core geographic RDD assumption—**all non-tax determinants of high-income share are smooth at the border**—is clearly violated by your own diagnostics (placebo reversal; covariate imbalance; bandwidth sign flips; Section 5.2 and Table 6). That means the cross-sectional RDD cannot be interpreted as an effect of tax differentials. You state this, which is good, but then large parts of the Results still read like “tax sorting near the border” rather than “border geography.”
- The **placebo outcome** (low-income share) is not just “statistically significant,” it is economically enormous in the very-local bandwidth (−27 pp within 1.9 km; Table 2). That magnitude strongly suggests that the border is separating fundamentally different settlement patterns (urban form, housing stock, industry mix), not marginal tax incentives. This is not a minor violation; it is essentially fatal to a causal interpretation of the baseline RDD.

**Bottom line:** the paper should treat the cross-sectional RDD purely as descriptive spatial correlation and reframe the empirical contribution around the *within-border change* design (SALT) if it can be made credible.

### DDD using SALT cap: potentially interesting but currently not publication-ready
The DDD is the only plausible route to a causal claim, but it hinges on assumptions that are currently **insufficiently defended and, in places, internally contradicted by your own event-study evidence**.

#### (i) Parallel trends / no differential shocks by income group at the border
Your identifying assumption is: absent SALT, the **difference in high- vs low-income shares** between sides of the border would have evolved similarly pre/post 2018. This is a strong assumption because:
- Border areas in high-tax states (CA/NJ/NY/OR/MN) may have experienced **differential income-composition changes** around 2018–2021 for reasons correlated with income (tech booms, housing constraints, local labor demand, COVID remote work, etc.) that differ across the border.
- You attempt to address this with a **DDD event study** (Figure 8) and find (a) a **rejection of joint pre-trends** (p=0.005) driven by 2016, and (b) **effects only in 2020–2021**, not 2018–2019 (Section 5.5). This timing is much more consistent with **COVID/remote-work mobility** than with immediate SALT-driven adjustment.

You acknowledge this, but the paper still leans toward interpreting the DDD estimate as SALT-induced tax sorting (Abstract; Introduction; Conclusion). As written, the DDD evidence is at best **ambiguous attribution** (SALT vs COVID interaction), and at worst **violates the design’s key identifying assumption**.

#### (ii) Treatment definition is too coarse and risks misclassification
“High-income” = AGI ≥ $200k is not a clean proxy for SALT-cap exposure. Exposure depends on:
- itemization probability,
- SALT level (property + income taxes),
- filing status, and
- housing prices/property taxes that vary sharply within metro areas.

You note this (Section 4.3), but the design consequence is serious: the DDD is effectively an **intent-to-treat with unknown first stage**, and it is not clear the first stage is stable across border sides or over time. This can create **differential measurement error** correlated with the border and with post-2018 housing changes—exactly the kind of compositional confound that would contaminate a share-based DDD.

#### (iii) “Border-pair × year FE” structure may not be consistent with key interaction/event-study variation
In the parametric/event-study specifications you include **border-pair × year fixed effects** (Equation (1) and event study in Section 4.2). This absorbs all shocks common to a border pair in a year, which is appropriate, but it also means the identifying variation comes from **within-pair, within-year differences by distance and side**. For the DDD, you further stack income groups and add ZIP FE and border-pair × year FE (Table 3 notes). That is a demanding set of fixed effects and interactions; the paper needs to be much clearer (and ideally provide algebra/appendix) on:
- exactly which lower-order interactions are included,
- which are collinear with the FE,
- and what variation identifies the triple interaction.

Right now the reader must trust the implementation without a transparent design matrix discussion.

#### (iv) Unit of analysis and “multiple membership” ZIPs threaten interpretation
You allow ZIPs to appear in multiple border segments (Section 3.4). This creates two problems:
- **Interpretation:** a single ZIP-year observation effectively contributes to multiple “experiments,” which muddies what a “border-pair × year FE” means when an observation belongs to multiple pairs.
- **Inference:** clustering at ZIP code does not correct dependence induced by reusing the same observation across multiple border definitions; clustering at border pair is too coarse (8 clusters). This design feature alone can materially distort both point estimates (via implicit reweighting) and standard errors.

At minimum, you need a clean “single-assignment” rule (e.g., assign each ZIP to its nearest border pair, or pre-specify mutually exclusive border corridors), or move to an aggregation level that avoids duplication (e.g., grid cells or border-distance bins unique to a border pair).

### Additional design issues that weaken causal interpretation
- **Distance to border based on ZCTA centroid** (Section 3.2) is a noisy running variable for irregular, large ZCTAs, especially in rural areas. Noise in the running variable is not classical here; it correlates with urban/rural status and likely with income composition. This matters for “local” bandwidth interpretation and for donut/bandwidth sensitivity claims.
- **Borders follow rivers/mountains** (you acknowledge). In those cases, “very close to the border” is not “similar neighborhoods,” even if distance is small (e.g., crossing a river bridge is not symmetric to straight-line distance). This undermines the “adjacent ZIPs share amenities” premise in the Introduction.

**Overall on identification:** The baseline boundary RDD cannot identify tax effects; the SALT DDD is the right direction but currently undermined by (a) questionable parallel trends and timing, (b) coarse treatment, and (c) structural sample/inference issues (duplicate ZIPs; too few independent clusters).

---

## 2. Inference and statistical validity (critical)

### The paper does not yet clear the inference bar for a top journal
Your own key result changes from “highly significant” to “not significant” depending on clustering (Table 9). This is not a minor robustness check; it is the central inferential issue.

#### (i) Few independent clusters: border-pair clustering is conceptually right but statistically weak
- The causal variation is essentially at the **border-pair level** (8 pairs). That implies asymptotics with 1,500 ZIP clusters are not credible if shocks are correlated within border pair (and they almost surely are).
- With 8 clusters, conventional cluster-robust SE are unreliable too. A top-journal-ready approach would include **randomization inference / permutation tests**, or **wild cluster bootstrap-t** designed for few clusters, and/or **aggregation to the border-pair × side × year level** to make the effective sampling unit explicit.

Right now, the headline “p < 0.001” (ZIP clustering) is misleading given the design. The abstract correctly notes the border-pair clustered p=0.27, but then the narrative still treats the DDD as “confirming” a tax channel.

#### (ii) rdrobust with clustering at ZIP in panel settings
For the nonparametric RDD, you cluster at ZIP, but the running variable is distance and the treatment is side-of-border. The local sample includes repeated years. The dependence structure is likely within ZIP over time and within border corridor over space. It is not obvious ZIP clustering is appropriate for local polynomial RDD in this geographic/panel context; you should justify:
- whether you collapse to cross-section (e.g., 2012–2017 average) before rdrobust,
- or use a panel-aware approach,
- or implement a **spatial HAC** or border-segment clustering for local RDD.

Given you already conclude the cross-sectional RDD is not causal, the main value of rdrobust is descriptive; still, reported p-values should not overstate precision.

#### (iii) Coherence of sample sizes across specs
N differs across bandwidths and outcomes (expected), but the paper needs a clearer accounting of:
- how many ZIPs per border pair,
- how many effective observations per pair in the rdrobust window,
- and whether some pairs contribute almost nothing (you mention non-convergence for four pairs in Table 4).

For the DDD, because you stack groups, readers need explicit N by group and whether the shares mechanically constrain each other (see below).

#### (iv) Compositional outcome and mechanical dependence
You regress **shares** (high-income share; low-income share). These are components of the same denominator (total returns). Shifts in middle-income shares mechanically affect high/low shares even absent any behavioral change. In a stacked regression, the error terms across “group observations” within a ZIP-year are not independent; they are linked by the simplex constraint. This matters for correct inference and interpretation of “High Income × Post-SALT” terms (Table 3), and could bias standard errors downward if treated as independent stacked observations.

A more defensible approach is to model **counts with an offset** (e.g., Poisson/PPML or binomial quasi-likelihood) using:
- high-income returns as outcome,
- log total returns as offset,
- with fixed effects and clustering at the correct level.
This would also handle heteroskedasticity induced by varying ZIP sizes.

---

## 3. Robustness and alternative explanations

### Robustness exercises are numerous, but several key ones are missing or need reorientation

#### What you do well
- You run placebos, balance checks, bandwidth sensitivity, donut variants, and acknowledge failures (Sections 5.2 and 5.8; Appendix).
- You explicitly show NJ–PA drives the pooled nonparametric RDD (Table 8). This is important.

#### High-priority missing or underdeveloped robustness
1. **Explicit COVID vs SALT separation.**  
   Because the DDD “effect” appears in 2020–2021, the obvious alternative is remote work / pandemic relocation. You need a design that can separate:
   - a discrete 2018 SALT shock,
   - from a discrete 2020 COVID shock,
   - and potentially their interaction (SALT matters more when mobility costs fall).
   
   Concretely: include **two shocks** (Post2018, Post2020) and estimate an event study that tests for a 2018 break *net of* 2020 break, or limit to 2016–2019 as a clean pre-COVID window (even at power cost) as a primary estimand.

2. **Border-pair-specific estimates for DDD.**  
   If the identifying variation is at the border-pair level, show the pair-level DDD estimates (forest plot). This helps diagnose whether the pooled DDD is driven by one corridor (as the RDD is driven by NJ–PA). With 8 pairs, transparency here is essential.

3. **Weighting by ZIP size / precision.**  
   Shares from ZIPs with 200 returns are noisier than those with 20,000 returns. Unweighted OLS on shares can overweight noisy small ZIPs (and suppression correlates with small ZIPs). Consider:
   - WLS weighted by total returns, or
   - count models with offsets as noted above.

4. **Exposure intensity to SALT cap.**  
   Even if SOI lacks itemized deductions, you can proxy exposure using external data:
   - pre-2018 county-level itemization rates (IRS publishes some itemization/statistics at county/state level),
   - local house prices / property tax rates (ACS; Zillow; county tax data),
   - or predicted SALT exposure based on pre-period income and housing costs.
   
   A continuous treatment (high-tax side × predicted exposure × post) would be far more persuasive than the $200k cutoff.

5. **Single-assignment of ZIPs to borders (no duplicates).**  
   Re-estimate all key models after assigning each ZIP to one border pair only. This is critical.

#### Mechanisms vs reduced form
The paper largely stays reduced-form, which is appropriate given data constraints. However, some discussion (e.g., capitalization) is speculative. Keep mechanism claims clearly labeled as hypotheses unless you add housing price evidence.

---

## 4. Contribution and literature positioning

### Contribution: promising idea, but currently more a “negative result/diagnostic” paper
The most distinctive element is using **ZIP-level SOI near borders** and showing diagnostics that reveal how boundary designs can fail when borders bundle many confounds. That can be publishable if the paper:
- delivers a clean causal design for a specific policy shock (SALT), or
- reframes as a methodological warning with strong evidence and careful inference.

Right now it sits in between: the cross-sectional design fails (by your own tests), and the SALT design is suggestive but not credibly identified/inferred.

### Literature to add / sharpen
Consider citing and engaging more directly with:

- **SALT cap incidence and behavioral responses** (there is a sizable policy/public finance literature post-TCJA). You need a few anchor cites on SALT cap distributional incidence and location incentives. Examples to consider (not exhaustive): work by **Slemrod**, **Giertz**, **Gale**, **Kamin**, **Moore**, and NBER/TPF analyses on SALT cap behavioral responses. The paper currently treats SALT as a clean shock but does not anchor in empirical SALT-response evidence.
- **Recent border and spatial RD/DiD inference**: work on geographic discontinuities and spatial correlation corrections beyond Keele & Titiunik. Also literature on **few-cluster inference** in policy evaluation (wild cluster bootstrap, randomization inference).
- **Remote work and migration** post-2020 (important because your timing points there). Without this, the main alternative explanation is underdeveloped.

---

## 5. Results interpretation and claim calibration

### Over-claiming risk
- The abstract states the DDD estimate and reports p-values under two clustering schemes (good), but still frames it as “yields” an effect and “findings place a modest upper bound.” Given p=0.27 under the conceptually relevant clustering level and pre-trends rejection plus post-effect appearing only in COVID, the right conclusion is closer to:  
  **“We cannot statistically distinguish a SALT effect from zero once we account for few-cluster inference and pandemic-era confounds.”**

### Magnitudes
- The translation of −0.6 pp into “13% relative to a 5% base” is fine arithmetically, but policy interpretation (e.g., “a state raising its top rate by 1 pp would lose at most 2–3%”) is not well supported. Your estimated shock is not a 1 pp state tax increase; it’s a **federal deductibility regime change** with heterogeneous incidence. Converting it into a generalized “1 pp top rate” statement is too speculative unless you build a clear mapping from SALT cap to effective marginal tax price differences at each border.

---

## 6. Actionable revision requests (prioritized)

### 1) Must-fix issues before acceptance
1. **Redesign inference for the DDD around the true number of independent units (few clusters).**  
   - *Why it matters:* AER/QJE/JPE/ReStud/Ecta will not accept a headline result that disappears under correct dependence structure.  
   - *Fix:* Use (i) wild cluster bootstrap-t at the border-pair level, (ii) randomization inference/permutation over border-pairs or over “treated side” labels within pairs, and/or (iii) aggregate to border-pair × side × year (and income group) outcomes to make the sampling unit explicit. Report these as primary inference.

2. **Eliminate duplicate ZIP usage across multiple border segments or justify it formally.**  
   - *Why it matters:* Multiple membership breaks the interpretation of FE and invalidates naive clustering.  
   - *Fix:* Assign each ZIP to a single border pair (nearest border, or pre-defined mutually exclusive corridors), re-run all key results, and show sensitivity.

3. **Address the SALT vs COVID confound directly with a two-shock design and/or restricted window.**  
   - *Why it matters:* Your event study implies the “effect” is a pandemic-era phenomenon, undermining SALT attribution.  
   - *Fix:* (a) restrict main causal analysis to 2014–2019 (pre-COVID) and treat 2020–2021 separately; (b) include Post2020 and interactions; (c) explicitly test for a 2018 discontinuity net of 2020.

4. **Fix outcome modeling to respect compositional structure and heteroskedasticity.**  
   - *Why it matters:* Share-based stacked regressions can misstate precision and can be mechanically driven by changes in other shares.  
   - *Fix:* Use count models (PPML/binomial) with total returns as an exposure/offset, and cluster appropriately. If you keep shares, use WLS by total returns and account for within-ZIP-year correlation across stacked groups.

### 2) High-value improvements
5. **Construct a continuous SALT exposure proxy and estimate heterogeneous treatment effects.**  
   - *Why it matters:* It strengthens first-stage relevance and interpretation; reduces misclassification.  
   - *Fix:* Predicted itemization/SALT exposure using external data (county itemization rates, house prices, property taxes) interacted with high-tax side and post-2018.

6. **Report border-pair-specific DDD estimates and diagnostics.**  
   - *Why it matters:* With only 8 pairs, readers need to see whether results are broad-based or driven by one corridor.  
   - *Fix:* A table/plot of pair-level estimates; leave-one-border-out pooled DDD.

7. **Clarify the identifying variation with your FE structure.**  
   - *Why it matters:* Current specification descriptions are not enough to verify identification.  
   - *Fix:* Add an appendix laying out the exact regression equation for DDD/event study with all FE and interactions; explain what variation remains.

### 3) Optional polish (substance-oriented, not prose)
8. **Reframe the paper’s main contribution explicitly as either (a) a credible SALT causal estimate after redesign, or (b) a methodological demonstration of why border RDD fails for state tax differences.**  
   - *Why it matters:* Top journals need a crisp “main result,” not two partially conflicting designs.

9. **Consider alternative geographic units (e.g., census tracts or grid cells) if feasible.**  
   - *Why it matters:* ZCTAs are large/irregular; centroid distance is noisy and sometimes meaningless for “local” comparisons.

---

## 7. Overall assessment

### Key strengths
- Uses a novel and policy-relevant dataset (SOI ZIP panels) and a natural spatial framing.
- Commendably transparent about diagnostic failures (placebo, covariate imbalance, bandwidth sensitivity).
- The SALT cap is a plausible quasi-experimental shock worth studying in a border framework.

### Critical weaknesses
- The cross-sectional boundary design does not identify tax effects (and most of the descriptive results are driven by geography and one border segment).
- The SALT DDD result is **not statistically credible** once you account for the true number of independent units and is **timing-inconsistent** with a 2018 shock (effects show up in 2020–2021).
- Key design elements (duplicate ZIPs across borders; compositional outcomes; FE identification) are not yet defensible at a top general-interest journal standard.

### Publishability after revision
Potentially publishable **only if** the paper is reorganized around a defensible causal design with correct few-cluster inference and a credible separation of SALT from COVID-era shocks, or if it is reframed as a methodological cautionary paper with appropriately modest claims and rigorous inference. As written, it is not ready.

DECISION: MAJOR REVISION