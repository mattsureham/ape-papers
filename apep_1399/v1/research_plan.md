# Research Plan: The Bedrock Dose

## Research Question
Do radon-resistant new construction (RRNC) building codes reduce lung cancer mortality? Treatment intensity is determined by geological radon potential (GRP) — ancient bedrock uranium content that predates modern policy by hundreds of millions of years.

## Identification Strategy
**Geology × Policy interaction DiD.** 11 US states adopted mandatory RRNC codes at staggered times (1995–2021). RRNC codes are uniform within states, but the health benefit varies by underlying geology: high-GRP counties (uranium-bearing bedrock) get large effective dose reductions, while low-GRP counties get near-zero benefit.

**Specification:**
```
LungCancer_cst = α_c + δ_st + β(Post_RRNC_st × HighGRP_c) + X_cst'γ + ε_cst
```
- County FE (α_c) absorb time-invariant county characteristics
- State × Year FE (δ_st) absorb all state-level trends including code adoption
- β identified from within-state, post-code differential between high-GRP and low-GRP counties

**Falsification:**
1. Cancers with no radon mechanism (breast, prostate, colorectal) — should show no geology × policy interaction
2. Pre-trends: event study should be flat before code adoption
3. New construction share: effect should be larger where more housing is built post-code

## Expected Effects
- Lung cancer mortality declines more in high-GRP counties after RRNC adoption
- Effect grows over time as housing stock turns over (long lag: 10-20 year latency)
- No effect in low-GRP counties (placebo within treated states)
- No effect on non-radon cancers (placebo across outcomes)

## Data Sources
1. **CDC WONDER Compressed Mortality** — County-year lung cancer deaths (ICD-10 C33-C34), 1999–2020
2. **USGS Geological Radon Potential** — Shapefile of 926 geological provinces with GRP scores (1-3)
3. **State RRNC adoption dates** — From LawAtlas, EPA, and academic sources
4. **Census Building Permits** — County-level new residential construction (mechanism)
5. **Controls:** County population, smoking rates (BRFSS), income (BEA CAINC)

## Risk Assessment
- **Main risk:** Long latency between radon exposure and lung cancer (10-30 years). States adopting after 2010 may show no effect by 2020.
- **Mitigation:** Focus on early adopters (NJ 1995, WA 1997, MN 2009) for main results. Later adopters serve as control group.
- **Power:** 3,141 counties × 22 years ≈ 69K observations. With county FE and state-year FE, effective variation is within-state geology × timing.
