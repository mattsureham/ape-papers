# Reviewer Response Plan

## Key Concerns Across Reviewers

1. **Lack of pre-period for early-treated lines** (GPT R1, R2, Gemini) — 5/8 lines started construction before 2020. Cannot test parallel trends for these cohorts.
2. **Within-commune differential trends** (GPT R1) — Commune FE don't guarantee within-commune spatial parallel trends.
3. **CS-DiD is too noisy** (GPT R1, R2) — The CS estimate is imprecise and does not resolve TWFE concerns.
4. **Treatment timing coarseness** (GPT R1) — Line-segment level timing ignores station-level variation.
5. **L14/L15/L16/L17 suspicious SE** (Gemini) — Very small SE for interchange stations.

## Actions

1. **Strengthen limitations discussion.** Add explicit acknowledgment that pre-2020 data would strengthen identification. Reframe contribution as documenting construction disamenity conditional on the spatial DiD design, not as causal proof.
2. **Temper causal language.** Reduce "causal" claims to "suggestive evidence consistent with construction disamenity."
3. **Caveat CS-DiD more strongly.** Present TWFE as primary, CS as suggestive only.
4. **Acknowledge within-commune trend limitation.** Add discussion of why near-station sub-areas may differ.
5. **Prose improvements** from Gemini prose review.
