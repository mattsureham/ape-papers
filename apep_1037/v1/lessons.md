## Discovery
- **Idea selected:** idea_1113 — Taiwan CGT round-trip (introduction Jan 2013, repeal Nov 2015)
- **Data source:** TWSE Open API — market-level aggregate + firm-level P/E and institutional flows
- **Key risk:** API data quality; STOCK_DAY_ALL endpoint returned static (non-historical) data, requiring pivot to aggregate TAIEX data

## Execution
- **What worked:** TAIEX aggregate daily data (FMTQIK endpoint) provided clean monthly panel. P/E and institutional flow data provided firm-level cross-sectional evidence. Three-period decomposition (announcement/implementation/repeal) revealed that the volume decline was concentrated in the announcement period.
- **What didn't:** STOCK_DAY_ALL endpoint returned identical data regardless of date parameter — a silent API failure that wasted ~20 minutes. Per-stock daily data (STOCK_DAY endpoint) would take ~4.5 hours for 50 stocks, so I pivoted to aggregate analysis.
- **Key finding surprise:** The paper's story completely reversed from the idea manifest. Expected: "CGT reduces volume, repeal restores it." Found: "Volume recovered during CGT implementation; the disruption was an announcement-period uncertainty shock." Transaction counts told a different story — persistently depressed during CGT, revealing a retail→institutional composition shift.
- **Review feedback adopted:** Added explicit transaction count coefficients to results text; acknowledged China 2015 crash as concurrent event; added absence-of-control-group limitation.
