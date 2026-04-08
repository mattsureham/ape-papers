# V1 Empirics Check — openai/gpt-oss-120b (Variant B)

**Model:** openai/gpt-oss-120b
**Variant:** B
**Date:** 2026-04-08T11:18:16.032309

---

**1. Idea Fidelity**

The paper generally follows the original manifest: it uses IPEDS panel data (2004‑2022) and a Bartik‑style instrument based on the interaction of a state’s initial higher‑education budget share with a national fiscal shock (unemployment). The research question—how state disinvestment translates into tuition changes and the *composition* of the student body (Pell‑grant and minority shares)—is retained.  

However, several elements of the original plan are not fully realized:

| Manifest element | Paper implementation | Comment |
|------------------|----------------------|---------|
| **Full panel (≈70 000 institution‑years)** | Uses a *sub‑sample* of 512 public 4‑year institutions (≈7 000 institution‑years). | The sample is far smaller than the manifest’s “all public 4‑year institutions” and compromises the ability to explore heterogeneity across types and states. |
| **Bartik instrument (initial HE‑budget share × national GDP/unemployment)** | Implements the instrument as initial 2004 HE‑budget share × *national* unemployment change. | The same functional form, but the first‑stage is weak (F < 4), a problem anticipated in the manifest but not mitigated (e.g., using a richer set of shocks or a multi‑period Bartik). |
| **Outcome set (tuition, Pell share, race/ethnicity composition)** | Included tuition, Pell share, and a combined Black‑Hispanic share. | Aligns with the manifest, although the paper does not present separate Black and Hispanic coefficients (the manifest suggested examining both). |
| **Heterogeneity by institution type (research vs. non‑research, HBCU)** | Provides interaction with Carnegie R1/R2 status and a brief HBCU check. | Present, but the HBCU interaction is under‑powered and not discussed in depth. |
| **State‑specific trends** | Added in later specifications (Table 3). | Consistent with the manifest’s “state‑specific trend FE” recommendation. |
| **Robustness / placebo tests** | Limited to reduced‑form and trend specifications; no falsification tests. | Missing a key robustness component recommended in the original idea. |

Overall, the paper stays on the intended research path but sacrifices much of the sample size and fails to deliver a strong first‑stage, which was a central risk highlighted in the manifest. Consequently, the causal claim rests mainly on OLS with fixed effects rather than on the stated IV strategy.

---

**2. Summary**

The paper investigates whether cuts in state appropriations to public universities affect (i) tuition levels and (ii) the socioeconomic and racial composition of the enrollee pool. Using an IPEDS panel of 512 public four‑year colleges (2004‑2022) and a Bartik‑style instrument based on initial state higher‑education budget shares interacted with national unemployment shocks, the author finds weak IV identification but robust OLS evidence that appropriation cuts *increase* the share of Pell‑grant recipients (by about 0.08 percentage points per $1 000 per‑FTE cut) and that tuition passthrough is substantial only at research universities. The key contribution is the identification of a “composition squeeze”: higher‑income students leave when funding declines, leaving a higher proportion of low‑income students behind.

---

**3. Essential Points**

1. **Instrument Weakness and Identification Strategy**  
   - The first‑stage F‑statistic (< 4) is below conventional thresholds, making the IV estimates unreliable and undermining the paper’s primary causal identification claim.  
   - The paper retreats to OLS for the main results but does not provide a convincing argument that fixed effects plus state trends fully purge endogeneity.  

2. **Sample Scope and Generalizability**  
   - Restricting the analysis to 512 institutions (≈7 % of the public 4‑year universe) raises concerns about selection bias, especially given that the excluded institutions are likely those with missing appropriation data (often smaller, less‑resourced colleges).  
   - The heterogeneity analysis (research vs. non‑research) is limited; other institution types (e.g., regional comprehensive, HBCU, land‑grant) are not examined in depth.

3. **Robustness and Validation Gaps**  
   - No falsification/placebo tests (e.g., using pre‑treatment periods, alternative shocks, or outcomes that should be unaffected) are reported.  
   - Sensitivity to alternative specifications of the Bartik instrument (different baseline years, inclusion of state‑level political variables) is absent, leaving the credibility of the identification unclear.

---

**4. Suggestions**

Below are detailed, actionable recommendations intended to strengthen the paper’s contribution, improve credibility, and align it more closely with the original manifest.

| Area | Recommendation & Rationale |
|------|---------------------------|
| **A. Strengthening the Instrument** | 1. **Expand the shift‑share construction**: Instead of a single national unemployment series, incorporate a vector of national shocks (GDP growth, state tax revenue growth, federal aid changes) and interact each with the initial HE‑budget share. Use a generalized Bartik (e.g., multiple shocks) to boost variation.\n2. **Use lagged baseline shares**: The manifest suggested using *2003* budget shares; test robustness to 2000‑2005 windows to capture more variation.\n3. **Implement a “two‑stage least squares with many instruments” (e.g., LIML, Fuller) or a Joint First‑Stage–Reduced‑Form approach** to improve efficiency when instruments are weak.\n4. **Consider a dynamic Bartik** that allows the shock to affect appropriations with a lag (e.g., 1‑year lag) to reduce attenuation from year FE. |
| **B. Recovering a Larger Sample** | 1. **Impute missing appropriation data** where possible using state‑level aggregates or neighboring institutions’ averages; this can substantially increase the number of institutions while preserving variation.\n2. **Run analyses on the full IPEDS public‑four‑year panel (≈70 000 obs.)** as originally planned, at least for the OLS specifications, to demonstrate that findings are not driven by a selective subset.\n3. **Report sample‑selection diagnostics** (e.g., compare means of tuition, Pell share, enrollment between included and excluded schools) to reassure readers that the trimmed sample is representative. |
| **C. Enhancing Causal Claims Beyond OLS** | 1. **Add state‑year specific trends (state‑by‑year FE) or time‑varying controls** (e.g., state unemployment, median household income) to further isolate the funding channel.\n2. **Instrument with a *within‑state* shift‑share**: Use differential exposure across *institutional* characteristics (e.g., proportion of tuition‑dependent revenue) interacted with state fiscal shocks, creating an institution‑level Bartik that may be stronger.\n3. **Employ a difference‑in‑differences‑in‑differences (DiDiD)** design: compare changes in Pell share at research vs. non‑research universities *and* high‑vs‑low exposure states, adding a third dimension (institution type). This can exploit the heterogeneity highlighted in the manifest without relying on a weak instrument. |
| **D. Robustness & Validation** | 1. **Placebo outcomes**: Test whether the Bartik shock predicts outcomes that should not be affected (e.g., enrollment in unrelated majors, campus physical‑plant expenditures). A null effect would bolster credibility.\n2. **Pre‑trend checks**: Plot trends in Pell share and tuition for high‑ vs. low‑exposure states before 2008 to confirm parallel trends.\n3. **Alternative clustering**: Because there are only ~50 state clusters, use wild‑cluster bootstrap or the Cameron‑Miller (2009) correction to ensure inference is not driven by a small‑cluster problem.\n4. **Sensitivity to outliers**: Re‑estimate after winsorizing appropriation per‑FTE at the 1 % and 99 % levels (already done for the variable, but show that coefficients are stable). |
| **E. Extension of Heterogeneity Analyses** | 1. **Separate Black and Hispanic shares**: The manifest envisioned distinct race/ethnicity outcomes; presenting them separately can reveal whether the composition squeeze is driven more by one group.\n2. **HBCU focus**: Given the policy relevance, expand the HBCU interaction (perhaps using a larger HBCU sample or pooling with similar minority‑serving institutions) and discuss any differential passthrough.\n3. **Geographic distance to out‑of‑state markets**: Include an interaction with the proportion of out‑of‑state tuition revenue to test the “out‑of‑state substitution” mechanism.\n4. **Student‑level validation**: If possible, link IPEDS institutional data to the College Scorecard or NCES longitudinal student files to track individual transitions (e.g., low‑income students staying vs. high‑income students leaving). Even a descriptive appendix would strengthen the “exit vs. entry” narrative. |
| **F. Presentation & Transparency** | 1. **Provide a replication package** (Stata/R code, DuckDB queries) and a data‑access checklist, matching AER‑Insights standards.\n2. **Clarify the definition of “state appropriations per FTE”** (e.g., whether it includes only state appropriations or total state fiscal support) and justify any winsorization decisions.\n3. **Re‑label tables** for readability (e.g., separate OLS and IV columns, add column headers indicating the specification). Use consistent decimal places and include significance stars where appropriate.\n4. **Discuss the policy relevance more concretely**: How large is a 0.08 pp increase in Pell share in terms of absolute student numbers? What are the fiscal implications for institutions (e.g., need for more federal aid, changes in tuition discounting)? |
| **G. Theoretical Framing** | 1. **Add a short formal model** (even a two‑period supply‑demand framework) that predicts when low‑income students might *increase* in proportion after a cut, helping readers understand the “composition squeeze” mechanism. \n2. **Link to the broader literature on price elasticity of demand by income group** (e.g., Hoxby & Turner 2013) to position the finding within existing theory. |

**Prioritized Action Plan (what to do first):**

1. **Address instrument weakness** – either by augmenting the Bartik (multiple shocks) or by switching to a more credible quasi‑experimental design (DiDiD).  
2. **Enlarge the sample** – bring back the full public‑four‑year IPEDS panel or at least demonstrate that the trimmed sample is not biased.  
3. **Add robustness/ placebo checks** – pre‑trend graphs, falsification outcomes, and alternative clustering to reassure reviewers that the OLS estimates are not driven by omitted variables.  

By tackling these three pillars, the paper will move from a suggestive but methodologically thin contribution to a robust, policy‑relevant analysis that fulfills the promise of the original idea manifest.
