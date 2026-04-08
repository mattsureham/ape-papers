# V1 Empirics Check — mistralai/mistral-large-2512 (Variant A)

**Model:** mistralai/mistral-large-2512
**Variant:** A
**Date:** 2026-04-08T11:45:44.819457

---

### 1. Idea Fidelity

The paper closely adheres to the original idea manifest, successfully executing the proposed dose-response analysis of Singapore’s escalating Additional Buyer’s Stamp Duty (ABSD) on foreign purchasers. Key elements of the identification strategy—differential foreign-buyer exposure across market segments (CCR vs. OCR/RCR), staggered treatment timing (five ABSD hikes), and the use of HDB public housing as a within-market control—are all faithfully implemented. The paper also extends the original idea by incorporating rental spillovers and a triple-difference specification to test the displacement hypothesis, which was hinted at but not fully developed in the manifest.

Two minor deviations are worth noting:
- The manifest mentions using "complete URA transaction data," but the paper relies on aggregated quarterly price/rental indices and transaction volumes rather than individual transaction-level data. This limits the ability to explore heterogeneity (e.g., by property type or buyer nationality) or to implement more granular event-study designs.
- The manifest proposes a "CS-DiD" (Callaway-Sant’Anna difference-in-differences) approach, but the paper uses a simpler two-way fixed-effects (TWFE) specification with Driscoll-Kraay standard errors. While the TWFE approach is reasonable given the small number of clusters (3 segments), the paper does not engage with recent critiques of TWFE in staggered settings (e.g., Goodman-Bacon 2021, de Chaisemartin and D’Haultfœuille 2020).

Overall, the paper delivers on the core promise of the manifest: a credible dose-response analysis of ABSD effects using modern DiD methods.

---

### 2. Summary

This paper exploits Singapore’s five staggered increases in the Additional Buyer’s Stamp Duty (ABSD) on foreign purchasers (2011–2023, 0% to 60%) to estimate the causal effects of escalating capital controls on housing prices, rents, and transaction volumes. Using differential foreign-buyer exposure across market segments (Core Central Region [CCR] vs. Outside Central Region [OCR]), the authors find that ABSD significantly suppressed prices and transactions in high-exposure segments, with a cumulative 39% decline in CCR prices relative to controls. Rental prices fell by only 7%, revealing an asymmetric response: ABSD reduces foreign demand for ownership without proportionally displacing it to rental markets. The results are robust to placebo tests, pre-trend checks, and alternative specifications, and they inform global debates about the efficacy of foreign-buyer taxes.

---

### 3. Essential Points

The paper is methodologically sound and makes a valuable contribution, but three critical issues must be addressed before publication:

#### (1) **Clarify the Identification Strategy in Light of Staggered Treatment and TWFE Limitations**
The paper uses a two-way fixed-effects (TWFE) DiD specification with staggered treatment timing, which has been shown to produce biased estimates when treatment effects are heterogeneous across units or time (e.g., Goodman-Bacon 2021, de Chaisemartin and D’Haultfœuille 2020). While the authors acknowledge the "few-cluster problem" and use Driscoll-Kraay standard errors, they do not discuss whether their TWFE estimates might be contaminated by "negative weighting" or other biases inherent to staggered designs.

**Required revisions:**
- Report event-study coefficients (e.g., leads and lags around each ABSD hike) to assess dynamic effects and pre-trends visually. The current pre-trend test (Table 4, Column 1) is insufficient because it only tests for a linear trend in the pre-period, not differential trends in the *leads* of treatment.
- Compare TWFE results to estimates from a more robust staggered DiD estimator (e.g., Callaway-Sant’Anna 2021 or Sun-Abbring 2020). If the results are similar, this would strengthen confidence in the findings. If not, the authors should justify their choice of TWFE or switch to the more robust estimator.
- Discuss whether the "dose-response" interpretation is valid in a staggered setting. The current specification assumes that the effect of each round is additive, but this may not hold if later rounds interact with earlier ones (e.g., if the 60% rate in 2023 has a different effect because the market has already adjusted to prior rounds).

#### (2) **Address Potential Confounding from Concurrent Policies**
The ABSD was introduced alongside other cooling measures (e.g., LTV limits, TDSR, SSD), which the authors argue are "nationality-blind" and thus should not bias the CCR vs. OCR comparison. However, these policies may have *differential* effects across segments if, for example, high-end properties (disproportionately in the CCR) are more sensitive to LTV limits. The paper does not adequately rule out this possibility.

**Required revisions:**
- Test for differential trends in CCR vs. OCR *during periods when only non-ABSD policies were active* (e.g., between ABSD hikes). If CCR and OCR diverge during these periods, it would suggest that other policies are confounding the ABSD effect.
- Include controls for concurrent policies (e.g., LTV limits, TDSR thresholds) in the main specifications to isolate the ABSD effect. If the coefficients on CCR × Post-ABSD remain stable, this would strengthen the causal interpretation.
- Discuss whether the timing of other policies (e.g., SSD changes) aligns with ABSD hikes in a way that could bias the results. For example, if SSD was tightened in 2018 alongside the ABSD increase, the estimated effect of the 2018 ABSD hike might be overstated.

#### (3) **Improve the Rental Market Analysis**
The paper’s central claim—that ABSD suppresses ownership demand without displacing it to rental markets—rests on the finding that rental prices fell by less than ownership prices. However, the rental market analysis has two key limitations:
- **Measurement of rental demand:** The paper assumes that rental price changes reflect changes in demand, but rental prices are also influenced by supply (e.g., if ABSD reduces condominium purchases, fewer units may be available for rent). The authors should discuss whether the rental price decline could reflect a *supply* contraction rather than weak displacement.
- **Lack of transaction-level data:** The rental index is aggregated at the segment-quarter level, making it impossible to distinguish between changes in rental *prices* and changes in the *composition* of rented units (e.g., if ABSD causes a shift toward lower-quality rentals). The authors should acknowledge this limitation and discuss whether it could bias the results.

**Required revisions:**
- Test whether the *volume* of rental transactions (if available) changes after ABSD hikes. If rental volumes fall alongside prices, this would support the supply contraction hypothesis.
- Discuss whether the rental index adequately controls for quality changes (e.g., if ABSD causes a shift toward smaller or older units being rented). If not, the rental price decline might understate the true effect on rental demand.
- Consider an alternative specification where the outcome is the *price-to-rent ratio* (a proxy for the "ownership premium"). This would directly test whether ABSD widens the gap between ownership and rental values.

---

### 4. Suggestions

The following recommendations are non-essential but would strengthen the paper:

#### (1) **Enhance the Theoretical Framework**
The paper briefly mentions the "ownership premium" channel but does not develop a formal model to explain why foreigners might value ownership more than renting. A simple theoretical section could:
- Formalize the idea that foreigners derive utility from ownership beyond rental returns (e.g., wealth storage, residency signaling, portfolio diversification).
- Show how ABSD taxes this premium, leading to asymmetric price vs. rental effects.
- Discuss why displacement to rentals might be limited (e.g., due to search frictions, regulatory barriers, or foreigners’ preference for ownership).

#### (2) **Explore Heterogeneity**
The paper treats the CCR as a homogeneous segment, but foreign-buyer exposure likely varies within the CCR (e.g., by district or property type). Suggestions:
- Use finer geographic units (e.g., URA districts) to test whether effects are concentrated in the most foreign-exposed areas (e.g., Districts 9/10 vs. Downtown Core).
- If transaction-level data are available, test whether effects vary by property type (e.g., luxury vs. mass-market condominiums) or buyer nationality (e.g., Chinese vs. non-Chinese foreigners).
- Test whether the rental displacement effect varies by segment (e.g., if CCR rentals are more likely to attract foreigners than OCR rentals).

#### (3) **Improve the Placebo Tests**
The HDB placebo test is a strength, but it could be expanded:
- Test whether HDB prices in *all* towns (not just near-CCR) are unaffected by ABSD. If the effect is null across all HDB towns, this would further rule out spillovers.
- Use commercial property (as mentioned in the manifest) as an additional placebo. If ABSD affects only residential property, this would strengthen the causal interpretation.
- Test whether ABSD affects *new* private condominium sales (which may be more sensitive to foreign demand) differently than resale transactions.

#### (4) **Address External Validity**
The paper’s findings are highly relevant to other cities with foreign-buyer taxes (e.g., Vancouver, Hong Kong, London), but the discussion of external validity is limited. Suggestions:
- Compare Singapore’s ABSD to other cities’ policies in terms of design (e.g., rate, exemptions, enforcement) and market context (e.g., foreign-buyer share, housing supply elasticity).
- Discuss whether Singapore’s bifurcated housing market (public HDB vs. private condominiums) makes it a unique case or a useful template for other cities.
- Provide a back-of-the-envelope calculation of how the 0.7% price effect per percentage point of ABSD might translate to other markets (e.g., Vancouver’s 20% tax).

#### (5) **Clarify Data and Measurement**
- The paper uses log price/rental indices, but it is unclear whether these are *quality-adjusted*. If not, the results might reflect compositional changes (e.g., if ABSD causes a shift toward smaller or older units being sold/rented). The authors should clarify how the indices are constructed and whether they control for quality.
- The transaction volume data are only available for CCR and OCR, not RCR. The authors should explain why RCR is excluded and whether this could bias the results (e.g., if RCR is a better control for CCR than OCR).
- The HDB resale data cover 2017–2026, but the ABSD was introduced in 2011. The authors should explain why earlier HDB data are not used or acknowledge this limitation.

#### (6) **Improve Presentation**
- **Figures:** The paper would benefit from visualizations of:
  - Event-study plots showing leads/lags around each ABSD hike (to assess dynamic effects and pre-trends).
  - Dose-response plots (e.g., cumulative price effects by ABSD rate).
  - CCR vs. OCR price/rental trends over time (to show divergence post-ABSD).
- **Tables:** The robustness checks (Table 4) could be expanded to include:
  - Alternative bandwidths for Driscoll-Kraay standard errors.
  - Results with and without controls for concurrent policies (e.g., LTV limits).
  - Subsample analyses (e.g., pre-2018 vs. post-2018, to test whether effects changed over time).
- **Discussion:** The conclusion could more explicitly link the findings to policy debates. For example:
  - Do the results suggest that foreign-buyer taxes are more effective than other cooling measures (e.g., LTV limits)?
  - What are the welfare implications of ABSD (e.g., for domestic buyers, renters, or developers)?
  - How might the results inform the design of future policies (e.g., should taxes be targeted at specific segments or buyer nationalities)?

#### (7) **Engage with the Literature on Staggered DiD**
The paper cites recent work on housing taxation (e.g., Best and Kleven 2018, Deng et al. 2018) but does not engage with the broader DiD literature on staggered treatment timing. Suggestions:
- Cite and discuss key papers on staggered DiD (e.g., Goodman-Bacon 2021, de Chaisemartin and D’Haultfœuille 2020, Sun and Abraham 2021) to justify the choice of TWFE or to explain why alternative estimators are not used.
- If the authors stick with TWFE, they should acknowledge its limitations and discuss whether their results might be sensitive to these issues.

#### (8) **Discuss Potential Mechanisms**
The paper focuses on the "ownership premium" channel but does not explore other possible mechanisms, such as:
- **Liquidity effects:** ABSD might reduce market liquidity, leading to larger price declines in the CCR (where foreigners are more active).
- **Expectations:** If foreigners anticipate future ABSD hikes, they might front-load purchases, leading to temporary price spikes before each round.
- **Developer behavior:** Developers might reduce supply in the CCR if they expect lower demand, amplifying price effects.
The authors should discuss these mechanisms and whether their data can distinguish between them.

---

### Final Assessment

This is a strong paper with a compelling research design and important policy implications. The core results—dose-response effects of ABSD on prices and the asymmetric price vs. rental response—are novel and well-identified. With the revisions outlined above (particularly addressing staggered DiD concerns, confounding from concurrent policies, and rental market mechanisms), the paper would make a significant contribution to the literature on housing taxation and capital controls.

**Recommendation:** Revise and resubmit. The authors should address the three essential points (staggered DiD, confounding policies, rental market analysis) and consider the non-essential suggestions to strengthen the paper further.
