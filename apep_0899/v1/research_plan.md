# Research Plan: apep_0899

## Title (working)
The Mandate Mirage: Finland's Extended Compulsory Education and the Limits of Legal Obligation

## Research Question
Does extending compulsory education from age 16 to 18 reduce dropout rates and improve school-to-work transitions? Finland's 2021 reform (Compulsory Education Act 1214/2020) provides the first opportunity to evaluate a modern compulsory education extension in a high-income, high-attainment setting.

## Identification Strategy

### Primary: Regional Intensity Difference-in-Differences
The reform is universal (all regions treated simultaneously in August 2021), but its "bite" varies across Finland's 21 regions because pre-reform vocational dropout rates ranged from 5.9% (Satakunta) to 12.6% (Uusimaa). I use continuous treatment intensity = pre-reform average vocational dropout rate (2018-2020) interacted with post-reform indicator.

### Built-in Placebo: Vocational vs. General Education (DDD)
The mandate primarily binds vocational students (dropout ~10%) rather than general/academic track students (dropout ~3%). DDD: vocational vs. general × high-intensity vs. low-intensity regions × pre vs. post.

### Design Parameters
- **Treated units:** 21 regions, continuous intensity
- **Pre-periods:** 13+ years (2007-2020 for school-to-work; 2000-2020 for dropouts)
- **Post-periods:** 3 years (2021-2024)
- **Clustering:** Region level (21 clusters) — will use wild cluster bootstrap

## Expected Effects and Mechanisms
**Hypothesis:** The reform has null or very small effects on dropout rates because the binding constraint in Finland is student motivation, not financial access or legal barriers. Textbook subsidies and tracking mandates may improve margins but cannot overcome disengagement.

**If null confirmed:** This challenges the worldwide presumption that compulsory education laws mechanically raise attainment. The mechanism insight: mandates work when the constraint is access (developing countries, historical Europe), not when it's motivation (modern welfare states).

## Primary Specification
```
Y_{r,s,t} = α + β₁(Intensity_r × Post_t) + β₂(Intensity_r × Voc_s × Post_t)
           + γ_r + δ_t + θ_s + μ_{r,t} + ν_{s,t} + ε_{r,s,t}
```
Where r = region, s = education sector (vocational/general), t = year.

## Data Sources
1. **Statistics Finland PxWeb API** — School-to-work transitions (table sijk/111l): 2007-2024, 21 regions, 26 outcome measures
2. **Statistics Finland PxWeb API** — Discontinuation of education by region (table kkesk/14pi): 2018-2024, 21 regions
3. **Statistics Finland PxWeb API** — Discontinuation of education nationally (table kkesk/14pn): 2000-2024, 4 education sectors

## Fetch Strategy
All data fetched via PxWeb REST API (JSON-stat format). No API key required. Base URL: `https://pxdata.stat.fi/PxWeb/api/v1/en/StatFin/`

## Robustness
1. Event study (year-by-year Intensity × Year interactions)
2. Wild cluster bootstrap (Cameron, Gelbach, Miller 2008)
3. Leave-one-region-out
4. Placebo: general education track (should show zero effect)
5. Alternative intensity measures (dropout level vs. dropout rank)
6. HonestDiD sensitivity (Rambachan-Roth bounds)
