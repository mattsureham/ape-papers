# Research Plan: The Midnight Rulemaking Survival Discontinuity

## Research Question

Does Congressional Review Act (CRA) exposure causally reduce the longevity of federal regulations? Rules finalized during the CRA lookback window (approximately the last 60 Senate session days of a Congress) face binary vulnerability to nullification when a cross-party presidential transition occurs. This paper estimates whether crossing the lookback cutoff discontinuously increases the probability of regulatory reversal.

## Identification Strategy

**Difference-in-Discontinuities Design.** The running variable is the number of days between a rule's Federal Register publication date and the CRA lookback cutoff date. The key identification insight is that this threshold creates vulnerability only during cross-party presidential transitions:

- **Cross-party transitions** (2001, 2009, 2017, 2021, 2025): CRA is a credible threat. Rules published inside the lookback window can be nullified by simple majority vote.
- **Same-party transitions** (2005, 2013): CRA is unused. The same lookback window exists but creates no political incentive for nullification.

The diff-in-discontinuities compares the jump at the lookback cutoff in cross-party years against the (expected null) jump in same-party years. This eliminates smooth confounders like end-of-term rule quality differences.

**Key assumptions:**
1. No precise manipulation of finalization dates around the cutoff (testable: McCrary density test)
2. Continuity of rule characteristics at the threshold
3. Same-party transitions provide valid counterfactual for the calendar-date effect

## Expected Effects and Mechanisms

**Primary hypothesis:** CRA-vulnerable rules are more likely to be reversed, delayed, or modified within 24 months of the new administration.

**Mechanisms:**
1. **Direct CRA nullification:** Congressional resolutions of disapproval (9 in 2017)
2. **Executive action:** New administration delays effective dates or initiates repeal rulemaking
3. **Strategic withdrawal:** Agencies preemptively withdraw vulnerable rules under new leadership
4. **Deterrence/anticipation:** Late-term agencies may rush weaker rules into the window, creating a quality gradient

**Expected magnitude:** The 2017 transition saw 21 repeal/rescission rules, 9 CRA resolutions, and ~50 excess effective-date delays. With ~500-1,000 rules in the lookback window per transition, the treatment effect on "any adverse action" could be 5-15 percentage points.

## Primary Specification

Y_{i,t} = α + β₁ · CRA_Vulnerable_{i,t} + β₂ · CrossParty_t + β₃ · (CRA_Vulnerable × CrossParty)_{i,t} + f(Days_from_cutoff) + X'δ + ε

Where:
- Y = binary indicator for rule reversal/delay/modification within 24 months
- CRA_Vulnerable = 1 if rule published inside lookback window
- CrossParty = 1 for cross-party transition years
- f(·) = local polynomial in running variable
- X = agency fixed effects, rule significance indicator

β₃ is the diff-in-discontinuities estimand: the excess effect of CRA vulnerability during cross-party transitions.

**Bandwidth:** Calonico-Cattaneo-Titiunik (2014) MSE-optimal, with sensitivity analysis.

## Data Source and Fetch Strategy

**Federal Register API** (https://www.federalregister.gov/api/v1/):
- All final rules 1999-2025, including: publication date, agency, CFR parts, "significant" flag, document number
- Amendments, corrections, and repeals citing original rules (for outcome construction)
- No authentication required; JSON format; paginated

**CRA lookback cutoff dates:** Computed from Congressional session calendars. The cutoff is approximately May 15-June 1 of the year preceding the transition (for the Congress that adjourns ~Jan 3).

**Outcome construction:**
1. For each rule published within bandwidth of cutoff: search Federal Register for subsequent documents citing its CFR parts with repeal/rescind/withdraw/delay language
2. Cross-reference with confirmed CRA resolutions (Public Laws)
3. Track effective-date-delay notices in first 6 months of new administration

**Timeline:**
1. Fetch all final rules from FR API (2000-2025)
2. Identify CRA lookback windows for each transition
3. Construct running variable (days from cutoff)
4. Build outcome: any adverse regulatory action within 24 months
5. Estimate RDD and diff-in-disc specifications
