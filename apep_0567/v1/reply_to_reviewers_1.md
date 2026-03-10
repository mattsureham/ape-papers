# Reply to Reviewers

## Reviewer 1 (GPT-5.4 R1) — REJECT AND RESUBMIT

### 1. Broad control group / local DiD
**Concern:** DiD compares all above-20% (Alpine) to all below-20% (including flatland), vulnerable to differential shocks.
**Response:** We added a canton-by-year FE specification that absorbs all canton-specific time-varying shocks. The estimate increases to -0.49 pp (p=0.012), ruling out cantonal macro shocks as a confound. We also estimated a near-threshold local DiD (10-30% second-home share band); the null result there (-0.02, p=0.83) is consistent with our dose-response evidence: effects concentrate in high-intensity municipalities. We added text discussing this honestly.

### 2. Pre-trends not formally tested
**Concern:** Need formal joint test of pre-treatment coefficients.
**Response:** Added. Joint Wald test rejects (F=112.4, p<0.001), driven by high power over 15+ coefficients with N>37,000. We interpret this honestly: placebo timing shows no effects, canton-by-year FE strengthens the estimate, and the pattern is not systematic trending.

### 3. RDD not convincing
**Concern:** Post-treatment RDD, underpowered, sign reversal for population.
**Response:** We now explicitly acknowledge the positive RDD population estimate and explain that the wide CI easily includes the DiD estimate. We present the RDD as inconclusive local evidence rather than corroboration.

### 4. WCB p=0.107 / inference
**Concern:** Headline result not significant under WCB.
**Response:** Abstract now reports both p-values (clustered p=0.037; WCB p=0.11). Robustness conclusion rewritten to acknowledge statistical uncertainty. Claims softened throughout.

### 5. RI not design-consistent
**Concern:** Unrestricted permutation overstates significance.
**Response:** Added text noting that unrestricted permutation may overstate significance given geographic concentration of treatment. No longer present RI as "unambiguous evidence."

### 6. Sample loss 2100→1301
**Response:** Added explanation in the data section: excluded municipalities lack ARE inventory data (small/recently merged communes without computed second-home shares).

### 7. Mechanism claims exceed evidence
**Response:** Softened mechanism language. Added explicit note that vacancy includes for-sale units. Acknowledged employment data limitation (2 pre-treatment years).

### 8. Welfare calculation too speculative
**Response:** Removed the speculative rent-increase calculation and 55,000 displacement figure. Replaced with cautious discussion acknowledging vacancy is not rental-specific.

### 9. External validity claims too broad
**Response:** Rewritten to explicitly distinguish stock vs. flow regulations and narrow policy claims to Alpine-specific setting.

---

## Reviewer 2 (GPT-5.4 R2) — REJECT AND RESUBMIT

Reviewer 2's concerns largely overlap with Reviewer 1. Key additions addressed:

### 1. Canton-by-year FEs (addresses differential tourism shocks)
Added as new robustness check. Effect strengthens to -0.49 pp (p=0.012).

### 2. More nuanced treatment of population magnitude
Revised welfare section to note that 11% population decline should be interpreted cautiously, may partly reflect broader Alpine demographic trends.

### 3. Outcome definition (vacancy not rental-specific)
Added explicit acknowledgment in the welfare section.

### 4. Spillovers
Acknowledged as limitation but note geographic isolation of many treated municipalities limits scope for large spillovers.

---

## Reviewer 3 (Gemini) — MINOR REVISION

### 1. Reconcile population vs. vacancy magnitudes
Added discussion acknowledging the apparent disproportionality and offering interpretation: construction decline directly eliminates jobs (population effect) while vacancy effect is measured at a point in time.

### 2. RDD power
Acknowledged underpowered RDD, added explicit p-values to Table 3.

### 3. Internal migration
Noted as important limitation for future work.
