# Research Plan: The Landlord Tax Experiment — Mortgage Interest Deductibility and Rental Housing Supply in New Zealand

## Research Question

Does removing mortgage interest deductibility for landlords reduce rental housing supply? New Zealand's 2021 reform provides a unique natural experiment: existing rental properties lost deductibility (phased out Oct 2021–Apr 2024) while new builds retained full deductions for 20 years. The policy then reversed in 2024. This paper estimates the rental supply elasticity to tax incentives using within-market variation between new-build-intensive and existing-stock-intensive territorial authorities.

## Identification Strategy

**Primary design: Continuous-treatment DiD.** Territorial authorities (TAs) with higher pre-reform shares of new-build rental stock were less exposed to the deductibility removal (since new builds were exempt). This creates a dosage instrument: TAs where 30% of rentals are new builds lost deductibility on ~70% of their stock, while TAs where 5% are new builds lost it on ~95%.

- Treatment intensity: (1 − new-build share of rental stock, pre-2021) × phase-out schedule
- Unit: 67 TAs × monthly panels, 2018–2025
- Pre-period: 36 months (Oct 2018–Sep 2021)
- Post-period: ~48 months (Oct 2021–Sep 2025), spanning both removal and restoration

**Event study specification:**
Y_{it} = Σ_k β_k × ExposureShare_i × 1(t = k) + α_i + γ_t + X_{it}δ + ε_{it}

where ExposureShare_i = share of TA i's rental stock that is existing (non-exempt), and Y is active bonds (rental stock proxy), bond lodgements (new tenancy flow), or median weekly rent.

**Triple-difference (robustness):** (high-existing-share TAs vs low) × (post vs pre) × (rental vs owner-occupied market). Owner-occupied housing was unaffected by the reform.

**Treatment-reversal test:** The 2024 restoration of deductibility provides a symmetric natural experiment. If the removal caused rental supply contraction, the restoration should cause recovery. This is the gold standard for ruling out confounders — any time-varying confounder would need to reverse at exactly the same moment.

## Expected Effects and Mechanisms

1. **Rental supply contraction (primary):** Removing deductibility raises the effective cost of holding rental property → landlords sell to owner-occupiers → active bonds decline in high-exposure TAs
2. **Rent increases:** Supply contraction → upward pressure on median rents, especially in TAs where new-build alternatives are scarce
3. **New-build stimulus (secondary):** The exemption creates a relative advantage for new construction → building consents may rise in areas with development capacity
4. **Asymmetric reversal:** The restoration may have faster effects (landlords re-entering is easier than construction) — testing this asymmetry is a contribution

## Primary Specification

```r
# Callaway-Sant'Anna not needed (single treatment timing, continuous exposure)
# Use TWFE with continuous treatment intensity

feols(active_bonds_per_capita ~ i(period, exposure_share, ref = -1) | ta + month,
      data = panel, cluster = ~ta)
```

## Data Sources

1. **MBIE Tenancy Bond Registry** (primary): Monthly active bonds, bond lodgements, closed bonds, median weekly rent by 67 TAs. CSV download from tenancy.govt.nz or API from portal.api.business.govt.nz.

2. **Stats NZ Building Consents** (secondary): Monthly new dwelling consents by TA. Available via Stats NZ Infoshare (free CSV download). Used to construct pre-reform new-build share of rental stock.

3. **Stats NZ Subnational Population Estimates** (denominator): Annual estimated resident population by TA. For per-capita normalization.

## Fetch Strategy

1. First try direct CSV download from tenancy.govt.nz
2. If CSV unavailable, register for free API key at portal.api.business.govt.nz
3. Building consents from Stats NZ Infoshare (CSV download, no key needed)
4. Population from Stats NZ API (no key needed)

## Key Risks

- **Data granularity:** Tenancy bond data may not distinguish new-build from existing stock directly → rely on TA-level building consent shares as proxy for exposure
- **Small country:** 67 TAs, but monthly frequency gives 5,600+ observations
- **Concurrent policies:** RBNZ loan-to-value (LVR) restrictions changed during study period → include as control
- **COVID:** Lockdowns and border closures affected NZ housing market 2020-2021 → pre-period starts 2018 to capture pre-COVID trends; event study will show whether effects align with policy timing vs COVID timing
