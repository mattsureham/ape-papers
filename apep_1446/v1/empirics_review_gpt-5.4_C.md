# V1 Empirics Check — openai/gpt-5.4 (Variant C)

**Model:** openai/gpt-5.4
**Variant:** C
**Date:** 2026-04-09T14:51:34.429649

---

## 1. **Idea Fidelity**

The paper follows the spirit of the manifest—a provider-entry study around the January 2023 X-waiver elimination using T-MSIS linked to NPPES geography—but it does **not** faithfully implement the strongest version of the original idea.

Most importantly, the paper shifts from “buprenorphine prescribers” to **injectable buprenorphine J-code billers** only. That is a major narrowing, and it changes the question substantially. Injectable buprenorphine is a niche modality relative to office-based buprenorphine treatment more broadly, so the paper is not really testing whether X-waiver elimination expanded access to buprenorphine prescribing in general. The manifest also proposed distinguishing entry into **deserts vs. thick already-served markets (e.g., 5+ prior NPIs)** and examining **patients per new entrant, months-to-first-patient, and survival**. The paper keeps survival, but drops the richer market-thickening design and instead uses a much coarser desert/non-desert split defined off 2022 injectable billing.

So: yes, the paper pursues the original broad question, but it misses key elements of the proposed identification and, more seriously, narrows the outcome to a slice of treatment that is too limited to support the paper’s headline claims.

## 2. **Summary**

This paper asks whether the January 2023 elimination of the X-waiver induced new buprenorphine providers to enter previously unserved counties or simply expand supply in counties that were already active. Using T-MSIS claims linked to provider location data, it finds that post-2023 entrants overwhelmingly appear in previously served counties, with little entry into counties classified as deserts.

The paper’s core message is potentially important: deregulation may have increased participation on paper without materially improving geographic access. But in its current form, the evidence is too narrow and the design too mechanical to sustain the paper’s stronger policy conclusions.

## 3. **Essential Points**

1. **The outcome does not match the policy question.**  
   The paper uses only injectable buprenorphine J-codes (J0571–J0575). That is not the relevant universe for studying the X-waiver’s elimination, which primarily matters for office-based prescribing of buprenorphine more broadly. The claim that “96.7% of counties lacked even a single Medicaid provider” is therefore not a plausible statement about buprenorphine access; it is a statement about **Medicaid injectable-buprenorphine billing in this dataset**. That distinction is crucial. As written, the paper overstates scarcity and overinterprets the results.

2. **The DiD is mechanically driven and not very informative about causal effects.**  
   “Desert” is defined by having zero prior providers, and the outcome is new entrant counts in a setting where pre-treatment outcomes are essentially zero for deserts by construction. The paper even acknowledges that pre-trends are “trivially satisfied.” That is precisely the problem: this is not a compelling parallel-trends design. With a single national shock, only 101 non-desert counties, and an outcome whose support is highly sparse, the DiD coefficient mostly redescribes cross-sectional concentration rather than identifying a policy-induced differential response.

3. **The policy interpretation is too strong relative to the evidence.**  
   The conclusion that “the binding constraint is provider willingness, not legal permission” goes beyond what the design can show. At most, the paper shows that among Medicaid injectable-buprenorphine billers, post-2023 entry was concentrated in already active counties. That could reflect modality choice, Medicaid participation, telehealth coding, billing conventions, provider organization, or uptake dynamics—not just willingness. The paper needs to scale back the claims substantially unless it broadens the data and analysis.

## 4. **Suggestions**

The paper has a good instinct and an interesting descriptive pattern. To make it publishable in an AER: Insights-type format, I would strongly encourage the authors to reframe it as a **carefully bounded geographic incidence paper** and to rebuild some parts of the empirical design.

First, **fix the measurement problem**. The single biggest issue is that injectable J-codes are too narrow to proxy for buprenorphine treatment access. If T-MSIS allows identification of buprenorphine use through NDCs, pharmacy claims, or other outpatient service records, the paper should incorporate them. If not, the title, abstract, introduction, and conclusion must repeatedly say that the analysis concerns **injectable Medicaid buprenorphine billing**, not buprenorphine prescribing overall. Right now, the paper slides between those concepts too easily. A seasoned reader will immediately question the plausibility of the claim that only 101 counties in the United States had a Medicaid buprenorphine provider before 2023. That is not plausible as a statement about treatment access in general, and the paper should not invite that reading.

Relatedly, I would urge the authors to present a **sanity-check table on magnitudes**. For example: how many counties have any buprenorphine-related claims under broader coding? How do your counts compare with IQVIA, SAMHSA waivered-provider counts pre-2023, DEA registrant counts, or state Medicaid reports? Even if the match is imperfect, readers need anchoring evidence. At present, the headline magnitude—96.7% deserts—is so extreme that it undermines confidence in the construct.

Second, **recast the empirical strategy away from a formal DiD as the main contribution**. The current DiD is not wrong in a narrow algebraic sense, but it is not persuasive. Treatment is defined off lagged outcome status, pre-period variance in the treated group is nearly degenerate, and the policy shock is national. This is a setting where a transparent descriptive design may be more convincing than a thin causal veneer. I would recommend leading with:
- the cross-sectional destination of entrants,
- entrant shares by prior market thickness (0, 1, 2–4, 5+ prior NPIs),
- entrant counts normalized by county population or Medicaid enrollment,
- and event-time plots of entry by baseline market thickness.

That would better match the original idea from the manifest: did the policy open new markets or merely thicken old ones? The 0 vs. 1+ split is too blunt. A table showing where the 189 entrants went across the distribution of prior provider density would be much more informative economically.

If the authors retain regression analysis, they should use models tailored to the data’s structure. The outcome is a **very sparse count**, so an OLS TWFE on county-month counts is a fragile choice. Consider:
- Poisson pseudo-maximum-likelihood with county and month fixed effects,
- or a linear probability/event-hazard model at the county-month level for “first entrant arrives,”
- or an entrant-level location-choice framework where the alternative set is baseline county type.

Each of these would be more natural than the current specification. At a minimum, the paper should show that the core pattern survives Poisson or negative-binomial-type approaches.

Third, **improve inference**. County-clustered standard errors are not necessarily appropriate here as the central inferential device. You have a single national treatment date, highly unbalanced groups (2,993 deserts, 101 non-deserts), and very sparse outcomes. Clustering at the county level may understate uncertainty about common post shocks interacting with baseline county type. I appreciated the permutation exercise, but it is not enough in the present form. I would suggest:
- wild-cluster bootstrap or randomization inference built around the county-type assignment,
- state-level clustering as a robustness check,
- collapsing to pre/post county-level changes and showing inference there,
- and reporting exact or permutation-based p-values more prominently than conventional clustered ones.

More fundamentally, the paper should stop leaning on “***” significance as if this were a standard many-treated-units DiD. The key question here is economic magnitude and external validity, not whether 0.088 clears a threshold.

Fourth, **tighten the interpretation of magnitudes**. The coefficient of -0.088 new entrants per county-month is hard to interpret in isolation. Since there are only 101 non-desert counties, that implies roughly 8.9 entrant-county events per month in non-deserts relative to deserts post period—a large flow relative to 189 total entrants over two years. The paper should walk readers through the arithmetic carefully. Likewise, the statement that per-county entry rates are “approximately 180 times higher” in non-deserts than deserts is mathematically true because the desert rate is near zero, but it is not very informative. Better to present shares of entrants, shares of counties, and implied expected entrant counts over a year.

Fifth, **address telehealth and location measurement much more seriously**. This is not a minor caveat. For addiction treatment after COVID, telehealth is central, and billing/provider-office location may be poorly aligned with where access improved. If a provider in an urban county starts treating patients in rural counties remotely, your county-of-provider analysis will miss that. Since the paper’s whole contribution is about geography, this issue belongs near the front, not buried as a caveat. If patient county is available in T-MSIS, even in aggregated form, the authors should examine whether beneficiaries in desert counties experienced any uptake after 2023 regardless of provider location. That would dramatically strengthen the paper.

Sixth, **the beneficiary null result needs more work**. A coefficient of 0.413 with an SE of 6.961 is essentially uninformative, not informative evidence of “market thickening.” If the beneficiary outcome is too noisy, say so. Alternatively, redefine it more sensibly: beneficiaries per active provider, beneficiaries per entrant, or county-level probability of any buprenorphine-treated beneficiary. As written, the paper uses an imprecise null to support a strong mechanism, which is not convincing.

Seventh, I would **scale back the rhetorical framing**. Phrases like “credential gap fallacy” and “the right policy for the wrong problem” are punchy, but they overstate what these data can support. A more defensible conclusion would be: *within Medicaid injectable buprenorphine billing, post-waiver entry was concentrated in already active counties, suggesting that deregulation alone may not be sufficient to expand care into previously unserved areas.* That is still policy relevant, and it is much harder to knock down.

Eighth, the paper would benefit from a few **simple descriptive additions**:
- a map of baseline county categories and post-2023 entrant destinations;
- a histogram of prior market thickness for entrant destination counties;
- a table by provider specialty/taxonomy (physician, NP, PA, addiction medicine, psychiatry, primary care);
- and state-level heterogeneity, since Medicaid reimbursement and addiction-treatment infrastructure vary enormously across states.

These would make the result more economically meaningful. Right now the paper shows concentration, but not enough about where, by whom, and under what market conditions.

Finally, I think the paper should more clearly distinguish **three claims** that are currently bundled together:
1. the policy increased the number of Medicaid injectable-buprenorphine billers;
2. those entrants disproportionately appeared in already active counties;
3. therefore legal barriers were not the binding constraint on access.

The first is descriptive and likely true. The second is interesting and likely true in these data. The third is much harder and currently not established. If the paper narrows itself to the first two, improves measurement, and presents the geography more transparently, it could become a useful short paper. In its current form, however, the headline conclusion outruns the evidence.
