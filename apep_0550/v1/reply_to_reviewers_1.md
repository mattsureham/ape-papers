# Reply to Reviewers — Round 1

## Reviewer 1 (GPT-5.4 R1): REJECT AND RESUBMIT

### 1. "Exposure is conceptual, not observed" (§1.2)
**Response:** We acknowledge this limitation explicitly in the expanded Limitations section. APMC stringency is a proxy for treatment intensity, not a direct measure of implementation. Without administrative data on trade volumes flowing through vs. outside mandis, we cannot verify the first stage. We frame the finding as "no evidence of large retail price effects" rather than "no policy effect."

### 2. "Parallel trends asserted more than demonstrated" (§1.3)
**Response:** Added: (a) formal linear pre-trend test (WLS regression of event-study coefficients on time, p = 0.43); (b) state-specific linear trends specification (ON coefficient shrinks to 0.018, SE = 0.108). The event study coefficients are now available in a data CSV for inspection.

### 3. "Symmetric design oversold" (§1.4)
**Response:** Substantially revised. Removed "remarkably clean" and "powerful" language. Added β1 = β2 equality test (p = 0.34). Acknowledged that β2 is a post-Feb-2021 differential relative to pre-period, not a direct reversal estimate. Split OFF into post-stay and post-repeal sub-periods.

### 4. "Timing choices need validation" (§1.5)
**Response:** Added narrow-window robustness (2019-2022). Alternative onset dates would further strengthen the paper but the ON period is already only 8 months; shortening it further reduces power below useful levels.

### 5. "Outcome not tightly matched to mechanism" (§1.6)
**Response:** Extensively revised. Conclusions now explicitly state "these findings apply specifically to monitored retail prices; wholesale price effects and farm-gate outcomes remain open questions." The political economy discussion acknowledges that farmer protests were about MSP and bargaining power, not retail prices.

### 6. "Composition and missingness" (§1.7)
**Response:** Added balanced-sample analysis restricting to 122 state-commodity cells observed in all three phases (N = 6,501). Results are nearly identical (ON: 0.049, OFF: 0.214). This directly addresses the concern that changing market composition drives the null.

### 7. "Wild cluster bootstrap needed" (§2.1)
**Response:** Attempted WCB using fwildclusterboot but it is incompatible with feols + high-dimensional fixed effects in the current R package version. RI (1,000 permutations, p = 0.52) provides the primary non-parametric inference complement. We cite Cameron, Gelbach, Miller (2008) and acknowledge the 28-cluster limitation explicitly.

### 8. "RI not a complete solution" (§2.2)
**Response:** Revised: no longer called "the strongest evidence." Now described as "a complementary, non-parametric assessment that does not rely on asymptotic approximations."

### 9. "Precisely estimated null" overclaimed (§2.3)
**Response:** Removed "precisely estimated null" throughout. Replaced with "no evidence of large retail price effects" and explicit CI bounds ([-0.10, 0.22] for ON).

### 10. "Reverse-treatment placebo uninformative" (§3.3)
**Response:** Now acknowledged as "mechanically the mirror image" and "not independently informative in a linear model." Added 7 alternative placebo onset dates as more meaningful falsification.

### 11. "Recalibrate claims" (§5)
**Response:** Abstract, introduction, and conclusion comprehensively revised. Claims narrowed to monitored retail prices. Political economy section acknowledges protests were about margins this paper cannot measure.

---

## Reviewer 2 (GPT-5.4 R2): MAJOR REVISION

### 1. "Identifying assumption stronger than acknowledged" (§A)
**Response:** Added state-specific trends and balanced-sample robustness. Both confirm null. The Limitations section now explicitly lists the identification concerns.

### 2. "Symmetric reversal conceptually overstated" (§B)
**Response:** Revised as described above. Added equality test, split OFF, toned down rhetoric.

### 3. "Parallel trends asserted, not demonstrated" (§C)
**Response:** Added formal pre-trend test (p = 0.43). Event study coefficients available in data.

### 4. "Treatment intensity not validated" (§D)
**Response:** Acknowledged. Results using cess rate only (Column 3) and binary treatment (Column 2) confirm null across all treatment measures, providing partial validation.

### 5. "Aggregation raises composition concerns" (§E)
**Response:** Balanced-sample analysis directly addresses this.

### 6. "Standard errors — few cluster concern" (§A, Inference)
**Response:** RI provides non-parametric complement. WCB implementation failed due to package limitations.

### 7. "Cannot claim precisely estimated null" (§C, Inference)
**Response:** Language revised throughout.

### 8. "Shorten and stratify OFF period" (§8)
**Response:** Done. Post-stay: 0.254 (0.186); Post-repeal: 0.176 (0.198). Both insignificant.

### 9. "Replace weak placebo tests" (§7)
**Response:** Added 7 alternative placebo dates. Reverse-treatment demoted with explicit caveat.

---

## Reviewer 3 (Gemini-3-Flash): MAJOR REVISION

### 1. "Wholesale data comparison"
**Response:** Acknowledged as key limitation. AGMARKNET data proved inaccessible. Future research direction noted in Discussion and Conclusion.

### 2. "External validity / implementation certainty"
**Response:** Expanded Discussion section to distinguish between "test of the laws" vs "test of temporary, contested laws." Limitations section addresses this explicitly.

### 3. "Heterogeneity by distance"
**Response:** WFP market locations at the state level do not permit border-proximity analysis. Noted as future research direction.
