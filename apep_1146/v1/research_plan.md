# Research Plan: Batching the Land Market

## Research Question

Does switching from continuous to batched residential land auctions affect housing price dispersion and volatility? China's February 2021 "double concentration" (两集中) reform forced 22 major cities to batch all residential land auctions into 3 annual rounds, while 48 other cities in the NBS 70-city panel continued continuous auctions. This creates a clean DiD to estimate how auction frequency affects within-city housing price variation.

## Identification Strategy

**Design:** Difference-in-differences comparing 22 treated cities (mandated batched auctions) vs 48 control cities (continued continuous auctions) around the February 2021 reform.

**Why it's credible:**
- Top-down administrative mandate: the 22 cities were designated by the Ministry of Natural Resources based on tier status (4 first-tier + 18 prominent second-tier), not based on pre-existing housing market conditions
- Clean treatment timing: all 22 cities switched simultaneously in February 2021
- Large treated sample (22 units) with rich control group (48 units)
- 24 months of pre-treatment data (Jan 2019 – Dec 2020) for parallel trends testing

**Threats:**
- COVID recovery differential across city tiers (address with city-tier × time FE)
- Other concurrent housing policies (Three Red Lines for developers, Sept 2020) — affects both treated and control cities
- NBS price indices may be smoothed/manipulated — use multiple outcome measures

## Expected Effects and Mechanisms

**Mechanism:** Batching creates "lumpy information arrival." Under continuous auctions, land prices provide a steady stream of signals about housing demand. Under batched auctions, signals arrive 3x/year in concentrated bursts. Theory (Grossman-Stiglitz 1980) predicts:

1. **Short-run volatility increase:** Concentrated information → larger price adjustments around auction dates
2. **Cross-segment dispersion change:** With fewer auctions, developers bid on broader portfolios → price convergence across size segments
3. **Developer concentration:** Batched auctions favor larger developers with more capital → market concentration increases

## Primary Specification

$$Y_{ct} = \alpha + \beta \cdot \text{Treated}_c \times \text{Post}_t + \gamma_c + \delta_t + \epsilon_{ct}$$

Where:
- $Y_{ct}$: housing price dispersion (CV across 3 size categories) or month-to-month volatility in city $c$, month $t$
- Treated: indicator for 22 designated cities
- Post: indicator for March 2021 onward
- $\gamma_c$: city FE; $\delta_t$: month FE
- Cluster SEs at city level (22+48=70 clusters — use wild cluster bootstrap given moderate cluster count)

**Event study:** Callaway-Sant'Anna not needed (single treatment timing), but estimate standard event study for visual pre-trends check.

**Robustness:**
- Wild cluster bootstrap p-values
- Synthetic control matching
- Placebo treatment dates (12, 18 months earlier)
- Drop first-tier cities (Beijing, Shanghai, Guangzhou, Shenzhen) to test sensitivity
- City-tier × time FE to absorb differential trends across tiers

## Data Source and Fetch Strategy

### Primary: NBS 70-City Housing Price Indices
- Source: National Bureau of Statistics of China (stats.gov.cn)
- Coverage: 70 cities, monthly, by property size (under 90m², 90-144m², above 144m²)
- Variables: MoM index, YoY index for newly constructed residential housing
- Period: January 2019 – December 2023 (24 pre + 34 post)
- Fetch method: AKShare Python library (`ak.macro_china_new_house_price()` or similar)

### Secondary: Developer Financial Data
- Source: AKShare for listed A-share developer stock returns
- Variables: Monthly stock returns for ~70 listed developers
- Use for developer concentration / market structure analysis

### Fetch plan:
1. Use Python with AKShare to download NBS 70-city price data
2. Save as CSV for R analysis
3. Construct treatment indicator (22 treated cities)
4. Construct outcomes: within-city CV across size segments, MoM volatility
