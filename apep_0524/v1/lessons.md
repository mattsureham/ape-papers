## Discovery
- **Policy chosen:** CROWN Act (state hair discrimination bans) — 25 states, staggered 2019-2024, zero economics literature. Combines strong DiD variation with genuinely novel policy and multiple mechanism channels.
- **Ideas rejected:** Cannabis testing bans (only 10-12 states, borderline for DiD), salary history bans (existing Bessen et al. 2020 literature), domestic violence leave laws (can't identify treated population in CPS).
- **Data source:** ACS 1-year PUMS via Census API — large samples (~420K Black respondents/year), occupation/industry detail, state identification. CPS monthly as secondary.
- **Key risk:** COVID overlap with early adopters (CA, NY, NJ all adopted 2019-2020). Mitigated by triple-diff (Black × state × post) which nets out COVID effects common to both races.

## Review
- **Advisor verdict:** 3 of 4 PASS (GPT, Grok, Codex PASS; Gemini FAIL on recurring methodological opinions)
- **Referee verdicts:** GPT MAJOR, Grok MAJOR, Gemini MINOR
- **Top criticism:** The paper claimed a "14% reduction in the gap" for customer-facing occupations, but Blacks are *overrepresented* (47% vs 38%) and the +1.28pp effect *widens* this. All three reviewers flagged this as mathematically wrong and misleading. This was the single most impactful feedback.
- **Surprise feedback:** GPT raised that TWFE triple-diff in staggered settings may inherit negative-weight pathologies even though it's a DDD. This is a novel methodological point — heterogeneity-robust DDD estimators are nascent.
- **CS-DiD vs triple-diff tension:** All reviewers noted the CS-DiD (0.5pp, p=0.36) is less than half the triple-diff (1.28pp, p<0.01). This is NOT just a power issue — likely different estimands. Key lesson: when two estimators disagree in magnitude (not just significance), investigate the estimand, not just the SE.
- **What changed:** Rewrote abstract, intro, Section 6.2, Discussion 7.1, Conclusion to remove "reduction" language and honestly describe the widening overrepresentation. Added multiple testing discussion, Puerto Rico sensitivity note, Census suppression discussion, TWFE DDD limitation. Added caveat that welfare interpretation is ambiguous.

## Summary
- **Key lesson for future papers:** Always check the *sign* of the baseline gap before interpreting treatment effects as "reductions." This is the most basic empirical error and all three reviewers caught it immediately. The paper's entire narrative was built on misinterpreting the direction of the effect.
- **Methodological lesson:** When CS-DiD and TWFE disagree in magnitude (not just significance), present both honestly and discuss what drives the difference. Don't default to "power" as the explanation.
- **Data lesson:** ACS Summary Tables are workable for DiD but severely limit interpretation. PUMS microdata would have allowed finer occupation categories, individual controls, and within-occupation earnings analysis. Consider PUMS for future labor papers.
