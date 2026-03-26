# Research Plan: Consolidation Backlash — Forced EPCI Mergers and the Rise of the Rassemblement National

## Research Question

Did forced intercommunal mergers under France's Loi NOTRe (2015) increase support for the Rassemblement National? The reform eliminated 39% of EPCIs on January 1, 2017, forcing ~15,000 communes into larger, more distant intercommunal structures. We test whether this institutional consolidation — which shifted competences away from commune-level governance — fueled populist backlash at the ballot box.

## Identification Strategy

**Continuous Difference-in-Differences.** Treatment intensity = log ratio of post-merger to pre-merger EPCI population for each commune. Communes whose EPCI was unchanged serve as controls (intensity = 0). The identifying assumption is that, absent the merger, trends in RN vote share would have been parallel across communes with different merger intensity.

- **Treatment group:** ~15,000–20,000 communes whose EPCI changed on January 1, 2017
- **Control group:** ~10,000–15,000 communes whose EPCI was unchanged
- **Pre-treatment elections:** Presidential 2002, 2007, 2012; European 2004, 2009, 2014
- **Post-treatment elections:** Presidential 2017 (round 1), 2022 (round 1); European 2019, 2024
- **Clustering:** Département level (~96 clusters)

**Robustness:**
1. Callaway-Sant'Anna (binary: merged vs not) with commune and election FE
2. Mountain-zone derogation subsample (communes exempt from the 15,000 threshold)
3. Placebo: communes affected by 2010 RCT-law mergers (pre-Loi NOTRe) — should show no differential effect in 2012
4. Pre-trends: 2002–2012 trend tests
5. Controlling for département-level economic trends (unemployment, population change)

## Expected Effects and Mechanisms

**Primary hypothesis:** Forced mergers increase RN vote share. Mechanism: democratic distance. When communes are absorbed into larger EPCIs, citizens lose proximity to decision-makers. Competence transfers (water, waste, transport planning) mean local preferences matter less. This breeds alienation and anti-establishment voting.

**Secondary outcomes:**
- Turnout (could decrease if citizens feel disengaged)
- Blank/null ballots (protest voting signal)
- Vote share for other anti-establishment parties (Mélenchon/LFI) — to test whether the effect is specific to far-right or general anti-system

## Primary Specification

Y_{c,t} = α_c + γ_t + β · (MergerIntensity_c × Post_t) + X_{c,t}'δ + ε_{c,t}

Where:
- Y_{c,t} = RN vote share (% of expressed votes) in commune c at election t
- α_c = commune fixed effects
- γ_t = election fixed effects
- MergerIntensity_c = log(EPCI_pop_2017 / EPCI_pop_2016) for affected communes, 0 otherwise
- Post_t = indicator for elections after January 1, 2017
- X_{c,t} = time-varying controls (log population, département unemployment)
- Standard errors clustered at département level

## Data Sources and Fetch Strategy

1. **Election results:** data.gouv.fr commune-level results for Presidential (2002, 2007, 2012, 2017, 2022) and European (2004, 2009, 2014, 2019, 2024). Direct CSV download, no API key.

2. **EPCI composition:** BANATIC (Base Nationale sur les Intercommunalités) and HistoBanatic from data.gouv.fr — tracks all commune-to-EPCI mappings and EPCI mutations 2011–2024. This gives us pre-merger and post-merger EPCI assignment for every commune.

3. **Commune characteristics:** INSEE BDM/SDMX — population, unemployment, income at commune/département level. No API key needed for SDMX endpoint.

4. **Mountain-zone classification:** For derogation subsample — communes in mountain zones were allowed lower EPCI population thresholds.
