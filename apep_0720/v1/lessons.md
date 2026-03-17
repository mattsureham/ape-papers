## Discovery
- **Idea selected:** idea_0184 — Sports betting revenue cannibalization. Chose for clear fiscal stakes, clean staggered DiD, and reliable Census STC data.
- **Data source:** Census STC flat files (2012-2022). File naming changed across eras — needed 3 different patterns to download all 11 years.
- **Key risk:** T11 (amusements) bundles sports betting with existing gambling taxes — increase is partly mechanical.

## Execution
- **What worked:** The staggered DiD is clean: 26 treated states, 13 controls, 6-7 pre-periods. CS-DiD and TWFE agree (66-74 log points). Placebos (sales tax, tobacco) are precisely estimated zeros. Pari-mutuel (T20) shows no decline — no evidence of horse racing cannibalization.
- **What didn't:** The T11 category is too aggregated. All three reviewers independently flagged that T11 mechanically includes sports betting tax, so its increase doesn't directly test cannibalization of lottery/casino components. Would need NASPL lottery data (not available in unified panel) to isolate the substitution channel.
- **Review feedback adopted:** Reframed the T11 finding to acknowledge mechanical inclusion. Added transparent limitations about the composition problem. The paper's contribution is establishing that TOTAL gambling revenue expanded, while acknowledging it cannot decompose within-T11 substitution.
