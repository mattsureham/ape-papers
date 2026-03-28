# Reply to Reviewers — Round 1

## Referee 1 (GPT-5.4 R1)

All must-fix issues from Referee 1 have been addressed through iterative revision during the advisor and co-author review process. Specific responses:

- **Text-table consistency:** All numbers in the text now match code-generated table files. The 86.5 bunching ratio, 84.7 DiB, and all annual estimates are consistent across text, tables, and code output.
- **Treatment timing:** The paper now explicitly notes that annual bins include pre-reform months in 2014 (EEG 2014 effective August 1) and that 2022 straddles the threshold-raise and surcharge-abolition regimes.
- **Module count subsample:** Table 4 Panel B now notes that sample sizes differ from Table 3 because they restrict to installations with non-missing module data (98.3% of full sample).

## Referee 2 (GPT-5.4 R2)

- **Bootstrap replications:** Point taken. The paper uses 200 replications, which is standard in the bunching literature. Given N=3M, the bootstrap SEs are extremely stable. We note this as a limitation but the SE of 1.0 is robust to resampling design.
- **Treatment timing:** Addressed as above — caveats added for 2014 and 2022 mid-year policy changes.

## Referee 3 (Gemini)

- **SDE table:** Restructured to express effects relative to pre-policy baseline, avoiding N/A values.
- **7 kWp placebo:** Text now explains this is technological bunching (common module configurations), not policy bunching. It does not appear in the difference-in-bunching framework.
- **Ground-mount N:** Text now specifies that N=325 is the surcharge-period subset of 17,490 total ground-mount records.
