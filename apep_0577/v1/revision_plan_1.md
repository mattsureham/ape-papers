# Revision Plan — Round 1

## Summary of Feedback

Three external referees (GPT-5.4 R1: R&R, GPT-5.4 R2: R&R, Gemini: Major Revision) plus exhibit and prose reviews. Key concerns:

### Critical Issues (Must-Fix)
1. **Pre-treatment convergence trends**: Employment event study shows strong monotonic pre-trend (0.68 in 2008 → 0 by 2017). Need formal trend-adjusted specifications, not just narrative defense.
2. **Treatment intensity endogeneity**: 2014-2017 micro-share may be contaminated by earlier REACH phases (2010, 2013). Need pre-REACH baseline.
3. **Inference weakness**: RI p=0.064 vs cluster-robust p=0.014 — must foreground RI, add formal joint pre-trend test.
4. **Mechanism overclaiming**: "Downsizing not exit" and "supply-chain restructuring" too strong for aggregate data.
5. **Control sector validity**: C22-C25 may be indirectly affected through chemical inputs.

### High-Value Improvements
6. Common sample for enterprise/employment comparison
7. Drop 2020 / shorter windows around treatment
8. Literature: Roth (2022), Rambachan & Roth (2023), MacKinnon & Webb
9. Mean of dependent variable in Tables 2 and 3

### Exhibit Changes
10. Move Figure 4 (raw trends), Figure 6 (LOO), Figure 7 (RI) to appendix
11. Convert Figure 1 to single-color scheme
12. Delete roadmap paragraph, sharpen prose

## Execution Plan

### Code Changes

**02_clean_data.R:**
- Add 2008-only micro-share (`micro_share_2008`) as earliest pre-REACH measure

**03_main_analysis.R:**
- Add trend-adjusted DDD: include `chem × micro_share_pre × year_centered` linear trend
- Add specification with 2008 micro-share as treatment intensity
- Add common-sample estimation (intersect enterprise + employment observations)
- Add employment event study CSV export
- Add formal joint F-test of pre-treatment event-study coefficients

**04_robustness.R:**
- Add drop-2020 specification (2008-2019 only)
- Add shorter window (2014-2019) specification

### Paper.tex Changes
- Soften all causal claims ("suggests" / "consistent with" / "associated with")
- Add trend-adjusted specification as Table 2 extension
- Add 2008 micro-share results
- Foreground RI p-values alongside CRSE in main text
- Report joint F-test for pre-treatment coefficients
- Add Roth (2022), Rambachan & Roth (2023), Olden & Møen (2022) citations
- Strengthen control sector justification
- Reframe mechanisms as hypotheses
- Delete roadmap, sharpen transitions
- Move Figures 4, 6, 7 to appendix; renumber
- Add mean dep var to Tables 2 and 3
