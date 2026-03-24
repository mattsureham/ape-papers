# Research Plan: Revealed Hostility — Anti-Immigration Referendum Signals and Foreign Residential Sorting in Swiss Municipalities

**Paper ID:** apep_0864
**Idea:** idea_0705
**Date:** 2026-03-24

## Research Question

Do municipalities that revealed stronger anti-immigration preferences through the 2014 Mass Immigration Initiative (MEI) vote experience differential changes in foreign resident population? If referendums function as costly signals of local hostility, municipalities voting more strongly "yes" should see relative foreign population declines — even though the national policy outcome was identical everywhere.

## Identification Strategy

**Primary: Continuous Treatment DiD**

- **Treatment intensity:** Municipal MEI yes-vote share (range 19–94%, SD ≈ 11pp)
- **Unit:** Municipality × year
- **Panel:** 2010–2023 (4 pre-periods, 9 post-periods)
- **Specification:** Y_{mt} = α_m + γ_t + β(VoteShare_m × Post_t) + X_{mt}δ + ε_{mt}
- **Outcome:** Foreign resident share, foreign population growth rate
- **Fixed effects:** Municipality FE (α_m), year FE (γ_t)
- **Controls:** Pre-vote foreign share × year trends, language region × year, canton × year
- **Clustering:** Municipality level (2,100+ clusters)

**Secondary: RDD within close municipalities**

- Within 48–52% yes-vote band (~266 municipalities): sharp discontinuity at 50%
- Running variable: municipal yes-vote share centered at 50%
- Tests whether crossing the symbolic "majority hostile" threshold has additional sorting effects

**Diagnostics:**
- Event study: dynamic treatment effects by year relative to 2014
- Placebo referendum: 2014 railway financing referendum (62% yes, no immigration content)
- HonestDiD/Rambachan-Roth sensitivity to parallel trends violations
- Leave-one-canton-out robustness

## Data Sources

1. **Referendum results:** ogd-static.voteinfo-app.ch JSON API — municipal-level MEI results (2,114 municipalities)
2. **Population by citizenship:** BFS PXWeb API — permanent residents by municipality, year, citizenship (Swiss vs Foreign), 2010–2023
3. **Municipality merger mapping:** BFS SMMT — harmonize municipality IDs across panel
4. **Controls:** BFS municipal statistics (employment, unemployment, language region)

## Exposure Alignment

The treatment is the municipal-level MEI yes-vote share — a cross-sectional measure revealed on February 9, 2014. All municipalities receive the "signal" simultaneously (the vote date), but treatment intensity varies continuously. The affected population is foreign permanent residents (and prospective foreign residents considering where to live). The outcome (foreign population share) measures the stock of foreign residents at year-end, capturing the net result of inflows, outflows, naturalizations, and demographic change. The identifying variation is within-canton differences in how strongly municipalities voted, conditional on pre-existing composition.

## Expected Effects

If referendum signals operate as "revealed hostility":
- Municipalities with higher MEI yes-vote shares should see relative decline in foreign resident share post-2014
- Effect should be stronger for discretionary movers (not tied to specific employers)
- Placebo referendum should show no effect

Economically: A 10pp higher yes-vote share might reduce foreign population growth by 0.5–2pp over the subsequent decade.

## Primary Specification

```
ForeignShare_{mt} = α_m + γ_t + β(YesShare_m × Post2014_t) + (PreForeignShare_m × γ_t) + (Language_m × γ_t) + ε_{mt}
```

Where β < 0 indicates that more hostile municipalities experienced larger relative declines in foreign population.
