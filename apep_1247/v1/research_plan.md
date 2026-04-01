# Research Plan: apep_1247

## Research Question

Did the 2009 ARRA Pell Grant expansion — the largest single-year maximum award increase in Pell history ($619, +13.1%) — differentially increase Black and Hispanic enrollment at community colleges with higher pre-existing Pell recipient intensity?

## Mechanism: The Composition Lever

Uniform federal financial aid increases have racially differentiated effects because the racial composition of Pell recipients varies sharply across institutions. Community colleges where 50%+ of students received Pell grants experienced a much larger per-student funding shock than colleges at 20% Pell share. Because Black and Hispanic students are 2–3× more likely to be Pell recipients, high-Pell-intensity institutions serve as natural conduits for racially disproportionate enrollment effects. The mechanism is compositional, not targeted — the same $619 increase produces different racial effects depending on where it lands.

## Identification Strategy

**Bartik intensity design:**
- **Dose variable:** Pre-ARRA (2007–08 average) Pell recipient share × $619 maximum award increase = implied per-student dollar shock
- **Treatment window:** AY 2009–10 through 2011–12 (ARRA implementation + wind-down)
- **Unit:** Institution-year (2-year public colleges only)
- **Estimating equation:**

  Y_it = α_i + δ_t + β(PellShare_i × Post_t) + X_it'γ + ε_it

  Where PellShare_i is pre-ARRA (2007–08) Pell recipient share, Post_t indicates 2009+ academic years.

**Outcomes:**
1. Black enrollment (headcount)
2. Hispanic enrollment (headcount)
3. White enrollment (placebo — lower Pell rates → smaller treatment)
4. Total enrollment

**Triple-difference (robustness):** High-Pell × minority race × post-ARRA

## Exclusion Restriction

Pre-ARRA Pell share (2007–08) is predetermined relative to the ARRA shock. The ARRA increase was a federal legislative action affecting all institutions proportionally to their existing Pell intensity. Institution fixed effects absorb time-invariant selection into Pell intensity. Year fixed effects absorb common enrollment trends (including Great Recession effects shared across institutions).

**Key threat:** The Great Recession itself drove community college enrollment up. The Bartik design addresses this: the identifying variation comes from *differential* enrollment gains at high- vs. low-Pell institutions, beyond any common recession effect.

## Falsification Tests

1. **Placebo dose years:** Use 2004–05 or 2006–07 Pell share changes (smaller, non-ARRA) — should not predict differential enrollment
2. **White enrollment as within-institution placebo:** Lower Pell rates → smaller expected effect
3. **Pre-trend test:** Event study on Black enrollment × PellShare dose, checking for differential pre-trends 2002–2008
4. **Outcome that should NOT move:** Institutional characteristics (tuition, faculty counts) should not jump discontinuously in 2009 at high-Pell institutions

## Data Sources

**Primary:** IPEDS (Integrated Postsecondary Education Data System)
- Download complete survey files via NCES bulk download (CSV)
- Tables needed: HD (institutional characteristics), EFFY (enrollment by race), SFA (student financial aid / Pell recipients)
- Years: 2002–2015 (long pre-period + post-ARRA recovery)
- Universe: 2-year public institutions (IPEDS sector codes 4, 5)
- Expected sample: ~1,100 institutions × 14 years ≈ 15,400 institution-year observations

**Construction:**
1. Merge HD + EFFY + SFA tables by UNITID × year
2. Compute pre-ARRA Pell share = avg(Pell recipients / total enrollment) for 2007–08
3. Create Bartik dose = PellShare × $619
4. Construct enrollment outcomes by race from EFFY

## Expected Effects

- **Black enrollment:** Positive and larger at high-Pell institutions (β > 0)
- **Hispanic enrollment:** Positive and larger at high-Pell institutions (β > 0)
- **White enrollment:** Smaller or null effect (built-in placebo)
- **Magnitudes:** A 10pp higher Pell share → perhaps 3–8% additional enrollment, given the aid elasticity literature (Dynarski 2003 finds ~3% per $1,000)

## Primary Specification

Event study with continuous Bartik dose:

Y_it = α_i + δ_t + Σ_k β_k (PellShare_i × 1{year=k}) + ε_it

Where k ranges over event-time indicators (2002–2015), with 2008 as the omitted base year. Cluster standard errors at the institution level.
