# V1 Empirics Check — x-ai/grok-4.1-fast (Variant B)

**Model:** x-ai/grok-4.1-fast
**Variant:** B
**Date:** 2026-03-31T10:42:15.963108

---

### 1. Idea Fidelity
The paper faithfully pursues the original idea manifest. It implements the core continuous difference-in-differences design comparing Level 3 (treated, ~70 airports) to Level 1/2 airports using Eurostat avia_paoa passenger data, with a normalized waiver intensity measure \((80 - \text{threshold}_t)/80\) that captures the dose-response from graduated restoration (0%→50%→64%→80%). Key elements are retained: 2016–2019 pre-period (constant 80%), within-country variation via country×year fixed effects (e.g., Frankfurt vs. Dortmund), event studies, and triple-difference placebo using scheduled vs. non-scheduled (charter) passengers. Minor deviations include using annual rather than quarterly/monthly data (despite availability noted in manifest) and ~70 vs. ~100 Level 3 airports (likely due to data coverage/Eurostat reporting), but these do not alter the strategy. Post-Brexit UK adjustments enhance fidelity. No key elements are missed.

### 2. Summary
This paper provides the first causal evidence on the effects of the EU's COVID-era airport slot rule waiver—the only exogenous variation in the 80/20 "use-it-or-lose-it" regulation since 1993—using a continuous DiD design that exploits Level 3 vs. Level 1/2 airport status and staggered threshold restoration. Leveraging comprehensive Eurostat data (2016–2024, ~3,500 airport-years), it finds a precise null effect on log passenger volumes once country×year fixed effects absorb COVID recovery differentials: β ≈ -0.024 (SE=0.054), ruling out effects >12% in magnitude. Results hold across scheduled/non-scheduled decompositions, event studies validating parallel trends, and robustness checks, suggesting the waiver created no measurable "incumbency shield" reducing airport throughput.

### 3. Essential Points
1. **Data granularity and treatment timing misalignment.** The policy changed by scheduling season (e.g., summer 2021: 50%, winter 2020/21: 0%, summer 2022: 64%, winter 2022/23: 75%), but annual data assigns a single intensity per calendar year (e.g., 2021=0.375), blurring intra-year variation and potentially biasing the dose-response. Switch to quarterly (or monthly) avia_paoa data to align treatment precisely with seasons, re-estimate, and report how this affects β and pre-trends. If power drops, quantify it explicitly.

2. **Verification of treatment assignment.** The paper identifies ~64–68 Level 3 airports from Eurostat, vs. manifest's ~100; provide an appendix table listing all Level 3 airports (with sources, e.g., ACI Europe or national coordinators) and confirm none changed status endogenously during COVID (e.g., due to revised congestion). Justify exclusion criteria (e.g., zero passengers) and tabulate pre-COVID summary stats by exact coordination level (Level 1 vs. 2) to ensure controls are valid non-slot counterfactuals.

3. **Interpretation of null for "competition".** Passengers proxy throughput but not directly market concentration (e.g., HHI, entrant shares, route proliferation). The null rules out aggregate effects but cannot exclude route/carrier-level incumbency shielding. Explicitly caveat this in abstract/introduction/conclusion (e.g., "no airport-level throughput effects; route data needed for concentration"), and cite supporting evidence (e.g., OAG/ Cirium if accessible) or pre-register power for secondary outcomes like flights/carriers if added.

### 4. Suggestions
The paper is well-executed, coherent, and policy-relevant, with high-quality Eurostat data, clean identification off predetermined Level 3 status and continuous policy doses, and a precise null that credibly informs Regulation 95/93 revision debates. The within-country FE elegantly addresses hub-size/COVID confounds, event studies validate assumptions, and placebo/scheduled tests strengthen internals. Standardized effect sizes (Appendix) and robustness suite (size-matched, IHS, levels) are exemplary for AER: Insights. To elevate:

- **Visuals for intuition and validation (priority).** Add 3–4 figures: (i) Event-study plot (not just table) for main spec, binning pre/post-waiver phases or by intensity quartile, with 90% CIs; (ii) Parallel trends graph pre-2020 (Level 3 residualized on country×year FE vs. controls); (iii) Scatter of residuals: Level 3 airports' log passengers vs. waiver intensity, size-colored; (iv) Map of Level 3 airports with pre/post passenger changes. These would make the null vivid and preempt PT concerns.

- **Refine treatment and specs.** Normalize waiver intensity seasonally even in annual data (e.g., weight by summer/winter passenger shares from quarterly data) as bridge to quarterly analysis. Interact Level 3 × Waiver with airport size terciles (pre-2019 passengers) in main table—Appendix heterogeneity hints at this. Pool quarterly data but collapse to airport-quarter with season FE for power boost (~12k obs). Test leads/lags of intensity changes explicitly.

- **Mechanism and heterogeneity exploration.** Tabulate (not just mention) flight movements regressions alongside passengers, including passengers/flight (load factor) to probe ghost flights vs. demand. Split non-scheduled by charter type if avia_paoc granularity allows. Heterogeneity: low-cost carrier (LCC) exposure (e.g., % Ryanair/EasyJet pre-COVID from Eurostat routes) × waiver, as incumbency shield may hit entrants hardest. Country-heterogeneity plot (e.g., DE/FR/NL vs. others).

- **Data and sample enhancements.** Merge avia_paoc country scheduled/charter for aggregate placebo (manifest idea). Appendix: balance table (Level 3 vs. 1/2 on pre-2016 observables like hub status, LCC share); zero-passenger imputation discussion (winsorize or drop?); power calculations (e.g., minimum detectable effect=10% at α=0.05, 80% power). Source code/data repo link (GitHub noted) is excellent—add replication package.

- **Writing and framing polish.** Abstract: Quantify CI economically ("rules out >10% throughput drop"). Intro: Lead with slot value ($75M Heathrow) and policy hook, shorten theory lit review. Discussion: Expand model implications (e.g., simulate Brueckner 2009 with empirical β=0). Conclusion: Broader lessons (e.g., parallels to spectrum auctions, taxi medallions). JEL/keywords spot-on. Trim institutional to 1 page; move Brexit to note.

- **Extensions for impact (non-essential).** If space, route-level DiD (Eurostat avia_parm if available) for entry/concentration, or IV using distant airports' waiver exposure. Simulate policy counterfactual: full 80% restoration in 2021—ghost flight costs vs. forgone entry.

Overall, addresses a timely gap with rigor; revisions would make it submission-ready for AER: Insights.
