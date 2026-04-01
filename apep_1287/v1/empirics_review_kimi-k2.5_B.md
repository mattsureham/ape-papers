# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant B)

**Model:** moonshotai/kimi-k2.5
**Variant:** B
**Date:** 2026-04-02T00:17:50.375961

---

**Referee Report: "The Sharecropping Escape: Flood-Induced Displacement and Black Occupational Upgrading in the Great Migration Era"**

---

**1. Idea Fidelity**

The paper pursues the core research question outlined in the manifest—whether the 1927 Mississippi Flood improved occupational trajectories for displaced Black sharecroppers—but deviates from the promised empirical strategy in two consequential ways. First, the sample size is 44,191 rather than the 167,348 Black farm workers cited in the manifest; this 74% attrition stems from requiring linkage across three censuses, fundamentally changing the population under study from the intended "Black farm workers" to "Black farm workers successfully linked across 1920–1940." Second, the paper abandons the promised continuous measure of flood severity (county proportion inundated from Hornbeck & Naidu) in favor of a binary Alluvial Plain indicator, substantially weakening the instrumental variable's power and altering the interpretation from "flood intensity" to "flood zone residence." The paper also omits the promised Palmer drought placebo test and pre-1927 trend verification, leaving the parallel trends assumption largely unsubstantiated.

---

**2. Summary**

This paper uses individual-level linked census data to estimate the causal effect of the 1927 Mississippi Flood on Black sharecroppers' occupational mobility, instrumenting migration with county-level flood exposure. The authors find that flood-induced migration generated large, positive effects on socioeconomic index scores by 1940 (5.7 points), with null effects for white workers supporting a race-specific "sharecropping trap" mechanism.

---

**3. Essential Points**

**1. Massive sample selection and external validity.** The drop from 167,348 Black farm workers in the manifest to 44,191 in the analysis (26% retention) represents a critical external validity threat. Linked census samples are highly selected toward stable, literate, higher-status individuals—precisely those likely to benefit most from migration. The paper must demonstrate that the linked sample resembles the full population on observable 1920 characteristics and explicitly discuss how selection into linkage (rather than selection into migration) biases the LATE. Without this, the results may not generalize to the marginalized sharecroppers most trapped by the system.

**2. Binary instrument vs. continuous severity.** The shift from Hornbeck & Naidu's continuous inundation measure to a binary Alluvial Plain dummy discards substantial variation and deviates from the manifest's promised design. The binary approach conflates marginal levee breaches with catastrophic flooding and reduces the first-stage power (F-stat ≈ 12.8, borderline with clustered standard errors). The authors must justify why the continuous measure was abandoned—was it unavailable at the individual level?—and demonstrate robustness to alternative flood intensity codings (e.g., quartiles of inundation share).

**3. Weak instrument fragility in falsification and heterogeneous effects.** The white falsification test produces an IV coefficient of 11.8 (SE = 11.7), indicating a completely uninformative estimate due to weak instruments in the white sample, not a "null" effect. Similarly, Table 4 splits the sample by age without reporting first-stage F-statistics for each subgroup; if compliance rates vary by age, these subsample IV estimates may suffer from severe weak-instrument bias. The paper must report first-stage statistics for all subsamples and avoid interpreting statistically insignificant coefficients as evidence of "no effect."

---

**4. Suggestions**

**Mechanism and destination analysis.** The paper argues the flood "broke the sharecropping trap" but provides limited evidence on *where* compliers moved and *what* occupations they entered. Using the linked data's geographic identifiers, the authors should tabulate destination counties (urban vs. rural, North vs. South) and occupational transitions (e.g., farm laborer → operative → craftsman). If movers predominantly entered domestic service rather than manufacturing, the welfare interpretation changes substantially despite similar occscore gains.

**Pre-trends and dynamic effects.** The balance tests in Table 1 only verify 1920 cross-sectional balance. The manifest promised pre-1927 trend analysis; the authors should exploit the 1910–1920 linked data (if available) to test whether flood-exposed counties were on differential occupational trajectories prior to the flood. An event-study specification plotting coefficients for 1910, 1920, 1930, and 1940 would dramatically strengthen the identifying assumption.

**Clarify the "effective F-statistic."** Table 2 reports both an "F-test (1st stage)" of 502.7 and text citing "effective $F \approx 12.8$." These refer to different statistics (likely the non-clustered vs. clustered Kleibergen-Paap F-statistics). With 208 county clusters, the effective F-statistic of 12.8 suggests potential weak-instrument bias toward OLS. The authors should report the Stock-Yogo critical values for the Kleibergen-Paap F-statistic and consider using the Anderson-Rubin test or weak-inversion confidence intervals for the main results, particularly given the large standard errors on occscore changes.

**Address the linkage selection explicitly.** The paper should include an appendix table comparing the 44,191 linked individuals to the full 167,348 Black farm workers on 1920 observables (age, literacy, home ownership, occupational score). If linked individuals are positively selected, the authors could implement a Heckman-style selection correction or bounds analysis to assess how selection into linkage affects the main estimates.

**Heterogeneous treatment effects by compliance type.** The LATE interpretation hinges on who the compliers are. The paper suggests older workers benefited more, but if older workers were less likely to be compliers (lower first-stage), the IV weighting may obscure this. The authors should use the Abadie (2003) kappa weighting approach to characterize complier demographics or estimate the LATE separately for "likely compliers" (e.g., those in high-flood counties with low baseline mobility).

**Alternative falsification tests.** The manifest promised a Palmer drought placebo; the paper should implement this by interacting drought severity in non-flood years with year indicators to verify that the instrument does not proxy for general weather shocks. Additionally, the authors should test for effects on 1930 outcomes conditional on *not* migrating—if flood exposure hurt non-movers (e.g., through local labor market destruction), the exclusion restriction is violated.

**Policy implications.** The conclusion suggests displacement assistance should focus on "occupational transition rather than restoration." However, the paper shows forced displacement had positive effects *only because* the status quo was a coercive trap. The policy lesson should be nuanced: the welfare gains came from escaping a specific institutional failure (debt peonage), not from displacement per se. The authors should distinguish between "forced displacement from coercive institutions" (welfare-improving) and "forced displacement from functioning markets" (likely welfare-reducing).

**Presentation issues.** Table 3 Panel C reports IV estimates for white workers that are undefined due to weak instruments; these should be reported as "undefined/infinite" or omitted rather than presented as precise coefficients. Table 4 should report first-stage F-statistics for each subsample. The label "left\_farm\_30" in Table 2 appears twice (columns 4 and 7); clarify that column 7 is the IV estimate while column 4 is reduced form.
