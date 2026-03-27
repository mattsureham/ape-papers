# V1 Empirics Check — openai/gpt-5.4 (Variant C)

**Model:** openai/gpt-5.4
**Variant:** C
**Date:** 2026-03-27T11:30:02.305280

---

## 1. Idea Fidelity

The paper broadly follows the manifest’s core idea: it studies whether counties more socially connected to SVB’s footprint experienced larger deposit declines during the 2023 panic, using county-level SCI exposure and FDIC Summary of Deposits. The main research question is preserved, as is the emphasis on distinguishing social ties from pure geography.

That said, several important elements from the original design are either omitted or only asserted rather than implemented. Most notably, the manifest promised controls for media-market overlap and local bank balance-sheet fundamentals, diagnostics for the shift-share design (including Rotemberg weights), and complementary bank-level evidence using FFIEC Call Reports. None of these actually appears in the paper. The paper also frames the design as if the identifying variation is “orthogonal to geographic proximity,” but it does not provide the kind of exposure decomposition or leave-one-origin diagnostics that would make that claim credible in a shift-share setting. So the paper is faithful to the broad idea, but not yet to the full identification strategy originally envisioned.

## 2. Summary

This paper argues that private social ties helped propagate the 2023 banking panic: counties with stronger Facebook-based social connectedness to SVB’s California footprint saw larger deposit declines between June 2022 and June 2023. The main estimate implies that a one-standard-deviation increase in exposure predicts a 0.89 percentage point larger deposit decline, with placebo pre-periods and a JPMorgan placebo exposure used as supporting evidence.

The paper’s central contribution is clear and potentially interesting. But in its current form, the design does not yet convincingly separate social-network contagion from correlated county characteristics, compositional shifts in local banking structure, and the limitations of annual county-level deposit data for a shock that unfolded in days.

## 3. Essential Points

1. **The outcome measure is too coarse for the mechanism being claimed.**  
   The paper’s mechanism is an acute panic in March 2023, but the main outcome is the change in county deposits from June 2022 to June 2023. That is an annual net change that bundles together the panic, subsequent stabilization, interest-rate-driven reallocations, deposit competition from money market funds, bank failures and acquisitions, and branch network changes. A county-level annual SOD change is therefore a very noisy proxy for “deposit flight during the panic.” This does not make the exercise useless, but it sharply weakens the causal interpretation. At minimum, the paper needs complementary evidence using higher-frequency bank-level Call Report deposits (Q4 2022 to Q1 2023, as the manifest itself proposed), ideally interacting county exposure with bank exposure or county branch composition.

2. **Identification is not yet persuasive because the exposure variable may proxy for omitted economic connectedness, not panic transmission through private ties.**  
   Counties socially connected to Silicon Valley are also likely to be richer, more educated, more financially sophisticated, more exposed to venture/tech networks, and more likely to reallocate deposits in response to rate changes or uninsured-deposit concerns. The current controls—distance, income, population, state fixed effects, and an “information sector” employment share—are not enough. In particular, the paper does not control for county banking composition, uninsured deposit intensity, local branch shares of vulnerable banks, or media overlap despite claiming to distinguish private networks from public information channels. The null JPM placebo is not a strong falsification test, because JPM’s footprint is national and economically very different from SVB’s concentrated and sector-specific footprint. The paper needs stronger identification diagnostics and richer controls before one can interpret the coefficient as social contagion rather than “Silicon Valley–connected counties behave differently in 2023.”

3. **The inference and some descriptive statistics raise red flags.**  
   State-clustered standard errors with about 50 clusters are not automatically inappropriate, but here treatment varies at the county level while the shock is national and the exposure is highly spatially correlated. I would want to see wild-cluster bootstrap p-values and spatially robust alternatives. More importantly, several numbers in the paper are internally inconsistent or implausible. Table 2 labels a placebo as 2017–2018 even though the data section begins in 2019. The “tech employment share” summary statistics are impossible as written if interpreted as a share of total employment: a mean of 0.72 with interquartile range 0.78–0.91 cannot be right for NAICS 51. The heterogeneity table reports a low-deposit coefficient of 0.0167 with SE 0.0605 but describes it as “oppositely signed” and uninformative; that estimate is essentially noise. These issues undermine confidence in the data construction and should be corrected before the result can be evaluated seriously.

## 4. Suggestions

The paper has the skeleton of an AER: Insights-style note, but it needs to become much more disciplined empirically. My suggestions below are meant to help you get there.

First, **tighten the empirical object**. Right now the paper says “deposit flight during the March 2023 panic,” but the main outcome is annual June-to-June county deposit growth. That is too far from the event. The natural fix is exactly what your manifest proposed: use **bank-level Call Report deposits from Q4 2022 to Q1 2023**. If county SCI exposure matters, then banks with greater deposit exposure to high-SCI counties should show larger Q1 deposit declines, especially among banks more vulnerable to uninsured-deposit runs. This would align timing with mechanism and address the biggest weakness of the current draft. Even a simple two-part design—county SOD annual evidence plus bank-level quarterly validation—would be much stronger.

Second, **clarify what variation identifies the effect**. In shift-share designs, it is not enough to state that SVB’s footprint was concentrated. You should show:
- the distribution of county exposure,
- the contribution of each origin county to overall identifying variation,
- whether Santa Clara overwhelmingly drives the result,
- leave-one-origin-county-out estimates,
- and ideally Rotemberg-style weights or a close analogue.

This matters because with only 9 SVB counties, the exposure may effectively collapse to “social connectedness to Santa Clara/Bay Area,” which is itself a proxy for many omitted county traits. A map of exposure and a decomposition of the shares would help readers understand whether the design has real cross-county variation or just one dominant origin.

Third, **improve the control strategy substantially**. At minimum, I would add:
- county banking structure measures from SOD: concentration, number of branches, branch shares of large banks, local exposure to uninsured-deposit-heavy institutions if constructible;
- local pre-2023 deposit composition or growth by bank type;
- direct controls for education, sector mix beyond NAICS 51, and perhaps asset-income proxies;
- media market controls if the claim is “beyond public information channels.” State fixed effects are not a substitute for media-market overlap.

The current “tech employment share” variable especially needs attention. As reported, it looks miscoded. If it is not a share, relabel it. If it is, reconstruct it.

Fourth, **be more careful in interpreting magnitude**. A 0.89 percentage point effect on an average 2.5 percent decline is not implausibly large; if anything, it is modest. But the paper overstates precision and mechanism. Given the annual outcome, I would describe the estimate as evidence that socially connected counties experienced somewhat weaker deposit growth / larger net deposit declines over the panic year, not that private friendships directly caused a nationwide run. Also, the larger coefficients when dropping California or restricting to distance >500 km are not “strengthening” the interpretation when the standard errors are huge and the estimates are no longer precise. Those columns should be presented as suggestive robustness checks, nothing more.

Fifth, **revisit inference throughout**. With county-level observations and exposure measures that are spatially smooth, I would report:
- conventional heteroskedasticity-robust SEs,
- state-clustered SEs,
- wild-cluster bootstrap p-values,
- and a spatial correction or Conley-style SEs if feasible.

If significance survives across these, confidence in the result rises considerably. Right now the headline relies too heavily on one clustering choice.

Sixth, **use the placebo design more effectively**. The pre-trend tests are useful, but they need cleaning and better presentation. Fix the years, make them consistent with the data section, and present confidence intervals graphically. Also consider placebo “epicenters” beyond JPMorgan. JPM is not ideal because its branch network is diffuse and not a realistic comparison to SVB. Better placebos would be concentrated California-based banks that did not fail, or a permutation exercise assigning the SVB shares to other sets of counties with similar branch concentration. That would better test whether any geographically concentrated California banking footprint would generate similar coefficients.

Seventh, **the heterogeneity analysis should be recast or dropped unless sharpened**. Splitting on county total deposits is not a compelling test of the uninsured-deposit mechanism. Large county deposits reflect county size as much as vulnerability. A better heterogeneity cut would be based on local exposure to banks with high uninsured deposit shares, bank business model, or branch share of banks known to be run-prone in March 2023. As it stands, the interaction table does not add much.

Eighth, **clean up several presentation issues**. The paper is written crisply, but there are avoidable problems:
- The summary statistics table contains implausible values and should be audited.
- The sample says 50 states plus territories, but the note under the table says 55 states.
- The placebo table years are inconsistent.
- The paper says “private social networks amplify deposit flight independently of public information channels,” but there is no direct measure of public-information exposure in the regressions.
- The literature citations should be updated and harmonized; some appear as working papers with future dates.

Finally, **consider reframing the contribution more narrowly**. The current draft claims to identify a distinct private-network contagion channel. That is too strong for the present evidence. What the paper can more credibly show is: *counties more socially connected to SVB’s footprint experienced larger subsequent deposit declines, even after basic controls and placebo tests.* That is still interesting. If you then add the bank-level quarterly validation and richer controls, you can move closer to the stronger contagion interpretation.

Overall, I think the question is timely and the basic empirical pattern may well be real. But for an AER: Insights paper, the design must be tightened considerably. Right now the result is intriguing but not yet persuasive enough to support the paper’s causal and policy claims.
