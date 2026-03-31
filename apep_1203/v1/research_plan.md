# Research Plan: apep_1203

## Research Question

Did Argentina's de facto ban on SAS (Sociedad por Acciones Simplificada) firm registrations under the Fernández administration (2020–2023) suppress total firm creation, or did entrepreneurs substitute to other firm types (SA, SRL)? And did Milei's April 2024 reactivation reverse the damage?

## Identification Strategy

**Firm-type DiD within province-month cells.** Treatment group: SAS registrations. Control group: SA/SRL/cooperative registrations in the same province-month. The identifying assumption is that absent the regulatory ban, SAS and other firm types would have followed parallel trends within provinces.

Key strengths:
- The shutdown was near-complete (14,000/year → ~34 total in Buenos Aires City) — no dosage ambiguity
- The ban targeted a specific firm type via IGJ Resolution 9/2020, leaving SA/SRL unaffected
- Provincial staggering in reactivation (CABA April 2024, BA Province June 2024) enables Callaway-Sant'Anna

## Expected Effects and Mechanisms

**Primary hypothesis:** The SAS ban reduced total firm creation, not just SAS-labeled creation. Evidence: if SA/SRL didn't rise proportionally during the ban period, the barrier was binding.

**Substitution test:** If SA/SRL registrations increased during the SAS ban (and decreased after reactivation), then the barrier merely relabeled entrepreneurs — challenging the Djankov et al. (2002) hypothesis.

**Mechanism channels:**
1. Extensive margin: new municipalities gaining SAS-forming firms post-reactivation
2. Sector heterogeneity: interacting with DNU 70/2023 product-market deregulation
3. Time-to-recovery: how quickly SAS registrations return to pre-ban trends

## Exposure Alignment

The treatment (IGJ Resolution 9/2020) directly affected CABA's firm registration process. The treated population is would-be entrepreneurs in CABA who would have chosen the SAS form. The outcome (monthly firm registrations by type) directly measures the margin affected by the policy. Treatment and outcome are measured at the same unit (province-month-firm type), avoiding mismatch between exposure and observed response.

## Primary Specification

```
Y_{p,t,type} = β × (SAS_type × Post_ban) + α_{p,t} + γ_{type} + ε_{p,t,type}
```

Where:
- Y = firm registrations count
- p = province, t = year-month, type = firm type (SAS vs others)
- Province×time FE absorb all province-level shocks
- Firm-type FE absorb level differences
- Clustering at province level (25 clusters)

Robustness:
- Callaway-Sant'Anna for staggered reactivation
- Event study with monthly leads/lags
- Permutation inference (25 provinces)
- Substitution test: SA/SRL as outcome when SAS is treated

## Data Source and Fetch Strategy

**Primary source:** Registro Nacional de Sociedades from datos.jus.gob.ar
- CKAN API provides annual ZIP files (2019–2026)
- CSV with: CUIT, firm name, incorporation date, firm type, province, municipality, activity code
- 2024 file: ~57 MB, confirmed HTTP 200

**Fetch plan:**
1. Download ZIP files for 2019–2026 via CKAN API
2. Extract and parse CSVs
3. Aggregate to province-month-firmtype cells
4. Validate against known facts (SAS collapse under Fernández, reactivation April 2024)
