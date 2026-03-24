# Research Plan: apep_0871

## Research Question

Does cybersecurity regulation change firm behavior, or does it merely generate compliance paperwork? The EU NIS2 Directive (2022/2555) imposes cybersecurity obligations on enterprises with 50+ employees while exempting smaller firms. Using the sharp size threshold and staggered transposition across EU member states, this paper estimates the causal effect of regulatory scope on enterprise cybersecurity investment.

## Identification Strategy

**Primary: Difference-in-Differences by firm size class**
- **Treated:** Enterprises with 50–249 employees (newly NIS2-covered)
- **Control:** Enterprises with 10–49 employees (exempt under NIS2)
- **Pre-treatment:** 2019, 2022 (Eurostat ICT security survey waves)
- **Post-treatment:** 2024 (first post-NIS2 survey wave)

**Secondary: Difference-in-Difference-in-Differences (DDD)**
- Interact DiD with cross-country transposition status: countries that fully transposed NIS2 by October 2024 vs. those that had not yet transposed
- This isolates the regulatory channel from secular cybersecurity trends

**Dosage test:** 250+ employee firms were already covered under NIS1 (Directive 2016/1148). NIS2 intensifies requirements but does not newly regulate them. Comparing treatment effects for 50–249 (new regulation) vs. 250+ (intensification) tests whether new vs. marginal regulation differs.

## Expected Effects and Mechanisms

- **Compliance channel:** NIS2 mandates written security policies, incident response plans, and risk assessments → expect large effects on formal documentation measures
- **Technical channel:** NIS2 requires encryption, intrusion detection, log maintenance → effects on technical measures may be smaller if firms already adopted these
- **Training channel:** NIS2 mandates staff cybersecurity training → expect positive effects
- **Compliance theater hypothesis:** If effects are concentrated in documentation but absent for technical measures, regulation generates paper compliance without behavioral change

## Primary Specification

```
Y_{cst} = β₁(MediumFirm_s × Post_t) + α_cs + γ_ct + δ_st + ε_{cst}
```

Where:
- c = country, s = size class, t = year
- Y = cybersecurity measure adoption rate (%)
- MediumFirm = 1 for 50–249 employees
- Post = 1 for 2024
- α_cs = country × size FE (absorbs level differences)
- γ_ct = country × year FE (absorbs country-specific trends)
- δ_st = size × year FE (absorbs EU-wide size trends)

DDD adds interaction with transposition status.

## Data Source and Fetch Strategy

**Primary:** Eurostat `isoc_cisce_ra` — ICT security survey, enterprise cybersecurity measures by size class
- 33 indicators across categories: security policies, risk assessment, security testing, log maintenance, intrusion detection, encryption, staff training
- Size classes: 10–49 (S_C10_49), 50–249 (S_C50_249), 250+ (S_GE250)
- Years: 2019, 2022, 2024
- 26 EU countries with complete panels (Portugal missing 50–249)
- ~1,994 non-null observations confirmed in smoke test

**Secondary:** Eurostat `isoc_cisce_ic` — ICT security incidents by size class

**Transposition data:** CELLAR SPARQL via `eurlex` R package for NIS2 (CELEX 32022L2555) national implementation measures

**Fetch strategy:**
1. Use `eurostat` R package to pull `isoc_cisce_ra` and `isoc_cisce_ic`
2. Use `eurlex` R package to construct NIS2 transposition panel
3. Merge on country × size class × year
4. No API keys needed — all open access

## Key Risks

1. **Only one post-period (2024):** Cannot test dynamic effects or pre-trends with multiple post-periods. Mitigated by two pre-periods (2019, 2022) for parallel trends testing.
2. **Aggregate data (country × size-class):** Not firm-level microdata. Mitigated by the fact that Eurostat survey representativeness is strong and this is the universe of available data.
3. **Anticipation effects:** Firms may have started compliance before transposition deadline. This would attenuate the DDD (transposed vs. not) but should not bias the main DiD.
4. **Spillovers to small firms:** NIS2 supply chain requirements may push security practices down to small firms (control group). This biases toward zero — conservative.
