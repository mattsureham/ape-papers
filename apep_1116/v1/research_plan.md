# Research Plan: The Patent Office Lottery

## Research Question
When continuation patent applications are reassigned to different examiners within the same art unit, how much does examiner identity causally contribute to patent outcomes? What are the implications for small entities?

## Identification Strategy
**Within-Family, Within-Art-Unit Twin Study.** Continuation and divisional applications that are reassigned to a different examiner within the same art unit provide a natural experiment: the same invention family faces different gatekeepers. Reassignment within an art unit is driven by workload balancing and examiner availability — plausibly orthogonal to invention quality conditional on art-unit × filing-year fixed effects.

**Primary specification:**
```
Grant_child = α + β × ExaminerLeniency_child + γ × ParentOutcome + AU×Year_FE + ε
```

Where ExaminerLeniency is the leave-one-out grant rate of the child's examiner. The key coefficient β measures how much a one-SD increase in examiner leniency shifts the grant probability, holding invention quality fixed within family.

**Placebo:** Same-examiner continuations should show lower discordance than reassigned continuations (31.7% vs 36.0% from smoke test).

## Expected Effects and Mechanisms
- Examiner leniency should strongly predict child grant outcome (first stage F >> 10)
- Discordance rate ~36% among reassigned pairs vs ~32% among same-examiner pairs
- Small entities face higher discordance (41.7% vs 34.4%) — "the small-entity penalty"
- Technology heterogeneity: Organic Chemistry highest discord (~65%), Design Patents lowest (~14%)

The portable mechanism is **"the examination lottery"** — regulatory inconsistency that randomly reallocates property rights.

## Primary Specification
1. **Discordance analysis:** Compare discordance rates between reassigned vs same-examiner pairs (within AU × year cells)
2. **IV regression:** Examiner leniency (leave-one-out) instrumented on grant outcome, controlling for parent outcome and AU × year FE
3. **Small entity differential:** Triple-difference — reassignment × small entity interaction

## Data Source and Fetch Strategy
All data from Google BigQuery (free tier, confirmed accessible):
- `patents-public-data.uspto_oce_pair.application_data` — 9.8M applications (filing dates, grant/abandon status, examiner IDs, art units, small entity flags)
- `patents-public-data.uspto_oce_pair.office_actions` — 4.4M office actions with rejection codes
- Continuity parent-child links from PAIR data

**Fetch approach:** Python BigQuery client → CSV exports → R analysis. Key queries:
1. Build continuation pairs (parent-child links within same art unit)
2. Flag reassigned pairs (different examiner, same AU)
3. Compute leave-one-out examiner grant rates
4. Merge office action data for mechanism analysis

## Robustness Checks
- Balance tests: examiner leniency orthogonal to small entity status, filing year, technology
- Placebo: same-examiner pairs as negative control
- Donut hole: exclude pairs where parent was abandoned (selection into continuation)
- Leave-one-out by technology center
- Wild cluster bootstrap at examiner level
