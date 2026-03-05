# Internal Review — Round 1

**Paper:** Slower Streets, Safer Streets? The Causal Effect of Wales's 20 mph Default Speed Limit on Road Casualties and Property Values

**Verdict:** MINOR REVISION

## Strengths

1. **Clean identification:** The Wales-England DiD with devolved policy is excellent. The built-in placebos (road-type, Scotland, temporal) provide unusually strong falsification tests for a DiD design.

2. **Novel question:** First causal evaluation of a national default urban speed limit reduction. The property value angle adds a welfare dimension absent from the public health literature.

3. **Comprehensive robustness:** Randomization inference (p=0.017), Poisson QMLE, border PFAs, excluding COVID, nation trends — all point in the same direction.

4. **Strong writing:** Opening hook is vivid (pedestrian fatality risk). Results section tells a story rather than narrating tables.

## Weaknesses

1. **Few clusters concern:** Only 4 treated PFAs is a real limitation. While RI addresses this for the point null, power for subgroup analysis is essentially zero. The paper acknowledges this but could be more explicit about the MDE for KSI outcomes.

2. **Property value identification:** The property value DiD uses postcode prefixes to assign nation, but some Welsh postcodes (especially LL) extend close to the border. The exclusion of SY is good but the boundary is still fuzzy. District fixed effects help but can't fully address selection on unobservables that differ between Welsh and English districts.

3. **Partial reversals:** The paper notes that reversals began in 2024 but doesn't quantify how many roads were affected. This matters for interpreting the magnitude.

4. **Missing references:** Some references in the bib file have wrong entry types (e.g., Fisher 1935 and Angrist 2009 are books listed as @article).

## Minor Issues

- The abstract says "20.2 percent" but this appears to be exp(-0.227)-1 = -20.2%. The log coefficient is -0.227. These are consistent but the paper switches between them without being fully explicit.
- Table float placement [H] may cause layout issues. Consider [htbp].
- The KSI trend figure (fig3) is only in the appendix — consider mentioning it more prominently in the main text.

## Recommendation

The paper is strong and publishable. Fix the minor issues and proceed to external review.
