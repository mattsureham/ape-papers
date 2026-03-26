# Research Plan: From Rice Paddies to Solar Panels

## Research Question
How did Japan's 2012 Feed-in Tariff (FIT) for solar PV affect agricultural land conversion? As the FIT rate declined 75% from 40 Yen/kWh (2012) to ~10 Yen/kWh (2022), did the rate of farmland diversion to solar installations respond proportionally, and which types of agricultural land were most vulnerable?

## Identification Strategy
**Continuous Difference-in-Differences.** Treatment intensity = FIT_rate(t) × PreFIT_upland_share(i), where:
- FIT_rate(t) is the national solar PV tariff in fiscal year t (continuous, declining from 40 to 10)
- PreFIT_upland_share(i) is prefecture i's share of cultivated land classified as upland (hatake) vs. paddy (ta) in 2011

**Why upland share?** Upland (dry field) is easier to convert to solar: no irrigation infrastructure, lower conversion costs, weaker legal protections. Prefectures with high upland shares (e.g., Tokyo 96%, Kagoshima 74%) should respond more to FIT incentives than paddy-dominant prefectures (e.g., Niigata 11%, Akita 19%).

**Key identifying assumption:** Absent the FIT, cultivated land trends would have been parallel across high- and low-upland-share prefectures. Testable with 5 pre-treatment years (2007-2011).

## Expected Effects and Mechanisms
1. **Primary:** Higher FIT rates × higher upland share → faster decline in cultivated land area
2. **Mechanism 1 (conversion):** Upland fields directly converted to solar installations
3. **Mechanism 2 (abandonment):** Rising solar opportunity cost accelerates farm exit
4. **Heterogeneity:** Effect should be stronger in prefectures near major grid connections, with smaller average farm sizes, or with aging farmer populations

## Primary Specification
```
ΔCultivatedLand_it = α_i + δ_t + β(FIT_rate_t × UplandShare_i) + X_it'γ + ε_it
```
- α_i: prefecture FE
- δ_t: year FE
- β: coefficient of interest (expected negative — higher FIT × higher upland share → more land loss)
- X_it: controls (population, agricultural GDP share, solar irradiance)
- Clustering: prefecture level (47 clusters → wild cluster bootstrap)

**Robustness:**
1. Event study: interact UplandShare with year dummies
2. Placebo: paddy land should respond less than upland
3. 2017 FIT amendment as within-regime structural break
4. Leave-one-out: exclude Tokyo (extreme upland share)
5. Randomization inference (47 clusters)

## Data Sources
1. **MAFF Cultivated Land Survey** (e-Stat API): Cultivated land area by type (paddy/upland) × prefecture × year. Annual, 2007-2022.
2. **MAFF Agricultural Land Diversion** (e-Stat API): Area of farmland converted to non-agricultural use × prefecture × year.
3. **FIT Rate Schedule**: Official METI rates by fiscal year (publicly documented).
4. **Controls**: Prefecture population (e-Stat), solar irradiance (JMA), agricultural output (MAFF).

## Exposure Alignment
Treatment is defined as FIT_rate(t) × UplandShare(i), where FIT_rate is a national policy that affects all prefectures simultaneously through the electricity purchase price. The cross-sectional variation in exposure comes from pre-FIT upland shares — prefectures with more upland fields have greater physical and economic exposure to the solar conversion incentive because upland fields face lower regulatory barriers and conversion costs. The treated population is farmland owners in high-upland-share prefectures during years with high FIT rates (2012-2017 especially). Since the FIT rate is national and upland share is a pre-determined geographic feature, there is no selection into treatment at the prefecture level.

## Fetch Strategy
- Primary: Japan e-Stat API (key available in .env)
- Backup: Direct download of MAFF statistical yearbook Excel files
- FIT rates: Hand-coded from official METI schedule (12 values)
