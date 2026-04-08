# Research Plan: The Legal Status Premium in Local Housing Markets

## Research Question
Does granting legal immigration status causally affect local housing markets? I exploit quasi-random assignment of asylum cases to immigration judges within EOIR courts as an instrumental variable for court-level asylum grant rates. The key insight: within the same court, judges differ dramatically in grant rates (56pp median disparity), and these differences are driven by judicial temperament rather than case characteristics. By aggregating judge leniency to the court-county level, I instrument for the flow of legally authorized immigrants into local housing markets.

## Identification Strategy
**Immigration judge leniency IV (UJIVE).** Within each EOIR court, asylum cases are quasi-randomly assigned to judges (GAO 2008, 2017). I construct a leave-one-out measure of each judge's average grant rate (excluding the focal case), then aggregate to the court-year level to instrument for local asylum grant rates.

**Key advantage over shift-share:** Saiz (2007 JUE), Howard (2020 JUE), and the broader literature use Bartik-style instruments that conflate immigration *volume* with immigration *status*. This IV isolates the status channel — holding the number of asylum cases constant, a more lenient court produces more legal residents.

**Exclusion restriction:** Conditional on court and year FEs, a judge's average grant rate reflects their idiosyncratic leniency (hawks vs. doves), not characteristics of the local housing market. Random case assignment ensures no selection on case-judge pairing.

## Expected Effects
- Legal status → work authorization, credit access, mortgage eligibility, Section 8 access
- Expected: increase in housing demand → higher rents, higher prices
- The "legal status premium" = housing market impact of status, net of any compositional effects
- Heterogeneity: tight vs. slack housing markets, high vs. low immigrant share counties

## Primary Specification
Y_{c,t} = α + β · GrantRate_{c,t} + γ_c + δ_t + X'_{c,t}θ + ε_{c,t}

Where c is county (linked to EOIR court catchment), t is year, GrantRate is instrumented by leave-one-out judge leniency. γ_c are county FEs, δ_t are year FEs. Standard errors clustered at county level.

**First stage:** GrantRate_{c,t} = π · JudgeLeniency_{c,t} + γ_c + δ_t + X'_{c,t}θ + ν_{c,t}

## Data Sources
1. **EOIR Case Data** (catalog.data.gov): 4.24 GB, ~2.7M cases. Judge IDs, court locations, decisions, nationalities.
2. **ACS 5-year estimates** (Census API): County-level median rent (B25064), median home value (B25077), homeownership rate (B25003), noncitizen population (B05001).
3. **FHFA HPI** (county-level): House price index for robustness.

## Fetch Strategy
1. Download EOIR case data from data.gov
2. Construct judge leniency measures (leave-one-out, within-court)
3. Map EOIR courts to counties using court location geocoding
4. Fetch ACS county-level housing outcomes via Census API
5. Fetch FHFA HPI county series
6. Merge EOIR court-level grant rates with county housing outcomes
