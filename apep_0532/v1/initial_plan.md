# Initial Research Plan — apep_0532

## Research Question

Do extreme weather events affect beliefs about global warming in India? Specifically, does weather-induced agricultural economic exposure drive climate awareness and belief updating?

## Identification Strategy

**Primary: Reduced-form OLS with local weather anomalies.**
- Unit: state × month (Google Trends) or individual × wave (WVS)
- Treatment: Local rainfall and temperature anomalies (deviation from 30-year mean)
- Controls: State FE + month-of-year FE + year FE (Google Trends); state FE + survey-wave FE (WVS)
- Clustering: State level

**Secondary (Mechanism): Bartik interaction test.**
- Interact local weather anomalies with pre-period (2000) state-level share of cultivated area under weather-sensitive crops
- Tests: Does agricultural economic exposure amplify the weather→beliefs channel?
- Interpretation: If coefficient on interaction is positive, the economic exposure channel matters beyond pure experiential salience

**Tertiary (Robustness): Full Bartik IV.**
- Instrument: B_it = Σ_k s_ik × g_kt (crop-share-weighted leave-one-out national weather)
- First stage: Actual local weather ~ f(Bartik)
- Report F-stats, Anderson-Rubin CIs if weak

## Expected Effects and Mechanisms

1. **Attention effect (Google Trends):** Negative rainfall anomalies (droughts) and positive temperature anomalies (heat waves) increase search interest for climate-related terms. Expected magnitude: 5-15% increase in search interest per 1 SD weather anomaly.
2. **Belief effect (WVS):** States exposed to more extreme weather show higher environmental priority. Potentially smaller and slower-moving than attention.
3. **Agricultural amplification:** States with higher crop dependence show stronger effects — economic losses make weather personally salient.
4. **Persistence:** Effects on attention likely decay within 1-3 months (consistent with Egan and Mullin 2012). Effects on beliefs may be more persistent.

## Primary Specification

**Google Trends (main):**
```
Search_it = α + β₁ × WeatherAnomaly_it + β₂ × WeatherAnomaly_it × CropShare_i + γ_i + δ_t + ε_it
```
Where:
- Search_it = Google Trends index for "climate change" in state i, month t
- WeatherAnomaly_it = standardized rainfall/temperature deviation from 30-year mean
- CropShare_i = pre-period (2000) share of land under weather-sensitive crops
- γ_i = state FE, δ_t = month-year FE

**WVS (validation):**
```
Belief_ijw = α + β₁ × WeatherExposure_iw + β₂ × WeatherExposure_iw × CropShare_i + X_j'θ + γ_i + δ_w + ε_ijw
```
Where:
- Belief_ijw = environmental priority for individual j in state i, wave w
- WeatherExposure_iw = cumulative weather anomaly in state i in year preceding wave w
- X_j = individual controls (age, education, income, urban/rural)

## Method Notes: Shift-Share / Bartik Design

Since no pre-built guide exists for shift-share, documenting key requirements:

1. **Identification assumption:** Exogeneity of shares (Goldsmith-Pinkham, Sorkin, Swift 2020 — "share exogeneity") or exogeneity of shifts (Borusyak, Hull, Jaravel 2022 — "shift exogeneity"). Our shares (pre-2000 crop area) are pre-determined and plausibly exogenous. Our shifts (national weather) are also plausibly exogenous.
2. **Required validity checks:**
   - Rotemberg weights to identify influential shares (GPSS 2020)
   - Pre-trend tests on the Bartik instrument
   - Leave-one-out sensitivity (drop each crop in turn)
   - Overidentification test (if J > 1 instruments)
3. **Common pitfalls:**
   - Shares correlated with unobserved heterogeneity (e.g., agricultural states differ in many ways)
   - Shifts correlated across industries/crops (weather affects all crops similarly)
   - Few effective instruments if crops are highly correlated
4. **R packages:** `ShiftShareIV` (GPSS diagnostics), `fixest` for IV, `AER` for ivreg
5. **Key papers:**
   - Goldsmith-Pinkham, Sorkin, Swift (2020, AER)
   - Borusyak, Hull, Jaravel (2022, RES)
   - Adao, Kolesar, Morales (2019) — shift-share inference

## Planned Robustness Checks

1. **Placebo outcomes:** Google Trends for "cricket," "Bollywood," "election," "inflation"
2. **Placebo treatment:** Lead weather anomalies (future weather shouldn't predict current searches)
3. **Alternative weather measures:** Rainfall anomaly, temperature anomaly, drought index, flood events
4. **Alternative Google Trends terms:** Hindi terms, regional language terms
5. **Distributed lag model:** Effects at 1, 3, 6, 12 months for persistence
6. **Internet penetration heterogeneity:** Interact with state internet penetration rates
7. **Bartik diagnostics:** Rotemberg weights, leave-one-out crop sensitivity, effective F-stat
8. **Urban/rural heterogeneity:** WVS analysis by residence type

## Data Sources

| Data | Source | Access | Geographic Level | Temporal Coverage |
|------|--------|--------|------------------|-------------------|
| Google Trends | gtrendsR R package | Free API | State | 2004-2024 monthly |
| WVS | worldvaluessurvey.org | Free download | State | Waves 5-7 (2006, 2012, 2022) |
| Weather | NOAA GHCN or IMD via IMDLIB | Free | Station → state | 1950-2024 |
| Crop area | ICRISAT DLD | Free download | District → state | 1966-2017 |
| Internet penetration | TRAI (Telecom Regulatory Authority of India) | Free reports | State | 2006-2024 |
