# Reply to Reviewers

## Reviewer 1 (GPT-5.2)

**Control group:** We acknowledge that our control communes are structurally different from ACV cities (rural vs. medium-sized urban). We now discuss this limitation more explicitly and note that propensity-score matching on pre-treatment characteristics is a natural extension. The département-by-year fixed effects specification helps but does not fully resolve within-département urbanity trends.

**Unbalanced panel:** The paper now clearly explains that 123 ACV communes with no pre-treatment data are dropped as singletons by the commune FE estimator. The identifying sample is the subset with pre-post variation.

**Treatment timing:** The paper now explicitly states that the 22 later-added communes are included conservatively (biasing toward zero), with a footnote quantifying the attenuation and noting robustness to restricting the sample.

**COVID confounding:** We have strengthened the discussion of COVID timing coincidence. The département-by-year FE absorbs regional pandemic shocks, and the event study shows effects persisting through 2024 (well past the pandemic period).

**Composition evidence:** We have added Figure 7 showing direct evidence of the compositional shift — apartment share rises from 48% to 52% in treated cities post-treatment, while controls remain stable.

## Reviewer 2 (Grok-4.1-Fast)

**Control group matching:** We acknowledge this concern and discuss propensity matching as an extension.

**COVID disentangling:** The département-by-year FE absorbs regional COVID variation. Effects persist through 2024, beyond the pandemic period. We note the remaining concern about within-département urbanity trends.

**Dose-response:** Convention-level funding data is not publicly available at sufficient granularity for dose-response analysis.

## Reviewer 3 (Gemini-3-Flash)

**Control group:** We acknowledge the imbalance and discuss matching as future work.

**COVID hypothesis:** We note that while the timing coincides, the persistence of effects through 2024 and the compositional nature of the effect (which is specific to housing market structure rather than general price appreciation) help distinguish ACV from pandemic sorting.

**Within-commune analysis:** The geocoded DVF data could support within-commune analysis in principle, but ACV perimeters are not consistently available as shapefiles. This is an important direction for future work.
