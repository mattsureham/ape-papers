## Discovery
- **Idea selected:** idea_0704 — Switzerland's 2009 Tatbeweis reform abolishing the conscience test for civilian service; sharp overnight policy change with 312% admissions increase
- **Data source:** BFS BESTA quarterly employment (PXWeb API) + ZIVI administrative statistics — BESTA required exploring German-language API endpoints; STATENT (canton-level) only starts 2011
- **Key risk:** Only 3 treated sectors (NOGA 86-88), creating fundamental power limitation for inference

## Execution
- **What worked:** The event study produces textbook-clean pre-trends with monotonically growing post-treatment effects; the BFS PXWeb API delivers reliable, high-frequency sector-level data once the correct cube IDs are found
- **What didn't:** Sector-specific linear trends absorb the effect because the treatment ramps up gradually (stock-building dynamic looks linear); canton-level deployment data unavailable for pre-2011, preventing the triple-difference design promised in the manifest
- **Review feedback adopted:** Softened multiplier language (10:1 is not a causal multiplier but total differential growth); made permutation inference the primary statistical test; added formal pre-trends joint F-test; acknowledged canton-level extension as future work; noted sector-level heterogeneity from LOO analysis
