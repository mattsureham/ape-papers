# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-03-17T15:50:15.782760

---

 **Referee Report**

**Manuscript:** The Missing Premium: Ground Rent Abolition and the Limits of Tenure Reform Capitalization in England  
**Format:** AER: Insights  
**Recommendation:** Major Revision Required

---

### 1. Idea Fidelity

The paper pursues the original idea faithfully, utilizing the HM Land Registry Price Paid Data and implementing the proposed temporal RDD, DiD, and triple-difference designs. It correctly identifies the June 2022 cutoff and uses the April 2023 retirement property cutoff as a validation exercise, as specified in the manifest. The paper appropriately addresses the "toxic leasehold" context and the £6,000 theoretical NPV calculation.

However, the manuscript deviates from the manifest in one critical respect: it fails to adequately test for the specific pre-trend break around the Royal Assent date (February 8, 2022) that was flagged as a key threat. While the paper includes a generic event study, it does not explicitly model price trajectories during the February–June 2022 anticipation window, which is essential for distinguishing full anticipation from non-capitalization. Additionally, the retirement property cutoff is relegated to a robustness footnote rather than being developed as the "independent replication" suggested in the manifest.

---

### 2. Summary

This paper exploits England’s 2022 abolition of ground rent on new residential leases to test whether recurring contractual obligations capitalize into property prices. Using 87,444 transactions from the Land Registry universe, the author finds precise null effects across RDD, DiD, and triple-difference specifications, challenging the £18 billion welfare estimate underlying pending reforms. The contribution lies in documenting a case where a well-defined cost reduction fails to transmit to asset prices, with implications for behavioral models of housing valuation and the efficiency of leasehold markets.

---

### 3. Essential Points

**1. The Empirical Design Cannot Distinguish Anticipation from Non-Capitalization**  
The paper interprets its null result as evidence of either "full anticipation" or "non-salience," but these have diametrically opposite implications for the £18 billion welfare estimate. If prices adjusted gradually between the February 2022 Royal Assent and the June 2022 implementation date (as the bunching evidence and density test failure suggest), the DiD—comparing pre-2022 to post-2022—misses the total effect. The manuscript must implement an event study around the Royal Assent date (not just the implementation cutoff) to test for price adjustment during the anticipation window. Without bounding the magnitude of anticipation, the claim of "precise null" is overstated, and the policy implications for existing leasehold reform (where anticipation is impossible) remain unsupported.

**2. The Temporal RDD Is Invalid, and the DiD Control Groups Are Likely Contaminated**  
The paper convincingly demonstrates that the temporal RDD fails due to concurrent monetary tightening and the September 2022 mini-budget. However, it then relies heavily on DiD and triple-difference estimates without adequately addressing why new-build freehold houses or existing leaseholds provide valid counterfactuals. New-build leasehold flats are disproportionately purchased by first-time buyers and buy-to-let investors facing severe mortgage liquidity shocks during the sample period, while also being differentially exposed to the cladding crisis. The parallel trends assumption is violated if these groups experience distinct credit constraints or fire sales. The paper must provide evidence of pre-trend parallelity back to 2020 (or earlier) or employ alternative control strategies (e.g., synthetic control methods using commercial properties or retirement leaseholds as treated controls).

**3. External Validity Gap Between New Leases and Existing Stock**  
The empirical analysis concerns *new* leases only (where ground rent was abolished prospectively), but the policy motivation centers on capping ground rents on *existing* leases (the £18 billion estimate). The behavioral mechanisms differ fundamentally: existing leaseholders experience actual cash-flow relief (making the obligation salient), whereas new buyers never paid ground rent. The paper must clarify that the null result for new-builds—whether driven by anticipation or non-salience—may not generalize to the existing stock of 4.98 million homes, or reframe the contribution to focus exclusively on new-build market efficiency and developer incidence.

---

### 4. Suggestions

**Distinguishing Mechanisms:**  
To separate anticipation from non-capitalization, exploit the cross-sectional variation in ground rent levels prior to the reform. If ground rent was capitalized pre-reform, properties with higher ground rents (especially those with onerous doubling clauses) should have traded at larger discounts. While Land Registry data lack ground rent terms, the paper could match to Energy Performance Certificate (EPC) data (which contain floor area) and use leasehold valuation tribunal records or a subsample of listings data (e.g., Zoopla/Rightmove scrapes) to impute ground rent levels. If high-ground-rent properties show no price convergence toward low-ground-rent properties after June 2022, this supports the non-salience interpretation over anticipation.

**Strengthening Identification:**  
- **Synthetic Control:** Construct a synthetic control for new-build leasehold flats using weighted combinations of new-build freeholds and existing leaseholds from pre-2020, rather than assuming additive fixed effects.  
- **Retirement Properties:** Treat the April 2023 retirement property cutoff as a separate natural experiment with its own DiD, not merely a robustness check. This provides a "placebo" for the June 2022 confounds (if monetary tightening affected all properties, the April 2023 cutoff should show no effect).  
- **Geographic Heterogeneity:** Exploit that the monetary tightening shock differentially
