# Initial Research Plan: Stranded by the Label?

## Research Question

Does the threat of regulatory rental bans on energy-inefficient properties affect transaction prices above and beyond the informational content of energy labels? We decompose the price discount on poorly-rated properties into (1) an informational component (buyers value efficiency) and (2) a regulatory component (buyers discount properties that face imminent rental restrictions).

## Policy Background

France's Diagnostic de Performance Energetique (DPE) reform provides a unique natural experiment:

- **Pre-July 2021:** DPE ratings were informational only. Sellers must display them, but no legal consequences attached to bad ratings.
- **Post-July 2021:** DPE became legally binding. The Loi Climat et Resilience (August 2021) announced progressive rental bans:
  - January 2023: Rent freeze on G and F properties
  - January 2025: G-rated properties banned from new leases
  - 2028: F-rated properties banned
  - 2034: E-rated properties banned
- **Methodology change:** The 2021 reform also unified the DPE calculation (all properties now use "3CL-2021" method, replacing the dual 3CL/facture system).

## Identification Strategy

### Primary: Difference-in-Discontinuities (DiDisc)

Compare the price gap at the G/F threshold (420 kWh/m2/year in post-2021 DPE) BEFORE vs AFTER the reform:

- **Pre-reform gap (2018-2021):** Captures pure informational effect — buyers see the G label but face no regulatory consequence
- **Post-reform gap (2022-2025):** Captures informational + regulatory effect
- **DiDisc estimate = Post gap - Pre gap:** Isolates the regulatory premium

### Supplementary: Cross-commune rental-share heterogeneity

The rental ban only matters for landlords. We interact the G-rating effect with commune-level rental share (from INSEE census):

- **High-rental communes:** G discount should be large (many buyers are investors facing the ban)
- **Low-rental communes:** G discount should be smaller (most buyers are owner-occupiers, informational only)
- **Difference:** Regulatory component

### Supplementary: Multi-cutoff comparison

Compare price gaps at:
- G/F boundary (420 kWh): Rental ban imminent (2025)
- F/E boundary (330 kWh): Rental ban distant (2028)
- E/D boundary (250 kWh): Distant regulatory threat (2034)

If the G/F gap exceeds the E/D gap, the excess reflects regulatory salience.

### Exposure Alignment

**Who is treated:** All properties with DPE ratings F or G are affected by the reform, as they face progressive rental bans (G: 2025, F: 2028). The treatment is the July 1, 2021 DPE enforceability date, when ratings became legally binding.

**Exposure heterogeneity:** The rental ban channel differentially affects landlords vs. owner-occupiers. At the commune level, higher rental-share communes should show larger treatment effects if the regulatory channel dominates. At the property level, apartments (more likely rental) should show larger effects than houses.

**Comparison group:** D-rated properties (never banned) and C-rated properties serve as controls. E-rated properties face a distant 2034 ban and are excluded from the primary DiD to avoid contamination.

**Timing:** The treatment is a single national-level reform (common timing for all properties). No staggered adoption across regions. Pre-reform data begins 2020H2; the reform date is July 1, 2021.

### Placebo

- Compare effects for properties in communes with very low rental shares (<20%) — regulatory threat should be minimal.
- Compare effects before the Loi Climat was publicly debated (pre-2019) vs the announcement window (2019-2021).

## Expected Effects and Mechanisms

**Primary hypothesis:** G-rated properties face a LARGER price discount after the 2021 reform than before, and this increment is concentrated in communes with high rental shares.

**Expected magnitudes (guided by UK EPC literature):**
- Informational discount at G/F boundary: 2-5% (from pre-reform period)
- Regulatory premium: Additional 3-8% discount post-reform
- Total G-vs-F discount post-reform: 5-13%
- In high-rental communes: 8-15%
- In low-rental communes: 2-5%

**Mechanisms:**
1. **Asset stranding:** G-rated rental properties lose their income stream in 2025, directly reducing present value
2. **Renovation cost capitalization:** Buyers price in the cost of upgrading from G to at least F
3. **Uncertainty premium:** Buyers uncertain about renovation costs and future regulatory tightening demand additional discount

## Primary Specification

Transaction-level hedonic regression:

```
log(price_it) = alpha + beta1 * G_i + beta2 * G_i * Post_t +
                gamma * X_i + delta_c + theta_t + epsilon_it
```

Where:
- `price_it`: Transaction price for property i at time t
- `G_i`: Indicator for DPE rating G (vs F comparison group)
- `Post_t`: Post-reform indicator (July 2021+)
- `X_i`: Property characteristics (surface, rooms, type, construction period)
- `delta_c`: Commune fixed effects
- `theta_t`: Year-quarter fixed effects

RDD specification near threshold:
```
log(price_it) = alpha + beta * 1[kWh > 420] + f(kWh_i) +
                gamma * X_i + delta_c + theta_t + epsilon_it
```

With triangular kernel, optimal bandwidth (Imbens-Kalyanaraman), and local polynomial of order 1.

## Planned Robustness Checks

1. McCrary density test at DPE thresholds
2. Donut RDD excluding observations within 10 kWh of threshold
3. Bandwidth sensitivity (50%, 75%, 125%, 150% of optimal)
4. Polynomial order sensitivity (linear, quadratic)
5. Pre-reform placebo (no effect expected before 2021)
6. Municipality-clustered standard errors
7. Alternative time windows for "post" definition
8. Controlling for property renovation status
9. Heterogeneity by property type (apartment vs house)
10. Heterogeneity by urban/rural classification

## Data Sources

| Source | Variables | Access |
|--------|-----------|--------|
| DVF (data.gouv.fr) | Transaction price, date, address, property type, surface, rooms, commune code, GPS | Open, bulk CSV |
| ADEME DPE (data.ademe.fr) | DPE rating (A-G), kWh/m2/year, building characteristics, address, GPS | Open, bulk CSV |
| INSEE RP (insee.fr) | Commune-level rental share, population, income | Open, SDMX API |
| Cadastre (cadastre.data.gouv.fr) | Parcel characteristics | Open |

## Sample Construction

1. Download DVF geolocalized (2018-2025)
2. Download ADEME DPE database (pre- and post-reform)
3. Match DVF transactions to DPE certificates by address/GPS (within 50m)
4. Restrict to residential transactions (apartments and houses)
5. Drop extreme prices (below 10K or above 5M euros)
6. Merge with commune-level rental shares from INSEE
7. Construct RDD sample: properties within bandwidth of G/F threshold

## Power Assessment

- DVF contains ~3-4 million residential transactions per year
- ADEME DPE database has 14.2M+ certificates post-reform
- Match rate estimated at 40-60% (conservative)
- Expected matched sample: 5-10 million transaction-DPE pairs over 2018-2025
- Near G/F threshold (within optimal bandwidth): likely 50,000-200,000 transactions
- With this sample size, we can detect effects of 1-2% on prices
- Clustering at commune level (~35,000 communes): power is not a concern

## Timeline

1. Data fetch and matching (01_fetch_data.R, 02_clean_data.R)
2. Descriptive statistics and density tests
3. Main DiD and RDD analysis (03_main_analysis.R)
4. Robustness and heterogeneity (04_robustness.R)
5. Figures and tables (05_figures.R, 06_tables.R)
6. Paper writing
