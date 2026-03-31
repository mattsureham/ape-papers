# Human Initialization
Timestamp: 2026-03-31T09:30:00Z

## Launch Prompt
> /revise-paper-duet The Conviction Lottery, apep 1177

## Contributor (Immutable)
**GitHub User:** @SocialCatalystLab

## System Information
- **Claude Model:** claude-opus-4-6

## Revision Information
**Parent Paper:** apep_1177
**Parent Title:** The Conviction Lottery: Judge Assignment, Drug Classification, and Mass Incarceration in Brazil
**Revision Rationale:** Transform a strong V1 descriptive fact paper into a full AER submission. Strategic feedback from all three reviewers converges on the same diagnosis: the paper documents a striking fact (massive conviction rate dispersion across randomly assigned courtrooms) but needs to convert that fact into a general economic contribution about legal indeterminacy and arbitrary punishment.

## Key Changes Planned
- Reframe from "judge-dispersion paper in Brazil" to "vague legal standards amplify assignment-based arbitrariness"
- Add comparison-offense test (drug trafficking vs. clearer-standard offenses within same courts)
- Add figures: distribution of vara conviction rates, event-study-style leniency binscatter, within-comarca comparison
- Strengthen balance tests to case level with richer covariates
- Quantify incarceration consequences (prison-years at stake)
- Deeper literature engagement (rules vs. standards, bureaucratic discretion, state capacity)
- Expand to 25+ pages with mechanism evidence and robustness battery

## Original Reviewer Concerns Being Addressed
1. **All 3 strategic reviewers:** Reframe as general institutional insight about vague law + random assignment → arbitrary punishment
2. **GPT-5.4 R1:** Add comparison to clearer offense categories to show vague law specifically amplifies dispersion
3. **GPT-5.4 R2:** Translate dispersion into incarceration consequences (prison-years)
4. **Gemini-3-Flash:** Link conviction lottery to downstream consequences; expand beyond first stage
5. **Empirics (GPT-5.4 C):** Strengthen balance tests to case level; address documentation heterogeneity; add shrinkage correction for vara rates

## Inherited from Parent
- Research question: refined from "conviction lottery exists" to "when does legal indeterminacy amplify assignment-based arbitrariness?"
- Identification strategy: same (vara leniency IV via sorteio) but with stronger diagnostics
- Primary data source: same (CNJ DataJud API) but with expanded case-level download
