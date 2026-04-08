# Research Plan: Does Fact-Checking Correct the Record?

## Question
Do fact-check publications shift topic-level media tone in subsequent coverage? Experimental lit studies individuals; we test the equilibrium media response.

## Data
- **ClaimReview** (Google Fact Check Tools API): 12,398 fact-check events 2013-2026, mapped from 21 query topics to 7 GDELT topics (immigration, climate, covid, elections, economy, healthcare, crime). ~85% rated false/misleading; 341 rated true (placebo).
- **GDELT GKG** (BigQuery v2Themes + v2Tone): daily topic-day panel 2017-01-01 to 2024-12-31, ~2921 days x 7 topics = 20,447 obs. `avg_tone`, `n_articles`.
- **GDELT Events IV**: daily counts of sports, disaster, cooperation, conflict events -> "competing news pressure."

## Mapping claimreview queries -> 7 topics
- immigration: immigration
- climate: climate
- covid: covid, masks, vaccine
- elections: election, ballot, fraud, trump, biden
- economy: economy, inflation
- healthcare: healthcare, abortion
- crime: crime, gun, school (school shootings)
- (dropped: china, israel, russia, ukraine — no matched GDELT topic)

## Identification
Topic-day panel, fact-check event counts as treatment intensity (`n_fc_t`). Main model:

```
tone_{i,t} = beta * fc_false_{i,t} + alpha_i + gamma_t + eps
```

Two-way FE (topic, date). Cluster on topic-week. Event-study leads/lags [-14, +14] around high-intensity days.

**IV (Eisensee-Strömberg style):** fact-check publication intensity on day t is partly crowded out by competing news. Instrument `fc_false_{i,t}` with `log(1 + sports_events_t + disaster_related_t)` (competing news pressure reduces attention to political coverage, hence reduces publication/salience of fact-checks).

Exclusion: sports/disaster news does not directly move political topic tone after partialling out topic+date FE and total GDELT volume.

## Placebo
Use `fc_true_{i,t}` (true-rated reviews) — information correction should not apply.

## Robustness
- Alt topic definitions (drop ambiguous queries)
- Alt windows (7d, 21d)
- Drop high-volume topics
- Weighted by n_articles
- Placebo: shuffled treatment timing

## Tables
1. Descriptives (topic panel summary)
2. OLS + FE specs
3. IV (first stage, reduced form, 2SLS)
4. Placebo + robustness
5. SDE (structured disclosure) — tabF1
