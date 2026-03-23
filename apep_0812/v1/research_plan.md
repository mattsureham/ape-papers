# Research Plan: Pump Prices and Le Pen

## Research Question
Did France's carbon tax escalation (TICPE composante carbone, 2014–2018) cause differential gains in National Rally (RN) vote share in car-dependent communes?

## Identification Strategy
**Continuous-treatment first-difference design.** Treatment intensity = commune-level car-commuting share (INSEE MobPro 2013, pre-treatment). The TICPE carbon component is a national tax, so the only cross-commune variation in exposure comes from differential car dependency. Communes where 90% of workers drive to work bear a much larger real fuel-cost shock than communes where 20% drive.

- **Estimand**: β in ΔRN_{c,t} = α + β × CarCommute_c + γ'X_c + ε_c
- **Pre-trend test**: Run the same regression for 2007→2012 (pre-carbon-tax period). β should be zero.
- **Main result**: 2012→2017 (3 years of escalation) and 2012→2022 (full escalation + gilets jaunes)
- **Inference**: Conley spatial HAC SEs (50km cutoff), department-clustered SEs

## Expected Effects and Mechanisms
- **Hypothesis**: Higher car-commuting communes experienced larger effective fuel tax increases, generating economic grievance channeled into populist voting.
- **Expected sign**: Positive β — more car-dependent communes shift more toward RN.
- **Magnitude prior**: Douenne & Fabre (2022 AEJ:Policy) find ~5pp higher opposition in high-car-exposure quintile. We expect 2–5pp at commune level given dose-response.
- **Mechanism channel**: Economic grievance (fuel costs), not cultural backlash. Test via heterogeneity by income.

## Primary Specification
ΔRN_share_{c, 2017-2012} = α + β₁ × CarShare_c + β₂ × log(pop_c) + β₃ × MedianIncome_c + β₄ × UnemployRate_c + β₅ × ShareHighEduc_c + département_FE + ε_c

## Data Sources
1. **Election results** (data.gouv.fr): Commune-level 1st round presidential results, 2007/2012/2017/2022
2. **INSEE MobPro 2013**: Commune-level mode of transport to work (car share)
3. **INSEE census/Filosofi**: Commune controls (population, median income, education, unemployment)
4. **Fuel prices** (donnees.roulez-eco.fr): Station-level annual prices for descriptive context

## Robustness
1. Pre-trend placebo (2007→2012)
2. Département fixed effects
3. Placebo outcomes (turnout change, left-wing vote change)
4. Alternative treatment: car-commuting quartiles instead of continuous
5. Dropping Île-de-France (Paris metro)
6. Conley spatial HAC at multiple bandwidths (25km, 50km, 100km)
