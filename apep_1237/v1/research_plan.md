# Research Plan: apep_1237

## Research Question
Does the 2012 Parent PLUS loan credit-standard tightening — which caused an abrupt 11% enrollment decline at HBCUs — reduce employment in HBCU-host counties? What is the local employment multiplier of HBCU revenue shocks, and which sectors transmit the effect?

## Mechanism
The "Credit Check Tax": a federal financial-eligibility rule change acts as an implicit tax on anchor institutions serving disadvantaged communities. When PLUS loan denial rates spike, HBCU enrollment and revenue fall. Institutions cut staff (direct effect), reduced student spending contracts local service-sector employment (indirect/multiplier effect). The 2014 partial policy reversal tests whether the community damage is reversible.

## Identification Strategy
**Event-study DiD with continuous treatment intensity.**

- **Event:** September 2012 Parent PLUS loan credit-standard tightening (single national date)
- **Treatment intensity:** Pre-shock (2010-11) HBCU enrollment share of county employment (continuous)
- **Treated counties:** ~80 counties hosting at least one HBCU
- **Control counties:** ~3,000+ counties without HBCUs (matched on demographics/economics)
- **Event window:** 2008Q1–2016Q4 (16 pre-quarters, 16 post-quarters)
- **Fixed effects:** County FE, year-quarter FE, state × year-quarter FE
- **Clustering:** State level (20 HBCU-hosting states)
- **Estimand:** β in Y_{ct} = α_c + γ_{s(c),t} + Σ_k β_k · (HBCUShare_c × 1{t=k}) + ε_{ct}

## Expected Effects
- **First stage:** IPEDS enrollment at HBCUs declines ~11% (2011 peak to 2015 trough)
- **Direct effect:** HBCU institutional employment (IPEDS eap) declines proportionally
- **Reduced-form:** QWI total employment in HBCU counties falls relative to non-HBCU counties after 2012
- **Sectoral:** Education (NAICS 61) first, then accommodation/food (72), retail (44-45) through spending multiplier
- **Reversal:** Partial recovery visible after 2014 policy relaxation

## Primary Specification
```
log(Emp_{ct}) = α_c + γ_{st} + Σ_{k≠-1} β_k · (HBCUShare_c × D_k) + X_{ct}'δ + ε_{ct}
```
where k indexes quarters relative to 2012Q3, HBCUShare_c is continuous treatment intensity, and γ_{st} are state-by-quarter FEs.

## Exposure Alignment
The treatment variable (pre-shock HBCU enrollment share of county employment) directly maps to the affected population: HBCU students and staff. The PLUS loan tightening operates through enrollment → institutional revenue → institutional employment → local spending multiplier. Counties with higher HBCU enrollment share receive a proportionally larger shock to their local economy. The outcome (county-level QWI employment) captures both the direct institutional employment channel and the indirect spending multiplier. The unit of analysis (county-quarter) matches the treatment unit because the policy operates at the national level and cross-sectional variation comes from the county-level intensity of exposure. We verify this alignment with a first-stage regression showing that enrollment-per-employment declines are proportional to the exposure measure (p = 0.006).

## Robustness
1. Binary treatment (HBCU county yes/no) instead of continuous
2. Wild cluster bootstrap (20 state clusters)
3. Matched control group (CEM on pre-period county characteristics)
4. Leave-one-state-out jackknife
5. Placebo outcomes: agriculture (NAICS 11), mining (21) — sectors with no HBCU spending channel
6. HonestDiD sensitivity bounds for pre-trend violations

## Data Sources
1. **IPEDS** (Azure: `raw/ipeds/ipeds.duckdb`): Institution-level enrollment (effy), employment (eap), financial (sfa), characteristics (hd with hbcu flag and county_fips)
2. **QWI** (Azure: `derived/qwi/rh/ns/*.parquet`): County × quarter × industry employment, earnings, hiring, separations. 51 states, 2001-2025.
3. **QCEW** (if needed): County-level federal employment share for controls

## Fetch Strategy
1. Query IPEDS DuckDB on Azure for HBCU institutions → county mapping, enrollment trends, institutional employment
2. Download QWI Parquet files from Azure for HBCU-hosting states + control states
3. Merge on county FIPS × year-quarter
4. Construct treatment intensity = Σ(HBCU enrollment in county c, 2010-11) / (QWI total employment in county c, 2010-11)
