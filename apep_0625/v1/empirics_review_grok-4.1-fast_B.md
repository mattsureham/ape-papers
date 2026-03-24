# V1 Empirics Check — x-ai/grok-4.1-fast (Variant B)

**Model:** x-ai/grok-4.1-fast
**Variant:** B
**Date:** 2026-03-13T11:14:50.280567

---

### 1. Idea Fidelity
The paper largely pursues the original idea manifest but deviates in key execution details. It retains the core Callaway-Sant'Anna (CS) staggered DiD design with 16 treated states (7 cohorts) and ~34 never-treated controls, QWI data from Azure paths, focus on new-hire earnings (EarnHirNS) across 20 NAICS sectors, industry heterogeneity testing (high- vs. low-gap industries), and Doleac-Hansen-style race tests (Black-White gaps in earnings/hiring). However, it misses or simplifies several elements: (i) aggregation to state-industry-quarter level (41k obs) instead of county-level triple differences (promised 4.9M obs with sex-by-age/education/race within county-industry-quarter); (ii) limited analysis of hiring rates/separations/turnover (only briefly in robustness, not central); (iii) no sex-by-education breakdowns or firm job creation; (iv) incomplete robustness (no border county pairs, Bacon decomposition only mentioned as infeasible, no randomization inference); and (v) industry DDD specification referenced but not fully reported (Table 4 shows NA coefficients). These changes make the design coarser and less novel than promised, shifting from granular demographic/industry flows to a state-level gender gap primarily.

### 2. Summary
This paper estimates the effects of staggered state salary history bans (2017–2023) on the gender gap in new-hire earnings using CS staggered DiD on QWI state-industry-quarter data, finding a 2.3 log point narrowing (p<0.01, ~8.5% of the pre-ban gap), growing to 4.1 log points after three years. Effects are strongest in healthcare and professional services, with no evidence of statistical discrimination against Black workers (earnings/hiring gaps unchanged or narrowing). It highlights how TWFE masks the effect due to heterogeneous treatment timing, while CS recovers it cleanly, contributing novel administrative evidence on industry mechanisms absent in prior survey/tax/audit studies.

### 3. Essential Points
1. **Revert to county-level analysis for stronger identification**: The manifest promised county-industry-quarter triple differences (women vs. men within county-industry, treated vs. control states), enabling finer controls for local shocks and border pair robustness. State-level aggregation (explicitly chosen in Appendix despite county data availability) risks confounding with state-wide policy shocks (e.g., minimum wage hikes, equity mandates). Re-estimate at county-level (3,144 counties, ~185M rows in sex panel); report triple differences explicitly as $\Delta_{gender} Y_{cti} = \beta (Post_g \times Ban_s)_{ct} + \gamma_{ct} + \delta_{sti} + \epsilon_{cti}$ (c=county, t=quarter, i=industry, s=state), with county$\times$industry FEs. This is critical for causal claims and fidelity to the idea.

2. **Incomplete industry DDD and mechanism tests**: Table 4 references a "DDD specification" (high- vs. low-gap industries) but reports NA coefficients, falling back to industry-specific TWFE. Fully implement and tabulate the cross-industry DDD as promised ($\beta_{DDD} = \beta (Post \times Ban \times HighGap_i)$); the insignificant interaction undermines anchoring claims. Similarly, hiring flows/separations (HirN/Emp, Sep/Emp) are barely analyzed despite being "key outcomes" in the manifest—report CS estimates for these to test information friction vs. discrimination (e.g., do female hiring rates rise?).

3. **Race analysis underpowered and inconsistent**: Black-White tests use CS for earnings but TWFE for hiring (Table 5), with small N=1,452/2,204 due to race panel sparsity. Manifest promised race-ethnicity breakdowns across industries; expand to full CS on county-race-industry cells, testing Black/Hispanic heterogeneity explicitly (e.g., do minority earnings rise more if anchoring dominates?). Current nulls are reassuring but require power diagnostics (e.g., minimum detectable effects) to support "no evidence of discrimination."

### 4. Suggestions
The paper is coherent, with high-quality QWI data (near-universe coverage, precise new-hire earnings) and strong pre-trends/event-study visuals supporting conclusions. The estimator contrast (CS vs. TWFE) is a standout contribution, crisply demonstrating Goodman-Bacon pitfalls in a policy context—lean into this for AER:Insights appeal. The gradual dynamic effects and lack of race backfire add policy nuance. To elevate:

- **Visuals and dynamics**: Replace Table 2's sparse event study with a Figure 1: CS dynamic ATTs (all cohorts) + 90% CIs, stratified by early (2017–19) vs. late (2020–23) cohorts to visualize heterogeneity driving TWFE bias. Add cohort-specific ATTs (Figure 2) to confirm no anticipation/attenuation (e.g., RI's short post-period may drag overall ATT). Plot industry-specific event studies for top effects (healthcare, professional) vs. low-gap (e.g., manufacturing).

- **Heterogeneity expansion**: Use manifest's sex-age/education panels for subgroups: e.g., prime-age women (25–44) or college-educated, where negotiation/anchoring may matter more. Tabulate CS ATTs by these (Appendix Table A3). For race, interact with gender (Black women vs. others) to test intersectionality.

- **Hiring/turnover mechanisms**: Even if not essential, add CS estimates for HirN/Emp, Sep/Emp, TurnOvrS (gender gaps), and firm dynamics (FrmJbGn). A 2x3 table (earnings/hiring/separations x gender gap/levels) would illuminate flows: e.g., if female hiring rises without separations spiking, it supports reduced anchoring without frictions.

- **Robustness enhancements**: Implement promised checks: (i) border county pairs (treated-control adjacent counties, ~100 pairs across 16 states); (ii) Bacon decomposition on balanced county panel; (iii) RI (1,000 perms via wild bootstrap). Report Sun-Abraham everywhere for consistency. Placebo on public sector (NAICS 92) is good; extend to exempt industries (e.g., small firms if data allows).

- **Quantification and context**: Great standardized effects (Appendix Table 7); promote to main text. Dollarize more: e.g., "$1,300/year relative gain" at mean earnings. Benchmark against lit: Agan-Starr (2022) tax data ~1–2pp narrowing; explain QWI advantages (industry/new-hire focus). Discuss threats: enforcement variation (e.g., index by state labor dept. resources), worker awareness (Google Trends on "salary history ban").

- **Tables polish**: Table 1: clarify FEs precisely (state-industry-quarter?); add R^2. Table 3: full pre/post binned (e.g., 0–3, 4–7, 8+ quarters). Table 4: compute pre-ban gaps consistently (log points, not %); sort by effect size. Table 5: harmonize estimators/specs; add female-only hiring.

- **Writing/streamlining**: Intro/discussion tight; cut redundant theory (Section 2.2). Abstract: specify "state-industry-quarter" level. Emphasize novelty: "first admin industry decomp" + "no BTB-style race harm." JEL/keywords spot-on. For Insights (~3,500 words): appendices are comprehensive—trim main text tables if needed.

Overall, with county-level fixes, this makes a genuine AER-caliber contribution: causal evidence on a timely policy, granular mechanisms, and methodological caution. Revise and resubmit.
