## Discovery
- **Idea selected:** idea_0650 — First cross-border application of judge-leniency IV (remittances, not domestic outcomes)
- **Data source:** Deportation Data Project processed EOIR parquet (317 MB vs 4.26 GB raw); World Bank WDI API
- **Key risk:** Aggregate total remittances (all sources) vs bilateral US flows — introduces measurement error

## Execution
- **What worked:** LOO judge leniency instrument is extraordinarily strong (F=50). Data processing pipeline clean — 10.6M cases → 3.76M resolved → 622 country-year obs across 29 countries.
- **What didn't:** The 2SLS effect is null (and negative). The "deportation dividend" hypothesis doesn't hold at the aggregate level — marginal asylees are too few relative to diaspora to move country-level remittances.
- **Review feedback adopted:** (1) Added back-of-envelope quantifying 1,035 additional asylees per SD vs 1-10M diaspora; (2) Softened "precisely estimated null" to "bounded null"; (3) Added family reunification mechanism to explain negative sign; (4) Discussed measurement attenuation from US share of total remittances.

## Key Takeaway
Judge-leniency IVs work powerfully across borders (strong first stage) but the aggregate remittance outcome is too noisy to detect effects from marginal asylum decisions. Future work should use bilateral US-to-country remittance data or individual-level outcomes.
