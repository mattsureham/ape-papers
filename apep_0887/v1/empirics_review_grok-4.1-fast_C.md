# V1 Empirics Check — x-ai/grok-4.1-fast (Variant C)

**Model:** x-ai/grok-4.1-fast
**Variant:** C
**Date:** 2026-03-24T23:03:57.816028

---

### 1. Idea Fidelity
The paper partially pursues the original idea manifest but deviates substantially in key elements. It retains the core research question (RRNC codes as potential nudges for voluntary testing/mitigation spillovers in existing homes), staggered DiD identification via Callaway-Sant'Anna (CS 2021), EPA radon zones for mechanism testing, and Census CBP NAICS 562910 data. However, it misses the primary outcome (CDC Environmental Health Tracking Network testing rates/measures 843 and 865), building permits (Census BPS), and placebo in low-risk Zone 3 counties as a clean control. Instead, it substitutes CBP remediation employment/establishments/payroll as a proxy and restricts to 20 statewide adoptions (2007–2015), ignoring the manifest's 100+ local/jurisdictional adoptions (e.g., Brentwood TN 1999, Iowa City 2002) and earlier timeline. This narrows variation, shifts from direct testing to an industry proxy, and abandons promised data sources without justification, diluting fidelity.

### 2. Summary
This paper exploits staggered statewide adoption of radon-resistant new construction (RRNC) codes across 20 U.S. states (2007–2015) to test for behavioral spillovers into voluntary radon testing/mitigation in existing homes, proxied by county-level employment, establishments, and payroll in the environmental remediation industry (Census CBP NAICS 562910). Using CS DiD with never-treated states as controls, TWFE, and Sun-Abraham estimators, it finds a precisely estimated null effect (ATT ≈ 0, SE ≈ 0.065; 95% CI rules out >0.065 SD effects), robust across outcomes, radon zones, and leave-one-out checks. The null implies building codes confine benefits to the regulated (new construction) margin, delivering no information externalities to existing stock.

### 3. Essential Points
1. **Outcome proxy validity and missing primary data**: The shift from CDC testing rates (manifest's core outcome, with confirmed access via API and smoke-tested county records) to CBP remediation industry metrics is a critical gap. While NAICS 562910 plausibly captures testing/mitigation firms, it conflates radon-specific demand with other remediation (e.g., asbestos, lead), and industry expansion may lag homeowner behavior due to entry barriers. Authors must report CDC results in an appendix (even if sparse/noisy) or rigorously validate the proxy (e.g., correlate CBP with CDC at county-year level; decompose NAICS via radon-specific firm counts if available). Absent this, the null risks confounding supply-side frictions with true behavioral absence.

2. **Incomplete treatment variation**: Restricting to 20 statewide adoptions post-2007 excludes the manifest's 100+ local staggered events (1999–2005), halving pre-periods and variation. This risks confounding (e.g., post-2007 coincides with Great Recession recovery, national EPA campaigns). Essential: Expand to local RRNC adoptions (AARST/state records confirm availability) or explicitly bound bias from exclusion via placebo on pre-2007 locals.

3. **Mechanism test underpowered in low-risk areas**: Zone 1 null is compelling, but Zone 3 (true placebo per manifest) is not separately reported/emphasized—interaction relies on Zone 2 reference, which shows noisy positive (0.117, SE=0.115). Triple-difference (Post × Zone1 vs. Zone3 baseline) is needed to confirm information channel; current table insufficiently isolates low-risk irrelevance.

### 4. Suggestions
The paper delivers a clear, economically meaningful precise null—magnitudes (≈0 log points) are plausible given baseline remediation employment (~18/county, 2% of waste sector) and low testing rates (<10% homes ever tested), where spillovers would need >10–20% uptake to move industry measurably. SEs are appropriate (state clustering matches treatment; CS handles stagger-robustness; power MDE=0.065 SD credible for N=32k). Strengthen as AER: Insights by emphasizing policy takeaway (codes ≠ nudges; prioritize direct testing mandates).

**Empirical enhancements**:
- Add event-study figures (CS group-time ATTs by e=-5 to +7, with 95% CI bands)—text description insufficient; plot pre-trends explicitly (current reassurance via scattered insignificance is weak). Include Sun-Abraham TW/ML weights table to quantify TWFE bias (manifest's placebo logic anticipates heterogeneity).
- Power curves: Extend Table 4 with formal MDE by outcome/cohort (e.g., via simulations); clarify SDE classification (Table A1 good start, but link to economic magnitudes: e.g., 0.065 SD ≈ +1.2 remediation jobs/county, or +$100k payroll).
- Robustness expansion: (i) BPS permits × RRNC interaction to control new construction demand leakage into remediation; (ii) falsification on non-radon NAICS (e.g., 562991 septic services); (iii) entropy balancing on pre-trends (Table 1 balance good, but weights could tighten SEs). LOO already strong—plot coefficient cloud.

**Data and transparency**:
- Appendix: Full CS cohort-specific ATTs (8 groups); county-level adoption map; CBP noise-infusion sensitivity (2017+ ok, but quantify coverage drop). Release replication code/data (GitHub placeholder appreciated).
- CDC integration: Even if counts sparse (e.g., Poisson/negbin DiD), report as supplementary—manifest confirms 2.9k counties/year; zero-inflated models handle skewness. If power too low, bound via IV (RRNC → awareness proxied by Google Trends "radon test").

**Writing and framing**:
- Title/Abstract: "Absence of spillovers" strong, but soften marginally-sig establishments (-2.8%, p=0.10) as "hint of crowding-out" rather than anomaly—explore in Discussion (e.g., contractors shift to new-build compliance).
- Intro/Disc: Quantify economic stakes (e.g., 21k deaths/year; $250 vs. $1.5k retrofit cost → spillovers could save $Xbn). Contrast Pinchbeck et al. sharper: UK maps direct-to-consumer vs. U.S. B2B compliance. Policy: Simulate welfare if disclosure mandated at sale (cite Bennear).
- Heterogeneity: Table 3 col (3) confusing (positive main + negative interaction = Zone1 null); reformat as stacked DiD by zone. Add home age share (ACS) interaction—spillovers likelier in older stock.
- Length: Trim Institutional Background (merge radon/RRNC); add 1/2-page lit review table (nulls like Greenstone vs. positives like Newell).

Overall, solid design elevates null to publishable insight—address essentials for credibility, and this fits AER: Insights (tight, powered null, policy-relevant). Reject risk low if proxy/CDC fixed.
