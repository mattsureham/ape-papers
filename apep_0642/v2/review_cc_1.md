# Internal Review: apep_0642 v2

## Reviewer 2 (Harsh)

1. **The pooled non-air result is NOT significant (p=0.245).** The V1 paper's headline finding — that non-air releases rise 1.8% — is gone. With 9 TRI years (vs 18 in V1), the sample shrinks from 485K to 115K observations and 3,544 to 2,023 facilities. This is a substantial loss of power. The paper must be honest about this, and it is.

2. **The balance test failure (F=18.05, p≈0) is devastating.** Inspection timing is strongly predicted by pre-treatment facility characteristics. The paper's entire identification rests on quasi-random timing, and this test says the timing isn't random. Combined with RI p-values >0.5 and pre-trends (p=0.009), the causal claims should be substantially weakened.

3. **The mechanism test sign inconsistency is concerning.** The split sample shows CAA chemicals have larger non-air increases (+0.026 vs +0.009), but the joint interaction specification reverses this (-0.032 interaction coefficient implies non-CAA chemicals have larger increases). The paper now correctly reports both, but this undermines the "targeted regulatory avoidance" narrative.

4. **Medium-specific decomposition is all insignificant.** Air -0.022 (p=0.55), Water -0.021 (p=0.35), Land +0.024 (p=0.13), POTW +0.008 (p=0.64). None individually significant. The pattern of signs is suggestive but the evidence is weak.

5. **Missing data years create compositional bias.** Having 2005, 2007, 2008, then jumping to 2014-2015, then 2018-2022 means the panel is sparse. Facilities active only in the missing years are excluded. This is not random — it systematically drops mid-2000s and early-2010s observations.

## Editor (Constructive)

**What works:**
- The CWA control addition is genuinely valuable. The CWA×NonAir interaction (-0.079, p=0.06) shows that correlated enforcement matters. This is a real contribution to the literature.
- The event study figures are well-constructed and add substantial visual evidence absent from V1.
- The honest framing — "Cross-Media Pollution Reallocation Under Fragmented Environmental Enforcement" — is appropriate for the evidence.
- The extensive-margin null (p=0.62) is useful information: substitution doesn't create new release pathways.

**What needs work:**
- The magnitudes section should use consistent pre-means (tab1 vs tab8 discrepancy noted by Codex)
- The paper could lead more aggressively with what IS strong: the CWA control innovation and the chemical-type asymmetry
- The abstract is slightly over-cautious per Codex feedback — tighten rhetoric

**Overall assessment:** This is an honest, methodologically improved V2 that adds CWA controls and visual evidence but discovers that the V1's headline finding doesn't survive with less data. The mechanism test remains the strongest evidence. The paper should be sent to formal review — the findings are real even if weaker than hoped.
