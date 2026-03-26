# Research Plan: The Formalization Dividend — Romania's Construction Tax Holiday and the Shadow Workforce

## Research Question

Did Romania's 2019 comprehensive construction-sector tax exemption (Law 18/2018) — eliminating income tax, slashing health contributions, and mandating a sector-specific minimum wage — formalize employment in a sector notorious for undeclared work?

## Policy Background

Romania's Law 18/2018 (effective January 1, 2019) created one of the most generous sectoral tax holidays in recent European history, targeting construction exclusively (CAEN codes 41-43):

- **Income tax:** 16% → 0% (full exemption)
- **Health insurance contribution:** 10% → 3.5%
- **Sectoral minimum wage:** 1,900 RON → 3,000 RON (+58%)

All other sectors retained the standard tax regime. The law was passed in December 2018 and took effect January 1, 2019 — a sharp, well-defined treatment date.

## Identification Strategy

**Design:** Sector-level Difference-in-Differences

- **Treated:** Construction sector (CAEN 41-43)
- **Control:** Manufacturing, trade, transportation, services, accommodation, ICT, and other sectors
- **Pre-period:** 2015–2018 (4 years annual; quarterly if available)
- **Post-period:** 2019–2023 (with COVID controls for 2020+)
- **Treatment timing:** January 1, 2019 (single, sharp date — no staggering)

Since treatment timing is common (all construction firms treated simultaneously), standard TWFE DiD is appropriate. No need for staggered estimators.

**Key parallel-trends argument:** Construction and non-construction sectors should follow similar wage and employment trends absent the tax reform. 16 pre-quarters provide strong trend evidence.

**Robustness:**
1. **Triple-difference:** Construction × formal (vs. informal) × post-2019, to isolate the formalization channel
2. **EU construction demand control:** Eurostat construction production index as a demand shifter to separate tax-induced supply effects from business-cycle demand
3. **Placebo sectors:** Test whether non-eligible sectors near construction (e.g., real estate, architecture) show spillover
4. **COVID controls:** Include 2020 COVID dummies; show results hold in 2019-only window

## Expected Effects and Mechanisms

**Primary channel:** The combined tax cut (>12pp) dramatically reduces the cost of formal employment relative to informal. Firms should shift workers from undeclared to declared status (extensive margin formalization).

**Predictions:**
1. Formal employment in construction rises relative to control sectors (positive, potentially large)
2. Gross wages in construction rise (the minimum wage floor was raised 58%)
3. The formalization effect should be largest in regions with high pre-reform informality

**Ambiguity:** If construction firms were already formal, the tax cut may simply raise profits without changing formalization. The magnitude of the effect reveals the answer.

## Primary Specification

```
Y_{st} = α + β(Construction_s × Post_t) + γ_s + δ_t + ε_{st}
```

Where:
- Y = log formal employment, log average gross wage
- s = sector, t = year (or quarter)
- Construction_s = 1 for CAEN 41-43
- Post_t = 1 for 2019+
- γ_s = sector fixed effects
- δ_t = time fixed effects

Standard errors clustered at the sector level (few clusters → will supplement with wild cluster bootstrap and randomization inference).

## Data Sources

### Primary: Romania INS (National Institute of Statistics)
- **Tempo Online database:** https://insse.ro/cms/en/content/tempo-online
- **Variable:** Average gross nominal monthly wages by sector (SOM101E or equivalent)
- **Coverage:** 2010–2024, quarterly/annual, by NACE sector
- **Access:** Public, no API key required

### Secondary: Eurostat
- **Employment by NACE sector:** `nama_10_a64_e` (annual) or `lfsq_egan2` (quarterly LFS)
- **Construction production index:** `sts_copr_q` (for demand control)
- **Access:** SDMX API, no key required

### Tertiary: Polish BDL (for cross-country placebo)
- Romania-only analysis is primary; if Romania data is rich enough, no need for cross-country extension

## Data Fetch Strategy

1. Query INS Tempo for sector-level wage and employment data (2010–2024)
2. Query Eurostat for Romanian employment by NACE sector (backup/cross-validation)
3. Query Eurostat for construction production index (demand control)
4. If INS Tempo API is difficult, fall back to Eurostat as primary source (confirmed available via SDMX)

## Risk Assessment

| Risk | Mitigation |
|------|-----------|
| INS Tempo API difficult to parse | Use Eurostat as backup (confirmed) |
| Few clusters (sectors) | Wild cluster bootstrap + randomization inference |
| COVID confound in 2020 | 2019-only clean window; COVID dummies; manufacturing as within-COVID placebo |
| Pre-trends failure | 16 pre-quarters provide strong test; HonestDiD bounds |
| Construction boom explanation | EU construction production index as demand control |
