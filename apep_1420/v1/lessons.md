## Discovery
- **Idea selected:** idea_2318 — CMS CC/MCC reclassification and hospital treatment intensity
- **Data source:** CMS Medicare Inpatient Hospitals PUF (data.cms.gov) — direct CSV download URLs required catalog lookup; standard API patterns don't work
- **Key risk:** Charges as proxy for treatment intensity (chargemaster prices, not costs)

## Execution
- **What worked:** DRG triplet construction from description parsing; within-triplet variation is clean and well-powered (93K obs, 87 triplets, 2,650 hospitals)
- **What didn't:** CMS data API URLs are not guessable — required machine-readable catalog lookup (data.json). OpenRouter API key expired during review phase.
- **Review feedback adopted:** Reviews could not run (API auth failure). No feedback to incorporate.
- **Key finding:** Coding dividend is small (~6%). Payment changes pass through almost 1:1 to charges. Surgical DRGs show perfect pass-through; medical DRGs slightly less. Null on coding margin.
