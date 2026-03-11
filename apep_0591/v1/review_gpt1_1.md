# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-11T10:53:26.123588
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 27881 in / 4946 out
**Response SHA256:** 3d702b4addb2754b

---

This paper studies whether Erasmus+ outflows reduce regional human capital in Europe, using a NUTS2 panel (2014–2022) and a shift-share IV based on pre-period bilateral shares and destination-side growth. The topic is important, the new geocoded Erasmus flow data are potentially valuable, and the paper is unusually transparent about some adverse diagnostics. That said, on the current design, the paper is not publication-ready for a top general-interest journal or AEJ: Economic Policy. The central empirical claim remains much less credible than the paper’s main tables suggest.

My overall view is that the paper identifies an interesting correlation structure in the Erasmus mobility network, but does not yet convincingly isolate a causal effect of Erasmus outflows on regional human capital. The main problems are not cosmetic; they concern identification, timing, and inference. In particular: (i) the shift-share design does not survive its own most relevant diagnostics; (ii) the main estimate appears to rely heavily on cross-country rather than within-country variation; (iii) the treatment-outcome timing is poorly aligned for a stock outcome; and (iv) several interpretations of placebo and labor-market results are overstated.

## 1. Identification and empirical design

### A. Core identification is not yet credible for the causal claim

The paper is commendably explicit that the evidence is “suggestive rather than definitive” (Abstract; Introduction; Section 6.3). I agree with that assessment, and for a top journal the current identification is not strong enough.

The key problem is that the shift-share IV does not clearly satisfy either the shock-based or share-based identification logic:

1. **Shock-based interpretation (Borusyak-Hull-Jaravel): weakly supported at best, arguably contradicted by the diagnostics.**  
   The paper’s own randomization inference (RI) exercise yields a p-value of 0.446 (Introduction; Section 5.6; Figure 5), which the author correctly interprets as showing that the destination-shock component is not unusually informative relative to permuted shocks. That substantially weakens the claim that identification comes from quasi-random destination growth shocks. For a paper leaning on BHJ-style shift-share logic, this is a major problem, not a secondary caveat.

2. **Share-based interpretation (Goldsmith-Pinkham-Sorkin-Swift): not convincingly defended.**  
   The paper then pivots to a shares-based interpretation (Section 4.4), arguing that historical bilateral university agreements are plausibly exogenous. But this is not enough. Historical Erasmus partner structures are likely correlated with persistent region-specific traits that also predict future human-capital trajectories: university quality, language compatibility, pre-existing migration corridors, urbanization, elite institutional networks, and westward integration patterns. The paper provides only indirect reassurance (balance tests and the older-cohort placebo in the appendix), but these do not credibly establish share exogeneity.

For top-journal causal standards, the design currently lacks a convincing identifying variation source.

### B. Country-by-year fixed effects are a central stress test, and the paper largely fails it

The most damaging result in the paper is the attenuation to near zero after including country-by-year fixed effects (Introduction; Section 5.6; Section 6.3; Appendix Table “Robustness,” col. 5). This means the main result is driven primarily by **cross-country variation**, not within-country regional differential exposure.

That is especially problematic because many omitted factors plausibly operate at the country-year level and correlate both with Erasmus outflows and regional human-capital trends: national labor-market conditions, national higher-education policy, accession/integration dynamics, emigration cycles, housing markets, language policies, youth unemployment, and COVID recovery. If adding country×year FE eliminates the estimate, the baseline specification with only region and year FE is not adequately isolating region-specific exposure.

This is not a minor robustness issue. For the stated claim—regional human-capital divergence through Erasmus mobility—the within-country contrast is the most policy-relevant and credible source of variation. On current evidence, the paper is closer to showing that **regions in high-outflow countries differ from regions in low-outflow countries**, not that regional Erasmus outflow shocks causally reduce regional human capital.

### C. Treatment timing is not coherent for the main causal interpretation

The paper acknowledges the timing mismatch in Section 4.5, but the implications are more serious than the discussion suggests.

- The treatment is the **contemporaneous annual outflow rate** of Erasmus participants, who are typically ages 20–24.
- The main outcome is the **stock share of tertiary-educated 25–34-year-olds**.

A contemporaneous-flow / stock-outcome regression is hard to interpret causally. A mobility flow in year \(t\) should not mechanically alter the 25–34 tertiary stock in the same year unless the relevant participants are already in that age bracket or the flow proxies for lagged/cumulative exposure. The paper says the coefficient should be interpreted as a reduced-form approximation of a dynamic process (Section 4.5), but then repeatedly presents it as an effect of “a one-percentage-point increase in the Erasmus outflow rate” on the tertiary share. That causal reading is too sharp for the design.

A more coherent approach would model:
- distributed lags of outflows,
- cohort-specific exposure windows,
- event-time links between Erasmus participation ages and later residence/attainment,
- or a long-difference design with pre-specified lag structure.

The current contemporaneous specification is a major design weakness.

### D. Potential exclusion violations are under-addressed

Even if the shift-share IV is relevant, the exclusion restriction is weakly defended.

Destination-side growth in Erasmus inflows may reflect broader attractiveness shocks—economic, institutional, linguistic, or policy shocks—that independently affect sending regions through channels other than Erasmus outflows. Examples:
- labor-demand shocks in destination countries may induce ordinary migration or job search by young adults from exposed sending regions;
- destination university expansion may coincide with broader recruitment of foreign workers and graduates;
- destination-specific demand may proxy for long-standing westward orientation of certain sending regions.

Region and year FE plus GDP per capita controls do not eliminate these concerns, especially because the baseline appears to rely on cross-country variation. The leave-one-out construction only removes mechanical reflection, not omitted common shocks.

### E. The placebo logic is weaker than claimed

The 25–64 placebo (Section 5.5; Table “Placebo”) is useful, but over-interpreted.

A null effect on the broader tertiary share is **consistent** with age-specific effects, but it does not “rule out” broad economic decline or share endogeneity, as the paper sometimes claims. The 25–64 stock is heavily diluted and slow moving; many plausible confounders affecting younger cohorts disproportionately would not show up there. Indeed, the paper itself notes this in the abstract/introduction, but later overstates the evidentiary value.

Moreover, Table “Placebo” reports a statistically significant negative effect on **employment for ages 25–64** (-4.387, SE 1.932), which directly complicates the claim that older cohorts are unaffected. That result is not squarely confronted. If the older employment stock responds, the age-specific interpretation is less clean than advertised.

## 2. Inference and statistical validity

### A. It is good that uncertainty is reported, but inference is inconsistently framed

The paper reports standard errors, confidence intervals, and alternative clustering, which is a strength. However, the discussion places undue emphasis on the more favorable one-way-clustered p-values, despite strong reasons to prefer more conservative inference.

Given:
- common year-level shocks,
- a shift-share design with a limited effective number of shocks (Appendix: effective number about 15–20),
- and evidence that identifying variation is not clearly shock-driven,

the paper should treat the **two-way clustered** or shock-level appropriate inference as primary, not secondary. The abstract does mention the two-way-clustered p ≈ 0.05, which is appropriate, but much of the text still foregrounds the stronger significance under region clustering.

For a shift-share design, the paper should also engage more seriously with the appropriate level of uncertainty accounting for shock structure, not just conventional clustering. Given the limited effective number of destination shocks, asymptotic approximations may be fragile.

### B. Reported first-stage strength is not enough to rescue identification

The first stage is strong in a conventional sense (Section 5.1; Table “First Stage”). But this does not solve the more important problem: instrument validity. The paper sometimes leans heavily on the strong first stage, yet the design’s weakness is exclusion/exogeneity, not relevance.

Relatedly, the manuscript alternates between reporting an enormous F-statistic from joint 2SLS (~1,300+) and a smaller cluster-robust \(t^2\approx 97\), and to its credit it explains why the latter is more conservative. Still, in a paper where validity rather than weakness is the issue, the first-stage emphasis should be toned down.

### C. Sample sizes and specification changes need tighter reconciliation

There are several sample counts across sections/tables:
- approximately 2,920 observations in the data section,
- 2,916 in OLS main table,
- 2,792 in 2SLS,
- 2,799 in several first-stage/placebo/labor tables,
- 2,705 under country×year FE,
- 2,449 with alternative shares,
- etc.

Some variation is expected due to missing controls or instrument construction, but the paper should present a clean accounting table explaining exactly why sample sizes differ across columns. Since the conclusions are sensitive to specification, this matters substantively.

### D. The cross-sectional long-difference result is very damaging

The long-difference 2SLS has a weak first stage (F ≈ 2.4) and flips sign (Appendix Table “Cross-Sectional Long Difference”). The paper presents this transparently, which is good, but underplays how much it undermines confidence that the panel specification is recovering a stable medium-run relationship rather than short-run covariance driven by common trends.

This by itself may not kill the paper, but combined with the country×year FE attenuation and the RI failure, it strongly suggests the design is not yet robust.

## 3. Robustness and alternative explanations

### A. Robustness is broad but not yet targeted to the main threats

The paper includes:
- leave-one-country-out,
- two-way clustering,
- alternative share windows,
- COVID exclusion,
- placebo older cohort,
- randomization inference,
- heterogeneity splits.

This is a respectable set. But the most probative robustness exercises are missing or underdeveloped.

Most importantly, because the identifying variation appears cross-country, the paper needs much stronger tests against **country-level confounding**:
- country-specific linear or flexible trends,
- pre-trend event-study style checks at the country and region level,
- controls for country-year youth unemployment, graduate wages, migration rates, university expansion, and national Erasmus budgets/co-funding,
- within-country normalization of exposure,
- separate analyses in countries with substantial within-country regional variation.

Without these, the country×year FE attenuation remains a near-fatal concern.

### B. Mechanism claims are too strong relative to evidence

The paper repeatedly interprets the findings as evidence that Erasmus acts as a “stepping stone” to non-return migration and that labor-force declines reflect physical departure of workers rather than local labor demand changes (e.g., Introduction; Section 5.3; Heterogeneity discussion). But the design does not observe return migration, destination retention, or participant-level residence.

The labor-market outcomes are especially difficult to interpret:
- LFP and employment are in **levels (thousands)**, not rates.
- Larger regions naturally have larger levels; although FE absorb time-invariant size, residual demographic change may still matter.
- A one-unit increase in outflow rate predicting a 5.5-thousand drop in labor force seems very large relative to the scale of the Erasmus flows themselves and suggests the instrument may be loading on broader youth out-migration or macro conditions.

These outcomes may be interesting reduced forms, but they should not be treated as clear mechanism validation.

### C. Heterogeneity patterns are suggestive, not decisive

The stronger effects in poorer/peripheral regions are plausible and policy-relevant. However, because the baseline design itself is not secure, the heterogeneity should be framed much more cautiously.

In particular, peripheral regions differ from core regions along many dimensions directly related to the validity of the instrument: exposure shares, accession history, national migration regimes, and broader convergence/divergence trends. The interaction estimates are interesting, but not strong evidence of mechanism absent more credible identification.

### D. External validity and scope are mostly well-stated

The paper is reasonably careful in noting that the results concern intensive-margin variation in Erasmus outflows, not the effect of the existence of Erasmus itself (Section 6.5). This is appropriate. But the text sometimes slips into sweeping claims about the Erasmus program “subsidizing brain drain” that go beyond what the design can support.

## 4. Contribution and literature positioning

### A. The topic is potentially important and novel

The paper’s main contribution is clear: bring newly geolocated Erasmus flow data to a regional question about spatial human-capital divergence. That is a potentially valuable contribution, and the paper is well-motivated relative to literatures on brain drain, regional divergence, and student mobility.

### B. The literature positioning is generally good, but some methodological references should be integrated more sharply

The paper cites the key shift-share papers, but the empirical strategy would benefit from fuller engagement with recent lessons on when shift-share designs are credible and how inference should be conducted.

Concrete references that should be more centrally discussed (some already cited, but need deeper integration):
- **Borusyak, Hull, and Jaravel (2022)** — not just as inspiration, but as the benchmark the paper’s RI result struggles to satisfy.
- **Goldsmith-Pinkham, Sorkin, and Swift (2020)** — especially the implications of share-based identification and diagnostics for endogenous shares.
- **Adão, Kolesár, and Morales (2019)** — for shift-share inference and shock-level correlation.
- **Jaeger, Ruist, and Stuhler (2024)** — the paper cites this, but should engage more directly with persistent network concerns and long-run migration channels.
- Depending on exact final bibliography style, the paper may also benefit from discussing more applied work on mobility-induced regional sorting and return migration after study abroad, if available in the Erasmus context.

### C. Contribution relative to prior Erasmus work is plausible but causality should be dialed back

The contrast with participant-level Erasmus evaluations is useful. But the claim to provide “causal evidence that a specific education policy amplifies divergence” is stronger than the current design supports.

## 5. Results interpretation and calibration

### A. Main claims are often too strong relative to uncertainty and design weakness

The best parts of the paper are the places where it admits limitations. The less convincing parts are where those limitations are rhetorically overridden by strong causal language.

Examples:
- The abstract says “I find that a one-percentage-point increase … is associated with a 0.39 percentage point decline,” which is appropriately associative. Good.
- But the introduction, results, and discussion often slide into “the IV strips away confounding and reveals the underlying negative causal effect” (Section 5.2). That goes beyond the evidence.
- The older-cohort placebo is said to “rule out” broad economic decline (Section 5.5). It does not.
- The labor-market results are taken as evidence of “physical departure of workers rather than changes in labor demand” (Section 5.3). That is not established.

The paper should adopt a consistently restrained reduced-form interpretation unless and until the design is materially improved.

### B. Magnitudes are not well reconciled with the underlying arithmetic

Section 6.1 usefully notes that the estimated effect is around four times larger than a simple mechanical benchmark. But the explanations offered—cumulative exposure, peer/network multipliers, positive selection—are speculative and untested.

This matters because the large multiplier is exactly the kind of pattern that could also emerge if the IV is picking up broader migration or macro divergence rather than Erasmus-specific effects. The magnitude puzzle should be treated as a warning sign, not just an invitation for narrative mechanism.

### C. Some table-based claims are inconsistent or insufficiently addressed

Most notably:
- The placebo table shows a significant negative effect on **25–64 employment**, which complicates the age-specificity story but is not seriously discussed.
- The country×year FE result essentially erases the main effect, but the paper still spends substantial space interpreting the baseline coefficient as if it were the operative parameter.
- The reduced-form SE reported as 0.005 in the text/figure appears extraordinarily small relative to the rest of the uncertainty discussed; if correct, it further underscores that conventional residual variation is not the main inferential issue in this shift-share setting.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Rebuild the empirical design around a coherent timing structure
- **Issue:** Contemporaneous outflow rates are regressed on a stock outcome for 25–34-year-olds, creating severe interpretation problems.
- **Why it matters:** Without timing coherence, the coefficient cannot be read as a causal effect of current Erasmus outflows on regional human capital.
- **Concrete fix:** Re-estimate using distributed lags and cohort-aligned exposure measures. For example, map Erasmus outflows for ages 20–24 in years \(t-k\) to outcomes for 25–34 in year \(t\), with pre-specified lag windows. A long-difference/cohort design would be preferable if feasible.

#### 2. Make country-level confounding the central identification challenge and address it directly
- **Issue:** The effect disappears with country×year fixed effects.
- **Why it matters:** This suggests the baseline relies on cross-country omitted variables rather than within-country regional exposure.
- **Concrete fix:** Treat the country×year FE result as central, not peripheral. Rework the design to exploit within-country variation only, or show persuasively why cross-country variation is valid. Add country-specific trends, country-year controls (youth unemployment, migration, university policies, national Erasmus funding/co-funding), and country-by-country analyses.

#### 3. Provide a much stronger defense of share exogeneity or abandon strong causal language
- **Issue:** RI fails for shock-based identification, leaving shares as the likely identifying source, but share exogeneity is weakly defended.
- **Why it matters:** Without credible share exogeneity, the IV does not identify a causal effect.
- **Concrete fix:** Add extensive evidence on the determinants of pre-period bilateral shares; test whether shares predict pre-period trends in multiple outcomes; show robustness to richer baseline controls interacted with time; and decompose the shift-share estimate into share components à la GPSS. If this cannot be established, rewrite the paper as a high-quality descriptive/reduced-form study.

#### 4. Revisit inference using methods appropriate for shift-share designs
- **Issue:** Conventional clustering may understate uncertainty given a limited number of effective shocks and the shift-share structure.
- **Why it matters:** Statistical significance is already borderline under two-way clustering.
- **Concrete fix:** Implement shock-level or AKM-style inference where appropriate, and make the most conservative valid inference the headline. Clarify exactly what level of variation justifies the reported SEs.

### 2. High-value improvements

#### 5. Reassess the labor-market outcomes using rates, not levels
- **Issue:** LFP and employment are in thousands, which are hard to interpret and may reflect broader demographic movement.
- **Why it matters:** The mechanism claims rely heavily on these outcomes.
- **Concrete fix:** Use participation and employment rates for 25–34-year-olds, or normalize levels by age-group population. Show whether the results survive.

#### 6. Strengthen placebo and falsification exercises
- **Issue:** The current 25–64 placebo is informative but limited and partially contradicted by the older-employment result.
- **Why it matters:** Stronger falsification is needed given design fragility.
- **Concrete fix:** Add placebo outcomes less plausibly affected by Erasmus-specific mobility (e.g., older-age educational composition, unrelated demographic shares, pre-determined outcomes), and explicitly discuss all placebo results including any failures.

#### 7. Decompose the instrument and document exposure concentration
- **Issue:** With 15–20 effective shocks and possible exposure concentration, the estimate may be driven by a handful of countries/destinations/share patterns.
- **Why it matters:** This bears directly on identification and generality.
- **Concrete fix:** Report exposure concentration by sending region, country, and destination; show shock-share decomposition; characterize which countries and corridors generate the identifying variation.

#### 8. Clarify sample construction and sample changes across tables
- **Issue:** Observation counts vary materially across columns without a full audit trail.
- **Why it matters:** In a paper with sensitivity to specification, sample changes can matter substantively.
- **Concrete fix:** Add a sample-accounting appendix table listing region counts and observation counts at each restriction stage and for each main specification.

### 3. Optional polish

#### 9. Recalibrate the discussion of mechanisms and policy
- **Issue:** Policy proposals are stronger than the evidence warrants.
- **Why it matters:** Overstated implications can undermine credibility.
- **Concrete fix:** Reframe policy discussion as contingent hypotheses pending stronger causal evidence.

#### 10. Tighten the interpretation of OLS vs IV
- **Issue:** The sign reversal is suggestive but not diagnostic of causal validity.
- **Why it matters:** The paper currently leans too heavily on this comparison.
- **Concrete fix:** Present OLS–IV contrast as descriptive evidence of differential selection, not proof that IV recovers the true causal parameter.

## 7. Overall assessment

### Key strengths
- Important and policy-relevant question.
- Potentially valuable new data on geolocated Erasmus flows.
- Transparent discussion of some unfavorable diagnostics.
- Broad robustness effort and clear motivation.

### Critical weaknesses
- Identification is not currently credible for strong causal claims.
- Main effect appears to depend on cross-country variation and disappears with country×year FE.
- Treatment timing is poorly aligned with the stock outcome.
- Shift-share diagnostics do not support the preferred shock-based interpretation.
- Mechanism and policy claims exceed what the evidence can sustain.

### Publishability after revision
I do not think this paper is close to acceptance in its current form for a top general-interest journal or AEJ: Economic Policy. However, I do think there is a potentially publishable paper here if the authors either:
1. substantially redesign the empirical strategy around timing and within-country identification, or  
2. reposition the paper as a more cautious reduced-form/descriptive analysis of Erasmus exposure and regional divergence, with causal claims sharply scaled back.

At present, the paper’s contribution is interesting but not yet scientifically secure enough for publication.

DECISION: REJECT AND RESUBMIT