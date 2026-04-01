# Research Plan: Pricing to the Cap

## Research Question
Do first home buyer subsidy thresholds distort the price distribution of housing transactions, and does the incidence of bunching reveal whether subsidies are captured by sellers (developers) or retained by buyers?

## Identification Strategy
**Multi-cutoff bunching estimation (Kleven 2016)** at three simultaneous price thresholds in New South Wales, Australia:

1. **$600,000** — FHOG notch (new homes only). Forfeiture of entire $10,000 grant above $600,001.
2. **$800,000** — FHBA stamp duty exemption threshold. Worth up to $31,335 in saved stamp duty.
3. **$1,000,000** — Concession phase-out upper limit.

The July 2023 reform simultaneously shifted the exemption threshold from $650K to $800K and the concession from $800K to $1M, creating a **bunching migration experiment**: policy-driven bunching should migrate with the threshold while round-number bunching stays put.

**Key identification tests:**
- **Migration test:** Pre-reform bunching at $650K should dissolve; new bunching at $800K should appear. Control round numbers ($550K, $750K) should not migrate.
- **Supply vs demand decomposition:** FHOG applies only to new homes → $600K bunching should appear in new construction (supply-side developer pricing). Stamp duty bunching at $800K should appear in all homes (demand-side buyer behavior).
- **Placebo:** Commercial and farm properties face no FHB thresholds → should show only round-number heaping.
- **Spatial heterogeneity:** Bunching intensity should correlate with first-home-buyer prevalence across postcodes.

## Expected Effects and Mechanisms
- **Demand-side bunching** at stamp duty thresholds: buyers negotiate harder or search below the threshold to avoid paying stamp duty. Expect moderate bunching at $800K (post-reform).
- **Supply-side bunching** at FHOG threshold: developers price new homes at exactly $600K to maintain buyer eligibility. If bunching is exclusive to new homes, subsidy incidence flows to sellers.
- **Migration:** If bunching is truly policy-driven, the $650K→$800K shift should produce observable migration. The smoke test already confirms this (31% decline at $650K, 34% increase at $800K).

## Primary Specification
For each threshold $z^*$, estimate excess mass $b$ using the Chetty et al. (2011) / Kleven & Waseem (2013) bunching methodology:
- Fit a counterfactual density using a polynomial in bin midpoints, excluding a window around $z^*$
- Excess mass $b = (B - B̂) / B̂$ where $B$ is observed count and $B̂$ is counterfactual
- Bootstrap standard errors (500 replications) varying the excluded window and polynomial degree
- Report implied elasticity and behavioral response

## Data Source and Fetch Strategy
**NSW Valuer General Property Sales Information (PSI)**
- Universe of NSW property transactions, 1990-present
- Bulk CSV download, CC BY-NC-ND 4.0 license
- 2,162,429 total transactions; ~1,851,722 residential
- Fields: purchase price, contract date, settlement date, locality, postcode, zoning, nature of property, primary purpose (Residence/Vacant land/Commercial/Farm)
- URL: NSW Spatial Services open data portal

**Fetch:** Download bulk CSV. Filter to 2018-2025 for main analysis (sufficient pre/post for July 2023 reform). Use full 1990-2025 for long-run density context.
