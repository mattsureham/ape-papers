# Research Plan: The Dissolution Tax — IR35 Off-Payroll Reforms and the Death of the Personal Service Company

## Research Question

Did the UK's IR35 off-payroll reforms — which shifted tax status determination from contractors to their clients — cause the dissolution of tens of thousands of personal service companies (PSCs)? And if so, what happened to the workers inside them?

## Institutional Background

The IR35 legislation (formally the Intermediaries Legislation) targets workers who supply services through an intermediary (typically a limited company — the PSC) but who would otherwise be employees. Originally (2000), the contractor determined their own tax status. Two reforms shifted this determination to the hiring organization:

1. **April 2017:** Public sector clients must determine tax status of contractors
2. **April 2021:** Private sector medium/large clients must do the same (delayed from April 2020 due to COVID-19)

The key insight: the reform doesn't change the tax rules per se — it changes who bears the compliance risk. When the contractor self-assessed, many classified themselves as outside IR35 (self-employed). When the client must make the determination, risk-averse HR departments default to "inside IR35" (employee-like), eliminating the tax advantage of the PSC structure.

## Identification Strategy

**Sector × Time Difference-in-Differences** exploiting:

1. **Cross-sector variation:** Sectors with high PSC prevalence (IT consulting SIC 62, management consulting SIC 70, architecture/engineering SIC 71, employment agencies SIC 78) vs. sectors with low PSC prevalence (retail SIC 47, food service SIC 56, manufacturing SIC 10-33)

2. **Two temporal shocks:**
   - April 2017: Public sector reform → moderate effect on PSC-heavy sectors
   - April 2021: Private sector reform → large effect on PSC-heavy sectors

3. **Built-in placebo:** COVID delay (April 2020 → April 2021) — if the reform drives dissolution, the effect should appear in 2021, not 2020

4. **Unit of analysis:** Local Authority × SIC sector × year (405 LAs × sectors × 10 years)

**Estimand:** ATT of IR35 reform on the number of registered companies, by sector, relative to control sectors

## Primary Specification

Callaway-Sant'Anna staggered DiD with sector-level treatment timing:
- Treated group 1 (2017): Sectors heavily supplying public sector clients
- Treated group 2 (2021): Same sectors, now fully treated via private sector extension
- Never-treated: Sectors with minimal contractor presence

Event study specification for visualization: leads/lags relative to each reform date.

## Data Sources

1. **NOMIS NM_142_1 (UK Business Counts):** 405 LAs × SIC 2-digit × legal_status (company/sole proprietor/partnership) × employment_sizeband × year (2015-2024). This is the primary outcome variable.

2. **NOMIS NM_189_1 (Business Births and Deaths):** LA × SIC × year. Decomposes net change into births vs deaths.

3. **NOMIS labor market data:** Employment by sector for mechanism analysis (did workers shift from self-employment to payroll employment?)

## Expected Effects

- **Main effect:** Decline in company counts in PSC-heavy sectors (SIC 62, 70, 71, 78) post-2017 and especially post-2021, relative to control sectors
- **Mechanism:** Increase in sole proprietorships OR decline in total business units (workers absorbed into payroll employment)
- **Heterogeneity:** Larger effects in LAs with higher baseline PSC concentrations
- **COVID placebo:** No effect in 2020 (reform delayed)

## Key Risks

1. COVID-19 independently affected business counts (addressed via sector controls — COVID hit retail/food service harder than IT)
2. Secular trends in gig economy may confound (addressed via control sectors, pre-trend tests)
3. NOMIS data is annual (March snapshot) — cannot isolate monthly dynamics

## Literature Context

- Freedman and Looney (2023) on contractor classification in the US (AB5)
- Naritomi (2019) on third-party reporting and tax compliance
- Kleven et al. (2011) on tax enforcement and evasion
- HMRC IR35 evaluations (2023-2024) — descriptive only, no causal design
