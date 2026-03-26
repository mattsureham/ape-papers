# Research Plan: The Soybean Unlock — Differential Export Tax Liberalization and Crop Reallocation in Argentina

## Research Question
Did Argentina's December 2015 differential elimination of export taxes — removing them entirely for wheat, corn, and sunflower while only reducing soybean taxes by 5pp — cause significant reallocation of planted area away from soybeans toward the newly liberalized crops? What does this reveal about the role of trade policy distortions in driving agricultural monoculture?

## Identification Strategy
**Triple-difference (crop × department × campaign):**
- Treatment crops: wheat (23%→0%), corn (20%→0%), sunflower (32%→0%)
- Control crop: soybeans (35%→30%)
- Unit: department-crop-campaign
- Fixed effects: department×crop, crop×campaign, department×campaign

The DDD absorbs:
- Department-level shocks (weather, infrastructure) via department×campaign FE
- Crop-level macro shocks (world prices, devaluation) via crop×campaign FE
- Time-invariant department-crop advantages via department×crop FE

**Key confound mitigation:** The simultaneous peso devaluation (~45%) and ROE permit elimination affect all crops equally in the DDD framework. The identifying assumption is that absent the differential tax change, the *relative* area shares of treated vs. control crops within departments would have followed parallel trends.

## Expected Effects and Mechanisms
1. **Area reallocation:** Treated crops gain planted area relative to soybeans (primary outcome)
2. **Magnitude ordering:** Corn (largest tax cut, 20pp) > Sunflower (32pp, but smaller market) ≈ Wheat (23pp)
3. **Production response:** Area effects translate to production changes (second outcome)
4. **Yield neutrality:** If reallocation occurs on marginal land, yields may fall slightly for treated crops (mechanism test)
5. **Heterogeneity:** Stronger effects in departments with higher initial soybean concentration (more room to reallocate)

## Primary Specification
```
Y_{dct} = β × Treated_c × Post_t + α_{dc} + γ_{ct} + δ_{dt} + ε_{dct}
```
Where d = department, c = crop, t = campaign. Y is log(planted_area). Cluster SEs at department level.

## Data Source and Fetch Strategy
- **MAGyP Estimaciones Agrícolas:** CSV from datos.magyp.gob.ar/reportes/. 160,499 rows, 508 departments, 41 crops, campaigns 1969/70–2024/25.
- **URL:** Direct CSV download confirmed in idea smoke test.
- **Sample window:** 2010/11–2019/20 campaigns (5 pre, 4 post treatment; excludes COVID disruption in 2020/21).
- **Focal crops:** Soja (soybeans), Trigo (wheat), Maíz (corn), Girasol (sunflower).
