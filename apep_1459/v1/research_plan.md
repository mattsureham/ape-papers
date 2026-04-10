# Research Plan: The Queue Tax — Administrative Barriers and Refugee Employment in Germany

## Research Question

Does removing administrative barriers to refugee employment — specifically the labor market priority check (Vorrangprüfung) — causally affect refugee and native labor market outcomes? Germany's 2016 Integration Act suspended this check in 133 of 156 employment agency districts while maintaining it in 23, creating sharp geographic variation in bureaucratic hiring frictions.

## Identification Strategy

**Primary: Geographic Difference-in-Differences**

- Treatment: 133 Agenturbezirke where the Vorrangprüfung was suspended (August 2016)
- Control: 23 Agenturbezirke where it was maintained (11 in Bavaria, 7 in NRW Ruhr, 5 in Mecklenburg-Vorpommern)
- Unit: NUTS-3 regions (Kreise), mapped to their Agenturbezirk treatment status
- Time: Annual, 2012–2020 (4 pre-treatment years, 4 post-treatment years)

Y_{it} = α_i + γ_t + β · Suspended_i · Post_t + X_{it}δ + ε_{it}

**Secondary: Within-Bavaria RDD**

Bavaria assigned suspension based on district unemployment relative to 3.6% state average — a mechanical cutoff. Districts below 3.6% got the suspension; those above retained the check.

**Built-in Placebo**

The Vorrangprüfung only applied to asylum seekers and Duldung holders during their first 15 months — not to recognized refugees with formal asylum status. Native German employment should also be unaffected.

## Expected Effects

- Small positive effect on foreign employment in suspended districts (the priority check was reportedly rarely binding, but compliance costs deterred hiring)
- Near-zero effect on native employment (the check was a formality, not a real labor market shield)
- Larger effects in tight labor markets (low-unemployment areas where employers faced genuine shortages)

## Primary Specification

Callaway-Sant'Anna DiD with NUTS-3 units, treatment = Vorrangprüfung suspended, clustered at the Agenturbezirk level (23 control + 133 treated clusters).

## Exposure Alignment

The Vorrangprüfung applied only to asylum seekers and Duldung holders during their first 15 months of residence — a small subset of the regional workforce (~1-2%). Total regional employment includes all workers regardless of nationality and legal status. This means the outcome variable (aggregate NUTS-3 employment) captures general-equilibrium effects on the entire local labor market, not the direct effect on the treated refugee subgroup. A large effect on refugee hiring could generate near-zero changes in aggregate employment if the treated population share is small. The analysis therefore identifies aggregate labor market spillovers from the policy change, not the direct effect on refugee employment.

## Data Sources

1. **Eurostat nama_10r_3empers** — NUTS-3 employment by industry (annual, 2012–2020). Confirmed working via REST API.
2. **Eurostat nama_10r_3gdp** — NUTS-3 GDP (annual). Confirmed.
3. **Eurostat demo_r_pjangrp3** — NUTS-3 population by age group (annual). Confirmed.
4. **Eurostat lfst_r_lfu3rt** — NUTS-2 unemployment rates. Confirmed.
5. **Eurostat migr_pop3ctb** — NUTS-3 population by citizenship (foreign vs national). For measuring foreign population share.

## Treatment Assignment

Map all German NUTS-3 codes to Agenturbezirke. Control NUTS-3 codes are those in:
- Mecklenburg-Vorpommern: All DE80x codes
- Bavaria (11 named Agenturbezirke): Map via city-to-NUTS-3 concordance
- NRW Ruhr (7 named Agenturbezirke): Map via city-to-NUTS-3 concordance

All other German NUTS-3 codes are treated.
