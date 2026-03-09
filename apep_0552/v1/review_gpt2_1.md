# GPT-5.4 (R2) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-09T14:55:02.655116
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 23840 in / 5299 out
**Response SHA256:** 26b6dc894e1952b9

---

This paper studies whether France’s 2021 DPE reform—making energy certificates legally consequential and introducing future rental bans—was capitalized into housing prices. The paper assembles a large and potentially valuable matched transaction-level dataset and presents an interesting descriptive fact: after the reform, low-rated dwellings appear to sell at somewhat larger discounts, and there is strong post-reform bunching around rating thresholds. The topic is important and timely. However, in its current form the paper is not publication-ready for a top field or general-interest outlet because the causal design is not yet sufficiently credible, and the main identification and measurement problems are more fundamental than the manuscript presently acknowledges.

My main concerns are not about prose or framing but about scientific substance: treatment measurement, comparability across pre/post periods, the validity of the RDD designs, and the ability of the DiD/triple-difference designs to support the paper’s central causal and decomposition claims.

## 1. Identification and empirical design

### A. The baseline DiD is not credible for the paper’s stated causal decomposition

The main baseline specification in Section 5.1 compares G-rated to other rated properties before and after July 1, 2021. This does not convincingly identify the causal effect of the regulatory reform for several reasons.

1. **Treatment is itself redefined by the reform.**  
   The paper is explicit that the 2021 reform simultaneously changed:
   - the legal consequences of ratings,
   - the methodology for assigning ratings,
   - and the threshold definitions across grades (Sections 2.3, 5.5, 7.4).

   This is not a minor caveat. It means “G-rated” pre- and post-reform are not directly comparable treatment states. In a DiD of the form \(G_i \times Post_t\), the composition of the treated group can change mechanically because the classification rule changes. That undermines the core causal contrast. The manuscript repeatedly states that the post-reform penalty “likely reflects a composite” of channels, but the empirical sections still treat the baseline DiD as evidence of capitalization of regulation. At present it is evidence of a post-2021 shift in the relative valuation of properties *classified* as F/G under changing measurement rules—not a clean estimate of regulatory capitalization.

2. **Parallel trends are effectively untestable.**  
   The event study (Section 6.2; Appendix Identification) has only one non-reference pre-reform period. The paper acknowledges this. With one pre period, there is no meaningful basis for a parallel-trends claim. This is particularly serious because the treated and comparison groups differ strongly in observables and likely in unobservables (Section 4.6). In such a setting, a short pre-period is not a cosmetic limitation; it is a major identification problem.

3. **The reform coincides with a major energy-price salience shock.**  
   The paper notes the 2021–2023 European energy crisis in Section 7.4. This is a first-order confound, especially because the treatment is based on energy inefficiency. A post-2021 widening discount on F/G properties could reflect higher expected heating costs rather than regulatory capitalization per se. Time fixed effects do not solve this because the effect is inherently differential by energy efficiency. The paper’s heterogeneity results—larger effects in houses and rural areas—are in fact quite consistent with energy-cost salience and renovation-cost differences, not specifically rental-ban exposure.

4. **The baseline comparison groups are not policy-clean.**  
   Column (1) of Table 1 uses G vs D. But G and D differ sharply in many attributes beyond energy efficiency. Commune FE and basic hedonic controls are not enough to justify a parallel counterfactual. Column (3), FG vs CD, sharpens power but worsens interpretability because F and G are both affected and may evolve differently from C/D for reasons unrelated to the reform.

Overall, the baseline DiD can support a descriptive statement—relative prices of low-rated properties changed after the reform period—but not the paper’s stronger causal interpretation.

### B. The timing and matching design raise serious treatment-measurement concerns

The most concerning data issue is in Section 4.3–4.5: the paper matches transactions to the nearest DPE certificate within 50 meters in the same commune, but it does **not impose a temporal restriction ensuring that the matched DPE predates the transaction**.

The paper says the certificate “predominantly reflects” the property’s energy characteristics at the time of transaction and “predominantly precedes or coincides” with the sale (Section 4.5), but this is not sufficient. If some transactions are matched to DPEs issued after sale—especially after renovations or reassessments—then treatment is measured post-outcome. This can induce severe misclassification and even post-treatment bias. The issue is especially acute in the post-reform period, when reassessment incentives changed.

This is not a minor housekeeping point. Without a verified certificate date window relative to transaction date, the treatment variable is not securely defined. At minimum, the paper must:
- require DPE issuance before sale (or no later than listing, if observable),
- report the distribution of certificate-sale lags,
- and show robustness to narrow timing windows (e.g., certificate issued within 12 months before sale).

### C. The spatial match is potentially too noisy for unit-level causal interpretation

The same-commune + within-50m nearest-neighbor match may work in single-family settings, but in multi-unit buildings it can easily assign a neighboring unit’s certificate to the transacted unit. The manuscript acknowledges this (Section 4.5), but then treats it as classical attenuation. That is not assured. In apartment buildings, nearby units can differ materially in floor, orientation, heating system, and hence DPE. More importantly, mismatch rates may vary systematically by urbanicity and property type, which could contaminate the heterogeneity results that the paper uses for interpretation.

A convincing paper needs much more validation here:
- exact address/string matching where available,
- narrower distance thresholds,
- match-quality tiers,
- and results re-estimated on a high-precision subsample.

### D. The triple-difference does not convincingly isolate the regulatory channel

The triple-difference in Section 5.3 is intended to exploit cross-commune rental exposure. But the design is weakly grounded empirically.

1. **The proxy is indirect.**  
   Commune apartment share from DVF is used as a proxy for rental share. Even with an aggregate correlation \(r>0.80\), this is still a noisy and conceptually imperfect proxy for the share of *marginal buyers* who are landlords in the affected segment.

2. **The identifying assumption is strong and unaddressed.**  
   The DDD requires that, absent the reform, the relative trend in G discounts across high- vs low-rental communes would have been similar. But high-rental communes differ systematically in urbanicity, building stock, energy systems, local market tightness, and exposure to the energy crisis. The paper does not present evidence supporting this differential-trends assumption.

3. **The sign goes the wrong way.**  
   Table 2 shows the triple interaction is positive and insignificant. The paper appropriately does not overclaim. But this also means the design fails to support the paper’s central decomposition ambition.

At present the DDD is best viewed as uninformative rather than supportive.

### E. The RDD design is not valid as implemented

The RDD sections (5.4–5.6; 6.4–6.6) face deeper problems than “imprecision.”

1. **Manipulation invalidates the standard RDD interpretation.**  
   The density tests show strong post-reform bunching at the threshold (Table 6). Once the running variable is manipulable in response to treatment incentives, continuity-based causal interpretation is compromised. This is not merely “bias toward zero” or a “lower bound.” Under sorting/manipulation, the composition of units just below and above the cutoff changes, and the RDD estimand need not have a causal interpretation at all. The manuscript currently understates this.

2. **Assignment is not based solely on the running variable.**  
   Section 2.5 states clearly that the binding DPE grade is the worse of **energy** and **emissions**. Yet the RDD uses only energy consumption \(E_i\) with cutoff 420 kWh/m²/year as a sharp design (eq. 8). That is generally incorrect. A dwelling can be G because of emissions even if energy consumption is below 420, and vice versa depending on the combined rule. Therefore crossing the energy threshold does not deterministically assign treatment. This implies the design is not sharp; at best it is a fuzzy design, and even that would require showing a first stage in the probability of G at 420 based on the full assignment rule. As written, the RDD treatment assignment is mis-specified.

3. **The pre-reform placebo at 420 is not a meaningful continuity check for the same treatment rule.**  
   The paper acknowledges that 420 was not the same boundary pre-reform. That means the pre-reform “placebo RDD” at 420 is not testing the pre-existing price discontinuity at an equivalent rating boundary; it is just testing whether an arbitrary energy value happened to be associated with a price jump. That is weak evidence.

4. **Bandwidth/inference choices are less central than assignment validity.**  
   The use of rdrobust and local linear methods is fine, but methodological correctness in bandwidth choice does not rescue a design with manipulation and mismeasured assignment.

Given these issues, the RDD/DiDisc results should not be presented as quasi-experimental estimates of the regulatory margin. At best they document threshold salience and manipulation.

## 2. Inference and statistical validity

### A. Standard errors are reported for main estimates, which is a strength
The paper consistently reports uncertainty for the main DiD and DDD results and clusters at the commune level. With many communes, commune clustering is plausible for the panel-style specifications.

### B. But the inferential target is often unclear because the estimand is unclear
This is especially true for:
- the RDD estimates under manipulation,
- the sharp RDD despite non-sharp assignment,
- and DiD coefficients when treatment classification changes across periods.

Inference on a poorly identified or mis-specified estimand is not sufficient for validity.

### C. Sample sizes and effective samples need clearer reconciliation
The paper reports:
- 814,887 matched transactions overall (Table 0 / Section 4),
- various much smaller estimation samples in specific columns,
- and RDD sample sizes in Table 3 and the placebo table that appear to refer sometimes to total and sometimes to effective bandwidth samples.

These numbers may well be coherent, but the paper should provide a sample-flow table that reconciles:
1. total raw DVF,
2. residential eligible,
3. geocoded eligible,
4. matched to DPE,
5. with nonmissing kWh,
6. estimation samples by specification.

For top-journal publication, this should be transparent.

### D. Event-study inference is overstated relative to available pre-data
The manuscript is admirably candid that formal pre-trend testing is impossible, but it still uses the event-study shape to bolster the design. With only one usable pre coefficient, the event study is primarily descriptive.

## 3. Robustness and alternative explanations

### A. Robustness is extensive in quantity but not yet targeted at the main threats
The paper includes bandwidth sensitivity, donut RDD, heterogeneity, and alternative timing. These are useful, but they do not resolve the key threats:
- treatment redefinition across periods,
- post-outcome or post-renovation certificate matching,
- energy-price salience confounding,
- and nonrandom matching error.

### B. The main alternative explanation—energy cost salience—is highly plausible and insufficiently separated
The paper’s own heterogeneity results point away from the narrow rental-ban mechanism:
- larger effects for houses than apartments,
- larger effects in rural than urban areas (Table 5).

Those patterns fit energy cost and renovation burden more naturally than landlord regulation. The paper ultimately concedes this, but then the central title/framing still leans heavily on “regulatory bans” and “stranded assets.” The contribution should be recalibrated unless the authors can more convincingly isolate regulation from information/salience.

### C. Mechanism claims are mostly well hedged, but some remain too strong
The manipulation result is genuinely interesting. However, the claim that density discontinuities at 420 are “evidence that market participants take the regulatory consequences seriously” is plausible but not fully pinned down. Some bunching may reflect diagnostician incentives under legal opposability, not necessarily owner demand or market pricing per se. Also, density discontinuities at 250 and 330 suggest broader bunching around grade boundaries; the manuscript notes this but should be more cautious in attributing all bunching to strategic gaming rather than partly to algorithmic bunching or heaping.

### D. External validity discussion is thoughtful
The external-validity section is balanced and one of the stronger parts of the paper.

## 4. Contribution and literature positioning

The question is important, and the manuscript is generally well positioned in the housing-energy and regulatory-capitalization literatures. The most attractive feature is the attempt to study a regime switch in which labels become regulatory tools. That said, the paper overstates how much it has achieved on decomposition.

### Literature to strengthen

1. **Modern DiD identification and event-study interpretation**
   - Callaway, Brantly and Pedro H.C. Sant’Anna (2021), *Journal of Econometrics*.
   - Sun, Liyang and Sarah Abraham (2021), *Journal of Econometrics*.

   Even though treatment timing is not staggered here in the usual sense, these references are relevant for careful discussion of dynamic treatment effects and event-study interpretation under heterogeneous effects.

2. **Regression discontinuity under manipulation / local randomization limitations**
   The paper cites Cattaneo et al. on density testing, which is good. But it should more directly engage the consequence that manipulation weakens or invalidates standard continuity-based causal interpretation, rather than treating the result as simple attenuation.

3. **Housing and energy price salience**
   The paper would benefit from citing work on capitalization of expected energy costs, not only certification labels, because the 2021–23 energy shock is central to interpretation.

4. **Selection/matching quality in administrative housing-DPE merges**
   If there is relevant French or European work validating address-level DPE-transaction matching, it should be cited and used as a benchmark.

## 5. Results interpretation and claim calibration

### What the paper can currently support
- There is a robust descriptive pattern that, in the reform era, F/G properties sold at somewhat larger discounts relative to better-rated properties.
- There is strong evidence of bunching around DPE thresholds post-reform.
- The decomposition into regulatory versus informational channels is unresolved.

### What the paper cannot currently support cleanly
- A causal estimate of the rental-ban capitalization effect.
- A credible decomposition of the brown discount into regulation versus information.
- A valid threshold causal effect from the current RDD.

### Specific over-claiming/calibration issues
1. The abstract and introduction still place too much weight on “regulatory bans” relative to what the designs identify. The paper ultimately admits the ambiguity, but the headline contribution remains stronger than warranted.
2. The aggregate stranded-value calculation in Section 7.1 is too aggressive given the identification uncertainty and small reduced-form estimate. Extrapolating a 2% estimate from a selected matched sample to all 5.2 million passoires in France is not yet justified.
3. The paper sometimes interprets insignificant threshold estimates as qualitatively supportive because of sign ordering. For a top journal, this should be toned down.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Enforce temporal validity of the DVF-DPE match
- **Issue:** The current match does not clearly require certificate issuance before transaction.
- **Why it matters:** Without this, treatment may be measured after sale or after renovation, invalidating causal interpretation.
- **Concrete fix:** Rebuild the matched sample requiring DPE issuance date to precede transaction date; report the distribution of lags; show robustness for certificates issued within 3/6/12 months pre-sale only.

#### 2. Reassess the core identification strategy given treatment reclassification
- **Issue:** The reform changes both treatment status and the way treatment is measured.
- **Why it matters:** The baseline DiD currently conflates regulation with measurement-rule changes.
- **Concrete fix:** Shift the main design away from pre/post comparisons of letter grades unless the authors can construct a harmonized energy-performance measure that is comparable across regimes. One possibility is to base analysis on continuous underlying physical measures or on a subset of properties assessed under a consistent methodology. Another is to focus the paper more transparently as a descriptive capitalization study rather than a causal decomposition.

#### 3. Remove or fundamentally redesign the sharp RDD
- **Issue:** The current RDD uses an energy threshold despite treatment depending on the worse of energy and emissions, and the running variable is manipulable.
- **Why it matters:** The design is mis-specified and not causally interpretable.
- **Concrete fix:** Either (i) drop the RDD as a causal design and reinterpret it strictly as a threshold-salience/manipulation exercise, or (ii) implement a properly specified fuzzy design using the full assignment rule and provide evidence on the first stage, while fully confronting manipulation. My prior is that option (i) is more defensible.

#### 4. Address the energy-crisis confound directly
- **Issue:** Differential salience of energy costs after 2021 is a major alternative explanation.
- **Why it matters:** It directly loads on low-energy-efficiency properties and can mimic the main effect.
- **Concrete fix:** Interact exposure with local heating degree days, dominant heating fuel, pre-existing gas dependence, or regional energy-price pass-through. At minimum, show whether effects are stronger where operating-cost exposure should be higher independent of regulation.

#### 5. Recalibrate the paper’s causal claims
- **Issue:** The current framing still overstates identification of regulatory capitalization.
- **Why it matters:** Publication readiness depends on matching claims to evidence.
- **Concrete fix:** Reframe the paper around a reduced-form change in valuation and strategic threshold behavior after a joint information/regulation/methodology reform, unless stronger identification can be added.

### 2. High-value improvements

#### 6. Validate match quality aggressively
- **Issue:** Spatial nearest-neighbor matching within 50m may create systematic error.
- **Why it matters:** Misclassification could distort both main effects and heterogeneity patterns.
- **Concrete fix:** Report results by match distance bins (e.g., 0–5m, 5–10m, 10–25m, 25–50m), exact-address subsamples if available, and separately for houses vs apartments.

#### 7. Improve support for the triple-difference or demote it
- **Issue:** The rental-share proxy is noisy and the identifying assumptions are not tested.
- **Why it matters:** The DDD is central to the decomposition claim but currently uninformative.
- **Concrete fix:** Use census rental share directly if possible; interact with pre-reform landlord share, investor purchase prevalence, or rental-market tightness; and provide evidence on pre-trend similarity across high/low rental-exposure areas. If these data are unavailable, demote the DDD to exploratory status.

#### 8. Provide a transparent sample flow and missingness audit
- **Issue:** Estimation samples are difficult to reconcile.
- **Why it matters:** Readers need confidence that the matched sample is not driving results via selection.
- **Concrete fix:** Add a sample construction table and a comparison of matched vs unmatched transactions on observables, pre/post, urban/rural, and by rating distribution.

#### 9. Use richer controls or local comparisons in the baseline reduced-form models
- **Issue:** Current controls are sparse for cross-sectional comparisons of very different property types.
- **Why it matters:** Residual composition differences are likely important.
- **Concrete fix:** Add finer location FE (e.g., commune-by-property-type or small-area FE where possible), nonlinear controls for surface/rooms, building vintage if available from DPE, heating type, and interactions.

#### 10. Test sensitivity to excluding post-reform reassessments and likely renovated units
- **Issue:** Some observed “treatment” changes may reflect renovation before sale.
- **Why it matters:** The post-reform composition of G/F may shift because owners upgrade before transacting.
- **Concrete fix:** Restrict to certificates issued shortly before sale and, if possible, exclude cases with recent major renovation flags or very recent reassessments.

### 3. Optional polish

#### 11. Tone down aggregate welfare calculations
- **Issue:** The stranded-asset totals are extrapolated from uncertain reduced-form estimates.
- **Why it matters:** They may overstate precision.
- **Concrete fix:** Present as back-of-the-envelope scenarios with wide ranges and explicit assumptions.

#### 12. Clarify which findings are descriptive versus causal
- **Issue:** Several sections blend the two.
- **Why it matters:** This affects reader interpretation.
- **Concrete fix:** Add a brief subsection at the end of Section 5 distinguishing “causal aspirational designs” from “descriptive reduced-form patterns.”

## 7. Overall assessment

### Key strengths
- Important policy question with wide relevance in Europe.
- Large transaction-level dataset with potentially high value.
- Honest discussion in several places about the inability to cleanly decompose channels.
- Interesting threshold-bunching result that may be publishable in its own right if better validated.
- Robustness effort is substantial, even if not yet targeted at the main threats.

### Critical weaknesses
- Core treatment definition changes with the reform, undermining the baseline causal contrast.
- Pre-trends are essentially untestable.
- Matching procedure appears not to enforce certificate timing relative to transaction, which is a major measurement threat.
- RDD is not valid as a sharp design because treatment is determined by the worse of energy and emissions, and manipulation is documented.
- The triple-difference does not identify the regulatory channel convincingly and returns the wrong-signed, insignificant interaction.
- Claims about regulatory capitalization and decomposition remain stronger than the evidence supports.

### Publishability after revision
There is a potentially useful paper here, but it likely needs substantial redesign rather than incremental revision. The strongest current contribution may be a careful reduced-form/descriptive paper on how a joint information-regulation-methodology reform changed valuation patterns and induced threshold bunching. To become a causal paper on regulatory capitalization suitable for a top journal, the empirical strategy needs to be rebuilt around cleaner treatment measurement and a more credible source of identification.

DECISION: REJECT AND RESUBMIT