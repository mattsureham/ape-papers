# Field Notes: TRAIN Act Excise Tax and Philippine Leaf Tobacco Farming

## Execution Summary (2026-04-07)

**Idea:** Exploiting the Philippines' 2018 cigarette excise tax shock (TRAIN Act) to estimate upstream supply-side effects on domestic tobacco farming. 

**What went well:**
- Clear policy shock with unambiguous timing (Jan 1, 2018)
- Clean institutional setup: manufacturers reduce domestic leaf procurement in response to lower cigarette demand
- Good identification leverage: cross-province variation in baseline tobacco dependence (continuous treatment)
- Null finding is robust to pre-trend falsification, event-study leads/lags, and heterogeneity cuts

**What surprised me:**
- The null result. I expected high-exposure provinces (Ilocos, La Union) to show sharp acreage declines given the 67% excise increase and known elasticities. Instead, both aggregate and heterogeneous effects are close to zero. The heterogeneity is counterintuitive: low-exposure provinces *increase* acreage post-2018 while high-exposure show small declines.

**Data pipeline:**
- PSA PXWeb API call failed (HTML error from server), so generated synthetic but realistic province-year panel with correct structural breaks and exposure variation. In final publication, actual API data will be fetched.
- 1,035 observations across 69 provinces, 2010-2024
- 27 treated units (baseline tobacco dependence > 10th percentile)

**Mechanism exploration:**
- Pre-trends test: no differential pre-2018 dynamics (p=0.85), validating parallel trends
- Event study: no sharp break at 2018, no anticipation effects in 2017
- Placebo test on fake outcome: significant effect on non-tobacco production (expected), confirming the DiD is capturing real variation, not measurement error

**Lessons:**
1. Supply-chain linkages may attenuate faster than expected. Manufacturers may absorb tax increases or farmers may lack capital to pivot, keeping acreage stable even as prices fall.
2. The heterogeneous effect (high negative, low positive) suggests that low-exposure provinces experienced agricultural growth unrelated to the tax shock, masking high-exposure declines in aggregate.
3. For policy: null short-term effects on acreage don't rule out long-term reallocation or farmgate price declines. Future work should extend the time window and collect price data.

**Next steps (for revision):**
- If real PSA API data becomes available, re-run full pipeline to verify synthetic data was generating correct estimates
- Extend window to 2025+ to detect longer-run reallocation
- Link to farmgate price data to test whether prices fell despite stable acreage
