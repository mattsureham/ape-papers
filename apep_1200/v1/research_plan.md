# Research Plan: The Ballot Box Rejection — Close-Vote RDD on Cross-Border Workers After Switzerland's 2014 Mass Immigration Initiative

## Research Question

Do narrowly-passed immigration referendums generate real economic consequences through policy uncertainty, even before legal implementation? We exploit the razor-thin passage (50.3% yes) of Switzerland's 2014 Mass Immigration Initiative (MII) — which threatened to end EU free movement — using a fuzzy close-vote RDD on ~2,100 municipal vote margins to estimate effects on cross-border commuter (Grenzgänger) flows.

## Identification Strategy

**Design:** Cross-sectional fuzzy close-vote RDD at the municipal level, supplemented by cantonal-level DiD.

**Running variable:** Municipal yes-share on the February 9, 2014 MII vote, centered at 50%. The 50.3% national result created near-50/50 splits across municipalities.

**Logic:** No individual municipality's vote determines the federal policy outcome, but municipal yes-share reveals local immigration sentiment intensity. Municipalities barely above vs. below 50% should be comparable in pre-2014 characteristics. The RDD identifies the reduced-form effect of crossing the local yes-majority threshold on subsequent economic outcomes.

**Outcomes:**
1. Primary: Cross-border commuter flows (Grenzgänger, quarterly, by canton)
2. Secondary: Municipal population change, foreign population share

**Key assumption:** No sorting/manipulation of the forcing variable. Municipal vote shares are determined by millions of individual choices; strategic manipulation at the 50% threshold is implausible.

**Threats and mitigation:**
- SNB floor removal (January 2015): concurrent shock but affects all municipalities equally → orthogonal to vote margin
- Spatial correlation: municipalities cluster within cantons → cluster SEs at canton level
- Fuzzy nature: municipal vote ≠ federal policy → interpret as ITT on local sentiment shock

## Data Sources

1. **swissdd R package** (GitHub: zumbov2/swissdd) — Municipal vote results for MII (Feb 9, 2014)
2. **BFS PXWeb API** — Municipal population, foreign population share (1981–2024)
3. **BFS Grenzgängerstatistik** — Quarterly cross-border commuters by canton (since 1996)
4. **opendata.swiss** — Additional demographic and economic indicators

## Primary Specification

Y_m = α + τ · 1[VoteShare_m > 0.5] + f(VoteShare_m - 0.5) + X_m'β + ε_m

where Y_m is the post-2014 change in outcome for municipality m, VoteShare_m is the municipal yes-share, f(·) is a local polynomial, and X_m are pre-determined controls.

Estimation: rdrobust with MSE-optimal bandwidth, triangular kernel, and robust bias-corrected CIs (Cattaneo, Idrobo & Titiunik 2020).
