# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T11:08:48.705397
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 18927 in / 5557 out
**Response SHA256:** 3c54ae5205417b62

---

This paper asks a clear and interesting policy question: did the EU’s 2017 abolition of retail roaming surcharges increase cross-border tourism? The paper’s core empirical design compares border and interior NUTS2 regions before and after the policy, and the headline finding is a precise null in specifications with country-by-year fixed effects.

The paper has several appealing features: a salient policy, transparent treatment timing, a plausible geography-based exposure margin, and an admirable effort to probe the null with event studies, placebo outcomes, leave-one-out checks, and few-cluster inference. The paper is also commendably explicit that its outcome captures accommodation nights rather than all travel.

That said, I do not think the paper is publication-ready in its current form for a top general-interest journal or AEJ: Economic Policy. The main reason is not that the paper finds a null, but that the identification and interpretation still rest on a fairly coarse exposure design whose validity is not yet fully established, and some aspects of the implementation raise substantive concerns. The paper is potentially publishable after substantial revision, but it needs a more convincing treatment of who is actually exposed, how exposure is measured, and whether the preferred identifying assumptions hold in the specification that drives the conclusions.

## 1. Identification and empirical design

### A. Core design: plausible but currently not fully convincing

The paper’s main design is a standard two-group DiD:

- treated: internal EU land-border NUTS2 regions,
- control: interior regions (and in some specifications external-border regions),
- treatment date: 2017.

Because treatment timing is common, the paper avoids the most severe staggered-adoption TWFE problems. That is a strength.

However, the causal claim is stronger than the design currently warrants. The identifying assumption is that, absent RLAH, border and interior regions would have had parallel trends in foreign tourist nights, conditional on fixed effects (and in the preferred model, country-by-year fixed effects). That assumption is not implausible, but it is demanding because border regions differ structurally from interior regions in many ways that can differentially matter for tourism trends: accessibility, road/rail infrastructure, shopping tourism, labor mobility, exchange-rate salience near borders, and exposure to neighboring-country shocks.

The paper partially addresses this with event studies and placebos, but not enough in the exact preferred specification.

### B. The preferred specification is stronger, but its identifying content needs more validation

The preferred model is Equation (3) / Table 1 Column (3): region fixed effects plus country-by-year fixed effects. This is a sensible direction, because it compares border and interior regions within the same country-year.

But two issues remain:

1. **The paper’s pre-trend evidence is not aligned with the preferred specification.**  
   The event study in Section 5.2 appears to be based on Equation (4), which includes year fixed effects, not country-by-year fixed effects. If the paper’s main conclusion relies on Column (3), then pre-trends should be shown for that exact identifying variation: border vs. interior within country over time. A clean pre-trend in the simpler FE structure does not establish a clean pre-trend in the preferred one.

2. **The large drop in the estimate and standard error from Column (1) to Column (3) needs more careful interpretation.**  
   The paper emphasizes that the estimate falls from 0.124 to 0.010 and the SE from 0.109 to 0.016. This could indeed reflect removal of country-level confounding and residual variance. But it could also indicate that the identifying variation in Column (1) was dominated by cross-country composition differences rather than the intended within-country border contrast. That is not fatal, but it means the paper should be much more explicit that the substantive conclusion rests almost entirely on the within-country comparison, and should demonstrate that this comparison is meaningful in a broad set of countries rather than being driven by a handful with both border and interior regions and complete data.

### C. A potentially important classification issue: treatment geography appears inconsistent for Ireland/UK

The sample construction in the Data Appendix includes Ireland but excludes the UK. That creates a substantive problem for border classification during the treatment period. Through 2019, Northern Ireland/UK was part of the EU for the purposes relevant to the 2017 policy implementation window. If UK NUTS2 regions are excluded from the adjacency algorithm, Irish regions bordering Northern Ireland will be misclassified as not sharing an internal EU border during the relevant period.

This is not a trivial detail. It means the treatment assignment may be historically inconsistent with the policy environment in the estimation period. More generally, the border classification is static, based on a 2016 vintage shapefile and an EU/EEA-country adjacency set that does not seem to align fully with the treatment-era institutional map.

This needs to be fixed or at least carefully audited country by country. At minimum:

- include UK regions in the adjacency classification for pre-2020 years, even if the UK is not otherwise kept in the estimation sample;
- clarify how Irish border regions are classified;
- provide a reproducible list of all treated regions.

Until this is resolved, I do not think the treatment definition is fully credible.

### D. Exposure is measured too coarsely relative to the mechanism

The paper’s mechanism is explicitly about short, spontaneous cross-border trips and digital frictions near borders. But the treatment is simply “NUTS2 touches an internal land border.” NUTS2 regions are large and heterogeneous. Many “border” regions are not meaningfully close to the border in tourism activity terms; many “interior” regions may be highly exposed to foreign visitors through airports and urban tourism.

This attenuation is acknowledged qualitatively, but for publication the paper should do more than acknowledge it. It should directly test whether results are robust or stronger under more behaviorally relevant exposure measures, such as:

- share of population within X km of an internal EU border,
- distance from the regional population-weighted centroid to the nearest internal border,
- border length normalized by area,
- travel-time-based accessibility to a foreign urban center,
- adjacency to a major neighboring-country population center,
- exclusion of very large NUTS2 regions where border-touching is especially noisy.

The current “distance-based treatment” in Section 7 is only mentioned briefly and seems still quite reduced-form; more detail is needed.

### E. The outcome includes many untreated observations, which weakens interpretation

The paper is appropriately candid that “foreign nights” include non-EU visitors who were never treated by RLAH. This is a serious attenuation issue. It does not invalidate the design, but it materially limits the interpretation of a null estimate as evidence that roaming charges were not important for travel.

If, for example, the share of EU-origin foreign nights varies across border and interior regions or changes over time, the treatment intensity is heterogeneous in a way not captured by the binary design. A region with many Swiss, US, or Asian visitors is much less exposed than one with mostly nearby EU-origin tourists.

This can likely be improved. Eurostat tourism data often include origin-country breakdowns at some aggregation level, even if not always at NUTS2-year. If origin-specific regional tourism data exist even for a subset of countries or years, the paper should exploit them. Short of that, country-level composition weights could be used to construct a more meaningful exposure index.

As it stands, the paper identifies the effect of RLAH on total foreign accommodation nights, not on the subset actually exposed to the policy. That distinction should be much more central in the interpretation.

### F. Timing: annual data and a mid-2017 treatment date

The policy begins on June 15, 2017, but the baseline post indicator equals 1 for all of 2017 onward. This is not wrong, but it is coarse and likely attenuates effects. The paper does provide a robustness check excluding 2017, and that is helpful.

Given the annual nature of the data and the sharp mid-year treatment date, I would prefer the paper to make the 2018–2019 post period the main specification, not just a robustness check. With annual data, treating all of 2017 as post is hard to defend as the primary analysis.

## 2. Inference and statistical validity

### A. Main estimates report uncertainty appropriately

A major strength is that the paper does report standard errors for all main estimates and supplements country-clustered inference with wild cluster bootstrap p-values. With 27 clusters, asymptotic CRVE is not ideal, so the bootstrap is appropriate and important.

This is one of the stronger parts of the paper.

### B. But some inferential objects need to match the preferred design more closely

As noted above, the joint pre-trends test should be reported for the preferred country-by-year FE event study, not only for the simpler event study. Likewise, placebo outcomes should be estimated under the same preferred FE structure where possible.

The current domestic placebo in Table 1 Column (5) is not fully parallel to the preferred foreign-tourism specification because it does not include country-by-year FE. That weakens the placebo’s value. The paper should report:

- domestic tourism with country-by-year FE,
- ideally an event study for domestic nights under the preferred FE structure,
- if available, placebo outcomes even less likely to respond to roaming (e.g., domestic accommodation nights in clearly non-border-exposed categories, or nights by non-EU foreigners if origin data are available).

### C. Sample-size coherence is mostly transparent, but some design consequences deserve more attention

The paper is admirably transparent about different observation counts across columns and explains singleton removal in the country-by-year FE model. That is good.

Still, the fact that the preferred specification drops 37 singleton observations and reduces the region count from 238 to 231 is not itself concerning; what matters is whether the effective identifying sample remains representative. The paper should show:

- which countries/regions are lost,
- whether treated-control comparisons exist within each country,
- how many countries contribute identifying variation in the preferred model,
- leverage or influence diagnostics at the country level.

### D. The external-border placebo is underpowered and should be interpreted cautiously

Table 2 Column (2) compares internal vs external border regions, but there are only 7 external-border regions in the sample. This is too thin for a strong placebo claim. The paper should present this as a weak suggestive check, not a serious placebo design.

## 3. Robustness and alternative explanations

### A. Robustness effort is good, but too much weight is placed on checks that do not resolve the main identification concern

The paper reports leave-one-out, matching, population weighting, placebo timing, Rambachan-Roth sensitivity, exclusion of 2017, and distance-based treatment. This is a solid robustness menu.

But several of these checks are not very probative for the core concern:

- **CEM on pre-treatment foreign nights and population** does not address unobserved trend differences.
- **Leave-one-country-out** is useful for influence but not for identification.
- **Rambachan-Roth** is only as informative as the underlying pre-trend/event-study setup; again, it should be tied to the preferred specification.
- **Placebo timing** on a short pre-period is helpful but limited.

The highest-value robustness checks are those that sharpen exposure and align with the preferred within-country design. Those are currently underdeveloped.

### B. Mechanism discussion is thoughtful but not empirically established

Section 6 is well reasoned, but the paper sometimes slips from “consistent with” to “suggests that binding constraints are not digital.” The mechanism claims are not directly tested. The data do not distinguish among:

- no effect because roaming was inframarginal,
- no effect because the treated share of foreign tourism is too small,
- no effect because accommodation nights miss day trips,
- no effect because border classification is noisy,
- no effect because any gains occurred in interior urban destinations as well.

This is especially important because the paper’s favored interpretation—digital barriers are shallow while cultural/institutional barriers are deep—is broader than the evidence can bear. It is a plausible interpretation, but not the only one.

### C. External validity and limitation statements are partly good, but still understate an important boundary

The paper does acknowledge that day trips may be the most elastic margin and that accommodation nights may miss them. This is a central limitation, not a secondary caveat. If the policy primarily affected same-day cross-border visits, the chosen outcome may be close to the wrong outcome for the mechanism the paper itself emphasizes.

That does not kill the paper, but the conclusion should shift from “RLAH did not increase cross-border mobility” toward “RLAH did not detectably increase foreign accommodation nights in border regions.”

## 4. Contribution and literature positioning

The contribution is potentially meaningful: most work on RLAH focuses on telecom usage and welfare, and this paper asks whether there were broader real-economy spillovers. That is a worthwhile question.

Still, the literature positioning could be improved in two directions.

### A. More on tourism and border-crossing behavior

The paper situates itself in the border effects and infrastructure literatures, but it would benefit from closer engagement with literatures on:

- cross-border shopping and day-trip behavior,
- tourism demand near national borders,
- local integration effects in Schengen/European border regions,
- mobile connectivity and travel behavior.

The current references are somewhat broad and canonical, but not especially close to the empirical margin being studied.

### B. More on modern DiD practice as it relates to this design

Although staggered-adoption problems do not arise here in the same way, the paper would benefit from citing and discussing modern DiD guidance on identifying assumptions and event-study interpretation. Concrete additions could include:

- Roth (2022), on pre-test limitations and event-study interpretation;
- Goodman-Bacon (2021), for DiD decomposition logic more generally;
- de Chaisemartin and D’Haultfoeuille (2020), if only to clarify why the usual staggered-TWFE concerns are less central here.

These are not strictly necessary for estimation, but they would improve the methodological positioning.

## 5. Results interpretation and calibration of claims

### A. The empirical conclusion is mostly well calibrated

The paper generally does a good job not overselling statistical significance. The preferred estimate is small and imprecise enough to rule out large effects while still allowing modest positive or negative effects. That is a useful result.

### B. But several broader claims are too strong relative to the evidence

The following claims should be toned down:

1. **“Roaming charges were inframarginal to the overnight travel decision.”**  
   This is plausible, but not established. The data are also consistent with exposure mismeasurement and outcome mismatch.

2. **“RLAH did not move the needle on deeper integration objectives.”**  
   That goes beyond accommodation nights in border regions.

3. **“The barriers that prevent people from moving between EU member states are not primarily financial.”**  
   This is too sweeping given the empirical design.

4. **The analogy that the policy was “oiling a door that was never locked.”**  
   This is rhetorically sharp but stronger than the evidence supports.

The paper should instead emphasize that it finds no detectable effect on a particular, economically important margin—foreign overnight stays in border regions—despite strong first-stage evidence on mobile usage.

### C. Some “null precision” claims are overstated

The abstract and introduction say the null is “not driven by imprecision.” That is only partly true. In the preferred specification, the estimate is precise enough to rule out large effects, but not to rule out small-to-moderate effects on the treated subgroup once attenuation is considered. Given the inclusion of untreated foreign visitors and a noisy exposure measure, the estimate on total foreign nights may be quite diluted relative to the underlying causal effect on EU short-trip tourism.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Audit and correct treatment classification, especially UK/Ireland and time-consistency of borders
- **Why it matters:** If Irish regions are misclassified because UK regions were excluded from adjacency despite UK membership during the treatment period, treatment assignment is substantively wrong.
- **Concrete fix:** Rebuild the border-classification algorithm using the institutional map relevant for each year, or at minimum for the pre-2020 treatment period. Include UK NUTS2 regions in adjacency calculations for classification. Provide a table listing every treated region and its classification rationale.

#### 2. Show pre-trends and event-study evidence for the preferred country-by-year FE specification
- **Why it matters:** The paper’s conclusion rests on Table 1 Column (3), but the main pre-trend evidence appears tied to a different specification.
- **Concrete fix:** Estimate an event study with region FE and country-by-year-comparable identifying structure if feasible (e.g., border × year with region FE and country-specific year effects, omitting the appropriate baseline). Report joint pre-trend tests and plots for this preferred design.

#### 3. Make the post-2018 specification primary, not ancillary
- **Why it matters:** Annual data with a June 15, 2017 treatment date make the baseline post coding coarse and attenuating.
- **Concrete fix:** Redefine the main post period as 2018–2019, with 2017 dropped. Keep the current version as a robustness check.

#### 4. Strengthen the measurement of exposure to RLAH
- **Why it matters:** “Touches internal border” at NUTS2 level is too noisy relative to the mechanism.
- **Concrete fix:** Add one or more richer exposure measures: border-distance-to-centroid, share of population within 25/50 km of a border, border length/area, travel-time accessibility to foreign cities. Make one of these the main alternative specification.

#### 5. Reframe the causal claim to match the observed outcome
- **Why it matters:** The current interpretation sometimes exceeds what the data can support.
- **Concrete fix:** Narrow claims throughout to “foreign accommodation nights” unless the paper adds data on border crossings or day trips. Tone down assertions about overall cross-border mobility and deep integration.

### 2. High-value improvements

#### 6. Improve the link between policy exposure and tourist composition
- **Why it matters:** The outcome includes many non-EU foreign visitors who were never treated.
- **Concrete fix:** If possible, use visitor-origin composition data to construct region-level treatment intensity based on the share of visitors from EU/EEA countries. If region-level origin data are unavailable, use country-level or destination-level composition to build an exposure-weighted measure.

#### 7. Estimate placebo outcomes under the same preferred FE structure
- **Why it matters:** Placebos are most informative when they mirror the main identifying variation.
- **Concrete fix:** Re-estimate domestic-tourism placebo with country-by-year FE; add event-study placebo if possible.

#### 8. Report the effective identifying sample for the preferred model
- **Why it matters:** With country-by-year FE, some countries may contribute little or no within-country identifying variation.
- **Concrete fix:** Add a table listing, by country, number of border and interior regions, usable observations, and whether the country contributes identifying variation.

#### 9. Clarify and justify the continuous-treatment specification
- **Why it matters:** Pre-treatment foreign share is not a clean measure of RLAH intensity; it may reflect endogenous tourism specialization.
- **Concrete fix:** Either downweight this specification in the narrative or replace it with a more defensible exposure measure tied to likely EU-origin short-stay tourism.

#### 10. Moderate the interpretation of the external-border placebo
- **Why it matters:** With only 7 external-border regions, the placebo has little power.
- **Concrete fix:** Present it as suggestive only and avoid strong inferential language.

### 3. Optional polish

#### 11. Expand literature positioning toward border tourism and cross-border local mobility
- **Why it matters:** It will help readers see the paper’s niche more clearly.
- **Concrete fix:** Add a short discussion of border-tourism/day-trip literature and how this paper differs.

#### 12. Quantify what effect sizes are ruled out on the treated margin under plausible attenuation
- **Why it matters:** This would help interpret the null more economically.
- **Concrete fix:** Provide a back-of-the-envelope attenuation adjustment under plausible shares of EU-origin foreign nights and likely treatment concentration near borders.

#### 13. Provide more details on the distance-based treatment and matching implementation
- **Why it matters:** These checks are currently too compressed to evaluate.
- **Concrete fix:** Move full estimates and construction details to the appendix.

## 7. Overall assessment

### Key strengths
- Important and policy-relevant question.
- Clean common treatment timing.
- Transparent presentation of main results.
- Serious attention to inference, including wild cluster bootstrap.
- Honest engagement with null results rather than specification searching for significance.
- Good awareness of outcome limitations.

### Critical weaknesses
- Treatment classification appears potentially inconsistent with the actual policy geography, especially around Ireland/UK.
- The main pre-trend evidence is not shown for the preferred specification.
- Exposure is measured too coarsely relative to the mechanism.
- The outcome substantially mixes treated and untreated foreign visitors.
- Interpretation sometimes overreaches from “no effect on foreign accommodation nights” to “no effect on cross-border mobility/integration.”

### Publishability after revision
I think this project is promising and potentially salvageable. The null result itself is not a problem; indeed, it could be valuable. But the paper needs a materially stronger treatment of exposure measurement, sample/treatment classification, and alignment between the preferred specification and the validating evidence. If those issues are addressed convincingly, the paper could become a solid contribution. In its current form, however, it is not yet ready for publication in the outlets named.

DECISION: MAJOR REVISION