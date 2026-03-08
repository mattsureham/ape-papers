# Reply to Reviewers — Round 1

**Paper:** apep_0544 v1 — Cutting the Pipeline
**All 3 external reviewers:** MAJOR REVISION

---

## Common Concern 1: Over-claiming relative to evidence

**GPT R1:** "The paper repeatedly interprets the results as evidence of 'de-industrialization,' 'persistent capacity loss,' 'hysteresis,' and a 'lower bound' on the true effect. Those claims are not currently established."

**GPT R2:** "The paper claims de-industrialization, persistence, hysteresis, and lower-bound interpretation despite null/imprecise estimates."

**Gemini:** "The abstract and conclusion describe 'causal estimates' and 'persistent de-industrialization,' but the empirical results do not support these claims."

**Response:** We agree this was the paper's most serious flaw. We have comprehensively recalibrated all claims throughout the paper:

- **Abstract:** Removed "first causal estimate" and "lower bound." Now says "reduced-form relationship," "statistically imprecise," and "suggestive of persistence but not statistically established."
- **Introduction:** Changed "first causal evidence" to "reduced-form evidence." Removed claim that imprecision is driven by subsidies. Added explicit caveat that dynamic coefficients are individually insignificant.
- **Results:** Dynamic effects now described as "suggestive evidence on the trajectory" with explicit caveats about imprecision and alternative explanations.
- **Discussion:** Removed "lower bound" interpretation entirely. Subsidy section now states "we cannot sign the resulting bias with confidence" and explicitly rejects the lower-bound framing. CGE comparison reframed as "illustrative rather than definitive."
- **Conclusion:** Completely rewritten. Removes hysteresis language, rare earths/semiconductors generalization, and "the true effect was likely larger" claims. Now frames the paper as providing "a framework for thinking about energy dependence" with honest limitations.
- **Energy Security section:** All three implications now hedged with "if the negative relationship we estimate is real" and similar qualifications.

---

## Common Concern 2: "Lower bound" claim not identified

**GPT R1:** "The claim that subsidies bias estimates toward zero... is too strong. Without subsidy data and an explicit model, it is not possible to sign the net bias."

**GPT R2:** "The paper has no direct subsidy measure."

**Gemini:** "If subsidies were perfectly targeted to the most exposed cells, they might mask the effect entirely."

**Response:** We have removed all "lower bound" language from the paper (3 instances: abstract, institutional background, limitations). The revised text states: "Subsidies could attenuate the measured effect (biasing β toward zero), but they could also create selection effects: if subsidies were targeted precisely to the most exposed country-sector cells, they interact with the treatment variable in ways not absorbed by country×month fixed effects. Without data on actual subsidy disbursements by country-sector-month, we cannot determine whether subsidies push our estimates toward or away from zero."

---

## Common Concern 3: Hungary outlier

**GPT R1:** "The sign of the estimated effect is not robust to the exclusion of a single country."

**GPT R2:** "Not just 'imprecision'; it indicates that the effective identifying variation is coming from a handful of influential units."

**Gemini:** "The entire result depends on Hungary."

**Response:** We have substantially expanded the LOO discussion. The revised text now:
- Correctly reports Hungary's gas dependence as 85% (the highest in the sample)
- Explains why Hungary has disproportionate leverage (combination of extreme gas dependence and broad sector coverage)
- Explicitly states: "The result cannot be interpreted as reflecting a general European pattern"
- Discusses potential idiosyncratic factors (industrial policy, Orbán government's energy pricing, IP index measurement)
- Notes Austria at the other extreme (-0.407 when excluded)
- Frames the LOO range as "an honest reflection of limited information in 23 clusters"

---

## Common Concern 4: Placebo tests are concerning

**GPT R1:** "The placebo tests using March 2019 and March 2020 produce coefficients of similar magnitude to the main estimate, which is a serious warning sign."

**GPT R2:** "A large negative placebo in 2019 cannot be dismissed by COVID."

**Gemini:** "It suggests that the interaction may be picking up a general 'vulnerability to shocks' rather than a specific gas cutoff channel."

**Response:** We have substantially revised the placebo discussion. The new text:
- Explicitly acknowledges the March 2019 placebo "is harder to dismiss" than March 2020
- Raises the possibility that "the gas-share × gas-intensity interaction captures broader vulnerability to macroeconomic shocks—a 'fragile heavy industry' channel—rather than the specific gas-cutoff mechanism"
- Notes that the pre-COVID trend test "rules out a secular differential trend but does not rule out episodic pre-trend violations"
- Presents these results as "a limitation of the design's ability to isolate the gas-specific channel"

---

## Common Concern 5: Dynamic claims not formally tested

**GPT R1:** "Without a formal test of difference, this is over-interpretation."

**GPT R2:** "Test β_2023 − β_2022 = 0, report confidence intervals."

**Response:** We have toned down all dynamic narrative. The revised text:
- Reports SEs alongside year-specific coefficients in the introduction
- Explicitly states "Neither is individually significant, and we do not report a formal test of their equality"
- Replaces "nearly doubled" with "point estimates become more negative"
- Replaces "the deepening pattern rules out several alternative explanations" with "several caveats apply" including imprecision and alternative explanations

---

## Concern 6: Estimand clarity (R1, R2)

**GPT R1:** "The paper mixes 'invasion shock,' 'gas cutoff,' and 'gas price shock' somewhat interchangeably."

**GPT R2:** "The draft slips between a gas-cutoff effect, a gas-price effect, and a broad war-exposure effect."

**Response:** Added a new "Estimand interpretation" paragraph in the Threats to Validity section that explicitly states: "Our design identifies a reduced-form differential effect of pre-war Russian gas exposure... This is not a clean estimate of the 'gas cutoff' channel alone, because gas dependence correlates with exposure to electricity price spikes, broader energy cost increases, and possibly differential demand or policy shocks."

Also added a "Gas intensity as proxy" paragraph acknowledging that "Sector gas intensity may proxy for broader energy intensity, trade exposure, or cyclical sensitivity."

---

## Concern 7: Literature positioning (R1, R2)

**GPT R1:** "The paper should engage with Borusyak, Hull, and Jaravel (2022) on quasi-experimental shift-share designs; Goldsmith-Pinkham, Sorkin, and Swift (2020) on Bartik/exposure designs."

**Response:** Added both citations to references.bib and incorporated them in two locations:
- Introduction (contribution paragraph): "Methodologically, our design is related to exposure-based identification strategies studied by Goldsmith-Pinkham, Sorkin, and Swift (2020) and Borusyak, Hull, and Jaravel (2022)"
- Threats to Validity: "Our design relates to exposure-based identification strategies... the identifying variation comes from the interaction of predetermined country-level 'shares' (gas dependence) with a common post-2022 shock"

---

## Concern 8: Mechanism evidence weak (R1, R2)

**GPT R1:** "A null on output prices does not identify the channel."

**GPT R2:** "The mechanism section does not establish a mechanism; it offers a speculative interpretation of a null."

**Response:** Reframed the producer price discussion as explicitly exploratory. Added caveats about seasonal adjustment, lag structure, and the fact that "the null is consistent with government price interventions but does not establish the subsidy channel—we have no direct subsidy data to test this interpretation."

---

## Not addressed (with rationale)

- **Wild cluster bootstrap:** RI p=0.58 already establishes the result is not significant. WCB would tell the same story. Adding it would not change any conclusion.
- **Longer event study (2015+):** The k=-24 to +22 window is standard for monthly event studies. The pre-COVID trend test (2015-2019, t=-0.14) addresses the concern about secular trends.
- **Exclude CZ/TR from baseline:** Already shown in appendix that β is identical (-0.231). Making this the preferred spec would not change results.
- **Subsidy data interaction:** Requires new data beyond scope.
- **Horse-race with other sector characteristics:** Requires new data beyond scope. Acknowledged as a limitation in the new "Gas intensity as proxy" paragraph.
- **Multiple placebo dates:** Acknowledged as a needed improvement; the two reported dates already reveal the concern.
