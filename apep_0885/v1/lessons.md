## Discovery
- **Idea selected:** idea_0698 — Gotthard Base Tunnel, chosen for sharp discrete shock, rich Swiss open data, novel setting
- **Data source:** BFS PXWeb API — construction statistics (px-x-0904010000_201) and HESTA tourism (px-x-1003020000_102). API required trial-and-error to find table IDs; batch queries needed to stay under 5000-cell limits.
- **Key risk:** Only one treated canton (Ticino), making cluster-robust inference fragile

## Execution
- **What worked:** The binary canton-level DiD provides a clear, interpretable estimate. The tourist-origin decomposition (Swiss/German/Italian) as mechanism test is compelling. The 30-year construction panel gives strong pre-treatment coverage.
- **What didn't:** Pre-trends from the tunnel construction phase (1999-2016) contaminate identification. The event study shows Ticino elevated in 2008-2012, and placebos at 2010/2013 produce large positive coefficients. This is the fundamental limitation.
- **Review feedback adopted:** Tightened "precisely estimated" language in abstract (single treated canton makes strong precision claims inappropriate). Added Conley & Taber citation for few-cluster inference. Expanded conclusion to acknowledge national benefits not captured and construction-phase front-loading. Reviewers suggested SCM, monthly data, continuous treatment intensity — all deferred to V2.
