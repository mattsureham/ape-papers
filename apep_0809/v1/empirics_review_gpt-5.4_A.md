# V1 Empirics Check — openai/gpt-5.4 (Variant A)

**Model:** openai/gpt-5.4
**Variant:** A
**Date:** 2026-03-23T12:52:13.308611

---

## 1. Idea Fidelity

The paper is broadly faithful to the original manifest in topic, outcome, and intended identification logic. It studies whether EU enlargements in 2004/2007 increased far-right voting in French départements through exposure to posted-worker-intensive sectors, and it uses presidential election outcomes plus a shift-share-style exposure measure based on pre-enlargement sector composition. It also attempts the planned distinction from the China channel and includes a manufacturing placebo.

That said, the paper departs from the manifest in a few important ways that matter for credibility. First, the manifest envisioned département-level posted worker declarations from DARES/DGT; the paper instead uses national posted-worker inflow series and pre-enlargement sector shares, so the empirical design is much closer to a coarse exposure-based DiD than to a Bartik design built on observed local inflows. Second, the paper says it uses département-level sector shares, but the data section reveals that sectoral employment is observed only at NUTS2 and then mapped to départements. This is a substantial weakening relative to the original idea, because within-region département variation in treatment is then largely imputed rather than measured. Third, the core identifying concern anticipated by the manifest—whether high-exposure places were already on different political trajectories—turns out to be first-order: the event study shows clear pre-trends. So the paper follows the original research question, but not yet with the identification strength promised in the manifest.

## 2. Summary

This paper asks whether the sharp rise in EU posted workers after the 2004 and 2007 enlargements increased support for the Front National/Rassemblement National in French départements. Using pre-enlargement employment shares in construction and agriculture interacted with a post-enlargement period, the paper finds that more exposed départements experienced larger increases in far-right vote share, with suggestive evidence that the effect is concentrated in non-tradable sectors rather than manufacturing.

The question is interesting and potentially important. However, in its current form the paper does not deliver a credible causal estimate, mainly because the central identifying assumption is directly contradicted by the paper’s own event-study evidence and because the empirical implementation only imperfectly measures local exposure.

## 3. Essential Points

1. **The identification strategy is not credible as currently implemented because parallel trends fail.**  
   The event study shows that high-exposure départements were already on differential FN trends before enlargement. This is not a minor caveat; it is fatal to the current DiD interpretation. Once the paper documents a significant 1995–2002 differential trend, the coefficient on `Exposure × Post` can no longer be read as causal without additional structure. The current framing in the introduction and conclusion overstates what the design can support. At minimum, the authors need to (i) substantially soften causal claims throughout, and (ii) rework the empirical design to address the pre-trend directly—e.g., allow for exposure-specific linear trends, estimate changes over shorter windows around accession dates, or exploit richer timing/sector/origin variation if available.

2. **The paper does not actually identify local posted-worker shocks; it identifies differential trends in places with larger construction/agriculture sectors.**  
   This is an important mismatch between the research question and the empirical approach. The treatment is not observed local posted workers, but a pre-period sector composition proxy. Since construction and agriculture correlate with many persistent political and socioeconomic features, the estimated effect may reflect rurality, education, urban structure, occupational composition, or long-run FN geography rather than posted-worker competition. The manufacturing placebo is not enough to resolve this, because the relevant omitted variables need not load similarly on manufacturing shares. To make the paper persuasive, the authors need either actual département-level posted worker exposure or a much richer design showing that enlargement-induced increases in posted workers were disproportionately realized in the places predicted by the exposure measure.

3. **The data construction materially weakens the analysis and needs clarification and improvement.**  
   The paper claims département-level exposure, unemployment, and controls, but several core variables appear to be measured at NUTS2 and then assigned to départements. This creates mechanical within-region duplication, overstates the amount of cross-sectional variation, and raises concerns about inference. The paper should be fully transparent about the level at which each variable is observed and about how many unique exposure values there really are. If treatment only varies at NUTS2, then clustering at the département level is inappropriate or at least incomplete; the relevant effective number of treated units is much smaller. This issue affects both precision and interpretation and must be fixed.

## 4. Suggestions

The paper addresses an excellent question, and there is a potentially publishable paper here if the empirical strategy is substantially strengthened. Below are concrete suggestions that, in my view, would most improve the manuscript.

**1. Recenter the paper around a design that matches the question.**  
Right now the question is about *posted workers*, but the empirical design is mostly about *pre-existing sectoral composition*. If département-level posted worker declarations exist—as suggested in the manifest—they should be brought to the center of the paper. Even descriptive evidence would help enormously: show that actual local posted-worker intensity rises discontinuously or sharply more in high-predicted-exposure départements after 2004/2007. A first-stage graph is essential. Without it, readers do not know whether the exposure measure meaningfully predicts realized local treatment.

Relatedly, if the DARES/DGT data provide posted workers by département-sector-year, the natural empirical object is a panel with:
- outcome: election results at département-election level;
- treatment: posted workers per private employment in the département, or by sector;
- instrument/predicted treatment: pre-2004 sector shares interacted with national growth in posted workers by sector and perhaps by origin-country group (A8, A2, old member states).

That would turn the paper into an actual shift-share design rather than a reduced-form DiD on sector shares.

**2. Use the accession timing more fully.**  
The current binary “post-2007” indicator compresses a lot of structure. There are at least two separate shocks (A8 in 2004, A2 in 2007), and France’s transitional rules differed for permanent migration versus posting. You should leverage that. For example:
- Estimate separate effects for exposure to sectors using A8-related national posting growth after 2004 and A2-related growth after 2007.
- Show whether sectors/places with higher pre-enlargement reliance on likely sender countries experienced larger realized increases.
- If origin-country information exists in the posted worker data, use origin-by-sector national shocks. This would both strengthen identification and address concerns that the timing simply proxies for broader anti-EU or anti-immigration sentiment.

A richer timing structure would also help test whether effects align with actual posted-worker inflows rather than with secular FN growth.

**3. Take the pre-trend problem much more seriously in the analysis and framing.**  
I appreciate the honesty in acknowledging the pre-trend, but the manuscript currently treats it as a limitation around an otherwise causal design. I do not think that is tenable. Several practical steps could improve matters:
- Include exposure-specific linear trends and show how much the estimate survives.
- Collapse the panel to first differences between adjacent elections and test whether exposure predicts especially large jumps in 2007 and 2012 relative to earlier changes.
- Implement a “stacked” event-study approach around 2004 and 2007 if you can construct a more annual local treatment series.
- Use pre-2004 covariates interacted with time to soak up heterogeneous trends: baseline FN support, urbanization, education, immigrant share, occupational structure, sectoral composition beyond construction/agriculture, and perhaps region-specific time trends.

Even if these exercises do not fully rescue causality, they would clarify whether the result is robust or merely reflects long-run sorting of FN support.

**4. Improve the measurement of local exposure.**  
The use of NUTS2 sector data mapped to départements is a serious weakness. If at all possible, replace this with true département-level sector shares from INSEE or another French administrative source. Construction and agriculture vary meaningfully within region; imputing the same regional share to all départements blurs treatment and can create misleading precision. At minimum:
- state clearly which variables are observed at NUTS2;
- report the number of unique exposure values;
- show maps of actual and imputed exposure;
- cluster at the level of treatment variation, or use wild bootstrap procedures given the small number of effective clusters.

This may also change the magnitude and significance of the results.

**5. Clarify what the “Bartik” specification is doing.**  
Table 1 is confusing. The paper presents a Bartik exposure, but with year fixed effects its identifying time variation appears mostly absorbed, and then the preferred specification is not Bartik but `Exposure × Post`. This is a sign that the paper should simplify and be more precise about what is estimated. I would recommend one of two paths:
- either develop a genuine Bartik/IV strategy with a meaningful first stage on local posted workers; or
- abandon the Bartik language and present the paper as a reduced-form differential-exposure design.

At present, calling the design Bartik overstates the identification content.

**6. Reconsider the placebo strategy.**  
The manufacturing placebo is intuitive, but it is not decisive. Manufacturing shares differ from construction/agriculture in many ways besides posted-worker relevance. More convincing placebo tests would include:
- pre-period placebo outcomes (e.g., change in FN vote between 1995 and 2002);
- sectors with low posted-worker exposure but similar local labor-market/political correlates;
- non-far-right political outcomes where no effect is expected;
- outcomes unlikely to move through labor competition, if available.

A useful exercise would be a horse race including multiple baseline sector shares interacted with post, to see whether construction/agriculture remain distinctive once one conditions on the broader local economic structure.

**7. Strengthen the control strategy, but avoid “bad control” logic.**  
The China shock control is sensible conceptually, but the implementation appears stylized and perhaps too aggregate. A more convincing version would use the standard local import-exposure construction based on local industry shares rather than national import penetration interacted with manufacturing share. More broadly, given the pre-trends, controls should focus on pre-determined characteristics that plausibly shape heterogeneous trends:
- baseline unemployment and employment structure;
- education;
- urban/rural status;
- immigrant share and composition;
- income and inequality;
- historical FN vote share.

At the same time, be careful not to rely too heavily on contemporaneous controls like unemployment if these are themselves affected by posted workers.

**8. Reassess statistical inference.**  
With only six election years and treatment partly varying at higher-than-département geography, conventional département-clustered standard errors may be misleading. Please report alternative inference:
- clustering at NUTS2 or region;
- wild cluster bootstrap;
- randomization inference or placebo reassignments of exposure;
- permutation tests using pre-treatment sector shares.

In a short-form journal article, one compact robustness table on inference would go a long way.

**9. Refine the interpretation of magnitudes.**  
Some of the magnitudes are difficult to parse. For example, the coefficient of 49.95 on an exposure variable with mean around 0.11 implies large average effects, but the text alternates between a one-standard-deviation interpretation and a one-percentage-point-share interpretation. Please standardize units carefully throughout. Also, the back-of-the-envelope claim that posted workers explain 2–3 percentage points of national FN support should be presented much more cautiously given the identification concerns.

**10. Tighten the discussion of mechanism.**  
The paper argues for labor-market competition, salience, and EU resentment, but provides no direct evidence distinguishing these channels. If data permit, consider heterogeneity by:
- occupational structure (manual workers, craft workers);
- unemployment sensitivity;
- sectors where posted workers are visible versus less visible;
- Eurosceptic baseline areas;
- local media coverage or anti-EU sentiment proxies.

Even one well-executed heterogeneity dimension would make the argument more compelling.

**11. Make the paper more transparent about data provenance.**  
Because the paper currently mixes DARES, DGT estimates, Eurostat regional data, and election returns, readers need a very clear appendix documenting:
- exact source tables and years;
- treatment of Corsica, Paris, and any boundary changes;
- how 572 rather than 576 observations arise;
- whether election-year variables are interpolated or matched to nearest available year;
- how national posted worker series are harmonized across pre- and post-SIPSI regimes.

This is especially important because the paper’s contribution hinges on administrative data credibility.

**12. Consider a narrower claim if stronger identification is not feasible.**  
If true département-level posted-worker data cannot be assembled and pre-trends remain strong, the paper may still be valuable as a descriptive political-economy paper documenting that FN gains were disproportionately concentrated in places specialized in posted-worker-intensive non-tradables during the enlargement era. But then the paper should abandon causal language and recast itself accordingly. A well-executed descriptive paper can still make a useful contribution if it is honest about what the evidence can and cannot establish.

Overall, I think the topic is timely and the intuition is good. But for an AER: Insights-style contribution, the empirical strategy has to do more work than it currently does. The most important next step is to align the treatment measurement and identification strategy with the paper’s substantive claim about posted-worker shocks, not simply sectoral composition.
