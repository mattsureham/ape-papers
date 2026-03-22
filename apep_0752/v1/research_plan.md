# Research Plan: Jackpots Against Despair

## Research Question
Does tribal casino gaming income protect American Indian/Alaska Native (AI/AN) communities from the opioid epidemic, or does increased disposable income enable substance abuse?

## Design Pivot (from idea_1712 manifest)
The original plan called for county-level AI/AN overdose mortality from CDC WONDER. Two constraints force a redesign:
1. **CDC WONDER has no bulk API** for county-level data — only an interactive web interface
2. **Suppression**: With AI/AN at 1.3% of US population, most county-year cells have <10 AI/AN overdose deaths (CDC suppresses these)

### Revised Design: County-Level Total Overdose Deaths in Tribal Counties

Instead of race-specific mortality (infeasible at county level), I exploit the fact that **in counties dominated by tribal lands, total overdose deaths largely reflect the AI/AN population.**

**Unit of analysis**: County-year (2003-2020)

**Treatment**: County contains a tribal gaming facility (binary, staggered timing). Casino opening dates from NIGC gaming facility records. ~200 counties with tribal casinos across 29 states.

**Outcome**: County-level age-adjusted drug overdose death rate (ALL races) from CDC WONDER. At the all-race level, suppression is much less severe — most counties with populations >10K have 10+ annual overdose deaths by 2015+.

**Key innovation**: I interact the casino treatment with the county's AI/AN population share (from Census 2000). If casinos protect AI/AN communities specifically, the effect should be stronger in counties with higher AI/AN shares. This is a triple-difference: casino × AI/AN intensity × post.

**Controls**: County-level poverty rate, median household income, rural/urban classification, state PDMP laws, naloxone access laws, Medicaid expansion status.

**Comparison group**: Non-gaming tribal counties (counties with federally recognized reservations but no casino).

## Identification Strategy
Staggered DiD with Callaway-Sant'Anna (2021). Treatment timing: first casino opening year per county. Casino opening dates are plausibly exogenous to county-level opioid mortality trends — driven by state political negotiations under IGRA, not by reservation health conditions.

### Key Threats & Robustness
1. **Selection into gaming**: Tribes with better governance open casinos. Pre-trend tests + baseline balance.
2. **Concurrent policies**: State PDMP/naloxone laws. Include as controls + triple-diff absorbs state shocks.
3. **Fentanyl supply shock** (post-2014): Heterogeneous effects by opioid wave period.

## Data Sources
1. **Casino locations**: NIGC gaming facility data (web), supplemented by Wikipedia's comprehensive list of Native American casinos
2. **County overdose deaths**: CDC WONDER Underlying Cause of Death (manual web query, exported as text files), ICD-10 X40-X44, X60-X64, Y10-Y14
3. **County demographics**: Census ACS 5-year (2005-2020) and Census 2000 for AI/AN population share
4. **Reservation-county crosswalk**: Census AIAN area geography codes
5. **State policies**: PDAPS/LawAtlas for PDMP, naloxone access, Medicaid expansion dates

## Expected Effects
Two competing hypotheses:
- **Protective**: Casino income → reduced economic despair → lower overdose mortality
- **Enabling**: Casino income → more disposable income → greater drug access → higher overdose mortality
The oracle ensemble (H=2.39-2.55) shows genuine model uncertainty about the sign.

## Feasibility Assessment
- Treated units: ~200 casino counties (exceeds 20-unit threshold)
- Control units: ~100 non-gaming tribal counties
- Pre-periods: 5+ years for most treatment cohorts (casinos opened 1993-2010, outcome data 2003-2020)
- Post-periods: 10+ years for early-opening casinos
