# Research Ideas: Taxes and Elite Mobility

## Idea 1: ZIP-Code Border RDD — State Tax Differentials and High-Income Geographic Sorting

**Policy:** State income tax differentials at US state borders, with the 2017 TCJA SALT deduction cap ($10,000) as an amplifying shock. High-tax states (CA 13.3%, NJ 10.75%, NY 10.9%, MN 9.85%, OR 9.9%) border low-tax or zero-tax states (NV, PA, CT, SD, WA). The SALT cap eliminated federal deductibility of state taxes above $10K, dramatically increasing the effective cost of living in high-tax states for high earners — effective January 2018.

**Outcome:** IRS Statistics of Income ZIP-code-level data (2012–2021), specifically:
- Number and AGI of $200K+ filers (agi_stub=6) per ZIP code
- Growth in high-income filer counts at border ZIP codes
- Average AGI per high-income return (intensive margin)
- Confirmed available: HTTP 200 for all years 2018–2021 at `irs.gov/pub/irs-soi/[YY]zpallagi.csv`

**Identification:** Multi-border boundary discontinuity design (RDD):
- Running variable: distance from ZIP code centroid to nearest high-tax/low-tax state border (negative = high-tax side, positive = low-tax side)
- Treatment: residing on the high-tax side of a state border
- Estimate the discontinuity in high-income filer density at the border
- Layer the TCJA SALT cap (2018) as a within-border event study: the cap differentially increased effective tax cost at borders with large pre-TCJA SALT deductions
- This creates a triple-difference-like structure: (high-tax side vs. low-tax side) × (high-income vs. low-income) × (post-SALT vs. pre-SALT)
- 8+ border pairs provide internal replication: NJ/PA, NY/CT, CA/NV, MN/SD, OR/WA, CA/AZ, MN/WI, MN/IA

**Why it's novel:**
- First paper to use IRS SOI ZIP-code income data for a geographic boundary discontinuity on tax-driven elite sorting
- Combines spatial RDD with event study (SALT cap), creating two independent sources of identification
- Decomposes response into extensive margin (# filers relocating) vs. intensive margin (income composition change)
- Multiple borders provide "internal replication" (judges value this highly)
- Built-in placebo: low-income brackets (agi_stub 1-2, <$50K) face minimal cross-border tax differentials
- Welfare calculation via sufficient statistics framework (Kleven-Landais-Saez 2014 revenue elasticity)

**Feasibility check:**
- IRS ZIP-code data: confirmed available 2012-2021, ~30K ZIP codes per year, income brackets include $200K+
- ZIP code centroids: Census ZCTA shapefiles (free)
- State borders: TIGER/Line shapefiles (free)
- State tax rates: Tax Foundation historical data (free)
- Pre-TCJA SALT levels: IRS SOI state data (free)
- No API keys needed — all direct downloads

---

## Idea 2: State-Level IRS Migration Flows — Tax Rate Differential Panel RDD

**Policy:** Same as Idea 1 — state income tax differentials and the TCJA SALT cap.

**Outcome:** IRS SOI state-to-state migration data (2011–2022) with income bracket breakdowns. The gross migration files (`inmigall.csv`) include inflow/outflow counts and AGI by agi_stub (0-7), where agi_stub=7 is $200K+ AGI. State-to-state flow files give bilateral migration between all state pairs.

**Identification:** Panel RDD on the tax rate differential:
- Running variable: difference in top marginal income tax rate between origin and destination state
- Outcome: share of $200K+ interstate migration flowing from high-tax to low-tax states
- Use state-pair × year fixed effects
- TCJA SALT cap as an event study within the RDD framework

**Why it's novel:**
- Uses the richest available income decomposition ($200K+) for interstate migration
- Panel structure (11 years) allows event study around SALT cap
- Can decompose by origin-destination characteristics

**Feasibility check:**
- State-level migration + income bracket data: confirmed available 2011-2022
- Tax rate data: Tax Foundation (free)
- Limited geographic precision (state-level, not ZIP/county) — weaker RDD

**Weakness:** State-level is coarse. Tax rate differential is not as "sharp" a running variable as geographic distance. This is more of a panel regression than a clean RDD.

---

## Idea 3: ACS Microdata Border RDD — Migration Status × Income

**Policy:** Same border tax differentials.

**Outcome:** ACS 5-year PUMS microdata with individual-level income (PINCP), migration status (MIG), and PUMA of residence. ACS table B07010 gives county-level migration by income, but top bracket is only $75K+.

**Identification:** Border RDD using PUMA centroids as geographic units:
- Running variable: distance from PUMA centroid to state border
- Individual-level analysis with demographic controls
- Can identify migration rates by fine income groups

**Why it's novel:**
- Individual-level data allows demographic controls (age, education, industry)
- Can test heterogeneity by occupation type (remote-compatible vs. place-bound)

**Feasibility check:**
- ACS PUMS: available via Census API
- B07010 county tables: confirmed available
- Weakness: PUMAs are large (~100K population), limiting geographic precision near borders
- Top income bracket in B07010 is only $75K+ — not truly "elite"

**Weakness:** Geographic imprecision of PUMAs undermines the boundary discontinuity. $75K+ threshold in tabulated data is too low for "elite" mobility.

---

## Idea 4: Remote Work Regime Change and Tax-Border Sorting (2020+)

**Policy:** COVID-19 as a natural experiment that dramatically reduced geographic friction for high-income knowledge workers. Combined with pre-existing tax differentials at state borders.

**Outcome:** Same IRS ZIP-code data as Idea 1, but focusing on the 2019-2021 period.

**Identification:** Triple-difference: (border vs. interior ZIP codes) × (high-income vs. low-income) × (post-COVID vs. pre-COVID). Tests whether remote work amplified tax-motivated sorting.

**Why it's novel:**
- Tests the interaction of geographic friction and tax incentives
- COVID is a large, plausibly exogenous shock to location flexibility

**Feasibility check:**
- Same data as Idea 1
- Weakness: COVID confounds everything (urban flight, amenity preferences, health concerns)
- Very short post-period (2020-2021 in IRS data)
- Hard to separate tax-motivated from amenity-motivated moves

**Weakness:** COVID is a confounded shock — impossible to isolate tax channel from urban flight, health concerns, etc. Short post-period.

---

## Idea 5: Estate Tax Threshold Notch and Elderly Out-Migration

**Policy:** State estate tax exemption thresholds. New York has a unique 105% "cliff" — estates exceeding 105% of the exemption ($6.94M in 2024) lose the ENTIRE exemption, creating a massive notch. MA and OR have $1M thresholds.

**Outcome:** Would need individual-level wealth + migration data for elderly. IRS estate tax data is aggregate only. Could proxy with ZIP-code-level data for 65+ populations from ACS.

**Identification:** RDD at the estate tax threshold — compare households just above vs. just below. The NY cliff provides the sharpest notch.

**Why it's novel:**
- NY's cliff is uniquely sharp — tests mobility response to a massive discrete tax jump
- Connects notch/bunching literature to mobility literature

**Feasibility check:**
- FATAL: No individual-level wealth × migration data publicly available
- ACS has age-specific income but not wealth
- Would need to use area-level proxies (median home values near threshold), which destroys the RDD
- IRS estate tax statistics are aggregate (number of estates by size class by state)

**Weakness:** Data infeasibility. Cannot observe individual wealth and migration jointly.
