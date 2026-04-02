# Research Plan: Click to Compete — E-Procurement Platform Adoption and Public Contract Competition in Colombia

## Research Question

Does transitioning from informational to transactional e-procurement increase competitive bidding in public contracts? Colombia's staggered rollout of SECOP II (2015–2022) provides entity-level variation in the adoption of a fully transactional e-procurement platform, enabling causal estimation of the effect on bidder participation, single-bidder contract rates, and award prices.

## Why This Matters

Public procurement accounts for 12–15% of GDP in developing countries. Single-bidder contracts — the canonical signature of weak competition — are associated with 7–15% price premiums (Auriol et al. 2016). Lewis-Faupel, Neggers, Olken, and Pande (2016, AEJ:EP) found that India and Indonesia's e-procurement platforms increased quality but did NOT reduce prices, suggesting informational transparency alone is insufficient. Colombia's SECOP II is different: it is fully *transactional* (firms bid, submit documents, and receive awards entirely online), not merely informational. If transactional e-procurement succeeds where informational platforms failed, the mechanism is reduced transaction costs for bidders — not just information disclosure.

## Identification Strategy

**Staggered Difference-in-Differences** exploiting entity-level variation in SECOP II adoption timing.

- **Treatment:** Month of each government entity's first SECOP II process
- **Control:** Not-yet-treated entities still operating on SECOP I
- **Estimator:** Callaway and Sant'Anna (2021) — robust to heterogeneous treatment effects
- **Cohorts:** ~11,744 entities adopted between April 2015 and October 2022
- **Clustering:** Entity level (or municipality level as robustness)

### Key Assumption
Parallel trends in bidder participation and single-bidder rates between early and late adopters, conditional on entity fixed effects and time fixed effects.

### Threats to Identification
1. **Selection into early adoption:** Larger, more sophisticated entities may adopt first. Addressed by: (a) event study showing flat pre-trends; (b) CS estimator using not-yet-treated as controls; (c) entity FE absorb time-invariant differences.
2. **Concurrent reforms:** Ley 2195 de 2022 mandated universal adoption. Primary specification restricts to pre-2022 variation.
3. **Composition effects:** SECOP II may attract different contract types. Addressed by within-entity, within-modality comparison.

## Expected Effects and Mechanisms

- **Bidder count:** Positive effect (+0.3–0.5 bidders per contract). Transaction cost reduction lowers entry barriers for small/distant firms.
- **Single-bidder rate:** Negative (−5 to −10 pp). More bidders mechanically reduce single-bid contracts.
- **Award-to-reserve ratio:** Ambiguous. More competition should lower prices, but Lewis-Faupel et al. found null price effects from informational e-procurement. The transactional channel may differ.

## Primary Specification

Y_{i,e,t} = α_e + γ_t + β · SECOP2_{e,t} + X'_{i,e,t}δ + ε_{i,e,t}

where:
- i = contract, e = entity, t = year-month
- Y = {bidder count, single-bidder indicator, log(award value/reserve value)}
- SECOP2_{e,t} = 1 if entity e has adopted SECOP II by month t
- α_e = entity FE, γ_t = year-month FE

CS (2021) group-time ATT estimates with entity adoption month as cohort.

## Data Source and Fetch Strategy

### Primary Data
- **SECOP Integrado** (datos.gov.co, dataset `rpmr-utcd`): 21.55M records combining SECOP I and II with `origen` field distinguishing platform
- **SECOP II** (dataset `p6dx-8zbt`): 9.19M records with bidder counts, award values

### Fetch Plan
1. Query Socrata API for SECOP Integrado, filtering to competitive modalities (licitación pública, selección abreviada, concurso de méritos, mínima cuantía)
2. Compute entity-level adoption date = month of first SECOP II process per entity
3. Construct entity-month panel: bidder count, single-bidder rate, award/reserve ratio
4. Sample restriction: entities with ≥10 total contracts across both platforms; pre-2022 adoption variation for primary spec

### Fallback
If Socrata API rate-limits, use SoQL `$limit` and `$offset` pagination. Alternatively, restrict to largest 1,000 entities by contract volume.

## Placebo Tests
1. **Direct contracting (contratación directa):** No competitive bidding → should show no competition effect
2. **Pre-trend event study:** Flat pre-trends in 6+ months before adoption
3. **Entity characteristics:** SECOP II adoption timing should not predict pre-adoption outcome levels

## Exposure Alignment

The treatment (SECOP II adoption) affects government entities' procurement processes. Treatment is assigned at the entity level but observed at the department level due to entity identifier incompatibilities across platforms. Department-level treatment intensity (SECOP II share) captures the fraction of a department's procurement that has migrated to the transactional platform. Directly affected: (1) procuring government entities (who switch from offline to online bidding processes), and (2) firms bidding on public contracts (whose participation costs decrease with digitization). The outcome (competitive procurement share) measures the compositional shift in how contracts are awarded, reflecting both platform-induced behavioral change and the administrative channeling of competitive processes through SECOP II.

## Robustness
1. Sun and Abraham (2021) interaction-weighted estimator
2. Cluster at municipality level instead of entity level
3. Restrict to entities switching 2016–2019 (avoid early adopters and mandate)
4. Control for entity size (annual contract volume)
