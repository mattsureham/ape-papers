# Research Plan: Where Your Parents Were Sent

## Research Question

Does the quasi-random municipality assignment of refugees in Denmark (1986–1998) causally determine second-generation adult outcomes in education, employment, and crime?

## Why It Matters

The neighborhood effects literature (Chetty & Hendren 2018 QJE; MTO) has established that where children grow up shapes their adult outcomes. But credible identification remains scarce: MTO covered five cities with self-selected volunteers; Chetty-Hendren relied on family movers with potential selection. Denmark's refugee dispersal policy quasi-randomly assigned ~80,000 refugees across the entire country. Their children are now 25–40 years old — the first time these second-generation cohorts are mature enough for comprehensive adult outcome measurement.

## Identification Strategy

**Design:** Cross-sectional reduced-form regression at the municipality level.

**Treatment:** Refugee placement intensity = (Non-Western immigrant stock in 2000 − Non-Western immigrant stock in 1986) / Population in 1986, by municipality.

**Outcomes (municipality-level):**
1. Education: Share of non-Western descendants aged 25–39 with tertiary education (HFUDD11)
2. Employment: Employment rate of non-Western descendants aged 25–39 (RAS200)
3. Crime: Conviction rate of non-Western male descendants aged 30–49 (STRAFNA9)

**Key assumptions:**
- Quasi-random assignment: Conditional on refugee nationality, family size, and age, placement was determined by the Danish Refugee Council's proportional allocation formula, not by municipality characteristics that predict child outcomes.
- SUTVA: No municipality-level spillovers (a strong assumption — we test this via neighbor effects).
- Exclusion: Initial placement affects descendants only through growing up in that municipality (modulo secondary migration).

**Controls:** Pre-dispersal (1985) municipality population, region fixed effects (5 regions), urbanization.

**Pre-trend check:** Using BEF3 1980–1985 data, verify that later-high-placement municipalities did not already have different non-Western immigrant populations or population trends before the dispersal policy began.

**Inference:** Robust standard errors. With ~98 municipalities, wild cluster bootstrap at the region level as robustness.

## Data Sources

All from Statistics Denmark's StatBank API (free, no authentication):
- **BEF3:** Immigrant stocks by municipality, ancestry, year (1980–2006) — treatment construction
- **HFUDD11:** Education by municipality × ancestry × age — education outcome
- **RAS200:** Employment by municipality × ancestry — employment outcome
- **STRAFNA9:** Crime convictions by ancestry × sex × age — crime outcome
- **FOLK1C:** Population by municipality × ancestry — denominators

## Expected Effects

Based on Damm (2009), Damm & Dustmann (2014 AER), and Chetty & Hendren (2018):
- Municipalities with higher initial refugee concentration should show *worse* descendant outcomes if ethnic enclaves reduce integration (Damm & Dustmann 2014 found higher enclave exposure increased adolescent crime).
- Alternatively, ethnic networks provide labor market information and social capital (Damm 2009 found positive employment effects for first-generation refugees in larger co-ethnic networks).
- The direction is an empirical question — and heterogeneity across outcomes (education vs employment vs crime) would itself be informative about mechanisms.

## Primary Specification

Y_m = α + β × RefugeeExposure_m + X_m'γ + ε_m

Where Y_m is the descendant outcome in municipality m, RefugeeExposure_m is the change in non-Western immigrant share 1986–2000, and X_m includes pre-dispersal controls and region fixed effects.

## Robustness

1. Alternative treatment definitions (level vs change, different base years)
2. Placebo test: pre-dispersal outcomes (1980–1985 immigrant trends)
3. Donut: exclude Copenhagen and Aarhus (major cities may have different dynamics)
4. Wild cluster bootstrap inference
5. Alternative outcome definitions (age groups, education levels)
