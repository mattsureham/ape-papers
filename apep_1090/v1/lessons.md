## Discovery
- **Idea selected:** idea_1732 — SNAP depth-of-stock provision is an "invisible" regulation that escaped Congressional block; strong policy relevance with 2025 proposed increase to 84 items
- **Data source:** CBP (NAICS 445120/445110) for treatment intensity, ACS B22003 for SNAP participation
- **Key risk:** SNAP Retailer Historical Database was inaccessible (ArcGIS token required), forcing pivot to CBP proxy

## Execution
- **What worked:** Clean pre-trends across 5 years; all LOSO estimates negative; effect concentrated in high-poverty counties; county-specific linear trends yielded larger estimate (-0.082) than baseline (-0.058)
- **What didn't:** CBP convenience store share is a noisy proxy for actual SNAP retailer exposure; ACS 5-year rolling window attenuates the treatment signal; main coefficient is imprecise with state×year FE
- **Review feedback adopted:** Toned down claims from "compliance trap is real" to "suggestive"; added county-specific trends robustness; acknowledged proxy limitations prominently; emphasized the finding is a reduced-form test, not a precise causal estimate

## Key Takeaway
When the ideal data source is inaccessible, be transparent about the proxy and calibrate claims accordingly. A well-argued suggestive finding with clean diagnostics is better than overclaiming with noisy data. The fade-out pattern itself (adjustment by 2022) is informative regardless of precision.
