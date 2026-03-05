## Discovery
- **Policy chosen:** Welsh 20mph default speed limit (September 2023) — uniquely clean devolved-nation DiD, massive political salience, zero rigorous causal evaluations despite descriptive 28% casualty reduction
- **Ideas rejected:** UC & crime (already published, d'Este & Harvey 2020/BJC 2023); Flood Re & property (Garbarino & Guin 2024, JORI); rainfall & crime (temporal mismatch 15-min vs monthly); CIAs (no central adoption database); Empty homes premium (limited stagger)
- **Data source:** STATS19 via `stats19` R package (confirmed 2022-2023 download, ~3,300 Welsh collisions/year); HM Land Registry PPD for property values
- **Key risk:** Only 4 Welsh police forces — RI is the appropriate inference procedure (wild cluster bootstrap unreliable with <5 treated clusters per MacKinnon et al. 2023). Partial reversals in 2024 turned out not to attenuate the effect.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT, Grok, Codex pass; Gemini fail on soft concerns)
- **Top criticism:** Property value analysis not causally identified (GPT) — pre-trends visible in quarterly event study
- **Surprise feedback:** The property event study we added per reviewer request actually revealed pre-trends that weakened our own claims — but this was the honest, right thing to report
- **What changed:** Added property event study figure (revealed pre-trends), early/late post-period split (no fade-out), heavily caveated property interpretation throughout, added exposure/traffic limitation, moved RI histogram to appendix, removed redundant severity figure, added Roth (2022) and MacKinnon et al. (2023) citations

## Summary
- **Key lesson:** Always run the event study on secondary outcomes before making strong claims. The property DiD looked clean in levels but the event study revealed pre-trends.
- **What worked:** Devolved-nation DiD is a powerful design; built-in placebos (road type, Scotland, fake date) were convincing to all reviewers
- **What didn't work:** Wild cluster bootstrap failed technically (fwildclusterboot error); property national DiD too coarse for housing markets
- **For future UK papers:** ONS population data at PFA level would enable per-capita specifications; Land Registry + border spatial DiD would improve hedonic identification
