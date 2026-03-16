# Research Plan: Taxing Away the Shadow — Sweden's RUT Household Services Deduction and Formal Employment

## Research Question
Did Sweden's 2007 RUT tax deduction (50% subsidy for household services from registered firms) cause a shift from informal to formal employment in the domestic services sector? Or did the subsidy primarily create new demand rather than formalizing existing shadow work?

## Policy Background
Sweden introduced the RUT-avdrag (Rengöring, Underhåll, Tvätt) on July 1, 2007 (Lag 2007:346). The deduction covers 50% of labor costs for household services (cleaning, gardening, childcare, elderly care) purchased from tax-registered firms. Maximum SEK 50,000/person/year. By design, only formally registered firms qualify — creating a price wedge between formal and informal services.

The Swedish National Audit Office (Riksrevisionen, RiR 2020:2) explicitly concluded that researchers cannot establish a causal link between the RUT subsidy and formalization. This paper provides the first causal evidence.

## Identification Strategy
**Continuous-treatment difference-in-differences** across 290 Swedish municipalities.

- **Treatment intensity (D_m):** Pre-reform (2006) share of population in top income quintile in municipality m. High-income municipalities have greater demand for household services and greater capacity to claim the RUT deduction (requires sufficient tax liability).

- **Model:** Y_mt = α_m + δ_t + Σ_τ β_τ × D_m × 1(t = τ) + ε_mt

- **Identifying assumption:** Absent the RUT reform, outcomes in high- and low-income-share municipalities would have evolved along parallel trends. Testable with 7+ pre-treatment years (1999-2006) for income outcomes.

- **Inference:** Cluster-robust SEs at the municipality level (290 clusters — well above the few-cluster threshold).

## Expected Effects and Mechanisms
1. **Formalization channel:** Workers previously paid cash-in-hand now employed formally → service-sector employment rises disproportionately in high-demand municipalities
2. **Creation channel:** Lower effective price of formal services → new demand → new jobs that did not exist informally
3. **Immigration channel:** Formalization concentrated among foreign-born workers (who disproportionately work in cleaning/domestic services)
4. **Gender channel:** Female employment in service sectors rises (domestic services are female-dominated)

## Primary Specification
- **Outcome 1 (income DiD):** Log mean declared income by municipality, 1999-2024
- **Outcome 2 (employment mechanism):** Employment in NACE M+N sector (professional/administrative services, includes household services) by municipality, 2008-2018
- **Outcome 3 (placebo):** Employment in NACE B+C (manufacturing) — should show no differential response to RUT

## Data Sources

### SCB PxWeb API (Statistics Sweden)
All data from the SCB open-access API (https://api.scb.se/OV0104/v1/doris/en/ssd/). No API key required.

1. **Income statistics:** SamForvInk1 table — mean/median earned income by municipality, 1999-2024
2. **Employment by sector:** RAMS table NattSNI07KonK — employment by municipality × NACE sector × sex, 2008-2018
3. **Population/demographics:** Municipality-level population for normalization

### Treatment coding
- Reform date: July 1, 2007
- Treatment intensity: continuous (pre-2006 top-quintile income share)
- All 290 municipalities treated (universal reform) — identification comes from intensity variation

## Analysis Plan
1. Construct treatment intensity variable from 2006 income distribution
2. Dose-response event study: plot β_τ coefficients (parallel trends test)
3. Main DiD table: aggregate pre/post effects
4. Mechanism tests: sector decomposition (M+N vs manufacturing), gender, immigration
5. Fiscal cost-effectiveness: SEK subsidy spent per additional formal job
6. Robustness: alternative treatment intensity measures, dropping Stockholm, permutation tests
