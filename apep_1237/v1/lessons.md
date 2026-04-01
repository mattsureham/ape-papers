## Discovery
- **Idea selected:** idea_0368 — HBCU PLUS loan shock as anchor institution natural experiment
- **Data source:** IPEDS DuckDB + QWI Parquet, both on Azure. IPEDS required local download (1.2GB DuckDB file can't be ATTACH'd from Azure). QWI wildcard query fast and reliable after connection string fix.
- **Key risk:** Only 74 treated counties with 20 state clusters — small-sample inference matters

## Execution
- **What worked:** Single national shock date gives the cleanest possible event study — no staggered timing complications. Pre-trends are unambiguously flat. The continuous treatment intensity (HBCU enrollment share) gives precision that the binary indicator lacks.
- **What didn't:** Wild cluster bootstrap failed due to fixest `^` notation incompatibility with fwildclusterboot. Jackknife serves as substitute. The first-stage regression required careful thought — naive enrollment % change doesn't load on the share variable because all HBCUs shrank ~11% regardless of county size. The correct first stage is enrollment *change scaled by county employment*.
- **Review feedback adopted:** Added explicit first-stage regression (Panel A of Table 4), restricted control group to HBCU-hosting states, employment-weighted specification, and text explaining why aggregate significance coexists with imprecise sector-level estimates.

## Key Finding
The most interesting result is not the employment decline itself but the **persistence**: the 2014 partial policy reversal produces no recovery. Employment effects deepen from β = -0.018 (shock period) to β = -0.034 (reversal period). This suggests HBCU revenue shocks trigger irreversible community damage — hysteresis in anchor institution labor markets.
