# Research Plan: The World's Highest Minimum Wage

## Research Question

What are the effects of the world's highest minimum wage on firm dynamics and employment? Geneva introduced a CHF 23/hr minimum wage in November 2020—the highest anywhere on Earth—while neighboring Vaud had none. We exploit this sharp spatial discontinuity using a triple-difference design to estimate effects on establishment counts, firm entry, firm exit, and employment across sectors with varying minimum-wage bite.

## Identification Strategy

**Primary design: Triple-difference (DDD)**

Y_{cst} = α_cs + γ_ct + δ_st + β(Geneva_c × HighBite_s × Post_t) + ε_{cst}

- **First difference:** Geneva vs. Vaud (canton)
- **Second difference:** Pre vs. Post November 2020 (time)
- **Third difference:** High-bite sectors (hospitality, retail, personal services) vs. Low-bite sectors (finance, pharma, IT)

This design addresses the key identification challenge: COVID-19 hit simultaneously with the minimum wage introduction. The triple-diff isolates the minimum wage effect because COVID affected sectors differently in both cantons, but only Geneva's low-wage sectors faced the additional minimum wage shock.

**Parallel trends assumption:** High-bite and low-bite sectors evolved similarly in Geneva relative to Vaud before November 2020. We test this with event studies spanning 9 pre-treatment years (2011–2019).

**Robustness:**
- Simple DiD (Geneva vs. Vaud, overall)
- Dose-response: continuous treatment using sector-level bite (fraction of workers below CHF 23/hr)
- Leave-one-sector-out to check driver sensitivity
- Cross-border commuters as mechanism channel

## Expected Effects and Mechanisms

**Baseline hypothesis:** Standard competitive model predicts the world's highest minimum wage reduces employment and increases firm exit in high-bite sectors.

**Alternative:** If monopsony power exists in Geneva's low-wage labor market (plausible given high living costs limiting worker mobility), moderate employment effects with wage compression.

**Expected signs:**
- Employment in high-bite sectors: negative or null
- Firm exits in high-bite sectors: positive (if negative employment effects exist)
- Firm entry in high-bite sectors: negative (higher labor cost barrier)
- Cross-border commuters: ambiguous (substitution toward cheaper cross-border labor vs. same minimum wage applies)

## Primary Specification

Triple-difference with canton × sector and canton × year and sector × year fixed effects. Clustering at canton-sector level. Wild cluster bootstrap for inference given small number of cantons.

## Data Sources

All data from BFS (Federal Statistical Office) via PXWeb API — no API keys needed.

1. **STATENT** (Structural Business Statistics): Establishments, employment, FTE by canton × NOGA 2-digit sector × year (2011–2023)
2. **UDEMO** (Business Demography): Firm births and deaths by canton × sector × year (2013–2023)
3. **SEM Cross-border permits**: Cross-border commuters by canton × sector (quarterly CSV)

## Sector Classification

**High-bite sectors** (NOGA 2-digit, where ≥20% workers typically earn below CHF 23/hr):
- 55: Accommodation
- 56: Food and beverage service
- 47: Retail trade
- 96: Other personal service activities
- 81: Services to buildings and landscape

**Low-bite sectors** (benchmark, <5% below CHF 23/hr):
- 64: Financial service activities
- 21: Manufacture of pharmaceuticals
- 62: Computer programming/consultancy
- 69: Legal and accounting activities
- 72: Scientific research and development

## COVID-19 Identification Challenge

The minimum wage (Nov 2020) coincides with COVID's second wave. Our DDD exploits within-canton, within-time variation:
- COVID restrictions were coordinated federally (same lockdowns in GE and VD)
- Differential sectoral COVID effects wash out in the third difference
- By 2022–2023, COVID effects dissipated while minimum wage persisted → clean late-period effects
