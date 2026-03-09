## Discovery
- **Policy chosen:** ZRR 2017 reclassification — sharp eligibility reform with 3,063 losers and 3,657 gainers creates natural experiment for electoral consequences of place-based policy withdrawal
- **Ideas rejected:** Loi NOTRe municipal mergers (fiscal outcomes less exciting, "technically competent but not exciting"), Maternity ward closures (endogeneity concerns with closure selection)
- **Data source:** data.gouv.fr for ZRR lists and election data; INSEE Sirene for firm creation; FLORES for employment — all public, no API keys needed for core data
- **Key risk:** Anticipation effects from 2015 law announcement could blur pre/post boundary; mitigated by treating April 2017 election as last pre-treatment and focusing on 2022 as clean post-treatment

## Review (Stage C Revision)
- **Critical finding from review:** All 3 reviewers demanded EPCI-level clustering; department-level clustering (most conservative available) renders main result insignificant (p=0.396)
- **Pre-trends concern confirmed:** New placebo test (purely pre-2017) is significant (p=0.013), indicating pre-existing differential trends
- **Denominator effect is real:** Registered voters +15, valid votes +12 per commune — loser communes experienced differential electorate growth, partly explaining vote-share decline
- **Event study re-anchoring:** Changing base from 2017 to 2012 makes 2022 coefficient CI include zero under conventional inference
- **Lesson:** With only 1 post-treatment election, design is inherently fragile. Result was over-claimed in initial draft. Honest reporting of fragility is better than optimistic framing
- **Subgroup tests formalized:** Interaction terms for size and prior-FN heterogeneity are both significant (p=0.001 and p<0.001)

## Summary
- **Final result:** Conventional DiD estimate is -0.334pp (p=0.005, commune-clustered) but not robust: insignificant under department clustering (p=0.396), HonestDiD includes zero, significant placebo pre-trend
- **Key contribution:** The paper documents a boundary condition for the "state withdrawal → populism" narrative: invisible, supply-side tax incentives may lack the political salience to generate backlash. This is a conceptual contribution even with a fragile causal estimate
- **Denominator/composition channel:** The most robust finding is differential electorate growth in loser communes, suggesting compositional change rather than attitudinal shift
- **Design lesson for future work:** Settings with only 1 post-treatment period and threshold-based assignment should exploit the threshold directly (RD or local DiD) rather than broad treated-vs-control comparisons. EPCI-level crosswalk data is essential for proper inference in French commune-level studies
- **Review lesson:** Reviewer convergence was strong — all 3 external reviewers flagged the same core issues (EPCI clustering, pre-trends, first-stage). Honest reporting of fragility was praised by all reviewers as a strength
- **Tournament expectation:** Given the fragile identification, this paper will likely underperform in tournament relative to papers with clean designs. But honest null results with interesting questions are valued over fabricated significance
