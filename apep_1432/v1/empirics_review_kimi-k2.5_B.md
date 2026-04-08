# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant B)

**Model:** moonshotai/kimi-k2.5
**Variant:** B
**Date:** 2026-04-08T18:34:18.288680

---

**Referee Report: "From the Streets to the Checkbooks: Do Protests Mobilize Campaign Contributions?"**

**1. Idea Fidelity**

The paper deviates substantially from the original research manifest in ways that undermine its feasibility and contribution. Most critically, the manifest proposed using the Crowd Counting Consortium (CCC) dataset, which contains GPS-coded events with crowd-size estimates for 57% of observations (median: 100 people). The actual paper instead uses GDELT media-coded events, which measure newsworthiness rather than physical attendance. This substitution is fatal to the identification strategy: the Madestam et al. (2013) weather IV requires crowd-size variation, whereas GDELT captures media mentions that may increase with dramatic rainy protests (creating reverse causality or at least attenuation).

Additionally, the manifest envisioned a sample of 1,491 cities with 5+ events and ~1.2M city-week observations. The actual paper analyzes only 21 cities with 6,594 city-week observations—a three-order-of-magnitude reduction that raises severe external validity concerns. The paper does not explain this contraction (whether it reflects data merging difficulties, the shift to GDELT, or sample selection criteria), nor does it address why the CCC data—described in the manifest as "confirmed" accessible—was abandoned. The discrepancy between the proposed 2017-2024 period and the actual 2017-2020 (or 2018-2023, as stated in text) sample is minor by comparison.

**2. Summary**

The paper attempts to estimate whether street protests causally increase local small-dollar campaign contributions by using rainfall as an instrument for protest occurrence. Leveraging a city-week panel of 21 U.S. cities (2017/8–2020), the author finds that weekly precipitation is a weak predictor of media-coded protest occurrence (F-statistic ≈ 2). The paper reframes this as a methodological contribution: the weather IV designed for physical attendance (Madestam et al. 2013) fails when applied to GDELT's media-based event coding because journalists report protests regardless of weather. While the OLS estimates show no association between protests and contributions, the 2SLS estimates are uninformative due to the weak instrument.

**3. Essential Points**

*Data Source Substitution and Identification Validity.* The paper cannot answer the research question posed in the manifest because it substitutes GDELT for CCC data without adequately addressing the consequences. GDELT events represent editorial decisions about newsworthiness, not physical turnout. Rainfall may correlate with protest *coverage* differently than protest *attendance* (e.g., dramatic confrontations in rain receive more media attention). The paper acknowledges this mechanism but treats it as a finding rather than a design flaw. Since the research question explicitly concerns physical mobilization ("From the Streets to the Checkbooks"), using media-coded events invalidates the study's ability to test whether street protest causes donations. The authors must either obtain and use the CCC data as specified in the manifest or reframe the paper entirely as studying media salience rather than street protest.

*Severe Sample Limitations.* The restriction to 21 cities (from the proposed 1,491) creates multiple problems. First, with only 21 clusters, standard errors clustered at the city level are likely underestimated, and inference is unreliable. Second, the sample selection criteria ("cities with at least five protest events") are endogenous: cities with frequent protests likely differ systematically in donation patterns. Third, the external validity is questionable—this represents fewer cities than many metropolitan statistical areas. The paper must explain why the CCC-FEC merge failed (if attempted) or justify why these 21 cities represent the relevant population.

*Internal Contradictions and Missing Evidence.* The text contains critical contradictions regarding the first stage. Section 3.2 claims "I show that precipitation strongly predicts protest occurrence in the first stage," yet Section 4.1 and the Abstract correctly note the F-statistic is approximately 2. This inconsistency undermines reader confidence. Furthermore, Section 4.4 ("Donor Extensity") claims that "The 2SLS estimate for the log number of unique contributors is positive" and discusses this as a key finding, yet no table or standard error is provided for this outcome (Table 2 only shows contributions count and amount). Given the instrument weakness, this claim cannot stand without explicit demonstration.

**4. Suggestions**

*Reconcile with the Manifest or Explain Deviations.* If the CCC data proved unavailable or unusable, the paper needs a transparent discussion of why the merge failed (e.g., geocoding inconsistencies, temporal coverage gaps) and how the GDELT substitution changes the research question. Ideally, the authors should attempt to obtain CCC data or another source with actual crowd sizes (e.g., the Digital Archive of Popular Protests). If restricted to GDELT, consider alternative research questions where GDELT is appropriate: for example, whether *media coverage of protests* causes donations (using the media mention count as the treatment), though this would require a different instrument.

*Address the Weak Instrument Problem Directly.* With an F-statistic of 2, the 2SLS estimates are biased toward OLS and unreliable. The paper should report weak-instrument-robust confidence sets (Anderson-Rubin or Kleibergen-Paap) rather than standard 2SLS standard errors. Given the likely failure of the exclusion restriction (media coverage vs. attendance), consider whether the paper should pivot to a "broken instrument" design that uses the weak first stage as a diagnostic for measurement error, or abandon the IV approach entirely in favor of event-study designs around specific high-profile protests (e.g., George Floyd) with synthetic controls.

*Clarify Sample Construction.* Provide a detailed appendix explaining how 43,000 events became 21 cities. If the limitation stems from requiring weather data or FEC contribution coverage, show the selection patterns: are the 21 cities larger or more politically active than excluded cities? Discuss how this selection affects generalizability. If the paper cannot expand the sample, acknowledge that this is a pilot study of major metropolitan areas rather than a representative sample.

*Fix Internal Inconsistencies.* Ensure the text accurately reflects the weak first stage throughout—remove claims of "strong" first-stage relationships. Either add Table 2 columns for unique donors with appropriate caveats about instrument weakness, or remove the donor extensity discussion. Similarly, reconcile the sample period discrepancies (2017-2020 vs. 2018-2023).

*Consider Alternative Mechanisms.* The Discussion section hints that protests may operate at national rather than local levels. This suggests a different empirical strategy: exploit variation in protest intensity across media markets relative to donation patterns in ActBlue/WinRed data (if obtainable). Alternatively, use the timing of protest days within weeks to test whether donations spike on days with protests versus other days of the same week, holding city-week fixed effects.

*Strengthen the Contribution.* The current contribution is framed as a "cautionary lesson" for extending weather IVs to GDELT data. This is useful but narrow. To merit publication, the paper needs either (1) a successful application showing that protests do/don't cause donations using valid instruments and crowd-size data, or (2) a systematic analysis of why GDELT and weather instruments are incompatible, potentially comparing GDELT counts to actual crowd counts where both exist (validation exercise). Without these additions, the paper represents a failed research attempt rather than a contribution.

*Data Reporting.* Table 1 reports mean contributions of 2.0 per city-week with SD of 27.8, yet the 75th percentile is 0. This suggests extreme skewness or coding errors—verify and discuss. Also, the measure of precipitation should be daily (as per the manifest and Madestam) rather than weekly averages, since protests occur on specific days and weekly averaging attenuates the signal.

**Verdict:** The paper in its current form does not support causal claims about the relationship between street protest and campaign contributions due to the identification failure (wrong data source), limited external validity (21 cities), and internal contradictions. The paper should be rejected unless the authors can obtain crowd-size data (CCC) and demonstrate a valid first stage, or completely reframe the question to match the GDELT data structure with appropriate methodology.
