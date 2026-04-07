# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant A)

**Model:** moonshotai/kimi-k2.5
**Variant:** A
**Date:** 2026-04-07T20:47:57.823402

---

**Referee Report**

**Manuscript:** The Renovation Trap: Denmark's Anti-Speculation Reform and the Investment Cost of Closing Rent Arbitrage  
**Authors:** APEP Autonomous Research et al.

---

### 1. Idea Fidelity

The paper pursues the core research question identified in the manifest—evaluating whether Denmark's 2020 renovation-cap reform deterred housing investment—but deviates significantly from the proposed empirical strategy and data sources. Three discrepancies are critical:

1. **Outcome Variable:** The manifest proposed analyzing §5 stk. 2 renovation permits (from the DHBA registry), rental property transactions (EJ131), and rent levels (BOL). The executed paper relies almost exclusively on building permits (BYGV11), which capture new construction rather than the renovation-to-relet arbitrage the reform targets. The authors acknowledge this limitation but do not adequately justify why building permits are a valid proxy for the extensive margin of renovation arbitrage activity.

2. **Empirical Method:** The manifest specified Callaway-Sant’Anna (CS-DiD) given potential heterogeneity in treatment timing, though it noted simplification to canonical DiD was possible. The paper uses standard TWFE OLS without discussing why CS-DiD was abandoned or whether heterogeneous treatment effects across the 80 treated municipalities bias the aggregated estimate.

3. **Data Scope:** The manifest emphasized property transaction data (EJ131) to identify mid-size rental buildings (10–50 units) as the specific mechanism. The paper does not use transaction data or analyze building-size heterogeneity, missing the opportunity to test whether the reform specifically deterred investment in the typical renovation-arbitrage target segment versus general construction.

---

### 2. Summary

This paper evaluates Denmark’s 2020 “Blackstone-Indgreb,” which capped post-renovation rents in 80 municipalities while allowing 18 peripheral municipalities to opt out. Using a difference-in-differences design on quarterly building permit data (2015–2025), the authors find a 26% decline in residential permits in treated municipalities, emerging with a two-year lag attributed to pipeline clearing. The authors interpret this as evidence of a "renovation trap" where closing rent-arbitrage loopholes imposes moderate but real supply costs.

---

### 3. Essential Points

The authors must address the following three issues. Failure to adequately resolve (1) or (2) would warrant rejection; issue (3) requires significant additional robustness.

**1. The Outcome Variable Does Not Match the Research Question or Mechanism**
The paper’s central claim—that closing renovation arbitrage deters investment—relies on building permits as the outcome. However, the reform explicitly targets *renovation* of existing regulated stock (§5 stk. 2), not new construction. Building permits (BYGV11) primarily capture new residential construction (detached houses, new apartment blocks), while renovation-to-relet arbitrage involves retrofitting existing buildings, often without triggering "new construction" permits. The 26% decline in new construction permits is surprisingly large for a reform targeting existing stock renovations and likely conflates the policy effect with macroeconomic shocks (see point 2). 

*Required revision:* If direct §5 stk. 2 permit data from the Danish Rent Tribunal are truly inaccessible, the authors must: (a) demonstrate that building permits are a valid proxy for renovation arbitrage activity (e.g., by showing pre-reform correlation between §5 approvals and building permits at the municipal level), and (b) analyze EJ131 property transaction data as originally proposed to identify effects on mid-size rental buildings (10–50 units)—the specific asset class targeted by Blackstone-style arbitrage.

**2. Severe Threats to Identification from Confounding Macro Shocks**
The post-treatment window (July 2020–2025) encompasses three major confounders: (1) COVID-19 supply disruptions, (2) the 2021–2022 global construction cost inflation, and (3) rapid European interest rate hikes beginning in Q2 2022. The "two-year lag" finding (effect emerging 2022Q3) coincides exactly with the ECB rate tightening cycle and Denmark’s housing market cooling. Urban treated municipalities (Copenhagen, Aarhus) are far more exposed to interest-rate sensitive institutional investment than rural control municipalities (Fanø, Læsø). Quarter fixed effects absorb common shocks but not differential exposure to monetary tightening or construction cost inflation across urban/rural markets.

*Required revision:* Include controls for municipal exposure to interest rate shocks (e.g., interaction of post-2022 period with pre-reform share of institutional investors) or construction cost indices. Furthermore, with only 18 control municipalities (many islands), a synthetic control approach is mandatory to credibly weight the comparison group; the current TWFE design with 80 vs. 18 units and massive baseline level differences strains the parallel trends assumption despite the 2015–2020 window appearing balanced.

**3. The Control Group Size and Composition Threatens Inference**
With only 18 clusters in the control group, cluster-robust standard errors (Bertrand et al. 2004) are likely too small (Cameron & Miller 2015). The effective degrees of freedom for inference approximate 17 (clusters - 1), implying the t-statistics reported are inflated. Moreover, the control municipalities are predominantly islands with thin rental markets; the identification assumes these would have followed the same trend as Copenhagen absent the reform, which is tenuous given differential urbanization pressures.

*Required revision:* Implement wild cluster bootstrap inference (Cameron et al. 2008) given the small number of control clusters. Alternatively, collapse to an aggregate time-series comparison (treated vs. synthetic control) to avoid the small-cluster problem entirely.

---

### 4. Suggestions

**Mechanism Heterogeneity and Dosage**
The paper notes that large cities (Copenhagen, Aarhus) show larger effects (58% decline) than other treated municipalities. This is consistent with the arbitrage mechanism but warrants further exploration. Can the authors obtain data on the *intensity* of pre-reform §5 stk. 2 usage at the municipal level? A dose-response specification (treatment intensity = pre-reform §5 approvals per 1000 dwellings) would strengthen the causal interpretation and distinguish the reform effect from general urban investment cycles.

**Placebo Tests with Owner-Occupied Construction**
The paper uses dwelling stock data as a placebo, but these are annual and miss the crucial 2021–2022 period. A stronger placebo would use permits for owner-occupied detached houses within BYGV11. If the reform specifically targeted rental renovation arbitrage, owner-occupied permits should show no effect (or a smaller effect). This would help isolate the mechanism from general construction cost/interest rate confounders affecting all residential investment.

**Pipeline Interpretation vs. Anticipation**
The two-year lag is interpreted as pipeline clearing, but the legislative process (L 47 introduced late 2019) suggests anticipation effects should have accelerated 2020H1 permits. The paper should test for pre-treatment bunching in 2020Q1–Q2. If permits declined *before* the reform (anticipation), the post-2022 drop might reflect mean reversion rather than policy effects.

**Alternative Control Group Construction**
Given the structural differences between treated (urban) and control (island/peripheral) municipalities, consider constructing a synthetic control using weighted combinations of untreated municipalities, or matching on pre-trends in rental market thickness (proportion of pre-1992 stock, pre-reform transaction volume). The current design assumes Fanø and Copenhagen share a common trend absent the reform, which requires stronger justification than provided.

**Welfare Clarification**
The back-of-envelope calculation compares tenant savings (DKK 67m/year) to foregone "quality improvements" (DKK 21bn). This comparison is misleading because the DKK 21bn represents gross asset value, not welfare. The welfare cost depends on whether the foregone construction was socially valuable or merely rent-seeking. The authors should clarify that without data on actual quality depreciation versus cosmetic upgrades, the welfare conclusion remains ambiguous.
