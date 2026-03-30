# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant B)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** B
**Date:** 2026-03-30T21:48:22.158841

---

# Referee Report

**Paper:** The Enforcement Lottery: Does It Matter Who Inspects?  
**Format:** AER: Insights  
**Date:** October 26, 2023

## 1. Idea Fidelity

The paper pursues the core question outlined in the manifest: does the identity of the environmental inspector (federal vs. state) causally affect pollution outcomes? However, there are notable deviations in the identification strategy and data scope that warrant comment.

*   **Identification Strategy:** The manifest proposed exploiting the **State Review Framework (SRF) 4–5 year review cycle** as a quasi-random instrument for federal intervention. The paper implements a **state-year aggregate federal inspection share** IV. While the text mentions the SRF as the institutional backdrop, the empirical strategy does not explicitly model the SRF cycle timing (e.g., interacting the IV with SRF review years). This weakens the specific "SRF lottery" claim made in the manifest.
*   **Data Scope:** The manifest highlighted access to 800,000+ facilities via EPA ECHO. The paper restricts the outcome analysis to **9,907 TRI-reporting facilities**. This is a necessary constraint given TRI coverage, but it significantly reduces the sample relative to the "800K facilities" promise. The paper should clearly acknowledge this limitation when discussing the welfare costs of delegation.
*   **Outcome:** The manifest proposed testing TRI emissions and SNC (Significant Non-Compliance) status. The paper focuses on TRI emissions. Including violation/penalty data (available in ECHO/ICIS) would have aligned more closely with the manifest's broader enforcement outcome goals.

Despite these deviations, the paper successfully operationalizes the central "enforcer lottery" concept using high-quality administrative data.

## 2. Summary

This paper tests whether federal EPA inspectors reduce toxic releases more effectively than state-delegated inspectors under the Clean Air Act. Instrumenting facility-level federal inspection receipt with state-year federal enforcement intensity, the author finds a strong first stage but a null second-stage effect on TRI emissions. The results suggest that inspector identity matters less for environmental outcomes than the act of inspection itself, challenging arguments for recentralizing enforcement authority.

## 3. Essential Points

The paper presents a clean null result with a strong first stage, which is a valuable contribution. However, three critical issues must be addressed to ensure the causal claim is robust and the interpretation is accurate.

1.  **Validation of the Exclusion Restriction (SRF Link):** The validity of the IV relies on the assumption that state-level federal inspection intensity is orthogonal to facility pollution trends. The manifest argued this exogeneity comes from the **SRF administrative rotation**. Currently, the paper asserts this but does not demonstrate it empirically.
    *   *Requirement:* The authors should explicitly test whether the variation in the instrument correlates with SRF review cycles. For example, include an indicator for "State in SRF Review Year" and show that the IV variation spikes during these periods. If the IV variation is driven by EPA targeting states with worsening pollution (rather than SRF rotation), the exclusion restriction fails.

2.  **TRI Reporting vs. Actual Emissions:** The outcome (TRI) is self-reported. A null effect on TRI could imply: (a) federal inspectors do not reduce actual pollution, OR (b) federal inspectors do not improve reporting accuracy relative to states. The paper hints at a "reporting channel" in the Discussion but treats TRI as a direct proxy for pollution.
    *   *Requirement:* The authors must distinguish between enforcement stringency and reporting compliance. Using **ECHO violation/penalty data** as an intermediate outcome is crucial. If federal inspectors find more violations (higher stringency) but TRI doesn't change, it suggests a reporting issue. If they find similar violations and TRI doesn't change, it suggests genuine equivalence.

3.  **Sample Generalizability (TRI vs. Universe):** The manifest emphasized the "800K+ regulated facilities" to quantify the welfare cost of delegation. The paper analyzes 9,907 TRI facilities (large polluters). State/federal delegation dynamics may differ for smaller facilities where state resources are more constrained.
    *   *Requirement:* The conclusion regarding the "welfare cost of delegation" must be qualified. The authors should discuss whether results might differ for non-TRI facilities (e.g., smaller sources) where state capacity constraints might be more binding. A brief analysis of inspection frequency or violation rates for the broader ICIS-Air sample (even without TRI outcomes) would help contextualize the findings.

## 4. Suggestions

The following recommendations are intended to strengthen the paper's narrative and robustness without altering the core findings. These suggestions constitute the majority of the feedback below.

**1. Strengthen the SRF Instrument Narrative**
The paper currently treats the SRF as background context rather than the empirical engine. To align with the manifest's novelty claim:
*   **Visualize the Cycle:** Create a figure showing the time series of federal inspection share for a few representative states, highlighting the SRF review years. If the instrument variation aligns with these reviews, it bolsters the exogeneity claim.
*   **Interaction Term:** Consider an IV specification that interacts the state federal share with an SRF review indicator. This would isolate the variation specifically driven by the administrative cycle, addressing potential concerns that federal share increases in response to state pollution spikes.

**2. Expand Outcome Analysis to Enforcement Metrics**
Since TRI data is limited to large facilities and is self-reported, leveraging the full ECHO/ICIS-Air dataset for enforcement outcomes would add depth:
*   **Violation Rates:** Regress the probability of a violation finding (SNC or formal violation) on the federal inspection indicator. If federal inspectors are stricter, this coefficient should be positive.
*   **Penalty Amounts:** Test whether federal inspections lead to higher penalties per violation. This helps mechanism: if federal inspectors are stricter (higher penalties) but pollution doesn't change, the null TRI result is more nuanced (deterrence failure vs. equivalence).
*   **Inspection Frequency:** The paper notes federal inspections substitute for state inspections. Clarify if total inspection *coverage* changes when federal share increases. If total inspections drop, the null TRI effect might reflect reduced coverage rather than inspector equivalence.

**3. Heterogeneity Analysis**
The null result might mask heterogeneity that is policy-relevant:
*   **Political Environment:** State enforcement might vary by political leaning. Test if the federal-state gap is larger in states with Republican governors or weaker environmental agencies (e.g., low state budget per capita).
*   **Industry Type:** Some industries (e.g., chemical manufacturing) might be more sensitive to inspector identity than others. A split by NAICS code could reveal where delegation matters most.
*   **Facility Size:** Within the TRI sample, split by emission volume. Larger facilities might have sophisticated compliance teams that negate inspector differences, while smaller TRI facilities might be more vulnerable to inspector stringency.

**4. Clarify Data Sources and Terminology**
*   **ECHO vs. ICIS-Air:** The manifest refers to "EPA ECHO data," while the paper uses "ICIS-Air." ECHO is the portal; ICIS-Air is the underlying system. Clarify this relationship in the Data section to avoid confusion for readers familiar with EPA data systems.
*   **Flag Definitions:** The paper mentions `STATE_EPA_FLAG` ('E', 'S', 'L'). Ensure the handling of 'L' (Local) is clear. Are local inspections excluded or grouped with state? This affects the "state vs federal" binary.
*   **Sample Selection:** Explicitly state why 9,907 facilities are used (TRI linkage). A flowchart of data matching (ICIS → FRS → TRI) would be helpful in the
