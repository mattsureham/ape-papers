# Reply to Reviewers

## Reviewer 1 (GPT-5.2) — MAJOR REVISION

### 1.1 Causal estimand precision
**Concern:** The paper oscillates between "capitalized kafala rents" (structural) and "stock market reaction" (reduced-form).
**Response:** We now state the estimand precisely in the Introduction: "the unanticipated change in expected discounted profits for high- versus low-exposure listed firms, attributable to information revealed at the three legislative milestones." The abstract, discussion, and conclusion have been reframed throughout to reference the "differential valuation effect" rather than "kafala rents."

### 1.2 Sector-based exposure confounding
**Concern:** Sector-level differential exposure to other UAE macro news could dominate short-window returns.
**Response:** We acknowledge this concern. The placebo dates, GCC benchmarks, and Appendix A.3 confound audit provide partial reassurance. We have added discussion of this limitation in the new Section 8 (Limitations and Caveats) and note that the stacked DiD with date-by-event FE absorbs all common daily shocks.

### 1.3 Emiratisation bundling as identification problem
**Concern:** This is not a "limitation" — it is a central identification problem.
**Response:** Agreed. We have substantially rewritten Section 2.3 (Background) to present Emiratisation bundling as a first-order identification challenge, with a back-of-the-envelope cost calculation (AED 4.8M/year for a median bank). Section 7.3 (Discussion) now explicitly states: "This is not a minor limitation—it is a central identification challenge." The conclusion and abstract have been reframed to describe the estimand as the "net reform package effect."

### 1.4 Anticipation
**Concern:** Long-run cumulative plots are noisy and do not definitively rule out anticipation.
**Response:** We acknowledge this limitation. The absence of pre-divergence in Figure 7 (now with 30-day smoothing for clearer visualization) provides suggestive but not definitive evidence. The Discussion (Section 7.1) presents anticipation as a credible interpretation rather than dismissing it.

### 1.5 Thin trading
**Concern:** DFM is plausibly not fully efficient; zero-volume days could push toward null.
**Response:** New Section 8 discusses thin trading explicitly. We note that high-exposure firms actually have *higher* mean trading volume (4,711 vs. 2,583 thousand shares, Table 1), and higher market betas (Table 8), suggesting active pricing. We acknowledge that a liquid subsample test and Scholes-Williams/Dimson adjustments are desirable robustness checks for future work.

### 2.1 Benchmark contamination (MAJOR)
**Concern:** CARs subtract an index constructed from treated/control firms — a serious contamination problem.
**Response:** We now acknowledge this issue explicitly in Section 4.1 (Data) and discuss it at length in Section 8 (Limitations). We note that: (a) the stacked DiD (Column 3) sidesteps this entirely via date-by-event FE, producing a near-zero coefficient consistent with the CAR results; (b) the direction of bias is toward attenuation (reinforcing the null, not creating it); (c) replication with the official DFM General Index or MSCI UAE would strengthen the result.

### 2.2-2.4 Cross-sectional correlation and RI structure
**Concern:** Firm clustering doesn't handle event-day common shocks; RI ignores sector assignment.
**Response:** Section 8 now discusses cross-sectional correlation explicitly, noting Table 3's event-by-event results as informal Fama-MacBeth evidence, and acknowledges the RI limitation (sector-level permutation yields only 84 unique permutations). We cite Cameron, Gelbach & Miller (2008) and note SUR/GLS as a direction for future work.

### 2.5 Stacked DiD false precision
**Concern:** 7,769 observations but effective independent observations are far fewer.
**Response:** We now include a paragraph in Section 6.2 noting that "the effective number of independent observations is far smaller" and that the identifying variation comes from 135 firm-event units.

### Claims calibration
**Concern:** "Precisely estimated null" overstated; "bound on rents" too strong.
**Response:** The abstract, introduction, discussion, and conclusion have all been reframed. We now describe the bound as applying to the "differential valuation effect" under "maintained assumptions," explicitly listing those assumptions. The rent calculation is labeled "illustrative" with caveats about Emiratisation bundling and benchmark contamination.

---

## Reviewer 2 (Grok-4.1-Fast) — MINOR REVISION

### Emiratisation confound
**Response:** Substantially expanded as described above. Section 2.3 now includes back-of-envelope Emiratisation costs; Section 7.3 reframes it as central identification challenge.

### Anticipation test
**Response:** We have improved Figure 7 with 30-day moving average smoothing for clearer visualization of pre-trend behavior. We acknowledge that formal pre-event analysis over longer windows would strengthen the paper.

### Firm-level exposure
**Response:** Acknowledged as limitation in Section 8. We note that the continuous specification (Column 2) provides a complementary test, and that firm-level workforce composition data from annual reports could sharpen the variation in future work.

### Missing citations
**Response:** Added: Sokolova & Sorensen (2021) on monopsony meta-analysis; Cameron, Gelbach & Miller (2008) on clustered inference; Kolari & Pynnonen (2010) on event-study cross-sectional correlation; ILO (2020) on Qatar reforms.

---

## Reviewer 3 (Gemini-3-Flash) — MINOR REVISION

### Mainland vs Free Zone heterogeneity
**Response:** New Section 8 discusses free zone heterogeneity explicitly, noting that free zone firms were already exempt from some kafala provisions and that this likely biases the estimated effect toward zero.

### Emiratisation cost quantification
**Response:** Section 2.3 now includes back-of-envelope calculation: 40 additional Emirati hires × AED 120,000 premium = AED 4.8M/year, capitalized at AED 48M — comparable to the monopsony rent the event study would need to detect.

### Trading volume and illiquidity
**Response:** Section 8 discusses thin trading, noting high-exposure firms have higher volume (Table 1). Market-cap weighting and illiquidity exclusion noted as desirable future robustness.

---

## Exhibit Review

### Table 4 labels
**Response:** Fixed in prior round (before referee review). Variable names cleaned to professional labels.

### Figure 7 smoothing
**Response:** Added 30-day moving average overlay. Faint lines show daily values; bold lines show smoothed trend.

## Prose Review

### Opening hook
**Response:** Sharpened in prior round ("nine out of ten private-sector workers cannot change jobs...").

### Roadmap trimmed
**Response:** Removed in prior round.

### Vivid sector examples
**Response:** Added in Section 4.2 — contrast between Emaar Properties and Emirates NBD with specific workforce details.

### Conclusion ending
**Response:** Now ends with: "Legal mobility is worth little to a worker who owes $5,000 to a recruiter. The law changed, but the debt stayed."
