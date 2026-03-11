# Reply to Reviewers — apep_0598 v1

## Reviewer 1 (GPT-5.4 R1): REJECT AND RESUBMIT

**Concern 1: Only 3 sectors is too few for credible DiD inference.**
We agree this is a fundamental limitation. We now frame the cross-sector DiD as a mechanism test providing design-based evidence (direction and ordering), not as a standalone hypothesis test. The wild cluster bootstrap p-values (0.289, 0.160) are reported transparently in both the table notes and text.

**Concern 2: Treatment intensity measured post-treatment (2016 ECB SPACE).**
Acknowledged in the text. We argue the ranking is stable because cash intensity reflects structural features (fuel station infrastructure, customer demographics) that change slowly. Pre-treatment Greek-specific data does not exist. Conservative bias strengthens the argument.

**Concern 3: Decline in reported turnover is conceptually ambiguous as evidence of formalization.**
We agree the turnover decline alone does not prove formalization. The paper's argument relies on the full triangulation: (1) monotonic ordering by cash intensity, (2) persistence after control removal, and (3) VAT/GDP increase. The turnover decline is consistent with both real contraction and measurement adjustment; the VAT/GDP result discriminates between them.

**Concern 4: SCM = Portugal only, poor pre-treatment fit.**
Acknowledged. We now describe the SCM as providing aggregate magnitude estimates, not sharp inference. The LOO analysis shows dropping Portugal yields a larger gap (-13.1 vs -10.4), suggesting the bilateral comparison understates the effect.

**Concern 5: VAT/GDP confounded by 2016 rate increase and concurrent reforms.**
Added Appendix C section with VAT rate decomposition: the 23%→24% increase accounts for ~4.3% of the improvement; the remaining ~8.2pp reflects base expansion. Also note that the cross-sector evidence (unaffected by the rate change) independently supports formalization.

**Concern 6: Persistence may reflect Law 4446/2016, not hysteresis.**
Added explicit discussion in Limitations section acknowledging that mandatory POS requirements represent a continuation treatment that cannot be separated from hysteresis in the current design.

## Reviewer 2 (GPT-5.4 R2): REJECT AND RESUBMIT

Reviewer 2's concerns substantially overlap with Reviewer 1. All addressed above. Additional points:

**Concern: Parallel trends not persuasive with 3 sectors differing along many dimensions.**
The F-test of pre-trends (F=1.42, p=0.23) is reported but acknowledged as low-powered. The key argument is the post-treatment monotonic ordering, not the pre-trend test.

**Concern: Fuel turnover decline may reflect oil prices.**
Added Appendix C section on oil price confound. The oil price collapse occurred in late 2014, not July 2015; time fixed effects absorb common energy price movements; and the food-versus-non-specialized ranking cannot be explained by oil prices.

## Reviewer 3 (Gemini-3-Flash): MAJOR REVISION

**Concern 1: Expand sectoral data to 4-digit NACE.**
Investigated; Eurostat STS does not provide 4-digit retail subsectors for Greece with sufficient coverage. The 3-sector limitation is binding.

**Concern 2: Control for global oil prices in sectoral DiD.**
Addressed with oil price discussion in Appendix C. Time fixed effects already absorb common price movements.

**Concern 3: LOO plot, not just table.**
Added LOO table (Table C.1) to Appendix C.

**Concern 4: VAT rate decomposition.**
Added Appendix C section with back-of-envelope calculation.

**Concern 5: Move augmented SCM to main text.**
The augmented SCM yields similar point estimates (-9.8 vs -10.4) and is already mentioned in Appendix B. Given the SCM's acknowledged limitations, promoting it to the main text would not strengthen the argument.
