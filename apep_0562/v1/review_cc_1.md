# Internal Review — Round 1

**Paper:** Networked Anxiety Without Contact: Asylum Dispersal and the Far-Right Network Multiplier in France
**Reviewer:** Claude Code (self-review as Reviewer 2 + Editor)
**Date:** 2026-03-09

## Verdict: MINOR REVISION

## Summary

This paper tests whether social-network exposure to France's 2021 asylum dispersal policy (SNA) increases Rassemblement National vote share, using a shift-share DiD design combining SCI weights with new asylum reception capacity. The main finding — β = 0.058 (t = 7.9) on NetworkDispersal × Post with a null own-dispersal effect — is striking and well-supported by robustness checks including randomization inference, leave-one-out, and wild bootstrap. The paper is well-written with a compelling narrative arc from the contact hypothesis puzzle to the network anxiety mechanism.

## Strengths

1. **Clever identification strategy.** The shift-share design is well-suited: SCI weights are pre-determined social ties, shifts are policy-driven asylum placements. The identification assumption is clearly stated and thoroughly tested.

2. **Strong robustness battery.** LOO, RI (1000 perms), wild cluster bootstrap, alternative SCI normalizations, binary treatment, and a placebo outcome. This exceeds the standard for shift-share papers.

3. **Triple-difference decomposition.** The hosting vs. non-hosting split (β_nonhost = 0.150 vs β_host = 0.065) is the paper's most compelling evidence for the network anxiety channel.

4. **Clean connection to apep_0464.** The paper explicitly positions itself relative to the "Connected Backlash" framework, testing cross-domain generalizability of the network multiplier.

5. **Institutional detail.** The SNA background is thorough without being excessive. The allocation formula description supports the exogeneity argument.

## Concerns

### Major

1. **2014 pre-trend coefficient.** The event study shows a significant negative coefficient in 2014 (−0.031, p < 0.05). The paper acknowledges this as "mean reversion from exceptionally high RN European performance" but this explanation is somewhat ad hoc. The 2017 presidential election coefficient should be closer to zero if trends are truly parallel — need to report this coefficient explicitly and discuss whether the 2014 outlier reflects a genuine concern about non-parallel trends or a known feature of European elections as a different electoral context.

2. **Asylum capacity data construction.** The actual CADA/OFPRA facility-level data returned 404 errors, so the shift variable was constructed from regional aggregates (Cour des comptes reports) distributed equally across departments within each region. This equal-distribution assumption could introduce measurement error. The paper should be more transparent about this data limitation and discuss the direction of resulting bias (likely attenuation if true allocation was concentrated in specific departments within regions).

3. **SCI as a measure of social ties.** Facebook penetration is not uniform across French departments. Urban departments and younger populations are overrepresented. If SCI systematically overmeasures social ties for certain department types that also have different voting trends, this could introduce bias. A brief discussion of SCI's validity in the French context, citing Bailey et al.'s validation studies, would strengthen the paper.

### Minor

4. **Limited mechanism evidence.** The paper posits "negativity bias in network transmission" but doesn't directly test information channels (e.g., social media engagement, news consumption). This is acknowledged as a limitation but could be strengthened by discussing what data would help isolate the mechanism.

5. **Single-country setting.** The generalizability beyond France is unclear. The SCI-as-instrument approach could be applied to other EU countries with asylum dispersal policies (Germany's Königsteiner Schlüssel, Sweden's EBO reform). A brief discussion of external validity would add value.

6. **Placebo is mechanical.** Using non_rn_share = 100 − rn_share as a placebo is mechanically the mirror of the main result. A more informative placebo would use turnout, abstention rate, or other party vote shares.

7. **No discussion of SUTVA.** If departments adjust behavior in response to connected departments' asylum placements (e.g., lobbying to avoid placements), the treatment could be endogenous. Brief discussion of SUTVA in the shift-share context would help.

## Recommendations

1. Expand discussion of the 2014 coefficient and what it means for identification
2. Be more transparent about asylum data construction from regional aggregates
3. Add a paragraph on SCI validity in the French context
4. Consider adding turnout as an alternative placebo outcome
5. Brief SUTVA discussion in the identification strategy section

## Overall Assessment

A strong paper with a novel question, credible identification, and robust results. The network anxiety channel is a genuine contribution to the immigration-voting literature. The concerns above are addressable within a minor revision — none threatens the core finding.
