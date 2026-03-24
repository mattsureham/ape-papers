# V1 Empirics Check — x-ai/grok-4.1-fast (Variant B)

**Model:** x-ai/grok-4.1-fast
**Variant:** B
**Date:** 2026-03-23T12:07:23.718219

---

### 1. Idea Fidelity
The paper faithfully pursues the core idea from the manifest: estimating race-differential occupational sorting from SSA-excluded (agricultural/domestic) to covered occupations using the MLP linked 1920-1930-1940 panel, with a DiD (pre-1920→1930 vs. post-1930→1940) and triple-difference incorporating covered workers as controls. It delivers the promised heterogeneity by excluded occupation (domestic vs. agricultural), falsification/placebo on covered workers, and geographic checks, while emphasizing domestic-worker switching as the key channel (11.8pp Black-white gap, close to the manifest's smoke-test 17.4pp gap). Minor misses include: (i) no explicit pre-trend graphs or 1920→1930 persistence tables (mentioned but not shown); (ii) no IV using county-level Black share in excluded occupations; and (iii) a major numerical discrepancy—manifest smoke test shows Black domestic switch rate of 58.2% (1930→1940, n=48k) vs. paper's ~24.7% post-SSA rate, likely due to sample restrictions (e.g., age 15-64 in 1930, valid occ all years), but unexplained.

### 2. Summary
This paper uses a novel 1920-1940 MLP census panel to estimate whether the 1935 Social Security Act's exclusion of agricultural/domestic workers (60% Black vs. 27% white exposure) induced race-differential sorting into covered occupations. A DiD comparing Black-white switching rates pre/post-SSA finds a localized 11.8pp higher post-SSA switch rate for Black domestic workers (p<0.001), with occupational upgrading (4.8 Duncan SEI points) and manufacturing entry (3.5pp), but null for agricultural workers. It identifies a behavioral "insured escape" channel in SSA's racial design, contributing causal evidence beyond prior political-economy accounts.

### 3. Essential Points
1. **Unexplained discrepancy with feasibility smoke test**: The manifest's DuckDB query on the full MLP 1920-1930-1940 panel yields Black domestic 1930→1940 switch rate of 58.2% (n=48,293) vs. white 40.8% (gap 17.4pp), but paper reports ~24.7% Black and 40.3% white post-SSA (gap effectively reversed pre-intervention). This ~33pp Black switch-rate drop cannot be dismissed as "sample restrictions" without a reconciliation table showing raw pre/post switch rates by race/occ (e.g., full vs. restricted samples) and linking rates by race/occ/switch status. Failure to address risks selection bias inflating/understating differentials.

2. **Parallel trends implausibility**: Baseline 1920→1930 Black-white switch gaps are enormous and non-parallel—e.g., domestic Black 27.5% vs. white 54.8% (27pp gap); aggregate excluded Black -4.3pp lower. Post-SSA, white rates fall sharply (e.g., domestic -14.5pp due to Depression), yielding positive DiD via differential decline, not Black acceleration. No event-study proxy, pre-trend test (e.g., linear trend assumption), or 1910-1920 placebo; triple-diff placebo weak (+0.9pp on any change). Authors must plot raw switch rates by race/decade/occ and test pre-trends formally (e.g., event-study with leads).

3. **Overreliance on small domestic sample amid aggregate weakness**: Domestic results drive claims (n=81k stacked obs., ~20-40k per race/decade), but aggregate excluded DiD is small (2.5pp, marginal p=0.085; insignificant with controls). Agricultural null attributed to "switching costs," but no direct test (e.g., urban/rural interaction). Reject if domestic is <5% of excluded sample without bounding aggregate implications.

### 4. Suggestions
**Data and descriptives (expand Section 3 and appendices)**: Add a reconciliation table for smoke-test vs. paper samples, e.g.:
```
| Sample | Black Domestic Switch 1930-40 | White Domestic Switch 1930-40 | N Black Dom |
|--------|-------------------------------|-------------------------------|-------------|
| Full MLP (smoke) | 58.2% | 40.8% | 48k |
| Paper restricted | 24.7% | 40.3% | ~10-20k? |
```
Report linking rates by race/occ1930/switch1940 (e.g., Bailey 2020-style table) to rule out differential attrition. Include balance table for pre-trends: mean switch1920-30, age, South share, SEI by race/occ/decade. Plot raw series: switch rate x decade x race x occ type (line graph, 1920-30-40 starts), with 95% CI shaded—visualize Depression drop and racial differential clearly. Tabulate 1920→1930 persistence rates (e.g., P(occ1930=occ1920 | race/occ1920)) to confirm parallel pre-mobility.

**Empirical strategy enhancements (Section 4)**: Implement manifest's IV: instrument individual excluded status x Black x Post with 1930 county % Black in excluded occ (interacted), clustered SE at county. Report first stage (exposure → switch prob). For trends, stack as pseudo-event-study: normalize 1920-30 as t=-1, 1930-40 t=0; estimate leads/lags with decade FE. Add South x interactions throughout (e.g., domestic Black x Post x South) given 88% Black excluded in South (Table 1). Restrict to prime-age men (25-55) to minimize age/composition noise, as linking favors stable men. For mechanisms, interact young age (<35) x Black x Post x Domestic (stronger pension incentive); report switch destinations fully (e.g., % to mfg/retail by race/decade).

**Robustness and heterogeneity (Section 5)**: Expand Table 3 with: (i) domestic-only triple-diff; (ii) no state FE (national DiD); (iii) South-only/North-only splits; (iv) SEI only for switchers. Test switching costs explicitly: interact urban1930 (>50k pop county) x Black x Post x Domestic. Bound Depression confound with New Deal exposure (e.g., interact AAA/relief spending from Fishback et al. county data). Appendix event-study on covered workers (any change, 1920-30-40). Compute LATE bounds assuming monotonicity in SSA incentive.

**Writing and framing (Sections 1,6)**: Tone down aggregate claims ("central finding is stark"); lead with domestic mechanism as "sharp but localized." Clarify incentive timing: payroll tax 1937, but "10-year vesting" forward-looking even for youth. Link to migration lit more: quantify overlap with Great Migration (e.g., % switchers interstate movers by race). Modern parallel: compare SDE (app Table 4, large 0.24 for domestic) to Gruber/Madrian job-lock precisely. Shorten background (merge subsubsections). Add Figure 1: map county Black excluded share 1930 vs. switch rates.

**General polish**: AER:Insights targets 6k words; this is concise—add 1-2 figures (trends, mechanisms). Bibliography: add Bailey/Morris (2020) on MLP biases, Collins (2021) on 1940s Black mobility. Feasibility strong (MLP access, large N), novelty high (first causal behavioral est.), but fix essentials for R&R. Overall coherent, data high-quality (MLP state-of-art), conclusions supported conditionally on domestic channel—but aggregate fragility tempers "fundamental" claim.
