# Research Plan: apep_0906

## Research Question

Did the June 2016 Panama Canal expansion — which enabled Neo-Panamax vessels to reach East and Gulf Coast ports directly — reallocate transport/warehousing employment from West Coast to East/Gulf Coast port counties?

## Identification Strategy

**Continuous treatment intensity DiD.** The June 26, 2016 canal expansion is a sharp, single-date infrastructure shock. Treatment intensity varies across port counties by their pre-expansion vessel traffic composition and Neo-Panamax capacity.

- **Treatment group:** East/Gulf Coast port counties that gained Neo-Panamax access (Savannah, Charleston, Houston, New Orleans, etc.)
- **Control group:** (1) West Coast port counties (already had mega-ship access via trans-Pacific routes); (2) inland counties
- **Intensity measure:** Pre-expansion share of container traffic in total port throughput (from Army Corps waterborne commerce data)
- **Panel:** County × quarter, 2010 Q1 - 2023 Q4 (24 pre-quarters, 30 post-quarters)
- **Fixed effects:** County + Quarter FEs
- **Clustering:** County level

## Expected Effects and Mechanisms

- **Primary:** Transport/warehousing (NAICS 48-49) employment growth in East/Gulf port counties relative to controls
- **Mechanism:** Larger vessels → lower per-unit shipping costs → competitive advantage for East Coast ports on Asia-origin trade routes
- **Heterogeneity:** Ports with container terminal upgrades (Savannah, Houston) vs those without
- **Possible null:** If containerized trade was already diversifying pre-expansion, or if West Coast ports adapted (automation)

## Primary Specification

```
log(Emp_{ct}) = α_c + γ_t + β(Post_t × PortIntensity_c) + ε_{ct}
```

Where Emp is NAICS 48-49 employment from QWI, PortIntensity is a pre-expansion port activity measure, and Post = 1{t ≥ 2016Q3}.

## Data Sources

1. **Census QWI API** — County × quarter × NAICS employment, earnings, hires for NAICS 48-49 (Transport/Warehousing) and 42 (Wholesale Trade). ~20 port counties.
2. **Army Corps of Engineers Waterborne Commerce Statistics** — Port-level tonnage data by commodity and year.
3. **Census County Business Patterns** — Annual county × NAICS establishment counts.

## Robustness Checks

1. Event study (quarterly leads and lags, 2010-2023)
2. Placebo industries (NAICS 62 Healthcare, NAICS 54 Professional Services)
3. Exclude LA/Long Beach (dominant West Coast port)
4. Wholesale trade (NAICS 42) as secondary outcome
5. Wild cluster bootstrap (small number of treated clusters)
6. Leave-one-port-out sensitivity
