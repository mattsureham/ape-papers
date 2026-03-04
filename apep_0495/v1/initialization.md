# Human Initialization
Timestamp: 2026-03-03T19:33:00Z

## Launch Prompt

> write a paper on the uk. Question. What is the causal effect of private secondary schooling on (i) admission to elite universities (Oxbridge/Russell Group), and (ii) early-career earnings? Design. Use the 20% VAT on private school fees starting 1 Jan 2025 as a large, nationwide price shock; implement DiD/event study by exposure (areas / cohorts / schools with higher baseline private-school share; schools with different pre-VAT fee levels; families near the margin). Data. Independent-school census/ISC + National Pupil Database (or equivalent) → UCAS/HESA → LEO (HMRC earnings). LEO is explicitly built to track graduate earnings and updated annually

## Contributor (Immutable)

**GitHub User:** @olafdrw

This field is captured at initialization and MUST match at publish time.

## System Information

- **Claude Model:** claude-opus-4-6

## Questions Asked

1. **Country:** Which country?
   - Options: USA, France, India, Switzerland, Nigeria, United Kingdom, Other

2. **Method:** Which identification method?
   - Options: DiD (recommended), RDD, DR (Doubly Robust)

3. **API keys:** Note: all core UK sources are open. Optionally set NOMIS_API_KEY for higher row limits. ADR UK RAPID requires TRE access — confirm if available.
   - Options: Yes, keys configured / No special keys

4. **External review:** Include external model reviews?
   - Options: Yes (recommended), No

5. **Other preferences:** Any other preferences or constraints?
   - Options: Follow my design closely / Explore alternatives too

## User Responses

1. United Kingdom
2. DiD (Recommended)
3. Yes, keys configured
4. Yes (Recommended)
5. Explore alternatives too

## Setup Results

- **Country:** UK
- **Domain:** Education / Housing (private school VAT and house price capitalization)
- **Method:** DiD (triple-difference)
- **Data era:** Modern
- **Risk appetite:** Novel angle (classic school quality capitalization question, novel policy shock)
- **Other preferences:** User specified private school VAT as the shock. Agent pivoted from university admissions/earnings (infeasible — no post-treatment data yet) to housing market capitalization (feasible with Land Registry PPD). User approved exploring alternatives.
