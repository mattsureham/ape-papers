## Discovery
- **Idea selected:** idea_0966 — Swiss CO2 levy escalations and building decarbonization. Chose for multi-dose design paralleling tournament winner (apep_0492), open Swiss data, and genuinely unstudied technology-switching channel.
- **Data source:** BFS Gebäude- und Wohnungsstatistik (GWS) — canton-level dwelling heating shares for 2000 + 2021-2024. BFS PXWeb API only had census years; found the key Excel files through BFS DAM API (asset 36158377).
- **Key risk:** Only 5 time periods (21-year gap between 2000 and 2021). No intermediate annual data available through public APIs.

## Execution
- **What worked:** The gas switching result (β=0.326, p=0.002) is robust and surprising — fossil-to-fossil substitution was not the expected finding. Placebo tests (electricity, wood) cleanly confirm the CO2 levy channel. Leave-one-out stability is excellent.
- **What didn't:** Heat pump result is marginal (p=0.056 in recent subsample). The 21-year data gap prevents event-study-style parallel trends testing. BFS API access was extremely difficult — spent 30+ minutes before finding the right download path.
- **Review feedback adopted:** Fixed economic magnitude interpretation (removed the 24pp overstatement), strengthened limitations discussion (added parallel trends caveat, Buildings Programme confounding, inference with few clusters), tempered conclusion.
