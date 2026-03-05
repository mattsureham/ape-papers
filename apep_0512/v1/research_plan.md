# Initial Research Plan: Who Bears the Tax Cut?

## Research Question

When a government eliminates a housing tax paid by occupants, how is the tax cut distributed between property owners (via price capitalization), tenants (via lower housing costs), and local governments (via offsetting tax increases on owners)? We study this through France's elimination of the taxe d'habitation for main residences (2018-2023), the largest modern housing tax reform in a major economy (~€26 billion/year).

## Identification Strategy

**Design:** Continuous-treatment Difference-in-Differences

**Treatment intensity:** Pre-reform commune-level taxe d'habitation rate (2017 or average 2014-2017), which determines the per-household tax savings from the reform. Communes with higher pre-reform rates experienced proportionally larger tax reductions.

**Time variation:** The reform began in 2018 (80% of households) and was completed by 2023. Pre-period: 2014-2017. Post-period: 2018-2024/2025.

**Primary specification (Part A — Capitalization):**

log(price/m²)_{i,c,t} = α_c + γ_t + β(TH_rate_c × Post_t) + X'_{i,c,t}δ + ε_{i,c,t}

Where i = transaction, c = commune, t = year. β measures the differential price appreciation in high-TH-rate communes relative to low-TH-rate communes after the reform.

**Secondary specification (Part B — Fiscal Displacement):**

TF_rate_{c,t} = α_c + γ_t + φ(TH_dependence_c × Post_t) + Z'_{c,t}θ + ε_{c,t}

Where TH_dependence_c = pre-reform TH revenue share of total commune revenue. φ measures whether communes more reliant on TH revenue raised their taxe foncière rates more aggressively.

**Part C — Net Incidence:** Combine A and B to compute net capitalization = gross TH capitalization - TF offset.

## Expected Effects and Mechanisms

**Theory (Oates 1969):** A permanent reduction in annual tax T should increase property values by ΔP ≈ T/r, where r is the discount rate. For the median commune (TH rate ~15%, median TH payment ~€600/year), full capitalization at r=3% predicts ΔP ≈ €20,000.

**Expected Part A:** Positive β — communes with higher pre-reform TH rates see differentially larger price increases post-2018. Magnitude: partial capitalization (30-70% of theoretical prediction) given salience, liquidity constraints, and uncertainty about reform permanence.

**Expected Part B:** Positive φ — communes more dependent on TH revenue increase TF rates to offset revenue loss. Magnitude depends on state compensation adequacy.

**Expected Part C:** Net capitalization < gross capitalization if fiscal displacement is significant. The ratio (net/gross) measures what fraction of the tenant tax cut is ultimately borne by property owners.

## Data Sources

1. **DVF (Demandes de Valeurs Foncières):** All property transactions in metropolitan France 2014-2025. Bulk download from cadastre.data.gouv.fr (2014-2019) and data.gouv.fr (2020-2025). Variables: price, date, commune code, property type, surface area, number of rooms.

2. **REI (Recensement des Éléments d'Imposition):** Commune-level tax rates and revenue from data.economie.gouv.fr. Variables: TH rate, TF rate, total tax revenue, by commune and year.

3. **INSEE commune characteristics:** Population, median income, urbanization category from INSEE BDM/SDMX. For controls and heterogeneity analysis.

## Exposure Alignment (DiD)

- **Who is treated:** All main-residence property occupants (owners and tenants) in France
- **Treatment intensity:** Pre-reform commune TH rate determines per-household tax savings
- **Primary estimand population:** Property buyers/sellers (observed in DVF)
- **Placebo/control populations:** (1) Secondary residences (kept the TH tax), (2) Commercial/industrial properties (unaffected), (3) Communes with very low pre-reform TH rates (minimal treatment)
- **Design:** Continuous-treatment DiD (not staggered — treatment timing is national, variation is cross-sectional in intensity)

## Power Assessment

- **Pre-treatment periods:** 4 (2014-2017)
- **Post-treatment periods:** 7-8 (2018-2025)
- **Treated clusters:** ~35,000 communes (continuous treatment intensity)
- **Observations:** ~2-3 million transactions per year × 11 years ≈ 25+ million
- **Standard errors:** Clustered at commune level
- **MDE:** With 25M+ observations across 35K communes, power is not a concern. Standard errors on the interaction coefficient should be very small.

## Planned Robustness Checks

1. **Event-study specification:** Year-by-year coefficients β_t for 2014-2025 to test pre-trends and trace dynamic capitalization
2. **Anticipation test:** Is there a jump in 2017 (Macron campaign) before the 2018 implementation?
3. **Secondary residence placebo:** Repeat Part A for communes with high vs low secondary-residence shares
4. **Commercial property placebo:** Estimate same specification for commercial transactions
5. **Phase-in exploitation:** Use the two-wave structure (80% in 2018, 20% in 2021) by interacting with commune income composition
6. **Bandwidth sensitivity:** Vary the definition of "high" vs "low" TH rate communes
7. **Compensation formula robustness:** In Part B, instrument fiscal stress with the predicted shortfall from the statutory compensation formula
8. **COVID controls:** Include department × year FEs or restrict sample to pre-COVID (2014-2019) for Part A sensitivity
9. **Border-pair design:** Compare adjacent communes with different TH rates for tighter spatial controls
10. **Honesty diagnostics:** Rambachan-Roth sensitivity for pre-trend violations

## Paper Structure

1. Introduction (hook: €26B tax cut, who benefits?)
2. Institutional Background (TH system, reform timeline, compensation mechanism)
3. Data (DVF, REI, commune characteristics)
4. Research Design
5. Part A: Tax Capitalization into Property Prices
6. Part B: Fiscal Displacement onto Property Owners
7. Part C: Net Incidence and Welfare
8. Robustness and Placebo Tests
9. Conclusion
