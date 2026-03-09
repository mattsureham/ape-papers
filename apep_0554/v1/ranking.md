# Research Idea Ranking

**Generated:** 2026-03-09T11:41:09.913830
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Can a Child Allowance Buy a Job? Poland'... | PURSUE (68) | — | SKIP (54) |
| Shorter Hours, More Babies? South Korea'... | CONSIDER (64) | — | PURSUE (72) |
| Billions to the Village: Indonesia's Dan... | SKIP (52) | — | CONSIDER (63) |
| Idea 3: Shorter Hours, More Babies? Sout... | — | PURSUE (85) | — |
| Idea 2: Can a Child Allowance Buy a Job?... | — | CONSIDER (58) | — |
| Idea 1: Billions to the Village: Indones... | — | SKIP (35) | — |

---

## GPT-5.4 (A)

**Tokens:** 8518

### Rankings

**#1: Can a Child Allowance Buy a Job? Poland's Family 500+ and the Local Fiscal Multiplier**
- **Score: 68/100**
- **Strengths:** This asks a big, policy-relevant question about whether a massive child transfer program generated local demand and employment spillovers, not just household-level effects. The program is economically large, the administrative geography is rich, and the 2019 expansion gives a useful second shock.
- **Concerns:** The core treatment variation comes from pre-program family composition, which is not obviously exogenous and may proxy for religiosity, urbanization, labor-market structure, and fertility trends. If the paper spreads across too many outcomes, it risks feeling like a competent local-effects exercise rather than a sharp mechanism paper.
- **Novelty Assessment:** **Moderate.** Family 500+ itself is already heavily studied, especially for labor supply, fertility, poverty, and politics. The local fiscal multiplier angle is less crowded and is the main reason this idea stands out.
- **Top-Journal Potential:** **Medium.** A top field journal could be interested if the paper is framed tightly as cash transfers → local demand → jobs/business formation, with one or two core outcomes. Top-5 potential is weaker because Bartik-style exposure based on family composition is not a design that editors will automatically trust.
- **Identification Concerns:** The exposure measure may capture persistent local demographic and economic differences rather than plausibly exogenous transfer intensity. With only national policy shocks, credibility will hinge on strong balance tests, trend stability, and a convincing use of the 2019 expansion as validation rather than just another event.
- **Recommendation:** **PURSUE (conditional on: centering the paper on one demand-side mechanism; defending the shift-share design aggressively; using the 2019 expansion as a built-in validation test)**

---

**#2: Shorter Hours, More Babies? South Korea's 52-Hour Workweek and the Fertility Crisis**
- **Score: 64/100**
- **Strengths:** This is a first-order question in a country where fertility is an existential policy issue, and the underlying mechanism is intuitive and important: work-hour regulation may affect time, stress, earnings, marriage, and fertility. The staggered rollout by firm size gives the project a potentially credible quasi-experimental backbone.
- **Concerns:** Fertility and marriage are low-frequency outcomes, so KLIPS may be underpowered once you narrow to relevant workers and treatment waves. The 2020 and 2021 rollout waves overlap with COVID, which is a major confound for exactly these outcomes.
- **Novelty Assessment:** **Moderately high.** There is broader literature on working time and family formation, and some work on Korea's hours reform for labor outcomes, but the causal fertility angle appears much less saturated.
- **Top-Journal Potential:** **Medium.** The question is highly salient and could travel well if the paper shows a clear first stage on hours and a disciplined mechanism story. But without a very credible design, it may read as an interesting policy evaluation rather than a field-shaping result.
- **Identification Concerns:** Firm-size groups differ systematically in wages, industries, and worker composition, so simple staggered DiD is not enough. Worker mobility across firm sizes, partial compliance, and pandemic-era rollout make it easy for treatment timing to be confounded with broader shocks.
- **Recommendation:** **CONSIDER (best if redesigned around the 2018 large-firm wave, with strong evidence on hours reductions and a serious power calculation for fertility/marriage outcomes)**

---

**#3: Billions to the Village: Indonesia's Dana Desa and the Infrastructure-Health Nexus**
- **Score: 52/100**
- **Strengths:** The policy is huge, nationally important, and plausibly underexplored in terms of health effects; infant mortality is a strong, legible outcome if the design were convincing. The combination of survey health data and satellite-based economic proxies is ambitious and policy-relevant.
- **Concerns:** The proposed treatment intensity is basically rurality: provinces with more Desa are structurally different from provinces with more Kelurahan in many ways that matter for health trends. One post-treatment DHS wave and a small number of province clusters make the causal claim fragile, and the village-level night-lights comparison is also fundamentally rural-versus-urban.
- **Novelty Assessment:** **Moderate.** Dana Desa is not an untouched policy—there is already a growing literature on governance, infrastructure, and local development—but the health angle is less studied. Still, novelty alone does not rescue this design.
- **Top-Journal Potential:** **Low.** The stakes are large and mortality is attractive, but top journals will not be persuaded by a design that leans so heavily on cross-province rural share differences under a nationwide reform. In current form this looks more like a suggestive development paper than a top-journal causal design.
- **Identification Concerns:** Treatment intensity is highly correlated with baseline poverty, remoteness, and preexisting health infrastructure, so parallel trends are very hard to believe. The single post period and province-level aggregation sharply limit inference, while village-level VIIRS comparisons inherit the same noncomparability problem.
- **Recommendation:** **SKIP (unless you can find a sharper allocation-rule discontinuity or formula-based design, and preferably move to micro-level administrative or village census data rather than province-level DHS aggregates)**

---

### Summary

This is a decent batch, but none of the three is a slam-dunk top-journal idea in its current form. I would **pursue Idea 2 first**, because it has the best combination of scale, feasible data, and a potentially sharp mechanism, and **keep Idea 3 as a secondary option** if the team can show a strong first stage and survive the COVID timing problem. **Idea 1 is the weakest as currently designed** because the identification is too close to comparing rural and urban places under a nationwide policy.

---

## Gemini 3.1 Pro

**Tokens:** 7217

Here is my evaluation of the research proposals, ranked from most to least promising, applying the criteria and editorial patterns provided.

### Rankings

**#1: Idea 3: Shorter Hours, More Babies? South Korea's 52-Hour Workweek and the Fertility Crisis**
- **Score**: 85/100
- **Strengths**: This addresses a massive, first-order policy crisis (South Korea's demographic collapse) with a very sharp, theoretically ambiguous mechanism (time vs. income). The staggered firm-size rollout provides a highly credible identification strategy with built-in placebos.
- **Concerns**: Statistical power is a severe threat; with South Korea's Total Fertility Rate below 0.8, a panel of 11,670 households will observe very few actual births per year, making it mathematically difficult to detect anything but massive effect sizes. 
- **Novelty Assessment**: High. While the 52-hour workweek has been studied for standard labor market outcomes, linking it causally to the fertility crisis using firm-size cutoffs is novel, timely, and highly relevant to global policy debates.
- **Top-Journal Potential**: High. This perfectly fits the "first-order stakes + one sharp channel" archetype from the editorial appendix. If it finds a credible effect (or a precisely estimated, opponent-killing null), it speaks to a global debate on work culture and demographic collapse.
- **Identification Concerns**: Workers might sort across firm-size thresholds to avoid or benefit from the regulation. You must use baseline (pre-2018) firm size to construct an Intent-to-Treat (ITT) design to avoid endogenous sorting.
- **Recommendation**: PURSUE (conditional on: power calculations proving the KLIPS panel has enough baseline births to detect a reasonable effect size; if not, pivot to administrative data).

**#2: Idea 2: Can a Child Allowance Buy a Job? Poland's Family 500+ and the Local Fiscal Multiplier**
- **Score**: 58/100
- **Strengths**: Cleverly repurposes a well-known social policy to answer a macroeconomic question (local fiscal multipliers) using highly granular, feasible administrative data. 
- **Concerns**: Areas with high baseline family sizes (e.g., rural, poorer, traditional) likely have fundamentally different secular trends in business formation and unemployment than low-fertility urban centers, threatening the shift-share exclusion restriction.
- **Novelty Assessment**: Medium. The Family 500+ policy is heavily studied for labor supply, but the local fiscal multiplier angle is a fresh, albeit somewhat niche, pivot.
- **Top-Journal Potential**: Medium-Low. While it yields economically legible outcomes (firm formation, unemployment), it risks reading as a "technically competent but not exciting" ATE paper. To win at a top-5, it would need to reveal a surprising mechanism about how child allowances specifically circulate in local economies compared to other fiscal transfers.
- **Identification Concerns**: The Bartik instrument relies on baseline family composition, which is highly correlated with local economic trajectories. You will need rigorous parallel pre-trend testing and likely need to control for local demographic-specific time trends.
- **Recommendation**: CONSIDER

**#3: Idea 1: Billions to the Village: Indonesia's Dana Desa and the Infrastructure-Health Nexus**
- **Score**: 35/100
- **Strengths**: Examines a massive, expensive, and under-evaluated policy with clear welfare implications (infant mortality).
- **Concerns**: The identification strategies are fatally flawed; comparing rural (Desa) to urban (Kelurahan) areas violates parallel trends, and a province-level DiD with N=33 is severely underpowered and highly aggregated.
- **Novelty Assessment**: Medium. Dana Desa is under-studied in top journals, but the proposed approach is a diffuse "policy affects many things" story rather than a sharp causal test.
- **Top-Journal Potential**: Low. The editorial appendix explicitly warns against "diffuse 'policy affects many things' stories" and "boundary confounding (urban-suburban designs)." Top journals will immediately reject the rural vs. urban comparison as confounded by differential development trends.
- **Identification Concerns**: Desa (rural) and Kelurahan (urban) are on completely different economic and health trajectories in a rapidly developing country, making Kelurahan an invalid control group. Furthermore, province-level Desa share is highly endogenous to regional geography (e.g., Java vs. Papua).
- **Recommendation**: SKIP

### Summary

This batch ranges from a highly promising, top-tier idea to a fundamentally flawed one. **Idea 3 (South Korea)** is the clear winner, offering a sharp design on a globally relevant crisis, provided the researchers can prove their data has sufficient statistical power to detect rare events like births. **Idea 2 (Poland)** is a solid, competent project that could land in a good field journal (like AEJ: Policy) but lacks the narrative punch for a top-5. **Idea 1 (Indonesia)** should be discarded; despite the importance of the policy, the proposed urban-vs-rural identification strategy is a classic example of boundary confounding and will not survive peer review.

---

## GPT-5.4 (B)

**Tokens:** 7216

### Rankings

**#1: Shorter Hours, More Babies? South Korea's 52-Hour Workweek and the Fertility Crisis**
- **Score:** 72/100
- **Strengths:** This asks a first-order policy question in a globally salient setting: can work-time regulation move marriage and fertility in a low-fertility economy? The staggered rollout by firm-size thresholds gives a more credible source of variation than the other proposals, and the sign is genuinely ambiguous, which raises upside.
- **Concerns:** KLIPS may simply be too small for precise fertility effects, especially once you split by firm size and treatment wave. The 2020/2021 phases overlap with COVID, and firms/workers on different sides of size thresholds may differ in ways that complicate DiD.
- **Novelty Assessment:** The broad topic—working hours and family formation—has been studied, but this exact reform-to-fertility question in Korea does not appear saturated. The novelty is real, though not “entirely untouched.”
- **Top-Journal Potential:** **Medium.** The stakes are top-journal sized, and the causal chain is easy to tell: hours cap → time/income/stress → marriage/fertility. But a top-5 would likely want stronger outcome data and a sharper design around the firm-size implementation margin than a survey-panel staggered DiD alone.
- **Identification Concerns:** The key threats are non-comparability across firm-size groups, threshold manipulation, and COVID confounding for later phases. A convincing paper needs a strong first stage on actual hours, careful cohort/event-time design, and ideally a near-threshold or triple-difference validation.
- **Recommendation:** **PURSUE (conditional on: showing a strong first stage on hours; addressing COVID explicitly; and, if possible, adding administrative birth/marriage data or a tighter threshold-based design)**

**#2: Billions to the Village: Indonesia's Dana Desa and the Infrastructure-Health Nexus**
- **Score:** 63/100
- **Strengths:** The policy is huge, consequential, and relatively underexploited in the top-journal literature. Mortality, facility delivery, diarrhea, electrification, and nighttime lights are all policy-legible outcomes, and the idea has a plausible mechanism chain through infrastructure.
- **Concerns:** The core treatment-intensity measure is basically province rurality, which makes identification much weaker than it first appears. There is only one post-treatment DHS wave for the health outcomes, and the health effects of infrastructure may not fully materialize by 2017.
- **Novelty Assessment:** Dana Desa is not unstudied, but rigorous causal work on its health consequences is much thinner than work on village transfers, decentralization, or Indonesian local development more broadly. So novelty is decent, though not exceptional.
- **Top-Journal Potential:** **Medium-Low.** The policy scale and mortality angle help a lot, but the current design risks reading like a competent rural-vs-urban intensity DiD rather than a “killer” identification strategy. This looks more like strong field-journal territory unless the design is sharpened substantially.
- **Identification Concerns:** Provinces with high Desa shares are systematically more rural and likely on different underlying health trajectories; with only ~33 provinces and one post period, inference is fragile. The village-level Desa vs. Kelurahan nighttime-lights comparison also risks severe control-group incomparability.
- **Recommendation:** **CONSIDER (best if redesigned around a sharper source of variation—e.g., allocation-formula discontinuities, border comparisons, or more granular health data)**

**#3: Can a Child Allowance Buy a Job? Poland's Family 500+ and the Local Fiscal Multiplier**
- **Score:** 54/100
- **Strengths:** The program is large, salient, and administratively important, and the local general-equilibrium angle is more interesting than yet another reduced-form labor-supply paper. The administrative data coverage is strong, and the 2016 and 2019 reforms give multiple shocks.
- **Concerns:** The Bartik-style exposure measure based on baseline family composition is the main problem: places with more children are different in many ways that directly predict unemployment, firm formation, marriage, and births. This is exactly the kind of design that will attract identification skepticism and “seen this before” reactions.
- **Novelty Assessment:** Family 500+ itself has already been studied heavily, especially for labor supply, fertility, poverty, and politics. The local multiplier framing is less common, but it enters a crowded transfer-shock/Bartik literature rather than opening a genuinely new policy question.
- **Top-Journal Potential:** **Low.** “Child allowance → local business registrations/unemployment” is not as sharp or compelling a causal chain as the other ideas, and the design will feel derivative unless there is unusually clean spending exposure and a much stronger exclusion argument.
- **Identification Concerns:** Baseline child composition is not plausibly exogenous to later local economic trends, and some outcomes are mechanically tied to family structure. The 2019 extension also makes treatment intensity partly reflect endogenous fertility composition, worsening interpretation.
- **Recommendation:** **SKIP**

### Summary

This is a decent batch, but only one idea clearly merits active development. I would pursue the South Korea work-hours project first, because it has the strongest combination of stakes, novelty, and a potentially publishable causal design if the data can be strengthened. The Indonesia idea is worth revising, but only with a sharper identification strategy; the Poland idea is the easiest to execute technically and the least likely to persuade top referees.

