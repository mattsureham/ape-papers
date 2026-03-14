# Research Plan: The Vanishing Mandate — Finland's Competitiveness Pact and the Productivity Paradox of Legislated Working Time Increases

## Research Question

Did Finland's 2017 Competitiveness Pact — which mandated a 24-hour/year increase in working time with no wage increase — actually increase hours worked and raise labor productivity? The policy created a natural experiment: Finland (treated) vs. Sweden, Denmark, Norway (controls), with public-sector workers receiving a "double dose" (hours increase + 30% holiday bonus cut).

## The Puzzle

The mandate predicted a ~1.4% increase in total hours. Finnish hours grew only 0.2% from 2016 to 2017, while Swedish hours grew 1.7%. The mandated hours appear to have *vanished*. Where did they go?

## Identification Strategy

**Triple-Difference-in-Differences:**
- **First difference (time):** Pre-2017 vs. post-2017
- **Second difference (country):** Finland vs. Sweden, Denmark, Norway
- **Third difference (sector intensity):** Public sector (O-Q, double treatment) vs. private sector (hours only)

**Specification:**
Y_{s,c,t} = α + β₁(FI_c × Post_t) + β₂(FI_c × Post_t × Public_s) + γ_{s,c} + δ_{c,t} + ε_{s,c,t}

Where β₁ = overall Pact effect, β₂ = additional public-sector channel.

**Key identifying assumption:** Absent the Pact, Finnish sector-level hours and productivity would have evolved parallel to Nordic peers.

## Expected Effects and Mechanisms

**Hours:** Near-zero aggregate effect (visible in raw data). The mandate was likely absorbed through:
- Reduced overtime/informal non-compliance
- Substitution between intensive and extensive margins
- Compositional effects (fewer workers × more hours/worker)

**Productivity:** Ambiguous. If diminishing returns dominate, productivity per hour falls. If fixed-cost spreading dominates, it rises.

**Public sector:** Stronger negative effect on recruitment/retention due to holiday bonus cut compounding the hours mandate.

## Primary Specification

1. **Main outcome:** Log total hours worked by sector-country-year
2. **Secondary:** Log GVA per hour (productivity), employment headcount
3. **Mechanism:** Public vs. private sector differential, hours per worker vs. employment decomposition

## Data Sources

All from Eurostat REST API (no authentication required):
1. `nama_10_a10_e`: Hours worked and employment by NACE A*10 sector, 4 countries, 2012-2022
2. `nama_10_a10`: GVA by sector for productivity calculation
3. `lfsa_egan2`: LFS employment by detailed NACE sector (robustness)

## Pre-registration of Design Choices

- Sample: 2012-2019 (dropping 2020+ due to COVID in main spec; 2012-2022 as robustness)
- Clustering: Country level (4 clusters → wild cluster bootstrap)
- Pre-trends: Event study 2012-2016 relative to 2016
- Placebos: (a) Apply same design to 2013 as fake treatment year; (b) Use agriculture (sector A) as placebo sector less affected by the pact
