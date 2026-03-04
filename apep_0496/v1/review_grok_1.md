# Grok-4.1-Fast Review

**Role:** External referee review
**Model:** x-ai/grok-4.1-fast
**Paper:** paper.pdf
**Timestamp:** 2026-03-04T11:10:12.522196
**Route:** OpenRouter + LaTeX
**Review mode:** Tri-model (3 independent reviewers)
**Tokens:** 18868 in / 2594 out
**Response SHA256:** 33cd008ca989cf8e

---

## 1. IDENTIFICATION AND EMPIRICAL DESIGN (CRITICAL)

The core identification relies on a spatial RDD at the equidistance locus (signed distance \(X_i = d(\text{non-REP}) - d(\text{REP})\)) between nearest REP/REP+ and non-REP collèges, proxying for unobserved *carte scolaire* catchment boundaries (Sec. 4, App. A). This approximates a boundary discontinuity under the assumption that catchments roughly follow nearest-school proximity, but the paper transparently notes limitations: true boundaries are address-level and irregular (rivers, highways; Sec. 7), leading to measurement error that attenuates estimates toward zero (conservative bias). Optimal bandwidth is tiny (57m; Sec. 5.1), mitigating proxy error locally.

Key assumptions (continuity of potential prices absent label) are explicitly tested and largely violated: McCrary density rejects sharply (\(T=31.3, p<0.001\); Fig. 3, Sec. 5.2.1), covariates discontinuous (surface \(-1.6\)m², rooms \(-0.03\), apt share +3.3pp, all \(p<0.001\); Tab. 3), as expected from endogenous sorting (Sec. 4.2). Parametric specs (Eq. 5; Tab. 2) progressively add distance polynomials, property controls (surface, apt), year FEs, département FEs, and commune FEs, collapsing the naïve \(-14.2\%\) to 0 (SE=0.008). This identifies a *conditional* REP-side gradient within communes, not a causal label effect, as REP status endogenously reflects neighborhood composition (circular; Sec. 2.2). Treatment stable since 2015 reform (pre-dates 2020-2024 data; Sec. 4), no timing issues/gaps.

Threats well-discussed: sorting (density/covariates), confounders (neighborhood amenities unobserved), proxy error (donuts attenuate; Tab. 5, Panel B). Private school heterogeneity provides quasi-within-boundary variation (Fig. 6). Overall credible for *descriptive gradient* claims (no stigma conditional on sorting), but not LATE for label *per se*—more hedonic gradient (Sec. 3). No manipulation incentives (distance partly chosen), but equilibrium sorting violates continuity.

## 2. INFERENCE AND STATISTICAL VALIDITY (CRITICAL)

Valid inference throughout. Nonparametric: rdrobust (Calonico et al. 2014) with MSE-optimal bandwidth, bias-corrected CIs, triangular kernel, robust to uniform kernel/alternative bandwidths (Fig. 4, Tab. 5 Panel A; all CIs exclude 0). Parametric: OLS via fixest, commune-clustered SEs (appropriate for spatial clustering; Tab. 2), large N=1.12M (1km window) vs. RDD effective N~274k. Samples coherent/reported (Tabs. 1,2; Sec. 4.3). p-values/CIs appropriate (e.g., commune FE insignificant). No TWFE/DiD (not staggered). RDD bandwidth defended via sensitivity/MSE-optimal; no polynomial order issues flagged. Manipulation checks explicit (density, balance; Tabs. 3,5). Pass.

## 3. ROBUSTNESS AND ALTERNATIVE EXPLANATIONS

Extensive and meaningful. Bandwidth/donut/placebo/kernel checks (Figs. 3-5, Tabs. 5, A3); donuts sharply attenuate (0.014 at ±100m, incl. 0), consistent with localized gradient/proxy error. Time dynamics (Fig. 2, Tab. A4): decline 7.7%→2.4% robust. Exclude Île-de-France reverses sign (-2.7%; Sec. 5.2.6). REP+ intensive margin (-3.3%, p=0.07; Sec. 5.2.7). Private mechanism sharp reversal (+2.7% low-density → -2.1% high; Fig. 6), differences out common RDD bias.

Mechanisms distinguished: resource (+, via dédoublement) vs. stigma (-) decomposed theoretically (Eqs. 3-4; Sec. 3), private schools neutralize sorting (not perception). Falsifications appropriate (placebos mixed but interpreted as smooth gradient; Tab. A2). Limitations clear: proxy error, unobserved amenities, no label shocks (Sec. 7). External validity bounded (Paris-driven; provincial reversal).

One gap: no explicit event study around known REP inputs (e.g., 2017 dédoublement rollout), though stable label.

## 4. CONTRIBUTION AND LITERATURE POSITIONING

Clear differentiation: extends school-quality capitalization (Black 1999; Bayer 2007; Gibbons 2013; Fack 2010) from *performance signals* (test scores) to *stigma labels* signaling composition (Intro, Sec. 7.2). National scale (6,429 collèges, 1.7M txns) vs. Fack's Paris-only. Parallels Beffy et al. (2009) null on ZEP outcomes. Private mechanism extends Hoxby (2000), Necyba (2006), Fack (2010) to labels nationally.

Lit coverage sufficient (method: Black→Calonico; policy: Piketty 2006, DEPP 2019). Missing: recent French housing capitalization (e.g., Comandon 2022 QJE on Paris zoning, for spatial sorting context); US stigma parallels (e.g., Figlio & Lucas 2004 on report cards, already cited). Add: Bayer & McMillan (2021 AER P&P) on equilibrium sorting in housing-school models—clarifies why parametric FEs identify conditional gradient.

## 5. RESULTS INTERPRETATION AND CLAIM CALIBRATION

Well-calibrated: abstract/conc. claim "no measurable stigma tax; entirely geographic sorting" matches commune-FE 0 (Tab. 2 Col. 5; SE=0.008 bounds [-1.6%,+1.6%]). RDD +5.3% framed as *upper bound* contaminated by sorting (not overclaimed causal; Sec. 7.1). Magnitudes consistent: naïve -14%→0 monotonic (Tab. 2); private reversal proportional. No contradictions (e.g., Fig. 1 supports +RDD; donuts explain attenuation). Policy proportional: no feedback loop, choice mitigates (Sec. 8). Overclaim flag: "genuine null" (Intro) strong but qualified by uncertainty (SE=0.008); Paris heterogeneity prevents national overgen.

Text matches tabs/figs: e.g., Tab. 2 reports exact progression; Fig. 6 supports mechanism (no substance-table mismatch).

## 6. ACTIONABLE REVISION REQUESTS

1. **Must-fix issues before acceptance**
   - Proxy running variable: Validate equidistance vs. true *carte scolaire* in a subsample (e.g., link to address-level assignments if acquirable via FOIA; Sec. 4.1). *Why*: Core threat; donuts hint at mismeasurement. *Fix*: Tabulate correlation (e.g., % properties where nearest=assigned); sensitivity to alternative proxies (e.g., Voronoi cells).
   - Placebo failures: Significant at ±250m/500m (Tab. A2). *Why*: Undermines sharp discontinuity claim. *Fix*: Plot full gradient (nonpar. over [-2km,+2km]); reframe as *smooth proximity penalty* vs. boundary jump.

2. **High-value improvements**
   - Event study on inputs: RDD around 2017 dédoublement (class-size halving; Sec. 2.4). *Why*: Distinguishes resource vs. stigma channels (Eq. 4). *Fix*: Interact REP_side × post-2019, using pre-trends from Fig. 2.
   - Unobservables: Proxy for amenities (e.g., merge INSEE crime/transport; Sec. 7.3). *Why*: Covariate imbalances may proxy confounders. *Fix*: RDD on these + energy proxies if in DVF.
   - Add citations: Bayer & McMillan (2021 AER P&P); Comandon (2022 QJE). *Why*: Frames equilibrium ID.

3. **Optional polish**
   - Intensive margin: REP vs. REP+ separate RDDs. *Why*: Heterogeneity in disadvantage.
   - Cost-benefit: Bound fiscal costs more precisely (e.g., cite DEPP totals). *Why*: Strengthens policy claim.

## 7. OVERALL ASSESSMENT

**Key strengths**: Massive open data (1.7M geocoded txns; novel DVF use); transparent ID limitations (violations expected/discussed); compelling mechanism (private escape valve, national extension of Fack); robustness depth (donuts, hetero, geo splits); null well-powered (SE=0.008).

**Critical weaknesses**: Proxy running var not validated (attenuation risk); RDD assumptions violated (density/balance), making nonparametric suggestive only—parametric FEs carry weight but identify conditional assoc., not causal label; mixed placebos suggest gradient > discontinuity; no exogenous label variation.

**Publishability after revision**: High potential for AEJ:EP or top-5 (novel policy, scale, mechanism). Salvageable with ID tweaks (proxy validation, event study)—contained major work elevates to causal gradient.

DECISION: MAJOR REVISION