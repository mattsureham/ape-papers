# V1 Empirics Check — openai/gpt-5.1-codex-mini (Variant A)

**Model:** openai/gpt-5.1-codex-mini
**Variant:** A
**Date:** 2026-03-25T10:54:39.577915

---

**Idea Fidelity**

The paper mostly tracks the original idea manifest: it exploits within-municipality variation in Zurich corporate Steuerfuss rates to test the Zodrow–Mieszkowski prediction that tax competition crowds out municipal public goods, and it draws on the specified administrative data sources. That said, several elements promised in the manifest are either missing or underdeveloped. The paper does not implement the proposed neighbor–rate instrument from \citet{Parchet2019} nor does it explicitly exploit the richer 1995–2024 panel of municipal accounts (it focuses on 2012–2017, evidently the overlap with STATENT), so the “192 indicators” and canton-level robustness checks noted in the manifest are not fully realized. The event‑study around large cuts is mentioned but very limited (11 municipalities), and the placebo test with the natural-person rate is weakened by the almost perfect correlation—a point the manifest acknowledged as a constraint. Overall, the paper remains faithful to the high-level research question but skips some of the identification and robustness ingredients laid out in the manifest, which weakens the causal argument.

---

**Summary**

This paper studies whether municipal tax competition in Canton Zurich leads to reductions in per-capita public expenditure, providing what it claims is a first causal test of the Zodrow–Mieszkowski “race to the bottom” mechanism at the municipal level. Using a panel of within-municipality Steuerfuss changes from 2012–2017, it finds no statistically significant effects on total, education, social security, or transport spending, nor on municipal tax revenue or firm entry, and argues that the null is well powered. It frames these findings as casting doubt on the welfare rationale for tax harmonization policies predicated on tax competition eroding public goods.

---

**Essential Points**

1. **Endogeneity of Steuerfuss changes remains unresolved.** Equation (1) relies on within-municipality taxation variation, but the paper has not convincingly established that municipalities do not adjust the Steuerfuss in response to contemporaneous or anticipated fiscal shocks (e.g., local development booms, demographic pressures, or budget shortfalls). Political frictions are invoked qualitatively, but no empirical test is provided. A more credible design would exploit pre-treatment trends (lead variables), use instrumental variables (e.g., neighbor changes or canton-level shocks), or leverage discontinuities in the timing or size of fiscal councils’ decisions. As written, reverse causality (steeper cuts when spending is already expected to rise) cannot be ruled out, so the null effect may simply reflect offsetting demand-driven Steuerfuss paths.

2. **Corporate tax competition is not isolated.** The 0.995 correlation between corporate and personal Steuerfuss rates means that the paper does not isolate the corporate tax channel central to the Zodrow–Mieszkowski prediction. In practice the treatment is a general fiscal stance rather than a corporate-specific rate, undermining the claim that this is the “first causal test” of the corporate tax competition mechanism. The paper should either find variation that distinguishes the two rates (e.g., municipalities that deviate more on corporate rates) or be forthright that it is testing the impact of municipal tax posture more broadly, adjusting its theoretical framing accordingly.

3. **Interpretation of the null requires stronger evidence on substitution mechanisms.** The theoretical race-to-the-bottom mechanism predicts spending cuts through a revenue shortfall from attracting capital. The paper finds no effect on spending but also no effect on firms, yet it does not explore whether municipalities responded through non-spending margins (reserves, transfers, fees, debt, or mandated revenue-sharing). Without ruling out non-public-good channels or showing that revenue falls (it does not), it is premature to conclude that tax competition is harmless—the model predicts reductions only if revenue cannot be offset. The current results could simply reflect a setting where fiscal equalization, reserve usage, or cantonal mandates stabilize spending; that is still compatible with harmful competition if those offsetting mechanisms come with other distortions. A more complete examination of revenues and fiscal balances is therefore essential.

If these issues cannot be resolved, the paper’s causal claims are too fragile for publication; they go to the core of whether the empirical approach adequately tests the theory.

---

**Suggestions**

1. **Strengthen identification via dynamic and instrumental strategies.** Estimate event-study specifications with leads of the Steuerfuss to test for anticipatory behavior: do spending paths change before a rate cut or increase? Presenting several leads (e.g., two years) would demonstrate whether Steuerfuss changes are orthogonal to upcoming fiscal shocks. Alternatively, revisit the manifest’s plan to instrument the municipal rate with a weighted average of neighboring Steuerfuss changes (e.g., following \citealp{Parchet2019}) or canton-level fiscal pressures. Even if the neighbor instrument is imperfect, it would provide bounds on the causal effect. These steps would make the null result far more credible.

2. **Exploit the longer time series and additional functional categories.** The manifest reports access to data spanning 1995–2024 and 192 financial indicators; consider expanding the analysis beyond 2012–2017 to increase variation in both treatment and outcomes. While the overlap with STATENT may limit the firm entry analysis, per-capita expenditure can likely be extended. Moreover, the detailed categories may allow testing whether certain spending types (e.g., administration, environment) are more responsive—if those categories move, it would change the interpretation of the null. Providing results for additional functions (e.g., administration, health) would also strengthen the contribution to fiscal federalism debates.

3. **Elaborate on fiscal adjustments beyond spending.** The appendix should present results on other fiscal margins: total revenue (not just tax revenue), transfers received, use of reserves, or debt issuance if available. This would reveal whether municipalities maintain spending by adjusting those margins and would clarify the normative implications: if they maintain spending by depleting reserves or increasing fees, there may still be welfare costs not captured by expenditure levels alone. If such variables are unavailable, discuss more concretely how actual budget constraints work in Zurich municipalities and why revenue shocks might or might not bind.

4. **Clarify the policy interpretation and scope.** The conclusion draws a connection to OECD Pillar Two, but the paper should be explicit about the limits of extrapolation: municipal tax competition among Swiss municipalities is very different from international corporate tax competition (different magnitudes, mobility, enforcement). Emphasize that the null applies to the municipal context and to general Steuerfuss adjustments; do not overstate generalizability to sovereign tax harmonization debates unless there is a clear theoretical link. A separate paragraph distinguishing the municipal setting from the international context would help readers correctly interpret the results.

5. **Elaborate on power calculations and effect sizes.** The MDE discussion is helpful, but it would be useful to translate the detectable effect into a welfare-relevant benchmark. For example, what would a 7\% reduction in spending imply in terms of class sizes, infrastructure projects, or service cuts? Providing a concrete example would help readers understand whether an effect large enough to matter is truly ruled out.

6. **Consider disaggregating the treatment.** Even with nearly collinear corporate and personal rates, there might be municipalities where corporate rates deviate more strongly (e.g., industrial towns). Explore whether the relationship differs in those cases, perhaps by interacting the rate with a firm-size indicator or industrial composition. This would permit the paper to say something specific about corporate competition even if the average correlation is high.

7. **Improve description of the institutional context.** The paper mentions that Steuerfuss changes are typically debated and announced in advance—provide citations or municipal examples to substantiate this claim. Additionally, describing whether canton-level equalization or mandates create hard budget constraints would help readers assess why the null might arise (if spending is mandated, we should not expect it to move).

8. **Address the limited power in heterogeneity/event-study analyses explicitly.** The event study around large cuts involves only 11 municipalities; discuss the implications for interpretation. Perhaps pool other substantial changes to increase N or provide bounds on treatment effect heterogeneity using continuous interactions. Similarly, when splitting the sample by fiscal capacity or population, report whether the splits preserve sufficient variation in Steuerfuss changes; if not, note this limitation.

By implementing these suggestions, the paper would offer a much sharper causal test of the theoretical mechanism and a clearer account of the policy significance of its null findings.
