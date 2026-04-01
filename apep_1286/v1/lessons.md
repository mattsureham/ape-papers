## Discovery
- **Idea selected:** idea_1883 — Alice Corp eligibility shock with within-TC art-unit variation
- **Data source:** USPTO DS-API (oa_rejections/v2, oa_actions/v1) — BigQuery ADC wasn't configured, so pivoted to the developer API with count queries
- **Key risk:** Tautological treatment definition (shock defined from outcome change)

## Execution
- **What worked:** The within-TC heterogeneity is real and massive (range -8.8pp to +54.7pp). Cross-TC DiD provides clean identification. §103 substitution effect is a genuinely novel finding.
- **What didn't:** Continuous-treatment DiD is mechanically R²=1 when treatment IS the outcome change. Had to reframe around binary comparison, cross-TC, and non-§101 outcomes. Bulk API download too slow (~2 min per quarter, 20 quarters); count queries also slow (~30s per art unit for quarterly data).
- **Review feedback adopted:** All three reviewers caught the tautological treatment — rewrote to lead with cross-TC and binary results. Added explicit limitations section about missing applicant-level outcomes. Toned down causal claims to "documents heterogeneity."
