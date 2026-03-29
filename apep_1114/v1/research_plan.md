# Research Plan: apep_1114

## Research Question

Does adverse selection undermine voluntary environmental buyout programs? Specifically, in the Dutch piekbelasters (peak emitter) livestock buyout program — the world's largest environmental farm buyout at EUR 1.5 billion — did the least nitrogen-intensive farms disproportionately exit, reducing the program's environmental cost-effectiveness?

## Background

The Netherlands faces a severe nitrogen deposition crisis. In October 2019, the Dutch Council of State (Raad van State) ruled the national nitrogen policy (PAS) invalid, effectively halting construction and agricultural expansion near Natura 2000 protected sites. This created enormous regulatory pressure on livestock operations.

In June 2023, the government launched the Lbv-plus ("piekbelasters") buyout, offering 120% of assessed farm value to the highest-emitting livestock operations near Natura 2000 sites, plus a general scheme at 100%. By December 2024: 920 peak emitter applications, 665 general scheme, 1,438 approved.

The adverse selection problem: if the 120% premium primarily attracts farms with low livestock intensity (who lose less productive capacity from exiting), the program pays above-market prices for farms that contribute least to the nitrogen problem.

## Identification Strategy

**Primary design: Intent-to-Treat DiD**

Treatment: Municipality-level exposure to the buyout program, measured as:
- Pre-2019 livestock density (cattle + pigs + poultry in livestock units) × share of municipality area within 5km of Natura 2000 sites

This continuous treatment intensity captures both the nitrogen emission potential and proximity to protected areas that determined buyout eligibility.

**Two treatment shocks:**
1. **October 2019**: Raad van State nitrogen ruling — regulatory uncertainty shock
2. **June 2023**: Lbv-plus buyout launch — direct financial incentive to exit

**Outcome variables** (CBS municipality-level):
- Number of agricultural holdings (farm exit rate)
- Total livestock counts (cattle, pigs, poultry — in livestock units)
- Agricultural employment (SBI section A)

**Estimator:** Callaway-Sant'Anna (2021) staggered DiD is not needed here since treatment timing is uniform (all municipalities face the same policy dates). Instead, use continuous treatment intensity DiD:

Y_{mt} = α_m + γ_t + β × (Exposure_m × Post_t) + ε_{mt}

where Exposure_m is pre-treatment livestock density × Natura 2000 proximity.

**Adverse selection test:**
- Compare livestock intensity trajectories between high-exposure and low-exposure municipalities
- If adverse selection: farm *counts* decline but livestock *per remaining farm* increases (intensive margin) or total livestock declines less than farm counts suggest
- Direct test: among exiting farms (proxied by municipality-level declines), did municipalities with lower pre-period livestock intensity per farm experience larger farm count declines?

## Data Sources

1. **CBS 80781ned** — Agricultural census by municipality (2000-2025)
   - Variables: number of farms, cattle, pigs, poultry, agricultural land
   - Access: CBS Open Data API (cbsodata4)

2. **CBS 83582NED** — Agricultural employment by municipality (2010-2024)
   - Variables: SBI section A employment
   - Access: CBS Open Data API

3. **PDOK Natura 2000** — GeoPackage with protected site boundaries
   - Used to construct municipality-level proximity exposure measure
   - Access: PDOK download service (confirmed 10.7 MB)

4. **CBS 70739ned** — Municipality area and land use
   - Used to normalize livestock density

## Expected Effects

1. **Farm exit:** High-exposure municipalities should show accelerated farm exit after 2019 (regulatory shock) and especially after 2023 (buyout).

2. **Adverse selection signature:** If present, the ratio of livestock decline to farm count decline should be below 1 — farms exit but total livestock falls less than proportionally, indicating low-intensity farms disproportionately left.

3. **Employment:** Agricultural employment in high-exposure areas should decline, with potential spillovers to agri-food processing.

## Primary Specification

```r
# Continuous treatment DiD
feols(log_farms ~ exposure_m:post_2019 + exposure_m:post_2023 |
        municipality + year,
      data = panel, cluster = ~municipality)
```

## Robustness

1. Placebo treatment year (2015) — no differential trends before 2019
2. Event study — year-by-year coefficients interacted with exposure
3. Alternative exposure measures (binary high/low, distance-based only)
4. Leave-one-out: drop Ede, Venray, Barneveld (highest concentration)
5. Agricultural land area as alternative denominator

## Key Risk

Short post-treatment window for the 2023 buyout (only 2 years). The 2019 nitrogen ruling provides a longer post-period (6 years) but is a regulatory shock, not a buyout. The paper's main contribution — testing adverse selection — is most convincingly addressed using the 2023+ variation, so power may be limited for the selection test.
