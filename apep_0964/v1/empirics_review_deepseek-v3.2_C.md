# V1 Empirics Check — deepseek/deepseek-v3.2 (Variant C)

**Model:** deepseek/deepseek-v3.2
**Variant:** C
**Date:** 2026-03-25T21:19:53.823917

---

**Review of “The Phantom Correction: EU Interest Limitation and the Persistence of Aggregate Debt Bias”**

**1. Idea Fidelity**

The paper faithfully executes the research plan outlined in the original manifest. It uses the exact identification strategy proposed: a dose-response DiD based on de minimis thresholds and a staggered DiD using the derogation group. The data source is Eurostat Annual Sector Accounts (S11) as specified, covering the 27 EU countries from 2012–2023. The research question—whether ATAD shifted aggregate corporate financing from debt toward equity—is pursued directly, with outcomes focused on the interest-to-GOS ratio, debt composition, and leverage. The paper also includes the promised event study, placebo test on derogation countries, and robustness checks (wild bootstrap, leave-one-out). No key elements from the manifest are missed.

**2. Summary**

This paper provides the first macroeconomic evaluation of the EU’s Anti-Tax Avoidance Directive (ATAD), using coordinated cross-country variation in de minimis thresholds and adoption timing. Analyzing Eurostat sector accounts for 27 EU countries, it finds precisely estimated null effects: ATAD did not detectably alter the aggregate interest burden, debt composition, or leverage of non-financial corporations. The design is sufficiently powered to rule out moderate-to-large effects, suggesting that even history’s largest coordinated reform of interest deductibility may have left the deep-seated debt bias unchanged.

**3. Essential Points**

*The authors must address these three critical issues before publication.*

**3.1. Statistical power and the interpretation of a “well-powered null.”**  
The paper claims a “well-powered null” because the minimum detectable effect (MDE) at 80% power is 5.1 percentage points for the interest-to-GOS ratio, or about half of its pre-treatment standard deviation. In a macroeconomic panel with only 27 country clusters, an MDE of this magnitude is not especially sharp. A 5-percentage-point change in the interest/GOS ratio is economically large (e.g., roughly the difference between Germany and Cyprus pre-ATAD). Therefore, the design can only rule out very substantial aggregate shifts. The authors should: (1) explicitly acknowledge that the null is consistent with economically meaningful but modest effects (e.g., a 1–2 percentage point decline); (2) conduct a simulation-based power analysis that accounts for the staggered design and clustering, rather than relying on a simple two-sample MDE formula; and (3) reframe the conclusion to state that ATAD did not produce a *large* aggregate shift, while leaving open the possibility of smaller, policy-relevant effects.

**3.2. Treatment heterogeneity and the dose measure.**  
The primary dose variable—\((5 - \text{de minimis})/5\)—treats the difference between a €0 and €3M threshold as 60% of the distance between €0 and €5M. This linear scaling assumes that the number of firms affected increases linearly with threshold strictness, which may not hold. The distribution of firm size and interest expenses across countries is highly skewed; a €3M threshold may already exempt the vast majority of firms. The authors should: (1) validate the dose measure using available data on the firm-size distribution (e.g., Eurostat structural business statistics) to estimate the share of corporate interest covered by the de minimis exemption in each country; (2) present results using categorical indicators for threshold groups (e.g., €0, €1M, €3M, €5M) to check for non-linearities; and (3) discuss whether the treatment intensity is adequately captured or whether the null result might reflect a poorly measured dose.

**3.3. Outcome validity and confounding trends.**  
The primary outcome, interest paid divided by gross operating surplus (GOS), is meant to proxy the firm-level interest/EBITDA ratio targeted by ATAD. However, GOS includes mixed income and is not identical to EBITDA; more importantly, this ratio can change for reasons unrelated to ATAD, such as shifts in profit margins or the interest-rate environment. The post-period includes the ultra-low interest years of 2019–2021 and the inflationary spike of 2022–2023. While year fixed effects absorb common trends, they may not fully account for *differential* trends correlated with de minimis thresholds (e.g., countries with stricter thresholds may have different sectoral compositions). The authors should: (1) demonstrate that the pre-trends are parallel not just statistically but also economically, by showing the evolution of the outcome for each dose group graphically; (2) control for time-varying country-level factors that could influence the outcome, such as corporate profit rates, sectoral composition, or private credit growth; and (3) consider an alternative outcome like the *net* interest-to-EBITDA ratio (if data permit) to better align with ATAD’s net borrowing cost focus.

**4. Suggestions**

*Helpful but non-essential recommendations for strengthening the paper.*

**4.1. Deepen the heterogeneity analysis.**  
The paper notes that the standard (€3M) threshold group shows a marginally significant decline, while the zero-threshold group does not. This could be explored further:  
- Interact treatment with pre-existing country characteristics, such as the initial level of corporate leverage, the share of multinational firms, or the strength of pre-ATAD interest barriers.  
- Test whether effects are larger in countries with higher statutory corporate tax rates (where the debt bias is stronger).  
- Examine sector-level data (Eurostat NACE aggregates) to see if debt-intensive industries responded differently.

**4.2. Expand the set of outcome variables.**  
Beyond debt composition and leverage, consider:  
- The *maturity structure* of debt: ATAD may prompt a shift from long-term to short-term debt if firms anticipate future constraints. Data on short-term vs. long-term loans (F41 vs. F42) are available in Eurostat.  
- *Intra-group versus external debt*: If firms substitute toward intra-group loans (which may be treated differently under ATAD), this could be detected using the “loans from affiliated enterprises” item (F4 subset).  
- *Equity issuance*: Check F5 (equity and investment fund shares) for changes in net issuance around adoption.

**4.3. Strengthen the robustness checks.**  
- **Placebo treatments:** Randomly assign de minimis thresholds or adoption years across countries and re-estimate the model many times to obtain a placebo distribution of coefficients. Compare the actual estimate to this distribution.  
- **Falsification outcomes:** Test for effects on variables that should not respond to ATAD, such as non-debt liabilities or tangible fixed assets (K1).  
- **Alternative clustering:** Acknowledge that with only 27 clusters, even wild bootstrap may have limitations. Consider reporting Conley–Taber–Wild permutations as an additional check.

**4.4. Improve the presentation of results.**  
- **Graphical evidence:** Include an event-study plot with confidence intervals for the main outcome, rather than only a table. Also, plot the raw evolution of the interest/GOS ratio for high-dose vs. low-dose countries.  
- **Standardized effect sizes:** In Table SDE, classify effects as “small,” “moderate,” or “large” based on benchmarks from the literature (e.g., 0.2 SD for a moderate effect). Discuss what magnitude would be policy-relevant.  
- **Transparency about missing data:** The paper notes one missing interest observation. Explain which country-year is missing and why, and show that results are unchanged if interpolated or dropped.

**4.5. Refine the discussion and policy implications.**  
- **Acknowledge data limitations:** Firm-level studies (e.g., Gundert 2023) find micro responses; the aggregate null may reflect offsetting general equilibrium adjustments (e.g., debt shifting across borders) that macro data cannot capture. Discuss this tension explicitly.  
- **Consider dynamic effects:** The post-period is short (max 4 years for early adopters). Debt restructuring takes time. Project the potential long-run effect using a simple partial-adjustment model.  
- **Policy alternatives:** Instead of concluding that “tax coordination alone cannot solve the debt bias,” provide a more nuanced recommendation: e.g., “ATAD’s design—particularly its generous de minimis thresholds—may limit aggregate impact; future coordination could consider lower thresholds or complementary tools like an allowance for corporate equity.”

**4.6. Minor technical points.**  
- **Table formatting:** In Table 1, use consistent rounding (e.g., two decimal places for ratios) and include the number of countries in each period.  
- **Standard errors:** Clarify whether the wild bootstrap p-value in Table 3 is two-sided.  
- **References:** Ensure all cited firm-level studies (Blouin et al., Buettner et al., Clifford, Gundert) are in the bibliography.

---

**Overall assessment:** This is a well-executed, timely paper that makes a valuable contribution by using publicly available macro data to test a major coordinated tax reform. The empirical approach is sound, and the null result is important—even if not definitively zero. Addressing the essential points above will significantly enhance its credibility and impact. With revisions, the paper would be suitable for a journal like *AER: Insights*.
