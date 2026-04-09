# Research Plan: The Switching Paradox

## Research Question
Does banning loyalty penalties reduce or increase consumer search? The FCA's GIPP reform (Jan 2022) banned price-walking in UK home and motor insurance. The CBA predicted switching would *fall* — consumers would no longer need to shop around. The alternative hypothesis: switching *rises* because the ban raised awareness or reduced search costs.

## Identification Strategy
**Cross-product DiD.** Treatment: motor and home insurance (subject to GIPP ban). Control: other financial products (pet, travel, savings, broadband) with loyalty penalties but NOT subject to the ban. Treatment date: 1 January 2022 (sharp).

- Pre-trends testable: 52+ weeks pre-treatment (Google Trends), 10+ half-years (FCA complaints)
- Common shocks (COVID, cost-of-living crisis, Consumer Duty Jul 2023) absorbed by DiD
- Robustness: drop travel (COVID-sensitive), use broadband as alternative control

## Data Sources
1. **Google Trends** — Weekly search intensity for UK insurance comparison sites (confused.com, comparethemarket.com, gocompare.com, moneysupermarket.com) vs non-insurance comparison sites. Free, weekly, 2004-present.
2. **FCA Aggregate Complaints Data** — Half-yearly complaints by insurance sub-product (motor, property, pet, travel, medical). Free Excel from fca.org.uk. 2016 H2–2025 H1.
3. **Financial Ombudsman Service (FOS) Quarterly Complaints** — Quarterly product-level complaints (car/motorcycle, buildings, pet, travel). Free XLSX. Q1 2021-22 onwards.

## Expected Effects
- **CBA prediction:** Switching falls → Google Trends for insurance comparison sites should decline relative to controls
- **Alternative:** Switching rises → Google Trends increase, complaints pattern changes
- Mechanism: information effect (ban raised salience of shopping around) vs reduced need effect

## Exposure Alignment
The treatment (GIPP pricing remedy) applies to home and motor insurance underwriting. Insurance comparison websites (confused.com, comparethemarket.com, gocompare.com) are directly exposed because their primary use case is motor/home insurance comparison shopping. The ban changes the price distribution consumers encounter when using these sites. Control sites (uswitch.com for energy/broadband, moneysavingexpert.com for general finance) serve markets with their own loyalty penalties but were NOT subject to GIPP. The exposure is at the product-market level: treated keywords serve treated insurance lines; control keywords serve untreated financial product lines.

## Primary Specification
Y_{pt} = α + β(Treated_p × Post_t) + γ_p + δ_t + ε_{pt}

where p = product, t = week/half-year, Treated = {motor, home insurance}, Post = {≥ Jan 2022}

## Key Robustness
- Event study with leads/lags
- Drop COVID period (2020-2021)
- Exclude travel insurance (COVID-sensitive)
- Placebo: Ofcom broadband review (2023-24) as treatment on control group
- Permutation test: randomly reassign treatment across products
