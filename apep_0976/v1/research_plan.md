# Research Plan: The Yakuza Tax — Organized Crime Exclusion and Real Estate Markets in Japan

## Research Question

Do laws that sever organized crime's economic ties affect property values? Japan's Yakuza Exclusion Ordinances (YEOs), adopted by all 47 prefectures between April 2010 and January 2012, prohibited ordinary citizens from transacting with yakuza members. Unlike prior anti-yakuza laws targeting yakuza directly, YEOs attacked the demand side — criminalizing the counterparty relationship. We estimate the causal effect of YEO adoption on real estate transaction prices, exploiting staggered prefectural timing.

## Identification Strategy

**Design:** Staggered difference-in-differences using Callaway and Sant'Anna (2021) estimator.

- **Treatment:** Prefecture-level YEO adoption date (month-year). All 47 prefectures adopted between April 2010 (Fukuoka) and January 2012 (Saga), with substantial timing variation — 19 prefectures adopted at dates other than the modal month.
- **Comparison:** Not-yet-treated prefectures serve as controls in the CS framework.
- **Event window:** 24 months pre-adoption to 36 months post-adoption.
- **Clustering:** Prefecture level (47 clusters).

**Key threats:**
1. *Anticipation:* Real estate markets may price in YEO passage before formal adoption. We test for pre-trends and consider 6-month anticipation window.
2. *Concurrent policies:* The 2011 Tohoku earthquake/tsunami (March 2011) is a major confound. We control for earthquake-affected prefectures and show results excluding Tohoku region.
3. *Composition effects:* YEOs may change the type of transactions (e.g., fewer yakuza-linked commercial properties). We examine residential vs. commercial splits.

## Expected Effects and Mechanisms

**Primary hypothesis:** YEO adoption increases property values through two channels:
1. **Safety premium:** Reduced yakuza presence improves neighborhood safety, raising willingness-to-pay.
2. **Transaction cost reduction:** Removing organized crime intermediaries reduces hidden costs and corruption in real estate markets.

**Expected magnitude:** Moderate positive (SDE 0.05–0.15). Organized crime's real estate footprint is concentrated in commercial/entertainment districts.

## Primary Specification

```
Y_{ipt} = α + Σ_g Σ_t ATT(g,t) + X_{ipt}β + δ_p + γ_t + ε_{ipt}
```

Where Y is log transaction price per m², g is adoption cohort, p is prefecture, t is quarter-year, and X includes property characteristics (area, building age, land use type, distance to station).

## Data Sources

1. **MLIT Real Estate Transaction Price Survey** (国土交通省 不動産取引価格情報)
   - Source: Kaggle mirror of MLIT data (CC BY 4.0), or direct from MLIT API
   - Coverage: 2005–2019, all 47 prefectures
   - Variables: transaction price, area (m²), building age, land use, prefecture, municipality, year-quarter
   - ~380,000+ transactions

2. **YEO Adoption Dates**
   - Source: Hoshino & Kamada (2020, Journal of Quantitative Criminology), Table 1
   - All 47 prefectures with exact adoption dates (month/year)
   - Hard-coded from the published table (verified, immutable policy dates)

3. **Prefecture-level Controls**
   - e-Stat: population, GDP per capita, unemployment rate
   - Japan Statistical Yearbook: crime statistics (yakuza membership, reported offenses)

## Fetch Strategy

1. Download MLIT transaction data from Kaggle (CC BY 4.0 license)
2. Hard-code YEO adoption dates from Hoshino & Kamada (2020)
3. Fetch prefecture-level controls from e-Stat API using E-STAT API key
