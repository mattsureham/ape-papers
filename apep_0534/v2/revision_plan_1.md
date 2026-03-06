# Revision Plan 1 — apep_0534 v2

## Source Reviews

| Reviewer | Decision | Core Concern |
|----------|----------|-------------|
| GPT-5.4 R1 | Reject & Resubmit | Outcome-treatment mismatch, pseudo-replication, weak balance |
| GPT-5.4 R2 | Reject & Resubmit | Shared outcome structure, subclass imputation, IV exclusion |
| Gemini-3-Flash | Major Revision | Aggregation discrepancy, clustering, citation mechanical contamination |

## Consensus Issues (all 3 reviewers)

1. **Pseudo-replication**: 640K observations share 96 unique follow-on outcome values
2. **Forward citations mechanically contaminated**: Abandoned apps cannot be cited
3. **"Bad controls"**: Claims/citations zero-coded for abandonments proxy grant status
4. **Balance tests post-treatment**: Grants-only balance conditions on outcome
5. **Filing-date timing**: Outcomes include pre-disposition activity
6. **IV over-interpreted**: Exclusion implausible (examiner affects scope, duration, continuations)
7. **Subclass imputation coarse**: Modal subclass for abandonments may be systematically wrong

## Revision Decisions

### ACCEPTED (changes made)

| # | Reviewer Request | Action Taken |
|---|-----------------|--------------|
| 1 | Restructure around collapsed spec | Collapsed subclass×year (96 cells) presented as primary evidence; application-level demoted to supplementary |
| 2 | Remove bad controls from baseline | Uncontrolled specification is baseline throughout; controlled shown as sensitivity with explicit zero-coding note |
| 3 | Reframe as ITT of examiner assignment | All text rewritten: "assignment to a more permissive examiner," not "grant effect"; IV labeled "exploratory" |
| 4 | Downgrade citation interpretation | Citations reframed as "largely mechanical" due to database visibility; no longer co-equal finding |
| 5 | Address aggregation discrepancy honestly | Both collapses (subclass-year significant, AU-year null) presented transparently; conclusion: "too sensitive to aggregation for firm causal claim" |
| 6 | Fix application-level inference framing | Added caveat that application-level p-values overstate precision; collapsed estimate is headline |
| 7 | Tighten all claims | Abstract, intro, discussion, conclusion rewritten with conditional language; removed "blocking effect" framing |
| 8 | Clarify first-stage reporting | F-statistics with/without controls shown side by side; explained why controls collapse F from 13,006 to 594 |
| 9 | Remove over-determined Column 3 | Domain×year saturated spec (R²=0.9999) removed from main table |
| 10 | Fix log(1+x) notation | All tables and text use $\log(1+\text{claims})$ notation, not "Log Claims" |
| 11 | Fix placebo construction | Deduplicated at subclass×year level; new result: coef=0.001, SE=0.000310 (significant but small mechanical complement) |
| 12 | De-emphasize IV estimates | IV section explicitly labeled "exploratory," starts with non-causal disclaimer |

### DECLINED (with reasoning)

| # | Reviewer Request | Reason for Declining |
|---|-----------------|---------------------|
| A | Redesign outcome to be application-specific (R1 §6.1, R2 §6.1) | Requires new data construction (text-similarity, citation-linkage) beyond scope of current revision. Acknowledged as limitation and future work direction. |
| B | Obtain subclass data for abandonments from PAIR file-wrapper text (R2 §6.2) | File-wrapper text parsing is a separate research infrastructure project. Imputation sensitivity test (restrict to ≥90% Y02 purity art units) provided instead. |
| C | Full-sample balance tests with richer PatEx covariates (R1 §6.3, R2 §6.6) | PatEx covariates (continuation status, inventor count) not available in current BigQuery extract without additional query development. Acknowledged as limitation. |
| D | Wild-cluster bootstrap at 96-cell level (R2 §6.3) | With 96 clusters, asymptotic cluster-robust SEs are adequate; bootstrap with so few cells has its own finite-sample issues. |
| E | Formal exposure-design justification (R1 §1A, R2 §6.4) | The paper now honestly acknowledges that the collapsed design does not inherit the random-assignment guarantee rather than making an unsupported claim. |

## Execution Sequence

1. Rewrite 06_tables.R: remove Column 3, fix variable labels, add R² note
2. Rewrite 04_robustness.R: fix placebo construction
3. Recompile all tables
4. Rewrite paper.tex: abstract, introduction, methodology, results, discussion, conclusion
5. Run LaTeX compile (3 passes)
6. Run advisor review → iterate until 3/4 pass
7. Run exhibit review, prose review
8. Run external review
9. Write reply_to_reviewers, review_cc, literature_review_late
10. Publish with --parent apep_0534
