# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-23T11:58:01.742673

---

**Idea Fidelity**

The paper departs significantly from the original Idea Manifest. The manifest promised to exploit the new-build exemption as a within-region control, comparing existing rental stock (treated) to new builds (exempt) across territorial authorities using administrative tenancy bond data on rental stock. In contrast, the paper studies the composition of building consents (multi-unit versus stand-alone houses) across 16 regions, without directly leveraging the new-build exemption or rental bond registry. Multi-unit consents serve as a proxy for investor-oriented construction, but the paper never explicitly uses the FCC-based exemption (CCC date) that defined the treatment/control groups in the manifest. Thus, several key elements of the promised identification strategy—within-country control defined by CCC date, tenancy bond data for treatment intensity, and the focus on rental housing supply rather than type composition—are missing in the submitted paper.

**Summary**

The paper studies New Zealand’s 2021–2024 mortgage interest deductibility reform, which phased out deductions for existing rental properties while exempting new builds for 20 years. Using a difference-in-differences design that compares multi-unit to stand-alone house consents within regions, it documents a 42 percent compositional shift toward multi-unit construction during the treatment period and a partial reversal once deductibility was restored. Robustness checks (functional form, exclusion of Auckland) support the result, while cross-territorial exposure to rental intensity shows no differential effect, emphasizing the intra-region dwelling-type margin.

**Essential Points**

1. **Identification and Control Group:** The causal interpretation hinges on the assumption that multi-unit consents proxy for investor-driven new builds benefiting from the exemption. Yet the paper never directly exploits CCC-based treatment status or links consents to actual investor uptake. Without evidence that the investor demand shock affected only multi-unit consents—and not houses for other reasons—the rendering is tenuous. The authors should either (a) link the exemption eligibility (CCC≥27 March 2020) to the consent data or (b) provide stronger evidence that only multi-unit consents are connected to the new-build exemption (e.g., share of investor purchasers, financing patterns). Otherwise, the control group may not capture the counterfactual.

2. **Parallel Trends and Limited Pre-treatment Period:** The pre-policy window is only nine months (January–September 2021) because the dwelling-type data starts in 2021. This severely limits the ability to assess parallel trends, especially since housing construction is highly cyclical and was still recovering from pandemic shocks. To credibly claim a DiD identification, the authors must either extend the time series further back (if the raw data allow) or present rigorous pre-trend tests/ event-study plots with leads to demonstrate stability. Without this, the estimates may simply reflect post-COVID demand shifts that differentially affected multi-unit and house consents.

3. **Interpretation of the Reversal:** The paper treats the April 2024 deductibility restoration as a reversal, yet the “reversal” period still includes a 20 percentage-point premium (April 2024–March 2025) and the pipeline effects of projects consented earlier. The treated coefficient remains positive but smaller; interpreting this as partial reversal requires showing that post-April 2024 incentives indeed declined and that the timing of consents aligns with the policy change (e.g., lags). The authors should consider dynamic specifications (event-study with leads/lags) and analyze whether the persistence is consistent with a pipeline or structural shift, rather than conflating it with incomplete reversal.

**Suggestions**

- **Link Consents to the Actual Exemption:** If possible, use the CCC date information (or approval dates) to classify consents as “new-build exempt” versus “existing stock”—this would align with the manifest’s intended control group. Even if direct CCC data are unavailable, the authors could explore a matching strategy where consents for multi-unit developments are more likely to be investor-oriented (e.g., based on project size or developer financing) and provide documentation supporting this assumption.

- **Demonstrate Investor Composition:** Provide data showing that multi-unit dwellings are disproportionately purchased by investors eligible for the exemption (e.g., from LandInfo or property sales registries). A cross-tabulation or plot of investor share by dwelling type over time would reassure readers that the differential tax incentives plausibly translate into differential demand for consents.

- **Extend Pre-periods / Event Studies:** If the Stats NZ Building Consents series goes back further than 2021 (the paper notes data monthly since 2008), the authors should include a longer pre-period to test for pre-trends. If the dwelling-type breakdown is unavailable earlier, consider constructing an event study using the total national tally to see if the multi-unit versus house gap was stable before 2021. In any case, an event-study figure with lead and lag coefficients (even if only nine leads) would greatly help assessing the parallel trends assumption.

- **Dissect the Treatment Timing:** The reform had multiple discrete steps (100→75→50→25→0). The dosage specification is a good start, but the authors should also estimate the effect separately for each phase to investigate nonlinearity (e.g., does the largest jump occur when deductibility falls to 50 percent?). Presenting a figure showing monthly coefficient estimates (from a distributed lag model) would help assess whether the timing aligns with the policy steps.

- **Address Alternative Mechanisms:** Multi-unit consents could respond to factors other than the exemption, such as zoning reforms, infrastructure investment, or changes in building costs. The authors should control for time-varying regional characteristics (e.g., GDP growth, planning approvals, interest rates at the regional level) or at least discuss why such factors would not differentially affect multi-unit versus house consents contemporaneously.

- **Reconsider the Cross-TA Specification:** The cross-TA exposure specification fails to reject zero, but this is not surprising since the incentive was national. However, the interpretation could be sharpened: perhaps TAs with higher pre-existing rental stocks also had more investor demand or different capacity for multi-unit construction. To make this test informative, the authors could interact exposure with a multi-unit share variable or examine whether high-exposure TAs saw larger shifts in the multi-unit share.

- **Clarify the Outcome and Units:** The paper relies on the number of consents per region-month, but these counts are influenced by projects of varying size. Do the results hold if the authors normalize by expected units (e.g., number of dwellings per consent) or by developer stage (consents vs completions)? A sensitivity check on whether the shift in consents translates into actual floor space or units would strengthen the policy implication.

- **Discuss External Validity and Welfare:** The conclusion hints at substitution versus net supply effects. A brief discussion of whether multi-unit dwellings are “net additions” to the rental supply (versus replacing houses) or how this affects affordability would provide more context. Mentioning how the compositional shift interacts with demand elasticities or rent outcomes could make the contribution clearer.

- **Transparency on Data Limitations:** The paper states that “multi-unit” includes apartments, townhouses, flats. Are retirement village units included initially (and later excluded)? The appendix should document how dwelling types were classified, how missing data were handled, and whether the regional panel is balanced (some minor numbers missing—why?). Providing the codebook or a data appendix would aid reproducibility.

By addressing these points, the paper can better align with the original empirical idea and make a more credible claim about the causal impact of mortgage interest deductibility reform on housing supply composition.
