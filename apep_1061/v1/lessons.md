## Discovery
- **Idea selected:** idea_0363 — Polish abortion ruling with border-distance DiD. Selected for first-order welfare question and clean uniform shock with spatial variation. Two prior ideas (FEMA lag, Swiss civilian service) blocked by existing work.
- **Data source:** Eurostat demo_r_find2 (NUTS2 TFR) + demo_r_gind3 (NUTS3 CBR). API worked perfectly via `eurostat` R package. Also fetched GDP, unemployment, population controls.
- **Key risk:** Small treatment count (17 voivodships) and tiny restricted margin (1,100 legal abortions out of 340,000 births).

## Execution
- **What worked:** The distance construction was clean — 47 to 502 km range provides strong cross-sectional variation. The German vs. Czech decomposition revealed a mechanism-matched asymmetry. Region-specific trends robustness was straightforward.
- **What didn't:** Wild cluster bootstrap failed (fwildclusterboot version incompatibility). Pre-trends at t-2 and t-3 complicated the event study interpretation. The MDE calculation revealed fundamental underpoweredness.
- **Review feedback adopted:** Added MDE/power arithmetic (the paper's strongest insight — MDE is 6.6× the max possible effect), region-specific linear trends (pre-trends don't drive the null), improved framing of the null as an arithmetic impossibility rather than a negative finding.
- **Key lesson:** When the restricted policy margin is tiny relative to aggregate outcomes, a null is mechanically guaranteed regardless of design quality. Future work on this setting needs individual-level or cross-border transaction data, not voivodship-level fertility rates.
