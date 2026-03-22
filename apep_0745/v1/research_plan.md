# Research Plan: The Freeport Gamble — Tax Zones and the Geography of Firm Birth in England

## Research Question

Do place-based tax incentives in England's eight freeport tax sites create genuinely new firms, or merely relocate existing economic activity from neighboring areas? We test whether freeport designation causally increased firm formation rates and whether any gains come at the expense of adjacent Local Authorities.

## Policy Background

In March 2021, the UK government announced 8 English freeports offering significant tax incentives:
- Zero-rate employer National Insurance Contributions (NICs)
- 100% enhanced capital allowances
- Full business rates relief for 5 years
- Stamp Duty Land Tax (SDLT) relief

Freeport tax sites became active in staggered fashion:
- **November 2021:** Teesside, Humber, Thames
- **December 2021:** Freeport East
- **March 2022:** Solent
- **April 2022:** East Midlands
- **July 2022:** Plymouth, Liverpool

Two Scottish Green Freeports followed in January 2023 (potential additional variation).

**The IFS (2023) explicitly noted that no rigorous causal evaluation of UK freeports exists.** This paper provides the first.

## Identification Strategy

**Callaway-Sant'Anna staggered DiD at Local Authority level:**
- Treatment: LAs containing freeport tax site boundaries (~20-25 LAs)
- Controls: ~280 comparable LAs in England
- Treatment timing: varies Nov 2021-Jul 2022 (6 distinct dates across 8 freeports)
- Pre-treatment: Jan 2016-Oct 2021 (~70 months)
- Post-treatment: Nov 2021-Dec 2025 (~36-50 months depending on cohort)

**Robustness:**
1. Wild cluster bootstrap for few-cluster inference
2. Unsuccessful freeport bidders as alternative control group (selection on observables)
3. Donut-hole excluding LAs adjacent to freeport boundaries (displacement test)
4. Sector decomposition using SIC codes (manufacturing vs. services; warehousing/logistics)
5. Event-study pre-trend checks

## Exposure Alignment

Treatment is assigned at the LA level: an LA is treated if it contains any portion of a designated freeport tax site. The tax incentives (zero NICs, capital allowances, business rates relief) apply specifically to firms locating within the tax site boundary, which is typically a small fraction of the LA's territory. This LA-level assignment introduces dilution bias: the estimated effect is attenuated by the share of the LA's economy that falls within the tax site. The affected population consists of new firms choosing where to register and operate, for whom the tax incentives reduce fixed costs of establishment.

## Expected Effects and Mechanisms

**Primary hypothesis:** Freeport designation increases the monthly rate of new firm incorporations in treated LAs, driven primarily by logistics, warehousing, and manufacturing sectors that benefit most from NICs relief and capital allowances.

**Displacement test:** If freeports merely relocate activity, we expect negative effects in adjacent (donut-ring) LAs. If they create genuinely new firms, adjacent LAs should show null or positive spillovers.

## Primary Specification

```
Y_{la,t} = α_{la} + γ_t + β × FreportActive_{la,t} + ε_{la,t}
```

Where:
- Y = log(1 + new incorporations) in LA la in month t
- α_{la} = LA fixed effects
- γ_t = year-month fixed effects
- FreeportActive = indicator for LA containing an active freeport tax site
- SE clustered at LA level

## Data Sources

1. **Companies House Bulk Data** — Monthly snapshot CSV (~468MB). Contains ~5M companies with CompanyNumber, CompanyName, PostCode, IncorporationDate, SICCode.

2. **postcodes.io API** — Maps postcodes to Local Authority codes, latitude/longitude.

3. **NOMIS BRES** — Annual employment by LA and sector (for pre-treatment balance checks and employment outcomes).

4. **Census Business Formation Statistics (experimental)** — Additional validation.

## Data Pipeline

1. Download Companies House bulk CSV (BasicCompanyDataAsOneFile)
2. Parse IncorporationDate, PostCode, SICCode
3. Map PostCode → LA code via postcodes.io
4. Define treated LAs (those containing freeport tax site boundaries)
5. Construct LA × month panel: count of new incorporations
6. Merge with NOMIS employment data for covariates

## Robustness Checks

1. Pre-trend falsification (2016-2021 event study)
2. Wild cluster bootstrap (few treated clusters)
3. Unsuccessful bidders as controls
4. Adjacent-LA displacement test
5. SIC code decomposition (logistics/warehousing vs. other sectors)
6. Excluding London LAs (outlier in firm formation)
7. Poisson regression for count outcome
