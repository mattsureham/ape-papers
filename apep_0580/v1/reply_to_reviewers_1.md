# Reply to Reviewers (Round 2)

## Reviewer 1 (GPT-5.4 R1) — MAJOR REVISION

**1. Concurrent policy confounding**
Expanded the Discussion paragraph to explicitly name naloxone, Good Samaritan, PDMP, and Medicaid expansion as specific threats, and to note that region-by-year fixed effects and state-specific trends are natural robustness checks for future work.

**2. Outcome series splice**
Already acknowledged in Data section. The structural limitation (two CDC products) cannot be fully resolved without a single-source alternative.

**3. Treatment heterogeneity**
Dose-response analysis by reform type already presented (Section 5.4). The binary treatment is standard in staggered DiD; multi-valued treatment frameworks are noted as a direction for future work.

**4. Event-study pre-trends**
Added formal joint Wald test (chi-squared(4) = 0.91, p = 0.92) and an explicit caveat that failure to reject is not proof of parallel trends.

**5. Long-run estimates**
Further toned down the e=+5 in abstract. It is now mentioned only in the body text with full Minnesota-only caveats.

**6. Federal equitable sharing loophole**
Already discussed as attenuation bias. First-stage validation using actual forfeiture receipts noted as future work.

## Reviewer 2 (GPT-5.4 R2) — REJECT AND RESUBMIT

**1-5.** Same concerns as R1 — addressed identically above.

**6. No first-stage evidence**
Acknowledged. The paper frames itself as a reduced-form analysis. Direct evidence on enforcement reallocation is identified as the top priority for future work.

**7. Formal difference tests for heterogeneity**
The TWFE interaction coefficient (2.22, SE = 0.95, p < 0.05) provides a formal test. Added clarifying note about why CS-DiD subgroup estimates differ from TWFE interaction predictions.

## Reviewer 3 (Gemini-3-Flash) — MINOR REVISION

**1. Data source consistency**
Acknowledged. State-level overlap validation is identified as a natural extension.

**2. Long-run estimate calibration**
Further toned down in abstract and conclusion per this reviewer's guidance.

## Internal Review (Claude Code) — MINOR REVISION

All suggested improvements incorporated.
