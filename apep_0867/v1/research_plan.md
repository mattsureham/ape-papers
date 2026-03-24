# Research Plan: Upload Filters and the Creative Economy

## Research Question
Does the EU Copyright Directive's Article 17 — mandating content recognition ("upload filter") technology on platforms — affect information-sector employment? The staggered transposition across 27 member states (December 2020 to August 2024) provides quasi-random variation in treatment timing.

## Identification Strategy
**Primary:** Callaway & Sant'Anna (2021) staggered DiD with heterogeneous treatment effects.
- Treatment: national transposition of Directive 2019/790 (Article 17 upload filter mandate)
- Treated units: 263 NUTS2 regions across 27 EU member states
- Never-treated controls: Norway, Switzerland, Iceland (EEA members not bound by Copyright Directive)
- Pre-period: 2015-2020 (5-6 years depending on country)
- Post-period: varies by transposition date (2021-2023 in data)

**DDD Extension:** NACE J (Information & Communication, directly affected) vs NACE K (Financial & Insurance, unaffected control sector) within same NUTS2 region.

**Key assumptions:**
1. Parallel trends conditional on region and time FE
2. No anticipation: compliance obligations bind at national transposition
3. No spillovers across countries

## Data Sources
1. **Employment:** Eurostat lfst_r_lfe2en2 (NUTS2 x NACE x year)
2. **Transposition dates:** EUR-Lex NIM via eurlex R package
3. **Controls:** GDP per capita (nama_10r_2gdp), population

## Robustness
- Event study pre-trends
- HonestDiD / Rambachan-Roth
- Leave-one-country-out
- Wild cluster bootstrap
- Placebo sector (NACE K)
