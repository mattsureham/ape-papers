# V1 Empirics Check — mistralai/mistral-large-2512 (Variant C)

**Model:** mistralai/mistral-large-2512
**Variant:** C
**Date:** 2026-03-25T15:44:01.287947

---

Here’s my direct, constructive review structured as requested:

---

### 1. **Idea Fidelity**
The paper faithfully executes the original manifest’s core idea: exploiting the Dominican Republic’s sudden enforcement of its MIPYME set-aside mandate to test whether such policies expand small firm access or merely relabel incumbents. Key elements are preserved:
- **Identification strategy**: Generalized DiD with continuous treatment intensity (agency-level change in MIPYME-directed share) is implemented as proposed.
- **Data sources**: All three DGCP datasets (awards, processes, providers) are used, with the supplier registry’s firm creation date enabling the critical "relabeling" decomposition.
- **Research question**: The paper directly addresses whether set-asides create new suppliers or redirect contracts to certified incumbents.

**Missed opportunity**: The manifest highlighted a *women-led MIPYME* sub-quota (rising from 0% to 3.4%), but this is relegated to a footnote. Given global interest in gender-targeted procurement, this could have been a secondary analysis.

---

### 2. **Summary**
The paper exploits a natural experiment in the Dominican Republic—where a dormant 20% MIPYME procurement set-aside mandate was suddenly enforced after a 2020 presidential transition—to show that set-asides *reduce* supplier diversity. Using 655,000 contract awards, it finds that agencies with larger compliance increases saw fewer unique suppliers, with 35% of post-period awards going to "relabeled" incumbents (existing suppliers who obtained MIPYME certification) versus only 17% to genuinely new entrants. The effect is concentrated in large agencies, where certification premiums are highest.

---

### 3. **Essential Points**
**1. Magnitudes and economic meaningfulness**
The central result—a 9% decline in unique suppliers per 14.7pp increase in MIPYME-directed share—is plausible but requires sharper economic interpretation. The paper frames this as a "relabeling illusion," but the mechanism could equally reflect:
- **Crowding out**: MIPYME set-asides may displace non-MIPYME suppliers without creating new ones.
- **Certification costs**: If obtaining MIPYME status is easier for incumbents, the mandate may shrink the pool of *eligible* suppliers.

**Suggestion**: Decompose the effect further. For example, does the decline in unique suppliers reflect:
- Fewer *non-MIPYME* suppliers (consistent with crowding out)?
- Fewer *new* MIPYME suppliers (consistent with certification barriers)?
- Or both?

**2. Standard errors and clustering**
The paper clusters standard errors at the agency level (256 clusters), which is appropriate given the treatment variation. However:
- The event study (\Cref{tab:event}) shows wide confidence intervals post-2020, suggesting noise in later years. This could reflect:
  - **Heterogeneous effects**: Some agencies may have expanded supplier pools while others contracted.
  - **Dynamic responses**: Firms may have taken time to relabel, creating delayed effects.
- **Suggestion**: Report wild bootstrap p-values to assess sensitivity to clustering assumptions.

**3. Parallel trends and pre-trend tests**
The pre-trend F-test ($p = 0.54$) and placebo test ($p = 0.53$) support parallel trends, but the event study (\Cref{tab:event}) reveals a puzzling pattern:
- Pre-treatment coefficients (2016–2018) are *positive* (though insignificant), while post-treatment effects are *negative*.
- This could indicate that high-shift agencies were already *losing* suppliers pre-2020, and the mandate accelerated this trend.

**Suggestion**: Test whether pre-period trends in supplier diversity predict treatment intensity. If high-shift agencies were already declining, the DiD estimate may be biased.

---

### 4. **Suggestions**
**A. Strengthen the mechanism**
1. **Formalize the "certification premium"**
   - The paper argues that incumbents relabel because certification is easier for them. Test this directly:
     - Regress MIPYME certification status on pre-period supplier characteristics (e.g., prior contract wins, firm age).
     - If incumbents are more likely to certify, this supports the mechanism.
   - Alternatively, use a **bunching estimator** to test whether firms cluster just below the MIPYME revenue/employee thresholds.

2. **Heterogeneity by procurement modality**
   - The *Procesos* dataset includes procurement modalities (e.g., competitive bids vs. direct awards). Test whether the effect varies by modality:
     - Competitive bids may be harder for relabeled incumbents to win (if they lack experience).
     - Direct awards may be easier to capture via certification.

3. **Geographic heterogeneity**
   - The *Proveedores* dataset includes province/municipality. Test whether the effect is stronger in regions with:
     - Higher pre-period corruption (using existing indices).
     - More concentrated supplier markets.

**B. Address potential threats**
1. **Compositional changes in procurement**
   - The mandate may have changed the *type* of contracts awarded (e.g., more services, fewer goods). If services are harder for new firms to supply, this could explain the decline in unique suppliers.
   - **Suggestion**: Control for the share of contracts by procurement object type (goods/services/works) in the DiD regression.

2. **Dynamic effects**
   - The event study shows persistent effects, but the paper does not test whether the decline in suppliers is temporary (e.g., firms exit but later re-enter).
   - **Suggestion**: Estimate a dynamic DiD model with leads/lags to test for:
     - Anticipation effects (pre-2020).
     - Rebound effects (post-2023).

3. **Alternative explanations for the decline in suppliers**
   - The paper attributes the decline to relabeling, but other mechanisms are possible:
     - **Corruption**: The anti-corruption push may have reduced "fake" suppliers (e.g., shell companies).
     - **Bureaucratic friction**: Enforcement may have increased paperwork, deterring new entrants.
   - **Suggestion**: Test whether the decline in suppliers is driven by:
     - Fewer *small* suppliers (consistent with certification barriers).
     - Fewer *large* suppliers (consistent with corruption crackdowns).

**C. Improve presentation and robustness**
1. **Clarify the decomposition**
   - \Cref{tab:decomp} is the paper’s most novel contribution, but the categories are not intuitive. For example:
     - "Relabeled" suppliers are defined as pre-period winners who later certify. But some may have been MIPYMEs all along (just not certified).
     - "New MIPYME" suppliers are defined as post-period entrants with certification. But some may have been active in other markets.
   - **Suggestion**:
     - Add a fourth category: "Pre-existing MIPYMEs" (firms certified before 2020).
     - Report the share of *contract value* (not just awards) by category, as value shares are more economically meaningful.

2. **Report effect sizes in levels**
   - The paper reports log(unique suppliers), but readers may struggle to interpret this. For example:
     - A 9% decline in unique suppliers sounds modest, but if the mean is 35 suppliers/quarter, this implies ~3 fewer suppliers per agency-quarter.
     - **Suggestion**: Report effects in levels (e.g., "a 14.7pp increase in MIPYME share reduces unique suppliers by 3.2 per agency-quarter").

3. **Test for spillovers**
   - The mandate may have affected *non-MIPYME* contracts. For example:
     - Agencies may have shifted non-MIPYME contracts to relabeled incumbents to meet the quota.
     - New entrants may have been deterred from bidding on non-MIPYME contracts.
   - **Suggestion**: Estimate the effect on non-MIPYME contracts separately.

4. **Address sample selection**
   - The paper restricts to agencies with ≥4 quarters in both pre- and post-periods (256 of 669 agencies). This could bias results if:
     - High-shift agencies are more likely to be excluded (e.g., if they had low pre-period volume).
     - Excluded agencies differ systematically (e.g., smaller, less transparent).
   - **Suggestion**:
     - Test whether excluded agencies differ in pre-period characteristics.
     - Use inverse probability weighting to adjust for selection.

**D. Policy implications**
1. **Design better set-asides**
   - The paper concludes that set-asides may need "complementary policies" to reduce certification barriers. Suggest specific policies:
     - **Simplified certification**: Reduce paperwork for new firms.
     - **Capacity-building**: Offer training to help new firms navigate procurement.
     - **Direct matching**: Pair new firms with agencies to reduce search costs.

2. **Compare to other countries**
   - The paper notes that set-asides are common worldwide, but compliance is often voluntary. Contrast the Dominican Republic’s experience with:
     - **US**: SBA goals are enforced but lack penalties for non-compliance.
     - **India**: MSME reservations are strictly enforced but face corruption challenges.
   - **Suggestion**: Add a table comparing set-aside policies across countries.

---

### **Final Assessment**
This is a strong paper with a clear, economically meaningful result. The identification strategy is well-executed, the data are rich, and the "relabeling" decomposition is novel. However, the paper would benefit from:
1. Sharper economic interpretation of the magnitudes.
2. More rigorous testing of alternative mechanisms.
3. Clearer presentation of the decomposition and robustness checks.

**Recommendation**: Revise and resubmit, with particular attention to the suggestions above. The core finding—that set-asides can contract the supplier base—is important and policy-relevant, but the paper needs to rule out alternative explanations more convincingly.
