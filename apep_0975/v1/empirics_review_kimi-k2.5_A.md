# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-03-26T11:56:00.296543

---

**Referee Report: "The Prosecution Gap: Cross-Border Enforcement Cooperation and Crime in the European Union"**

---

### 1. Idea Fidelity

The paper successfully pursues the core empirical agenda outlined in the manifest: exploiting the staggered transposition of Directive 2014/41/EU (the European Investigation Order) across EU member states to estimate effects on cross-border crime using Callaway-Sant'Anna estimators. The authors maintain the focus on fraud, drug offenses, and theft as primary outcomes, with homicide and serious assault as placebo categories, and correctly employ Denmark and Ireland as never-treated controls. 

However, the paper departs from the original design in one potentially consequential way: the manifest emphasized comparing "2 early transposers (May 2017) vs 13 infringement-procedure countries," suggesting a focus on the contrast between compliant and non-compliant states. Instead, the paper uses all transposition timing variation (including the four 2016 early transposers) in a standard staggered DiD framework. This is reasonable given the data, but the paper should explicitly address whether the early transposers (Hungary, Romania, Czechia, France) are credible controls for the late transposers, or whether they represent a distinct regime of institutional readiness that threatens the parallel trends assumption. Additionally, the manifest's emphasis on the "probability-of-conviction channel" (Becker 1968) is somewhat underdeveloped empirically; the paper would benefit from testing whether conviction rates or case clearance—not just reported crimes—respond to the reform.

---

### 2. Summary

This paper provides the first causal evaluation of the European Investigation Order (EIO), exploiting staggered adoption across 25 EU member states (2016–2018) to test whether streamlined cross-border evidence gathering deters crime. Using staggered difference-in-differences and triple-difference designs on Eurostat crime data (2008–2022), the author finds null effects on cross-border crime rates but documents a relative increase in reported cross-border versus domestic offenses post-transposition, consistent with a detection channel rather than deterrence.

---

### 3. Essential Points

**1. The placebo violations threaten the identification strategy.** The finding that serious assault declines significantly in both Callaway-Sant'Anna ($-0.191$, $p = 0.0002$) and TWFE specifications ($-0.430$, $p < 0.05$) undermines the validity of using domestic crimes as a control category for the triple-difference. If the EIO truly affects only crimes requiring cross-border evidence, we should expect precise zeros for homicide and assault. The significant assault result suggests either: (a) concurrent criminal justice reforms correlated with EIO timing, (b) differential reporting changes affecting violent crime, or (c) a broader trend in late-transposing countries that also affects cross-border crimes. The authors must address this explicitly—ideally by showing pre-trend plots for all five crime categories and testing whether assault/homicide trends diverge systematically prior to transposition. If the placebo fails, the triple-difference interpretation becomes fragile.

**2. The "detection channel" interpretation requires stronger evidentiary support.** The triple-difference finding that cross-border crimes *increase* relative to domestic crimes (coefficient $+0.683$) is interpreted as improved detection capacity. However, this could equally reflect: (a) reclassification of existing domestic crimes as cross-border crimes once the evidentiary infrastructure exists, (b) double-counting of cases across jurisdictions as cooperation improves, or (c) compositional changes in reporting behavior rather than true criminal activity. The authors need to provide auxiliary evidence distinguishing "true detection" (more cases solved/cleared) from "administrative artifact" (reclassification). For instance, do conviction rates for cross-border crimes increase? Do Eurostat metadata show changes in recording practices post-2017? Without this, the detection claim remains speculative.

**3. Selection into transposition timing is inadequately addressed.** The paper treats transposition dates as exogenous variation, but the 13 infringement-procedure countries likely delayed transposition due to weaker institutional capacity, resource constraints, or higher baseline crime complexity. If late transposers were trending differently in unobserved determinants of cross-border crime (e.g., slower digitization of financial surveillance), the parallel trends assumption fails. The authors should: (a) test for pre-trends by transposition cohort (2016 vs. 2017 vs. 2018), (b) report covariate balance across cohorts on observable determinants of crime (GDP, police spending, internet penetration for cyber-fraud), and (c) consider a "donut" design excluding the early 2016 transposers if they represent a distinct compliance regime.

---

### 4. Suggestions

**Measurement and Mechanisms.** The paper relies solely on police-recorded offenses, which conflate true crime, reporting behavior, and recording practices. To bolster the detection channel claim, I suggest the authors obtain data on: (a) EIO request volumes by member state (available from Eurojust or the European Commission's 2025 evaluation), (b) case clearance rates for cross-border crimes, or (c) prosecution statistics from Eurostat's `crim_just` database. If EIO transposition correlates with increased requests and higher clearance rates but not lower offense counts, this would strongly support the detection interpretation. Conversely, if request volumes are low, the null deterrence result may simply reflect low treatment intensity rather than behavioral inelasticity.

**Heterogeneity Analysis.** The EIO should matter most for crimes with high cross-border evidence intensity. The paper mentions fraud, drugs, and theft, but these categories are heterogeneous. Fraud encompasses purely domestic scams and complex transnational networks. The authors could use the ICCS subcategories (if available) or interact the treatment with measures of cross-border financial integration (e.g., TARGET2 payment volumes or bilateral trade flows) to test whether the EIO has larger (or any) effects where cross-border evidence is most necessary. Similarly, testing heterogeneity by pre-existing mutual legal assistance efficiency (perhaps proxied by bilateral treaty density) would clarify whether the EIO mattered most for countries replacing dysfunctional systems versus those with already-efficient cooperation.

**Spillovers and General Equilibrium.** The discussion briefly mentions substitution to non-EU jurisdictions, but the empirical design cannot detect this. Given the small sample (25 countries), the authors could examine spillovers to neighboring non-EU states (e.g., Western Balkans, Switzerland, Norway) using INTERPOL or UNODC data. If EIO implementation displaced criminal activity, we should see crime increases in adjacent non-EU regions correlated with EIO adoption timing.

**Statistical Precision and Presentation.** With only 25 clusters (countries), standard cluster-robust inference may undercover. The paper uses randomization inference (RI) for the main fraud result ($p = 0.24$), which is commendable, but should report RI p-values for all primary specifications, particularly the triple-difference where the detection claim rests. Additionally, the event-study plots referenced in Section 4 should appear in the main text or appendix to visually assess parallel trends; without them, readers cannot evaluate the identifying assumption.

**Policy Interpretation.** The conclusion argues that "evaluating [enforcement infrastructure] on deterrence alone risks abandoning effective institutions for the wrong reason." This is a valid point, but the paper should clarify what the counterfactual is. If the EIO increases recorded crime without improving convictions or victim restitution (metrics not shown), it is unclear whether society benefits from the "detection dividend." The authors should nuance the normative implications: detection without corresponding incapacitation or deterrence may simply impose higher criminal justice costs without reducing victimization.

**Writing and Structure.** The abstract is excellent—clear, concise, and comprehensive. However, Section 2 should clarify whether the 90-day deadline refers to recognition or execution (the text mentions both), as this affects the mechanism. Table 2 notes that Czechia and France transposed in 2016 with "On time / 2017" status, which is confusing—if they transposed in 2016, they were early, not merely "on time." Clarify the coding of these anticipatory transpositions. Finally, the standardized effect size table in the Appendix (Table A1) labels positive point estimates as "Large positive" despite being statistically insignificant; this is misleading—magnitude classifications should distinguish between precision and sign.

**Robustness Checks.** The robustness table excludes COVID years, but the pandemic may have affected cross-border crime differentially (e.g., travel restrictions reducing drug trafficking). Rather than dropping these years, include them with pandemic interaction controls or show that results are stable when including 2020–2022 with specific pandemic controls. Additionally, test sensitivity to defining treatment at the semester level rather than annual, given that transpositions occurred throughout the year.

**Broader Contribution.** The paper notes correctly that this is the first empirical economics paper on the EIO. To maximize impact, the authors should briefly contrast their findings with the literature on domestic procedural reforms (e.g., speedy trial acts, discovery rules) and transnational policing cooperation (e.g., Prüm Treaty evaluations). This would help readers understand whether the null deterrence result is specific to cross-border judicial cooperation or part of a broader pattern where procedural efficiency fails to deter rational offenders.
