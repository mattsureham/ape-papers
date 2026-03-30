# V1 Empirics Check — qwen/qwen3.5-397b-a17b (Variant C)

**Model:** qwen/qwen3.5-397b-a17b
**Variant:** C
**Date:** 2026-03-30T11:51:37.631059

---

1. **Idea Fidelity**

The paper largely pursues the original idea manifest (idea_0687), utilizing the unique triple-decomposition of worker tenure (total, mine-specific, job-specific) available in MSHA Form 7000-1 data. The core research question—whether establishment-specific tenure provides safety returns—is maintained. However, there are two significant deviations from the proposed identification strategy. First, the manifest explicitly proposed an "Inspection-induced turnover IV" using severe S&S findings to instrument for worker reallocation. The paper abandons this instrumental variable strategy in favor of OLS with fixed effects, relying on within-mine variation in workforce composition. Second, while the manifest indicated linking accidents to "mine-quarter employment" to construct turnover measures, the paper constructs the key mine-level regressor (`NewArrivalShare`) using the share of
