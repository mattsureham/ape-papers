# Initial Research Plan: Trade Protection by Fiat

## Research Question
Does Nigeria's sudden 2019 land border closure causally increase food prices in border-proximate markets relative to interior markets, and does the effect spill over to neighboring countries?

## Identification Strategy
**Spatial difference-in-differences.** Treatment intensity is defined by each market's distance to the nearest international land border. The border closure on August 20, 2019 provides a single sharp treatment date — this is a classic 2×2 DiD (pre/post × border/interior), not staggered adoption.

**Treatment assignment:**
- Binary: border markets (<150km from nearest land border) vs. interior markets (>300km)
- Continuous: inverse distance to nearest border crossing (gradient specification)
- Distance bins: 0-100km, 100-200km, 200-300km, 300+km

**Identifying assumption:** Absent the border closure, prices in border and interior markets would have followed parallel trends. Testable with 31 months of pre-treatment data (Jan 2017 – Jul 2019).

**Why the design is credible:**
1. The closure was sudden and unanticipated — no advance announcement
2. It was nationwide (all land borders simultaneously) — no selection into treatment
3. Treatment is geographic, not behavioral — markets can't choose their distance to the border
4. 31-month pre-period for parallel trends validation

## Exposure Alignment (DiD)
- **Who is actually treated?** Markets near land borders that depend on cross-border trade for commodity supply
- **Primary estimand population:** Border-proximate markets (<150km from border)
- **Placebo/control population:** Interior markets (>300km from border) AND non-tradeable commodities (firewood, charcoal)
- **Design:** Standard DiD (single treatment date), not staggered

## Expected Effects and Mechanisms
1. **Price increase for imported staples:** Rice (heavily smuggled from Benin) should show the largest price increase in border markets
2. **Commodity hierarchy:** Imported rice > local cereals (maize, sorghum) > non-tradeables (firewood)
3. **Distance gradient:** Effects should attenuate monotonically with distance from border
4. **Cross-border mirror:** Benin border markets should see price decreases (goods trapped on supply side)
5. **Import substitution:** Domestic-imported rice price gap should narrow

## Primary Specification
$$\log(P_{mct}) = \alpha + \beta \cdot \text{Border}_m \times \text{Post}_t + \gamma_m + \delta_t + \varepsilon_{mct}$$

Where $P_{mct}$ is the price of commodity $c$ in market $m$ at time $t$, $\text{Border}_m$ is an indicator for markets within 150km of the border, $\text{Post}_t$ indicates August 2019 onwards, $\gamma_m$ are market fixed effects, and $\delta_t$ are month fixed effects. Standard errors clustered at the market level.

## Planned Robustness Checks
1. **Parallel trends:** Event study with monthly leads/lags
2. **Rambachan-Roth (2023):** Sensitivity analysis for pre-trend violations (HonestDiD)
3. **Non-tradeable placebo:** Firewood, charcoal — should show zero effect
4. **Distance gradient:** Continuous treatment with distance bins
5. **Alternative windows:** Restrict to 12/18/24 months pre/post
6. **Leave-one-market-out:** Stability to dropping individual markets
7. **Wild cluster bootstrap:** Given modest cluster count (~34 markets)
8. **Randomization inference:** Permute treatment across markets
9. **Cross-border validation:** Benin/Niger prices as mirror-image test

## Power Assessment
- Pre-treatment periods: 31 months (Jan 2017 – Jul 2019)
- Treated clusters: ~22 markets in border zone (<200km)
- Control clusters: ~12 markets in interior (>200km)
- Post-treatment periods: 17 months (Aug 2019 – Dec 2020)
- Total clusters: ~34 markets
- With 34 clusters and a long pre-period, minimum detectable effect ≈ 5-8% price change (well below the expected 15-30% rice price increase reported in news accounts)

## Data Sources
1. **WFP HDX Nigeria:** 56,163 obs, 68 markets, 14 states, 43 commodities (2002-2026)
2. **WFP HDX Benin:** 50 rice markets, cross-border validation
3. **WFP HDX Niger:** Extensive market network, additional cross-border validation
