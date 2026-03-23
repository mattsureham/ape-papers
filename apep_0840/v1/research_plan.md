# Research Plan: The Noise Tax on Democracy — Competing News and Swiss Referendum Turnout

## Research Question

Does exogenous variation in competing news coverage reduce voter turnout in Swiss federal referendums? When foreign disasters absorb media bandwidth, do Swiss voters receive less information about upcoming ballot items, and does this "noise tax" depress participation and bias outcomes toward the status quo?

## Identification Strategy

**Competing-news IV (Eisensee & Stromberg 2006 QJE):**

1. **First stage:** Foreign disasters (earthquakes, floods, terror attacks) exogenously crowd out Swiss referendum coverage in the days before a vote. GDELT daily article counts quantify Swiss-topic vs. foreign-disaster article shares.

2. **Second stage:** Reduced pre-vote Swiss media coverage → lower municipal turnout and potentially higher status-quo (No) vote shares.

3. **Cross-sectional variation from language regions:** French-speaking municipalities consume French-language media; German-speaking municipalities consume German-language media. The *same* foreign disaster has differential salience across language regions depending on where it occurs (e.g., Francophone Africa disasters are more salient in French-language media). This provides within-referendum variation in the competing-news instrument.

**Estimating equation:**

```
Turnout_mvr = β₀ + β₁ × CompetingNews_vr + Municipality_FE + Vote_FE + Language_Region × Year_FE + ε_mvr
```

Where:
- m = municipality, v = vote (ballot item × date), r = language region
- CompetingNews_vr = share of GDELT articles in language r about foreign disasters in the 7 days before vote date v
- Instrument: count of major foreign disasters (GDELT event intensity) in regions covered primarily by language-r media

**Key identification assumptions:**
- Foreign disasters are exogenous to Swiss referendum timing (referendums scheduled 6+ months in advance)
- Foreign disasters affect Swiss turnout only through media crowding-out (exclusion restriction)
- Language-region media segmentation provides within-referendum variation

## Expected Effects and Mechanisms

- **Primary:** Higher competing news → lower turnout (information cost channel)
- **Heterogeneity:** Effect larger for complex/obscure ballot items (where information cost matters more) than for highly salient items
- **Status-quo bias:** Lower turnout may favor "No" votes (status quo) if marginal voters are more persuadable
- **Language-region differential:** Effect mediated by language-specific media markets

## Primary Specification

2SLS with municipality and vote fixed effects. Cluster standard errors at the vote-date × language-region level (the level of the instrument variation).

## Data Sources

1. **Swiss referendum results:** `swissdd` R package — municipal-level turnout and yes-share for all federal votes since 2015. ~2,100 municipalities × ~120 ballot items = ~252,000 obs.

2. **Competing news:** GDELT Global Knowledge Graph (BigQuery: `gdelt-bq.gdeltv2.gkg_partitioned`) — daily article counts by theme, location, and source language. Construct:
   - Swiss referendum coverage: articles mentioning Swiss political themes in 7 days pre-vote
   - Foreign disaster coverage: articles coded as natural disaster/conflict in same window
   - Language-specific: filter by source domain language (French vs. German)

3. **Ballot item characteristics:** Swissvotes database (swissvotes.ch) — policy domain, government recommendation, pre-vote poll margins, complexity indicators.

4. **Municipality characteristics:** BFS municipal statistics — population, language region, urban/rural classification.

## Robustness and Placebo Tests

- **Placebo timing:** Competing news in weeks *after* the vote should not predict turnout
- **Placebo geography:** Effect should be concentrated in language region matching the disaster's media market
- **Ballot-item heterogeneity:** Stronger effects for low-salience items
- **Alternative instruments:** Use only natural disasters (earthquakes, floods) vs. all GDELT events
- **Bandwidth sensitivity:** Vary pre-vote window (3, 5, 7, 10, 14 days)
