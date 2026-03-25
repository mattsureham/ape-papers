# Research Plan: AVR and Federal Jury Acquittal Rates

## Research Question
Does automatic voter registration (AVR) affect federal criminal jury acquittal rates by mechanically expanding the jury pool through voter registration list expansion?

## Identification Strategy
**Callaway-Sant'Anna staggered DiD** across 94 federal judicial districts, with treatment timing determined by state AVR effective dates (25 states, 2016-2023).

**Triple-difference falsification:** Federal courts that draw jurors ONLY from voter registration lists (treatment-exposed) vs. courts that supplement with driver's license lists (already capturing DMV contacts — AVR should have no marginal effect). This provides a built-in placebo.

**Key identification assumptions:**
1. Parallel trends in acquittal rates across AVR and non-AVR districts pre-treatment
2. No contemporaneous state-level criminal justice reforms correlated with AVR timing
3. SUTVA: AVR adoption in one state doesn't affect jury outcomes in non-AVR states

## Expected Effects and Mechanisms
- **First-order:** AVR expands voter rolls → jury pools drawn from voter rolls become larger and more demographically representative → jury composition shifts toward younger, more diverse jurors → acquittal rates may increase
- **Direction:** Positive effect on acquittal rates (if jury diversity increases skepticism toward prosecution), OR null (if compositional shifts are too small to move outcomes)
- **Magnitude:** Likely small — AVR changes composition at the margin. Even a well-powered null is a contribution.

## Primary Specification
```
AcquittalRate_{dt} = α_d + γ_t + β × AVR_{dt} + ε_{dt}
```
Where d = federal district, t = fiscal year. Callaway-Sant'Anna with never-treated and not-yet-treated as controls.

## Data Sources
1. **FJC Integrated Database (IDB):** https://www.fjc.gov/sites/default/files/idb/textfiles/cr96on.zip — 6.28M criminal defendant records, 1996-present. Key fields: DISP1 (disposition), DISTRICT, FISCALYR.
2. **AVR adoption dates:** Hand-coded from Brennan Center/NCSL data — 25 states + DC, 2016-2023.
3. **Jury source lists by district:** Federal district court jury plans (public) — identify which districts use voter-only vs. supplemented lists.

## Fetch Strategy
1. Download FJC IDB zip (240MB)
2. Parse criminal case records, filter to jury verdicts (DISP1 = 3 or 9)
3. Collapse to district-year panel: acquittal rate, total jury verdicts, total cases
4. Merge with AVR treatment indicator by state-year
5. Code jury source list type per district (voter-only vs. supplemented)
