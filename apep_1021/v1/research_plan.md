# Research Plan: The Laundering Premium — AML Enforcement and the Domestic Cost of Closing a Non-Resident Banking Sector

## Research Question

When anti-money-laundering (AML) enforcement forces a country's non-resident banking sector to exit, what is the domestic economic cost? Specifically, does the regulatory prohibition on shell-company bank accounts in Latvia (May 2018) — triggered by FinCEN's designation of ABLV Bank — cause differential firm dissolution in sectors that served non-resident clients, and does it reveal how much formal economic activity was sustained by dirty money?

## Identification Strategy

**Sector-intensity DiD.** The FinCEN designation (February 13, 2018) and subsequent legislative ban (in force May 2018) differentially affected sectors that served non-resident shell companies. We exploit within-country, cross-sector variation in exposure:

**Treated sectors** (high non-resident banking exposure):
- K64-66: Financial and insurance activities
- M69-70: Legal, accounting, management consulting
- L68: Real estate activities
- N82.1: Administrative/corporate secretarial services

**Control sectors** (low exposure):
- A: Agriculture, forestry, fishing
- C: Manufacturing
- G: Wholesale and retail trade
- F: Construction
- I: Accommodation and food service

**Unit of analysis:** Sector × municipality × month (119 municipalities, ~12 treated sectors, ~12 control sectors, 84 months from Jan 2015 to Dec 2021)

**Estimating equation:**
dissolution_rate_{ikt} = α_{ik} + γ_t + β · HighExposure_i · Post_t + ε_{ikt}

where i indexes sector, k municipality, t month. Standard errors clustered at sector-municipality level.

**Event study** centered on February 2018 (FinCEN announcement) to test pre-trends and trace dynamic effects.

## Expected Effects and Mechanisms

1. **Primary effect:** Sharp increase in dissolution rates in treated sectors post-February 2018, concentrated in Riga (financial center)
2. **Mechanism — shell exit:** Shell companies lose banking access → cannot operate → dissolve or go dormant
3. **Mechanism — legitimate spillover:** Legitimate firms in treated sectors lose clients (the shells were their customers) → some dissolve
4. **Heterogeneity:** Recently registered firms (post-2010) vs established firms; SIA (LLCs, typical shell structure) vs individual merchants; Riga vs rest of Latvia

## Primary Specification

Callaway-Sant'Anna (2021) staggered DiD is not needed here because treatment timing is uniform (February/May 2018 for all sectors). Standard TWFE event study with sector × municipality fixed effects and month fixed effects. Robustness with sector-specific linear trends.

## Data Source and Fetch Strategy

**Primary:** Latvia Enterprise Register Open Data
- URL: `https://dati.ur.gov.lv/register/register.csv`
- 482,077 records, 121MB, daily updates
- Fields: regcode, name, regtype_text, type_text, registered (date), terminated (date), region, city, atvk (municipality code)
- Smoke-tested and confirmed working

**Supplementary:** Statistics Latvia PX-Web API
- Industry-level firm counts by NACE division and municipality (annual)
- Confirms sector classifications and provides population denominators

**Challenge:** The Enterprise Register has firm type (SIA, AS, IK) and municipality, but no NACE sector code directly. We must classify firms into treated/control sectors using: (a) firm type (SIA is typical for shell companies), (b) the name field for keyword classification, or (c) supplementary Statistics Latvia data for NACE-level aggregates.

**Fallback if NACE unavailable at firm level:** Use Statistics Latvia's published sector-municipality-year aggregates as the primary unit, with Enterprise Register providing monthly dissolution timing within broad categories.

## Robustness Checks

1. Placebo reform dates (2016, 2019) — should show no effect
2. Riga vs non-Riga (treatment should concentrate in Riga)
3. Firm age heterogeneity (young shells vs established firms)
4. Leave-one-sector-out to check no single sector drives results
5. Firm type heterogeneity (SIA/LLC vs AS/joint stock vs IK/individual)
6. Alternative outcome: new firm registrations (should also decline in treated sectors)
