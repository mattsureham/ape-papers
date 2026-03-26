# Research Plan: apep_1013

## Research Question

How did Egypt's July 2014 energy subsidy reform — which raised industrial energy prices by 25–80% overnight — affect manufacturing output and employment across sectors with different energy intensities?

## Identification Strategy

**Design:** Difference-in-Differences with continuous treatment intensity.

- **Treatment:** Pre-reform sector-level energy intensity (energy cost share of value added), measured from UNIDO INDSTAT data in the pre-reform period (2010-2013 average).
- **Post-period:** 2014 onwards (main reform July 2014, subsequent tranches 2015-2017).
- **Variation:** Energy cost shares range from 30-50% in cement/steel/ceramics to 2-5% in textiles/food processing. This cross-sector variation is the identifying lever.
- **Key assumption:** Absent the reform, high- and low-energy-intensity sectors would have followed parallel trends. Testable with pre-2014 data.

## Expected Effects and Mechanisms

1. Energy-intensive sectors face a cost shock equivalent to a selective tax → output declines
2. Employment in energy-intensive sectors falls (labor demand shift)
3. Trade composition shifts: exports from energy-intensive products decline relative to non-energy-intensive ones
4. Mechanism: firm exit and within-firm contraction, not substitution toward capital (energy and capital are complements in heavy industry)

## Primary Specification

$$Y_{st} = \alpha + \beta \cdot (EnergyIntensity_s \times Post_t) + \gamma_s + \delta_t + \epsilon_{st}$$

Where $s$ indexes ISIC manufacturing sectors, $t$ indexes years, $EnergyIntensity_s$ is the pre-reform energy cost share, and $Post_t = \mathbb{1}[t \geq 2014]$.

Clustered standard errors at the sector level. Robustness: wild cluster bootstrap given ~23 sectors at ISIC 2-digit.

## Data Sources

1. **UNIDO INDSTAT2** (primary): Annual manufacturing data at ISIC Rev.3/Rev.4 2-digit level for Egypt. Variables: employment, wages, value added, output, number of establishments. Years: 2005-2022.
2. **UN Comtrade** (secondary/robustness): Product-level (HS 6-digit) export data for Egypt, mapped to ISIC sectors. Provides product-level variation (N~5000) as robustness for the sector-level results.
3. **World Bank WDI**: Macro controls (GDP, exchange rate, FDI) for Egypt.
4. **Energy intensity measures**: Constructed from UNIDO data (energy cost / value added) or from published IEA/World Bank tables.

## Exposure Alignment

The treatment (energy subsidy removal) operates at the sector level: all firms within a given ISIC manufacturing sector face the same energy price increase proportional to their sector's pre-reform energy cost share. The outcome (exports) is measured at the same sector level. Treatment and outcome units are therefore aligned. Energy-intensive sectors (cement, steel, ceramics, chemicals, petroleum refining) receive the largest "dose" because their production costs are most sensitive to energy price changes. Low-energy sectors (textiles, apparel, food processing) serve as the comparison group with minimal exposure to the reform. The identifying variation is continuous — energy intensity ranges from 0.02 to 0.55 across sectors — not a binary high/low split.

## Fetch Strategy

1. Try UNIDO STAT API (`stat.unido.org`) for INDSTAT data
2. Try UN Comtrade Plus API for HS 6-digit exports
3. World Bank API for macro indicators
4. If UNIDO API is restricted, use World Bank WDI manufacturing indicators + ILO ILOSTAT employment by sector as fallback
