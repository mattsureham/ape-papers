# Reviewer Response Plan

## Summary of Feedback

Three referee reviews (GPT: Major Revision; Grok: Minor Revision; Gemini: Minor Revision), plus exhibit, prose, and literature reviews.

### Common Concerns Across Reviewers
1. **Emiratisation bundling** — All three flag as central identification problem, not just a limitation
2. **Benchmark contamination** — GPT flags that CARs subtract a market index built from sample firms
3. **Tone of claims** — "Bound on kafala rents" overstates what design identifies
4. **Thin trading / illiquidity** — Not addressed diagnostically
5. **Sector-level exposure** — Coarse; firm-level preferable

### Reviewer-Specific Issues
- **GPT:** Cross-sectional correlation, RI permutation structure, stacked DiD false precision, external benchmark needed
- **Grok:** Anticipation test gap, missing citations (thin-market event studies, Qatar reforms)
- **Gemini:** Free Zone vs Mainland heterogeneity, Emiratisation cost quantification

---

## Revision Plan

### A. Reframe Estimand and Claims (LaTeX — all sections)
- **Abstract:** Replace "bounds the capitalized value of kafala-derived monopsony rents" with "bounds the net valuation effect of the reform package"
- **Introduction:** Precisely define estimand as "unanticipated change in expected discounted profits attributable to information at legislative milestones"
- **Discussion 7.5:** Recalibrate bounding language; label rent calculation as "illustrative" not "formal rejection"
- **Conclusion:** Reframe contribution from "bound on rents" to "bound on net expected profit effects under stated assumptions"

### B. Expand Emiratisation as Identification Problem (LaTeX — Sections 2.3, 7.3)
- Promote from "limitation" to central identification challenge
- Add back-of-envelope Emiratisation cost calculation (2% quota × median bank employment × Emirati wage premium)
- Discuss de-bundling infeasibility and what it means for interpretation
- Note that the stacked DiD (Column 3) with date×event FE is agnostic to benchmark but doesn't solve Emiratisation bundling

### C. Address Benchmark Contamination (LaTeX — Sections 4.1, 5)
- Acknowledge that the "DFM General Index" was constructed from sample firms
- Note that Column 3 (stacked DiD) absorbs all common daily shocks via date×event FE, providing benchmark-free identification
- Add footnote recommending future work use the official DFM General Index
- Discuss how contamination would attenuate (not inflate) treatment effects, biasing toward null

### D. Add Liquidity and Thin Trading Discussion (LaTeX — Sections 4, 7)
- Add paragraph on DFM trading characteristics and zero-volume days
- Discuss how thin trading biases toward null (stale prices miss information incorporation)
- Note that higher-volume high-exposure firms (Table 1) should incorporate faster, working against attenuation

### E. Improve Inference Discussion (LaTeX — Sections 5.6, 5.7)
- Acknowledge RI permutes at firm level, breaking sector structure; note this as limitation
- Discuss cross-sectional correlation within events; note Table 3's event-by-event results as Fama-MacBeth-style evidence
- Address stacked DiD precision: note effective independent observations far fewer than 7,769
- Mention wild cluster bootstrap as direction for future robustness

### F. Add Free Zone Heterogeneity Discussion (LaTeX — Section 7)
- Note that free zone firms were already exempt from some kafala provisions
- Discuss which high-exposure firms operate in free zones
- Acknowledge this as alternative explanation for muted response

### G. Strengthen Literature (LaTeX — Sections 1, 2)
- Add citations: Cameron/Gelbach/Miller (2008) on clustering, Qatar reforms, Emiratisation costs
- Better position within finance event-study inference literature

### H. Prose Improvements (LaTeX)
- Add vivid sector examples in Data section (name specific firms like Emaar vs Emirates NBD)
- Simplify Table 4 narration (less "Column X shows")
- Sharpen conclusion ending

### I. Figure 7 Smoothing (R code change)
- Add 30-day moving average to long-run cumulative returns plot
- Re-run 05_figures.R

---

## What We Will NOT Change
- Core empirical results (no re-running of main analysis)
- Event dates or classification
- Structure of tables (already cleaned in prior rounds)
