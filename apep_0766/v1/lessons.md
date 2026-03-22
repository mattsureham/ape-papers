## Discovery
- **Idea selected:** idea_0043 — Multi-cutoff RDD on Brazilian council size thresholds and infant mortality. Chosen because multi-cutoff RDDs are the #1 strategy in tournament rankings.
- **Data source:** IBGE Sidra API (population), BigQuery basedosdados (DATASUS SIM/SINASC vital statistics, TSE election results). IBGE API required debugging column names (D1C not "Município (Código)"). BigQuery was the key unlock for DATASUS data — DATASUS direct CSV downloads failed.
- **Key risk:** Bunching at 15K threshold (McCrary p=0.003) and treatment timing mismatch between annual population and 4-year election cycles.

## Execution
- **What worked:** BigQuery basedosdados for Brazilian administrative data is excellent — SIM microdata (703K infant deaths), SINASC (52.6M births), and TSE election results all accessible. Multi-cutoff design provides internal replication across 5 thresholds. rdrobust R package worked seamlessly.
- **What didn't:** DATASUS direct CSV/FTP downloads all failed. IBGE Sidra vital statistics tables don't exist at municipal level (table IDs were wrong). Initial TSE query used candidacy registration status ("deferido") instead of election results ("eleito") — needed the separate `resultados_candidato_municipio` table.
- **Review feedback adopted:** All three reviewers flagged missing first stage on actual council size — added TSE election data verification (first stage = 0.35 seats, p<0.001). Added three more balance tests (birthweight, LBW, prenatal). Ran clean-cutoff specification excluding manipulated thresholds. Toned down "hard null" rhetoric.
