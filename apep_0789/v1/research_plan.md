# Research Plan: Back Online — Nuclear Restarts and Electricity Prices in Japan

## Research Question

Do nuclear reactor restarts reduce wholesale electricity prices, and is the price benefit asymmetric relative to the shutdown cost documented by Neidell, Uchida & Veronesi (2021, JHE)?

Japan's post-Fukushima nuclear restarts (2015–2024) provide a staggered natural experiment across electricity regions separated by a 50Hz/60Hz frequency barrier that limits cross-regional spillover.

## Identification Strategy

**Staggered Difference-in-Differences** using Callaway & Sant'Anna (2021) estimator.

- **Treatment:** NRA-approved reactor restarts in 5 electricity regions (Kyushu, Kansai, Shikoku, Tohoku, Chugoku), staggered 2015–2024
- **Control:** 4 regions without restarts (Tokyo, Chubu, Hokuriku, Hokkaido) through the study period
- **Key identification feature:** Japan's 50Hz/60Hz frequency split creates a natural barrier (only 1.2GW interconnection capacity) between eastern and western grids, limiting spatial spillovers
- **Unit of analysis:** Region × month (aggregate from half-hourly JEPX spot prices)
- **Clustering:** Region level (with wild cluster bootstrap for 9-cluster inference)

## Expected Effects and Mechanisms

- **Price effect:** Negative — nuclear restarts should reduce marginal generation costs by displacing expensive LNG-fired generation from the merit order
- **Asymmetry hypothesis:** The restart price benefit may be smaller than the shutdown price cost because:
  1. Solar FIT deployment during nuclear hiatus permanently altered the merit order
  2. Fossil fuel contracts signed during shutdown create sticky costs (hysteresis)
  3. Restart costs include post-Fukushima safety compliance investments
- **Mechanism test:** Compare price effects during peak (daytime) vs off-peak (nighttime) hours — nuclear provides baseload, so effects should be larger at night when solar is absent

## Primary Specification

$$Y_{rt} = \alpha_r + \gamma_t + \sum_g \beta_g \cdot \mathbb{1}[G_r = g, t \geq g] + \varepsilon_{rt}$$

Where $Y_{rt}$ is mean monthly spot price in region $r$ at time $t$, estimated via CS ATT with never-treated regions as control.

## Robustness

1. Wild cluster bootstrap p-values (Webb 6-point distribution)
2. Randomization inference (permute treatment across regions)
3. Placebo tests: pre-treatment event study coefficients
4. Alternative aggregation: weekly prices, median prices
5. Peak vs off-peak decomposition as mechanism test
6. Donut specification excluding transition months

## Data Sources

1. **JEPX Spot Prices:** japanesepower.org/jepxSpot.csv — 279K+ half-hourly observations, 10 regions, 2010–2026
2. **Prefectural Emissions:** Figshare DOI 10.6084/m9.figshare.25010720.v4 — 47 prefectures × 16 fiscal years
3. **Restart timeline:** NRA approval dates from public records (14 reactors, 5 regions, 2015–2024)

## Exposure Alignment

**Who is actually affected by treatment:** The treatment (nuclear restart) directly affects the wholesale electricity price formation in the treated region's JEPX area. Every electricity buyer and seller in that JEPX area is exposed — utilities, large industrial consumers, and aggregators — because the spot auction clears at a single area price. The treated units (regions) are well-aligned with the exposure: each JEPX area has its own supply-demand clearing, and nuclear restarts add low-marginal-cost generation to that specific area's merit order. Retail consumers are indirectly affected through regulated retail tariffs that incorporate wholesale procurement costs, though with lags.

**Why the unit of observation matches the treatment:** The JEPX settles prices at the area level, which is also the level at which nuclear capacity is added. No within-region variation in exposure exists for wholesale prices — the entire area faces the same clearing price.

## Risk Assessment

- **Few clusters (9 regions):** Mitigated by wild cluster bootstrap + RI
- **Spillover via interconnectors:** Limited by 50Hz/60Hz barrier (only 1.2GW)
- **Concurrent policies:** Solar FIT changes, LNG price shocks — addressed via time FE + mechanism tests
