# Research Plan: The Veto Clock — OIRA Review Duration and Rule Withdrawal

## Research Question

Does OIRA's review duration causally increase rule withdrawal probability? Or does the correlation between long reviews and withdrawals merely reflect the controversy of the underlying rule? This paper provides the first causal estimate by instrumenting review duration with end-of-administration calendar compression.

## Identification Strategy

**Primary: End-of-Administration Compression IV (2SLS)**

Presidential transitions create sharp, constitutionally-mandated deadlines that compress OIRA throughput. In the final weeks of an administration, OIRA processes rules in days rather than months — not because the rules are simpler, but because of calendar pressure. This compression provides an instrument for review duration that is plausibly orthogonal to rule content.

- First stage: log(review_days) = α + β₁·TransitionWindow + X'γ + agency FE + ε
- Second stage: Withdrawn = α + β₁·log(review_days_hat) + X'γ + agency FE + ε
- TransitionWindow: indicator for rules completed in November–January of a presidential transition (2016-17, 2020-21)
- Exclusion restriction: transition timing shifts OIRA processing speed for political/administrative reasons unrelated to individual rule content

**Robustness:**
1. Legal-deadline rules (N≈624) as quasi-control: rules with statutory deadlines have constrained duration regardless of OIRA preferences
2. Cross-administration DiD: Trump OIRA withdrew 9.2% vs Obama's 4.6%, using agency × rule-type cells
3. Balance tests: verify that rule characteristics (economically significant, agency, stage) don't differ between transition-window and non-transition rules

## Expected Effects

- **Veto-player hypothesis (Croley 2008):** β₁ > 0. OIRA strategically delays controversial rules to kill them. Duration is the instrument of presidential control.
- **Quality-control hypothesis:** β₁ ≈ 0. Longer reviews reflect thorough analysis; withdrawal is driven by rule defects, not OIRA delay.
- Either result is informative. The veto-player finding reshapes understanding of executive oversight. A null supports the technocratic model.

## Primary Specification

2SLS with log(review_days) instrumented by transition-window indicator. Outcome: binary withdrawal (5.8% base rate). Controls: economically significant indicator, rule stage (proposed/final), agency FE. Standard errors clustered by agency.

## Data Source and Fetch Strategy

OIRA Completed Review XML files at reginfo.gov. Public, no authentication required.

- URL pattern: `https://reginfo.gov/public/do/XMLViewFileAction?f=XXXXXXXX.xml` (year-specific XML files)
- Coverage: 2009-2024, ~8,000 completed reviews
- Key fields: RIN, AGENCY_CODE, TITLE, STAGE, ECONOMICALLY_SIGNIFICANT, DATE_RECEIVED, LEGAL_DEADLINE, DATE_COMPLETED, DECISION, DATE_PUBLISHED
- Parse XML in R, construct panel, derive TransitionWindow indicator from DATE_COMPLETED

## Analysis Plan

1. **Summary statistics:** N by year, administration, decision type; duration distribution
2. **Reduced form:** OLS of withdrawal on transition-window indicator (intent-to-treat)
3. **First stage:** Regression of log(duration) on transition-window indicator (check F > 10)
4. **2SLS:** IV estimate of duration → withdrawal
5. **Robustness:** (a) Legal-deadline subsample, (b) Leave-one-agency-out, (c) Balance test on covariates, (d) Cross-administration DiD
