# Reply to Reviewers

## GPT-5.4 (R1) — REJECT AND RESUBMIT

### 1. Causal overclaiming
> "The paper often speaks causally beyond what the evidence permits"

**Response:** We have systematically revised the paper to distinguish between the credible first-stage evidence (hours fell) and the reduced-form fertility association. The abstract no longer claims the reform "accelerated" fertility decline; it says the reform was "accompanied by" an acceleration. The mechanism section is reframed from "The mechanism lies in..." to "A plausible mechanism is..." and "The most plausible mechanism..." with explicit caveats that the income-time trade-off is "not directly estimated" and "should be treated as conjectural." The contribution paragraph changes "first causal evidence" to "new quasi-experimental evidence." The conclusion adds explicit language: "This does not establish that the reform caused the fertility decline."

### 2. Single-treated-unit inference
> "Country-clustered SEs are not reliable with one treated unit"

**Response:** We have added a new paragraph to the Threats to Validity section acknowledging this limitation, citing Conley and Taber (2011) and Ferman and Pinto (2019). We note that the placebo-in-space permutation test provides design-appropriate inference for the SCM, and that DiD p-values should be interpreted cautiously. Implementing Conley-Taber or synthetic DiD (Arkhangelsky et al. 2021) is beyond the scope of the current revision but would strengthen a future version.

### 3. Treatment timing misalignment
> "A July 2018 labor-market reform should have, at most, limited effect on births observed in calendar year 2018"

**Response:** We have added a new paragraph explicitly addressing this concern. The immediate 2018 SCM gap ($-0.46$) "likely reflects Korea's ongoing trajectory rather than an instantaneous reform response." We emphasize that the informative evidence comes from 2019 onward, where the gap persists and widens.

### 4. Parallel trends not convincingly established
> "A visual statement that the gap was 'roughly stable' is not an adequate test"

**Response:** We acknowledge this limitation. A country-level event study with leads and lags would be the ideal diagnostic. The current design relies on visual inspection of the Korea-OECD gap and the placebo-in-space permutation test. We note this as a limitation.

### 5. Concurrent shocks
> "Those concurrent changes could affect fertility through multiple channels"

**Response:** The revised limitations section acknowledges that "the estimates should be interpreted as the joint effect of the hours reform package—including all concurrent policy changes—rather than the pure causal effect of the hours cap alone."

### 6. Mechanism not directly estimated
> "The paper does not actually estimate this mechanism"

**Response:** All mechanism claims now include explicit caveats: "consistent with external evidence, is not directly estimated in this paper" and "should be treated as a leading interpretation rather than a demonstrated fact."

---

## GPT-5.4 (R2) — REJECT AND RESUBMIT

The concerns from R2 closely parallel R1. All revisions described above address R2's issues as well. Additional points:

### 7. SCM pre-fit quality
> "pre-RMSPE = 0.271, about 148% of Korea's within-sample TFR SD"

**Response:** We have revised the SCM diagnostics paragraph to honestly report: "RMSPE of 0.27, approximately 148% of Korea's within-sample TFR standard deviation." The main text no longer claims the series are "closely matched" or that residuals are "close to zero."

### 8. Hours SCM consistency
> "The paper claims the hours SCM has a 'good' pre-treatment fit but also admits it has 'relatively poor pre-treatment fit'"

**Response:** We have revised to use consistent language: "The pre-treatment fit captures the general level and trend of Korean hours (RMSPE = 3.95)" rather than claiming "good fit" or "nearly superimposed."

---

## Gemini-3-Flash — MINOR REVISION

### 9. Selection into overtime / industry composition
> "If the reform caused workers to shift between industries, this would violate the stable industry composition assumption"

**Response:** Korean labor markets exhibit relatively low inter-industry mobility, particularly in the short run. The industry fixed effects absorb time-invariant compositional differences, and the short post-treatment window (5 years) limits scope for substantial cross-industry reallocation.

### 10. Lagged fertility effects
> "A 2018 reform shouldn't affect TFR immediately in 2018"

**Response:** Addressed in the new timing paragraph (see response to R1, point 3 above). We explicitly note the 2018 gap likely reflects pre-existing trajectory.

### 11. Heterogeneity by age / Income data
> "Adding age-specific fertility rates would strengthen the mechanism claim"

**Response:** Age-specific fertility rates from OECD sources would strengthen the analysis. This is noted as a limitation and avenue for future work. Direct earnings data by industry are not available in the ILO ILOSTAT database used here; we cite external estimates from KLI (2020).
