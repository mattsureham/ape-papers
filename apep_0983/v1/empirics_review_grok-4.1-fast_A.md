# V1 Empirics Check — x-ai/grok-4.1-fast (Variant A)

**Model:** x-ai/grok-4.1-fast
**Variant:** A
**Date:** 2026-03-26T15:33:13.707147

---

### 1. Idea Fidelity

The paper largely pursues the original idea manifest, which centers on exploiting within-municipality variation in the corporate-personal Steuerfuss wedge to test for differential sorting of firms (via establishment counts and employment from STATENT) versus residents (population) in Swiss municipalities, particularly Zurich and Basel-Landschaft (BL). It faithfully uses Zurich Steuerfuss data (personal: STF_O_KIRCHE1; corporate: JUR_PERS), STATENT firm outcomes, population statistics, and adds Steuerkraft per the manifest's feasibility check. The research question on factor-specific Tiebout sorting versus standard models is preserved, with novelty in the wedge as a "natural experiment." However, key misses include: (i) restricting to Zurich only (172 municipalities, 2012–2023), omitting BL (86 municipalities) despite the manifest's emphasis on both for ~3,200 observations and 34% wedge changes; (ii) implementing a two-way fixed effects (TWFE) panel regression on separate rates or the wedge, rather than the promised triple-difference (DDD) exploiting within-municipality/year across-factor-type variation; and (iii) shifting emphasis from sorting to a "tax base mobility" null result via Steuerkraft, which elevates a secondary outcome into the core contribution. These deviations narrow scope and weaken power but do not derail the core idea.

### 2. Summary

This paper examines whether separate municipal Steuerfuss multipliers for corporations and natural persons in Zurich canton induce factor-specific Tiebout sorting, using panel data from 2012–2023. It finds precise null effects on physical outcomes—establishments, employment, and population do not respond differentially to corporate versus personal rates—but a significant negative effect on municipal tax capacity (Steuerkraft), suggesting tax base shifting (e.g., profit relocation) without physical mobility. The results challenge multidimensional tax competition models and imply that observed fiscal responses stem from financial rather than locational channels.

### 3. Essential Points

The paper is promising but requires addressing three critical issues for AER: Insights viability; failure to do so warrants rejection.

1. **Narrow sample undermines identification and power**: Limiting to Zurich (172 × 12 years = 1,972 observations) ignores the manifest's BL inclusion, halving the promised sample and variation (manifest: 34.3% wedge changes across Zurich+BL). This raises concerns about canton-specific confounders (e.g., Zurich's urban agglomeration effects) and low power for nulls (e.g., establishment SE=0.005 implies ~80% power to detect β=0.01, but smaller effects go undetected). *Fix*: Merge BL data (confirmed feasible via CSVs); report baseline with combined sample, as Zurich-only feels like a feasibility shortcut.

2. **Empirical strategy mismatches promised DDD and risks endogeneity bias**: The TWFE on continuous rates/wedge (eqs. 1–2) is not a true DDD, despite intro claims—it equates to estimating within-municipality time-series effects of rate levels, assuming parallel trends in logs. Municipal rate-setting is endogenous to fiscal needs (e.g., low Steuerkraft prompts corporate cuts), biasing coefficients toward zero for physical outcomes but inflating tax base elasticities. No event-study or dynamic models address staggered timing/pre-trends. *Fix*: Implement explicit DDD as (FirmOutcome - Pop) × ΔWedge, or firm/resident × corporate/personal × post-change; add event studies around discrete changes (integer pp shifts in ~38% of obs).

3. **Steuerkraft result overclaimed as causal without decomposition**: The -3.1% effect on log Steuerkraft from +1pp corporate rate is the paper's hook, but Steuerkraft (3-year rolling tax base) may mechanically embed prior revenues or aggregate personal/corporate components imperfectly. No breakdown (e.g., Zurich data confirms personal/corporate decomposition?) or placebo on non-tax outcomes (e.g., housing prices) validates shifting vs. demand shocks. *Fix*: Decompose Steuerkraft into personal vs. corporate shares (per Thurgau precedent); bound elasticities assuming base = revenue / (cantonal × Steuerfuss).

### 4. Suggestions

**Data and Sample Expansion (20% effort)**: Beyond BL, incorporate Thurgau/Zug (manifest feasibility) for external validity, as Switzerland's uniqueness demands breadth. Harmonize STATENT (2011–2023) with pre-2012 Steuerfuss (1990+) for longer pre-periods, enabling dynamic specs. Add firm demographics (e.g., multinationals vs. locals via STATENT firm IDs) and resident income quantiles (opendata.swiss) to test mechanisms (e.g., high-income shifting). Cross-validate population with STATPOP coresidents for migrants only. Table 1 could split SDs by size (e.g., Zurich city vs. rural) to flag heterogeneity early.

**Strengthen Identification and Robustness (30% effort)**: Pivot to discrete treatment—code "corporate cut" as ΔCorporate <0 (or >median change), enabling clean DiD/DDD with binned timing. Event-study plots (e.g., leads/lags of ΔWedge on outcomes) would visualize pre-trends (essential for staggered adoption). Interact with baseline wedge size or muni fiscal gap (e.g., lagged Steuerkraft) for heterogeneity. Address clustering: municipality-level is correct but add wild bootstrap for small N=172. Appendix with first-differences (ΔY_mt = β ΔCorporate_mt + ...) directly matches within-muni ID. Placebo: Run on non-Steuerfuss cantons or fake wedges (corporate + noise).

**Mechanism Exploration (15% effort)**: Lean into tax base null vs. sorting contrast. Regress Steuerkraft subcomponents (if available) or proxies like property values (immobilienregister) on rates. Test capitalization: Interact rates with housing supply elasticity (e.g., via land constraints). Simulate Tiebout model extensions (e.g., 2D taxes with shifting) calibrated to estimates—simple fig showing physical vs. financial margins. Heterogeneity table 3 is good; extend to high/low initial wedges or border pairs (Zurich intra-canton pairs).

**Presentation and Framing (20% effort)**: Sharpen AER: Insights fit (concise, novel fact). Title "Wedge Illusion" is punchy but soften to "Factor-Specific Taxes Shift Tax Bases, Not Factors." Abstract: Quantify power (e.g., "MC sim: 95% CI excludes elasticities >0.01"). Intro: Cite more Swiss lit (e.g., Krapf & Staubli 2025 explicitly contrasts uniform rates). Results: Add col on Δ specifications; Wald p-values everywhere. Standardized effects (app) excellent—promote to main text. Discussion: Quantify policy scale (e.g., "1pp corporate cut raises Steuerkraft 3%, worth X jobs?"). Trim auto-generated boilerplate (e.g., APEP timings).

**Minor Polish (15% effort)**: Fix typos (e.g., "flee high corporate rates" → consistent directionality; table notes align SE sig). Figs: Event-study plots > sumstats. Bib: Add devereux2007 etc. to AER style. Power calcs: Explicitly report (e.g., for nulls, SD(Y)=1.1, need N>500 for precision). This elevates to desk-reject avoidance—strong null + base effect is publishable with fixes.

Overall, the paper's precise nulls and clever institution position it well for Insights, but expansions/DDD rigor are vital for credibility. Recommend revise-and-resubmit after these.
