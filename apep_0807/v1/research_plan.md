# Research Plan: Legislating at Midnight

## Research Question

Does end-of-session calendar pressure degrade the quality of U.S. federal legislation? The U.S. Constitution mandates that each Congress expires on January 3 of odd-numbered years, creating a hard deadline that compresses legislative deliberation in final weeks. If deadline pressure forces hasty lawmaking, we should observe that laws enacted under calendar compression require more subsequent corrections, amendments, and revisions than laws enacted earlier in the session with adequate deliberation time.

## Identification Strategy

**Design:** Regression discontinuity in time (RDiT) combined with within-Congress dose-response.

**Running variable:** Days remaining in the congressional session when a public law was enacted. Laws enacted with fewer days remaining faced greater calendar compression.

**Key institutional feature:** The constitutional January 3 deadline is exogenous to the content of any individual bill. It creates a sharp, predictable endpoint that intensifies scheduling pressure nonlinearly as it approaches. The final 30 days of each Congress see a dramatic spike in legislative activity — the "lame duck" compression period.

**Primary specification:**
- Within-Congress comparison: same political composition, same policy agenda, but different amounts of calendar pressure
- Congress fixed effects absorb all between-Congress variation (party control, macro conditions)
- Policy-domain fixed effects (Congressional Budget Office subject classifications) control for systematic differences in which topics get addressed early vs. late
- Bill-level controls: number of cosponsors, bipartisan indicator, committee of origin, bill complexity (text length)

**Identifying assumption:** Conditional on Congress and policy domain, the timing of a bill's final passage within a session is not systematically correlated with unobserved bill quality, except through the calendar pressure mechanism.

**Threats and mitigants:**
1. *Selection:* More complex/controversial bills take longer → passed later. Direction: these bills may be higher quality (more deliberation) despite more pressure, biasing against finding quality degradation.
2. *Omnibus packaging:* End-of-session bills often bundled into omnibus packages. I will separately analyze standalone vs. omnibus bills.
3. *Lame-duck composition:* Post-election lame-duck sessions may differ politically. I will test robustness excluding lame-duck periods (Nov election → Jan 3).

## Expected Effects and Mechanisms

**Primary prediction:** Laws enacted under high calendar compression (final 30 days of session) will have significantly higher rates of subsequent technical corrections, amendments, and revisions compared to laws enacted earlier.

**Mechanisms:**
1. *Reduced deliberation:* Less committee markup time, fewer floor amendments considered
2. *Omnibus packaging:* Bundling many provisions increases error probability
3. *Reduced oversight:* Less time for CBO scoring, legal review, and stakeholder input
4. *Logrolling pressure:* Time pressure increases side deals and last-minute additions

**Magnitude prior:** This could be a moderate positive effect (SDE 0.05-0.15). Calendar compression is a real constraint but Congress has institutional safeguards (counsel's office, CRS review).

## Primary Specification

```
AmendmentRate_i = β₁ × CalendarPressure_i + β₂ × Controls_i + α_Congress + γ_Subject + ε_i
```

Where:
- `AmendmentRate_i` = number of subsequent amendments to law i within the next 2 Congresses (4 years)
- `CalendarPressure_i` = days remaining in session when law i was enacted (negative coefficient expected: fewer days → more amendments)
- Alternative: binary indicator for "enacted in final 30 days" vs. earlier

## Data Source and Fetch Strategy

**Primary source:** Congress.gov API (api.congress.gov)
- Universe: All enacted public laws, 93rd Congress (1973) through 118th Congress (2024)
- ~500-600 enacted public laws per Congress × ~26 Congresses ≈ 13,000-15,000 observations
- Fields: bill number, enactment date, subject classifications, sponsor info, cosponsors, text length, related bills (for tracking amendments)
- API key: Available via CONGRESS_API_KEY or free tier (rate-limited)

**Amendment tracking:** Congress.gov API's "related bills" and "amendments" endpoints allow tracking which enacted laws were subsequently modified.

**Session dates:** Official session start/end dates from Congress.gov for each Congress.

**Fetch strategy:**
1. Pull all enacted public laws with metadata (bill endpoint, filter by type=law)
2. For each law, pull related bills and amendments from subsequent Congresses
3. Construct panel: law × subsequent-Congress amendment indicators
4. Merge with session calendar data for the running variable
