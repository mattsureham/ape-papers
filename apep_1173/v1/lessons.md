## Discovery
- **Idea selected:** idea_1894 -- PTZ zone reclassification bunching. Chosen because bunching is the highest-performing method in tournament (avg 22.1) and DVF gives universe coverage.
- **Data source:** DVF from data.gouv.fr (3 years, 2.9M transactions) + zone ABC classification. All open data, no API keys needed. Download was straightforward.
- **Key risk:** Post-reclassification VEFA sample too thin for a clean causal test. Only 6 months of post data + VEFA is 2.2% of transactions = very few treated observations.

## Execution
- **What worked:** Cross-sectional bunching at PTZ caps is sharp and convincing (6x VEFA-resale differential). Placebo caps show zero excess mass. The zone reclassification file from data.gouv.fr had exactly the right format (old/new zones for all 865 communes). The France country skill's data catalog was accurate.
- **What didn't:** The difference-in-bunching causal test was underpowered for VEFA specifically (97 post-treatment transactions). The all-transactions triple-diff was significant but less cleanly interpretable. Dose-response across reclassification magnitudes was also underpowered.
- **Review feedback adopted:** Added explicit discussion of power limitations, buyer-sorting vs developer pricing distinction, clarified triple-diff specification (lower-order terms), added footnote on September 2025 zone reversal logic.
- **Key lesson:** For bunching papers using reclassification events, ensure enough post-treatment time for the rare transaction type (VEFA). A full year of post data would have quadrupled the sample.
