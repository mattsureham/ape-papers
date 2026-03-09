# Reply to Reviewers

## Reviewer 1 (GPT-5.4 R1) — Reject and Resubmit

### 1. "Unusually clean" and "gold standard" language overstates the design
> The Introduction describes the setting as "an unusually clean setting for causal inference."

**Response:** Agreed. We have replaced this with "a promising — though ultimately imperfect — setting for causal inference." All references to permutation inference as the "gold standard" have been removed. We now characterize permutation as "an informative diagnostic" and note explicitly that "neither inferential procedure is unambiguously valid in this quasi-experimental setting."

### 2. The treated unit is effectively one jurisdiction
> The relevant treatment assignment is not "22 independently treated clusters," but one treated polity.

**Response:** This is a valid concern. The paper already acknowledges the few-cluster problem extensively (Section 5.5), and the conclusion now explicitly states that the design "does not automatically provide a credible counterfactual when the policy affects an entire devolved jurisdiction." We agree this is the fundamental limitation.

### 3. Parallel trends are not credible in the baseline
> Event-study pretrends are jointly rejected, the estimate flips with trends, border controls eliminate the effect.

**Response:** We agree entirely. This is, in fact, the paper's central message. The paper does not claim a causal effect — it uses these failures diagnostically to argue against causal interpretation. The contribution is the systematic documentation of how this apparently compelling natural experiment fails.

### 4. Border design underdeveloped
> The border-county restriction is the most persuasive robustness check but is not developed into a primary design.

**Response:** We have strengthened the border-county discussion. The reviewer's suggestions for border-pair matching, distance-to-border designs, and synthetic control are excellent directions for future work, which we now note in the Discussion.

### 5. Outcome is indirect proxy for landlord exit
> Total transactions are too indirect for the headline claim about landlord exit.

**Response:** The paper's title asks about "housing market response," not landlord exit specifically. The conceptual framework (Section 3) explicitly models three channels through which the reform could affect transactions. We have further clarified that Category A is not a clean owner-occupier measure.

### 6. Policy bundling
> The treatment is a bundle, not "abolition of no-fault evictions" narrowly construed.

**Response:** Section 8.2 discusses this at length, and the second-home exclusion (now correctly listing all 5 excluded LAs) addresses one of the key bundles. We agree this is an important limitation and have not changed our cautious interpretation.

### 7. Permutation test validity
> Exchangeability is not credible for this quasi-experiment.

**Response:** We now include an extended discussion in Section 7.3 explaining exactly why the permutation and bootstrap tests diverge, noting that the permutation test's exchangeability assumption is debatable and that neither procedure is unambiguously correct.

---

## Reviewer 2 (GPT-5.4 R2) — Major Revision

### 1. Main identification strategy not credible
**Response:** We agree. This is the paper's thesis, not a bug.

### 2. "Gold standard" language
**Response:** Removed throughout. See reply to R1 above.

### 3. Wild bootstrap vs permutation conflict not resolved
**Response:** We have added an extended paragraph in Section 7.3 explaining the different null hypotheses and distributional assumptions of each procedure, and why they diverge in this setting.

### 4. Price result is compositional
**Response:** We have added explicit language noting that mean transaction price is sensitive to compositional changes and "should be interpreted as reflecting compositional selection rather than market-wide appreciation." The abstract now says "mean transaction prices" rather than just "prices."

### 5. Category B proxy is noisy
**Response:** We acknowledge this limitation in the data section and DDD table notes. Category B includes second homes and repossessions, not just landlord activity. We note that validation against Census tenure shares or Rent Smart Wales data would strengthen the analysis.

### 6. Border design should be primary
**Response:** We have strengthened the border-county analysis discussion but maintain the current structure where the national DiD is presented first and then systematically dismantled. This narrative arc (finding → debunking) is the paper's contribution.

### 7. Additional literature suggestions
**Response:** The reviewer suggests citing Abadie et al. (2010, 2021) on synthetic control, Arkhangelsky et al. (2021) on synthetic DiD, and Athey & Imbens (2022). These are excellent references for the methodological discussion and directions for future work.

---

## Reviewer 3 (Gemini) — Minor Revision

### 1. Wild Bootstrap vs Permutation discrepancy
**Response:** Extended discussion added in Section 7.3. See above.

### 2. Pre-treatment trend visualization
**Response:** The event study figure already shows pre-period volatility. The pre-trends diagnostics table (Appendix B) reports the mean pre-treatment coefficient and formal test.

### 3. Rent data
**Response:** This is an excellent suggestion for future work. ONS rental data at the LA level could complement the transaction-based analysis but was beyond the scope of this paper's focus on the extensive margin.

---

## Exhibit Review Responses

- **Table 2:** Reviewer suggested adding SDs for all continuous variables. The table already reports SD for transaction counts. Adding SDs for prices and shares across 4 rows would make the table unwieldy; the key balance information is already visible.
- **Figure 3 (Cat B event study):** Reviewer suggested moving to appendix. We retain it in the main text as it directly supports the placebo argument.
- **Figure 6 (Leave-one-out):** Reviewer suggested moving to appendix. We retain it as it provides visual evidence of robustness that complements the statistical tables.
- **Table 9 (Pre-trends):** Reviewer suggested promoting to main text. We agree this is important but it is already discussed in the main text with a reference to the appendix table.

## Prose Review Responses

- **Opening hook:** Revised to lead with the specific policy date rather than a generic "policy debates" framing.
- **"Gold standard" and overstatement:** Corrected throughout per referee feedback.
- **Log points vs percentages:** All percentage claims now use exact conversion (1 - e^β) rather than approximating log points as percentages.
