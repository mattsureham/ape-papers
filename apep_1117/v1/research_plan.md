# Research Plan: The Payday Depletion Cycle — Payment Timing and Property Crime in Buenos Aires

## Research Question

Does property crime increase as time since the most recent welfare payment day grows? Argentina's ANSES system pays ~18 million beneficiaries on staggered calendar days determined by the last digit of each person's national identity document (DNI), creating quasi-random within-month variation in neighborhood-level cash receipt timing. I exploit this payment calendar to test whether property crime follows a "depletion cycle" — rising as household liquidity falls between payment dates.

## Identification Strategy

**Design:** Following Foley (2011, ReStat), I regress daily property crime counts on "days since payment" for each DNI digit group. The last digit of the DNI is quasi-randomly assigned (determined by birth registration sequence) and uncorrelated with demographics. ANSES publishes a monthly calendar assigning each digit (0-9) to a specific payment day.

**Key variation:** Within each month, different digit groups receive payments on different days, creating 10 separate payment-date shocks spread across the month. This within-month, cross-digit variation is the identifying variation.

**Primary specification:**
```
Crime_dt = α + Σ_k β_k · 1(DaysSincePayment_dt = k) + γ_dow + δ_month×year + ε_dt
```
where d indexes digit groups and t indexes calendar days.

**Assumptions:**
1. DNI digit assignment is orthogonal to criminal propensity (testable via digit uniformity in EPH microdata)
2. Payment date assignment is exogenous conditional on digit (deterministic from published calendars)
3. No spillovers across digit groups within the same day

## Expected Effects and Mechanisms

- **Primary prediction:** Property crime (robo = robbery, hurto = theft) increases with days since last payment, peaking just before the next payment date
- **Mechanism:** Liquidity constraints — as cash depletes between payments, the marginal return to property crime rises relative to the declining consumption opportunity cost
- **Heterogeneity:** Effect should be stronger in neighborhoods with higher ANSES beneficiary density (testable using EPH microdata to estimate commune-level beneficiary shares)
- **Placebo:** Violent crimes not motivated by economic need (amenazas = threats, lesiones = assault) should show no payment-cycle pattern

## Primary Specification

1. **Aggregate daily design:** Pool all digit groups, compute city-wide "average days since payment" weighted by digit-group beneficiary shares, regress total daily crime on this measure
2. **Digit-group panel:** Stack digit-group × day observations, with digit and day FEs
3. **Spatial refinement:** Commune-level analysis using EPH-derived beneficiary intensity as treatment heterogeneity

## Data Source and Fetch Strategy

1. **Crime data:** Buenos Aires City Open Data — CSV downloads for 2019-2023
   - URL pattern: `https://cdn.buenosaires.gob.ar/datosabiertos/datasets/ministerio-de-justicia-y-seguridad/delitos/delitos_YYYY.csv`
   - Fields: date, crime type, commune, lat/lon, weapon use
   - ~600K property crime records across 5 years

2. **ANSES payment calendars:** Published monthly at anses.gob.ar
   - Need to reconstruct calendar for each month 2019-2023
   - Each digit (0-9) → specific payment date per month
   - Will scrape or manually construct from archived calendars

3. **EPH microdata:** Via `eph` R package
   - Household survey with income source, ANSES receipt, geographic identifiers
   - Use to construct commune-level beneficiary intensity weights
   - Also to verify DNI digit uniformity (balance test)

4. **Supplementary:** National SAT homicide microdata from datos.gob.ar (2017-2023) for violent crime placebo
