# Internal Review — Round 1

## 1. Research Question and Contribution

The paper asks whether France's 2023 vacancy tax (TLV) expansion affects property transaction volumes and prices. The central contribution is a negative finding: the standard DiD fails due to endogenous zone designation, and the paper honestly documents this failure with comprehensive diagnostics. This is a genuine contribution — most papers would cherry-pick the specification where pre-trends look acceptable.

**Strengths:** Novel policy, universe transaction data, honest engagement with identification failure.
**Weaknesses:** The paper is fundamentally a well-executed negative finding, which limits its publishability.

## 2. Identification Strategy

The DiD comparing newly-treated vs never-treated communes is well-motivated but fatally compromised by pre-trend violations (F=12.1, p<1e-15). The paper correctly diagnoses this as endogenous zone selection rather than a data error. The DDD (newly vs always treated) also fails due to differential exposure to monetary tightening.

The HonestDiD sensitivity analysis is well-implemented and appropriate.

## 3. Data

DVF universe data is excellent — 5.5M transactions, full coverage. The balanced panel construction (660K obs) is appropriate. The data description should clarify that 2025 data appears in figures but not in estimation.

## 4. Results

- Main DiD: -3.4% volume, +2.5% price — but invalidated by pre-trends
- Placebo: always-treated shows -14.6% — devastating for the design
- Heterogeneity: tourist zones +3.3% price vs tense zones -1.9% — interesting
- RI p=0.000 — correctly interpreted as selection, not causation
- CS estimator: confirms TWFE results

## 5. Tables and Figures

Tables are clear and well-formatted. The robustness table now correctly labels interaction terms. Composition effects table added. Event study figure is standard and clear.

## 6. Writing

The paper is well-written with clear prose. The introduction hooks effectively. The honest framing ("But these estimates are wrong") is compelling.

## 7. Overall Assessment

**Key strengths:** Honest engagement with identification failure, comprehensive diagnostics, policy relevance.
**Critical weaknesses:** No credible causal estimate survives the diagnostics; the paper is ultimately descriptive.
**Publishability:** Could be published as a cautionary tale for place-based tax evaluation, with revisions.

DECISION: MINOR REVISION
