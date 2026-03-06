# Internal Review (Round 1)

## PART 1: CRITICAL REVIEW

### 1. Identification and Empirical Design

The paper's core identification relies on within-market variation in competitor counts over an 84-week panel. The two-way fixed effects specification (drug-market + calendar-week FE) is standard and appropriate. The key identifying assumption — that within-market changes in N are uncorrelated with unobserved time-varying price determinants — is discussed and defended through three channels: (1) the event study showing no pre-trends, (2) the 2-4 year ANDA timeline making weekly reverse causality implausible, and (3) the near-zero estimates themselves being inconsistent with entry-attracts-price-declines reverse causality.

**Concern:** The limited within-market variation (median within-market SD of N = 0.4) raises questions about whether the "zero" finding is truly informative or simply reflects insufficient identifying variation. The paper acknowledges this but argues the SEs are tight enough to rule out economically meaningful effects. This argument is sound — the CI at the main estimate excludes effects larger than ±0.001.

**Concern:** The event study is acknowledged as imprecise (huge SEs from high-dimensional FE). This honesty is appreciated, but it weakens the paper's ability to make dynamic claims. The event study is best treated as a corroborating diagnostic, which the current text does.

### 2. Inference and Statistical Validity

Standard errors are clustered at the drug-market level throughout, which is appropriate given the panel structure. All main tables report SEs and sample sizes. The robustness table (Table 4) is complete with SEs and N for all rows. The non-parametric tables include significance stars with standard notation.

**No issues found.**

### 3. Robustness and Alternative Explanations

The paper provides three robustness checks: minimum price outcome, trimmed sample, and cross-section comparison. These are adequate but could be strengthened:

- **Missing:** A log-log within-market specification is reported in Table 2 but not discussed in the robustness section.
- **Missing:** No heterogeneity analysis (e.g., does the null result hold for high-value vs. low-value drugs? For recently-entered vs. established markets?).
- **Missing:** No discussion of measurement error in N. If NDC count is a noisy proxy for effective competition, attenuation bias could explain the zero finding.

### 4. Contribution and Literature Positioning

The contribution is clearly stated and well-differentiated from prior work (Caves 1991, Frank 1997, Reiffen 2002, Grabowski 2007). The "selection gap" framing is novel and visually compelling. The literature section is adequate.

**Missing citations:** Olson and Wendling (2018) on generic drug pricing dynamics; Scott Morton (1999) on entry decisions in pharmaceutical markets; Stigler (1964) on the theory of oligopoly pricing.

### 5. Results Interpretation and Claim Calibration

The paper is appropriately cautious. The "zero" finding is framed as a short-run result with explicit caveats about longer-run effects. The discussion of why the cross-sectional gradient persists despite zero causal effects is well-reasoned.

**Minor concern:** The abstract says "the cross-sectional gradient reflects market sorting, not causation" — the min-price result (-0.0025***) does show a small but significant causal effect. The text should acknowledge this more prominently in the abstract.

### 6. Actionable Revision Requests

**Must-fix:**
1. Add a brief discussion of measurement error / attenuation bias as an alternative explanation for the null within-market result.

**High-value improvements:**
2. Add heterogeneity analysis: estimate the within-market effect separately for high-N vs. low-N markets, or by drug therapeutic class.
3. Add Scott Morton (1999) to the literature review for entry decision modeling.

**Optional:**
4. The 84-week vs. 104-week discrepancy (data covers ~84 of 104 possible weeks in 2023-2024) should be briefly explained in the data section.

### 7. Overall Assessment

**Strengths:** Novel and compelling framing; visually striking "selection gap" figure; precise null result that is informative rather than merely inconclusive; honest treatment of event study limitations; strong institutional background.

**Weaknesses:** Limited within-market variation constrains the design; no heterogeneity analysis; event study is essentially uninformative; short panel limits ability to detect medium/long-run effects.

**Publishability:** This is a solid AEJ: Economic Policy paper with a clear, interesting finding. The "selection gap" concept is novel and policy-relevant. After minor revisions (attenuation bias discussion, heterogeneity analysis), this paper is publication-ready.

DECISION: MINOR REVISION
