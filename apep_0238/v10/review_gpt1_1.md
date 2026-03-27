# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-03-27T01:56:16.390102
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 14487 in / 5591 out
**Response SHA256:** faa4a24c9180aa8a

---

This paper studies whether labor-market scarring differs across “demand” and “supply” recessions by comparing cross-state employment dynamics after the Great Recession and the COVID recession. The paper’s central claim is that the persistence gap reflects a “duration trap”: housing-exposed states in the Great Recession experienced persistent employment deficits because prolonged nonemployment accumulated, whereas COVID-exposed states recovered quickly because temporary layoffs preserved matches and enabled recall.

The paper is ambitious, topical, and asks an important question. The comparison between the Great Recession and COVID is inherently interesting, and the effort to unify them in a common state-level framework is potentially valuable. The paper is also admirably transparent in acknowledging that the cross-episode comparison is not a clean causal estimate of “demand” versus “supply” shocks per se (Introduction; Section 4.1). That said, in its current form I do not think the paper is publication-ready for a top general-interest journal or AEJ:EP. The main issues are not presentation, but scientific substance: the core causal comparison is weaker than the paper’s framing suggests; the headline Great Recession scarring estimate is imprecise; the mechanism evidence relies on problematic post-treatment controls and proxies that are too indirect to support the stronger mediation language; and several identification threats remain insufficiently resolved.

Below I organize the review around the requested criteria.

---

## 1. Identification and empirical design

### A. What is identified, and what is not

A major strength is that the paper explicitly admits the key limitation of the cross-episode comparison: the Great Recession and COVID differ along many dimensions besides “demand” versus “supply” shock type, including policy response, recall technology, monetary environment, sectoral composition, and timing (Introduction, “What this comparison can and cannot identify”; Section 4.1). That caveat is essential.

However, the paper then repeatedly moves from “patterns consistent with” this distinction to stronger causal language such as “Demand recessions scar, supply recessions don’t” (title), “The distinction that matters most is not depth, it is duration” (Conclusion), and claims that “the persistence gap traces to a duration trap” (Abstract). Those stronger statements are not fully supported by the design. At most, the paper identifies:
1. within the Great Recession, housing-boom exposure predicts weaker subsequent employment performance;
2. within COVID, Bartik exposure predicts sharp short-run losses but little medium-run cross-state gradient;
3. the two episodes differ in national duration/temporary-layoff patterns.

That is interesting, but it is not a clean causal estimate of the effect of recession type on scarring.

### B. Great Recession identification

The within-GR design uses the 2003Q1–2006Q4 housing price boom as exposure, with controls for pre-recession growth, log employment, and region (Section 4.2). This follows a large literature. The concern, which the paper partly acknowledges in Section 8, is that the housing boom itself was not orthogonal to pre-existing differential local growth and sectoral expansion. Indeed, the paper reports a significant 36-month pre-trend (\(p=0.009\)). That is not a minor detail; it is a direct challenge to the identifying assumption for the OLS specification.

The manuscript argues that this likely reflects the housing construction boom itself. But that is precisely the problem: the same forces that create the “treatment” may also generate differential trajectories in employment that complicate interpretation of post-2007 persistence. If high-boom states were already on distinct trajectories because of construction, finance, migration, or other boom-related forces, then the long-run employment deficits are not cleanly attributable to a demand-collapse-induced scarring channel.

This means the baseline OLS specification is not credible enough, on its own, for the paper’s central causal claims.

### C. Saiz IV

The paper uses Saiz housing supply elasticity as an instrument (Sections 4.2, 8.1, Appendix IV table). This is directionally sensible and motivated by prior work, but the current implementation is not yet persuasive enough to rescue identification.

Issues:
- The first-stage \(F=11.4\) is borderline, and the paper itself notes caution.
- More importantly, exclusion is not discussed rigorously enough. Housing supply elasticity may affect long-run employment dynamics directly through construction intensity, migration responses, land-use constraints, recovery dynamics, housing affordability, and reallocation margins—not only through the 2003–2006 boom.
- The IV results are only shown for selected horizons (\(h=12,24,48\)), not for the main long-run averaged estimand.
- The paper treats the IV as “supporting evidence,” but given the pre-trend problem in OLS, the IV needs to play a central role if the causal claim is to stand.

At minimum, the paper needs a much deeper defense of exclusion and should move the IV for the main estimand into the core analysis.

### D. COVID Bartik design

The COVID exposure measure is a leave-one-out Bartik based on 2019 industry shares and Feb–Apr 2020 national industry shocks (Section 4.2). This is standard in spirit, but several concerns remain.

1. **The identifying variation is limited.** Summary statistics show the raw Bartik has a cross-state SD of just 0.01 (Table 1), i.e., much smaller dispersion than the GR exposure. Standardization masks how limited the underlying cross-state variation is.

2. **Interpretation depends heavily on industry-composition exogeneity.** Yet states with large leisure/hospitality/tourism shares differ systematically in urbanization, density, cost structure, remote work feasibility, demographics, and policy responses. The paper includes only relatively light controls in the baseline. This may be adequate for short-run impacts, but less obviously so for medium-run “full recovery” claims.

3. **A null medium-run gradient is not the same as proof of no scarring.** The design only shows that states more exposed according to this Bartik recovered similarly, relative to less exposed states, by 24–48 months. It does not show that COVID caused no scarring in aggregate, nor that “supply recessions don’t scar.” General equilibrium, common national shocks, and homogeneous recovery can all erase cross-state gradients without implying zero scarring.

### E. Different horizon windows

The main estimand uses months 48–120 for the Great Recession and 24–48 for COVID (Section 4.4). The paper is transparent about this, but it remains a major comparability issue. The pooled interaction is explicitly “cautious” because the outcome windows differ, and indeed the interaction is insignificant (Table 3). This matters because the paper’s central comparative claim rests on comparing estimates from fundamentally different post-periods:
- GR: averaging over years 4–10 after peak,
- COVID: averaging over years 2–4 after peak.

A result of “near zero by years 2–4” is not directly comparable to “negative on average over years 4–10.” If the paper wants to emphasize a cross-episode contrast, it should compare common horizons much more centrally.

---

## 2. Inference and statistical validity

### A. Main estimate is not statistically convincing

The headline Great Recession scarring coefficient is \(-0.0567\) with HC1 SE 0.0467 and permutation \(p \approx 0.13\) (Table 2). This is the main result in the paper, and it is not conventionally statistically significant under the paper’s preferred inference. That alone does not invalidate the paper, but it sharply constrains what can be claimed. A top-journal paper can certainly feature imprecise estimates if the design is exceptional or the contribution is conceptual, but then the claims must be correspondingly modest. Here the paper’s title, abstract, and conclusion are much stronger than the evidence warrants.

The formal pooled interaction test comparing GR to COVID is also insignificant (\(p>0.6\), Table 3). So the paper’s most important comparative claim is not statistically established by its own formal cross-episode test.

### B. Use of permutation inference

Using permutation inference in a 50-state cross-section is a reasonable idea. However, the manuscript overstates it as providing “exact finite-sample validity without distributional assumptions” (Section 4.4). Exactness requires exchangeability under the null. With strong geographic structure, region effects, and exposures that are not randomly assigned across states, exchangeability is far from automatic. Randomly reassigning exposure labels across states may not generate valid exact inference in the presence of spatial dependence or covariate-dependent assignment. At minimum, the paper should justify why unrestricted permutation is appropriate, or implement restricted/randomization procedures respecting geography or observable strata.

### C. Local projections and multiple testing

The paper motivates the single estimand partly to avoid multiple-testing concerns from horizon-by-horizon LPs (Section 4.4), which is reasonable. But the manuscript then relies on significance at selected short/medium horizons to support the main conclusion (Sections 5.1, 6.2, 8). This creates an uncomfortable asymmetry:
- the headline long-run GR estimand is not significant;
- supporting dynamic evidence is emphasized when significant at some horizons.

That is not fatal, but the inferential hierarchy should be more disciplined. If the main estimand is primary, then the non-significance should play a much more central role.

### D. Sample sizes and coherence

Sample sizes are transparent and coherent: \(N=50\) throughout the cross-state regressions, and \(N=100\) in the pooled regression. No concerns there.

### E. Statistical issues in mediation/attenuation

The “attenuation” exercise in Table 5 is not valid evidence of causal mediation as currently presented. The paper adds unemployment-rate changes at \(h=24\) or \(h=48\) as “mediators” in a regression of long-run employment on HPI exposure. This has several problems:

1. **Post-treatment bad control.** UR at 24 or 48 months is itself an outcome of the recession and likely affected by the same shocks driving long-run employment. Conditioning on it does not identify a mediated causal pathway without very strong assumptions.

2. **Mechanical relationship.** Employment, unemployment, and labor force participation are jointly linked by accounting identities. Regressing long-run employment outcomes on unemployment changes risks a partly mechanical attenuation, especially with UR at 48 months and an employment average starting at 48 months.

3. **Mediator measured after treatment with no causal mediation design.** There is no sequential ignorability argument, no formal mediation framework, and no attempt to distinguish mediation from overcontrol.

As written, the attenuation results are best described as descriptive decomposition or conditional association, not evidence that duration “explains” 77.3% of scarring.

---

## 3. Robustness and alternative explanations

### A. Robustness is partial and uneven

The window-robustness exercise is useful (Table 6), and the coefficient’s rough stability is reassuring. But all window variants remain imprecise. So this is robustness of point estimates, not robustness of inference.

The added-industry-share control check is sensible. However, the most revealing robustness check is Panel C of Table 6: dropping the four Sand States reduces the coefficient from \(-0.057\) to \(-0.025\) and renders it clearly uninformative. This suggests that the evidence is highly concentrated in a handful of extreme-boom states. That may well be economically meaningful, but it undercuts the generality of the title and conclusion. The paper currently interprets this as “consistent with the mechanism,” but it is also consistent with a result driven by a small number of influential states and episode-specific housing-bust dynamics.

### B. Pre-trends

The 12-month pre-trend is flat, but the 36-month pre-trend is significant (Section 8). This is a major issue and should not be treated as a secondary caveat. Because the treatment is a multi-year boom variable, longer pre-trend evidence is arguably more informative than the final 12 months before peak. This result substantially weakens the causal interpretation of the baseline GR estimates.

### C. Horse race specification

The horse-race result is difficult to interpret. The GR Bartik enters with a positive sign and the HPI coefficient becomes stronger (Section 5.1; Appendix Table 8). The paper acknowledges this is not a clean decomposition because the variables are correlated. I agree. As currently used, it does not provide compelling evidence that “housing demand—not industry composition—is the source of persistent scarring.” The positive sign on the GR Bartik may reflect multicollinearity, omitted factors, differential reversion, or construction-specific channels. It should not be used as strong channel evidence.

### D. Mechanism evidence is too indirect

The paper’s mechanism story relies on:
- national long-term unemployment and temporary layoff series;
- state unemployment-rate responses as a proxy for duration accumulation;
- attenuation when conditioning on state unemployment-rate persistence.

This is suggestive, but not enough to support the strong mechanism claim.

Most importantly, **state unemployment rates are not unemployment duration**. They are stock measures affected by inflows, outflows, participation, migration, and compositional change. The paper repeatedly interprets persistent unemployment-rate differentials as “duration trap” evidence (Section 6.2), but that is at best indirect.

For a paper centered on duration, I would expect actual duration-based state-level evidence:
- CPS microdata to construct state-by-time long-term unemployment shares;
- temporary layoff shares by state;
- recall rates or separation-type composition;
- participation and employment-population ratios by state;
- perhaps linked evidence on duration distribution, not just unemployment stocks.

Without that, the mechanism section remains interesting but underpowered relative to the paper’s framing.

### E. Alternative explanations

The manuscript acknowledges fiscal policy and match preservation (Sections 6.4, 8.2), but it still too quickly assigns the asymmetry to shock type and duration. Other plausible explanations remain underexplored:
- heterogeneity in policy speed and generosity across episodes;
- an unusually strong aggregate-demand rebound post-COVID;
- sectoral reallocation differences;
- remote work and digital substitution;
- differing monetary policy environments;
- differences in business balance sheets and credit conditions;
- demographic composition and migration patterns.

The current design cannot cleanly separate these. That is fine if the paper is reframed as documenting an episode contrast, but not if the title and conclusion generalize to “demand recessions” and “supply recessions” writ large.

---

## 4. Contribution and literature positioning

The paper is well-situated broadly in the hysteresis, local labor markets, and COVID labor-market literatures. The framing around duration as a central propagation mechanism is potentially useful.

That said, the literature positioning could be sharpened in two directions:

### A. Methodological / design literatures to engage more directly
For the Bartik design and shift-share identification:
- Borusyak, Hull, and Jaravel (2022), “Quasi-Experimental Shift-Share Research Designs”
- Goldsmith-Pinkham, Sorkin, and Swift (2020), “Bartik Instruments: What, When, Why, and How”

These are cited, but the paper should engage their identifying assumptions more directly, not just cite them for construction.

For mediation / mechanisms, the paper currently uses informal attenuation language where a stronger discussion of causal mediation assumptions is needed. Even if formal mediation is not pursued, the paper should acknowledge the limits of post-treatment conditioning.

### B. Policy-domain and hysteresis literatures
The paper cites several core contributions, but I would recommend adding or discussing:
- Ball (2009) on hysteresis and the Great Recession;
- Yagan (2019) is already cited and should be used more centrally, since it directly bears on long-run local labor market effects and worker outcomes;
- relevant post-COVID work on temporary layoffs/recall and labor market flows more systematically;
- work on state-level labor market adjustment and housing bust persistence beyond the headline Mian-Sufi framing.

The paper’s contribution relative to existing work is presently: “same 50 states across both episodes, with a duration-trap interpretation.” That is plausible, but it needs to be stated more narrowly and defended more carefully.

---

## 5. Results interpretation and claim calibration

This is the area most in need of recalibration.

### A. Over-claiming relative to statistical evidence

The title is too strong for the evidence. The paper does not establish that “demand recessions scar” in general or that “supply recessions don’t.” It studies one archetypal housing/financial recession and one pandemic recession with extraordinary policy intervention. Even within that comparison:
- the main GR long-run estimate is not significant at conventional levels;
- the formal pooled interaction test is insignificant;
- the mechanism is indirect.

A title and abstract framed as documenting “evidence consistent with stronger scarring after the Great Recession than after COVID” would be more defensible.

### B. “Full recovery” claim

The COVID result is a near-zero exposure gradient by 24–48 months. That is not the same as “recovered fully” in a broad economic sense. It is a relative cross-state statement conditional on the chosen exposure and controls. There may still have been national-level scarring or other persistent effects that the cross-state design cannot detect.

### C. Mechanism claims exceed evidence

The statement that “controlling for unemployment persistence substantially attenuates the Great Recession scarring coefficient, suggesting that duration—not initial job loss per se—is a primary driver of permanent damage” (Abstract) is too strong. Given the bad-control and accounting-identity concerns, that result does not identify duration as a primary driver.

### D. Policy implications are too strong

The conclusion draws sharp policy lessons on fiscal timing, PPP-like match preservation, and long-term-unemployment interventions. These are plausible and interesting, but the design does not separately identify:
- shock type,
- policy response,
- recall technology,
- timing of intervention.

So the policy implications should be presented as hypotheses or implications of the episode comparison, not direct causal lessons established by the estimates.

---

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Reframe the causal claim and substantially soften the title/abstract/conclusion
- **Issue:** The paper overstates what the design identifies.
- **Why it matters:** Current framing implies general causal claims about demand vs. supply recessions that the design cannot support.
- **Concrete fix:** Reframe around “evidence from comparing the Great Recession and COVID across states” and “patterns consistent with a duration-trap mechanism.” Remove categorical claims that demand recessions scar and supply recessions do not.

#### 2. Address the Great Recession pre-trend problem head-on
- **Issue:** Significant 36-month pre-trends undermine the baseline OLS identification.
- **Why it matters:** This is the most direct threat to the causal interpretation of the core GR result.
- **Concrete fix:** Make the pre-trend evidence central, not ancillary. Either redesign the specification to account for differential pre-trends, or shift the empirical center of gravity toward a more credible IV/event-study framework. At a minimum, show results with richer controls and trend adjustments and discuss how much the claims survive.

#### 3. Stop treating the attenuation exercise as causal mediation
- **Issue:** Table 5 conditions on post-treatment unemployment-rate outcomes that are mechanically and causally intertwined with employment.
- **Why it matters:** As written, the mechanism claim is overstated and methodologically misleading.
- **Concrete fix:** Recast Table 5 as descriptive decomposition only, or remove it from the main text. If mediation is retained, explicitly state the assumptions required and why the exercise is not causal mediation.

#### 4. Provide direct duration evidence at the state level, or sharply weaken the mechanism claim
- **Issue:** The paper’s central mechanism is duration, but the state-level evidence uses unemployment rates rather than duration measures.
- **Why it matters:** Persistent unemployment rates are not equivalent to prolonged unemployment duration.
- **Concrete fix:** Construct state-level CPS-based long-term unemployment shares, temporary layoff shares, and/or recall-related measures if feasible. If not feasible, revise the claim to say the evidence is “consistent with” but does not directly test duration accumulation.

#### 5. Reassess inference and the role of non-significant headline results
- **Issue:** The main GR estimate is not significant under the paper’s preferred inference, and the pooled interaction is insignificant.
- **Why it matters:** The strongest claims currently rest on statistically weak evidence.
- **Concrete fix:** Bring the non-significance front and center. If the main estimate remains imprecise, reframe the paper as a suggestive comparative study rather than a decisive causal demonstration.

### 2. High-value improvements

#### 6. Put common-horizon cross-episode comparisons at the center
- **Issue:** The GR and COVID long-run windows differ substantially.
- **Why it matters:** This undermines direct comparability.
- **Concrete fix:** Show common-horizon comparisons wherever possible, e.g., both episodes at 24, 36, and 48 months, and make those the main cross-episode contrast. Keep longer GR horizons as supplementary evidence on persistence.

#### 7. Strengthen the IV analysis
- **Issue:** The IV is relegated to supporting evidence despite baseline OLS weaknesses.
- **Why it matters:** If OLS has serious pre-trend concerns, IV needs to do more of the identification work.
- **Concrete fix:** Report IV for the main averaged estimand, discuss exclusion more rigorously, and explore sensitivity to additional controls related to construction, land use, migration, and pre-boom trends.

#### 8. Clarify the permutation procedure and justify exchangeability
- **Issue:** The manuscript overstates the validity of unrestricted permutation inference.
- **Why it matters:** Inference is a pass/fail issue.
- **Concrete fix:** Explain exactly what is permuted, whether controls are residualized first, and why exchangeability is plausible. Consider region-restricted permutations or placebo/randomization procedures that better match the assignment structure.

#### 9. Better characterize the COVID result as a relative-gradient result
- **Issue:** “Full recovery” is too broad.
- **Why it matters:** Readers may misread a cross-state null as aggregate no-scarring.
- **Concrete fix:** Use language such as “the cross-state exposure gradient largely closes by 24–48 months.”

#### 10. Investigate sensitivity to influential states more systematically
- **Issue:** Dropping the Sand States materially weakens the GR result.
- **Why it matters:** The result may be driven by a few states.
- **Concrete fix:** Report influence diagnostics, leave-one-out estimates, and leverage statistics in an appendix.

### 3. Optional polish

#### 11. Sharpen the literature contribution
- **Issue:** The current contribution is somewhat diffuse.
- **Why it matters:** Top journals require a very clear marginal contribution.
- **Concrete fix:** State more precisely whether the contribution is new evidence on episode heterogeneity, a duration-based interpretation of hysteresis, or a unified state-level framework spanning both recessions.

#### 12. Separate descriptive and causal evidence more explicitly
- **Issue:** The paper sometimes blends national descriptive templates, state-level causal claims, and mechanism arguments.
- **Why it matters:** This makes it harder to assess what each component contributes.
- **Concrete fix:** Label national series as descriptive, state exposure regressions as quasi-experimental within-episode evidence, and mechanism exercises as exploratory unless upgraded with stronger data.

---

## 7. Overall assessment

### Key strengths
- Important question with broad interest.
- Creative comparison of the same 50 state labor markets across two major recessions.
- Transparent acknowledgment that cross-episode differences reflect a treatment bundle, not pure shock type.
- Useful attempt to connect hysteresis to duration/recall mechanisms.
- Data construction and summary of the two episodes are clear.

### Critical weaknesses
- The main causal comparison is weaker than the paper’s framing suggests.
- The headline Great Recession long-run estimate is imprecise; the formal cross-episode interaction is insignificant.
- Significant longer-run pre-trends seriously weaken the baseline GR OLS identification.
- Mechanism evidence relies on indirect proxies and problematic post-treatment “mediation” regressions.
- The strongest substantive claims and policy conclusions overreach relative to the evidence.

### Publishability after revision
I think the project is potentially salvageable, but only with substantial reframing and stronger empirical work. In particular, the paper needs either (i) materially stronger identification/mechanism evidence, or (ii) a much more modest and descriptive interpretation of what is shown. In its current form, it is not publication-ready for the outlets listed.

DECISION: REJECT AND RESUBMIT