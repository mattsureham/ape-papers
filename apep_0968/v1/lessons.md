## Discovery
- **Idea selected:** idea_1762 — Administrative contagion through integrated eligibility systems: SNAP recertification intensity destabilizing Medicaid enrollment
- **Data source:** CMS Monthly Enrollment Reports + USDA ERS SNAP Policy Database + KFF IES classification — all public, no API keys needed for core data
- **Key risk:** Whether cross-program administrative spillover could be isolated from confounding state-level policy changes

## Execution
- **What worked:** The interaction design (continuous recertification intensity × binary IES status) cleanly separates the contagion mechanism from the reminder channel. The opposite-sign result in non-IES states (reminder effect) validates the design.
- **What didn't:** CMS enrollment data has duplicate rows (preliminary + final reports). Initial analysis with duplicates inflated the main coefficient 4x (2.38 → 0.63) and made the RI p-value appear significant (0.022 → 0.236). Always deduplicate CMS data.
- **Critical lesson:** ALWAYS check for duplicate reporting periods in CMS administrative data. The Final.Report column distinguishes preliminary from final entries. Failing to deduplicate biases SEs downward and inflates coefficients.
- **Review feedback adopted:** Fixed observation count inconsistency (the #1 issue all three reviewers flagged). Honest reporting of RI p-value (0.236) and pre-COVID attenuation (p = 0.28). Clarified the enrollment-vs-claims outcome pivot.
