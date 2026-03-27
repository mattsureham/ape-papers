# Research Plan: The Picture Bride Premium

## Research Question

Did the picture bride system — a diplomatic loophole allowing Japanese men in the US to send for wives from Japan (1908-1920) — drive measurable economic mobility for Japanese immigrants? The 1907-08 Gentlemen's Agreement banned Japanese male labor immigration but permitted family reunification, producing a 4-fold increase in Japanese women by 1920 (sex ratio from 6.6:1 to 1.9:1). The 1920 Ladies' Agreement abruptly closed this channel. Chinese men faced similar labor market discrimination but the Chinese Exclusion Act (1882) denied all family formation. This paper estimates whether the picture bride channel produced a measurable economic premium for Japanese men relative to Chinese men.

## Identification Strategy

**Primary design: Cross-race difference-in-differences**

- Treatment: Japanese men (RACE=5) gained access to wives via picture brides (1908-1920)
- Control: Chinese men (RACE=4) denied family reunification by Chinese Exclusion Act
- Pre-period: 1910 (before mass picture bride arrivals)
- Post-period: 1920 (peak), 1930 (medium-run)
- Unit: individual men aged 20-50 at baseline

Key assumption: Absent the picture bride system, Japanese and Chinese men's economic trajectories would have been parallel. Both groups:
- Concentrated in West Coast states (CA, WA, OR)
- Worked in agriculture, railroads, mining, domestic service
- Faced racial discrimination and legal exclusion (Alien Land Laws, housing covenants)
- Had no realistic path to US citizenship (Ozawa v. US, 1922)

The identifying variation comes from a diplomatic agreement, not individual self-selection.

**Supporting design: Within-Japanese individual panel (1920→1930 via MLP)**
- Link Japanese men across 1920 and 1930 censuses using MLP crosswalk
- Compare occupational mobility for men married in 1920 vs. unmarried
- Addresses: does marriage (via picture bride) cause within-person economic gains?

**Heterogeneity: Alien Land Law interaction**
- CA (1913), WA (1921), OR (1923) enacted Alien Land Laws barring Japanese from owning agricultural land
- DDD: Japanese vs. Chinese × Pre vs. Post × ALI state vs. non-ALI state
- Tests whether family formation buffered against legal discrimination or whether the marriage premium was concentrated in states without land ownership barriers

## Expected Effects and Mechanisms

**Primary mechanism:** Household formation enables economic specialization, stability, and social capital accumulation. Married men can take longer-term employment, invest in skills, access community credit networks. Picture brides also brought Japanese literacy skills, enabling joint household management.

**Expected direction:** Positive — married Japanese men should show occupational upgrading relative to Chinese men who remained unmarried. Effect should be larger in:
- Non-Alien Land Law states (where economic gains could be invested in land)
- Agricultural regions (where household labor was directly productive)
- Younger cohorts (longer horizon to benefit)

**Null possibility:** Picture bride marriage may have had no economic premium if (a) discrimination was binding regardless of household status, or (b) the marriage cost itself (supporting a family) offset any gains. A null is publishable if well-powered.

## Primary Specification

```
Y_{ist} = β₁(Japanese_i × Post_t) + γ_i + δ_t + State_s × Year_t + X_{it}Φ + ε_{ist}
```

Where:
- Y = OCCSCORE or SEI
- Japanese_i = 1 if Japanese, 0 if Chinese
- Post_t = 1 if year ≥ 1920
- γ_i = race fixed effects
- δ_t = year fixed effects
- State × Year = state-by-year fixed effects (absorbs local economic conditions)
- X = age, age², literacy

Since we have repeated cross-sections (not a panel in the aggregate DiD), use pooled regression with race and year FEs.

For the individual panel: first-differenced regression within linked individuals.

## Data Source and Fetch Strategy

All data from Azure Blob Storage (confirmed available):
- `raw/ipums_fullcount/us1910m.parquet` — 1910 full-count census
- `raw/ipums_fullcount/us1920c.parquet` — 1920 full-count census
- `raw/ipums_fullcount/us1930d.parquet` — 1930 full-count census
- `raw/ipums_mlp/v2/mlp_crosswalk_v2.parquet` — individual linkage

Query via DuckDB in R:
```r
source("scripts/lib/azure_data.R")
con <- apep_azure_connect()
# Filter RACE IN (4, 5) [Chinese, Japanese], SEX=1 [male], AGE 20-50
```

No external API calls needed — all data pre-staged in Azure.

## Design Parameters

- Japanese men per census: ~60K (1910), ~71K (1920), ~80K (1930)
- Chinese men per census: ~56K (1910), ~43K (1920), ~45K (1930)
- Linked panel (1920→1930): estimated 15-25K Japanese men via MLP
- Pre-periods: 1900, 1910 (if 1900 feasible)
- Treatment timing: Picture bride influx 1908-1920
- Clustering: State level (50+ clusters)

## Placebo Tests

1. White immigrant men (RACE=1, BPL>100) — had unrestricted family formation → should show no differential change
2. Chinese vs. Filipino men — neither had picture bride access → should show no differential
3. Pre-trend: 1900→1910 Japanese vs. Chinese trajectories (before picture brides)
