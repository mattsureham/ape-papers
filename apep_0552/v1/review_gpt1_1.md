# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T14:55:02.649175
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 23840 in / 5339 out
**Response SHA256:** 91fc4e59045933e2

---

This paper studies an important and timely question: whether France’s 2021 DPE reform, which made energy certificates legally consequential and tied them to future rental bans, was capitalized into housing prices. The paper is ambitious, uses a large matched administrative dataset, and is commendably candid that the channel-decomposition exercises are inconclusive. The manipulation result is potentially interesting. However, in its current form, the paper is not publication-ready for a top field or general-interest outlet because the core causal interpretation remains too weakly identified, and several design features undermine both the baseline DiD and the threshold-based designs.

My review focuses on scientific substance and publication readiness.

## 1. Identification and empirical design

### A. The central causal claim is not cleanly identified

The headline result is a post-reform discount for F/G properties relative to safer ratings (Table 1, col. 3). But the paper itself acknowledges the main problem: the 2021 reform simultaneously changed (i) the legal/regulatory consequences of ratings, (ii) the DPE methodology, and (iii) likely the salience/credibility of the label. In the current design, these channels are not separately identified. That would be acceptable if the paper were framed as documenting an overall post-reform repricing of poorly rated homes. But the introduction and contribution sections repeatedly claim to “decompose” informational and regulatory channels. The presented evidence does not support that stronger claim.

More importantly, even the reduced-form “effect of the reform” is not cleanly causal because treatment status itself is redefined by the reform. A G/F/E label before and after July 2021 is not the same object: thresholds changed and the methodology moved from dual 3CL/facture to 3CL-2021 (Institutional Background; Empirical Strategy, DiDisc discussion). That means the DiD is not comparing the same treatment across periods. Composition of “G-rated” properties can change mechanically, independent of market pricing.

### B. The baseline DiD has very weak support for its identifying assumption

The event-study evidence is insufficient to support a DiD interpretation. The sample starts only in 2020H2 (Data section), yielding effectively one non-reference pre period (2021H1). As the paper concedes, this does not permit a meaningful pre-trend test. That is already a serious limitation.

Worse, the paper also notes that markets may have begun anticipating the reform in mid-2020, after the Convention Citoyenne recommendations and before the formal law (Institutional Background). If anticipation starts in the pre period, then 2020H2 is not a clean untreated baseline. This is not a minor caveat: it directly undermines the interpretation of the pre/post contrast.

There is also ambiguity about the relevant “treatment date.” The paper uses July 1, 2021, because DPE became legally enforceable and methodology changed then, even though the Loi Climat was enacted only on August 22, 2021, and rental bans begin later. This means the treatment is a bundle of legal opposability, methodology revision, and anticipated future bans, not “the rental ban reform” per se. The paper should calibrate claims accordingly.

### C. The triple-difference design is not persuasive as a regulatory-channel isolator

The proposed DDD uses commune-level apartment share as a proxy for rental exposure (Data: Commune-Level Rental Shares; Table 2). This is too indirect for the causal decomposition the paper wants.

Problems:

1. **Proxy validity**: apartment share is not rental share. Even with correlation to census rental occupancy, it is also a proxy for urban density, building type, contractor availability, market thickness, and local price dynamics.
2. **Exogeneity**: the paper argues rental share is “orthogonal” to the DPE methodology change. That is not enough. The DDD needs the differential post trend in G-rated prices across high- vs low-rental-share communes to be absent absent the regulatory channel. Given urban/rural differences in energy salience, energy crisis exposure, housing composition, and renovation technology, that assumption is not credible as currently defended.
3. **Result failure**: the key three-way interaction is wrong-signed and imprecise (Table 2). That does not just mean the channel is hard to detect; it means the main decomposition strategy fails.

A top-journal version would need either buyer-level investor/owner-occupier information, direct landlord exposure, or a much stronger source of heterogeneity tied specifically to regulatory incidence.

### D. The RDD design is likely invalid in its current implementation

The paper estimates a sharp RDD at 420 kWh/m²/year (Equation 6; Table 3; Figure 3). There are several problems.

#### 1. Sorting/manipulation is present by the paper’s own evidence
The density test shows significant bunching around the threshold post-reform (Table 6 / Density Tests). That alone invalidates a standard sharp RDD interpretation. The paper treats this as attenuation and hence “lower bound” logic, but that is not generally justified. With endogenous sorting, the local comparison is no longer between quasi-randomly assigned units, and bias direction is not guaranteed.

#### 2. The running variable does not fully determine treatment
The post-2021 DPE grade is the worse of energy and emissions. Yet the RDD is implemented on energy consumption only (Table of thresholds; Equation 6). Crossing 420 in energy does not map cleanly into crossing from F to G if emissions can also bind, and units below 420 may still receive G on emissions. This creates fuzzy, not sharp, assignment at best. The paper does not show the first stage around 420 between energy-threshold crossing and actual G rating. Without that, the design is mis-specified.

#### 3. The pre/post “difference-in-discontinuities” placebo is hard to interpret
The paper uses a pre-reform placebo at 420 kWh, while acknowledging that pre-reform thresholds differed and the specific threshold was not a formal boundary before 2021 (Difference-in-Discontinuities section; Table 5). That is not a valid pre-reform analog of the same cutoff treatment. The “no pre discontinuity at 420” result is therefore weak reassurance.

In short, the threshold designs do not presently deliver credible causal evidence.

### E. Matching design raises selection and timing concerns that matter for identification

The paper matches transactions to the nearest DPE within 50 meters inside commune (Data section). Two substantive concerns are not adequately resolved:

1. **Timing of certificates relative to transaction**: the paper says the certificate “predominantly precedes or coincides with the transaction,” but does not impose or report a certificate-date restriction. If some matches use certificates issued after the sale, treatment is measured post-outcome.
2. **Time-varying match selection**: match rates are said to be higher post-2021 and in apartments/urban areas (Sample Construction and Match Quality). This is potentially first-order. If the matched sample changes composition differentially across DPE categories after the reform, the estimated “reform effect” may partly be a selection effect. This issue is especially serious because the post period is 78% of the sample (Table 1 summary stats) and DPE issuance itself changed after the reform.

The paper should show match rates over time by property type, geography, and energy rating; compare matched and unmatched transactions; and test robustness to tighter spatiotemporal matching rules.

## 2. Inference and statistical validity

### A. Main regressions report uncertainty, but inference is not yet fully convincing

The paper does report standard errors and p-values for the main specifications, and commune clustering is not obviously inappropriate given many communes. That is a strength.

But several statistical-validity issues remain:

1. **Event study with one usable pre period**: inference about dynamic treatment effects is not meaningful for validating DiD assumptions. The event-study is descriptive only.
2. **RDD inference under sorting**: robust bias-corrected intervals are reported, which is good, but once density discontinuity is present, standard rdrobust inference does not rescue identification.
3. **Sample sizes across specifications**: Ns differ substantially across columns and threshold exercises, which is fine mechanically, but the paper does not explain enough about the effective samples or how missing kWh/emissions data differ by period and treatment status.
4. **Multiple testing / over-reading insignificant estimates**: the paper is fairly cautious overall, but some text leans on qualitative ordering of insignificant RDD estimates (“consistent with prediction”) too heavily.

### B. The RDD should likely be treated as fuzzy or abandoned

Given the “worse of energy or emissions” rule, the first requirement is to estimate the discontinuity in actual G assignment at 420 energy. If it is weak, the design has little bite. If there is substantial noncompliance, the right framework is fuzzy RD, not sharp RD. If manipulation is also severe, even fuzzy RD may not be credible.

### C. Clustering level should be defended and alternatives reported

Commune clustering may be acceptable, but because treatment varies at the property level and some fixed effects are finer in robustness checks, the paper should show sensitivity to alternative clustering structures (e.g., département, spatial HAC if feasible, or two-way clustering with year-quarter if justified). This is not the main problem, but it should be checked.

## 3. Robustness and alternative explanations

### A. The central alternative explanations are not ruled out

The paper repeatedly notes three alternatives:
- DPE methodology change
- energy-price salience during the 2021–23 energy crisis
- selection/composition changes in the matched sample

These are not peripheral; they are core rival explanations. The current robustness checks do not adequately separate them from the treatment effect.

#### 1. Energy crisis confound
The paper notes that the post-reform period overlaps with the European energy crisis (Discussion, Limitations). This is potentially a major confound because high energy prices should mechanically increase buyer willingness to pay for efficiency, especially for low-rated homes, regardless of regulatory bans. The paper’s département × year-quarter FE do not solve a national salience shock that interacts with energy inefficiency.

A stronger design would exploit variation in heating fuel, climate zone, or pre-existing energy dependence to test whether the post-2021 repricing loads more on energy-cost exposure than on regulatory exposure.

#### 2. Methodology-change confound
This remains unresolved. The paper should do much more to characterize how the rating distribution shifted mechanically at reform, preferably using cases with repeated certificates or properties observed before and after methodology change. Without that, it is impossible to know whether the estimated “discount” reflects changes in who is labeled F/G.

#### 3. Sample selection from matching
As above, this needs dedicated diagnostics and correction attempts.

### B. Heterogeneity results cut against the preferred mechanism

The paper’s own heterogeneity analysis is important and, in my view, more damaging than the text suggests. The discount is larger for houses than apartments and larger in rural than urban markets (Table 7). Those patterns are the opposite of what a rental-ban incidence story would most naturally predict, given rental concentration in apartment-heavy urban areas.

The paper interprets this as evidence that the observed effect is a composite of regulation, renovation costs, and information. That is plausible. But it also means the paper does not currently have convincing evidence that regulation is the dominant or even a clearly identified component.

### C. The manipulation claim is interesting but needs more careful interpretation

The McCrary evidence may be valuable, but the interpretation as strategic manipulation is currently overstated. The paper itself notes density discontinuities at other thresholds too. That opens two possibilities:
- strategic behavior at multiple grade cutoffs, not just G/F; or
- mechanical bunching induced by the algorithm/reporting conventions of the new DPE methodology.

To claim “novel evidence of strategic manipulation,” the paper needs stronger validation:
- heaping/discreteness diagnostics in the running variable,
- whether bunching concentrates among observations assessed by certain diagnosticians or regions,
- whether density changes differ by property types most exposed to the ban,
- whether emissions-based binding cases show similar patterns.

As written, the density result is suggestive, not definitive evidence of gaming.

## 4. Contribution and literature positioning

### A. The topic is important and potentially publishable, but the current contribution is overstated

The paper’s strongest credible contribution at present is narrower than claimed: documenting a modest post-2021 repricing of low-rated French homes in a large transaction sample, plus suggestive evidence of threshold bunching after labels acquired regulatory bite. That is interesting.

But the paper repeatedly claims a decomposition of informational versus regulatory channels and positions itself as solving a central identification challenge in the literature. The actual results do not support that positioning.

### B. Literature positioning should better reflect modern quasi-experimental standards

A few concrete references would strengthen the methods framing:

- **Difference-in-discontinuities / policy threshold changes**:  
  Grembi, Nannicini, and Troiano (2016), *Do Fiscal Rules Matter?* for the diff-in-disc logic.
- **Modern DiD/event-study cautions**:  
  Roth (2022) on pre-trends;  
  Rambachan and Roth (2023) on sensitivity of parallel trends/event studies.  
  Even though this is not staggered adoption, these papers are relevant for how little can be inferred from one pre period.
- **Sorting/manipulation in RD**:  
  Cattaneo, Idrobo, and Titiunik (2020), *A Practical Introduction to Regression Discontinuity Designs*;  
  Gerard, Rokkanen, and Rothe (2020) or related work on RD with manipulation/sorting.
- **Housing and climate/energy-risk capitalization**:  
  There is scope to engage more with the recent climate-risk housing literature beyond the cited financial-markets papers, especially work on flood/fire/climate capitalization and heterogeneous salience.

### C. Domain literature on DPE measurement/reliability seems underused

Given how central measurement change and potential manipulation are, the paper should engage more directly with literature on EPC/DPE reliability, assessor disagreement, and label design. That literature is not just background; it is central to identification here.

## 5. Results interpretation and claim calibration

### A. Some claims are appropriately cautious; others still overreach

The paper is commendably candid in several places:
- “designs intended to isolate the regulatory channel yield imprecise results”
- “post-reform penalty likely reflects a composite”

Those are well calibrated.

However, other statements go too far given the evidence:
1. The abstract and introduction imply the paper identifies a regulatory-ban capitalization effect. It does not cleanly do so.
2. The manipulation finding is presented as “novel evidence of strategic manipulation” rather than suggestive evidence consistent with manipulation.
3. The aggregate stranded-value calculation in the Discussion/Conclusion extrapolates a 2% discount to 5.2 million homes. That is too strong given the design uncertainty and the fact that the estimated effect pertains to the matched transaction sample over 2020H2–2024, not the entire stock of passoires.

### B. Magnitudes need more care

A 2% price effect is economically meaningful, but the paper swings between describing it as evidence of capitalization and as a lower bound on a much larger regulatory burden. That lower-bound language is not established. With treatment redefinition, sample selection, and manipulation, the bias direction is not known.

### C. Policy implications should be softened

The broad policy lesson that regulatory decarbonization can reprice housing assets is reasonable. But statements about stranded assets, redistribution, and “regulation-based approaches produce larger effects” are ahead of the evidence in this paper because the paper does not isolate regulation from informational and energy-price-salience channels.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Reframe the paper around what is actually identified
- **Issue**: The paper claims to decompose informational vs regulatory channels, but neither the DDD nor RDD delivers credible identification.
- **Why it matters**: Overstating identification is fatal at publication stage.
- **Concrete fix**: Recast the paper as estimating a reduced-form post-2021 repricing of low-rated properties under a bundled reform, with suggestive but not causal evidence on mechanisms. Rewrite abstract, introduction, contribution, and conclusion accordingly unless stronger identification can be added.

#### 2. Address treatment redefinition from the methodology change
- **Issue**: Pre/post DPE labels are not directly comparable.
- **Why it matters**: This undermines the main DiD estimand.
- **Concrete fix**: Provide direct evidence on reclassification under old vs new methodologies. Ideally use repeated certificates on the same property around the reform, or administrative crosswalk evidence, to quantify how much of the post effect could be compositional. If this cannot be done, substantially downgrade causal claims.

#### 3. Impose and document certificate timing restrictions
- **Issue**: The matched DPE may post-date the sale.
- **Why it matters**: This would contaminate treatment measurement.
- **Concrete fix**: Restrict matches to certificates issued before transaction date, or within a very narrow pre-sale window; report how results change. Show the distribution of certificate-to-sale timing.

#### 4. Diagnose and address matching selection
- **Issue**: Match rates differ over time and likely by market segment.
- **Why it matters**: Selection into the matched sample may drive post-reform differences.
- **Concrete fix**: Report match rates by year, property type, region, and price segment; compare observables of matched vs unmatched transactions; reweight or bound estimates; run robustness on tighter distance thresholds and exact-address matches if feasible.

#### 5. Either properly redesign the threshold analysis or drop it as causal evidence
- **Issue**: The RDD is sharp where assignment is not sharp and is invalidated by manipulation.
- **Why it matters**: As presented, the threshold exercises do not support causal claims.
- **Concrete fix**: Show the first stage from crossing 420 energy to actual G rating, accounting for emissions. If assignment is fuzzy, estimate fuzzy RD. If sorting is severe, treat the threshold evidence as descriptive only and remove causal language.

### 2. High-value improvements

#### 6. Better confront the energy-crisis alternative
- **Issue**: National energy-price salience may explain repricing of inefficient homes.
- **Why it matters**: This is a leading alternative to regulation.
- **Concrete fix**: Interact post with ex ante exposure proxies such as heating type, climate severity, or local gas dependence; compare whether repricing is stronger where operating-cost salience should matter most versus where rental-ban exposure should matter most.

#### 7. Strengthen the mechanism evidence using better exposure measures
- **Issue**: Apartment share is an inadequate proxy for landlord exposure.
- **Why it matters**: The channel decomposition currently fails.
- **Concrete fix**: Use direct commune-level rental occupancy from INSEE everywhere possible; better, seek buyer-type proxies, tax records, cadastral ownership, or transaction characteristics indicating investor purchases. At minimum, replicate DDD with census rental share rather than apartment share.

#### 8. Use richer property controls / within-building or finer location comparisons
- **Issue**: Energy ratings correlate with many omitted structural traits.
- **Why it matters**: Simple controls plus commune FE may leave substantial compositional bias.
- **Concrete fix**: Add construction period, heating type, land area, finer geographic FE, possibly building-level or neighborhood FE where available. Explore repeat-sales or near-neighbor matching if possible.

#### 9. Reassess the manipulation claim
- **Issue**: Density discontinuities may reflect algorithmic bunching or heaping.
- **Why it matters**: The “strategic manipulation” contribution is potentially important but currently not established.
- **Concrete fix**: Show score heaping, digit preference, diagnostician-level heterogeneity, and whether bunching is stronger where incentives are larger (rental-heavy areas, small landlords, certain property types).

### 3. Optional polish

#### 10. Clarify the estimand in every table
- **Issue**: Some tables mix reduced-form and threshold estimates with different samples and interpretations.
- **Why it matters**: Helps readers see which evidence is descriptive vs causal.
- **Concrete fix**: Revise notes to state whether each estimate is intended as causal, reduced-form, or descriptive under acknowledged confounds.

#### 11. Moderate stock-level welfare extrapolations
- **Issue**: Aggregate stranded-value calculations overstate precision.
- **Why it matters**: Policy claims should match evidence strength.
- **Concrete fix**: Present these as rough illustrative calculations under strong assumptions, or move to an appendix.

## 7. Overall assessment

### Key strengths
- Important policy question with strong external relevance.
- Large administrative transaction dataset.
- Good instinct to triangulate across multiple designs rather than rely on one.
- Refreshingly honest acknowledgement that channel-specific designs are inconclusive.
- Potentially interesting finding on post-reform bunching near the threshold.

### Critical weaknesses
- Baseline DiD is fundamentally confounded by treatment redefinition and a simultaneous methodology change.
- Only one usable pre period; parallel trends cannot be meaningfully assessed.
- Pre period may already contain anticipation.
- Threshold designs are not credible as causal evidence given sorting/manipulation and the “worse of energy or emissions” assignment rule.
- Triple-difference proxy is weak and produces wrong-signed, null results.
- Matching selection and certificate timing are not adequately handled.
- Several claims about regulatory capitalization and strategic manipulation exceed what the evidence supports.

### Publishability after revision
There is a potentially publishable paper here, but it likely requires substantial redesign or a narrower claim set. In its current form, it is not ready for acceptance and falls short of the identification standards expected at AER/QJE/JPE/ReStud/Econometrica or AEJ: Economic Policy. The most promising path is to recast the paper as a reduced-form study of repricing under a bundled reform and to substantially strengthen the data construction and mechanism analyses. A stronger version would need either better microdata on landlord exposure or a cleaner strategy to isolate regulatory incidence from methodology and salience changes.

DECISION: REJECT AND RESUBMIT