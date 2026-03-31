# V1 Empirics Check — moonshotai/kimi-k2.5 (Variant B)

**Model:** moonshotai/kimi-k2.5
**Variant:** B
**Date:** 2026-03-31T11:48:41.739628

---

**Referee Report: "The Downwind Tax: Coal Pollution Transport and Rural Employment"**

**1. Idea Fidelity**

The paper pursues a modified and attenuated version of the original research design. While it correctly employs the HyADS atmospheric dispersion model to trace coal-attributable PM$_{2.5}$ from individual generating units to recipient counties, it deviates from the manifest in three critical dimensions:

First, and most importantly, the paper abandons the instrumental variables (IV) strategy central to the original proposal. The manifest explicitly proposed using "physics-model-predicted exposure [to] instrument for actual PM$_{2.5}$" to isolate the causal effect of pollution from confounding factors. Instead, the paper uses the HyADS output directly as the treatment variable in reduced-form OLS regressions. This represents a significant weakening of the identification strategy.

Second, the temporal scope is severely truncated. The manifest proposed a 20-year panel (1999–2020); the paper analyzes only 2014–2019 (six years), capturing merely the terminal phase of the coal transition when baseline pollution was already low and labor markets were tightening. This limits both statistical power and external validity.

Third, the paper omits the proposed business dynamism outcomes (establishment births/deaths from Census CBP), focusing exclusively on employment and wages from QCEW. The "productivity costs" and "business dynamism" elements highlighted in the manifest are absent.

**2. Summary**

This paper estimates the relationship between coal-attributable PM$_{2.5}$ and county labor markets using the HyADS atmospheric dispersion model to construct annual county-level exposure measures from 1,381 coal generating units. Analyzing 2014–2019 QCEW data with county and year fixed effects, the author finds that a 10 percent decline in modeled coal PM$_{2.5}$ is associated with a 0.12–0.24 percent increase in county employment (elasticity $-0.012$ to $-0.024$), concentrated in rural areas, with no corresponding effect on wages. The authors interpret this as evidence that coal retirements generated a "hidden dividend" of employment gains in downwind counties through spatial equilibrium adjustments.

**3. Essential Points**

**Abandoned IV Strategy and Threats to Identification.** The original proposal emphasized using the physics model as an instrument for measured PM$_{2.5}$ to address endogeneity and measurement error. By instead regressing employment directly on HyADS-predicted pollution, the current design cannot distinguish between the health/productivity effects of PM$_{2.5}$ and other economic externalities of coal plants (e.g., local demand shocks from plant closures, visual disamenities, or employment multipliers). When a plant retires, HyADS predicts zero pollution exposure, but local employment may fall due to direct job losses at the plant or supply-chain linkages—even in "downwind" counties if they are within commuting zones. The paper attempts to address this by excluding host counties, but general equilibrium effects and regional labor market shocks propagate beyond plant boundaries. Moreover, without instrumenting for measured PM$_{2.5}$, the estimates suffer from classical measurement error attenuation bias in the pollution measure, likely biasing effects toward zero.

**Temporal Truncation and Statistical Power.** The 2014–2019 window captures only the final phase of the coal decline, when coal PM$_{2.5}$ had already fallen 90 percent from 1999 levels (per the paper's own Figure 2). With limited within-county variation during this short period, the design has low power to detect effects. The sensitivity of results to state×year fixed effects (coefficient attenuates by 50% and loses significance, $p=0.16$) suggests that regional confounds dominate the limited residual variation in this short panel. The manifest proposed leveraging two decades of variation driven by scrubber installations, CSAPR implementation, and the shale gas revolution—variation largely excluded here.

**Mechanism and Interpretation.** The paper interprets the null wage effect as consistent with a Rosen-Roback spatial equilibrium where workers relocate in response to amenity changes. However, this interpretation requires that labor supply shifts while labor demand remains constant. Yet coal retirements directly reduce local labor demand (via plant closures), which would put downward pressure on both employment and wages—potentially masking the amenity-driven wage increase the model predicts. The paper cannot empirically distinguish between labor supply (amenity-driven migration) and labor demand (industrial decline) channels without data on migration flows or plant-level employment.

**4. Suggestions**

**Implement the Proposed IV Strategy.** The paper should return to the manifest's proposed 2SLS specification: use HyADS-predicted coal PM$_{2.5}$ to instrument for measured PM$_{2.5}$ (from EPA AQS monitors). This requires merging the HyADS data with monitor-level PM$_{2.5}$ readings to construct a first stage. The exclusion restriction becomes more credible: conditional on county fixed effects and weather controls, the physics-model-predicted transport of coal emissions should affect labor markets only through realized ambient PM$_{2.5}$ concentrations, not through other plant characteristics. Report first-stage F-statistics and test for weak instruments. Alternatively, implement a "shift-share" IV using plant-level emission changes (interacted with HyADS transfer coefficients) as instruments for county-level exposure, following the industrial organization literature.

**Extend the Panel and Add Business Dynamism.** Expand the analysis to the full 1999–2020 period proposed in the manifest. This adds substantial variation from the CAIR (2005) and early CSAPR (2011) implementation periods. Additionally, incorporate the Census CBP data on establishment births and deaths as originally proposed. Business dynamism (entry/exit) is more plausibly linked to pollution-driven amenity changes than aggregate employment, which conflates intensive and extensive margins.

**Address Spatial Correlation and Mechanisms.** Given the atmospheric transport mechanism,
