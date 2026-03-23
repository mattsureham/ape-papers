# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-23T12:55:55.183535

---

**Idea Fidelity**

The paper hews closely to the original manifest. It exploits the 2010 IRS auto-revocation wave as a natural experiment, leveraging the Auto-Revocation List and the Business Master File to study what predicts organizational survival. The key identification elements—cross-subsection variation, the asset proxy, and comparison across revocation waves—are preserved. The analysis also incorporates the stated policy motivation (PPA enforcement), datasets, and the focus on organizational survival/death following the compliance shock. No substantive deviations from the manifest’s research question or data plan are apparent.

---

**Summary**

This short paper documents how the 2010 IRS auto-revocation under the Pension Protection Act served as a compliance cliff that disproportionately killed certain types of nonprofits. Using the universe of revoked EINs matched to current IRS registrations, the author shows that organizations classified in physical-asset-heavy subsections (cemeteries, veterans posts, fraternal lodges) were substantially more likely to reinstate than charitable organizations, suggesting that institutional embeddedness—not social mission—predicted survival. A temporal comparison suggests this “asset premium” shrinks after the initial surprise wave, consistent with an information-asymmetry mechanism.

---

**Essential Points**

1. **Causal interpretation of subsection effects remains tenuous.** The core identifying assumption is that subsection-type differences (e.g., (c)(3) vs. (c)(13)) reflect reinstatement incentives rather than other correlated characteristics. Yet subsection classification also proxies for organizational size, capacity, pre-revocation financial health, and propensity to maintain contact information. Without controlling for these factors—or at least characterizing their correlation with subsection—the conclusion that physical assets per se drove reinstatement is suggestive but not convincing. The paper should either incorporate pre-revocation measures (e.g., historical revenue, assets, or filing history from prior Form 990/990-EZ/NXML data) or present evidence that such characteristics do not vary systematically across the key subsection comparisons.

2. **Measurement of the outcome conflates reinstatement with continued activity.** Identifying reinstatement solely via appearance on the current (2026) BMF overlooks several possibilities: (i) organizations that reinstated but later dissolved or were revoked again; (ii) organizations with the same EIN that materially changed purpose or structure; (iii) organizations that reconstituted under a different EIN (possibly more common for non-asset types). This attenuation bias could exaggerate the difference between asset-rich and asset-poor groups. The paper should quantify how often revoked EINs reappear intermittently, discuss the extent to which reinstated EINs may have later died, and assess whether substitution under new EINs is differential by type.

3. **The proposed information-asymmetry mechanism needs tighter empirical grounding.** The attenuation of the asset premium after 2010 is consistent with greater awareness, but it could also reflect changes in the composition of non-filers, IRS outreach, or other secular trends. Without pre-trend data or placebo comparisons—e.g., comparing reinstatement outcomes for organizations that missed filings before 2006 or for those that were always required to file—the mechanism remains speculative. The paper should either introduce direct proxies for information access (e.g., presence on state nonprofit registries, website presence, media coverage) or further interrogate why the premium changes over time beyond the simple before/after split.

If addressing these points requires substantially new analysis that cannot be accommodated, the paper may not meet AER: Insights’ empirical rigor standards and should be reconsidered.

---

**Suggestions**

- **Enhance control for confounders via pre-revocation data.** The BMF contains (for non-revoked entities) size metrics and ruling-year information. Although revoked organizations drop out of administrative filings, the IRS retains their EINs and, crucially, the three consecutive missed filings (990-N) exist. If the archival Form 990-N submissions (or even the absence thereof) can be recovered, they could provide proxies for organizational activity, revenue level, or contact information in the pre-treatment period. At minimum, the paper could merge in organizational age from the ruling year and state-level proxies (e.g., whether the EIN ever filed a 990/990-EZ) to show that subsection differences remain after conditioning on such variables. Even a partial audit (e.g., for a 5% sample) would reinforce the causal narrative.

- **Disaggregate asset status and consider alternative asset proxies.** The current physical-asset indicator groups heterogeneous subsections together, but subsection membership is an imperfect proxy for actual asset holdings. The author could exploit the BMF financial data for reinstated organizations to show that reinstated (c)(3) organizations that had larger reported asset bases prior to revocation (e.g., inferable from their last available return) were more likely to return than low-asset counterparts, helping to substantiate the mechanism. Alternatively, the analysis could parse subsections by NTEE codes or other administrative markers (e.g., presence of a building in the name, “cemetery,” “post,” “lodge”) to create richer proxies.

- **Clarify the interpretation of the asset premium magnitude and dynamics.** The 3.7 pp asset premium is statistically significant, but the paper would benefit from interpreting its substantive size relative to the baseline reinstatement rate. For example, presenting predicted probabilities for a prototypical asset and non-asset organization across states would help readers understand the practical impact. Similarly, when discussing the 27% attenuation, provide confidence intervals for the difference in premiums and explore whether the decline stabilizes, oscillates, or reverses in later years—this could relate to IRS policy shifts or economic cycles.

- **Address potential selection in the reinstated sample.** The approaching narrative treats reinstated organizations as representative survivors, but reinstatement itself may select on unobserved optimism, legal invoicing ability, or access to pro bono help. To the extent possible, compare reinstated organizations’ subsequent activity (e.g., number of filings post-reinstatement, reported revenue) to those that never reinstated but could plausibly have reappeared with new EINs. If reinstated organizations are systematically more active, the observed subsection differences might reflect differences in “organizational vigor” rather than only compliance capacity.

- **Deepen discussion of policy implications by acknowledging alternative enforcement designs.** The conclusion argues for proportionality, graduated enforcement, or outreach. Strengthen this section by referring to specific policy proposals (e.g., IRS reminder notices, fee waivers, low-cost reinstatement clinics) and, if data permit, show whether states with IRS-approved assistance programs (e.g., state associations offering pro bono help) had higher reinstatement rates for non-asset types. This would transform the policy implication from a rhetorical warning into an actionable insight.

- **Provide sensitivity checks on the state fixed-effects specification.** While state fixed effects absorb many confounders, some enforcement capacity is determined at the IRS regional or Service Center level, not necessarily aligned with state boundaries. Try re-estimating the regressions with IRS region fixed effects or by clustering at the region level, and report whether the subsection gradient persists. Additionally, consider interacting subsection indicators with nonprofit density or rurality to see if the effect differs in underserved areas.

- **Explicitly reference limitations inherent to administrative data.** The paper states that the matching is conservative because organizations that reinstated and later dissolved may appear as non-reinstated. Emphasize that the absence of re-entry might also stem from EIN retirement policies (e.g., IRS may retire EINs), data lags, or voluntary name changes. A short paragraph in the discussion acknowledging these limitations and their likely direction of bias would sharpen the empirical credibility.

Overall, the idea is compelling and the administrative data source is rich, but addressing these points—particularly the causal interpretation and mechanism validation—will elevate the manuscript to AER: Insights’ standards.
