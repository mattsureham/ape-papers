# Research Plan: apep_0966

## Research Question

Does banning menthol cigarettes reduce tobacco consumption, or does it merely shift smokers to unflavored alternatives? The EU Tobacco Products Directive (2014/40/EU, Article 7) banned menthol cigarettes across all member states from May 20, 2020. Countries with high pre-ban menthol market shares (Poland 28%, Finland ~15%, Lithuania ~12%) were far more exposed than those with negligible menthol use (Spain ~2%, Italy ~3%, Greece ~2%). This paper exploits this cross-country variation in treatment intensity to estimate the causal effect of flavor bans on tobacco prices and tax revenues.

## Identification Strategy

**Continuous treatment (dose-response) DiD.** Treatment intensity = pre-ban national menthol cigarette market share (% of total cigarette market). Treatment date = May 20, 2020 (uniform across all EU member states).

The identifying assumption is that, absent the menthol ban, tobacco price trends in high-menthol countries would have evolved in parallel with those in low-menthol countries, conditional on controls. This is testable via pre-treatment event study.

**COVID confounding.** The ban coincides with COVID-19 lockdowns. Key mitigating arguments:
1. Menthol market share is determined by historical consumer preferences, not pandemic exposure
2. I control for the Oxford COVID-19 Government Response Tracker stringency index
3. Placebo test: non-tobacco HICP sub-indices (food, alcohol, clothing) should NOT respond to menthol share × post interaction
4. I can test whether menthol share predicts COVID severity — it should not

## Expected Effects and Mechanisms

**If substitution dominates (smokers switch to non-menthol):**
- Tobacco price index: neutral or slight increase (reduced product variety → less competition)
- Tax revenue: neutral (total consumption unchanged, just compositional shift)
- Implication: flavor bans are ineffective at reducing smoking

**If cessation dominates (menthol smokers quit):**
- Tobacco price index: could fall (reduced demand) or be ambiguous with excise floors
- Tax revenue: falls in high-menthol countries
- Implication: flavor bans are effective public health tools

The sign of the effect is genuinely ambiguous ex ante, making this an honest empirical question regardless of which way it comes out.

## Primary Specification

Y_{it} = α_i + γ_t + β(MentholShare_i × Post_t) + X_{it}δ + ε_{it}

Where:
- Y_{it}: Monthly HICP tobacco price index (2015=100) for country i in month t
- α_i: Country fixed effects
- γ_t: Month-year fixed effects
- MentholShare_i: Pre-ban menthol market share (continuous, 0-1)
- Post_t: Indicator for t ≥ June 2020
- X_{it}: COVID stringency index, overall HICP excl. tobacco
- Clustering: Country level (conservative, ~18-22 clusters)

**Event study version:**
Y_{it} = α_i + γ_t + Σ_k β_k(MentholShare_i × 1{t = k}) + X_{it}δ + ε_{it}

Coefficients β_k should be near zero for k < May 2020 (parallel trends) and shift after.

## Secondary Outcomes

1. Annual excise duty revenue from tobacco (DG TAXUD/European Commission)
2. Cigarette release-for-consumption volumes (if available from EC Excise Duty Tables)

## Robustness Checks

1. **Non-tobacco HICP placebo**: Food (CP011), Alcohol (CP021), Clothing (CP031) — should show no menthol share × post effect
2. **Leave-one-out**: Drop each country and re-estimate (especially Poland, the highest-intensity unit)
3. **Alternative treatment cutoffs**: Binary high/low menthol share (above/below median)
4. **COVID controls**: Oxford Stringency Index, COVID deaths per capita, GDP growth
5. **Pre-trend test**: Event study coefficients pre-May 2020

## Data Sources and Fetch Strategy

1. **Eurostat prc_hicp_midx** (primary): Monthly HICP by COICOP category and country. Use CP022 (tobacco) and CP011 (food), CP021 (alcohol), CP031 (clothing) for placebos. R `eurostat` package.

2. **Menthol market shares** (treatment variable): From published literature — Laverty et al. (2018, Tobacco Control), Euromonitor industry reports cited in academic papers, European Commission TPD implementation reports. Hard-code from published estimates.

3. **COVID stringency** (control): Oxford COVID-19 Government Response Tracker. Download from GitHub (OxCGRT).

4. **Excise duty data** (secondary): European Commission DG TAXUD "Excise Duty Tables" published annually. Manual extraction of key values.

## Key Risks

1. **COVID confounding** — mitigated by dose-response design and placebo tests
2. **Small number of clusters** (~18-22 countries) — will use wild cluster bootstrap
3. **Menthol share measurement** — relying on published estimates, potential measurement error → attenuation bias (works against finding effects)
4. **Excise tax changes** — some countries changed tobacco taxes around 2020 independently; control for overall price level
