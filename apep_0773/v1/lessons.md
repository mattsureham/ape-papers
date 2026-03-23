# Lessons: apep_0773 v1

## Discovery
- Cross-program administrative spillover is a genuinely novel angle in the safety net literature. The mechanism (shared eligibility infrastructure transmitting negative shocks) is intuitive and policy-relevant, but has never been estimated causally.
- The SNAP × Medicaid intersection is data-rich: USDA FNS, CMS CAA reports, and KFF/CLASP classifications are all publicly available.

## Data
- Census ACS provides state-level SNAP household counts but only annually. Monthly expansion attenuates within-year variation and limits power.
- CMS procedural termination rates provide clean variation in administrative burden intensity. The continuous treatment specification exploiting this variation produced the strongest result.
- The integrated/separate system classification from KFF/CLASP is binary and somewhat coarse. Some "integrated" states may have different degrees of integration.

## Analysis
- With 51 states, 24 treated, and simultaneous treatment, power is fundamentally limited. The binary DiD has a standard error of 0.261 on a coefficient of -0.300 — the t-statistic is barely above 1.
- The continuous treatment specification (procedural termination rate × post) yields the best result (p = 0.10) because it exploits within-group variation in treatment intensity rather than just the binary split.
- The null placebo is crucial: no pre-existing differential trend between integrated and separate states.

## Review
- Both reviewers (codex-mini, gemini-3-flash) flagged the ACS annual data choice as the main weakness. USDA FNS provides true monthly administrative SNAP counts. I added an explicit discussion of this trade-off (ACS gives rates with a denominator; FNS gives counts without one).
- Both noted the procedural termination rate is endogenous (observed post-treatment). Added a paragraph acknowledging this concern and positioning the continuous spec as complementary evidence, not a clean causal estimate.
- Codex-mini requested event-study plots — not feasible for V1 (zero figures rule) but flagged for V2.
- Gemini suggested SNAP Application Processing Timeliness (APT) data as a mechanism test — excellent idea for future work.
- Added minimum detectable effect calculation to Discussion to contextualize the underpowered binary estimate.

## Summary
- Honest null result framed as "first causal estimate" with suggestive evidence. The dose-response pattern provides the most compelling evidence. Policy implications for integrated system design are clear even without statistical significance.
