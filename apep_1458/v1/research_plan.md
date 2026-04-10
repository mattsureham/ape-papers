# Research Plan: The Monitoring Mirage

## Research Question

Does regulatory monitoring of drinking water deter contamination, or does it primarily increase detection of pre-existing violations? The Safe Drinking Water Act's 33-step population-based coliform monitoring schedule creates discrete jumps in required monthly samples at each population threshold, providing 9 natural experiments to disentangle deterrence from detection.

## Identification Strategy

**Multi-cutoff RDD** (Cattaneo, Keele, Titiunik, Vazquez-Bare 2021). Running variable: population served by each community water system (CWS). Treatment: required coliform samples per month, which increases by 1 at each of 9 population breakpoints between 1,000 and 8,500.

## Data Sources

1. EPA SDWIS Water System table via Envirofacts API
2. EPA SDWIS Violation table via Envirofacts API
3. Population thresholds from 40 CFR § 141.21(a)(2)

## Key Results

- Pooled multi-cutoff RDD: null on coliform violations (τ = -0.011, p = 0.37)
- Null on health-based violations (τ = -0.002, p = 0.94)
- All 5 threshold-specific estimates null
- Robust to bandwidth, polynomial, donut, placebo cutoffs
- Borderline detection effect for private systems (τ = +0.046, p = 0.05)
