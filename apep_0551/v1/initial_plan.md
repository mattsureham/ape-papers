# Initial Research Plan: Disaster Salience and Regulatory Acceleration

## Research Question

Does disaster-induced regulatory expansion improve industrial safety, or does it merely increase detection of incidents? The September 2001 AZF ammonium nitrate explosion in Toulouse killed 31 people and triggered France's most significant industrial safety reform — the Loi n°2003-699 — which doubled ICPE inspectors and mandated risk prevention plans (PPRTs) for all Seveso high-threshold sites. This paper estimates the causal effect of the resulting enforcement surge on industrial accident outcomes, exploiting pre-existing geographic variation in Seveso site density across 96 French departments.

## Identification Strategy

**Design:** Continuous treatment difference-in-differences.

**Treatment variable:** Pre-AZF (2001) count of Seveso Seuil Haut (high-threshold) sites per department, D_i = log(Seveso H sites + 1). Departments with more Seveso sites received proportionally more inspectors and faced a larger PPRT compliance burden after 2003.

**Specification:**
Y_{it} = α_i + γ_t + β(D_i × Post2003_t) + X_{it}Γ + ε_{it}

- α_i: department fixed effects
- γ_t: year fixed effects
- X_{it}: time-varying controls (manufacturing employment, population)
- Clustering: department level (96 clusters)

**Post-treatment period:** 2003-2010 (Loi 2003 passed July 2003; inspector expansion 2003-2008)

**Key identifying assumption:** Departments with different Seveso site densities would have experienced parallel trends in industrial accidents absent the AZF shock and Loi 2003. Testable with 9 pre-treatment years (1992-2001).

## Expected Effects and Mechanisms

**Detection channel (expected positive):** More inspectors → more minor incidents detected and reported → increase in total ARIA records, especially low-severity events.

**Deterrence channel (expected negative):** More inspectors + PPRT compliance → improved safety practices → decrease in severe/fatal accidents.

**Net effect on total counts:** Ambiguous — depends on relative strength of detection versus deterrence. This ambiguity is itself the contribution: the paper decomposes the aggregate effect.

**Hypothesis:** Post-2003, high-Seveso-density departments experienced:
- Increase in total reported incidents (detection)
- Decrease in severe/fatal incidents (deterrence)
- Faster PPRT plan adoption (compliance channel)

## Primary Specification

1. **Main outcome:** Severe accidents per department-year (severity scale ≥ 3, or fatalities > 0)
2. **Secondary outcome:** Total ARIA records per department-year (captures reporting intensity)
3. **Mechanism outcome:** Minor/near-miss incidents per department-year
4. **First stage:** PPRT adoption speed by department (if data available)

## Exposure Alignment (DiD-specific)

- **Who is treated?** Departments with pre-existing Seveso Seuil Haut industrial sites. Treatment intensity is continuous (0-43 sites per department).
- **Primary estimand population:** Industrial establishments in high-Seveso-density departments
- **Placebo/control population:** Departments with zero or very few Seveso sites; also non-Seveso industrial accidents within treated departments
- **Design:** Standard continuous-treatment DiD (not triple-diff)

## Power Assessment

- **Pre-treatment periods:** 9 years (1992-2001) — strong for parallel trends testing
- **Treated clusters:** 90 departments with ≥1 Seveso H site (continuous intensity: 1-43)
- **Post-treatment periods:** 8 years (2003-2010)
- **Total observations:** 96 departments × 19 years = 1,824 department-year obs
- **Commune-level robustness:** ~300+ Seveso communes × 19 years ≈ 5,700+ obs
- **Outcome variation:** ARIA dept-year counts range 0 to ~150; mean ~17; post-2002 mean ~22
- **MDE assessment:** With 96 clusters, 9 pre/8 post periods, and continuous treatment, power should be adequate for moderate effects on severe accidents. Will compute formal MDE after data collection.

## Planned Robustness Checks

1. **Event study:** Dynamic treatment effects β_τ for τ = -9,...,-1, 0,...,+8 interacted with D_i
2. **Severity stratification:** Separate regressions for fatal, major, moderate, minor incidents
3. **Seveso-sector restriction:** Limit to accidents at Seveso-classified installations
4. **Industrial composition controls:** Manufacturing employment shares from INSEE BDM
5. **Commune-level analysis:** Replicate main specification at commune-year level
6. **Excluding Toulouse (dept 31):** Ensure results not driven by the AZF site itself
7. **Distance-from-Toulouse IV:** Use geographic distance as instrument for media salience shock
8. **Leave-one-out by department:** Test sensitivity to influential clusters
9. **Wild cluster bootstrap:** Alternative inference with 96 clusters
10. **Callaway-Sant'Anna estimator:** If treatment timing can be discretized at department level

## Data Sources

| Source | Content | Access |
|--------|---------|--------|
| ARIA (data.gouv.fr) | 63,365 industrial accident records, 1992-2025 | Open CSV |
| ICPE Georisques | 745 Seveso Seuil Haut site locations + communes | Open JSON |
| INSEE BDM/SDMX | Department-level manufacturing employment, population | Open API |
| Georisques PPRT | PPRT plan adoption dates by commune | Open (to verify) |

## Timeline

1. **Data fetch:** ARIA CSV + ICPE JSON + INSEE BDM controls
2. **Data cleaning:** Parse severity, commune codes, link Seveso density to departments
3. **Main analysis:** Continuous DiD + event study
4. **Robustness:** Severity stratification, composition controls, commune-level
5. **Paper writing:** Full paper with 25+ pages

## Key Risks

1. **Reporting bias dominates:** If all post-2003 increases are driven by detection rather than real changes in safety, the paper becomes about the measurement problem in regulation — still publishable but a different narrative.
2. **Parallel trends fail:** If high-Seveso departments had divergent trends before 2003, the design is compromised. Mitigation: 9 pre-periods, industrial composition controls.
3. **PPRT data unavailable:** If direct enforcement measures cannot be obtained, the paper relies on ITT with Seveso density as the treatment — still valid but less mechanistic.
