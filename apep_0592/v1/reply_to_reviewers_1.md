# Reply to Reviewers — Round 1

## Common Concerns Addressed

### 1. Pre-trend and Causal Language (All 3 reviewers)

**Concern:** The 1900–1910 earlier-period coefficient (5.34) is far larger than the main 1910–1920 estimate (0.80), undermining the parallel trends assumption. Causal language is too strong.

**Response:** We agree this is the paper's most significant limitation. We have comprehensively softened all causal language throughout the paper:
- Abstract: "raised" → "is associated with"; added RI p-value (0.098) alongside clustered p-value
- Introduction: "raised occupational scores" → "is associated with higher occupational scores"; added cautionary language about interpretation
- Results: Present RI p-value as co-primary with clustered p-value
- Long-run discussion: Reframed with multiple alternative explanations explicitly listed
- Conclusion: Reframed as "primarily descriptive" contribution; explicitly acknowledges design limitations
- Throughout: "effects" → "associations" or "patterns consistent with"

### 2. Treatment Timing Heterogeneity (GPT R1, GPT R2)

**Concern:** Collapsing 1907–1919 adopters into a single "treated" dummy ignores timing heterogeneity and prevents event-study analysis.

**Response:** This is a valid concern that we now discuss explicitly. Added paragraph in Related Literature engaging with Goodman-Bacon (2021), Callaway & Sant'Anna (2021), and Sun & Abraham (2021). The linked census panel structure (decadal observations only) fundamentally prevents annual event-study estimation. We acknowledge this constrains the design and note it as a limitation.

### 3. Mechanism Over-interpretation (All 3 reviewers)

**Concern:** Subsample heterogeneity ≠ mechanism identification. Claims about "reduced competition," "commercial real estate reallocation" are hypotheses, not findings.

**Response:** Renamed section from "Mechanism Tests" to "Heterogeneity by Industry and Outcome." Added explicit statement that these are "patterns consistent with candidate channels rather than identified mechanism tests." Reframed throughout as descriptive heterogeneity.

### 4. Long-run Reversal Not Identified (All 3 reviewers)

**Concern:** The 1920–1930 reversal could reflect many factors besides social infrastructure destruction.

**Response:** Substantially rewritten. Now presents the social infrastructure interpretation as "one interpretation — though not the only one," explicitly lists alternatives (differential urban-rural growth, compositional change, immigrant assimilation, mean reversion), and states that the design "cannot conclusively determine" the mechanism.

### 5. Inference Reconciliation (All 3 reviewers)

**Concern:** RI p-value (0.098) vs clustered p-value (0.004) are materially different; RI should be primary.

**Response:** Now present RI p-value alongside clustered p-value at first mention of the main result in the Results section. Added note explaining that "the RI p-value is more conservative because it accounts for the small number of policy units (45 states)."

### 6. Post-treatment Exposure for Early Adopters (GPT R1, GPT R2)

**Concern:** 1910 alcohol share is post-treatment for 5 states.

**Response:** Already addressed in Section 4.2 with dedicated paragraph. Paper argues this biases toward zero (conservative), notes the robustness of results to non-South sample (which drops most early adopters).

### 7. Missing DiD Literature (Both GPTs)

**Response:** Added Goodman-Bacon (2021), Callaway & Sant'Anna (2021), and Sun & Abraham (2021) to references.bib and discussed in a new methodological paragraph in Related Literature. Explains why decadal panel structure prevents standard event-study implementation.

### 8. Women's Star Inconsistency (Both GPTs)

**Response:** Fixed. Text now says "marginally significant at the 10% level" (consistent with the * in the table) rather than "statistically insignificant."

## Exhibit and Prose Improvements (from Stage A.5/A.6 reviews)

- Promoted 4 figures to main text (timeline, binscatter, mechanisms, heterogeneity)
- Split Table 5: long-run results now dedicated Table 5; women's results moved to Appendix
- Replaced roadmap paragraph with punchy reversal summary
- Translated 0.80 effect size into real-world terms (laborer-to-operative gap)
