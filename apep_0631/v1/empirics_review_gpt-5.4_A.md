# V1 Empirics Check — openai/gpt-5.4 (Variant A)

**Model:** openai/gpt-5.4
**Variant:** A
**Date:** 2026-03-13T16:13:37.040956

---

## 1. Idea Fidelity

The paper does pursue the core idea in the manifest: using the 2018 TCJA SALT cap and the 2025 increase in the cap as a paired policy experiment, with zip-code-level pre-reform SALT exposure interacted with post indicators in a continuous-treatment DiD using Zillow ZHVI. The central research question—whether capitalization is symmetric or “sticky”—is also faithful to the original concept.

That said, several important elements of the original design are either omitted or implemented in ways that materially weaken the paper. First, the manifest emphasized a **symmetric pair of shocks**, but the paper treats the 2025 reform as beginning in **July 2025**, whereas the manifest states the law is retroactive to tax year 2025; that timing choice matters for interpretation. Second, the manifest proposed stronger triangulation using **FHFA**, **Redfin**, and **IRS migration flows** to separate price effects from volume/sorting; the paper mentions migration only narratively and does not use the other datasets. Third, the paper does not implement the more careful heterogeneity-robust/event-study logic promised in the manifest, and the evidence it presents for the reversal is much thinner than the original idea suggested.

## 2. Summary

This paper studies whether the housing-market capitalization of the SALT deduction is reversible. Using zip-code-level exposure to the 2018 SALT cap interacted with post-reform indicators in a panel of monthly Zillow home values, the paper finds that more exposed zip codes experienced larger price declines after 2018 and that prices did not rebound after the 2025 cap increase.

The topic is timely and potentially important, and the basic research design is intuitive. However, the current empirical implementation does not yet support the paper’s strongest claim—namely, that the 2025 reform reveals asymmetric or “sticky” capitalization.

## 3. Essential Points

1. **The identification strategy is not yet credible enough for causal interpretation of the 2018 effect.**  
   The treatment measure—average 2017 SALT deductions per itemizing return above the cap—is strongly correlated with housing values, income, itemization behavior, and other place characteristics that likely generate differential trends even absent TCJA. The paper’s current defenses are not sufficient: the event study shows a statistically significant pre-period coefficient at \(k=-3\), and the placebo among below-cap zip codes is itself sizeable and marginally significant. These are warning signs, not reassuring checks. To make the 2018 design credible, the paper needs a more explicit discussion of what variation identifies \(\beta\), tighter controls for pre-existing differential trends, and substantially stronger evidence that high-bite and low-bite zip codes within the same metro were on similar trajectories before TCJA.

2. **The 2025 “reversal” analysis is too underdeveloped, and in places incorrectly framed, to support a symmetry test.**  
   Seven months of post-reform data are simply too little to conclude that capitalization is not reversible, especially when the law is retroactive to tax year 2025, phases out by AGI, and is temporary through 2029. The paper repeatedly interprets a lack of immediate price rebound as evidence of a structural asymmetry, but the design cannot distinguish among slow adjustment, imperfect salience, policy uncertainty, interest-rate movements, or compositional frictions. More fundamentally, the regression specification for the reversal is not consistently reported: Table 2 is described as separating TCJA and OBBB periods but does not display those estimates, and Table 3 contains “NANA” for the metro-by-month specification. As written, the central contribution is not empirically established.

3. **The paper needs major clarification and correction of empirical implementation and interpretation.**  
   There are numerous internal inconsistencies: the number of above-cap zip codes differs from the manifest and from the text; the event-study narrative says pre-trends are clean, yet one pre-treatment coefficient is statistically significant; table references/descriptions do not match the displayed columns; the symmetry test is described as “full reversal” but the OBBB raises the cap to \$40,000 with income-based phaseout rather than restoring the pre-2018 system. Also, state-clustered inference with 51 clusters may be acceptable, but given treatment is highly concentrated in a few states/metros, the paper needs much more careful discussion of leverage and effective identifying variation. In its current form, the paper is not ready for publication.

## 4. Suggestions

This is a promising paper, and I think there is a publishable short paper in the project, but it needs to be reframed and substantially tightened around what the data can actually identify.

First, I would strongly recommend **separating the paper into two claims of very different evidentiary strength**:  
- a better-developed estimate of the **2018 TCJA capitalization effect**, and  
- a much more tentative **early evidence / no immediate rebound** analysis for 2025.  
Right now the paper gives them equal rhetorical weight, but they are not equally persuasive. The 2018 shock has a long post-period; the 2025 shock has only a handful of months and a much murkier mapping from statute to expected tax savings.

On the 2018 analysis, the paper would benefit from a more convincing empirical design. In particular:

- **Use richer pre-trend diagnostics.**  
  Show event studies with confidence intervals, not just a table. Include joint tests of all pre-period coefficients, not only a linear pre-trend. The significant \(k=-3\) coefficient should be confronted directly, not described away. If pre-trends remain, consider allowing for **zip-specific pre-trends**, flexible controls for baseline home value bins interacted with time, or estimating within narrower comparison sets.

- **Exploit within-metro comparisons more aggressively.**  
  The metro-by-month fixed effects are a good start, but because exposure is still highly correlated with neighborhood income and housing stock, consider restricting comparisons to zip codes within the same metro and similar baseline price deciles, or even bordering zip codes where feasible. A useful robustness check would be to re-estimate only in large metros with substantial within-metro variation in SALT bite.

- **Reconsider the treatment measure.**  
  “Average SALT deduction per itemizing return” is only an imperfect proxy for the policy bite. It ignores the itemization margin and the fact that TCJA also changed the standard deduction and other tax provisions. At minimum, report alternative exposure measures:  
  1. average SALT per return (not per itemizer),  
  2. share of returns above the cap if recoverable from the SOI bins or approximate via income classes,  
  3. separate property-tax-heavy and income-tax-heavy states if possible.  
  If the estimated effect is highly sensitive to this choice, that would be revealing.

- **Address the broader TCJA bundle.**  
  The identifying assumption is not just that high- and low-bite places would have parallel house-price trends absent the SALT cap; it is also that other TCJA provisions did not differentially affect high-bite places. But high-income areas were differentially exposed to changes in marginal tax rates, AMT, mortgage-interest interactions, and itemization incentives. The significant placebo below the cap is exactly the sort of result one would expect if the design is picking up broader itemization-related TCJA effects. I would encourage the authors either to model this explicitly or to soften the interpretation to “TCJA tax reform exposure correlated with SALT bite” unless they can isolate the cap more cleanly.

- **Be more careful with inference.**  
  Since most identifying variation likely comes from a limited number of high-exposure states and metros, standard state clustering may understate concerns about spatial correlation and policy exposure concentration. Report robustness using wild-cluster bootstrap at the state level, and perhaps Conley-type spatial SEs or clustering at broader exposure groupings. Also report the distribution of treatment intensity by state/metro so readers can see where leverage comes from.

For the 2025 reversal, I would substantially scale back the claims and improve the design:

- **Do not present the current evidence as a decisive rejection of symmetry.**  
  What the paper can currently show is that there is **no detectable immediate rebound in the first seven months**. That is interesting, but it is not yet evidence of irreversible capitalization. The title, abstract, and conclusion should be revised accordingly unless stronger evidence is developed.

- **Fix the timing and expected-incidence discussion.**  
  If the 2025 law is retroactive to tax year 2025, the relevant timing for house prices is not necessarily July 2025. Buyers and sellers may respond to legislative anticipation, enactment, tax filing expectations, or year-end salience. I would recommend an event-study centered on several plausible dates: election/legislative progress, enactment, and tax-year start. If results differ sharply by coding, that tells the reader the 2025 evidence is not mature enough.

- **Map exposure to the 2025 reform more carefully.**  
  The OBBB increase to \$40,000 is not the mirror image of the TCJA cap: it is partial, temporary, and income-phaseout-dependent. A true symmetry test would require a treatment variable for the **incremental benefit from moving from \$10,000 to \$40,000**, ideally accounting for the local income distribution. Using the same 2017 “bite” variable for both shocks is too crude. The authors should either build a distinct “reversal exposure” measure or explicitly relabel the exercise as testing whether the same highly exposed places show immediate relative appreciation after 2025.

- **Use market-activity outcomes.**  
  The manifest smartly proposed Redfin inventory, sales volume, and days on market. Those are especially important for 2025 because prices may move slowly while listings and transaction activity respond sooner. If the 2025 reform changed demand but not yet prices, that would still be informative and would materially improve the paper.

- **Bring in migration data more seriously.**  
  The discussion invokes sorting lock-in, but the paper does not test it. Even simple county-level IRS migration analyses showing whether high-exposure counties lost high-AGI filers after 2018 and whether those flows attenuated after 2025 would strengthen the mechanism section considerably. As written, the mechanism discussion is speculative.

On presentation and transparency, there are several straightforward improvements:

- **Correct table/reporting inconsistencies.**  
  Table 2’s text does not match the displayed estimates. Table 3 includes “NANA.” The event-study text says \(k=-3\) is insignificant, but the table reports \(p=0.002\). These issues undermine confidence in the analysis and must be fixed.

- **Clarify the sample construction.**  
  The paper variously references 22,965, 25,303, 26,300, 27,658, and different counts of above-cap zip codes. Some of this may be due to matching restrictions, but the final analysis sample and attrition should be explained clearly in one appendix table.

- **Scale effects more carefully.**  
  The back-of-the-envelope capitalization calculation compares estimated price effects to present values of tax changes, but the incidence depends on marginal tax rates, itemization choices, and permanence assumptions. Given the temporary nature of the 2025 provision and the contemporaneous level of mortgage rates, I would avoid language like “near-full capitalization” unless the authors explicitly model these margins.

- **Use alternative price series as validation.**  
  Even in a short AER: Insights paper, one figure or appendix table using FHFA zip HPI or Redfin median sale prices would reassure readers that the Zillow result is not a series-specific artifact.

- **Tone down the strongest rhetoric.**  
  Phrases such as “one-way ratchet,” “damage to housing equity may not be undone,” and “de facto irreversible” go well beyond what the evidence supports, especially for the 2025 portion. A more measured framing would help the paper.

Overall, I like the question and think the 2018 component could become a useful short paper if the identification is sharpened and the claims narrowed. The 2025 reversal is, at this stage, best presented as preliminary evidence on short-run adjustment rather than as a conclusive test of asymmetric capitalization.
