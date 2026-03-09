# Internal Review — Round 1

## Verdict: MINOR REVISION

## Strengths
1. **Novel angle**: The venue substitution mechanism is creative and well-motivated. The connection between sports betting → alcohol → driving is a genuine causal chain that hasn't been studied.
2. **DDD design**: Exploiting NFL Sunday variation adds a convincing identification dimension beyond standard state-year DiD.
3. **Honest null framing**: The paper doesn't oversell — it transparently discusses the MDE, notes the marginal significance of the DDD, and frames the null as informative.
4. **Placebo test**: The non-alcohol crash placebo (column 2) is well-conceived and strongly supports the alcohol-specific interpretation.
5. **Leave-one-out**: Remarkably stable coefficients across all 22 permutations.

## Weaknesses
1. **Marginal significance**: The headline DDD result is p=0.10 — suggestive but not conventionally significant. The paper is upfront about this but the entire narrative rests on this marginal result.
2. **CS-DiD failure**: The paper references Callaway-Sant'Anna estimates but the actual CS estimation failed (unbalanced panel). The text should be more transparent about this.
3. **DRUNK_DR measurement break**: The variable coding change in FARS post-2020 (from accident-file DRUNK_DR to person-file derivation) creates a potential measurement discontinuity. While absorbed by year FE, this could interact with the treatment in states that legalized after 2020.
4. **Night vs Day puzzle**: Both nighttime and daytime DDD coefficients are negative (-0.118 and -0.151), which weakens the "bar drinking → home drinking" narrative since bar-to-home substitution should be strongest at night.
5. **Limited external validation**: The venue substitution mechanism is plausible but not directly tested — no data on actual bar visits, credit card transactions, or off-premise alcohol sales by state.

## Minor Issues
- Some reference entries may need updating (e.g., working paper citations)
- The welfare section's $4 billion estimate based on an insignificant coefficient should be flagged more prominently as speculative
- The abstract says "p = 0.10" but should note this is only marginally significant

## Recommendation
Proceed to external review. The paper has a compelling angle, honest methodology, and transparent discussion of limitations. The main weakness is statistical power, which is inherent to the setting and acknowledged throughout.
