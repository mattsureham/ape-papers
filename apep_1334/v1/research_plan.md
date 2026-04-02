# Research Plan: Paper Patents and Real Markets

## Research Question
Do marginally granted patents have real economic value in the secondary patent market? Using examiner leniency as an instrumental variable for patent grants, this paper estimates the causal effect of patent approval on market transactions (assignments, security interests, mergers) using 5.8M USPTO assignment records linked to 7M+ resolved applications.

## Identification Strategy
**Examiner Leniency IV (judge-design family)**

- **Instrument:** Leave-one-out examiner grant rate within art-unit × filing-year cells
- **First stage:** More lenient examiner → higher probability of patent grant
- **Second stage:** Instrumented grant → market transfer, collateralization, merger conveyance
- **Assignment story:** USPTO assigns applications to examiners quasi-randomly within art units. Conditional on art-unit × filing-year, examiner assignment is as-good-as-random.
- **Exclusion:** Examiner leniency affects market outcomes only through the grant decision, not through examiner-specific patent drafting quality (since the applicant's claims are written before assignment).
- **Monotonicity:** A more lenient examiner weakly increases grant probability for every application.
- **Estimand:** LATE — the causal effect of patent grant on market outcomes for applications whose grant status is changed by examiner assignment (compliers = marginal patents).

## Expected Effects and Mechanisms
1. **Main effect:** Marginal patents should be assigned/traded at lower rates than inframarginal patents if the market prices quality.
2. **Entity heterogeneity (key test):** Small-entity marginal patents may trade LESS than strict-examiner small-entity patents (reversed sign), suggesting market discipline is stronger for small entities. Large-entity patents may show flat effects (institutional buyers less sensitive to quality).
3. **Mechanism:** Quality pricing vs. portfolio filler. If marginal patents are traded at the same rate, they serve as portfolio fillers (NPE/troll concern). If traded less, markets discipline quality.

## Primary Specification
```
Y_i = α + β * Grant_i + γ * X_i + δ_{au,fy} + ε_i
```
where Grant_i is instrumented by leave-one-out examiner grant rate, X_i includes application characteristics (small_entity, filing_year, USPC class), and δ_{au,fy} are art-unit × filing-year fixed effects.

## Data Sources
1. **PatEx (BigQuery):** `patents-public-data.uspto_oce_pair.application_data` — 9.8M applications with examiner_id, disposal_type, art_unit, filing_date
2. **Assignment records (BigQuery):** USPTO assignment tables — 5.8M assignments with conveyance_type (assignment, security interest, merger, release)
3. **Join key:** application_number

## Fetch Strategy
1. Query PatEx for resolved applications (ISS/ABN) with examiner data
2. Query assignment records and classify by conveyance type
3. Join on application_number
4. Construct leave-one-out examiner grant rate within art-unit × filing-year
5. Export to CSV for R analysis

## Key Risks
- BigQuery assignment table schema may differ from manifest expectations → verify column names first
- Many-instrument bias with 11K+ examiners → use JIVE or UJIVE estimator, or collapse to leave-one-out rate
- Sample size is massive (7M+) → may need to sample for computational feasibility
- Small-entity flag coverage may be incomplete in early years
