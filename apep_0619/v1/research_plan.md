# Research Plan: The Innovation Lottery — H-1B Visa Randomization and Firm R&D Investment

## Research Question

Does access to high-skilled immigrant workers causally increase publicly traded firms' R&D investment? We exploit the pure random lottery used to allocate H-1B visas (FY2021–FY2024) as an instrument for firm-level immigration access, matching lottery outcomes to SEC financial filings.

## Identification Strategy

**Instrument:** The H-1B visa lottery is a true randomization — when registrations exceed the 85,000 annual cap, USCIS selects petitions by computer-generated random number. The firm-level win rate (selected/registered) is the instrument for actual H-1B hiring.

**Key parameters:**
- FY2021: 269,424 registrations, 46.2% selection rate
- Among firms with 5+ registrations: N=6,324, mean win rate 48.5%, SD=17.4%
- ~800–1,500 publicly traded firms matchable to SEC EDGAR

**Exclusion restriction:** Conditional on the number of registrations (firm demand for H-1B workers), the lottery outcome is independent of all firm characteristics. Win rate affects financial outcomes only through the hiring channel.

**Estimation:** 2SLS where the first stage is lottery win rate → H-1B petitions filed/approved, and the reduced form is win rate → R&D spending, capital investment, employment. Panel IV exploiting within-firm variation across 4 lottery years.

## Expected Effects and Mechanisms

**Primary channel:** H-1B workers are concentrated in STEM occupations. Firms that win more lottery slots can hire planned STEM workers → maintain/expand R&D programs.

**Predictions:**
1. Higher win rate → higher R&D spending (intensive margin)
2. Effects concentrated in tech-intensive industries (SIC 35-38, 73)
3. Larger effects for firms with higher H-1B dependence (more registrations/employee)
4. Potential effects on employment, revenue, and operating income with lags

## Primary Specification

```
R&D_{i,t+k} = α + β × WinRate_{i,t} + γ × Registrations_{i,t} + δ_i + θ_t + ε_{i,t}
```

Where i indexes firms, t indexes fiscal years, k ∈ {0,1,2} allows for lagged effects, δ_i are firm FEs, θ_t are year FEs. Standard errors clustered at firm level.

## Data Sources and Fetch Strategy

1. **Bloomberg FOIA H-1B Data** (GitHub: BloombergGraphics/2024-h1b-immigration-data)
   - ~210MB, FY2021–FY2024 lottery results at petition level
   - Fields: employer name, FEIN (tax ID), registration status (selected/not selected), fiscal year
   - Aggregate to firm-year: count registered, count selected → win rate

2. **SEC EDGAR XBRL CompanyFacts API**
   - Financial data for ~10,400 publicly traded firms
   - Key variables: ResearchAndDevelopmentExpense, Revenues, Assets, NumberOfEmployees, OperatingIncomeLoss, PropertyPlantAndEquipmentNet
   - Match via employer FEIN (EIN field in SEC submissions API)

3. **Matching strategy:**
   - H-1B data has employer FEIN; SEC submissions have EIN
   - Direct EIN-to-EIN match for publicly traded firms
   - Supplementary fuzzy name matching for unmatched firms

## Robustness Checks

1. **Balance test:** Pre-lottery firm characteristics should be uncorrelated with win rate
2. **Dose-response:** Effects should scale with H-1B dependence (registrations per employee)
3. **Placebo test:** Lottery win rate should not predict outcomes in pre-lottery years
4. **Industry heterogeneity:** Effects should be concentrated in H-1B-intensive sectors
5. **Alternative clustering:** State-level, industry-level
