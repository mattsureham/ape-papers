## Discovery
- **Idea selected:** idea_1923 — MSA boundary redefinitions create mechanical CRA reclassification, a clean natural experiment for mortgage lending
- **Data source:** CFPB Data Browser API (HMDA loan-level data, 2018-2024) — state-by-state download with rate limiting issues; CA/TX/FL too large for API
- **Key risk:** Single post-treatment year (2024), small treated sample (205 tracts)

## Execution
- **What worked:** The "denominator shuffle" identification is clean — pre-trends are remarkably flat (F=0.26, p=0.93). The CFPB API provides rich post-2018 HMDA fields including rate spread, which enabled the pricing finding.
- **What didn't:** FFIEC census flat files are behind Cloudflare protection (403 errors), so we couldn't directly decompose numerator vs denominator changes. The original placebo design (comparing tracts far from 80% threshold) captured real income differences rather than testing the CRA mechanism — switched to temporal placebo.
- **Review feedback adopted:** Fixed text-table inconsistency (abstract cited 0.13pp from asymmetric spec but main table shows 0.082pp pooled). Redesigned placebo from cross-sectional income comparison to temporal placebo (fake 2022 treatment date). Reviewers also flagged need to separate CRA-regulated from nonbank lenders — important for V2 but out of scope for V1.
- **Key insight:** CRA reclassification doesn't change lending volume — it changes pricing. Gained-LMI tracts see 0.13pp higher rate spreads, suggesting banks serve marginal borrowers at higher rates to satisfy CRA requirements. This reframes the CRA debate from "does it expand credit?" to "how does it reshape credit composition?"
