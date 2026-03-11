# Internal Claude Code Review — Round 1

**Role:** Internal referee (Reviewer 2, skeptical)
**Paper:** When Harmonization Codifies the Status Quo: The EU Mortgage Credit Directive and Lending Rates
**Timestamp:** 2026-03-11T17:00:00

---

## 1. IDENTIFICATION AND EMPIRICAL DESIGN

The identification relies on staggered transposition of the MCD across 18 euro area countries. The key assumption—that transposition timing is as-good-as-random conditional on country and time FE—is plausible but not ironclad. The paper correctly identifies the main threat (country-specific macro-financial dynamics correlating with timing) and addresses it with country-specific linear trends, which is the most targeted robustness check available.

**Strengths:**
- Sun-Abraham estimator properly handles heterogeneous treatment effects in staggered design
- Balanced panel vs unbalanced TWFE comparison isolates methodological vs sample effects
- Country-specific trends directly address the main identification threat

**Concerns:**
- The latest-treated cohort (Spain) serves as the SA-IW reference group. Spain is idiosyncratic (deep housing crisis, late recovery). Some discussion of how much identifying weight comes from Spain would strengthen the design section.
- Treatment measured at notification rather than effective date. The paper acknowledges this but could be more explicit about the ITT interpretation.

## 2. INFERENCE AND STATISTICAL VALIDITY

Standard errors are properly clustered at the country level. Wild cluster bootstrap and randomization inference are appropriate for 18 clusters. The paper no longer overclaims precision—the revised "What Can the Data Rule Out?" section is honest about the CI bounds.

**The SA-IW vs TWFE SE gap** is now properly explained (cost of robustness, not misspecification). The balanced-sample TWFE comparison (-0.022, SE 0.123) confirms this.

Sample sizes are coherent: 828 (unbalanced TWFE, 18 countries), 768 (balanced, 16 countries), 457 (temporal placebo).

## 3. ROBUSTNESS AND ALTERNATIVE EXPLANATIONS

The robustness battery is now comprehensive: baseline SA-IW, unbalanced TWFE, balanced TWFE, country-specific trends, RI, temporal placebo, WCB, leave-one-out, consumer credit placebo. This is a thorough set of checks.

The consumer credit placebo is well-designed—it verifies the design doesn't generate spurious effects on an untreated outcome.

**Remaining gap:** The heterogeneity analysis (3 stringent countries) is admittedly coarse. The paper now acknowledges this explicitly, which is appropriate.

## 4. CONTRIBUTION AND LITERATURE POSITIONING

Literature coverage is adequate. Citations include Sun-Abraham, Goodman-Bacon, de Chaisemartin-D'Haultfoeuille, Borusyak et al., Callaway-Sant'Anna, and Roth et al. The policy literature (Abadie 2020, Enriques 2015) is well-integrated.

The contribution—documenting a null effect of conduct-of-business harmonization when national practice has already converged—is clearly differentiated from studies of structural reforms (CRD IV, SSM) that show significant effects.

## 5. RESULTS INTERPRETATION AND CLAIM CALIBRATION

Claims are now well-calibrated. The paper appropriately:
- States "no detectable effect" rather than "precise null"
- Acknowledges that moderate effects below 0.2pp cannot be excluded
- Presents the codification mechanism as "consistent with" evidence rather than proven
- Notes the euro-area scope limitation in the abstract and conclusion

The title ("When Harmonization Codifies the Status Quo") is appropriate—descriptive rather than overclaiming.

## 6. ACTIONABLE REVISION REQUESTS

### Must-fix: None remaining

### High-value improvements:
1. **Discuss Spain's role as reference cohort.** A sentence in the Estimation section noting the identifying weight from the latest cohort would be valuable.
2. **Joint F-test for pre-trends.** The paper mentions it in the appendix but doesn't report the statistic. Include it.

### Optional polish:
3. The HonestDiD section mentions "1.45 pp max pre-treatment violation" which sounds alarming. Could add context that this is in absolute terms across many quarters with wide individual CIs.

## 7. OVERALL ASSESSMENT

### Key strengths:
- Important policy question with real data
- Modern DiD methodology properly implemented
- Comprehensive robustness battery
- Well-calibrated claims after revision
- Clear institutional context

### Critical weaknesses:
- Heterogeneity analysis limited by coarse classification (3 stringent countries)
- No extensive-margin outcomes available
- Treatment timing measurement imprecise

### Publishability:
Suitable for AEJ: Economic Policy or a policy-oriented general-interest journal. The paper makes a genuine contribution by documenting that conduct-of-business harmonization may have limited effects when national practice has already converged. The revised framing appropriately matches the evidence.

DECISION: MINOR REVISION
