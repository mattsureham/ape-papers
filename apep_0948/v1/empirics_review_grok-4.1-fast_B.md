# V1 Empirics Check — x-ai/grok-4.1-fast (Variant B)

**Model:** x-ai/grok-4.1-fast
**Variant:** B
**Date:** 2026-03-25T16:20:41.975245

---

### 1. Idea Fidelity
The paper faithfully pursues the core idea from the manifest: using the pre-1988 triplicate-state instrument (Alpert et al. 2022) to causally link opioid supply exposure (via ARCOS oxycodone shipments, 2006–2012) to downstream Medicaid treatment demand (T-MSIS MAT claims), estimating the novel "supply-to-treatment pipeline elasticity." Key elements like the policy background, first-stage validation, placebo test on non-opioid SUD, and T-MSIS geocoding via NPIs are implemented. However, it misses several proposed enhancements: (i) county-level analysis or continuous ARCOS variation to address the "killer critique" of limited cross-state variation (only 7 triplicate states); (ii) secondary instruments like OxyContin reformulation (2010); and (iii) additional outcomes (CDC overdose deaths, QWI employment). The outcome period shifts to 2018–2024 (vs. manifest's 2014+), and claims counts vary inconsistently (e.g., abstract: 597k MAT claims; section: 148k; manifest: 8.3M), but the research question and identification remain intact.

### 2. Summary
This paper exploits variation from pre-1988 triplicate prescription programs—which deterred Purdue Pharma's OxyContin marketing in seven states—as an instrument for state-level oxycodone supply (ARCOS, 2006–2012), estimating its effect on Medicaid medication-assisted treatment (MAT) claims (T-MSIS, 2018–2024). IV estimates suggest a near-unitary elasticity of MAT demand with respect to supply (0.84, imprecise), supported by a precise null placebo on non-opioid SUD treatment, though OLS estimates are larger (1.96). The contribution is a first causal estimate of the fiscal pipeline from pharmaceutical supply to public insurance treatment costs, with implications for opioid litigation settlements.

### 3. Essential Points
1. **Imprecise main estimates undermine conclusions**: The IV point estimate (0.84) is statistically insignificant (p=0.40; CI includes zero), driven by limited variation (51 states, 7 treated) and a weak first stage with controls (F=5.7–13.8, below conventional 10+ threshold in some specs). Claims of a "near-unitary elasticity" and policy relevance (e.g., "one-for-one translated into...costs") overstate the evidence; authors must either sharpen precision (e.g., via county-level IV) or substantially temper interpretive language to null/ suggestive results.

2. **Cross-sectional design vulnerable to unobserved time-invariant confounders**: Averaging supply (2006–2012) and outcomes (2018–2024) into a single cross-section discards temporal variation, ignoring national trends (e.g., MAT expansion post-ACA, fentanyl shift). This risks bias from fixed differences (e.g., triplicate states' larger populations, \cref{tab:summary}). Essential: Implement a panel/event-study design interacting Triplicate_s × Post_t (e.g., post-1996) with county/state fixed effects.

3. **Inconsistent data reporting and sample details**: MAT claims fluctuate across text (597k abstract; 148k background; implied 8.3M from manifest/T-MSIS totals), and T-MSIS extraction lacks full transparency (e.g., exact codes, geocoding validation). \Cref{tab:summary} shows triplicate states have 3.5× larger populations (p<0.05), yet log(pop) controls may not fully adjust. Provide replication code/files for claims aggregation and confirm N=51 includes DC appropriately.

### 4. Suggestions
The paper is coherent and well-motivated, leveraging validated instruments (Alpert et al.) and novel data linkage (ARCOS-T-MSIS) for a policy-relevant elasticity. Strengths include the clean placebo test (\cref{tab:placebo}, precise null), robustness checks (\cref{tab:robustness}, AR test p=0.46), and economic interpretation (extensive vs. intensive margins). To elevate to AER: Insights, expand empirics and robustness while keeping brevity.

**Expand identification for power**: Follow manifest's preemption: shift to county-level IV (3,000 units × years), instrumenting log(oxycodone pills/capita)_{c,2006-12} with Triplicate_s × distance-to-triplicate-border_c or pre-1988 Triplicate_s × ARCOS_pre-1996 (if available). Add OxyContin reformulation (Aug 2010) as second instrument: high pre-reform ARCOS counties × post-2010 shock, enabling overID tests (Sargan/Hansen). This yields LIML/GMM estimates and sharpens precision; expect F>30.

**Panel structure**: Construct state/county × year panel: supply exposure as cumulated lagged ARCOS (e.g., 5–10yr lag to capture addiction stock), outcomes as T-MSIS flows. Run event studies: Triplicate_s × (year - 1996)_t, with leads (pre-trends) and lags (dynamic effects). Include state FE, year FE, region × year trends. This tests parallel trends (pre-1996 placebo) and exclusion (no direct triplicate effects on 2018+ outcomes).

**Data and outcomes**: Harmonize claims counts via appendix table (e.g., raw MAT claims by state/year). Extract full T-MSIS SUD costs/duration/retention (e.g., claims per beneficiary), benchmarking vs. Powell et al. (2020 JHE: 14.1% admissions/10% supply). Add manifest outcomes: CDC WONDER overdoses (replicate Alpert mortality), QWI healthcare employment (NAICS 62/624). Heterogeneity: by Medicaid expansion, rurality (RUCA), baseline poverty.

**Tables/Figures**: Replace cross-sections with visuals: (i) binned scatter log(oxy) vs. log(MAT), OLS/IV fits; (ii) \cref{tab:summary} as balance pre-1996 (e.g., 1980s drug arrests); (iii) appendix forest plot of leave-one-out + AR CIs. Standardize SDE table (\cref{tab:sde}) with exact formula (currently SD(log X)/SD(log Y) mislabeled).

**Text tweaks**: Abstract: note imprecision ("imprecise elasticity near 1"). Discussion: quantify fiscal externality (e.g., "10% supply cut saves $Xbn Medicaid, at point estimate"). Lit review: cite recent T-MSIS papers (e.g., HHS 2026 analytic guidelines). Limitations: add migration (people move for treatment?)—test with origin-state supply.

**Feasibility**: All data in Azure (per manifest); county geocoding feasible (99.8% NPI match). Runtime low (22m). This yields a tight, high-impact Insights paper: precise elasticity, fiscal simulations for settlements ($50B+ context). Reject if unaddressed; revise-and-resubmit otherwise.
