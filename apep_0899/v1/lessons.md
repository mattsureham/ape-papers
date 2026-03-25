## Discovery
- **Idea selected:** idea_0822 — Finland's 2021 compulsory education extension from 16 to 18
- **Data source:** Statistics Finland PxWeb API — free, well-structured, 18 years of transitions data
- **Key risk:** Short post-period (3 years) and small cluster count (20 regions)

## Execution
- **What worked:** DDD with vocational/general placebo was clean — general education track confirmed mean reversion, validating the design. PxWeb API delivered exactly the data promised in the manifest.
- **What didn't:** The "Unknown" region is noise but needed for the 20-unit threshold. PxWeb API required careful query formatting (list() not c() for values, batch splitting for large queries).
- **Review feedback adopted:** Added justification for intensity measure choice (unemployment vs dropout), noted DDD event study pre-trend validation, expanded welfare discussion of student continuation effect.
