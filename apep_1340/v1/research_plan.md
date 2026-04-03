# Research Plan: The Denominator Shuffle — MSA Redefinitions and CRA Mortgage Lending

## Research Question

Does CRA eligibility causally affect mortgage lending? When OMB redefines MSA boundaries, the area median income (AMI) used to classify census tracts as Low-and-Moderate Income (LMI) changes mechanically — even though the tract's own income is unchanged. Tracts that cross the 80% threshold gain or lose CRA eligibility, creating a natural experiment.

## Identification Strategy

**Difference-in-differences** exploiting the 2014 MSA redefinition (OMB Bulletin 13-01, effective January 1, 2014).

- **Treatment group:** Census tracts whose LMI status changed due to MSA boundary redefinition (gained or lost CRA eligibility)
- **Control group:** Tracts in the same MSAs whose LMI status was unchanged
- **Key feature:** The tract's own median family income (MFI) is held constant — only the denominator (MSA/MD median) shifts. This eliminates confounding from local income changes.

Two sub-treatments:
1. **Gained CRA eligibility:** Tracts reclassified from non-LMI to LMI (newly below 80% of revised AMI)
2. **Lost CRA eligibility:** Tracts reclassified from LMI to non-LMI (newly above 80% of revised AMI)

## Expected Effects and Mechanisms

- **Lending volume:** Tracts gaining CRA eligibility should see increased mortgage originations as banks seek CRA credit. Tracts losing eligibility should see decreased lending.
- **Approval rates:** Marginal applications in newly-eligible tracts may be approved to meet CRA targets.
- **Racial composition:** If CRA promotes lending to minority borrowers, newly-eligible tracts should see increased minority lending share.
- **Loan terms:** CRA-motivated lending may come at similar or slightly higher rates (subprime concern) or comparable rates (access without risk).

## Primary Specification

$$Y_{it} = \alpha_i + \gamma_t + \beta \cdot (\text{Reclassified}_i \times \text{Post}_t) + X_{it}'\delta + \varepsilon_{it}$$

Where:
- $Y_{it}$: loan count, approval rate, minority share, or average rate spread in tract $i$, year $t$
- $\alpha_i$: tract fixed effects
- $\gamma_t$: year fixed effects
- $\text{Reclassified}_i$: indicator for tracts whose LMI status changed
- $\text{Post}_t$: indicator for years after 2014
- $X_{it}$: time-varying tract controls (population, income growth)

Cluster standard errors at the MSA level (~380 MSAs).

## Exposure Alignment

The treatment (CRA reclassification) operates at the census tract level. Outcomes (mortgage originations, approvals, rate spreads) are measured at the same tract level using HMDA data. CRA eligibility directly affects all CRA-regulated depository institutions lending in the tract. A limitation is that HMDA includes both CRA-regulated depositories and nonbank lenders (who are exempt from CRA); the tract-level analysis captures the net effect across all lenders. Stronger effects among CRA-regulated banks would be expected, but lender-type decomposition is deferred to V2.

## Robustness
1. **RDD at 80% threshold:** Local polynomial regression around the 80% AMI ratio cutoff
2. **Donut hole:** Exclude tracts very close to 80% (±2pp) to check sensitivity
3. **Placebo:** Apply same methodology to tracts far from the 80% cutoff that were unaffected
4. **Event study:** Year-by-year coefficients to verify parallel pre-trends
5. **Heterogeneity:** Split by tract minority share, urban/rural, bank competition

## Data Sources

1. **HMDA (Home Mortgage Disclosure Act):** Loan-level microdata from CFPB, 2010–2017. Key fields: census_tract, action_taken, loan_amount, applicant_race, rate_spread, tract_to_msa_income_percentage.
2. **FFIEC Census Files:** Tract-level MSA assignments, tract MFI, MSA MFI, LMI status — for identifying reclassified tracts across the 2013→2014 boundary change.

## Fetch Strategy

1. Download FFIEC census flat files for 2013 and 2014 to identify reclassified tracts
2. Download HMDA aggregate data by tract from CFPB for 2010–2017
3. Merge on census tract FIPS code
4. Construct panel at tract-year level
