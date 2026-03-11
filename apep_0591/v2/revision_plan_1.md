# Revision Plan — apep_0591 v2

## Overview
This revision addresses three strategic reviewer reports from v1 that identified cross-country variation as the primary identification concern.

## Key Changes
1. **NUTS3 disaggregation**: Constructed Bartik IV at NUTS3 level using Zenodo bilateral flow data. Go/no-go diagnostic confirms 94% within-country variance (F=60.5 with CxY FE).
2. **Multiple specifications**: NUTS3 long-difference (youth share), NUTS2 panel (tertiary share), NUTS2 long-difference (tertiary share change).
3. **Expanded robustness**: Distributed lags, Rotemberg weights, AKM inference, receiver-side analysis, pre-trend test, leave-one-out stability.
4. **Framing recalibration**: Honest reporting of RI failure (p=0.44-0.49) and CxY FE attenuation. Claims calibrated to "suggestive" rather than "causal."
5. **Cohesion Policy framing**: Explicit analysis of the mobility-cohesion tension, including heterogeneity by peripheral vs core regions.
6. **Complete rewrite**: Abstract, introduction, and conclusion rewritten from scratch. Data section describes LFS-based long-difference (not census).
