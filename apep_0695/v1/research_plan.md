# Research Plan: apep_0695

## Research Question

Does mass denationalization causally increase informal employment, compress wages, and reduce school enrollment? Specifically, does the Dominican Republic's 2013 TC/0168 ruling — which retroactively stripped citizenship from ~210,000 Haitian-descent Dominicans — push affected populations into informal labor markets and out of education?

## Identification Strategy

**Continuous-treatment difference-in-differences.** Treatment intensity = province-level Haitian-descent population share from IPUMS 2010 Census (pre-ruling). Provinces with higher Haitian-descent shares experienced more severe labor market disruption from TC/0168 because a larger fraction of their workforce lost legal documentation overnight.

**Specification:**
Y_{pt} = α_p + δ_t + β × (HaitianShare_p × Post2013_t) + ε_{pt}

where α_p = province FE, δ_t = year FE. β captures the differential change in outcomes for provinces with higher Haitian-descent exposure after TC/0168.

**Key assumptions:**
1. Parallel trends: high- and low-exposure provinces would have followed similar labor market trajectories absent TC/0168
2. No anticipation: TC/0168's retroactive scope was unexpected (the 2010 amendment was forward-looking)
3. Excludability: Haitian-descent share affects outcomes only through denationalization

## Expected Effects

- **Informality:** Positive β — denationalized workers are barred from formal employment
- **Wages:** Negative β — labor supply shock to informal sector compresses wages
- **School enrollment:** Negative β — affected youth lose access to public schools

## Primary Specification

Province × year panel using IPUMS census (2002, 2010) and World Bank/ILO annual data (2010-2023). Binary alternative: border provinces (Dajabón, Monte Cristi, Elías Piña, Independencia, Pedernales) as high-treatment group.

## Data Sources

1. **IPUMS International:** DR 2002, 2010 census microdata — province-level Haitian-born shares, employment, informality, school enrollment
2. **ILO SDMX API:** Monthly ENCFT unemployment, labor force participation (2015+), annual series (2010+)
3. **World Bank WDI API:** Vulnerable employment (informality proxy), unemployment, LFP (annual, 2000-2023)
4. **DHS API:** DR 2002, 2007, 2013 surveys — province-level education, health outcomes (7 waves 1986-2013)

## Robustness
- Border province dummy as binary treatment
- Placebo tests: fake 2010 treatment date
- Leave-one-out (drop largest province)
- Alternative treatment measure: Haitian-born share from census
- Two-shock design: 2010 amendment (weak) vs 2013 TC/0168 (strong)

## Mechanism Tests
- Formal→informal transition: decompose employment shifts
- Wage channel: informal sector wage compression in high-exposure provinces
- Human capital: school enrollment drop for affected youth
