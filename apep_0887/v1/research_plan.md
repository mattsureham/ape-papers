# Research Plan: Building Codes as Behavioral Nudges

## Research Question

Do radon-resistant new construction (RRNC) building codes generate behavioral spillovers by increasing voluntary radon testing in the existing housing stock? When jurisdictions mandate passive sub-slab depressurization in new homes, does the salience of radon risk spread to owners of older homes — or does the mandate crowd out voluntary action?

## Identification Strategy

**Staggered Difference-in-Differences (Callaway & Sant'Anna, 2021)**

- **Treatment:** County-year of RRNC code adoption (IRC Appendix F or equivalent). 100+ counties adopted between 1999 and 2015, with major statewide adoptions (Minnesota 2007, Oregon 2011) and city/county-level adoptions.
- **Outcome:** Annual radon testing rate per 10,000 housing units (CDC Environmental Health Tracking Network, measure 865).
- **Control:** Never-treated counties and not-yet-treated counties.
- **Built-in placebo:** EPA Zone 3 (low radon risk) counties where RRNC codes have minimal behavioral impact because radon is not salient. If the effect is driven by information/salience rather than some correlated trend, we should see zero effect in Zone 3.

## Expected Effects and Mechanisms

**Primary hypothesis:** RRNC adoption increases voluntary radon testing in existing homes (positive spillover).

**Mechanism — Information salience:** When builders must install radon systems, local media covers the code change, home inspectors mention radon, and new-home buyers learn about radon risk. This information diffuses to owners of existing homes, who then test voluntarily.

**Alternative — Crowding out:** If homeowners believe new codes "solve" the radon problem, they may reduce testing of existing homes (false sense of security). This would generate a negative or null effect.

**Heterogeneity predictions:**
1. Stronger in EPA Zone 1 (high radon) counties where risk is real and salient
2. Stronger in counties with more new construction (higher treatment intensity)
3. Possibly stronger in first years (novelty) then fading

## Primary Specification

```
Y_{ct} = α_c + α_t + β × RRNC_{ct} + X_{ct}γ + ε_{ct}
```

Where Y is radon tests per 10,000 housing units, RRNC is a binary indicator for code adoption, α_c and α_t are county and year fixed effects. Cluster SEs at the state level (adoption often statewide).

CS-DiD with never-treated as control group for the heterogeneity-robust estimator.

## Data Sources

1. **CDC Environmental Health Tracking Network** — County-level annual radon testing (measure 865: rate per 10,000; measure 843: total tests). API confirmed: 2,929 county records per year.
2. **EPA Radon Zone Classification** — 3,144 counties classified Zone 1 (highest)/2/3 (lowest).
3. **Census Building Permits Survey (BPS)** — County-level new residential construction permits (treatment intensity proxy).
4. **Census County Business Patterns (CBP)** — NAICS 562910 (Remediation services) for supplementary outcome.
5. **RRNC adoption dates** — Compiled from IRC Appendix F adoption records, state building code databases, and AARST (American Association of Radon Scientists and Technologists) documentation.

## Robustness

1. Event study (dynamic treatment effects) — test for pre-trends
2. Callaway-Sant'Anna with never-treated and not-yet-treated control groups
3. Placebo test: Zone 3 counties (should show null)
4. Leave-one-out: drop Minnesota (largest statewide adopter) to check sensitivity
5. Continuous treatment intensity: interact with new construction permits
6. Wild cluster bootstrap (few state-level clusters in early cohorts)
