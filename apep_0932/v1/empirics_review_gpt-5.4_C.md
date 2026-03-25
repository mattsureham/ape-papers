# V1 Empirics Check — openai/gpt-5.4 (Variant C)

**Model:** openai/gpt-5.4
**Variant:** C
**Date:** 2026-03-25T15:48:16.347862

---

## 1. **Idea Fidelity**

The paper pursues the broad spirit of the manifest, but it departs from several core elements in ways that matter for identification and interpretation.

First, the manifest’s central question was about **WPA/FERA work relief** and whether county work-relief intensity translated into different Black–White occupational mobility. The paper instead uses **total New Deal grants per capita**, explicitly including “WPA, FERA, CWA, and other programs.” That is a meaningful drift away from the original idea. If the mechanism is local gatekeeping in work relief jobs, the treatment should be work-relief spending, not omnibus New Deal spending.

Second, the manifest proposed a **DDD design with explicit pre/post structure** and validation using 1920–1930 trends. The implemented specification is really a **cross-sectional interaction in changes**:
\[
\Delta Y_i = \beta (Black_i \times ND_c)+\gamma_c+\delta_o+\phi_a+\varepsilon_i.
\]
That can be a useful specification, but it is not the same as a full DDD with stacked decades and race-by-period-by-treatment interactions. Since the paper leans heavily on DDD language, it should either implement that design directly or describe the current specification accurately.

Third, the manifest emphasized the novelty of using linked records to address composition. The paper does use linked data well, but it also introduces substantial **selection by conditioning on valid occupation in both 1930 and 1940**. That excludes many people with unemployment, nonparticipation, or unstable labor force attachment—the very margins on which relief may have mattered. This is not fatal, but it is a major departure from the original ambition of tracing broader individual consequences of work relief.

So: the paper is faithful to the motivating question, but not fully to the proposed treatment definition or empirical design.

## 2. **Summary**

This paper links 11 million men across the 1920, 1930, and 1940 censuses and asks whether New Deal spending had differential effects on Black versus White occupational mobility. The main result is that in higher-spending counties, Black men experienced slightly less occupational upgrading than comparable White men, with the negative differential concentrated in the South.

The paper’s contribution is potentially important: individual-level linked evidence on racial heterogeneity in Depression-era policy impacts would be valuable. But the current version does not yet deliver a clean causal result, and the magnitudes—while statistically precise—are small enough that identification and interpretation must be especially tight.

## 3. **Essential Points**

**1. The identification strategy is too weakly defended for the causal language used.**  
The core concern is that county New Deal spending is endogenous to local economic distress, political influence, agricultural structure, and racial institutions. County fixed effects absorb levels, but not the possibility that counties receiving more spending also had different **Black–White occupational dynamics** for reasons unrelated to work relief. Your own pre-trend estimate is the biggest problem here: the 1920–1930 coefficient is **-0.11**, more than half the 1930–1940 main effect in magnitude. “Not statistically significant” is not reassuring with millions of observations and only about 3,000 county clusters; the issue is economic magnitude, not the star count. As written, the paper overstates causality.

**2. The treatment variable and mechanism do not line up.**  
The paper is framed around WPA/FERA work relief and local gatekeeping in job assignment, but the treatment is **total New Deal spending per capita**. That includes programs with very different channels. If you want to claim evidence on “work relief,” you need to use work-relief spending specifically, or at minimum show that the results are driven by WPA/FERA rather than by AAA, PWA, roads, loans, etc. Right now the mechanism is asserted more strongly than the design supports.

**3. The main effect is economically small and the interpretation is at times inflated.**  
A coefficient of about **-0.18 OCCSCORE points per SD of spending** is tiny relative to the level gap in occupational status and small even relative to the dispersion of decadal changes. Small effects are perfectly publishable if credible and policy-relevant, but here the prose overreaches (“white men got the careers”). In Table 1, mean occupational change is **0.98 for Whites and 0.97 for Blacks**; the paper then states that 0.18 is 19% of the “unconditional Black–White gap in decadal occupational change,” which is simply incorrect if those summary statistics are right. This raises concern about basic magnitude interpretation. Tighten the arithmetic and calibrate the claims to the actual size of the estimates.

## 4. **Suggestions**

The paper is promising, and I think it can become much stronger with a sharper design and more disciplined interpretation.

**Start by aligning treatment, mechanism, and language.** If the claim is about work relief, use WPA/FERA spending if available. If only broader Fishback spending is available in the current draft, then rename the paper and claims accordingly: this is about **county New Deal intensity**, not specifically work relief. Better still, present both: total New Deal spending and work-relief-only spending. If the “gatekeeper” story is right, the work-relief measure should be the one that matters.

**Implement the DDD more transparently.** Right now the paper describes a triple difference but estimates a change regression with an interaction. I would strongly recommend stacking the 1920–1930 and 1930–1940 changes and estimating something like:
\[
Y_{it} = \beta (Black_i \times ND_c \times Post_t) + \text{lower-order terms} + \text{FE} + \varepsilon_{ict},
\]
or the equivalent at the change level with decade indicators. This would make the design match the narrative, allow a formal test of whether the post-period effect differs from the pre-period relationship, and force you to confront the sizable pre-trend directly.

**Relatedly, put the pre-trend front and center rather than burying it in robustness.** In this paper, the pre-trend is not a side note; it is central evidence about validity. Show an event-style figure with the two decade changes by race and spending bin. If the pre-period slope is already negative, then the burden is on you to show that the 1930–1940 slope becomes materially more negative beyond baseline trend. A table with separate estimates is not enough.

**Control more flexibly for baseline county characteristics interacted with race.** At a minimum, interact race with county-level 1930 covariates that plausibly shape occupational mobility: Black population share, farm share, manufacturing share, urbanization, literacy/education proxies if available, unemployment/distress proxies, and perhaps region-by-race effects. Since identification is coming from cross-county variation in the Black–White differential, you need to show the coefficient is not just picking up differential racial mobility in farm, low-income, or Jim Crow counties.

**The farm heterogeneity result needs more thought.** You find a positive effect among farm workers and near zero among non-farm workers, yet the aggregate effect is negative and you argue the mechanism is blocked occupational transitions. As stated, those pieces do not fit together well. Is the negative result coming from composition plus occupation fixed effects? From transitions out of agriculture? From Southern non-farm Black workers? You need a more systematic decomposition:
- by South × farm status,
- by baseline occupation rank,
- by transition margins (farm to non-farm, laborer to craftsman, etc.),
- and ideally by whether the person stays in the same county.

**Be much more careful about sample selection.** Requiring OCCSCORE \(>0\) in both 1930 and 1940 is likely consequential. It drops men with no coded occupation, unemployment, and possibly some of the hardest-hit workers. Since relief programs plausibly affected employment and labor-force attachment, conditioning on observed occupation in 1940 may induce selection. At minimum:
- report how many linked men are excluded by this restriction, by race and region;
- show results using broader outcomes such as any occupation observed in 1940, employment status, or an indicator for positive wage income;
- consider Lee-bound logic or inverse probability weighting if attrition into “valid occupation” is differential.

**The linked-sample representativeness issue deserves explicit treatment.** IPUMS MLP linkage is not random; match rates depend on name distinctiveness, migration, age misreporting, race, and literacy. This is especially important for Black men in the South. I would want to see:
- linkage rates by race, region, age, and urban status,
- reweighting to the underlying census population if available,
- and a comparison of linked versus full-count samples on observables.
Without that, it is hard to know whether the results reflect occupational mobility or linkability.

**Revisit the standard-error discussion.** County clustering is the natural default because treatment varies at the county level. But with only about 3,000 clusters and substantial within-state correlation in spending and institutions, I would like to see sensitivity to:
- clustering at the state level,
- wild cluster bootstrap p-values,
- and perhaps Conley-style spatial correlation if nearby counties share shocks.
I do not think the current SEs are obviously wrong, but given how small the estimated effects are, inference should be stress-tested.

**The women placebo is not persuasive in its current form.** You call women a placebo because WPA work relief was “overwhelmingly male,” yet the coefficient is strongly positive. That is not a placebo success; it is a signal that your treatment may be proxying for broader county trajectories or family-level income effects, or simply that the design is not isolating work-relief exposure. This result should be interpreted honestly. Either explain why female occupational mobility should respond through household channels, or drop the placebo framing.

**Clean up the outcome definitions and variable descriptions.** There is an inconsistency in the paper between OCCSCORE and SEI/Duncan coding. Table 1 notes say OCCSCORE is “the Duncan socioeconomic index,” which is incorrect. If variable definitions are muddled, readers will worry the coding is too. Also, log wage income in 1940 is tricky because many people have zero wage/salary income or self-employment/farm income. Explain precisely who is in that sample and what the treatment does to sample selection into positive wage income.

**Calibrate the magnitudes more credibly.** The paper needs a simple, transparent benchmark. For example:
- What is the mean and SD of 1930–1940 OCCSCORE change?
- What is the 90–10 difference in New Deal spending?
- How large is the implied Black–White mobility differential when moving from a low- to high-spending county?
Those conversions will help readers judge whether the effect is substantively meaningful. Right now the prose alternates between “economically meaningful” and very small standardized effects. Be consistent.

**Use the county fixed effects more effectively in exposition.** Since county FE imply identification comes from comparing Black and White men **within county**, say that clearly and repeatedly. But also admit the limitation: with one treatment variable per county, you are not observing differential racial treatment directly; you are inferring it from whether racial mobility gaps are steeper in higher-spending counties. That is a reduced-form interaction, not direct evidence on access, assignment, or within-program occupational ladders.

**The South/non-South split is the strongest result; build around it more carefully.** This is where the paper has the most historical coherence. I would recommend:
- estimating a full interacted model rather than split samples, so readers can test the South/non-South difference directly;
- showing county-level binscatters separately by region;
- and linking the heterogeneity to independent measures of Jim Crow institutions, Black disenfranchisement, or local administrative capacity.
That would make the “local discretion under racial hierarchy” mechanism much more convincing.

**Tone down the rhetorical flourishes in the abstract and conclusion.** “Black men got the paychecks; white men got the careers” is memorable, but not warranted by the current evidence. You do not observe WPA jobs, occupational assignments within the program, or long-run careers beyond 1940. AER: Insights papers benefit from sharp prose, but the rhetoric must not outrun the design.

In short: there is a publishable paper somewhere in this project, because the data are excellent and the question matters. But in its current form, the paper does not yet establish a clean causal effect of work relief on racial occupational mobility. The path forward is clear: use the right treatment, match the design to the DDD language, confront the pre-trend honestly, and moderate the claims to fit the very small magnitudes.
