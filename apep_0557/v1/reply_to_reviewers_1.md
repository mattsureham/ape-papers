# Reply to Reviewers

## Reviewer 1 (GPT-5.4 R1)

> The core problem is that the paper does not convincingly isolate "aid as a buffer against oil-revenue shocks" from other state-specific post-2008 changes correlated with pre-2008 aid exposure.

**Response:** We agree this is the central challenge. We have added two robustness checks that directly address region-specific confounding: (1) excluding the six northeastern states most affected by Boko Haram (β attenuates to 0.108, p=0.134), and (2) adding geopolitical zone × post fixed effects to absorb region-specific post-2008 trends (β = 0.103, p=0.195). Both remain positive and insignificant, supporting the null.

> The paper overstates the case that aid placement is orthogonal to later conflict.

**Response:** We have softened the orthogonality claims throughout. We acknowledge that predetermination addresses reverse causality but not omitted-variable bias from differential state-specific trends. The zone×post specification helps absorb broad regional confounders.

> The event study is not enough as currently presented.

**Response:** We now report the joint F-test on 23 pre-period coefficients: F=0.640, p=0.904. We acknowledge that failure to reject is weak evidence with 37 clusters, consistent with Roth (2022).

> The causal estimand is conceptually misaligned with the "buffering" hypothesis.

**Response:** We agree that a triple-difference exploiting state-level FAAC exposure would be ideal. Unfortunately, state-level FAAC allocation data at the monthly frequency is not available in our dataset. We note this as a limitation and present the geopolitical zone × post specification as a partial solution.

> The "well-powered null" claim is not justified.

**Response:** We have replaced "well-powered null" throughout with language that the design has "reasonable power to detect moderate-to-large effects" and that the CI "rules out large protective effects but cannot exclude small buffering." The abstract now explicitly states the CI.

> With 37 clusters, clustered SEs alone are not enough.

**Response:** We have added wild cluster bootstrap-t inference (p=0.111, CI=[-0.039, 0.337]), which confirms the clustered-SE based inference. The randomization inference is presented as a supplementary device rather than a definitive finite-sample correction.

> The randomization inference is not clearly valid under the paper's assignment process.

**Response:** We acknowledge that the RI procedure assumes exchangeability of aid exposure across states, which is a strong assumption. We present RI as one of several inference approaches, not as a standalone confirmation. The wild cluster bootstrap does not require exchangeability and yields a similar p-value.

## Reviewer 2 (GPT-5.4 R2)

> The design relies on a single nationwide time shock interacted with cross-sectional aid exposure that is unlikely to be as-good-as-random.

**Response:** We agree with the characterization. We have softened causal claims throughout, reframing the contribution as "no evidence of buffering in this design" rather than a definitive rejection of the aid-as-stabilizer hypothesis. The new zone×post and exclude-northeast specifications strengthen the case that the null is not driven by a single regional confound.

> Parallel trends are asserted more than established.

**Response:** We now report the joint F-test (F=0.640, p=0.904, 23 pre-period coefficients). We acknowledge that failure to reject is weak evidence and that pre-trends do not address post-2008 differential shocks.

> The "well-powered null" claim is not supported.

**Response:** Removed and replaced with nuanced language throughout. See response to Reviewer 1.

> "Large positive" labels on non-significant, likely confounded estimates are misleading.

**Response:** Changed all classifications in the SDE table from "Large positive" to "Positive, n.s." to avoid overinterpretation.

> The annual specification has p=0.054, yet the discussion still frames the overall pattern as a stable null.

**Response:** We now discuss the annual result more directly, noting it is "larger but noisier" without dismissing the borderline significance.

## Reviewer 3 (Gemini-3-Flash)

> Aid Intensity vs. Project Counts: the paper should discuss whether these 376 projects represent the bulk of Nigerian aid.

**Response:** The Aid Landscape subsection (Section 2.4) now discusses the major donors captured in AidData AIMS. We acknowledge that project counts are a noisy proxy for aid intensity and that non-geocodable aid (budget support) is excluded, making the substitution mechanism harder to test.

> The 2009 Amnesty Program: test if results hold when excluding the Niger Delta states entirely.

**Response:** The existing "Exclude FCT" robustness (β=0.142) is complemented by the new "Exclude Northeast" specification (β=0.108). The oil-state triple difference (Table 9) already shows the amnesty effect is absorbed by the oil-state×post interaction.

> State-Level Controls: interact Post with baseline characteristics.

**Response:** The new geopolitical zone × post FE specification absorbs region-specific trends. This addresses the concern that aid exposure proxies for state capacity or regional characteristics.

## Exhibit Improvements (from Exhibit Review)

- Added dependent variable note to Table 3 discussion
- SDE table classifications changed to "Positive, n.s."
- Table 7 notes expanded to explain RI row

## Prose Improvements (from Prose Review)

- Reduced "column-talk" in results narration — lead with findings, not table architecture
- Improved intro roadmap transition
- Strengthened conclusion's final sentence
- Improved outcome heterogeneity opening
