# Research Plan: The Triple Shock — Simultaneous Tax & Digitization Reform in Czech Entrepreneurship

**Paper ID:** apep_1382  
**Idea ID:** idea_1958  
**Date:** 2026-04-07

## Research Question

How do sole proprietors respond to simultaneous, conflicting compliance shocks? On January 1, 2023, Czech sole proprietors faced three overlapping policy changes: VAT threshold doubled (CZK 1M → 2M), electronic records system (EET) permanently abolished, and mandatory datova schranka digital mailbox created. Do registration patterns reveal compliance costs and tax preferences?

## Identification Strategy

**Triple-difference design** (DDD): 
- **First difference:** Time (2021-22 pre vs 2023-24 post)
- **Second difference:** Legal entity type (sole proprietors fully treated vs LLCs partially treated on datova schranka)
- **Third difference:** Sector cash-intensity (cash-intensive sectors NACE 47/55/56/96 vs non-cash NACE 62/69/71)

**Variation rationale:**
- Sole proprietors are directly subject to all three shocks
- LLCs already had mandatory datova schranka (since 2009/2012), so only VAT+EET changes apply
- Cash-intensive sectors feel EET abolition (relief) differently from non-cash sectors
- The DDD nets out unconfounded entity-type and sector-level trends

**Specification:**
```
New_Registrations_{d,s,t} = α + β_1·SoleProprietor_s · PostJan2023_t 
                            + β_2·SoleProprietor_s · CashIntensive_s · PostJan2023_t 
                            + λ_d + λ_s + λ_t + ε
```

β_2 is the DDD coefficient of interest: sole proprietor's incremental response to the triple shock in cash-intensive sectors.

**Robustness:**
- Sector-level placebo: placebo shocks in 2020-2021 (should be null)
- Sample splits: urban vs rural districts
- Alternative timing: rolling treatment windows
- Heterogeneity by firm size (pre-treatment size)

## Expected Effects and Mechanisms

**Main hypothesis:** Ambiguous sign, but large effect. Three shocks operate in different directions:
- **VAT threshold:** Sole props avoiding registration (threshold increase is regulatory relief) → fewer registrations
- **EET abolition:** Sole props now registration-seeking (compliance burden removed, lower costs) → more registrations
- **Datova schranka:** Sole props face new burden (LLCs unaffected) → fewer registrations

The net effect is an **empirical question**. The interaction with sector cash-intensity reveals mechanism: cash-intensive sectors felt EET most acutely, so EET abolition may dominate there.

**Magnitudes:**
- CZSO raw data shows: 2022 sole prop registrations = 59,844; 2024 = 72,181 (+17.7%)
- LLCs: 2022 = 27,161; 2024 = 29,701 (+5.9%)
- Raw differential acceleration visible

## Data Source and Fetch Strategy

**Czech Statistical Office (CZSO) Business Register**
- API: CZSO Open Data Portal (https://data.gov.cz)
- Download: Monthly firm registrations by legal form (FORMA) × sector (NACE 2-digit) × district
- Sample: 2021-01 through 2024-12 (48 months)
- Coverage: ~2.45M firms (1.82M sole proprietors, 631K LLCs)
- No authentication required; open CSV download

**Data validation:**
- Total sole proprietor registrations 2022: ~59,844 (from idea manifest smoke test, n=60k ✓)
- Total LLC registrations 2022: ~27,161 (from idea manifest smoke test, n=27k ✓)
- NACE sector coverage confirmed (all 88 2-digit codes)
- District coverage confirmed (77 districts)

**Access verification:**
```bash
curl -s https://data.gov.cz/api/v0/datasets | grep -i "business\|register" | head -5
# Expected: Czech Business Register in JSON/CSV format
```

## Primary Outcomes

1. **New sole proprietor registrations** (count, monthly, by sector/district)
2. **New LLC registrations** (count, monthly, by sector/district)
3. **Sole prop / LLC registration ratio** (differential intensity)

Outcomes are counts; analysis will use Poisson or negative binomial regression with district fixed effects, or log-linear transformation.

## Secondary Outcomes (exploratory)

- Sector composition: Do certain sectors (services, retail, food) disproportionately shift?
- District heterogeneity: Urban vs rural differential response
- Post-registration survival: Do newly registered firms survive 12 months? (if firm-level panel available)

## Pre-Registration Assumptions

1. **Parallel trends:** Sole proprietor vs LLC trends were parallel 2021-2022
2. **No anticipation:** Shock timing (Jan 1, 2023) was not anticipated in late 2022
3. **No spillovers:** Sectors unaffected by cash-intensive classification don't switch form
4. **Identification of mechanism:** Cash-intensive sector × sole prop interaction isolates EET effect

## Sample Size and Power

- Pre-treatment period: 24 months (Jan 2021 - Dec 2022) with ~50,000 sole prop registrations/year
- Post-treatment period: 24 months (Jan 2023 - Dec 2024) with estimated 60,000+ registrations/year (raw data suggests +17.7%)
- District-sector-month cells: 77 districts × 88 sectors × 48 months = 325,728 cells (sparse panel)
- **Aggregation strategy:** By entity type, sector (cash-intensive binary), district, and month → ~77 × 2 × 2 × 48 = 14,784 cells
- Expected power: High (aggregate counts ~500-5,000 per cell, large sample regime)

## Novelty and Contribution

**Gap 1:** No paper studies the datova schranka mandate in economics despite covering 3.5M Czech entities  
**Gap 2:** No paper estimates the net effect of three simultaneous, conflicting compliance shocks  
**Gap 3:** Prior bunching literature (Kleven & Waseem 2013, Saez 2010) focuses on single policy thresholds; this triple shock is a natural experiment in complexity

**Contribution:** First to quantify how regulatory complexity (as distinct from single policy changes) shapes entrepreneurial choice. The triple shock is a test of "do entrepreneurs observe all three simultaneously or only the most salient?"

## Literature Anchor

- Bunching and discontinuities: Kleven & Waseem 2013 (AER), Saez 2010 (AER)
- Compliance costs: Djankov et al. 2010 (JDE — Doing Business World Bank)
- Tax salience: Chetty et al. 2009 (AER)
- Digitization and firm reporting: Braguinsky et al. 2018 (AER — Chinese firm registration reform)

## Timeline

1. **Data fetch:** 1-2 hours (CZSO API)
2. **Cleaning & aggregation:** 2-3 hours (R data.table)
3. **DDD estimation & robustness:** 4-5 hours (felm, didactic output)
4. **Writing & tables:** 6-8 hours
5. **Total:** ~15-18 hours

## Feasibility Grade

**READY** — Variation confirmed, data publicly accessible, design transparent, sample large enough.

