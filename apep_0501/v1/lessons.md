## Discovery
- **Policy chosen:** Swiss municipal mergers — clean staggered adoption, excellent BFS data, novel direct democracy angle
- **Ideas rejected:** MuKEn energy codes (only 8 cantons); HarmoS concordat (SAKE too small); Cantonal minimum wages (only 5); E-voting (data access uncertain)
- **Data source:** BFS PXWeb API (referendum) + BFS mutations API (merger timeline). Debugging: Windows-1252 encoding, current-boundary retroactive data
- **Key risk:** Pre-existing trends in merging communes (confirmed as Ashenfelter's dip)

## Review
- **Advisor verdict:** 3 of 4 PASS (Grok, Gemini, Codex pass; GPT fails on control group nuance)
- **Top criticism:** Dose-response used TWFE while paper argued TWFE is contaminated
- **Surprise feedback:** Stacked DiD dose-response REVERSES sign (from +5.14 to -5.18), changing mechanism from identity-loss to free-riding
- **What changed:** Re-estimated dose-response in stacked framework, added ±3yr window, strict controls, canton-clustered SEs

## Summary
- **Key lesson:** TWFE contamination extends beyond ATT to mechanism inference — compound bias problem
- **Data insight:** BFS PXWeb uses current boundaries retroactively; mutations API is excellent for merger timeline
- **Methodological:** Narrower windows (±3yr) produce STRONGER effects, consistent with pre-trend contamination attenuating wider windows
