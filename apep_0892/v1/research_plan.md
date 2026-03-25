# Research Plan: Weaponized Trade and Local Economic Costs

## Research Question
Does Russia's September 2013 wine embargo on Moldova impose measurable subnational economic costs on wine-dependent raions, and do these costs persist or dissipate as producers adjust?

## Identification Strategy
**Bartik shift-share design:**
- **Shift:** Russia's September 2013 wine embargo (binary timing shock)
- **Share:** Pre-embargo vineyard area per capita by raion (from 2011 General Agricultural Census)
- Continuous treatment intensity: raions with higher pre-embargo wine dependence experience larger exposure to the trade shock

**Specification:**
```
Y_rt = α_r + γ_t + β(VineyardShare_r × Post_t) + ε_rt
```

Where Y_rt is mean nighttime light radiance in raion r at month t, with raion FE and year-month FE.

**Key threats and diagnostics:**
1. Pre-trends: 20 months (Jan 2012 – Aug 2013) to verify parallel trends in nightlights between high and low wine-share raions
2. EU Association Agreement (signed June 2014) confounds post-2014 — use Sept 2013–May 2014 window as "pure embargo" period
3. 2006 prior embargo may have already adjusted high-wine raions — this strengthens null interpretation but weakens finding

## Expected Effects and Mechanisms
- **Direct:** Wine-dependent raions lose export revenue → reduced economic activity (nightlights decline)
- **Adjustment:** Producers may redirect exports to EU (Association Agreement) → recovery in medium run
- **Spillovers:** Downstream effects on processing, transport, services in wine regions
- **Expected sign:** Negative β (wine-dependent raions lose relative nightlight intensity post-embargo)
- **Magnitude:** Effect likely moderate given wine is ~25% of Moldova's exports and Russia was ~30% of wine market

## Primary Specification
- Panel: 37 raions × 150 months (Jan 2012 – May 2024)
- Treatment: Continuous (vineyard hectares per capita from 2011 census)
- Outcome: Mean VIIRS nighttime light radiance (nW/cm²/sr)
- FE: Raion + year-month
- Clustering: Raion level (37 clusters)
- Inference: Wild cluster bootstrap (Cameron, Gelbach, Miller 2008) given 37 clusters
- Robustness: Randomization inference, leave-one-out, placebo treatment dates

## Data Sources and Fetch Strategy
1. **EOAtlas VIIRS Nightlights** (AWS S3): Monthly mean radiance for all 37 Moldovan admin2 units, Jan 2012 – May 2024. Fetch via HTTPS from EOAtlas S3 bucket.
2. **UN Comtrade API**: Moldova wine exports (HS 2204) to Russia, annual 2010–2023, for aggregate trade collapse documentation.
3. **Moldova 2011 Agricultural Census**: Vineyard area by raion. Published as PDF/tables — construct manually from reported statistics.
4. **GADM**: Moldova admin2 boundaries for mapping.
