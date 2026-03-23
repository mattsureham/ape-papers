## Discovery
- **Idea selected:** idea_0707 — Eisensee-Stromberg competing-news IV applied to Swiss direct democracy. Selected from random draw of 10 ideas because of sharp institutional variation (referendums scheduled 6+ months ahead), large sample (175K obs), and all-public data.
- **Data source:** swissdd R package (referendum results, 2,117 municipalities) + USGS earthquake API (global M5.0+ earthquakes). Pivoted from GDELT (BigQuery access denied, DOC API rate-limited) to USGS earthquakes as the instrument source.
- **Key risk:** Missing media coverage first stage — can't directly show earthquakes crowd out referendum news.

## Execution
- **What worked:** The language-region variation is the paper's strongest feature. The language-swap placebo reversing sign is the most compelling test. Randomization inference (p=0.031) dramatically strengthened the statistical argument vs. cluster-robust SEs (p≈0.08).
- **What didn't:** GDELT access was blocked on all fronts (BigQuery permissions, DOC API rate limits). This forced a pivot from measuring media coverage directly to a reduced-form earthquake salience instrument. Reviewers correctly identified this as the main weakness.
- **Review feedback adopted:** Added randomization inference (1000 permutations, p=0.031). Strengthened diaspora/exclusion-restriction discussion with three mitigating arguments. Better acknowledged missing first-stage as primary limitation with indirect evidence.
