# V1 Empirics Check — x-ai/grok-4.1-fast (Variant B)

**Model:** x-ai/grok-4.1-fast
**Variant:** B
**Date:** 2026-03-14T12:21:17.453674

---

### 1. Idea Fidelity

The paper faithfully pursues the original idea manifest. It uses the specified IPUMS MLP linked panels (1920-1930 main sample of ~11.7M native-born workers, close to the manifest's 10.7M after refinements; 1910-1920 placebo of ~9.3M), full-count 1920 census for county-level Bartik-style exposure (restricted-origin share from the exact listed countries: Italy, Russia, Poland, etc.), and the core outcomes (OCCSCORE change, upgrading/downgrading indicators, farm exit, mobility, industry switching). The identification mirrors the proposed continuous-treatment design with individual controls, state FE, and initial occupation FE (extending to state×occupation FE). The placebo test is prominently featured, as promised, and novelty claims (individual-level vs. aggregate like Tabellini 2020; built-in placebo; massive power) hold. Minor deviations include a slightly larger sample due to relaxed filters and emphasis on low-skill heterogeneity (as mechanistically intended), but no key elements are missed. The research question—whether restriction caused native occupational upgrading—is directly addressed, albeit with nuanced (non-upgrading) conclusions.

### 2. Summary

This paper exploits county-level variation in pre-1924 Southern/Eastern European immigrant settlement as a continuous treatment intensity for the 1924 Johnson-Reed Act's 87% immigration cut, tracking 11.7 million native-born men via IPUMS MLP linked censuses to measure occupational trajectories (OCCSCORE changes, transitions). Conditional on initial occupation and state, higher exposure predicts modest native upgrading (β=4.3 OCCSCORE points per percentage-point exposure, driven by low-skill workers), with reduced downgrading and farm exits. However, a pre-quota 1910-1920 placebo reveals three times larger pre-trends (β=13.3), implying endogenous immigrant sorting into dynamic counties and potential complementarity effects that slowed upgrading post-restriction—the first individual-level evidence on the Act's native labor market impacts.

### 3. Essential Points

**1. Failed placebo undermines causal claims for upgrading.** The paper correctly highlights the large pre-trend (β=13.3 in 1910-1920 vs. 4.3 post-quota), interpreting it as evidence against strict causality and toward complementarity. However, main results and abstract still frame effects as "quota exposure raises occupational scores" (e.g., "a one-standard-deviation increase... raises occupational scores by 0.023 SD"), implying causation. Authors must explicitly reframe: report the *difference-in-changes* (post minus pre: -9.0) as the preferred causal estimate, with SE accounting for both panels (e.g., via stacked regression or wild bootstrap). Without this, conclusions overclaim what is identified (residual correlation after FE, not policy effect). If unaddressed, this alone warrants rejection.

**2. Cross-sectional change regression is not true DiD; leverage panel structure more rigorously.** The spec regresses ΔOCCSCORE_{1920-1930} on fixed 1920 exposure with 1920 covariates/FE, which differences out individual fixed effects but remains vulnerable to county-time shocks (e.g., differential 1930s Depression effects in immigrant hubs). Manifest promised "individual-level continuous-treatment DiD," but this is cross-sectional. Essential fix: estimate a full panel DiD stacking 1910-1920 and 1920-1930 panels, interacting exposure with post-1924 dummy (using 1920 exposure as shift-share proxy for post-shock). This directly tests/nets out pre-trends. Report both levels and changes equations for transparency.

**3. Linking selection bias unaddressed quantitatively.** MLP links (~30-35% rate for men) select on stable, literate, higher-SES traits (Price 2020 cited but not quantified here). Low-skill natives (where effects concentrate) link less reliably, biasing toward high-mobility success stories. Essential: tabulate link rates by 1920 OCCSCORE terciles, race, literacy; reweight sample by inverse link probabilities (or bound bias using non-linked full-count aggregates). Sensitivity to link-quality weights (e.g., Abramitzky et al. 2021) must be shown; if low-skill bias >20%, reject low-skill claims.

These three issues are fixable with existing data but central to causal validity; addressing them would elevate to AER:Insights caliber.

### 4. Suggestions

**Strengthen visualization and intuition.** Add 2-3 figures comprising ~20% of revisions: (i) binned scatterplot of mean ΔOCCSCORE (with state×occ FE residuals) vs. binned restricted share (non-parametric main effect); (ii) event-study style plot stacking panels, plotting exposure×period interactions (1910-1920 as pre, 1920-1930 post) by skill group; (iii) map of restricted share (top panel) overlaid with residual ΔOCCSCORE (to visualize geographic patterns, e.g., Northeast industrial counties). These would clarify pre-trends visually and preempt "black box" critiques.

**Expand heterogeneity and mechanisms.** The low-skill gradient is compelling; extend Table 3 to interact exposure with 1920 industry (e.g., manufacturing vs. agriculture) and immigrant-overlap occupations (e.g., laborers vs. operatives, using IPUMS OCC overlap stats). Test mechanisms: regress outcomes on *changes* in local immigrant shares (1920-1930 full-count), instrumented by 1920 restricted share—to isolate realized supply shock. Explore gender (add women, ~20% sample) and Black natives (noted in robustness; full table by race, given Great Migration). For complementarity, add supervisor ratios (natives supervising foreign-born via OCC hierarchy) as outcome/mediator.

**Robustness suite enhancements.** Build on existing checks: (i) Alternative exposure (1920 restricted FB *among workers only*, excluding kids; or 1910 share for placebo consistency); (ii) Commuter adjustment (exclude border counties or use MSA FE if county too local); (iii) Depression controls (interact exposure with 1930 unemployment proxies from Haines census aggregates); (iv) Entropy balancing on county pre-1920 covariates (e.g., 1910 manuf. share, log pop, education); (v) LASSO-selected controls from county observables. Report all in Appendix Table A1 with signs/SE plot (like Chetty et al.). Population-weighting nullifies effects—promote as key robustness, discussing small-county power.

**Refine outcomes and welfare.** OCCSCORE (1950-based) is standard but anachronistic; validate with 1930 wage analogs (e.g., OCCWAGE) or nominal earnings if available in MLP. Decompose upgrading into wage vs. skill content (using IPUMS task scores). Add nominal wage changes (if linkable) for welfare relevance. Standardize all effects (Table A2 expands SDE table nicely—move to main text). For transitions, clarify farm exit denominator (309% mean seems erroneous; check subsample).

**Institutional and historical context.** Bolster background: quantify realized inflow drop (e.g., actual 1924-1930 arrivals by origin from Historical Statistics). Discuss spillovers (e.g., Western Hemisphere inflows offsetting? Unrestricted Canadians/Germans diluting?). Cite more on 1920s labor markets (e.g., Higgs 1971 occupational data; Lewis 2011 task models).

**Writing and presentation tweaks.** Abstract: lead with nuance ("modest upgrading but pre-trends suggest..."). Introduction: sharpen policy hook with modern parallel (e.g., Trump-era restrictions). Tables: add depvar means/cols in all; use siunitx for uniformity. Trim discussion speculation (e.g., Denmark parallel strong but quantify similarity). Appendix: add balance table (exposure vs. county 1910 traits); link rates plot. Target 20-25% shorter via tighter prose (e.g., merge data/summary stats).

**Broader extensions (non-essential for AER:I).** Long-run: link to 1940 for persistence. Aggregate validation: replicate with city-level wages (mimic Tabellini 2020). Modern analog: H-1B lotteries on occupational mobility.

This is ambitious, high-quality work with unmatched scale—fixing essentials yields a major contribution on immigration's historical task dynamics.
