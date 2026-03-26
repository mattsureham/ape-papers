# Research Plan: Receipts for the Republic

## Research Question
Does mandatory real-time electronic reporting of cash transactions formalize the shadow economy or destroy marginal businesses? The Czech Republic's phased Electronic Records of Sales (EET) system — rolled out sector-by-sector from December 2016 to June 2018 — provides a staggered natural experiment to estimate the causal effect of enforcement technology on business dynamics.

## Identification Strategy
**Staggered Difference-in-Differences** exploiting the phased EET rollout:
- Phase 1 (Dec 2016): Accommodation & food service (NACE I)
- Phase 2 (Mar 2017): Wholesale & retail trade (NACE G)
- Phase 3 (Mar 2018): Professional services (M), transport (H), agriculture (A)
- Phase 4 (Jun 2018): Manufacturing & remaining crafts (C other)

**Unit of analysis:** ORP district × quarter (205 districts × ~40 quarters)

**Treatment intensity:** Each district's exposure depends on its baseline (2015) sector composition. Districts dominated by hospitality/retail face earlier, more intense treatment than manufacturing districts.

**Estimator:** Callaway-Sant'Anna (2021) with not-yet-treated districts as controls. Treatment cohorts defined by when cumulative EET exposure exceeds 50% of district employment.

**Key assumption:** Parallel trends in business counts across districts with different sector compositions, conditional on district and time fixed effects.

## Expected Effects and Mechanisms
1. **Formalization effect (positive):** Previously informal businesses register to comply → business counts increase (Naritomi 2019 finding in Brazil)
2. **Compliance destruction effect (negative):** Marginal businesses that survived on tax evasion shut down → business counts decrease
3. **Net effect is ambiguous:** In developed economies with stronger baseline enforcement, the destruction channel may dominate

## Primary Specification
Y_{dt} = α_d + γ_t + β × EET_exposure_{dt} + ε_{dt}

where EET_exposure_{dt} is the share of district d's baseline businesses in sectors that have been phased into EET by quarter t. Clustered SEs at ORP district level.

## Data Sources
1. **CZSO package 140131:** Quarterly business entity counts by ORP district, 2010-2023
2. **CZSO sector data:** Baseline sector composition by region for constructing treatment intensity
3. **Eurostat sbs_na_1a_se_r2:** Annual sector-level business statistics for Czech Republic (national-level robustness)
4. **CZSO package 250169:** Monthly unemployment by municipality (mechanism test)

## Robustness
- Event-study pre-trends by treatment cohort
- Permutation inference (randomly reassign district sector shares)
- Slovakia as control country (no EET) via Eurostat
- Sole proprietors vs. legal entities (differential compliance costs)
- Entry/exit decomposition (formalization vs. destruction mechanism)
- HonestDiD sensitivity to parallel trend violations
