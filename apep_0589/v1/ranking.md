# Research Idea Ranking

**Generated:** 2026-03-10T16:06:22.128286
**Models:** GPT-5.4 (A), GPT-5.4 (B)
**Reasoning:** high

## Comparison Table

| Idea | GPT-5.4 (A) | GPT-5.4 (B) |
|------|------|------|
| ERDF Treatment Withdrawal and Regional C... | PURSUE (69) | PURSUE (68) |
| EU Geo-Blocking Ban and Cross-Border Pri... | CONSIDER (52) | CONSIDER (57) |
| Staggered PSD2 Transposition and Consume... | None (46) | SKIP (41) |

---

## GPT-5.4 (A)

**Tokens:** 10822

### Rankings

**#1: ERDF Treatment Withdrawal and Regional Convergence: Evidence from Regions Graduating Through the 75% Threshold**
- **Score:** 69/100
- **Strengths:** This asks a meaningful and policy-relevant question: do place-based subsidies create durable convergence, or only temporary gains while funding lasts? The 75% rule gives a recognizable quasi-experimental margin, and the data backbone is stronger than in the other proposals.
- **Concerns:** The novelty is narrower than claimed because the ERDF 75% threshold is already a classic design in the literature. The main empirical risk is that “graduation” is bundled with mean reversion, post-crisis recovery, and complicated transition-region rules, with only a modest number of near-cutoff regions.
- **Novelty Assessment:** **Moderately novel.** EU structural funds and the 75% threshold are well studied; the withdrawal/graduation angle is less studied and potentially useful, but this is an extension of an established literature rather than a new policy object.
- **Top-Journal Potential:** **Medium.** This could be an **AEJ: Economic Policy**-type paper if framed around a big question—whether regional aid creates self-sustaining growth or subsidy dependence—and tied to a clear mechanism. Top-5 potential is limited unless the paper delivers a sharp, surprising causal chain rather than just another threshold ATE.
- **Identification Concerns:** You need to show a strong first stage in actual ERDF intensity at the 2014 boundary after accounting for phase-out/transition categories. Because the running variable is regional GDP itself, local mean reversion and prior-treatment-induced threshold crossing are serious threats.
- **Recommendation:** **PURSUE (conditional on: documenting a large discontinuity in actual payments/co-financing after 2014; handling transition/phasing-out exceptions cleanly; keeping spillover analysis secondary unless it is very convincing)**

---

**#2: EU Geo-Blocking Ban and Cross-Border Price Convergence: Triple-Difference Evidence**
- **Score:** 52/100
- **Strengths:** The underlying question is strong: consumer prices and market integration are first-order outcomes, and the regulation’s explicit exclusions create an attractive built-in placebo structure. It is also a relatively fresh policy area.
- **Concerns:** As proposed, the data look mismatched to the question. HICP monthly indices are not clean cross-country online price-level data, so the design may not actually measure “price convergence,” and the covered-goods vs excluded-services comparison is vulnerable to obvious nonparallel trends.
- **Novelty Assessment:** **Fairly novel.** I do not know of a saturated causal literature on this exact geo-blocking margin, and the exclusion-based DDD appears new. But novelty is not enough if the outcome is not the right object.
- **Top-Journal Potential:** **Low.** Prices are top-journal-friendly, but only when measured directly and credibly. With broad HICP categories, this would likely read as indirect and non-decisive rather than field-shifting.
- **Identification Concerns:** Excluded services are a weak control group because they are structurally different markets with different demand, regulation, and pandemic exposure. More basically, index data normalized around a base year make cross-country convergence hard to interpret as a policy effect.
- **Recommendation:** **CONSIDER**

---

**#3: Staggered PSD2 Transposition and Consumer Internet Banking Adoption**
- **Score:** 46/100
- **Strengths:** There is some incremental novelty in using staggered national transposition dates rather than a single EU adoption date, and the data are at least accessible. The topic is policy-relevant in digital finance.
- **Concerns:** The main outcome is too far from the policy margin: PSD2 is about API access, competition, and third-party providers, not whether households use “internet banking” at all. The timing variation is also plausibly endogenous to digital readiness and state capacity.
- **Novelty Assessment:** **Somewhat novel, but not very.** PSD2/open banking is not a saturated literature, but exploiting transposition timing is more a design tweak than a major new question.
- **Top-Journal Potential:** **Low.** Even with clean execution, “PSD2 increased internet banking adoption” is not a particularly compelling general-interest result. The more interesting outcomes—fin

---

## GPT-5.4 (B)

**Tokens:** 7699

### Rankings

**#1: ERDF Treatment Withdrawal and Regional Convergence: Evidence from Regions Graduating Through the 75% Threshold**
- **Score:** 68/100
- **Strengths:** This asks a genuinely important policy question with a strong institutional margin: does EU regional aid create durable convergence, or does performance fade when support is withdrawn? The graduation/withdrawal framing is more novel than the classic Objective 1 eligibility papers, and the spillover angle could give the paper a more interesting causal chain.
- **Concerns:** The design is less clean than a standard sharp threshold story suggests: “graduation” often came with transitional arrangements, and actual payments can lag formal programming periods. The local sample near the cutoff may be quite small, so inference could be fragile and heavily bandwidth-dependent.
- **Novelty Assessment:** **Moderately novel.** The underlying ERDF/Objective 1 threshold literature is already substantial, so this is not a new policy domain. But I am not aware of many papers centered specifically on the treatment-withdrawal shock at graduation, and the cross-border spillover test is a useful added margin.
- **Top-Journal Potential:** **Medium.** A top field journal could find this attractive if it clearly shows whether cohesion policy creates persistence versus dependency, especially with a mechanism from funding withdrawal to employment/sectoral change to GDP. Top-5 potential is limited because regional convergence under EU funds is already a mature literature unless the result is very surprising and the first stage is exceptionally sharp.
- **Identification Concerns:** The paper must demonstrate a clear discontinuity in **realized** ERDF intensity/co-financing at the threshold after accounting for phasing-out rules and spending lags. Because the running variable is GDP-based, mean reversion and limited local support around the cutoff are serious threats.
- **Recommendation:** **PURSUE (conditional on: documenting a strong first-stage in actual ERDF payments/co-financing; handling transitional-status and payment-lag issues explicitly; keeping the paper centered on one main outcome chain rather than many parallel outcomes)**

**#2: EU Geo-Blocking Ban and Cross-Border Price Convergence: Triple-Difference Evidence**
- **Score:** 57/100
- **Strengths:** The policy itself is relatively under-studied, and the exclusion structure is a clever source of within-policy contrast. Price convergence is also an economically legible outcome that matters for the EU single market.
- **Concerns:** The biggest problem is outcome mismatch: HICP is not the object the regulation directly changes, which is cross-border online access and transaction terms. Covered goods and excluded services are structurally different, so the DDD could easily pick up unrelated differential trends rather than geoblocking effects.
- **Novelty Assessment:** **Fairly novel.** I do not know of a well-known causal paper using the regulation’s exclusions in this exact DDD setup. That said, novelty is being purchased partly by using a weaker outcome than one would ideally want.
- **Top-Journal Potential:** **Low.** In its current form this looks like a competent policy evaluation, not a paper likely to reshape how economists think about digital-market integration. It would become much more compelling with product-level online prices, seller availability, or direct measures of cross-border purchasing.
- **Identification Concerns:** The key parallel-trends assumption is shaky because excluded services differ from treated goods in tradability, cost structure, and regulation. The post-2018 period also overlaps COVID and broader e-commerce changes, which makes attribution difficult with aggregate price indices.
- **Recommendation:** **CONSIDER (conditional on: obtaining direct online price or web-scraped retailer data; validating pre-trends convincingly; restructuring the design around country-pair/product-level dispersion rather than national HICP averages alone)**

**#3: Staggered PSD2 Transposition and Consumer Internet Banking Adoption**
- **Score:** 41/100
- **Strengths:** Open banking is policy-relevant, and staggered transposition at least creates some timing variation. With better outcomes, the broader topic could support a useful paper on fintech competition or bank behavior.
- **Concerns:** The current outcome is too far from the policy mechanism: internet banking usage is a blunt secular-trend variable, not a direct measure of open-banking adoption or competition. Transposition timing is also plausibly endogenous to country capacity and digital readiness, so the design is not very credible as stated.
- **Novelty Assessment:** **Limited to moderate.** The exact staggered-date design may be less exploited, but PSD2/open banking is already a well-discussed area, and “does PSD2 increase internet banking use?” is not a fresh or especially surprising question.
- **Top-Journal Potential:** **Low.** This currently reads as a timing-based DiD with a weakly matched outcome, which is exactly the kind of “technically competent but not exciting” paper that struggles. It would need a much sharper mechanism and better data to become field-journal material.
- **Identification Concerns:** Legal transposition dates are unlikely to equal economically meaningful treatment dates; the relevant rollout often came later through API implementation, regulatory standards, and TPP entry. That treatment mismeasurement, combined with likely endogenous delay, undermines causal interpretation.
- **Recommendation:** **SKIP**

### Summary

This is a mixed batch: one idea worth pushing, one that is interesting but currently underpowered by the wrong data, and one that I would not spend scarce research capacity on. I would pursue **Idea 1** first, but only with a hard check on the first stage and transitional-funding complications; **Idea 2** is salvageable if you can get direct online price data; **Idea 3** should be dropped in its current form.

