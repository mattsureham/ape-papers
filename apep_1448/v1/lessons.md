## Discovery
- **Idea selected:** idea_2518 — Medicare Advantage 3.75 star rating threshold RDD; chosen for clean design, $12.7B stakes, and public data
- **Data source:** CMS Star Ratings Data Tables (2015-2026) — URLs required scraping the CMS performance data page; obvious URL patterns all returned 404s
- **Key risk:** Continuous summary score not published directly; had to reconstruct from measure-level stars

## Execution
- **What worked:** Reconstructed continuous summary score from measure-level stars (correlation 0.92 with displayed rating). Clean McCrary test (p=0.72), perfect covariate balance. The score dynamics finding (3.5-star plans improve 6.4pp more than 4-star plans) is the strongest result.
- **What didn't:** The original plan was to study benefit pass-through, but the near-zero first stage (the CAI blurs the threshold mapping) forced a pivot to studying the gaming-resistance properties of the rating system itself. This turned out to be a more interesting paper.
- **Review feedback adopted:** Pending reviews.
