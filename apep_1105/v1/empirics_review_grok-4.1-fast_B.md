# V1 Empirics Check — x-ai/grok-4.1-fast (Variant B)

**Model:** x-ai/grok-4.1-fast
**Variant:** B
**Date:** 2026-03-29T14:34:27.823389

---

### 1. Idea Fidelity
The paper partially pursues the original idea manifest but deviates substantially from key elements of the identification strategy, data sources, and research design. It retains the core policy shock (2014 hydrocodone rescheduling), instrument construction (pre-rescheduling county HCP share from ARCOS), and outcome (Medicaid MAT/SUD claims from T-MSIS), while emphasizing novelty in estimating treatment utilization demand. However, it abandons the promised shift-share IV panel design (Archetype 6 × 4 with county-year variation and post-2014 indicator) in favor of a cross-sectional reduced-form regression using a mismatched time periods: ARCOS 2006–2012 for shares and T-MSIS 2018–2024 for outcomes (skipping the manifest's 2011–2019 panel window and immediate post-shock dynamics). It omits first-stage verification on total opioid volume (ARCOS), pre-trends tests, zero-HCP placebo, CDC overdose deaths, and QWI employment outcomes; restricts to 587 counties (vs. ~3,000); and ignores substitution preemption details (e.g., Lozano-Rojas validation for fiscal outcomes). These changes weaken causal claims, shifting from a "READY" panel IV to an imprecise descriptive exercise.

### 2. Summary
This paper examines whether the 2014 hydrocodone rescheduling—a major supply shock—affects Medicaid-funded addiction treatment utilization, using cross-county variation in pre-shock HCP dependence as a shift-share instrument in a reduced-form design. Linking ARCOS shipment data (2006–2012) to T-MSIS claims (2018–2024), it finds positive but statistically imprecise point estimates for MAT claims, with a placebo null on non-opioid SUD treatment and suggestive patterns by modality (stronger for buprenorphine). The results highlight limits of cross-sectional identification but fail to deliver credible causal evidence on a "treatment dividend" due to design flaws and imbalance.

### 3. Essential Points
The paper has three critical flaws that undermine its causal claims and prevent a genuine contribution to understanding policy effects. These must be addressed for any revision to be viable; failure to do so warrants outright rejection.

1. **Cross-sectional design lacks temporal variation and pre-trends**: The manifest promised a panel shift-share IV or DiD exploiting pre/post-2014 timing across county-years, with 3+ pre-periods for parallel trends. Instead, the paper uses a static cross-section (pre-2012 shares vs. 2018–2024 averages), spanning 6+ years post-shock. This misses dynamic effects, confounds long-run trends (e.g., fentanyl wave, Medicaid expansion), and omits testable pre-trends or event-study plots. Without panel structure, it's impossible to attribute outcomes to the shock rather than persistent cross-county differences in treatment infrastructure.

2. **Severe time mismatch and sample attrition erode identifying variation**: Outcomes start in 2018 (4 years post-shock), averaging away immediate "dividend" effects while capturing unrelated expansions (e.g., buprenorphine waiver relaxations). The sample shrinks to 587 counties (from ~3,000 promised) via arbitrary cuts (>100k ARCOS shipments, ≥1 MAT provider), biasing toward larger/urban areas with high baseline MAT (SD=36/1k pop./mo.). This induces mechanical selection and power loss; e.g., buprenorphine mean=1.0 but P75=0 due to zeros. Expand to full counties, use 2011–2019 T-MSIS if available (manifest claims 2011 start), or impute zeros.

3. **No first-stage evidence and failed exclusion due to imbalance**: No verification that HCP shares predict post-shock supply declines (total opioids via ARCOS 2011–2019), despite acknowledged substitution bias. Balance test fails badly (F=6.0, p<0.001 post-state FE; correlates with poverty/population/race), violating share exogeneity. Placebo works but can't rescue this; add IV 2SLS with total post-HCP opioids as endogenous, zero-HCP falsification, and over-ID tests.

### 4. Suggestions
While the core question—does opioid supply restriction generate treatment demand?—remains policy-relevant and novel (no prior causal work on utilization post-rescheduling), the execution prioritizes description over causality. The data quality is strong (178M ARCOS + 227M T-MSIS rows, clean geocoding via NPPES/ZIP crosswalks), but analysis underutilizes it. Below are concrete, prioritized suggestions to elevate to AER:Insights standards, focusing on feasibility with existing Azure data.

#### Strengthen Identification (Top Priority)
- **Adopt panel DiD**: Restructure as county-quarter/year T-MSIS (2018–2024) regressed on HCP_share_c × Post_2014_t (or finer Oct-2014 cut), with county FE + linear county trends. This recovers the manifest's Archetype 6×4, tests pre-trends (extend ARCOS back for leads), and uses event-study for dynamics. Include state×year FE to absorb policy confounders (PDMPs, naloxone). Expected power boost: full ~3,000 counties × 28 quarters = 84k obs vs. 587 cross-section.
  
- **First-stage and IV estimates**: Compute post-shock Δlog(total opioid shipments)_ct from ARCOS (2015–2019, product-level filter: DRUG_NAME="HYDROCODONE" vs. others). Run 2SLS: instrument total opioids with HCP_share × Post; outcome=MAT_rate_ct. Report F-stat (>10 target), Kleibergen-Paap rk LM for under-ID. Address substitution via LATE bounds (e.g., assuming partial offset per 24 studies' 3–66% declines).

- **Exclusion tests**: (i) Triple-difference: interact HCP_share × Post with opioid-specific MAT (vs. non-opioid placebo). (ii) Zero-HCP subsample (manifest killer critique): restrict to counties <5th %ile HCP_share; expect null. (iii) Link CDC WONDER overdoses (T40.x ICD-10, county-year 2011–2019) as falsification—should rise if no treatment dividend.

#### Data and Sample Improvements
- **Full sample + zeros**: Drop 100k shipment cut (endogenous to opioid exposure); use inverse hyperbolic sine or Poisson for skewed outcomes with zeros (buprenorphine P50=0). Add small-county weights or collapse to state-level for diagnostics. Manifest's 227M T-MSIS covers 2011–2019—query Azure `raw/medicaid/tmsis.parquet` for pre-2018 if restricted file used.

- **Incorporate manifest data**: Add QWI healthcare employment_ct (quarterly) as outcome (treatment supply proxy) and control. Merge CDC overdoses for overdose/MAT ratio. Descriptives: map HCP_share quartiles × Δopioids pre/post; time series of MAT_rate by exposure tercile.

- **Controls and heterogeneity**: Add baseline MAT (pre-2018 proxy via SAMHSA TEDS if Azure-available) to balance. Slice by Medicaid expansion status, rurality, baseline overdose rates. Standardized effect sizes (App. Table 5) are helpful—extend to bounds (e.g., CI for SDE).

#### Tables/Figures and Presentation
- **Visuals for intuition**: Add (i) binned scatter HCP_share vs. MAT_rate (post-state FE residuals); (ii) event-study coef plots (ΔMAT_ct on leads/lags of shock); (iii) balance donut plot (pre/post-2012 county traits by HCP quartile). Replace raw coef tables with these—readers need to see variation.

- **Refine tables**: Table 3 mechanism has errors (methadone coef=1.89 but mean=20; bup=7.13/mean=1—scale issue?); sum components ≠ total. Add col. for total opioids first-stage. Report means/SD in all; star patterns consistently.

- **Narrative tweaks**: Lean into imprecision as contribution ("bounds rule out large dividend >0.25 SD(Y)"), cite Borusyak et al. (2022) shift-share pitfalls explicitly. Broaden discussion: compare to DiNardi (2025) supply effects; policy recs conditional on LATE (e.g., pair restrictions with buprenorphine access). Cut redundancies (e.g., intro repeats abstract).

#### Feasibility and Extensions
- Execution time (56m) suggests scalable: re-run with panel in <2h via DuckDB/Polars on Azure. If T-MSIS pre-2018 unavailable, pivot to SAMHSA DAWN/NSDEUH treatment admissions (county proxied) for longer panel.
- Bigger picture: Test "dividend vs. illicit" via overdose/ER visits (manifest CDC). Heterogeneity by prescriber density (NPI counts) could reveal mechanisms.

With these, the paper could credibly quantify a small/precise null (challenging supply-side assumptions) or detect heterogeneity (e.g., rural dividend). Current version coheres as an exploratory analysis but lacks causal punch for AER:Insights.
