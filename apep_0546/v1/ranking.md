# Research Idea Ranking

**Generated:** 2026-03-09T01:51:37.915109
**Models:** GPT-5.4 (A), Gemini 3.1 Pro, GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | Gemini 3.1 Pro | GPT-5.4 (B) |
|------|------|------|------|
| Do Red Flag Laws Save Lives or Shift Dea... | PURSUE (70) | SKIP (35) | PURSUE (72) |
| Can Shorter Workweeks Save Fertility? So... | CONSIDER (64) | PURSUE (85) | CONSIDER (68) |
| The Local Fiscal Multiplier of Unconditi... | SKIP (55) | CONSIDER (55) | SKIP (52) |

---

## GPT-5.4 (A)

**Tokens:** 9850

### Rankings

**#1: Do Red Flag Laws Save Lives or Shift Deaths? Means Substitution in Suicide Prevention**
- **Score: 70/100**
- **Strengths:** This asks a sharp, policy-central question on a hard outcome: do ERPOs reduce total suicides or only reallocate method choice? The paper would also directly address a live credibility problem in the literature, since much of the existing multi-state evidence relies on now-questioned TWFE designs.
- **Concerns:** ERPO adoption is politically endogenous and often bundled with other post-Parkland gun reforms, so “law passed” may not isolate the causal effect of ERPOs. Also, take-up varies enormously across states, so the treatment may be too weak at the state-year level to detect changes in total suicides.
- **Novelty Assessment:** **Moderate.** ERPOs and firearm suicides are already studied, including state case studies and some multi-state work. But the specific means-substitution/total-suicide question, done credibly with modern staggered-adoption methods and updated post-2018 adopters, is still a meaningful gap.
- **Top-Journal Potential: Medium.** The topic has first-order stakes and a clear causal chain—ERPOs → firearm access → firearm suicides → total suicides—which editors like. But “state gun-law DiD” is a crowded genre, so this needs to do more than re-estimate a familiar question with a better estimator.
- **Identification Concerns:** The main threats are endogenous adoption timing, concurrent gun-policy bundles, and low/intensive-enforcement heterogeneity that makes statute adoption a noisy proxy for actual treatment. A convincing version needs strong take-up/intensity evidence and careful handling of co-occurring laws.
- **Recommendation:** **PURSUE (conditional on: measuring ERPO petition/use intensity; using the longest feasible pre-period and ideally monthly data; explicitly addressing concurrent gun-law changes and power for total-suicide effects)**

**#2: Can Shorter Workweeks Save Fertility? South Korea's 52-Hour Reform**
- **Score: 64/100**
- **Strengths:** This is the most exciting question in the batch substantively: a major labor regulation in the world’s lowest-fertility country, with a plausible mechanism from hours constraints to marriage and childbearing. The phased rollout by firm size gives a real quasi-experimental backbone rather than pure before/after speculation.
- **Concerns:** The design is badly exposed to COVID, especially for the 2020 and 2021 waves, and fertility is slow-moving enough that the cleanest post-treatment window is short. KLIPS may also be too small for credible birth-event analysis once you split by firm size, age, sex, and marital status.
- **Novelty Assessment:** **High on the exact policy, moderate on the broader question.** There is a broad work-hours/family-formation literature, but I am not aware of a well-identified paper on this reform’s effects on marriage/fertility outcomes specifically.
- **Top-Journal Potential: High.** If executed cleanly, this is exactly the sort of first-order, mechanism-rich policy paper that could travel: labor regulation → time allocation → family formation/fertility. The problem is not the question; it is whether the current design can credibly answer it.
- **Identification Concerns:** Firm-size groups likely have different underlying trends, workers may sort across firms, and the later treatment waves coincide with pandemic shocks that almost certainly vary by firm size. Without a strategy that neutralizes those confounds, the causal interpretation will be fragile.
- **Recommendation:** **CONSIDER**  
  *(I would upgrade this to PURSUE if you can get larger administrative microdata on births/marriages or build a design centered on the 300+ firm wave with a convincing pre-COVID window.)*

**#3: The Local Fiscal Multiplier of Unconditional Cash Transfers: Poland's Family 500+**
- **Score: 55/100**
- **Strengths:** The policy is large, important, and the two-phase structure is genuinely useful: targeted first, then universal. The local panel is feasible and could generate informative descriptive evidence on geographic incidence.
- **Concerns:** The identifying variation is weak for the ambition of the claims. Baseline shares of families with children are not plausibly exogenous to later trends in births, marriages, unemployment, or business formation, so this risks looking like a standard but vulnerable shift-share exercise.
- **Novelty Assessment:** **Moderate-low.** The local-multiplier angle within Poland seems less studied, but Family 500+ itself is heavily researched, and local economic effects of transfers are a mature literature. The contribution is incremental unless the design is much cleaner than it currently appears.
- **Top-Journal Potential: Low.** As written, this reads like a competent application rather than a paper that would change how the field thinks about transfers or local multipliers. Without stronger identification or richer spending/firm-level data, it is unlikely to clear a top-journal bar.
- **Identification Concerns:** This is essentially a national shock interacted with demographic exposure, and that exposure is itself correlated with many outcome trends. For births and marriages, the exposure measure is especially close to the outcome-generating population, which makes causal interpretation even harder.
- **Recommendation:** **SKIP**

### Summary

This is a mixed but useful batch: one solid “pursue,” one high-upside idea that needs a serious design upgrade, and one that is likely too weakly identified for the intended claims. I would pursue **Idea 1** first because it best combines feasible data, hard outcomes, and a live unresolved policy question; **Idea 2** is the more glamorous question, but only if you can solve the COVID and sample-size problems.

---

## Gemini 3.1 Pro

**Tokens:** 8191

Here is my evaluation of the research proposals, ranked from most to least promising, applying the editorial patterns and rigorous identification standards expected at top economics journals.

### Rankings

**#1: Can Shorter Workweeks Save Fertility? South Korea's 52-Hour Reform**
- **Score**: 85/100
- **Strengths**: This perfectly executes the "first-order stakes + one sharp channel" winning formula by linking a massive demographic crisis (Korea's world-lowest fertility) to a highly legible, economically meaningful mechanism (work hours). The staggered rollout by firm size provides a clean, built-in identification strategy with clear placebo groups.
- **Concerns**: The January 2020 wave perfectly coincides with the onset of the COVID-19 pandemic, which drastically altered both work arrangements and fertility decisions. Additionally, there is a risk of endogenous sorting, where workers switch firms or firms artificially split to avoid the regulatory thresholds.
- **Novelty Assessment**: High. While the 52-hour rule has been studied for standard labor outcomes (wages, employment), causally linking it to fertility via the staggered firm-size rollout is a novel and highly impactful angle.
- **Top-Journal Potential**: High. A top-5 journal would find this very exciting. It addresses a globally relevant policy question with hard outcomes (births) and a sharp quasi-experiment, moving beyond descriptive fertility panic into actionable causal evidence.
- **Identification Concerns**: The primary threat is the COVID-19 shock confounding the second treatment wave. A secondary threat is firm-size manipulation (bunching just below 50 or 300 employees) or worker sorting, which could violate the assumption of exogenous treatment assignment.
- **Recommendation**: PURSUE (conditional on: convincingly isolating the COVID-19 shock; proving no firm-size manipulation around the regulatory thresholds)

**#2: The Local Fiscal Multiplier of Unconditional Cash Transfers: Poland's Family 500+**
- **Score**: 55/100
- **Strengths**: Leverages a massive, salient policy shock (~2% of GDP) and uses a clever two-phase design to compare the local economic impacts of targeted versus universal transfers.
- **Concerns**: Powiats with high baseline shares of families with multiple children are likely systematically different (e.g., more rural, lower income) from those with fewer children, threatening the parallel trends assumption.
- **Novelty Assessment**: Medium. The Family 500+ policy has been heavily studied at the micro level. Moving to local multipliers is a nice twist, but the "local fiscal multiplier" literature is quite mature and crowded.
- **Top-Journal Potential**: Medium to Low. This risks falling into the "technically competent but not exciting" category. To hit a top journal, it would need to reveal something fundamentally surprising about universal vs. targeted transfers, rather than just estimating another standard local multiplier.
- **Identification Concerns**: The continuous treatment intensity relies entirely on pre-existing demographic shares, which almost certainly correlate with unobserved local economic trajectories, making the Bartik-style exogeneity assumption highly vulnerable.
- **Recommendation**: CONSIDER

**#3: Do Red Flag Laws Save Lives or Shift Deaths? Means Substitution in Suicide Prevention**
- **Score**: 35/100
- **Strengths**: Asks an important conceptual question (means substitution) and proposes using modern, robust staggered DiD estimators rather than the flawed TWFE models that plague the older gun policy literature.
- **Concerns**: The "bite" of ERPO laws is microscopic (a few dozen to a few hundred orders per state per year) compared to the state population, making it mathematically impossible to detect an effect on aggregate state-level suicide rates.
- **Novelty Assessment**: Low. Means substitution is a classic question, and state-level gun law DiDs are an incredibly saturated, exhausted genre. While the specific CS-DiD application to ERPOs might be technically new, the approach is tired.
- **Top-Journal Potential**: Low. As noted in the editorial patterns, "near-zero-take-up policies" evaluated on aggregate data are a fatal flaw. This design will inevitably yield a noisy null, which editors will correctly attribute to a lack of statistical power rather than a true zero effect.
- **Identification Concerns**: Beyond the severe power/MDE issue, state-level parallel trends for suicide rates are notoriously difficult to defend, as states adopting ERPOs are often on fundamentally different political, social, and healthcare trajectories than non-adopting states.
- **Recommendation**: SKIP

### Summary

This batch presents a clear hierarchy: one standout idea, one competent but unexceptional idea, and one fundamentally flawed idea. I strongly recommend pursuing the South Korean fertility paper first, as it combines a first-order global policy crisis with a sharp identification strategy, giving it genuine top-5 potential if the COVID-19 confounder can be managed. The Poland multiplier paper is a viable backup for a solid field journal, while the Red Flag law paper should be abandoned due to the insurmountable statistical power issues inherent in using state-level aggregate designs for micro-targeted policies.

---

## GPT-5.4 (B)

**Tokens:** 8624

### Rankings

**#1: Do Red Flag Laws Save Lives or Shift Deaths? Means Substitution in Suicide Prevention**
- **Score: 72/100**
- **Strengths:** This asks a sharp, policy-relevant question on a hard outcome that matters: do ERPOs reduce total suicides or just firearm suicides? The proposed contribution is strongest when framed as resolving confusion in an existing literature that used weaker TWFE designs.
- **Concerns:** This is not a blank-slate topic—ERPOs and suicide have already been studied, so the paper must clearly show why prior estimates are misleading and why total suicide is the right object. Identification is also not pristine: adoption is politically endogenous, many laws bunch after Parkland, and homicide effects will likely be underpowered at the state-year level.
- **Novelty Assessment:** **Moderately novel.** ERPO effects on firearm suicide are already studied; the more novel piece is a credible multi-state test of **means substitution using total suicide** with modern staggered-DiD methods.
- **Top-Journal Potential: Medium.** Mortality plus a clean substitution mechanism is the right kind of question, and “firearm suicide falls but total suicide does/doesn’t” is a publishable fact that could matter. But state gun-law DiD papers are common, so this needs to be framed as settling a live empirical dispute, not as “another gun-policy ATE.”
- **Identification Concerns:** The main threat is endogenous adoption: states may pass ERPOs in response to shootings, mental-health politics, or pre-existing suicide trends. The design also leans heavily on a small number of aggregate units, and the late-adopting states contribute little post-treatment time.
- **Recommendation:** **PURSUE (conditional on: convincing pre-trend evidence; enforcement/take-up data to separate paper laws from active use; a clear power argument for total suicides and not just firearm suicides)**

**#2: Can Shorter Workweeks Save Fertility? South Korea's 52-Hour Reform**
- **Score: 68/100**
- **Strengths:** Very high-stakes question in a first-order policy setting, and the phased rollout by firm size gives the project a more credible design than most fertility papers. If the paper can show a strong first stage on hours and a meaningful effect on marriage or births, the narrative is compelling: labor regulation → time constraints → family formation.
- **Concerns:** COVID is a serious problem here, especially because two rollout waves coincide almost exactly with the pandemic period. Fertility is also a slow-moving outcome, and firm-size groups differ a lot in wages, career paths, and baseline marriage/fertility trajectories, so parallel trends are not automatic.
- **Novelty Assessment:** **Fairly novel.** There is a large literature on work hours and fertility, but the exact reform-to-fertility link in Korea appears relatively understudied.
- **Top-Journal Potential: Medium.** The upside is real because Korea’s fertility collapse is globally salient and policy-relevant. But absent a very clean design and strong first stage, this could read as an interesting country-specific application rather than a field-shifting paper.
- **Identification Concerns:** Firm-size-based rollout creates obvious comparability issues, and selective sorting around childbirth or employment could bias estimates. The pandemic overlap is the biggest threat: it affects both working hours and fertility, and it arrives right in the treatment window.
- **Recommendation:** **CONSIDER**  
  *(I would upgrade to PURSUE if the team can show: a large hours first stage; enough births/marriages for power; and a design that isolates pre-COVID effects or handles COVID credibly.)*

**#3: The Local Fiscal Multiplier of Unconditional Cash Transfers: Poland's Family 500+**
- **Score: 52/100**
- **Strengths:** The policy is large, consequential, and nationally important, and the administrative local data are feasible. The two-phase reform does add some structure and could help distinguish targeted from universal transfers.
- **Concerns:** The identification strategy is the weak link. A Bartik-style intensity design based on pre-program child shares is exactly the kind of setup where treatment intensity is entangled with deep local demographic and economic trends, making causal claims easy to attack.
- **Novelty Assessment:** **Somewhat novel, but not very.** Poland’s 500+ program has already been heavily studied, and local transfer multipliers are a well-developed literature even if this exact application is new.
- **Top-Journal Potential: Low.** This risks reading as a competent but standard shift-share application with diffuse outcomes rather than one sharp, surprising result. It is more likely to land as a solid field-journal paper if identification is strengthened, not as a top-5 contender.
- **Identification Concerns:** Baseline family structure is not plausibly exogenous to later trends in births, marriages, unemployment, or business formation. Phase II is also close to universal, so the remaining cross-sectional variation may mostly proxy for regional demography rather than treatment exposure.
- **Recommendation:** **SKIP**  
  *(Unless the team can find a much sharper source of quasi-experimental variation—e.g., a discontinuity, administrative eligibility kink, or border-based design.)*

### Summary

This is a decent batch, but only one idea clearly rises above “competent and feasible.” I would pursue the **ERPO/means-substitution** project first because it combines high policy relevance with a sharp mechanism and a plausible chance to clean up a messy literature. The **South Korea workweek-fertility** idea has high upside but also substantial execution risk, mainly from COVID and fertility timing; the **Poland 500+ multiplier** idea is the least convincing because the identification strategy is too vulnerable.

