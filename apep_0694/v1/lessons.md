## Discovery
- **Idea selected:** idea_0072 — Australia HomeBuilder additionality. First causal evaluation of a pandemic-era housing construction subsidy.
- **Data source:** ABS Building Approvals (8731.0) via SDMX API — required understanding of multi-dimensional data structure (VALUE bands, SECTOR codes). No authentication needed.
- **Key risk:** Only 8 states (few clusters for DDD). Mitigated by leave-one-out showing tight range [0.355, 0.568].

## Execution
- **What worked:** The DDD (houses vs apartments) was the key identification breakthrough. It cleanly separates the HomeBuilder effect from the post-pandemic housing boom. The apartment placebo (insignificant during program, significant after) is the most convincing evidence.
- **What didn't:** Initial ITS approach was confounded by the general housing boom (post-program approvals stayed elevated for both houses and apartments). Had to pivot from ITS-only to DDD as the preferred specification.
- **Review feedback adopted:** Reviews pending at time of writing.
