# Research Plan: The Secrecy Premium — Beneficial Ownership Transparency and Corporate Formation in Europe

## Research Question

Does public access to beneficial ownership registers deter opaque corporate formation? The EU's Fifth Anti-Money Laundering Directive (AMLD5, 2018) mandated public beneficial ownership registers with staggered member-state compliance (2019–2021). In November 2022, the CJEU struck down the public access requirement, and eight member states immediately rolled back transparency. This paper exploits the adoption–reversal sequence to estimate the causal effect of ownership transparency on new enterprise births and foreign direct investment, using the UK (which maintained its PSC register) as a permanent treatment control.

## Identification Strategy

**Symmetric shock DiD.** Two treatment events provide internal replication:

1. **Transparency ON (staggered, 2019–2021):** AMLD5 required public registers. Member states transposed at different speeds (Netherlands June 2019 → Germany August 2021). Treatment = quarter when national register became publicly accessible.

2. **Transparency OFF (near-simultaneous, Nov 2022–Jan 2023):** CJEU Cases C-37/20 and C-601/20 invalidated the public access provision. Luxembourg, Netherlands, Belgium, Austria suspended within weeks; Germany restricted to "legitimate interest" by January 2023. UK (post-Brexit) unaffected — permanent treatment arm.

**Estimator:** Callaway-Sant'Anna staggered DiD for the adoption phase; standard two-period DiD for the reversal (near-simultaneous treatment). Wild cluster bootstrap for inference with ~28 clusters.

**Key identifying assumption:** Transposition timing driven by domestic legislative calendars and EU infringement proceedings, not by trends in corporate formation. CJEU ruling date is exogenous (initiated by two Luxembourg privacy lawsuits whose timing was unpredictable by member states).

**Exposure alignment:** The treatment (public register access) affects all entities incorporating in a given country. The outcome (quarterly business registration index) captures the universe of new enterprise registrations at the country-quarter level, directly matching the treatment level. Companies forming in a country with a public register are exposed to the disclosure requirement regardless of sector or entity type.

## Expected Effects and Mechanisms

**Hypothesis:** Public registers increase the cost of using opaque corporate structures → new enterprise births decline in high-opacity sectors (holding companies, real estate SPVs) when registers open, and rebound when registers close.

**Mechanism: The "secrecy premium."** Some corporate formations exist primarily because beneficial ownership is hidden. When transparency removes this premium, these entities either (a) don't form, (b) form in non-EU jurisdictions, or (c) restructure to avoid disclosure. The reversal tests permanence: if formations rebound immediately, the deterrence effect is real-time, not structural.

**Heterogeneity predictions:**
- Larger effects in high-Financial Secrecy Index countries
- Larger effects in holding company / financial intermediation sectors
- UK PSC register (always-on) should show no discontinuity at either event

## Primary Specification

```
Y_{ct} = α_c + γ_t + β₁·TransparentRegister_{ct} + X_{ct}·δ + ε_{ct}
```

Where:
- Y_{ct} = log new enterprise births in country c, year t (Eurostat business demography)
- TransparentRegister_{ct} = 1 if country c has a publicly accessible beneficial ownership register in year t
- α_c = country fixed effects
- γ_t = year fixed effects
- X_{ct} = GDP growth, unemployment rate (controls)
- Cluster: country level, wild bootstrap

**Secondary outcomes:**
- FDI inflows (World Bank WDI)
- Composition of UK PSC beneficial owners by nationality (Companies House PSC snapshot)

## Data Sources and Fetch Strategy

1. **Eurostat Business Demography** — Country-level enterprise births/deaths by NACE sector
   - Dataset: `bd_9bd_sz_cl_r2` or `demo_r_dbirth` (country × year, 2008–2023)
   - API: Eurostat REST JSON API, no key required
   - Fallback: `eurostat` R package

2. **World Bank WDI** — FDI net inflows by country
   - Indicator: `BX.KLT.DINV.CD.WD`
   - API: World Bank REST API, no key required
   - Coverage: 2010–2023

3. **AMLD5 Transposition Dates** — From EUR-Lex/CELLAR SPARQL
   - `eurlex` R package: `elx_make_query("directive", include_date_transpos = TRUE)`
   - Cross-referenced with published legal analyses (NautaDutilh, PwC, A&O Shearman)

4. **CJEU Rollback Dates** — Manually coded from press releases and legal publications
   - 8 countries with documented rollback dates (Nov 2022 – Jan 2023)

5. **Financial Secrecy Index** — Tax Justice Network
   - Pre-determined country-level scores for heterogeneity analysis
   - CSV download, no API required

## Robustness and Placebo Tests

- **UK as placebo:** UK maintained its register — should show no discontinuity at CJEU ruling
- **Non-financial sectors placebo:** Manufacturing, agriculture should not respond to ownership transparency
- **Pre-trends:** 5+ pre-reform years (2013–2018) for parallel trends in early vs. late AMLD5 compliers
- **Leave-one-out:** Drop Luxembourg, Netherlands (financial centers) to check if results are driven by outliers
- **Permutation inference:** Randomize treatment assignments across countries

## Timeline

1. Fetch Eurostat + WDI data, construct transposition panel
2. Build country-year panel with treatment indicators
3. Run main DiD (adoption effect), reversal DiD, event study
4. Heterogeneity by FSI score and NACE sector
5. Write paper in AER: Insights format
