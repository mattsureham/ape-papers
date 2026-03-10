# Internal Review — Round 1

**Paper:** What Goes On Does Not Come Off: Estimating Policy Hysteresis Across Five European Reversals
**Reviewer:** Claude Code (self-review)
**Date:** 2026-03-10

## Verdict: Minor Revision

## Strengths

1. **Novel estimand.** The reversal ratio (RR = β_OFF / β_ON) is a clean, interpretable measure of policy hysteresis. No prior work systematically compares this across multiple policy domains.

2. **Built-in placebos.** Each reform has a natural control group that strengthens identification: non-food HICP for Denmark, men 60-64 for Poland, neighboring countries for France.

3. **Honest about limitations.** Czech data dropped cleanly (no pre-policy data). Italy RR acknowledged as uninformative. Meta-regression honestly flagged as N=4.

4. **Strong Denmark and Poland results.** Denmark fat tax shows clear price ratcheting (RR = 0.36). Poland retirement age shows near-complete hysteresis (RR = 0.95). Both have clean pre-trends.

## Weaknesses

1. **Italy specification is weak.** Splitting regions by median baseline poverty is a poor proxy for RdC treatment intensity — all regions received the program. The near-zero β_ON suggests the identification doesn't capture the policy effect. Consider dropping Italy or reframing as descriptive.

2. **France interpretation needs care.** The negative β_ON for the supertax (labor costs FELL in France relative to neighbors) is counterintuitive and needs more careful explanation. Could reflect compositional changes or the broader French economic slowdown rather than the tax itself.

3. **Small N for meta-regression.** With N=4, the cross-reform regression is essentially illustrative. The paper acknowledges this but could make the framing even more cautious.

4. **Poland pre-trend concern.** The p=0.09 pre-trend test for Poland is borderline. The paper should discuss this more thoroughly and consider Rambachan-Roth sensitivity.

5. **VCOV warnings.** Several models report non-positive-semi-definite variance matrices that were "fixed." This should be investigated and reported transparently.

## Recommendations

1. Reframe Italy more explicitly as an illustration with a data limitation
2. Add a paragraph explaining the France β_ON sign
3. Discuss Poland pre-trend more thoroughly
4. Mention VCOV fixes in a footnote
5. Consider adding a conceptual figure (timeline of all 5 reforms) early in the paper
