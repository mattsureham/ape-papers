# Research Plan: The No-Advice Trap — Contingent Charging Ban and Pension Transfer Complaints

## Research Question

When the FCA banned contingent charging for defined benefit pension transfer advice in October 2020 (PS20/6), did it reduce consumer harm from unsuitable transfer recommendations? Under the old regime, advisers paid only if clients transferred — creating a 68% vs 28% conversion rate gap between contingent and non-contingent firms. We estimate whether eliminating this conflict of interest reduced complaints to the Financial Ombudsman Service.

## Identification Strategy

**Product-level Difference-in-Differences.** Treatment: Occupational pension transfer complaints (product directly subject to the contingent charging ban). Controls: Annuity complaints, personal pension complaints, SIPPs (products not subject to the ban).

**Key identification argument:** The contingent charging ban exclusively affected DB pension transfer advice. Annuities, personal pensions, and SIPPs involve different advisory relationships and were not subject to PS20/6. The parallel trends assumption requires that absent the ban, DB transfer complaints would have trended similarly to control product complaints.

**Inference challenge:** Single treated product category. Address through: (i) permutation inference (randomly assign treatment to each product category), (ii) comparison against each control product separately, (iii) a COVID placebo test (March 2020 lockdown affected all products symmetrically).

## Expected Effects and Mechanisms

1. **Reduction in complaints:** If the ban eliminated conflicted advice, unsuitable transfer complaints should fall
2. **The no-advice trap:** If advisers exit the market rather than switch to non-contingent models, complaint reduction could reflect LESS ADVICE (fewer transfers) rather than BETTER ADVICE
3. **Composition shift:** Remaining advisers may be higher quality → lower upheld rate at FOS
4. **Delayed effect:** Complaints lag advisory activity by 6-18 months (complaint pipeline)

**Magnitude prior:** If complaints tracked the 60% drop in contingent charging firms documented in FCA EP25/1, expect moderate negative SDE. But if the no-advice trap dominates, aggregate complaints could remain stable while composition changes.

## Primary Specification

$$Y_{pt} = \alpha_p + \gamma_t + \beta \cdot (\text{DBTransfer}_p \times \text{Post}_{t \geq Q4\ 2020}) + \varepsilon_{pt}$$

Where $Y_{pt}$ is new complaints for product $p$ in quarter $t$, with product and quarter fixed effects. Permutation p-values for inference (5 products → 5 permutations for exact test).

## Data Source and Fetch Strategy

1. **Financial Ombudsman Service (FOS):** Quarterly complaints data by product category, published as Excel files on financial-ombudsman.org.uk. Covers Q1 2014/15 through Q4 2024/25 (44 quarters). Variables: new cases, ombudsman decisions, % upheld, by pension product.
2. **FCA Register data:** Number of firms authorized for pension transfer advice — from FCA data download portal.
3. **FCA EP25/1 statistics:** Market structure data (contingent vs non-contingent charging share) for mechanism evidence.

## Exposure Alignment

The FCA's contingent charging ban (PS20/6) applies to all regulated firms providing DB pension transfer advice. The treatment directly affects **advisory firms** — they must change their charging model. The outcome measures **consumer complaints** about DB transfers filed with the FOS. The alignment is indirect: the ban changes adviser incentives → this changes the quality/volume of advice → this changes the quality/volume of complaints reaching the FOS. The treated product category at the FOS (DB transfers) captures the downstream effect of the ban on consumer harm, not the firm-level response. Critically, the ban applies nationally and simultaneously — all firms are treated at the same time — so variation comes only from the product dimension (DB transfers vs other pension products).

## Limitations (stated upfront)

- **Single treated product:** One product category receives treatment — standard DiD inference inappropriate. Use permutation inference and synthetic control weights.
- **COVID confound:** Pandemic disrupted FOS operations in Q4 2019/20 through Q2 2020/21. The ban took effect during COVID recovery — test robustness excluding these quarters.
- **Complaint pipeline lag:** Complaints reflect advisory activity 6-18 months prior; effects may appear with delay.
- **Composition vs access:** Cannot separately identify "better advice" from "less advice" with complaint data alone.
