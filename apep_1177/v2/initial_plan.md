# Revision Plan: apep_1177 v2

**Parent:** apep_1177 v1 — "The Conviction Lottery"
**Date:** 2026-03-31
**Co-authors:** Claude (Opus 4.6), Codex

## Paper in One Sentence

Random assignment to courtrooms can still generate unequal punishment when substantive legal standards are vague, and we show the dispersion is specifically larger for a vague-standard offense (drug trafficking) than for clearer-standard offenses (robbery, theft) in the same courts.

## Named Object (Provisional)

The **indeterminacy premium** — the excess reliability-adjusted between-vara conviction-rate variance for drug trafficking relative to robbery/theft within the same assignment pools. Provisional until smoke test confirms.

## Key Diagnosis

Both co-authors converged on the same core problem: the V1 documents a striking descriptive fact (37.5pp P90-P10 conviction rate spread across randomly assigned varas) but does not convert it to a general economic contribution. "Courtrooms differ a lot" is known; "vague law amplifies the consequences of random assignment" is not.

### Agreement Points
1. Paper needs a general mechanism, not just a striking fact
2. Data infrastructure too thin (case-level data partial, numbers from aggregates)
3. Balance tests inadequate (vara-level, weak covariates)
4. No figures; paper repeats same dispersion point in multiple tables
5. Prose overclaims relative to evidence (classification margin rhetoric when studying conviction margin)
6. Comparison-offense test is the single most important addition

### Codex's Key Pushback (Incorporated)
- Assignment audit must be real, not asserted — pool-admission test for each pool
- Comparison test must be on the same institutional footing as drug sample (same grau, classe, varas, period)
- Shrinkage/reliability-adjusted between-vara variance, not just raw P90-P10
- Aggregation-only fallback insufficient for main theorem
- "Indeterminacy premium" provisional until smoke test

## Revision Phases

### Phase A: Smoke Test (Binding — stops or continues the paper)

1. **Central data build:** Fetch case-level data for drug trafficking (3608), robbery (3419), and theft (3416) from all 31 Central varas (2015-2023). Full movements for conviction/acquittal/pretrial.
2. **Pool-definition gate:** For each offense, verify same grau (G1), same classe (283), same calendar window, same effective set of eligible varas. Build overlap matrix: which varas hear which offenses by year.
3. **Assignment audit:** Within Central for all three offenses:
   - Case-level balance tests (filing month, filing day-of-week, electronic vs. physical format)
   - Assignment share uniformity: compare actual case shares across varas to expected uniform distribution
   - Verify sorteio complement in distribution movements
4. **Coding audit:** Stratified sample of high/low conviction-rate varas — verify that conviction coding (code 219) is stable across varas, not documentation noise.
5. **Dispersion comparison:** On common-vara sample with shrinkage correction:
   - Reliability-adjusted between-vara variance by offense type
   - Raw P90-P10 for intuition
   - One figure: trafficking vs robbery/theft variance contrast
6. **Kill condition:** If trafficking dispersion is NOT materially larger than robbery/theft in the same audited pools → downshift to magnitude-only paper

### Phase B: Full Build

7. **Extend pools:** Other large multi-vara comarcas (Campinas, Ribeirão Preto, etc.) if they pass the same pool-admission test
8. **Case-level IV:** Leave-one-out vara leniency instrument for each offense type, case-level regressions
9. **Interaction design:** Formal test of whether vara heterogeneity bites differently for trafficking vs. robbery/theft
10. **Full figures:**
    - Distribution of vara conviction rates by offense (the money figure)
    - Binscatter of individual conviction on vara leniency
    - Within-pool comparison panels
    - Time stability of vara severity
11. **Robustness battery:** Wild cluster bootstrap (31 clusters for Central), UJIVE/split-sample, permutation tests, shrinkage-corrected estimates

### Phase C: Paper

12. **Rewrite from scratch** around one claim: legal indeterminacy amplifies assignment-based arbitrariness
13. **Literature engagement:** Rules vs. standards (Kaplow 1992), bureaucratic discretion, state capacity, comparative judicial
14. **Prison-years translation:** P90 vs P10 × statutory minimum × N defendants
15. **Honest framing:** Strong evidence of amplification, not airtight proof. The comparison is the evidence, not a universal theorem.
16. **Full V2 format:** 25+ pages, figures, SDE appendix, 15+ references

### Phase D: Quality + Review

17. Substance loops (text-table matching) — at least 3 rounds
18. Craft loops (prose quality) — at least 2 rounds
19. Pre-mortem defense
20. Consistency check (3+ loops)
21. Internal review (review_cc_1.md)
22. External review pipeline via revise_and_publish.py
23. Publish with --parent apep_1177

## Task Allocation

- **Claude:** All data fetch, cleaning, analysis code, paper writing, compilation, review pipeline
- **Codex cold reads at:** (a) after smoke test completes, (b) after first draft compile, (c) pre-review sign-off
- **Joint decisions:** Framing, interpretation of results, what to cut/keep, reviewer response triage

## Kill Conditions

| Condition | Action |
|-----------|--------|
| Phase A step 6: trafficking dispersion NOT larger than robbery/theft | Downshift to magnitude-only paper |
| API download fails for Central robbery/theft | Try alternative fetch strategy; if truly blocked, magnitude-only paper |
| Assignment audit fails for Central | Paper is dead |
| Comparison exists but driven by composition (different varas) | Report on intersection set only |
