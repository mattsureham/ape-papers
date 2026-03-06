# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-06T13:24:00.631342
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 15495 in / 5987 out
**Response SHA256:** 46fcb8ffcb80a273

---

This paper asks an important, policy-relevant question: whether France’s low-emission zones (ZFEs) capitalized into housing prices. The paper’s core message—that naïve boundary TWFE estimates are badly misleading, while a staggered-adoption estimator yields a near-zero effect—is potentially valuable both substantively and methodologically. The administrative transaction data are strong, the policy setting is salient, and the paper is refreshingly explicit that its own headline TWFE result is not credible.

That said, I do not think the paper is yet publication-ready for a top general-interest journal or AEJ: Economic Policy. The central problem is that the paper’s preferred identification strategy is not yet sufficiently defended relative to the difficulty of the design. The paper convincingly shows that the naïve inside/outside boundary TWFE is confounded. But it does not yet fully establish that the Callaway–Sant’Anna (CS) estimate recovers the causal effect of interest, nor that the inference around that estimate is fully persuasive given the small number of treated cohorts/cities and the aggregation choices. In short: the paper does a strong job falsifying one design, but a less complete job validating the replacement design.

Below I focus on scientific substance and publication readiness.

---

## 1. Identification and empirical design

### Main identification idea

The paper begins with a boundary DiD comparing properties inside vs. outside ZFE polygons around adoption, then pivots to CS-DiD exploiting staggered city adoption timing (Sections 4–5). The paper’s diagnosis of the boundary TWFE is persuasive: ZFE boundaries are not quasi-random and instead track the urban–suburban divide, so inside/outside comparisons are contaminated by differential trends in city-center versus periphery prices. The event-study evidence, bandwidth pattern, and commercial placebo all point in the same direction.

However, the preferred CS design still requires stronger justification.

### A. What exactly is the identifying contrast in the preferred estimator?

In Section 4.3, the paper states that communes inside a ZFE boundary are treated when the city adopts, while communes outside are coded never-treated; the control group also includes inside-boundary communes in not-yet-treated cities. This means the preferred estimator is not a pure “inside-treated across cities” design; it is a mixed design combining:

1. inside-treated vs. outside-never-treated comparisons within and across cities, and  
2. earlier-treated inside communes vs. later-treated inside communes across cities.

This matters because the paper’s substantive critique of the TWFE design is that inside and outside differ structurally in urban form and trends. Yet the CS implementation still relies, at least in part, on outside communes as never-treated controls. The paper says CS “purges” the urban–suburban confound by using not-yet-treated cities as controls, but the actual implementation still includes outside-boundary communes as never-treated units. That is a weaker claim than the text often suggests.

**Why this matters:** If inside–outside trend differences vary across cities and are correlated with adoption timing—as the paper itself acknowledges in Section 4.4—then the CS estimator may still be biased. The current draft recognizes this as a threat, but treats the CS pre-trends as largely dispositive. They are not yet enough.

**Concrete needed clarification:** Decompose the estimator’s identifying variation. Report how much weight comes from:
- inside treated vs. inside not-yet-treated;
- inside treated vs. outside never-treated within treated cities;
- inside treated vs. outside never-treated in other cities.

A clean way to strengthen the paper would be to estimate a specification using only inside-boundary units, comparing earlier- to later-adopting cities, possibly with city fixed effects and cohort/event-time structure at the city or finer spatial level. If the result remains near zero in an “inside-only” design, that would much more directly address the central confound the paper emphasizes.

### B. Spatial unit choice is not yet fully convincing

The paper aggregates to commune-quarter cells for the CS estimator. But communes are administratively large and heterogeneous spatial units, and in many cities they are precisely the units along which urban core/periphery segmentation occurs. It is not clear that commune aggregation preserves the relevant within-boundary variation or avoids ecological bias.

Moreover, the paper states that CS-DiD “requires a balanced panel” and therefore aggregation (Appendix, Identification Appendix). That is not correct as a general statement about the `did` framework. This raises concern that the aggregation choice is driven more by convenience than design.

**Why this matters:** Aggregating to commune-quarter means can create composition bias if the mix of transacted properties changes over time within commune. The paper says hedonic controls address composition in the transaction-level regressions, but the CS estimation on means appears not to be hedonic-adjusted in an equivalent way.

**Concrete fix:** Re-estimate the preferred design at the transaction level if computationally feasible, or at least at a much finer spatial cell (e.g., IRIS, grid-cell, or boundary-bin-by-quarter). If aggregation must remain, construct hedonic-residualized prices first (e.g., residualize log price/m² on observables and flexible location effects) and then aggregate residuals. At minimum, show that results are robust to:
- median rather than mean prices,
- repeat-sales subsample if possible,
- constant-quality price indices within commune-quarter,
- transaction-count weighting choices.

### C. Spillovers are likely first-order, not a secondary concern

The paper notes that spillovers may bias boundary estimates upward because traffic may be displaced outside the zone (Section 4.4). But in the preferred CS setup, outside-boundary communes are coded never-treated. If the policy worsens conditions just outside the zone, these are not clean controls—they are partially affected units. That could bias estimated treatment effects upward, downward, or toward zero depending on the margin.

**Why this matters:** A near-zero ATT could reflect true zero capitalization, but it could also reflect offsetting positive inside effects and negative outside spillovers if outside controls are contaminated.

**Concrete fix:**  
- Re-estimate excluding outside-boundary communes in treated metropolitan areas from the control pool.  
- Or use “inside-only” comparisons across cities.  
- Or trim controls to metros not yet treated and sufficiently distant from any active ZFE boundary.  
- Show results by distance to boundary outside the ZFE in the preferred estimator, not only in the TWFE exercise.

### D. Treatment definition is coarse relative to the policy

The paper codes treatment using each city’s first adoption date and treats the geographic boundary as fixed (Section 3.2). But the policy intensity varies substantially across cities and over time through Crit’Air tightening, enforcement regimes, hours, and practical salience. The first adoption date for a weakly enforced Crit’Air 5 restriction may be a very weak treatment.

**Why this matters:** A null average effect could arise because the treatment is mismeasured and diluted, rather than because capitalization is absent. This is especially important because the paper’s own first-stage evidence suggests modest or nonexistent pollution effects.

**Concrete fix:** Build a treatment-intensity measure:
- number/share of vehicles banned in a city-month/quarter,
- indicator for substantial tightening rather than initial launch,
- enforcement regime (camera/manual),
- fines or enforcement onset if available.

At minimum, distinguish initial weak implementation from later tighter phases. If the geography is constant but intensity changes, this is usable variation.

### E. Early adopters are important and awkwardly handled

Paris and Grenoble are excluded from the preferred CS estimate because there is no observed pretreatment period (Section 3.1, 4.3, 7.6). Yet Paris accounts for a very large share of the sample and plausibly the most salient version of the policy. The paper later notes Paris is 49% of the boundary sample (Section 7.6). This creates a mismatch between the broad framing (“France’s staggered rollout”) and the actual identified estimand (seven later adopters, not the most important early adopter).

**Why this matters:** The paper’s strongest null estimate does not identify the effect in the largest and most policy-relevant city. External validity even within France is thus narrower than the introduction and conclusion imply.

**Concrete fix:** Reframe the estimand more explicitly as late-adopting French ZFEs during 2020–2023. Also explore whether Paris/Grenoble can be studied separately using alternative designs:
- synthetic control / interrupted time series at finer spatial scales,
- ring-based comparisons with long pre-2020 non-geocoded data if some less granular source exists,
- repeat-sales around later tightening phases rather than initial adoption.

### F. Event-study evidence is informative but not sufficient as currently used

The TWFE event study is used to show pre-trends (Section 5.2). That is directionally useful. But with staggered adoption and treatment-effect heterogeneity, event-study coefficients from conventional TWFE can be contaminated. Since the paper is making a methodological point about exactly these issues, it should avoid leaning too heavily on a potentially contaminated dynamic specification to prove pre-trends.

The CS dynamic plot is more relevant, but it is described only qualitatively (“centered on zero”). The paper should report formal pre-trend tests and the underlying support by relative time.

**Concrete fix:**  
- Use a modern event-study estimator throughout (Sun–Abraham, Callaway–Sant’Anna dynamic aggregation, or de Chaisemartin–D’Haultfoeuille alternatives).  
- Report the number of cohorts and observations contributing to each relative-time coefficient.  
- Report a formal joint test of pre-treatment coefficients in the preferred dynamic design.

---

## 2. Inference and statistical validity

This is the most important area after identification. The paper is not yet fully convincing here.

### A. Standard errors for the preferred estimate need stronger support

For TWFE, commune-level clustering may be reasonable mechanically, but the effective treatment variation is at the city-by-adoption-time level, with only seven identified treated city cohorts in the preferred CS analysis and nine cities in the broader sample. That is a classic setting where conventional clustered inference can be misleadingly precise.

The paper cites the problem with city clustering because there are too few cities (Section 4.5), but that does not solve the inferential problem—it highlights it.

**Why this matters:** A standard error of 2.5 pp on the preferred ATT may be understated if treatment variation is effectively driven by a handful of cohorts/cities.

**Concrete fix:**  
- Report wild-cluster bootstrap or randomization-based inference at the city/cohort level where possible.  
- For the preferred CS estimate, conduct placebo adoption-timing permutations across cities/cohorts and report randomization-based p-values/confidence intervals for the ATT, not only for the discredited TWFE specification.  
- If possible, use leave-one-city-out plus influence diagnostics in a more formal way (e.g., jackknife standard errors).

### B. Randomization inference is currently applied to the wrong object

The paper reports randomization inference for the TWFE estimate (Section 6.4; Appendix) and finds a high mean permuted coefficient. This is useful to discredit TWFE. But the paper’s claim ultimately rests on CS-DiD, for which no comparable design-based inference is shown.

**Concrete fix:** Conduct randomization/permutation inference for the preferred estimator under reassigned adoption dates among the seven identified treated cities. This is especially important given the small number of cohorts.

### C. Sample sizes and support in CS estimation are underreported

The paper gives the transaction count in the raw sample and says the CS sample aggregates to “a few thousand commune-quarter observations” (Section 7.6), but it never reports the exact number of commune-quarter cells, number of treated communes, number of inside communes by cohort, or how balanced the panel really is.

**Why this matters:** Readers need to know whether the near-zero estimate comes from broad support or a small number of cells. This is especially important because two early adopters are excluded, two cities have sparse boundary transactions, and some cohorts are late in sample with little post-treatment exposure.

**Concrete fix:** Add a table for the preferred CS design with:
- number of treated and control communes,
- number of treated communes by cohort,
- number of pre- and post-periods by cohort,
- total commune-quarter cells,
- weighting scheme in aggregation.

### D. First-stage inference is too weak to support mechanism claims

The city-level air-quality “first stage” uses only 540 city-month observations across 9 cities (Table 3). This is coarse and likely underpowered, and the data are acknowledged to be too coarse to capture within-city treatment gradients. Yet the paper uses it several times to rationalize the null (“If air quality barely improves, there is little amenity gain to capitalize”).

This is a plausible interpretation, but the evidence presented is not strong enough to support it as anything beyond suggestive.

**Concrete fix:** Dial back the first-stage claims or obtain better pollution data. Ideally, use station-level monitor data or satellite/fused data with finer spatial resolution, and estimate boundary or inside/outside pollution effects more analogously to the housing design.

---

## 3. Robustness and alternative explanations

### Strengths

The paper does several useful things well:
- shows a large gap between naïve and staggered estimators;
- presents a commercial-property placebo;
- examines bandwidth sensitivity;
- does leave-one-city-out for CS-DiD.

These are good ingredients.

### Main remaining concerns

### A. The commercial placebo is useful but overinterpreted

Commercial prices may indeed be less sensitive to residential amenity capitalization, but they can absolutely respond to traffic restrictions, access changes, retail footfall, and city-center demand. So the result is suggestive of confounding, but it is not a “should be zero” placebo in the strong sense the paper implies.

**Concrete fix:** Recast it as a falsification with ambiguous expected sign rather than a definitive placebo. Add stronger placebo outcomes if available:
- property characteristics that should not shift discontinuously,
- pre-policy transaction volumes,
- outcomes in cities before announced but not yet implemented phases.

### B. Robustness mostly revisits the flawed TWFE design

Many of the robustness exercises (bandwidth, donut, distance gradient, heterogeneity by size/city) are informative about why TWFE fails, but they do not strengthen the preferred causal estimate. The revision needs more robustness around CS or an alternative preferred design, not more variants of the non-credible specification.

**Concrete fix:** Prioritize robustness for the preferred estimator:
- inside-only estimation;
- excluding possibly contaminated outside controls;
- treatment-intensity measures;
- alternative aggregation/weighting;
- alternative spatial units;
- dynamic effects around later tightening phases.

### C. Mechanism claims are not cleanly separated from reduced-form results

The discussion offers several explanations for the null—weak enforcement, political uncertainty, offsetting car-access disamenities, measurement horizon (Section 7.2). All are plausible, but the evidence in the paper does not distinguish among them.

**Concrete fix:** Present these explicitly as hypotheses, not as inferred mechanisms. If mechanism evidence is desired, bring in direct measures:
- enforcement intensity/citations,
- vehicle fleet composition changes,
- commuting dependence or car ownership heterogeneity,
- local air monitor changes.

### D. Anticipation and announcement effects deserve more attention

ZFEs were legislated and discussed before implementation; buyers may have anticipated adoption. The paper mentions anticipation but does not substantially analyze it beyond event-study leads. Given the limited pre-period and policy salience, anticipation could matter.

**Concrete fix:** Distinguish legal mandate announcements from implementation dates. If many effects should occur at announcement rather than enforcement, then “first adoption date” may be the wrong treatment date.

---

## 4. Contribution and literature positioning

The paper has a potentially nice dual contribution:
1. substantive evidence on ZFEs and housing capitalization;
2. a methodological warning about boundary DiD in non-arbitrary policy geographies.

That said, the literature positioning could be tightened.

### A. Contribution relative to prior environmental capitalization work is clear enough, but the closest methodological literature is underdeveloped

The paper cites Black (1999), Chay and Greenstone (2005), Goodman-Bacon (2021), Sun and Abraham (2021), and Callaway and Sant’Anna (2021). But for a paper making a methodological point about treatment timing, event studies, and boundary/policy-zone designs, it should engage more directly with the broader recent DiD literature.

### Concrete citations to add

- **de Chaisemartin, C., and X. D’Haultfoeuille (2020), “Two-Way Fixed Effects Estimators with Heterogeneous Treatment Effects,” AER.**  
  Important complement to Goodman-Bacon/Sun-Abraham on why TWFE can mislead.

- **Roth, J., P. Sant’Anna, A. Bilinski, and J. Poe (2023), “What’s Trending in Difference-in-Differences? A Synthesis of the Recent Econometrics Literature,” Journal of Econometrics.**  
  Useful for positioning pre-trend tests and modern practice.

- **Borusyak, K., X. Jaravel, and J. Spiess (2024), “Revisiting Event Study Designs,” Review of Economic Studies** (or working paper version if journal version unavailable in authors’ bib).  
  Relevant for dynamic effects and robust event-study estimation.

If there is a close literature on LEZs/ULEZs and property markets, that should also be covered explicitly. The paper currently claims “first estimate” of low-emission zone effects on housing prices. That may or may not be true, but such a claim requires especially careful verification against urban/environmental policy and transport literatures, including congestion pricing / traffic restriction capitalization studies.

### B. The current “first paper” claim should be softened unless exhaustively verified

For a top-journal paper, “first rigorous test” is a strong claim. Unless the authors have systematically checked the transport, urban, and environmental literatures—including working papers—this should be stated more cautiously.

---

## 5. Results interpretation and claim calibration

### What the paper gets right

The authors are admirably cautious about the TWFE estimates and do not sell them as causal. The preferred null estimate is presented with a confidence interval, and the paper appropriately notes that it rules out large effects more than very small ones.

### Where claim calibration still needs work

### A. “Precisely estimated zero” is somewhat too strong

The preferred ATT is -0.3 pp with SE 2.5 pp and a 95% CI of roughly [-5.2, 4.6]. That does rule out very large effects, but it does not pin the effect down tightly enough to claim “precisely estimated zero” in a broad sense—especially once one accounts for the inferential concerns above. For many urban capitalization contexts, a 4–5% effect is economically meaningful.

**Suggested calibration:** “The preferred estimates rule out large capitalization effects but remain consistent with small positive or negative effects.”

### B. The conclusion that fears of “green gentrification” are unsupported is too broad

The evidence speaks to transaction-price capitalization in a subset of French cities over a limited horizon, excluding Paris from the preferred staggered estimate and lacking rental outcomes. It does not fully speak to rents, displacement, neighborhood composition, or non-price channels.

**Suggested calibration:** The paper supports a narrower claim: no detectable large capitalization into sale prices in later-adopting French ZFEs during 2020–2024.

### C. The first-stage discussion overreaches slightly

Given the coarse pollution data, the paper should not lean heavily on the “weak first stage” to explain the null price effect. Keep this as suggestive, not as a central explanatory finding.

### D. Some numerical inconsistencies need reconciliation

The paper mentions PM2.5 falls by -0.39 in Table 3, but later in the discussion compares to a reduction of -0.66 µg/m³ (Section 7.4). That discrepancy should be corrected. More generally, all magnitudes referenced in the discussion should map cleanly to reported tables.

---

## 6. Actionable revision requests

## 1. Must-fix issues before acceptance

### 1. Validate the preferred identification strategy more directly
- **Issue:** The CS design still appears to rely partly on outside-boundary “never-treated” controls, even though the paper’s main critique is that inside/outside comparisons are structurally confounded.
- **Why it matters:** The paper currently shows TWFE is wrong, but does not yet fully prove the replacement design is right.
- **Concrete fix:** Estimate an “inside-only” staggered design comparing earlier- vs later-adopting inside-boundary units across cities. Also report results excluding outside-boundary communes in treated metros from the control pool.

### 2. Strengthen inference for the preferred estimate
- **Issue:** Standard errors may be too optimistic given few treated cities/cohorts and treatment timing variation at the city level.
- **Why it matters:** Valid inference is essential; the current SE=2.5 pp may understate uncertainty.
- **Concrete fix:** Add randomization/permutation inference and/or wild-cluster/bootstrap procedures for the preferred CS estimate at the city/cohort level.

### 3. Rework the CS implementation or justify aggregation rigorously
- **Issue:** Commune-quarter aggregation may induce composition bias; the claim that CS requires a balanced panel is inaccurate.
- **Why it matters:** The preferred estimate may reflect aggregation choices rather than economics.
- **Concrete fix:** Re-estimate at transaction level or finer spatial cells if possible; otherwise use hedonic-residualized prices and show robustness to means/medians/weights/repeat-sales or constant-quality indices.

### 4. Address spillovers explicitly
- **Issue:** Outside-boundary units may be partially treated via displaced traffic or market responses.
- **Why it matters:** Contaminated controls can bias ATT toward zero or otherwise distort sign/magnitude.
- **Concrete fix:** Exclude nearby outside units in treated metros from the control pool; show estimates using only not-yet-treated cities’ inside units or more distant controls.

### 5. Recalibrate the paper’s main claim
- **Issue:** “Precisely estimated zero” and broad claims about “green gentrification” overstate what the current design can establish.
- **Why it matters:** Top-journal standards require conclusions tightly matched to the estimand.
- **Concrete fix:** Narrow the claims to sale-price capitalization in late-adopting cities over the observed horizon; clearly separate this from rents, displacement, and earliest adopters.

## 2. High-value improvements

### 6. Exploit treatment intensity rather than only first adoption date
- **Issue:** Coding treatment at first adoption ignores variation in stringency and enforcement.
- **Why it matters:** Coarse treatment timing may attenuate true effects.
- **Concrete fix:** Build a city-quarter intensity measure using Crit’Air threshold changes, estimated vehicle shares affected, enforcement modality, or tightening phases.

### 7. Improve dynamic treatment analysis
- **Issue:** The current event-study discussion leans on TWFE dynamics that may be contaminated.
- **Why it matters:** The paper’s methodological message should itself use state-of-the-art event-study tools.
- **Concrete fix:** Report modern event-study estimates (e.g., CS/Sun-Abraham/Borusyak-Jaravel-Spiess) with support by event time and formal pre-trend tests.

### 8. Strengthen outcome construction
- **Issue:** Mean commune-quarter log price/m² may be composition-sensitive.
- **Why it matters:** Transaction composition changes can masquerade as price changes.
- **Concrete fix:** Use hedonic-adjusted residualized outcomes, medians, or repeat-sales where feasible.

### 9. Improve first-stage evidence or downweight it
- **Issue:** City-centroid CAMS data are too coarse to sustain the explanatory role assigned to them.
- **Why it matters:** Mechanism interpretation currently outruns evidence.
- **Concrete fix:** Either obtain monitor-level / finer-resolution pollution data or explicitly treat pollution results as descriptive and ancillary.

### 10. Clarify support and sample structure for the preferred estimand
- **Issue:** The paper underreports the number of treated communes/cells by cohort and the weighting in aggregation.
- **Why it matters:** Readers need to understand where the estimate comes from.
- **Concrete fix:** Add a table describing cohort sizes, treated/control counts, pre/post support, and sample shares.

## 3. Optional polish

### 11. Reposition the placebo exercise
- **Issue:** Commercial properties are not a clean zero-effect placebo.
- **Why it matters:** Overstating placebo logic weakens credibility.
- **Concrete fix:** Reframe as a falsification with ambiguous expected sign and add other placebo outcomes if available.

### 12. Tighten literature positioning
- **Issue:** The recent DiD literature is not fully represented.
- **Why it matters:** The methodological contribution needs firmer anchoring.
- **Concrete fix:** Add de Chaisemartin & D’Haultfoeuille (2020), Roth et al. (2023), and Borusyak et al. on modern event studies, and verify the “first” claim against related LEZ/congestion/property studies.

### 13. Reconcile numerical discrepancies
- **Issue:** PM2.5 magnitudes differ across sections.
- **Why it matters:** Internal consistency is necessary for trust.
- **Concrete fix:** Check all discussion magnitudes against tables and figures.

---

## 7. Overall assessment

### Key strengths
- Excellent policy question with clear public relevance.
- High-quality administrative transaction data.
- The paper does a strong job demonstrating that the naïve boundary TWFE is not credible.
- The methodological instinct is good: diagnose design failure rather than defend an attractive but confounded estimate.
- Several useful diagnostics point in a consistent direction.

### Critical weaknesses
- The preferred causal design is not yet fully validated relative to the confound the paper itself identifies.
- Inference for the preferred estimate is not yet convincing given few treated cities/cohorts.
- Aggregation choices in the CS implementation are insufficiently justified and may introduce composition problems.
- Spillovers and treatment-intensity heterogeneity are under-addressed.
- The broad substantive conclusions currently outrun the estimand and evidence.

### Publishability after revision
I think this paper is **salvageable and potentially quite good**, but it needs substantial additional work on identification and inference before it would be competitive at the target outlets. The best version of this paper may end up being as much a paper about how boundary designs fail in this setting as about the null effect itself—but then the replacement design must be especially airtight.

**DECISION: MAJOR REVISION**