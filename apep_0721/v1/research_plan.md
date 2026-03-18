# Research Plan: The Compression Dividend — How Britain's National Living Wage Reshaped the Bottom of the Distribution

## Research Question

Did the UK's National Living Wage (2016-2023) merely raise the wage floor, or did it compress the entire lower half of the wage distribution through spillover effects above the minimum? Using the cross-local-authority variation in the NLW's "bite" (ratio of NLW to local median wage), we estimate the causal effect of minimum wage increases on each percentile of the hourly wage distribution.

## Identification Strategy

**Design:** Continuous-treatment difference-in-differences.

**Treatment intensity:** Pre-policy (2015) NLW bite ratio per local authority, defined as NMW (£6.70) / LA-level median hourly wage. This ranges from 0.277 (City of London) to 0.835 (Weymouth and Portland), mean 0.604, SD 0.081.

**Intuition:** The NLW is set nationally at a uniform rate, but its economic impact varies by local labour market. In high-bite LAs (where the minimum is close to the median), the NLW affects a large share of workers and may compress the entire lower distribution. In low-bite LAs (where the minimum is far below the median), the NLW affects few workers and generates minimal compression.

**Specification:**
log(p_kit) = α_i + γ_t + β × Bite_i × Post_t + X'δ + ε_it

where p_kit is the k-th percentile of hourly wages in LA i in year t, Bite_i is the pre-2016 bite ratio, Post_t = 1 for years ≥ 2016, and α_i and γ_t are LA and year fixed effects.

**Key test:** If β > 0 for k = 10, 25 but β ≈ 0 for k = 50, 60, 90, the NLW compresses the lower distribution through spillovers. If β > 0 only for k = 10, the NLW merely raised the floor without spillovers.

## Expected Effects

- p10: Large positive (direct effect of the NLW floor)
- p25: Moderate positive (spillover — firms restructure pay scales)
- p50: Small or null (the median should be less affected)
- p60, p90: Null (upper distribution unaffected)

The gradient from p10 to p90 IS the test of wage compression.

## Data Sources

1. **NOMIS ASHE (NM_99_1):** Workplace-based hourly pay excluding overtime at 5 percentiles (10th, 25th, 50th, 60th, 90th) for 406 local authority districts, annually 2013-2023.
   - API: https://www.nomisweb.co.uk/api/v01/
   - R package: `nomisr`

## Exposure Alignment

The NLW applies uniformly to all workers aged 25+ (later 23+) across all UK local authorities. The treatment intensity — the bite ratio — measures how binding the NLW is in each LA. In high-bite LAs (where pre-NLW median wages were low), a larger fraction of workers earn near the NLW floor and are directly affected. The key exposure alignment: workers in high-bite LAs are more likely to have their wages directly raised or indirectly affected by the NLW through firm pay-scale adjustments. ASHE data captures workplace-based earnings, so the outcome measures wages of people working in each LA regardless of where they live. This aligns well with the NLW's workplace-based application.

## Analysis Plan

1. Fetch NOMIS ASHE data via API
2. Construct bite ratio for each LA using 2015 median wage
3. Estimate continuous-treatment DiD: log(percentile) ~ LA FE + Year FE + Bite × Post
4. Separately for each percentile (p10, p25, p50, p60, p90)
5. Robustness: pre-trends, alternative bite definitions, excluding outlier LAs
6. Heterogeneity: by region, by sector composition
