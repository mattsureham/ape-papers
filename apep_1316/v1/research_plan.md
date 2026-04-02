# Research Plan: The Appeals Lottery

## Research Question
Does winning a VA disability benefits appeal cause improvements in veteran mortality and employment? We exploit random case assignment to Veterans Law Judges (VLJs) at the Board of Veterans Appeals as an instrumental variable for appeal grant decisions.

## Identification Strategy
**Judge-leniency IV (Kling 2006).** The BVA's Caseflow Automatic Case Distribution (ACD) system assigns cases to ~60+ VLJs based on availability and docket order — not case characteristics. VLJs exhibit persistent heterogeneity in grant rates (estimated range: 30–80%). We construct leave-one-out VLJ grant rates as an instrument for individual appeal outcomes.

**Key assumptions:**
1. **Relevance:** VLJs vary in leniency (testable via F-statistic)
2. **Independence:** ACD assigns cases quasi-randomly (testable via balance on observables)
3. **Exclusion:** VLJ identity affects outcomes only through the grant decision (standard in leniency designs)
4. **Monotonicity:** More lenient VLJs weakly increase grant probability for all cases

## Expected Effects and Mechanisms
- **Mortality:** Negative (grants → income + healthcare access → better health outcomes)
- **Employment:** Ambiguous (income effect vs. disability label effect)
- Grant provides monthly compensation ($150-$3,700+/month depending on rating) plus healthcare eligibility

## Primary Specification
IV-2SLS at the case level:
- First stage: Grant_i = α + β·Leniency_{j(i),-i} + X_i'γ + δ_t + ε_i
- Second stage: Y_i = α + β·Grant_hat_i + X_i'γ + δ_t + ε_i

Where Leniency_{j(i),-i} is the leave-one-out grant rate of judge j assigned to case i. X_i includes appeal issue type, regional office, and year FE.

## Data Source and Fetch Strategy
1. **BVA Decisions (primary):** Download plain-text decision files from va.gov/vetapp{YY}/files{N}/{YYXXXXX}.txt for FY2016-2019. Parse to extract: VLJ name, decision (grant/deny/remand), date, docket number, regional office, disability issue.
2. **County-level outcomes (aggregate design):** Map Regional Offices to counties. Merge with:
   - CDC WONDER: Veteran mortality (or all-cause by county-year)
   - BLS QCEW: County-level employment
3. **Alternative individual-level:** If aggregate link is too noisy, focus on the rich first-stage analysis with case-level heterogeneity.

## Key Risk
The main risk is that BVA decision text files may not contain enough structured information to cleanly extract case characteristics for balance tests. Mitigation: the VLJ name and grant/deny decision should be reliably extractable from the standardized format.
