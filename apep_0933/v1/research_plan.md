# Research Plan: Mandatory Biodiversity Net Gain and Housing Development in England

## Research Question

Does mandatory Biodiversity Net Gain (BNG) reduce housing development in England? The Environment Act 2021 requires all developments to deliver a minimum 10% biodiversity net gain, creating an implicit tax on greenfield land conversion. LAs with scarce brownfield land face higher effective compliance costs. We estimate whether this environmental mandate constrains housing supply or merely reallocates it from greenfield to brownfield sites.

## Identification Strategy

**Heterogeneous-intensity Difference-in-Differences.**

- **Treatment:** Mandatory BNG implemented Feb 12, 2024 (major sites: 10+ dwellings) and Apr 2, 2024 (small sites).
- **Intensity:** Cross-LA variation in brownfield land availability. LAs with abundant brownfield sites face lower effective BNG costs (brownfield development often has low baseline biodiversity). LAs reliant on greenfield face higher costs (must create or purchase biodiversity credits).
- **Treatment intensity measure:** Inverse brownfield share — the fraction of an LA's developable land that is NOT brownfield. Higher values = more greenfield-dependent = more exposed to BNG costs.
- **Unit of observation:** Local Authority × quarter.
- **Pre-period:** 2019 Q2 – 2023 Q4 (~20 quarters).
- **Post-period:** 2024 Q1 – 2025 Q3 (~7 quarters).

**Key identifying assumption:** In the absence of BNG, planning application trends would have evolved similarly across high- and low-brownfield LAs (parallel trends in levels or growth rates). Testable with pre-treatment event study.

**Threats and responses:**
1. *Correlated policy changes:* Check for other planning reforms coinciding with BNG implementation.
2. *Compositional shifts:* If BNG shifts applications toward brownfield, we should see divergent brownfield vs. greenfield application trends.
3. *Anticipation:* BNG was legislated in 2021 but only mandatory from Feb 2024. Test for pre-trends starting 2021.

## Expected Effects and Mechanisms

- **Primary hypothesis:** LAs with less brownfield land (higher BNG exposure) experience larger declines in planning applications and approvals after Feb 2024.
- **Mechanism:** BNG compliance costs (on-site habitat creation, off-site credits, or statutory credits at £42,000/unit) are higher for greenfield sites with richer baseline biodiversity. This creates a differential cost burden.
- **Secondary:** Compositional shift toward brownfield applications (substitution effect).
- **Null result interpretation:** If BNG has no differential effect, this suggests either (a) compliance costs are small relative to development value, or (b) developers absorb costs rather than reduce quantity.

## Primary Specification

$$Y_{lt} = \alpha + \beta \cdot (Post_t \times Intensity_l) + \gamma_l + \delta_t + \varepsilon_{lt}$$

Where:
- $Y_{lt}$ = planning applications received/granted in LA $l$, quarter $t$
- $Post_t$ = indicator for quarters after Feb 2024
- $Intensity_l$ = continuous treatment intensity (inverse brownfield share)
- $\gamma_l$ = LA fixed effects
- $\delta_t$ = quarter fixed effects
- Clustering: LA level (311 clusters)

Event study version: interact intensity with quarter dummies for pre-trend validation.

## Data Sources and Fetch Strategy

1. **DLUHC PS2** (planning decisions): Quarterly LA-level data on planning decisions by type. Download CSV from gov.uk/government/statistical-data-sets/planning-applications-statistics.
2. **DLUHC PS1** (planning applications received): Same source.
3. **Brownfield Land Register**: Consolidated national dataset from data.gov.uk. 38,176 sites across 310 LAs.
4. **HM Land Registry PPD**: New-build transactions as secondary outcome. Bulk CSV.
5. **ONS Mid-Year Population Estimates**: For per-capita normalization.

All sources are publicly available CSVs requiring no API keys.
