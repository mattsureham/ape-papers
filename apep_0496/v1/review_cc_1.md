# Internal Review - Claude Code (Round 1)

## 1. IDENTIFICATION AND EMPIRICAL DESIGN

The boundary discontinuity design is well-motivated but faces significant challenges:
- The running variable (distance to nearest REP vs non-REP school) is a proxy for true catchment boundaries, introducing measurement error
- McCrary density test rejects continuity (T=31.3, p<0.001), indicating sorting at the boundary
- Covariate balance fails for all tested covariates (surface, rooms, apartment share)
- These failures are transparently discussed and appropriately interpreted as reflecting equilibrium sorting rather than invalidating the design

**Key concern:** The RDD assumptions are systematically violated. The paper correctly reframes the analysis as measuring a price gradient rather than a locally randomized treatment effect, but this limits causal interpretation.

## 2. INFERENCE AND STATISTICAL VALIDITY

- Standard errors appropriately clustered at commune level
- Bandwidth sensitivity analysis shows stability across 0.5x-2x optimal bandwidth
- The 57-meter optimal bandwidth is very narrow, raising concerns about external validity
- Year-by-year estimates show consistent pattern with declining trend
- The 200m and 500m donut estimates (0.010, 0.007) being insignificant suggests the gap is highly localized

## 3. ROBUSTNESS AND ALTERNATIVE EXPLANATIONS

**Strengths:**
- Comprehensive bandwidth sensitivity
- Informative donut specifications
- Placebo cutoffs at shifted boundaries
- IDF exclusion revealing geographic heterogeneity
- Private school mechanism analysis

**Weaknesses:**
- Placebo cutoffs at ±250m are significant, suggesting a smooth gradient rather than sharp discontinuity
- The IDF exclusion sign reversal fundamentally changes the interpretation
- No commune-level fixed effects specification (would be informative given département FE already reduces coefficient to 1.3%)

## 4. CONTRIBUTION AND LITERATURE POSITIONING

Well-positioned relative to Black (1999), Gibbons (2013), Fack & Grenet (2010). The distinction between performance signals and government labels is novel and important. Missing potential references:
- Cheshire & Sheppard (2004) on UK school quality capitalization
- Benabou, Kramarz & Prost (2009) on French ZEP policy
- Epple & Romano (1998) on private school sorting models

## 5. RESULTS INTERPRETATION

- The positive RDD coefficient (+5.3%) combined with negative raw correlation (-14.2%) is correctly interpreted as showing geographic sorting dominates
- The private school mechanism finding is compelling but the significant negative coefficient in high-density areas (-2.1%, p<0.001) needs careful interpretation — it's not "no gap" but a reversal
- Cost-benefit calculation appropriately notes that the positive boundary gap implies no stigma tax

## 6. ACTIONABLE REVISION REQUESTS

### Must-fix:
1. Add commune-level fixed effects specification to parametric table
2. Clarify that the positive coefficient means REP-side premium (not discount) consistently throughout

### High-value:
3. Add heterogeneity by property type (apartments vs houses)
4. Discuss what drives the declining trend more carefully
5. Add a formal test comparing the private school interaction coefficients

### Optional:
6. Discuss implications for the 2015 reform evaluation
7. Compare with DVF-based hedonic studies for other policy questions

## 7. OVERALL ASSESSMENT

**Strengths:** Novel question, comprehensive data, transparent about identification limitations, compelling private school mechanism finding.

**Weaknesses:** RDD assumptions violated, very narrow bandwidth, results driven by Paris region, causal interpretation limited.

The paper makes a genuine contribution by documenting the price gradient at REP boundaries and showing it's driven by geographic sorting rather than label stigma. The private school mechanism is the most interesting finding. The paper should strengthen the causal interpretation section and add commune FE.

DECISION: MINOR REVISION
