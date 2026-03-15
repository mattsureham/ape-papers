# Research Plan: The Price of Privacy

## Research Question

Do state comprehensive data privacy laws deter entrepreneurship? When states mandate consumer data rights (access, deletion, opt-out) and impose compliance costs on businesses, does business formation decline — and is the effect concentrated in data-intensive sectors?

## Identification Strategy

**Callaway-Sant'Anna DiD** exploiting staggered adoption across 20 US states (2020–2026), with ~30 never-treated states as controls.

- **Treatment timing:** Effective date of each state's comprehensive privacy law (CCPA Jan 2020, Virginia Jan 2023, Colorado Jul 2023, etc.)
- **Unit:** State × week
- **Key assumption:** Parallel trends in business applications absent the law. Testable with 14 years of pre-treatment data (2006–2019 for the first cohort).

**Triple-difference (DDD):** Compare data-intensive sectors (NAICS 51 Information, 54 Professional/Technical, 52 Finance) vs. non-data-intensive sectors (NAICS 23 Construction, 72 Accommodation) — exploiting differential regulatory bite.

## Expected Effects and Mechanisms

- **Compliance cost channel:** Privacy laws impose $50K–$450K in compliance costs. This should deter marginal entrants, especially small data-intensive startups.
- **Expected direction:** Negative effect on business applications, larger for high-propensity (HBA) and corporate (CBA) applications, concentrated in data-intensive sectors.
- **Magnitude:** GDPR literature suggests 15–30% reduction in tech startups (Jia et al. 2021 JLE). US state laws are weaker than GDPR, so we expect smaller effects (5–15%).
- **Alternative channels:** (1) Demand reduction if privacy concerns reduce data-driven business models; (2) Reallocation to non-privacy states.

## Primary Specification

```
Y_{st} = α_s + α_t + β × Treat_{st} + X_{st}γ + ε_{st}
```

Where:
- Y_{st} = log(business applications) in state s, week t
- α_s = state fixed effects
- α_t = week fixed effects
- Treat_{st} = 1 if state s has an effective privacy law in week t
- CS-DiD handles heterogeneous treatment timing

DDD adds sector dimension:
```
Y_{skt} = α_sk + α_kt + α_st + β × (Treat_{st} × DataIntensive_k) + ε_{skt}
```

## Robustness Battery

1. Pre-trend event studies (CS-DiD dynamic effects, 52 weeks pre/post)
2. Signed date vs. effective date (anticipation test)
3. Exclude California (COVID confound)
4. Donut-hole excluding March–June 2020 (COVID shock)
5. Wild cluster bootstrap (state-level clustering, ~50 clusters)
6. Randomization inference (permute treatment across states)
7. Leave-one-out (drop each treated state)
8. HBA, WBA, CBA as alternative outcomes
9. Synthetic control for California (single-treated-unit robustness)

## Data Sources

1. **Census BFS weekly state data:** `bfs_state_apps_weekly_nsa.csv` (53,398 rows, 2006–2026)
   - BA_NSA, HBA_NSA, WBA_NSA, CBA_NSA
2. **Census BFS NAICS 2-digit sector data:** National weekly by sector (for DDD)
3. **Privacy law adoption dates:** Hand-coded from IAPP State Privacy Law Tracker

## Outcome Variables

| Variable | Description |
|----------|-------------|
| BA_NSA | Total business applications (not seasonally adjusted) |
| HBA_NSA | High-propensity business applications |
| WBA_NSA | With planned wages |
| CBA_NSA | Corporate business applications |
