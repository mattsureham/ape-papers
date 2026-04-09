# GPT-5.4 (R1) Review

**Role:** External referee review
**Model:** openai/gpt-5.4
**Paper:** paper.pdf
**Timestamp:** 2026-04-09T02:38:42.581816
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 20171 in / 5099 out
**Response SHA256:** 2f25c6584ac5b53a

---

This paper asks an important and policy-relevant question: did the 1924 Johnson-Reed Act improve native workers’ economic outcomes in the places most exposed to the resulting immigration cutback? The paper assembles a very large linked-census panel and presents an intuitively appealing comparison across counties with different pre-1924 concentrations of immigrants from heavily restricted origins. The main empirical findings are a null effect on occupational upgrading and a negative effect on transitions into homeownership, especially for young and urban native-born men.

The question is interesting, the data effort is substantial, and the paper is written around a clear substantive claim. However, in its current form I do not think the paper is publication-ready for a top general-interest journal or AEJ: Policy. The central problem is not the broad idea, but the identification strategy. The design as implemented does not credibly identify the causal effect of the 1924 Act, and some of the paper’s own results—especially the strong positive 1910–1920 “placebo” relationship—undermine the causal interpretation rather than support it. The paper is potentially salvageable, but only with substantial redesign of the empirical strategy and more careful calibration of claims.

## 1. Identification and empirical design

### Main concern: the current design is not a credible causal design for the paper’s headline claim

The core estimating equation in Section 4 regresses individual outcome changes from 1920 to 1930 on county-level 1920 exposure to restricted-origin immigrants, with state fixed effects, baseline occupation fixed effects, and individual controls. This is a cross-sectional exposure design in changes, not a convincing difference-in-differences design. It does not include county fixed effects, period fixed effects, county-specific trends, or any explicit post × exposure interaction in a multi-period panel. As a result, the identifying variation comes from permanent cross-county differences in immigrant settlement patterns, which are very likely correlated with differential economic trajectories.

The paper states that “the key assumption is that exposure is as-if-randomly assigned conditional on state fixed effects and initial occupation” (Section 4). That assumption is not credible here. Counties with high Southern/Eastern European settlement in 1920 were systematically different in urbanization, industrial structure, sectoral composition, housing demand, unionization, racial composition, and exposure to 1920s manufacturing booms and to the onset of the Great Depression. Table 1 itself shows large compositional differences across exposure quartiles.

### The 1910–1920 “placebo” is not reassuring; it is a serious identification failure

The paper’s own placebo evidence in Section 7 is the most damaging issue for identification. High-exposure counties had substantially faster native occupational upgrading before the 1924 Act, and the preferred pre-period coefficient is very large and positive (Table 5, col. 3: +17.9). This is direct evidence that exposure is correlated with differential trends. The paper argues that this “biases against” finding positive post-1924 effects and therefore makes the null “conservative.” I do not find that logic persuasive.

A nonparallel pre-trend does not validate post-period comparisons. It shows that exposure loads on underlying county trajectories. Once that is true, a null 1920–1930 coefficient cannot be interpreted cleanly as the effect of restriction. It could reflect:

- the end of a preexisting upward trend for reasons unrelated to immigration restriction,
- differential exposure of high-immigrant counties to 1920s sectoral slowdowns or the 1929 shock,
- mean reversion,
- ceiling effects not fully absorbed by occupation FE,
- or some mix of these.

The paper’s preferred interpretation—that quotas disrupted complementarity—is plausible, but the current design does not isolate that mechanism from these confounders.

### Treatment timing and coherence

The paper repeatedly describes the 1924 Act as a shock spanning the 1920–1930 intercensal period. But the outcome window is 1920 to 1930, while treatment begins in mid-1924 and the endpoint is affected by the 1929 downturn. That creates two timing problems:

1. **Pre-treatment years are included in the outcome change**: the “treated” decade contains four pre-policy years (1920–1924), diluting interpretation.
2. **Post-treatment endpoint includes the onset of the Great Depression**: high-exposure counties were disproportionately urban/industrial, so 1930 outcomes may reflect differential cyclical sensitivity rather than quota effects.

A stronger design would either:
- build county-by-decade or county-by-year panels using additional census waves and interact a predetermined exposure measure with a post-1924 indicator, or
- construct a shift-share prediction of local immigrant inflow losses due specifically to the quota schedule and relate that to outcomes in a panel with county and time fixed effects.

### The “first stage” is not enough, and it is not a first stage in an IV sense

Section 8 shows that counties with higher exposure experienced larger declines in restricted-origin foreign-born shares. This is useful descriptive evidence that the act mattered more in high-exposure places. But it does not solve the core problem: exposure is not exogenous. Also, the paper calls this a “first stage,” but the main analysis is not IV. If the authors want IV language, they should actually instrument realized immigrant decline with a predicted quota shock. Otherwise this is reduced-form validation, not a first stage.

### Threats to identification are under-addressed

Several important threats are either absent or treated too lightly:

- **Differential industrial trends**: high-exposure counties were concentrated in industrial Northeast/Midwest counties.
- **1920s housing and construction cycles**: particularly important given the homeownership result.
- **The 1929 crash**: likely correlated with exposure via urban/industrial composition.
- **Selective linkage into IPUMS MLP**: linked samples are not random; match rates vary by name commonness, mobility, literacy, ethnicity, and urbanization. This is especially relevant in immigrant-dense areas.
- **Selective survival and attrition** between 1920 and 1930.
- **County boundary and coding consistency** across linked records.
- **Endogenous local exposure measure**: 1920 immigrant shares reflect recent pre-1920 local growth dynamics.

These are first-order issues for a paper making strong causal claims.

## 2. Inference and statistical validity

### Main estimates report uncertainty, but inference is uneven

The main tables do report standard errors, which is necessary and good. The use of county-level treatment with county clustering is directionally appropriate. But several inference issues remain.

### County-level treatment on millions of individuals: precision may be overstated without stronger aggregate checks

Because treatment varies only at the county level, the effective variation is at the county level, not 10 million individual observations. The individual-level regressions may be fine if clustering is done correctly, but in a paper like this I would want:
- county-level collapsed regressions as a direct check,
- randomization-inference or permutation-based p-values at the county level,
- sensitivity to weighting schemes,
- and explicit reporting of the number of counties contributing identifying variation in each specification.

Otherwise the very large N risks encouraging overconfidence.

### First-stage table uses IID standard errors

Table 6 reports IID standard errors for county-level regressions. That is not adequate for an exposure-based county design with strong spatial and within-state correlation. The claim of “t > 80” should not be emphasized unless the inference is corrected. At minimum the county-level regressions should use heteroskedasticity-robust SEs, and likely clustering by state or spatially robust methods. The coefficient will almost surely remain large, but the current reported precision is not credible.

### Functional form and bounded outcomes

Several outcomes are binary (upgraded, moved, became owner, lost home, etc.) but estimated with linear probability models. That can be acceptable, but given some large coefficients and heterogeneous subsamples, the paper should show that marginal effects are robust to nonlinear models or at least that fitted values remain well behaved.

### Sample sizes are generally coherent, but some outcome constructions need clarification

The sample counts are broadly coherent across tables. But the homeownership outcome deserves much clearer definition. In Table 2, “became_owner” is estimated on the full sample, even though this is logically an entry margin. Coding everyone else—including 1920 owners who remain owners—as zero makes interpretation opaque. Table 4 properly decomposes renters and owners; the paper should treat the renter subsample specification as the primary entry result and stop foregrounding the full-sample version as if it were directly interpretable.

### No modern DiD issue, but the paper should not imply it has a valid DiD when it does not

The prompt mentions staggered DiD/TWFE concerns; those are not the main issue here because treatment is a one-time national shock interacted with baseline exposure. The problem is more basic: the paper does not establish the parallel-trends-type condition needed for exposure-based causal interpretation.

## 3. Robustness and alternative explanations

### Current robustness checks are not the ones the paper most needs

Leave-one-origin-out, state-only clustering, and non-mover restrictions are useful but secondary. They do not address the main threat: differential underlying county trends.

The most important missing robustness tests are:

1. **Controls for baseline county characteristics and trends**
   - 1920 manufacturing share, construction share, urbanization, farm share, baseline foreign-born share, population growth 1910–1920, occupational structure, homeownership rate, and region × baseline characteristics.
2. **Pre-trend diagnostics beyond one placebo**
   - Ideally 1900–1910 and 1910–1920, or a county-by-decade panel.
3. **County-level panel/event-study specification**
   - Outcome by county and decade, with county and decade FE, exposure × post interactions.
4. **Alternative endpoint sensitivity**
   - If possible, outcomes less contaminated by 1929–1930 macro collapse.
5. **Collapsing to county cells**
   - To show the findings are not artifacts of micro weighting.
6. **Reweighting for linked-sample representativeness**
   - Or at least documenting linkage rates by exposure quartile and covariates.

### Alternative explanations for homeownership are not ruled out

The homeownership finding is interesting but particularly vulnerable to omitted variables. High-exposure counties were urban and industrial; those counties also experienced distinctive housing-market dynamics in the 1920s and were likely hit differently by 1929. A negative effect on entry into homeownership could reflect:
- housing price appreciation in booming urban counties,
- land scarcity,
- credit market differences,
- cyclical employment shocks unrelated to immigration,
- or measurement changes in tenure.

The paper jumps quickly to a complementarity/housing-supply interpretation, but there is no direct evidence on construction activity, housing stock growth, rents, building permits, or local employment composition. As written, the mechanism is speculative.

### Mechanism claims are stronger than the evidence supports

Section 9 often writes as if complementarity is established. It is not. The evidence supports, at most, a suggestive pattern:
- pre-period positive association between immigrant presence and native upgrading,
- post-period null occupational effect,
- negative homeownership entry in exposed places.

That is consistent with complementarity, but also with many correlated-growth stories. Mechanisms need to be framed more cautiously unless the paper adds direct evidence.

### External validity is only partly acknowledged

The discussion does note that 1920s evidence need not generalize mechanically to the 21st century. That is good. But the paper should also acknowledge internal-validity limitations more honestly before drawing broader lessons.

## 4. Contribution and literature positioning

### Potential contribution is meaningful, but currently overstated relative to identification

There is genuine value in revisiting the economic incidence of a major historical immigration restriction using linked microdata. The paper could contribute to economic history, immigration, and political economy. But for a top journal, the paper needs a sharper and more credible empirical contribution than “exposure-based cross-county comparison with a positive placebo trend.”

### Literature coverage is decent on substance, thinner on methods

The domain literature is reasonably covered. But for the empirical strategy, the paper should engage more directly with the modern shift-share and exposure-design literature, especially because its design hinges on historical settlement patterns.

Concrete citations to add:

- **Goldsmith-Pinkham, Sorkin, and Swift (2020, Econometrica)** on Bartik/shift-share designs; important because the paper explicitly invokes “standard shift-share logic.”
- **Borusyak, Hull, and Jaravel (2022/2024, depending on cited version)** on quasi-experimental shift-share research designs; relevant for clarifying when such designs are credible.
- **Jaeger, Ruist, and Stuhler (2018, JEEA)** on shift-share instruments and dynamic adjustment concerns.
- Potentially **Adão, Kolesár, and Morales (2019, QJE)** on inference in shift-share designs, if the authors move in that direction.
- For historical immigration/local labor markets, additional engagement with papers using predicted immigrant inflows or quota-based designs would help if such a redesign is pursued.

### The paper should distinguish more clearly from existing historical immigration papers

The paper claims to study “the reverse experiment” of prior immigration-inflow papers. That is a nice framing device, but the authors need to show more clearly why their design identifies a restriction shock rather than simply comparing different types of counties after a national policy. The contribution is not yet sufficiently differentiated on empirical credibility.

## 5. Results interpretation and claim calibration

### The text overclaims relative to the design

Phrases such as:
- “The answer is no—and the truth is worse than a broken promise”
- “The restrictionist promise was a mirage”
- “The restriction imposed a cost”
- “restriction destroyed a productive complementarity”

all read as causal conclusions. With the current design, those statements are too strong. The paper can say the data do not show the promised occupational gains in more exposed counties, and that more exposed counties saw lower homeownership entry. It cannot yet cleanly attribute those patterns to the Act.

### The null on occupational upgrading is more credible than the negative mechanism story, but still not definitive

The occupational result is reasonably precisely estimated in the preferred specification, and the confidence interval seems to rule out large positive gains. That is useful. But because exposure is correlated with pre-trends, the paper should frame this as evidence against large labor-market improvements for natives in exposed counties, not as a definitive causal null for the Act.

### The homeownership result should be treated as provisional

This result is intriguing and likely the most novel part of the paper. But it is also the most vulnerable to omitted local housing-market and macroeconomic confounding. It should not be the basis for a strong headline without much more support.

### Some internal inconsistencies need tightening

- The full-sample “became owner” effect in Table 2 is statistically significant, but the “net ownership” effect in Table 4, col. 3 is not. These are conceptually related but interpreted differently in the text. The paper needs to clarify exactly which margin is economically meaningful.
- The ladder-up effect in the appendix is statistically significant and negative, which somewhat complicates the headline “null” occupational story. The paper mentions it but does not integrate it. Either explain why this discrete measure differs or present it more centrally as suggestive evidence of modest negative occupational effects.

## 6. Actionable revision requests

### 1. Must-fix issues before acceptance

#### 1. Redesign the empirical strategy to address differential trends
- **Issue:** The current 1920–1930 change-on-exposure regression does not identify the causal effect of the 1924 Act because exposure is strongly correlated with pre-existing trends.
- **Why it matters:** This is the central validity problem. Without solving it, the paper’s causal claims are not credible.
- **Concrete fix:** Recast the analysis as a multi-period panel. At minimum, stack 1910–1920 and 1920–1930 county-period outcomes and estimate an exposure × post1924 specification with county and period fixed effects. Better still, add earlier decades if possible. If feasible, construct a predicted local quota shock using pre-1920 national-origin settlement shares interacted with quota-induced national inflow changes, then use that in a panel framework.

#### 2. Stop treating the positive 1910–1920 result as a reassuring placebo
- **Issue:** The pre-period positive coefficient is currently interpreted as support for complementarity and as evidence that the main estimate is “conservative.”
- **Why it matters:** It is actually evidence that the identifying assumption fails.
- **Concrete fix:** Reframe the pre-period result as a pre-trend violation. Use it to motivate a stronger design rather than to defend the current one. If the authors believe the break after 1924 is causal, they must demonstrate that in an explicit comparative panel/event-study framework.

#### 3. Address confounding from industrial structure, urbanization, and the 1929 downturn
- **Issue:** High-exposure counties differ dramatically in characteristics that matter for both occupation and homeownership outcomes.
- **Why it matters:** These differences are plausible alternative explanations for both the null and negative findings.
- **Concrete fix:** Add rich baseline county controls and interactions, including 1920 industrial composition, urbanization, farm share, manufacturing/construction employment, population growth, and baseline homeownership. Show robustness to region-specific trends or state-specific decade shocks if using a panel.

#### 4. Correct the inference in county-level aggregate regressions
- **Issue:** Table 6 uses IID standard errors and overstates precision.
- **Why it matters:** Valid statistical inference is nonnegotiable.
- **Concrete fix:** Re-estimate county-level regressions with heteroskedasticity-robust and state-clustered SEs, and consider randomization inference/permutation tests for county-level treatment assignment. Report county-level collapsed versions of the main regressions.

#### 5. Recalibrate all causal language
- **Issue:** The paper currently writes as though it has established causal effects of the Act.
- **Why it matters:** Claim calibration must match design strength.
- **Concrete fix:** Replace definitive causal language with appropriately cautious phrasing unless and until the identification strategy is strengthened.

### 2. High-value improvements

#### 6. Make the homeownership analysis conceptually cleaner
- **Issue:** The full-sample “became owner” specification is hard to interpret.
- **Why it matters:** This is a central result.
- **Concrete fix:** Make renter-to-owner transitions among 1920 renters the primary homeownership outcome. Present owner-to-renter separately as a secondary margin. Clarify base rates and interpret coefficients relative to those margins.

#### 7. Add direct evidence on the proposed housing/complementarity mechanism
- **Issue:** The mechanism is speculative.
- **Why it matters:** The paper’s novelty rests heavily on this channel.
- **Concrete fix:** Bring in county-level evidence on housing stock growth, construction employment, building activity, rents, crowding, or manufacturing/construction labor demand. Even simple descriptive correlations by exposure and period would help.

#### 8. Document linked-sample representativeness and selection
- **Issue:** Linked census panels are subject to nonrandom match rates.
- **Why it matters:** If linkage varies by exposure or outcome determinants, estimates may be biased.
- **Concrete fix:** Report linkage rates by county exposure quartile and baseline characteristics; if available, use linkage weights or show robustness in more conservative linked subsamples.

#### 9. Show aggregate county-level results alongside individual-level estimates
- **Issue:** With county-level treatment, readers need to see the effective unit of variation.
- **Why it matters:** This helps assess leverage, weighting, and functional form.
- **Concrete fix:** Present county-level scatter/regressions for change in mean OCCSCORE and renter-to-owner transition rates, with and without baseline controls and weights.

#### 10. Engage the shift-share design literature directly
- **Issue:** The paper invokes shift-share logic without grappling with its assumptions.
- **Why it matters:** This is now standard in top-journal empirical work.
- **Concrete fix:** Add and discuss Goldsmith-Pinkham et al., Borusyak-Hull-Jaravel, Jaeger-Ruist-Stuhler, and if relevant Adão-Kolesár-Morales. Explain what variation identifies the estimates and what orthogonality condition is required.

### 3. Optional polish

#### 11. Clarify magnitudes more systematically
- **Issue:** Magnitude discussion is uneven across outcomes.
- **Why it matters:** Helps readers assess economic significance.
- **Concrete fix:** Report effect sizes relative to outcome means and SDs in the main text, not only the appendix.

#### 12. Integrate the appendix “ladder up” result into the main narrative
- **Issue:** This is one of the few statistically significant occupational findings.
- **Why it matters:** It may qualify the headline null.
- **Concrete fix:** Either move it into the main results or explain clearly why it is less informative than OCCSCORE/SEI.

## 7. Overall assessment

### Key strengths
- Important historical and contemporary policy question.
- Very large linked microdata sample.
- Clear motivation and intuitive empirical setup.
- Occupational null is potentially informative if credibly identified.
- Homeownership result is interesting and potentially novel.

### Critical weaknesses
- Identification strategy is not sufficient for the causal claims.
- Strong pre-period trend differences undermine the design.
- Homeownership interpretation is vulnerable to omitted local housing and macro confounders.
- County-level aggregate inference is not fully credible in Table 6.
- Mechanism and policy conclusions are stronger than the evidence warrants.

### Publishability after revision
In current form, I do not think the paper is close to acceptance at a top journal. But I do think there is a promising paper here if the authors substantially redesign the empirical strategy around a proper panel/exposure interaction framework, confront the pre-trend problem honestly, and moderate claims where identification remains limited. The data and question justify a serious revision, but it would be a major revision of substance, not a minor cleanup.

DECISION: REJECT AND RESUBMIT