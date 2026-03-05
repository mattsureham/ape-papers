# Research Idea Ranking

**Generated:** 2026-03-05T17:10:51.873815
**Models:** GPT-5.2, Gemini 3.1 Pro, Grok 4.1 Fast
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.2 | Gemini 3.1 Pro | Grok 4.1 Fast |
|------|------|------|------|
| Rent Control at City Borders: Capitaliza... | PURSUE (69) | — | CONSIDER (61) |
| When Zones Disappear: Priority Neighborh... | PURSUE (66) | — | CONSIDER (67) |
| Speed Limits and Road Fatalities: A Boun... | PURSUE (63) | — | PURSUE (74) |
| Speed Cameras and the Kangaroo Effect: M... | CONSIDER (56) | — | PURSUE (82) |
| Council Size and Local Spending: Multi-C... | SKIP (52) | — | SKIP (54) |
| Idea 2: When Zones Disappear: Priority N... | — | PURSUE (78) | — |
| Idea 3: Speed Cameras and the Kangaroo E... | — | CONSIDER (68) | — |
| Idea 1: Speed Limits and Road Fatalities... | — | SKIP (55) | — |
| Idea 5: Rent Control at City Borders: Ca... | — | SKIP (45) | — |
| Idea 4: Council Size and Local Spending:... | — | SKIP (35) | — |

---

## GPT-5.2

**Tokens:** 7974

### Rankings

**#1: Rent Control at City Borders: Capitalization Evidence from France's Encadrement des Loyers**
- **Score:** 69/100
- **Strengths:** First-order policy with a clean, legible outcome (asset-price capitalization) and unusually sharp “on–off–on” timing that can be exploited as a difference-in-discontinuities design at the same border. Universe transaction data (DVF) gives power to estimate tight bounds and heterogeneity (by property type, investor share proxies, etc.).
- **Concerns:** Paris’ municipal boundary is *not* a “neutral” border—housing stock, amenities, taxes, schools, and demand composition shift discretely—so a *pure* cross-sectional border RDD is not credible on its own. The suspension/reintroduction may coincide with other Paris-specific shocks (Airbnb rules, metro expansions, COVID-era preferences), complicating attribution.
- **Novelty Assessment:** **Moderate.** Rent control capitalization is heavily studied internationally; Paris has some work already, but the **border + on–off–on** combined design with DVF at full scale is plausibly novel enough if executed tightly.
- **Top-Journal Potential:** **Medium.** Rent control remains top-field/top-5 adjacent when identification is airtight and the paper delivers a mechanism chain (caps → expected rent stream → prices → tenure/renovation/supply). The “on–off–on at a sharp border” is a strong narrative hook if you can rule out differential trends.
- **Identification Concerns:** The key threat is **differential time trends at the Paris edge** (gentrification and redevelopment progressing differently inside vs outside) that survive differencing; you’ll need strong pre-trend/event-study evidence and possibly ultra-local controls (e.g., grid-cell×time FEs) to make the design persuasive.
- **Recommendation:** **PURSUE (conditional on: implementing difference-in-discontinuities/event-study at the border; demonstrating strong pre-trend stability; showing robustness to ultra-local fixed effects/bandwidth choices and excluding border segments with major concurrent projects).**

---

**#2: When Zones Disappear: Priority Neighborhood Redesignation and Property Value Responses in France**
- **Score:** 66/100
- **Strengths:** The “gain vs loss vs retain” redesignation creates an unusually rich set of built-in placebos and asymmetry tests (stigma vs subsidy vs hysteresis), and DVF provides enormous statistical power. A boundary RDD combined with time (boundary DiD/DDD) is a credible template when executed with care.
- **Concerns:** QPV boundaries were redrawn based on poverty criteria and local political/administrative processes—so boundary neighborhoods may differ in ways that evolve differently over time (selective regeneration, policing, school programs). Treatment is also a **bundle** (funding, programs, signaling), so interpretation must be disciplined (what exactly changed in 2014 at the margin?).
- **Novelty Assessment:** **Moderately high.** Place-based policies and boundary designs are common, but the **France-wide map redraw + “loss” group** with transaction-level DVF is less mined than typical enterprise-zone settings.
- **Top-Journal Potential:** **Medium.** The upside is a mechanism result (asymmetric capitalization when designation is removed vs added) plus a policy-relevant welfare interpretation (stigma vs resources). Without a sharp mechanism or a compelling “why this teaches us something general,” it risks reading as a solid but standard place-based capitalization paper.
- **Identification Concerns:** The most important pitfall is **endogenous boundary placement** interacting with time (neighborhoods just inside/outside may be on different trajectories); you’ll need extensive balance tests, boundary-placebo exercises, and possibly designs that compare only *very* local micro-areas with flexible spatial trends.
- **Recommendation:** **CONSIDER (upgrade to PURSUE if you can document program/intensity first stages and show tight pre-2014 stability in boundary discontinuities).**

---

**#3: Speed Limits and Road Fatalities: A Boundary Discontinuity at French Department Borders**
- **Score:** 63/100
- **Strengths:** Uses high-stakes outcomes (fatalities/serious injuries) with rich microdata (BAAC geocodes) and a policy reversal that generates meaningful cross-sectional variation. The “full-restoration vs neighbor retains 80” restriction is sensible and helps clarity.
- **Concerns:** Department borders are often meaningful discontinuities in geography, enforcement, road engineering standards, and driving culture—classic boundary-design fragility. Also, “restored 90” can be partial in practice (segment-level signage, compliance/enforcement), so treatment measurement must be extremely careful.
- **Novelty Assessment:** **High-ish.** The French 80→90 partial reversals are not saturated in econ journals, and the boundary discontinuity angle is less common than national time-series evaluations.
- **Top-Journal Potential:** **Low–Medium.** Traffic safety is important, but top journals typically want a broader behavioral/market mechanism or a methodological leap; otherwise it may land in strong field outlets. The paper gets more exciting if it can quantify displacement (to other roads), compliance, and welfare trade-offs cleanly.
- **Identification Concerns:** Main threat is **border discontinuities proxying unobservables**; credibility improves substantially if you can implement a “same-road-across-border” design (only road segments that physically cross the border) and show covariate smoothness in road characteristics and enforcement intensity.
- **Recommendation:** **CONSIDER (only pursue if you can: (i) precisely code segment-level speed-limit changes; (ii) implement same-road/close-network comparisons; (iii) show strong border balance/placebos).**

---

**#4: Speed Cameras and the Kangaroo Effect: Micro-Geographic Evidence from France's Automated Enforcement Network**
- **Score:** 56/100
- **Strengths:** Big administrative scale (thousands of cameras) and a clearly articulated mechanism (speed reductions near cameras with possible downstream rebound) that could be policy-relevant for optimal placement/design (fixed vs section control). Replication across many sites is a real advantage.
- **Concerns:** “Upstream vs downstream” around a camera is **not quasi-random**: cameras are placed at speed transitions, intersections, black spots, or road geometry changes—precisely where accident risk may differ directionally. Accidents are sparse at the micro level, so results may be sensitive to bandwidth/binning and road-network measurement error.
- **Novelty Assessment:** **Moderate.** Speed cameras are extensively studied; the *France-wide micro-geo displacement* angle is less common, but the conceptual question is well known.
- **Top-Journal Potential:** **Low–Medium.** Could be a strong field-paper if you convincingly isolate displacement and show implications for enforcement design; top-5 is unlikely unless identification becomes unusually persuasive and the results overturn standard beliefs about camera efficacy.
- **Identification Concerns:** The design risks conflating the camera with **local road features and speed-limit changes at the camera point**. A more credible approach would lean on **installation timing** (event-study around install) combined with tight spatial windows and camera-type contrasts (section control as a “no kangaroo” benchmark).
- **Recommendation:** **SKIP unless re-designed** around timing-based identification and/or a camera-type contrast that cleanly separates behavior from road geometry (then it becomes **CONSIDER**).

---

**#5: Council Size and Local Spending: Multi-Cutoff Evidence from 35,000 French Communes**
- **Score:** 52/100
- **Strengths:** Classic, transparent RDD with many cutoffs and a large universe of communes; data are feasible and results would be easy to explain to policy audiences. Multi-cutoff replication can be a credibility asset.
- **Concerns:** Low novelty (population-threshold RDDs and political budget cycles are heavily mined), and council size changes may have small, diffuse effects on budgets—risking a “precisely estimated zero” that doesn’t move the literature. Multiple institutional thresholds in France (electoral rules, inter-municipal structures) raise compound-treatment concerns at key cutoffs.
- **Novelty Assessment:** **Low.** The France setting is less used than Italy, but the design is extremely standard and well-trodden.
- **Top-Journal Potential:** **Low.** Unless you uncover a stark, generalizable mechanism (e.g., bargaining/fragmentation causing systematic investment distortions) with sharp welfare implications, it is likely “competent but not exciting.”
- **Identification Concerns:** Potential **manipulation/sorting around population thresholds** (administrative population adjustments, strategic behavior) and bundled rule changes at certain cutoffs can undermine causal interpretation without extensive institutional disentangling.
- **Recommendation:** **SKIP** (a reasonable institute report/working paper topic, but weak for high-impact research relative to the other options).

---

### Summary

This is a strong batch in terms of data feasibility (French open administrative microdata) and credible quasi-experimental instincts, but several ideas hinge on boundary designs where **unobserved discontinuities** are the central risk. If choosing one to start, I would prioritize **Paris rent control (Idea 5)** for its “on–off–on” leverage and broad interest, with **QPV/ZUS redesignation (Idea 2)** as the next-best option if you can document program first stages and convincingly rule out differential local trends.

---

## Gemini 3.1 Pro

**Tokens:** 10955

Here is my evaluation of the research proposals, ranked from most to least promising, applying the criteria and empirically observed editorial patterns.

### Rankings

**#1: Idea 2: When Zones Disappear: Priority Neighborhood Redesignation and Property Value Responses in France**
- **Score**: 78/100
- **Strengths**: Tests a rare and theoretically fascinating mechanism—the asymmetry and hysteresis of place-based policies (what happens when subsidies and stigma are removed?). The boundary-DDD design with a built-in placebo (retained zones) is structurally elegant and pre-empts alternative stories.
- **Concerns**: QPV boundaries were drawn using strict 200m-grid income data, meaning the "just outside" areas might be demographically discontinuous by construction. 
- **Novelty Assessment**: High. While the *introduction* of place-based policies is a heavily saturated literature, the *removal* of such zones is rarely studied, especially leveraging universe-level transaction data to test for sticky capitalization.
- **Top-Journal Potential**: High. The appendix explicitly notes that "mechanism surprises" and "composition shifts vs capitalization in place-based policy" are high-upside. If the paper can disentangle the loss of investment from the loss of stigma, it elevates from a standard policy evaluation to a field-level contribution.
- **Identification Concerns**: The primary threat is that the newly drawn boundaries perfectly isolate poverty, meaning parallel trends between the inside and outside might fail. The DDD helps, but differential gentrification trends remain a risk.
- **Recommendation**: PURSUE (conditional on: proving covariate smoothness at the boundary and parallel pre-trends).

**#2: Idea 3: Speed Cameras and the Kangaroo Effect: Micro-Geographic Evidence from France's Automated Enforcement Network**
- **Score**: 68/100
- **Strengths**: Leverages massive scale (3,400 cutoffs) to test a clear behavioral mechanism (spatial displacement/substitution) rather than just a simple policy ATE. 
- **Concerns**: Accidents are rare events, so statistical power at the micro-segment level (e.g., 100m bins) may be surprisingly low despite the 20-year horizon.
- **Novelty Assessment**: Medium-High. The "kangaroo effect" is well-known in the transport literature but rarely identified with this level of micro-geographic precision and scale in mainstream economics.
- **Top-Journal Potential**: Medium. Fits the appendix pattern where "scale is treated as scientific content when it tightens what can be ruled out." However, it risks being viewed as a niche transport paper unless explicitly framed around the broader economics of localized enforcement and substitution/offset effects.
- **Identification Concerns**: Cameras are endogenously placed at accident blackspots, often where road geometry (curves, intersections) changes. Upstream and downstream segments may therefore have fundamentally different baseline accident risks.
- **Recommendation**: CONSIDER

**#3: Idea 1: Speed Limits and Road Fatalities: A Boundary Discontinuity at French Department Borders**
- **Score**: 55/100
- **Strengths**: Uses a clean spatial RDD to evaluate a highly salient policy reversal, allowing for a modern calculation of the Value of a Statistical Life (VSL).
- **Concerns**: The core question (do lower speed limits reduce accidents?) is entirely conventional, and the specific French policy has already been evaluated in published literature.
- **Novelty Assessment**: Low-Medium. The spatial RDD approach is a methodological upgrade, but the topic itself is heavily saturated.
- **Top-Journal Potential**: Low. This perfectly matches the appendix's modal loss: "standard DiD/RDD + unsurprising sign/null + narrow margin." It is a competent but unexciting ATE that lacks a mechanism surprise or a belief-changing pivot.
- **Identification Concerns**: Drivers cross department borders, creating spatial spillovers (e.g., accelerating after leaving an 80 km/h zone). Furthermore, department borders bundle other local policies like police enforcement and road maintenance budgets.
- **Recommendation**: SKIP

**#4: Idea 5: Rent Control at City Borders: Capitalization Evidence from France's Encadrement des Loyers**
- **Score**: 45/100
- **Strengths**: The "on-off-on" legal history of the Paris rent control policy provides a unique quasi-experiment to test for hysteresis in capitalization.
- **Concerns**: The Paris municipal boundary is the Boulevard Périphérique, a massive multi-lane ring road that acts as a severe physical and demographic cliff, destroying the RDD assumption.
- **Novelty Assessment**: Medium. Rent control capitalization is well-studied, but the triple policy variation (implementation, suspension, reimplementation) is a fresh angle.
- **Top-Journal Potential**: Low. The appendix explicitly warns that "Endogenous sorting at administrative boundaries (BDD/RDD)" is a fatal flaw. Reviewers will immediately recognize the Périphérique as a massive confounder, reclassifying the paper as a cautionary tale at best.
- **Identification Concerns**: The boundary is not arbitrary; it separates fundamentally different housing markets (Paris vs. Banlieue) with different amenities, tax rates, and demographics, violating the core spatial RDD assumption of smooth confounders.
- **Recommendation**: SKIP

**#5: Idea 4: Council Size and Local Spending: Multi-Cutoff Evidence from 35,000 French Communes**
- **Score**: 35/100
- **Strengths**: Huge sample size and multiple cutoffs provide excellent statistical power and internal replication.
- **Concerns**: This exact design has been done repeatedly in other countries, and the French population thresholds are known to be manipulated by mayors.
- **Novelty Assessment**: Very Low. The effect of council size via population thresholds is a textbook RDD example with dozens of existing papers (e.g., Italy, Brazil, Sweden).
- **Top-Journal Potential**: Low. It is the definition of "technically competent but not exciting" and suffers from a known, fatal identification flaw.
- **Identification Concerns**: Precise manipulation of the running variable. Eggers et al. (2018) explicitly showed that French communes manipulate their census population counts to sort around these exact thresholds, invalidating the RDD.
- **Recommendation**: SKIP

### Summary

This batch contains one highly viable idea, one solid backup, and three that should be discarded due to saturated literatures or fatal identification flaws. I strongly recommend pursuing **Idea 2**, as it tackles a novel theoretical angle (policy hysteresis and stigma) with a robust design, fitting the profile of high-upside papers that uncover mechanism surprises. **Idea 3** is worth considering if framed carefully around behavioral substitution, but Ideas 1, 4, and 5 suffer from the classic "competent but unexciting" or "broken boundary" traps that lead to swift editorial rejections.

---

## Grok 4.1 Fast

**Tokens:** 6858

### Rankings

**#1: Speed Cameras and the Kangaroo Effect: Micro-Geographic Evidence from France's Automated Enforcement Network**
- **Score**: 82/100
- **Strengths**: Massive replication across 3,400+ cameras provides exceptional power and internal validity, directly quantifying a discussed-but-unmeasured mechanism (spatial displacement/"kangaroo effect") with universe-level geolocated accident data. Pairs clean local RDDs with heterogeneity (camera/road types) and policy trade-offs, enabling welfare analysis of enforcement spillovers.
- **Concerns**: Relies on accidents as a precise proxy for risk (could miss near-misses or severity shifts); pre-camera trends or road-specific confounders (e.g., curves post-camera) need rigorous placebos.
- **Novelty Assessment**: High—spatial displacement rarely tested at micro-scale; French open data enables first large-scale quantification, unlike aggregate before/after studies.
- **Top-Journal Potential**: High. Mechanism surprise (offset/substitution in enforcement) fits editorial preference for trade-offs over raw ATEs; universe-scale replication + tight bounds on displacement echo winning "scale as content" papers (e.g., T-MSIS claims), with clear policy counterfactual for camera placement.
- **Identification Concerns**: Strong—running variable is physical distance along road (exogenous to accidents); multi-camera replication kills site-specific confounds. Main threat: unobserved driver anticipation beyond local segments, testable via upstream placebos.
- **Recommendation**: PURSUE (conditional on: road-network matching validation; severity-heterogeneity extension)

**#2: Speed Limits and Road Fatalities: A Boundary Discontinuity at French Department Borders**
- **Score**: 74/100
- **Strengths**: Clean spatial discontinuity exploits staggered reversals in full-restoration departments, yielding causal speed-safety estimates and VSL welfare calc with long post-periods (5+ years) and universe accidents. Superior to prior time-series/group designs.
- **Concerns**: Department borders may proxy geography/demographics (e.g., rural density), risking smooth-crossing violation despite pairing; limited to secondary roads narrows external validity.
- **Novelty Assessment**: High—no prior RDD/BDD on French reversals; builds on but transcends national ITS studies.
- **Top-Journal Potential**: High. Challenges speed-limit consensus with trade-off (safety vs time), first-order policy stakes, and sufficient-statistic VSL; "causal chain" (speed → accidents → welfare) aligns with winning arcs, though niche to France.
- **Identification Concerns**: Border smoothness assumption vulnerable to admin sorting (editorial red flag); needs covariate balance, pre-trends, and full vs partial-restoration falsification.
- **Recommendation**: PURSUE (conditional on: covariate balance tests across multiple border pairs; VSL robustness)

**#3: When Zones Disappear: Priority Neighborhood Redesignation and Property Value Responses in France**
- **Score**: 67/100
- **Strengths**: Tests asymmetry/hysteresis in place-based policy (gain vs loss of status) via boundary DDD with built-in retained-area placebo, using universe transactions for precise capitalization. Mechanism potential (stigma vs investment) adds depth.
- **Concerns**: Zone boundaries likely endogenous (drawn on poverty), biasing smoothness; short post-period for losses may underpower hysteresis detection.
- **Novelty Assessment**: High—no RDD on QPV/ZUS transition with DVF; gain/loss framing fresh for hysteresis.
- **Top-Journal Potential**: Medium. Asymmetry could yield mechanism surprise, but place-based capitalization is crowded; lacks field-level puzzle pivot, reading as "competent boundary study" without belief-changing scale.
- **Identification Concerns**: Endogenous boundary drawing risks sorting (common BDD pitfall); DDD helps but needs pre-2014 balance and no-jump placebo in retained zones.
- **Recommendation**: CONSIDER

**#4: Rent Control at City Borders: Capitalization Evidence from France's Encadrement des Loyers**
- **Score**: 61/100
- **Strengths**: "On-off-on" quasi-experiment at Paris border tests hysteresis uniquely, with massive Ile-de-France transactions for capitalization effects in hot policy area.
- **Concerns**: Municipal borders correlate with amenities/zoning (e.g., Paris center premium), violating exogeneity; suspension/reimplementation may confound with market trends.
- **Novelty Assessment**: Medium—Paris rent control studied (e.g., Chapelle & Eymeoud), but boundary RDD + triple variation novel.
- **Top-Journal Potential**: Medium. Builds on AER rent-control canon (SF/Berlin), but border endogeneity demotes to field-journal; no clear mechanism beyond ATE capitalization.
- **Identification Concerns**: Severe sorting at city borders (editorial "cautionary tale" pattern); needs owner-occupier placebo and market-wide controls to kill alternatives.
- **Recommendation**: CONSIDER (conditional on: strong owner-placebo and multi-city replication)

**#5: Council Size and Local Spending: Multi-Cutoff Evidence from 35,000 French Communes**
- **Score**: 54/100
- **Strengths**: Multi-cutoff RDD with 35k communes offers replication and decomposition (e.g., vs voting changes); fiscal data comprehensive.
- **Concerns**: Population thresholds induce sorting (per Eggers 2018); council-size effects well-studied elsewhere (Italy/Brazil), yielding incremental contribution.
- **Novelty Assessment**: Low—threshold RDD validated (Eggers); council-spending link replicated internationally, absent France-specific twist.
- **Top-Journal Potential**: Low. "Competent but not exciting" modal loss: unsurprising fiscal ATE without mechanism surprise or welfare pivot; crowded legislator-size literature.
- **Identification Concerns**: Sorting/manipulation at thresholds (density tests needed); bundled cutoffs (e.g., 1k voting) confound separation.
- **Recommendation**: SKIP

### Summary
This is a strong batch overall, leveraging France's exceptional open data for quasi-experimental policy tests—several could yield policy-relevant mechanisms with top-field potential. Prioritize Idea 3 for its scale-powered offset quantification and Idea 1 for VSL trade-offs; the boundary designs (2,4,5) risk editorial skepticism on sorting, while Idea 4 feels too trodden. Pursue the top two to capitalize on road-safety freshness.

