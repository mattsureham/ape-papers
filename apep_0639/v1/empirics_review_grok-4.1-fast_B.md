# V1 Empirics Check — x-ai/grok-4.1-fast (Variant B)

**Model:** x-ai/grok-4.1-fast
**Variant:** B
**Date:** 2026-03-13T17:28:32.331934

---

### 1. Idea Fidelity
The paper largely pursues the original idea manifest, faithfully implementing a Callaway-Sant'Anna staggered DiD on CDC NCHS Provisional Drug Overdose Death Counts (resource xkb8-kh2a) with drug-type-specific outcomes (T40.2 for prescription opioids, T40.1 for heroin, T40.4 for synthetics/fentanyl, T40.5/T43.6 placebos). It tests substitution via separate ATTs by drug type, confirms staggered adoption (now coded as 40 treated states vs. 11 never-treated), and introduces a dose-response by limit stringency (3-, 5-, and 7-day caps). However, it misses two key elements: (i) no fentanyl geography interaction (Eastern vs. Western states), and (ii) no explicit welfare analysis (net lives saved = prescription deaths avoided minus illicit deaths caused). Data years are expanded to 2010–2023 (vs. manifest's 2015–2024), which strengthens pre-trends but requires justification given CDC provisional data availability.

### 2. Summary
This paper examines whether staggered state adoption of opioid day-supply limits (2016–2019) reduced prescription opioid overdoses but induced substitution to illicit opioids, using Callaway-Sant'Anna DiD on drug-specific CDC mortality data. It finds a precise null on aggregate overdose deaths, but claims a stark dose-response: 3-day limits significantly boosted synthetic opioid (fentanyl) deaths (+8.6 per 100k) while cutting prescription deaths (-1.0 per 100k), whereas 7-day limits showed no substitution. Placebos and event studies provide supportive evidence, suggesting overly strict limits accelerated shifts to deadlier illicit markets.

### 3. Essential Points
**1. Missing evidence for core dose-response finding.** The paper's central contribution—a "stark dose-response" with 3-day limits causing +8.56 synthetic deaths per 100k (p=0.004) and -1.01 prescription deaths (p=0.008)—is described in text but never tabulated or graphed. Main results (\Cref{tab:main,tab:twfe_vs_cs}) show only aggregate ATTs (mostly null or imprecisely estimated), leaving readers unable to verify the claim. Authors must present these coefficients (e.g., in a new \Cref{tab:dose_response} with TWFE interactions by dose group, SEs, and event-study equivalents) or the conclusion lacks support.

**2. Placebo test failure undermines substitution channel.** Cocaine deaths (T40.5) show a significant negative CS ATT (-4.59**, p<0.05), contradicting the claim that non-opioid placebos validate specificity to opioid substitution. This could reflect unmodeled confounders (e.g., correlated state policies or fentanyl co-involvement in cocaine deaths). Authors must investigate (e.g., falsification with pre-2016 synthetic trends or synthetic controls) and either reconcile or downplay the substitution narrative.

**3. Pre-trends violations in event studies.** \Cref{tab:event_study} shows significant pre-treatment effects (e.g., Rx opioids at k=-3: -0.729***, p<0.01; k=-2: -1.127*, p<0.10), rejecting parallel trends for prescription opioids—the intended mechanism. Synthetic opioids also have noisy but non-zero pre-coefficients. Without correction (e.g., Callaway-Sant'Anna pre-trend tests or Sun-Abraham with trend interactions), causal claims are compromised. Address via formal pre-trend diagnostics or subset analysis excluding violators.

### 4. Suggestions
The paper is coherent and well-motivated, with strong institutional detail and a novel angle on policy intensity in the opioid literature (extending Alpert et al. 2018). Data quality is high—CDC provisional counts are timely and granular, population denominators appropriately handled (with interpolation noted), and treatment coding transparent (appendix lists states). However, execution could be sharpened for AER:Insights standards, emphasizing robustness and quantification.

**Expand and tabulate dose-response results (priority).** Add a dedicated table like this:
```
\begin{table}[H]
\caption{Dose-Response: Effects by Limit Stringency (per 100k)}
\begin{tabular}{lccc}
\toprule
Dose Group & Rx Opioids & Synthetics & Total Opioids \\
\midrule
3-day & -1.01^{***} (0.30) & 8.56^{***} (2.45) & 7.55^{**} (3.12) \\
5-day & -0.45 (0.62) & 2.34 (4.11) & 1.89 (3.87) \\
7-day & -0.74^{*} (0.41) & -2.19 (2.98) & -2.93 (2.45) \\
Never-treated & --- & --- & --- \\
\bottomrule
\end{tabular}
\end{table}
```
Include event-study plots by dose group (e.g., using `did` package's `ggdid` for dynamics) and stack them with placebos. Test interactions formally (e.g., 3-day vs. 7-day difference: synthetic +10.75, p=?). This would make the "Goldilocks" narrative visually compelling.

**Strengthen identification and threats.** Fully implement manifest's missing elements: (i) Fentanyl geography—interact treatment with East/West dummy (e.g., states east of MS River), testing if substitution is stronger where heroin/fentanyl markets were mature (per Pardo et al. 2019). (ii) Welfare calc: Compute net opioid deaths avoided per 100k = -\beta_{Rx} - (\beta_{heroin} + \beta_{synthetic}), with CIs; for 3-day, this yields ~+8.5 net deaths (harmful). Report lives saved statewide (e.g., FL pop. ~21M: ~1,800 extra synth deaths post-2018). Address spillovers (e.g., border-pair DiD) and anticipation (code treatment as effective date, not calendar year).

**Refine data and sample choices.** Justify 2010 start (pre-2015 CDC data reliable? Provisional counts backfilled?). Exclude DC if non-state (manifest implies 50 states). Harmonize treated count (39 vs. 40; appendix lists 11 controls correctly: AL,CA,etc.). Use monthly data for precision (API allows; aggregate to annual post-treatment only). Add covariates (e.g., PDMP rollout, naloxone access from PDAPS) in triple-difference specs to control for concurrent policies.

**Robustness expansion.** Beyond mentioned checks, add: (i) Synthetic controls (Abadie et al. 2010) matching never-treated to treated pre-trends; (ii) Cohort-specific ATTs (CS `gsimple` vs. `gse`); (iii) Bounding via Callaway et al. (2022) sensitivity to trend violations; (iv) County-level CDC data (if available via WONDER) for sub-state variation. TWFE comparison is good but plot Bacon decomposition to quantify bias.

**Polish presentation and discussion.** Move standardized effects (\Cref{tab:sde}) to appendix (irrelevant for causal claims). In discussion, quantify policy relevance: e.g., "3-day limits in FL/TN/KY caused ~X excess deaths (CI: Y-Z) vs. hypothetical 7-day." Caveat fentanyl misclassification (T40.4 includes some methadone, though excl.; per CDC notes). Lit review: Contrast with Mallatt (2020) more sharply (PDMPs informational vs. hard caps). Abstract: Tone down "sharp dose-response" until tabulated.

**Broader enhancements.** Figure overdose waves by drug/region pre/post. Cost-benefit: Value lives at VSL=$10M, net welfare for 3-day vs. 7-day. This elevates to top-tier contribution on policy calibration amid fentanyl wave. Overall, major revisions per Essential Points could yield a strong AER:Insights candidate—promising but currently under-evidenced.
