# Research Idea Ranking

**Generated:** 2026-03-05T15:13:05.932230
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| ZIP-Code Border RDD — State Tax Differen... | PURSUE (69) | — | PURSUE (88) |
| State-Level IRS Migration Flows — Tax Ra... | CONSIDER (51) | — | CONSIDER (68) |
| ACS Microdata Border RDD — Migration Sta... | SKIP (44) | — | SKIP (52) |
| Remote Work Regime Change and Tax-Border... | CONSIDER (39) | — | SKIP (42) |
| Estate Tax Threshold Notch and Elderly O... | SKIP (12) | — | SKIP (18) |
| Idea 1: ZIP-Code Border RDD — State Tax ... | — | PURSUE (88) | — |
| Idea 2: State-Level IRS Migration Flows ... | — | SKIP (52) | — |
| Idea 4: Remote Work Regime Change and Ta... | — | SKIP (42) | — |
| Idea 3: ACS Microdata Border RDD — Migra... | — | SKIP (35) | — |
| Idea 5: Estate Tax Threshold Notch and E... | — | SKIP (20) | — |

---

## GPT-5.2

**Tokens:** 6065

### Rankings

**#1: ZIP-Code Border RDD — State Tax Differentials and High-Income Geographic Sorting**
- **Score:** 69/100  
- **Strengths:** Best-designed idea in the set: a classic border discontinuity with “internal replication” across many borders, plus a clear policy shock (2018 SALT cap) that plausibly increases the bite of state tax differences specifically for high earners. Administrative “near-universe” IRS ZIP data gives power and a clean extensive-margin outcome (# high-income filers) aligned with the mechanism.  
- **Concerns:** Border RDD validity hinges on “only taxes jump at the border,” which is questionable: states differ in amenities, schools, regulation, and local labor markets; border metros may be asymmetric (NYC area especially). ZIP centroid distance is noisy, ZIP definitions change, and SOI suppression/rounding can create nonclassical measurement error near the cutoff.  
- **Novelty Assessment:** **Medium.** Tax-induced migration and SALT-cap effects are heavily studied, but *ZIP-level* border discontinuities using SOI income-stub counts (with multi-border replication + SALT amplification) is less saturated than state-level migration regressions and could be a publishable measurement/design contribution.  
- **Top-Journal Potential:** **Medium.** A top field journal (AEJ:EP) is plausible if you (i) show compelling “bite” of SALT at the border, (ii) adjudicate a live elasticity debate with tight bounds, and (iii) deliver a welfare/revenue counterfactual. Top-5 is harder because the question is well-trodden unless the design yields a belief-changing elasticity or a surprising substitution pattern (e.g., intensive vs extensive margin, within-metro re-optimization).  
- **Identification Concerns:** Key threats are discontinuous non-tax policies/amenities at borders and differential metro trends that violate local continuity/parallel trends even within narrow bands. You’ll need strong diagnostics: covariate balance, border-segment fixed effects, donut RD, bandwidth sensitivity, and placebos (fake borders; outcomes not affected by SALT; pre-2018 “effects”).  
- **Recommendation:** **PURSUE (conditional on: strong pre-2018 event-study flatness by border segment; convincing diagnostics that ZIP-level measurement/suppression isn’t driving discontinuities; a narrative that isolates within-metro re-sorting rather than broad state divergence).**

---

**#2: State-Level IRS Migration Flows — Tax Rate Differential Panel RDD**
- **Score:** 51/100  
- **Strengths:** Feasible, transparent, and uses widely trusted IRS migration tabulations with high-income breakdowns—good for descriptive facts and benchmarking magnitudes around SALT.  
- **Concerns:** This is not a credible “RDD”: the tax-rate differential is not a quasi-random running variable, and state-pair flows confound taxes with jobs, housing costs, climate, and contemporaneous policy bundles. With only ~50 states, inference is fragile and easily driven by a few origin-destination pairs (NY→FL, CA→TX/NV/AZ).  
- **Novelty Assessment:** **Low.** Interstate migration responses to taxes and SALT have many existing papers using similar state-level flow or tax-return-based measures; incremental contribution likely.  
- **Top-Journal Potential:** **Low–Medium.** Could place in a decent field outlet as an updated descriptive decomposition, but unlikely to clear top outlets without a genuinely new design/variation beyond “tax differences + SALT timing.”  
- **Identification Concerns:** Endogenous policy (tax changes respond to state conditions) and omitted-variable bias in state-pair trends are first-order; “event study around SALT” is still vulnerable because many other 2018+ macro forces shift flows.  
- **Recommendation:** **CONSIDER** as a companion/validation exercise to Idea 1 (external benchmark), not as the flagship identification strategy.

---

**#3: ACS Microdata Border RDD — Migration Status × Income**
- **Score:** 44/100  
- **Strengths:** Individual microdata enables rich heterogeneity (education/occupation/remote-compatibility) and allows checking compositional shifts that ZIP aggregates can’t.  
- **Concerns:** PUMAs are too large for a border discontinuity (centroid-to-border is especially crude), and ACS income is noisy/top-coded while the available tabulated “high income” cut is only $75K+—not “elite.” Using 5-year ACS products also blurs timing around SALT (2018) and COVID (2020).  
- **Novelty Assessment:** **Low–Medium.** Many studies use ACS/CPS for migration and taxes; the geographic/coarseness constraint makes it unlikely you’ll add a new clean fact to the literature.  
- **Top-Journal Potential:** **Low.** Likely reads as “competent but not exciting,” with identification dominated by spatial measurement error and weak treatment contrast at the relevant income tail.  
- **Identification Concerns:** Treatment assignment is mismeasured (large PUMAs straddle heterogeneous labor/housing markets), so estimates are attenuated and hard to interpret; border comparability is weak.  
- **Recommendation:** **SKIP** as a main design; only revive if you can access finer geocodes (restricted ACS) or link to a sharper location measure.

---

**#4: Remote Work Regime Change and Tax-Border Sorting (2020+)**
- **Score:** 39/100  
- **Strengths:** A potentially interesting interaction: reduced moving/commuting frictions could increase responsiveness to tax differentials, which is a conceptually clean comparative-static.  
- **Concerns:** COVID is an omnibus shock (health risk, urban disamenities, school closures, crime perceptions, housing demand shifts, temporary remote work, stimulus) and will overwhelm any tax channel; with 2020–2021 you have a short, highly nonstationary post window.  
- **Novelty Assessment:** **Medium.** “Remote work and location choice” is now a crowded area; adding “tax borders” is a twist but not enough by itself.  
- **Top-Journal Potential:** **Low–Medium.** Only becomes exciting if you can *separate* remote-work enablement from other COVID channels (e.g., using pre-pandemic remote-feasible occupation shares as an exposure design) and show a crisp mechanism chain.  
- **Identification Concerns:** Triple-differences won’t rescue you if the border vs interior differential is itself affected by pandemic-era urban flight and housing re-sorting unrelated to taxes; parallel trends are very unlikely to hold in 2019–2021.  
- **Recommendation:** **SKIP** as currently framed; **CONSIDER** only if redesigned around a pre-COVID exposure measure to remote feasibility and a longer post period.

---

**#5: Estate Tax Threshold Notch and Elderly Out-Migration**
- **Score:** 12/100  
- **Strengths:** The NY “cliff” is genuinely sharp and conceptually ideal for studying behavioral response to a notch; if you had the right microdata, this could be a standout design.  
- **Concerns:** The proposal is data-infeasible with public sources: you cannot observe wealth near the threshold and migration jointly, so the RDD/bunching design cannot be implemented credibly. Area-level proxies destroy identification.  
- **Novelty Assessment:** **High conceptually, but moot empirically.** There’s a notch/bunching literature and a tax-migration literature, but this specific notch × mobility test would be new *if* feasible.  
- **Top-Journal Potential:** **Potentially high in a counterfactual world with linked estate/mobility microdata; low in practice** given data constraints.  
- **Identification Concerns:** Without individual wealth and location changes, any “threshold” design collapses into ecological correlations with no credible local randomization.  
- **Recommendation:** **SKIP** (unless you can secure restricted IRS microdata or a proprietary wealth panel with address histories).

---

### Summary

This is a one-idea batch: **Idea 1** is the only proposal that combines feasible administrative data, a plausibly sharp design, and a policy shock with clear first-stage bite. The rest are either identification-weak (Ideas 2–4) or not feasible (Idea 5). If the institute funds one project, fund **Idea 1**, with a deliberate diagnostic plan to convince skeptics that border discontinuities are not picking up non-tax state differences and that the SALT amplification is doing real identification work.

---

## Gemini 3.1 Pro

**Tokens:** 10346

Here is my evaluation of the research proposals, ranked from most to least promising. As requested, I have applied a highly critical lens, grounding my assessments in the realities of top-tier journal editorial preferences and empirical feasibility.

### Rankings

**#1: Idea 1: ZIP-Code Border RDD — State Tax Differentials and High-Income Geographic Sorting**
- **Score**: 88/100
- **Strengths**: Combines a sharp spatial RDD with a massive federal policy shock (SALT cap) using highly granular, publicly available IRS universe data. The built-in "internal replication" across 8+ borders and the low-income placebo group perfectly align with what top journals demand for credibility.
- **Concerns**: ZIP codes are postal routes, not true polygons, which can create measurement error at the boundary. The intensive margin (AGI per return) might capture income shifting or realization timing rather than physical migration.
- **Novelty Assessment**: High. While the broader topic of tax-induced elite migration is well-trodden (e.g., Moretti & Wilson, Rauh & Shyu), applying a spatial boundary discontinuity design to the SALT cap using ZIP-level IRS data is highly novel and represents a massive methodological upgrade over standard state-level panel studies.
- **Top-Journal Potential**: High. This hits multiple empirically observed winning patterns: it leverages "internal replication" as a storytelling device, uses a placebo (low-income filers) as an opponent-killer, and links a legible shock to a concrete welfare margin via sufficient statistics.
- **Identification Concerns**: The main threat is spatial sorting within ZIP codes or ZIPs that straddle borders, which could blur the discontinuity. Additionally, unobserved local economic shocks at specific borders could confound the SALT event study if not absorbed by border-pair-by-year fixed effects.
- **Recommendation**: PURSUE (conditional on: verifying that ZIP code centroids provide enough density close to the border for a well-powered RDD; ensuring border-pair fixed effects absorb local trends).

**#2: Idea 2: State-Level IRS Migration Flows — Tax Rate Differential Panel RDD**
- **Score**: 52/100
- **Strengths**: Uses reliable, universe-level IRS migration data that is ready off-the-shelf. Directly answers a policy-relevant question about interstate tax competition.
- **Concerns**: Calling a state-level analysis an "RDD" is a severe misnomer; this is just a standard two-way fixed effects panel regression. State-level aggregates mask the actual mechanism of geographic sorting and suffer from massive unobserved heterogeneity.
- **Novelty Assessment**: Low. The literature is saturated with state-level panel regressions on tax migration (e.g., Young et al. 2016). Adding the SALT cap updates the timeframe but doesn't fundamentally change the heavily studied, standard empirical approach.
- **Top-Journal Potential**: Low. This falls squarely into the "technically competent but not exciting" bucket. Without a sharp design or a new mechanism, it will be viewed as just another ATE on a saturated topic and rejected by top-5 and top field journals.
- **Identification Concerns**: State-level tax differentials are not a sharp running variable, making the "RDD" framing invalid. The design cannot cleanly separate tax-motivated moves from broader macroeconomic trends, amenity preferences, or regional labor market shocks.
- **Recommendation**: SKIP

**#3: Idea 4: Remote Work Regime Change and Tax-Border Sorting (2020+)**
- **Score**: 42/100
- **Strengths**: Asks a highly relevant, modern question about how remote work interacts with local tax policy. Uses the same high-quality IRS ZIP-code universe data as Idea 1.
- **Concerns**: The COVID-19 shock is the ultimate confounder, simultaneously changing preferences for density, housing, and amenities. The post-period is too short to distinguish temporary pandemic flight from permanent tax-motivated sorting.
- **Novelty Assessment**: Medium. The interaction of remote work and taxes is a hot topic, but the empirical execution proposed here lacks a unique angle to isolate the tax channel from the broader pandemic shock.
- **Top-Journal Potential**: Low. As noted in the editorial appendix, papers where results are "driven by COVID" or confounded by the 2020 pandemic shocks routinely lose because the exclusion restriction is fundamentally violated.
- **Identification Concerns**: It is impossible to disentangle tax-motivated border sorting from pandemic-induced urban flight, as high-tax states (like NY and CA) also had the most severe early COVID outbreaks and strictest lockdowns.
- **Recommendation**: SKIP

**#4: Idea 3: ACS Microdata Border RDD — Migration Status × Income**
- **Score**: 35/100
- **Strengths**: Individual-level microdata theoretically allows for rich demographic controls and heterogeneity analysis by occupation (e.g., remote-compatible vs. place-bound).
- **Concerns**: PUMAs are far too large (100,000+ people) to serve as the geographic unit for a boundary discontinuity design. The $75K+ income threshold in the tabulated data is too low to capture the "elite" mobility that is most sensitive to top marginal tax rates.
- **Novelty Assessment**: Medium. Using ACS microdata for border RDDs is somewhat common, but applying it to tax migration with occupational heterogeneity is a nice idea, albeit fatally poorly executed here due to geographic coarseness.
- **Top-Journal Potential**: Low. The geographic coarseness of PUMAs destroys the sharpness of the RDD, leading to an underpowered or biased design that top journals will reject for failing basic diagnostics.
- **Identification Concerns**: Distance from a PUMA centroid to a state border is a highly noisy running variable. Households can live dozens of miles from the centroid, completely invalidating the assumption that units just across the border are identical.
- **Recommendation**: SKIP

**#5: Idea 5: Estate Tax Threshold Notch and Elderly Out-Migration**
- **Score**: 20/100
- **Strengths**: The NY 105% estate tax cliff is a massive, fascinating policy notch that theoretically provides incredible identifying variation for behavioral responses.
- **Concerns**: The required data (jointly observing individual wealth and migration) simply does not exist in the public domain. Using aggregate ZIP-code proxies would completely destroy the sharp notch design.
- **Novelty Assessment**: High. If the data existed, linking the bunching/notch literature to elderly out-migration would be a very fresh contribution to the public finance literature.
- **Top-Journal Potential**: Low (due to fatal feasibility flaws). While the policy setting is top-tier, the lack of microdata means any empirical execution would rely on weak proxies, which top journals heavily penalize.
- **Identification Concerns**: Without individual-level wealth data, you cannot place households on the running variable (distance to the estate tax threshold). Area-level proxies suffer from severe ecological fallacy and measurement error, erasing the notch.
- **Recommendation**: SKIP

### Summary

This batch contains one outstanding proposal (Idea 1) and four deeply flawed ones. Idea 1 perfectly aligns with top-journal editorial preferences by combining a sharp spatial design, a massive policy shock, and high-quality administrative data with built-in placebos. The other ideas suffer from fatal identification flaws (Idea 4's COVID confound, Idea 3's coarse geography), data impossibility (Idea 5), or a lack of novelty (Idea 2), and should be discarded so resources can be focused entirely on Idea 1.

---

## Grok 4.1 Fast

**Tokens:** 5581

### Rankings

**#1: ZIP-Code Border RDD — State Tax Differentials and High-Income Geographic Sorting**
- Score: 88/100
- Strengths: Clean spatial RDD with multiple border pairs for internal replication, layered with TCJA SALT cap event study creating a triple-difference structure; uses universe IRS ZIP-level data to decompose extensive/intensive margins of elite sorting, enabling sufficient-statistics welfare estimates.
- Concerns: Potential attenuation from ZIP centroids (not exact addresses) or spillovers across borders; needs robust bandwidth selection and density tests to rule out sorting at the border itself.
- Novelty Assessment: Moderately novel—border RDDs exist for amenities/wages (e.g., Black 1999 housing), but combining IRS ZIP AGI stubs with SALT shock for high-income tax sorting appears first-of-its-kind, unlike coarser state-level migration studies (e.g., Young et al. 2019).
- Top-Journal Potential: High—matches editorial winners with "internal replication" across 8+ borders, legible causal chain (tax shock → sorting margins → revenue elasticity), universe-scale data, and policy stakes on federalism/tax competition; challenges "immobile rich" conventional wisdom.
- Identification Concerns: Parallel trends testable with 5+ pre-SALT years; low-income placebo verifies exogeneity, but compositional changes (e.g., remote work anticipation) could bias intensive margin without occupation controls.
- Recommendation: PURSUE (conditional on: confirming no pre-SALT bunching at borders via McCrary test; adding remote-work robustness post-2020)

**#2: State-Level IRS Migration Flows — Tax Rate Differential Panel RDD**
- Score: 68/100
- Strengths: Leverages rich IRS state-to-state flows with income brackets and long panel for SALT event study; decomposes bilateral high-income outflows, feasible with free data.
- Concerns: Tax differential as "running variable" is not sharp (endogenous policy choices, no true discontinuity); state-level aggregation loses geographic precision, risking ecological fallacy.
- Novelty Assessment: Low—state migration responses to taxes well-studied (e.g., Leigh 2008, Young 2019, Agrawal-Knight 2021 on SALT); adds little beyond existing panels.
- Top-Journal Potential: Medium—competent event study on saturated topic, but lacks tight causal channel or scale to excite top-5 (more APEJ-level); no belief-changing pivot.
- Identification Concerns: Fixed effects absorb time-invariant confounders, but dynamic tax responses and confounders like amenities/housing correlate with differentials; weak "RDD" claim undermines credibility.
- Recommendation: CONSIDER (as robustness to Idea 1, but only if paired with finer geography)

**#3: ACS Microdata Border RDD — Migration Status × Income**
- Score: 52/100
- Strengths: Individual-level ACS allows rich heterogeneity (e.g., occupation, remote-work compatibility); migration status directly observed.
- Concerns: PUMAs too large (~100K pop) for precise border discontinuity, diluting power; topcoded income at $75K+ misses true elites ($200K+).
- Novelty Assessment: Low—ACS PUMS/border RDDs common for migration (e.g., Diamond 2016 superstar cities, Autor et al. China shock); no unique angle.
- Top-Journal Potential: Low—technically sound but "competent not exciting" on saturated migration topic; imprecise ID and coarse income limit to field-journal at best.
- Identification Concerns: Large PUMAs mix border/interior, biasing discontinuity toward zero; migration status may capture short-term movers, not permanent sorting.
- Recommendation: SKIP

**#4: Remote Work Regime Change and Tax-Border Sorting (2020+)**
- Score: 42/100
- Strengths: Clever interaction of COVID flexibility shock with tax borders; reuses IRS ZIP data from Idea 1.
- Concerns: COVID massively confounded (urban exodus, health/amenity shifts); only 2-year post-period underpowered for trends.
- Novelty Assessment: Moderate—post-COVID remote/tax papers emerging (e.g., Del Carpio et al. 2023), but border-specific interaction novel; still builds on saturated COVID migration lit.
- Top-Journal Potential: Low—explicit editorial red flag for COVID confounds driving results; short window and diffuse channels read as "driven by 2020 spike."
- Identification Concerns: No way to isolate tax from amenity/health frictions; triple-diff assumes parallel trends absent COVID, but urban flight violates this.
- Recommendation: SKIP

**#5: Estate Tax Threshold Notch and Elderly Out-Migration**
- Score: 18/100
- Strengths: Intriguing NY cliff as sharp notch linking bunching/mobility literatures.
- Concerns: Fatal data gap—no public individual-level wealth + migration (ACS lacks wealth, IRS estates aggregate); proxies destroy RDD.
- Novelty Assessment: Moderate—estate notches studied for bunching (e.g., Kopczuk-Slemrod 2007), but mobility extension novel if feasible.
- Top-Journal Potential: Low—infeasible data kills it; even if possible, niche outcome without scale.
- Identification Concerns: RDD requires individual wealth-migration link, impossible publicly; area proxies confound with local amenities.
- Recommendation: SKIP

### Summary
This batch has one standout idea (Idea 1) with top-journal potential due to novel ID, scale, and replication, warranting pursuit as a lead project. Ideas 2-3 are feasible but derivative on a studied topic, suiting as supplements; 4-5 fail on confounds or data. Prioritize Idea 1 for its clean path to welfare-relevant findings on elite tax flight.

