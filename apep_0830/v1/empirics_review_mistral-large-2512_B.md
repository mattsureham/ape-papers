# V1 Empirics Check — mistralai/mistral-large-2512 (Variant B)

**Model:** mistralai/mistral-large-2512
**Variant:** B
**Date:** 2026-03-23T15:17:28.982887

---

### 1. **Idea Fidelity**

The paper closely adheres to the original idea manifest, pursuing the core research question of whether VAT receipt lotteries reduce the VAT compliance gap across EU member states. Key elements of the identification strategy—staggered adoption, difference-in-differences (DiD) with heterogeneity-robust estimators (Callaway-Sant’Anna, Sun-Abraham), and the use of VAT/GDP as the primary outcome—are faithfully implemented. The paper also leverages the three cancellations for reversal tests, though it acknowledges the limited power of this analysis.

However, there are two notable deviations from the manifest:
1. **Sample restriction**: Malta (1997 adopter) is excluded due to lack of pre-treatment data, reducing the treated units from 10 to 9. This is justified but narrows the scope.
2. **Outcome variable**: The manifest emphasizes the VAT *compliance gap* (from CASE/EC reports) as the primary outcome, but the paper uses VAT *revenue as a share of GDP* (from Eurostat). The authors justify this as a more direct and less model-dependent measure, but it conflates compliance effects with other factors (e.g., rate changes, exemptions). The compliance gap would have been a cleaner test of the mechanism.

The paper also omits the decomposition of effects by prize size or persistence, which was flagged as a potential contribution in the manifest. This is a missed opportunity to explore heterogeneity beyond baseline compliance.

### 2. **Summary**

This paper provides the first cross-country evaluation of VAT receipt lotteries, exploiting staggered adoption across 9 EU member states (2013–2021) using heterogeneity-robust DiD methods. The main finding is a nuanced null: receipt lotteries do not significantly increase VAT revenue as a share of GDP on average, but they generate meaningful gains (0.54 percentage points) in countries with below-median baseline compliance. The results suggest that consumer-as-auditor mechanisms work only where retail evasion is prevalent, offering policy-relevant heterogeneity that single-country studies cannot capture.

### 3. **Essential Points**

**1. Outcome Measurement and Mechanism Validity**
The paper’s use of VAT/GDP as the primary outcome is problematic. VAT/GDP is influenced by factors unrelated to compliance (e.g., rate changes, exemptions, consumption shifts), and the paper does not convincingly isolate the compliance channel. The manifest’s proposed outcome—the VAT *compliance gap* (from CASE/EC reports)—would have been a more direct test of the mechanism. If the authors insist on VAT/GDP, they must:
   - Show robustness to controlling for VAT rate changes (available in Eurostat’s `gov_10a_taxag`).
   - Provide a bounding exercise to demonstrate that the observed effects are unlikely to be driven by non-compliance factors (e.g., compare VAT/GDP trends to those of excise taxes, which are less prone to evasion).
   - Address whether the compliance gap (from CASE) moves in tandem with VAT/GDP in their sample, to validate the latter as a proxy.

**2. Heterogeneity Analysis and External Validity**
The heterogeneity by baseline compliance is the paper’s most compelling finding, but it is underdeveloped. The authors must:
   - Clarify how "low" and "high" baseline compliance are defined (e.g., median split in 2005, but why 2005? Why not pre-adoption levels?). This choice appears arbitrary and could drive the results.
   - Test whether the heterogeneity is robust to alternative splits (e.g., terciles, continuous interaction) and to using the compliance gap (if available) as the moderator.
   - Discuss whether the "high-compliance" countries (e.g., Portugal, Italy) are truly high-compliance or simply have high VAT/GDP due to other factors (e.g., broad bases, few exemptions). This matters for interpreting the null effect.

**3. Event Study Interpretation**
The Sun-Abraham event study shows a growing effect over time, but this is driven by a small number of long-exposure adopters (Portugal, Romania, Greece). The authors must:
   - Explicitly acknowledge that the long-run effects are based on only 3 countries and may reflect idiosyncratic factors (e.g., Portugal’s e-invoicing integration, Romania’s large prizes).
   - Test whether the growing effect is robust to excluding these countries or to using a balanced panel of pre- and post-treatment years.

### 4. **Suggestions**

**A. Data and Measurement**
1. **Primary Outcome**: If the CASE compliance gap data are accessible, use them as the primary outcome. If not, justify why VAT/GDP is a reasonable proxy and address its limitations (e.g., via robustness checks as suggested above).
2. **Prize Size and Program Features**: The manifest highlights the potential to decompose effects by prize size or program design (e.g., e-invoicing integration). The paper should include a table summarizing key features of each country’s lottery (e.g., prize size as % of GDP, frequency of drawings, electronic vs. paper receipts) and test whether these moderate the treatment effect.
3. **Placebo Tests**: The income tax placebo is well-executed, but the authors could add:
   - A placebo test using excise tax revenue (e.g., on alcohol or tobacco), which is less prone to evasion than VAT.
   - A test for spillovers to non-adopting countries (e.g., do border regions in control countries see changes in VAT/GDP?).

**B. Identification and Robustness**
1. **Parallel Trends**: The event study shows no pre-trends, but the authors should:
   - Formally test for joint significance of pre-treatment coefficients (e.g., using a Wald test).
   - Show the event study for the heterogeneity analysis (low vs. high compliance) to ensure parallel trends hold within subgroups.
2. **Dynamic Effects**: The growing effect in the event study is intriguing but noisy. The authors could:
   - Estimate separate ATTs for short- vs. long-exposure adopters (e.g., split at 3 years post-adoption).
   - Use a distributed lag model to test whether effects persist or fade over time.
3. **Cancellation Reversal**: The reversal test is underpowered but could be improved by:
   - Extending the sample to include pre-adoption years for cancelling countries (to increase power).
   - Testing whether the effect of cancellation varies by baseline compliance (e.g., do low-compliance countries see larger reversals?).

**C. Heterogeneity and Mechanisms**
1. **Baseline Compliance**: The heterogeneity analysis is the paper’s strongest contribution. To strengthen it:
   - Use a continuous interaction (e.g., `Lottery × Baseline VAT/GDP`) to avoid arbitrary splits.
   - Test whether the effect is driven by specific countries (e.g., Romania, with its large prizes) or is generalizable across low-compliance adopters.
2. **Retail Sector Composition**: The consumer-as-auditor mechanism may work better in countries with larger retail sectors or more cash-based transactions. The authors could:
   - Interact treatment with the share of retail trade in GDP (from Eurostat) or the size of the shadow economy (from Schneider et al.).
   - Test whether effects are larger in countries with higher card payment usage (since receipt lotteries may complement card incentives).
3. **Enforcement Capacity**: The effect of receipt lotteries may depend on tax authority capacity. The authors could:
   - Interact treatment with enforcement proxies (e.g., tax authority staff per capita, audit rates).
   - Test whether effects are larger in countries with weaker enforcement (where consumer audits are more valuable).

**D. Policy Implications**
1. **Cost-Benefit Analysis**: The paper estimates a 0.54 percentage point increase in VAT/GDP for low-compliance countries, but it does not discuss the costs of running lotteries (e.g., prize expenditures, administrative overhead). A back-of-the-envelope calculation (e.g., comparing revenue gains to prize costs) would strengthen the policy relevance.
2. **Generalizability**: The paper argues that receipt lotteries are not a "universal best practice," but it does not discuss whether the EU’s experience generalizes to other regions (e.g., Latin America, where single-country studies find large effects). A brief discussion of external validity would be helpful.
3. **Alternative Policies**: The paper could compare receipt lotteries to other compliance tools (e.g., e-invoicing, third-party reporting) in terms of cost-effectiveness, especially for high-compliance countries where lotteries are ineffective.

**E. Presentation and Clarity**
1. **Tables and Figures**:
   - The event study figure should include confidence intervals and a clear reference line at 0.
   - Add a table showing the timing of adoption/cancellation and key program features (prize size, frequency, etc.).
   - The heterogeneity analysis (Table 3, column 3) should include the main effect of `Lottery` alongside the interactions.
2. **Discussion of Null Results**: The paper’s null finding is important but could be framed more constructively. For example:
   - Discuss whether the null is due to low power or genuine ineffectiveness (e.g., using the minimum detectable effect).
   - Compare the null to the magnitudes found in single-country studies (e.g., Naritomi’s 22% increase in reported sales) and explain why the cross-country effect is smaller.
3. **Mechanism Clarity**: The paper could better explain *why* receipt lotteries work in low-compliance countries. For example:
   - Do consumers in these countries respond more to incentives (e.g., due to lower incomes)?
   - Are vendors in these countries more likely to evade, making consumer audits more valuable?

**F. Minor Issues**
1. **Sample Size**: The paper notes the low power of the country-level panel but could quantify this (e.g., "with 26 countries, we can detect effects larger than X at 80% power").
2. **Malta’s Exclusion**: The exclusion of Malta is justified but should be noted earlier (e.g., in the abstract or introduction).
3. **COVID-19**: The paper mentions COVID-19 as a confounder for the cancellation test but does not address whether it affects the main results. A robustness check excluding 2020–2021 would be useful.

### Final Assessment
This is a well-executed paper with a clear contribution to the literature on tax compliance and consumer-as-auditor mechanisms. The heterogeneity analysis is particularly compelling and policy-relevant. However, the paper’s reliance on VAT/GDP as the primary outcome weakens its causal claims, and the heterogeneity results require more robustness checks. Addressing the essential points above would significantly strengthen the paper’s credibility and impact. With these revisions, it would be a strong candidate for publication in *AER: Insights*.
