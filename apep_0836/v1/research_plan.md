# Research Plan: The Fiscal Cliff After Merger — Grant Expiration and Municipal Service in Japan

## Research Question

When temporary intergovernmental transfers mechanically expire, do municipalities cut spending (flypaper unwinding) or substitute toward own-source revenue? Japan's Heisei-era municipal mergers (1999–2010) came with a 10+5 year Local Allocation Tax (LAT) grace period that inflated post-merger grants to the sum of pre-merger entitlements. As these grace periods expire at staggered dates determined solely by merger timing, they create mechanical fiscal cliffs of known magnitude and timing — ideal for estimating the flypaper effect and its composition.

## Identification Strategy

**Design:** Staggered difference-in-differences exploiting the mechanical timing of LAT grace period expiration.

- **Treatment:** The onset of the 5-year phase-out period (10%, 30%, 50%, 70%, 90% annual reductions in the merger bonus) for each merged municipality, determined by its merger date.
- **Control:** ~1,190 never-merged municipalities that face no such fiscal cliff.
- **Variation:** ~560 merged municipalities with phase-out dates staggered across FY2009–FY2025.
- **Estimator:** Sun & Abraham (2021) interaction-weighted estimator for staggered adoption. Callaway & Sant'Anna (2021) as robustness.
- **Dose-response:** Heterogeneity by pre-merger LAT dependence (share of revenue from LAT grants).

## Expected Effects and Mechanisms

1. **Primary:** Total per-capita expenditure declines as the fiscal cliff bites — the flypaper effect in reverse.
2. **Composition:** Administrative expenditure absorbs disproportionate cuts (merger rationalization gains), while welfare/education spending is more rigid.
3. **Revenue substitution:** Municipalities partially offset lost grants by raising local tax rates or expanding fee revenue.
4. **Dose-response:** High-LAT-dependence municipalities face steeper cliffs and larger spending responses.

## Primary Specification

Y_{it} = α_i + δ_t + Σ_k β_k × 1[K_{it} = k] + X_{it}γ + ε_{it}

Where K_{it} is event time relative to the start of phase-out, α_i are municipality FEs, δ_t are year FEs. Clustered SEs at municipality level.

## Data Sources

1. **RIETI Municipality Converter:** CSV with 3,628 rows mapping pre-merger to post-merger codes, merger dates, merger type (consolidation vs incorporation). URL confirmed accessible.
2. **MIC Survey on Local Public Finance (Chihou Zaisei Jyoukyou Chousa):** Excel files FY2006–FY2023 with total expenditure by category, revenue by source, fiscal indicators for all ~1,744 municipalities.

## Fetch Strategy

1. Download RIETI converter CSV → parse merger dates and types
2. Download MIC fiscal data for FY2006–FY2023 (18 fiscal years) → panel construction
3. Merge on municipality codes, compute event-time indicators
4. Key constructed variables: per-capita expenditure (total, by category), LAT share of revenue, local tax revenue, phase-out indicator

## Key Risks

- MIC data format may vary across years (different Excel layouts)
- Municipality code changes require careful harmonization via RIETI converter
- Need to distinguish consolidation mergers (new entity) from incorporation mergers (absorbed into existing entity)
