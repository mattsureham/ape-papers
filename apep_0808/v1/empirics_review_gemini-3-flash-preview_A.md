# V1 Empirics Check — google/gemini-3-flash-preview (Variant A)

**Model:** google/gemini-3-flash-preview
**Variant:** A
**Date:** 2026-03-23T12:55:59.125792

---

**Reviewer Report**

**Paper Title:** The Compliance Cliff: Mass Organizational Death and Selective Resurrection in the U.S. Nonprofit Sector
**Reviewer:** Anonymous

---

### 1. Idea Fidelity
The paper aligns closely with the original idea manifest. It successfully exploits the 2010 IRS Automatic Revocation List (377,409 organizations) as a natural experiment to study organizational survival. It correctly identifies the Pension Protection Act of 2006 as the policy lever and utilizes the specified datasets (Auto-Revocation List and BMF). 

However, there is a notable omission: the manifest suggested using the ProPublica Nonprofit Explorer API for "financial trajectories of reinstated organizations" and a "dose-response analysis" using organizational age as a running variable. The current draft focuses almost exclusively on cross-sectional subsection variation and the "asset premium." While the paper is cohesive, it misses the longitudinal depth (revenue growth post-reinstatement) and the age-based identification strategy proposed in the manifest.

### 2. Summary
The paper investigates the determinants of organizational survival following the 2011 mass revocation of tax-exempt status for over 370,000 U.S. nonprofits. Using a linear probability model with state fixed effects, the author finds that organizations in subsections typically associated with physical assets (e.g., cemeteries and veterans' posts) were significantly more likely to reinstate than purely charitable or social welfare organizations. The study suggests that regulatory compliance shocks disproportionately eliminate "institutionally thin" organizations, reshaping the sector’s composition.

### 3. Essential Points

1.  **Reverse Causality and Selection into Revocation:** The paper treats "revocation" as a uniform shock, but the *reason* for non-filing (which led to revocation) is likely correlated with the likelihood of reinstatement. An organization that was already defunct in 2007 (a "ghost") is revoked for the same reason as a "living" organization that simply missed the memo. The current analysis cannot distinguish between "death caused by the IRS" and "the IRS cleaning out a cemetery of already-dead orgs." Without using the pre-2007 filing history or age data (as suggested in the manifest), the 90% non-reinstatement rate might simply reflect the proportion of organizations that were already inactive.
2.  **Definition of "Physical Asset" Variable:** The categorization of subsections into "physical asset" vs. "non-asset" (Table 3, Column 3) is a coarse proxy. While cemeteries (c13) certainly have land, the assumption that all 501(c)(5) labor unions or 501(c)(8) fraternal lodges have halls—while 501(c)(3) charities do not—is a strong assumption. Many small (c)(3) organizations (churches, local museums) own property, while many (c)(5) or (c)(6) entities are paper-only professional associations. The author needs to validate this proxy using the BMF financial data (asset field) for the reinstated subset to prove the correlation exists.
3.  **Measurement Error in Reinstatements:** The matching procedure identifies "reinstated" organizations as those appearing in the *current* (2026) BMF. This ignores organizations that reinstated in 2012 but went out of business by 2020. This "survivor bias" in the reinstatement variable conflates *reinstatement* (the act of fixing the status) with *long-term survival*. The paper needs to clarify if it is measuring the capacity to navigate a bureaucracy or the long-term viability of the organization.

### 4. Suggestions

*   **Exploit Organizational Age:** As noted in the manifest, the "ruling year" in the BMF allows you to calculate organizational age. One would expect "Compliance Cliff" effects to be most pronounced for very old, small organizations that predated electronic filing norms. Integrating age as a control or an interaction term would significantly strengthen the "institutional embeddedness" argument.
*   **The 501(c)(3) vs. (c)(4) Contrast:** A missed opportunity in the current draft is the comparison between (c)(3) and (c)(4). Both are often similar in size and scope, but (c)(3)s have the powerful incentive of offering tax-deductible donations. The fact that (c)(3)s reinstate at roughly the same low rate as (c)(4)s (8.9% vs 8.2%) is a fascinating finding that contradicts "incentive-based" survival models and supports "capacity-based" models. I recommend expanding on this.
*   **Geographic Heterogeneity:** The paper mentions state-level variation (6.7% in CA vs 15.1% in PA). Are these differences driven by state law (e.g., state-level tax-exempt status being linked to federal status) or by the presence of "Nonprofit Capacity Builders"? Merging in state-level data on the density of CPA firms or nonprofit associations could test the "compliance cost" mechanism.
*   **Matching Robustness:** To address the "ghost organization" problem, could you subset the analysis only to organizations that were "active" just before the PPA? While they didn't file 990s, did they appear in other databases? Alternatively, look at the "Ruling Year." If an organization was formed in 2005 and revoked in 2010, it was likely "alive." If it was formed in 1950 and revoked in 2010, the probability it was already a "ghost" is much higher.
*   **Mechanism Test (Fee Sensitivity):** The IRS changed the reinstatement fees over this period. If the "Compliance Cliff" is truly about fixed costs, the 2014-11 Revenue Procedure (which streamlined/cheapened the process) should have triggered a wave of reinstatements for the "non-asset" organizations. A time-series analysis of *when* reinstatement occurred (if available in the BMF "Exemption Date" or "Ruling Date") would be highly valuable.
*   **Table 4 Interpretation:** The "Temporal Placebo" in Table 4 is excellent evidence for the "Information Surprise" hypothesis. I suggest emphasizing this more in the Introduction. It provides the "cleanest" evidence that the 2010 wave was a unique shock compared to the "steady-state" revocations of later years.
*   **Visualizing the "Cliff":** A histogram of the "Ruling Year" for revoked vs. reinstated organizations would be a powerful visual for the paper. Does the 2010 wave cull "old" organizations specifically? This would support the "institutional drift" narrative.
*   **Language and Tone:** The term "Mass Organizational Death" is evocative but perhaps slightly dramatic for an AER: Insights format. "Large-scale exit" or "Administrative culling" might be more standard, though I personally find the current framing compelling.
