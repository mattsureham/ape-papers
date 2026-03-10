# Initial Research Plan: The Anatomy of Import Compression

## Research Question

Do large devaluations compress imports uniformly, or do they create a "hierarchy of survival" that protects intermediate inputs relative to final consumer goods? If so, how large is the differential, and does this endogenous hierarchy sustain domestic production through the expenditure-switching channel?

## Identification Strategy

**Design:** Product-level event study exploiting Egypt's 48% overnight devaluation (November 3, 2016).

**Key variation:** Cross-sectional differences in product-level demand elasticity determined by position in the production chain (BEC classification):
- **Intermediate inputs** (BEC 111, 121, 21, 22, 31, 322, 42, 53): Firms need these to maintain production → inelastic demand
- **Capital goods** (BEC 41, 521): Lumpy investment → deferrable
- **Final consumption goods** (BEC 112, 122, 51, 522, 61, 62, 63): Consumers can substitute or reduce → elastic demand

**Primary specification:**

log(Import_value_{p,t}) = α_p + γ_t + β₁(Post_t × Intermediate_p) + β₂(Post_t × Capital_p) + ε_{p,t}

where final consumption goods are the omitted category.

**Prediction:** β₁ > 0 (intermediate imports decline less than finals); β₂ intermediate between β₁ and 0.

**Pre-trends:** 6 years (2010-2015) of parallel import trajectories across BEC categories before November 2016.

**Built-in placebo:** Capital goods should show intermediate response — they are needed for production but investment is deferrable. This ordered prediction (intermediate > capital > final) is the key test.

## Expected Effects and Mechanisms

1. **Differential compression:** Intermediate goods imports decline 20-30% less than final consumption goods (β₁ > 0)
2. **Capital deferral:** Capital goods decline more than intermediates but less than finals (0 < β₂ < β₁)
3. **Expenditure-switching channel:** Sectors with protected intermediate imports show less output decline and stronger export growth post-devaluation
4. **Geographic trade diversion:** Final goods imports shift from dollar to euro/yuan-denominated partners

## Primary Specification

- **Unit:** HS6 product × year (annual) and HS6 product × month (monthly for dynamics)
- **Sample:** ~5,000 HS6 products × 13 years = ~65,000 product-year observations
- **Fixed effects:** Product (α_p) + Year (γ_t)
- **Clustering:** HS2 chapter level (~97 clusters)
- **Outcome:** log(import value + 1) in USD

## Planned Robustness Checks

1. **Pre-trend test:** Event study with year-by-BEC interactions (2010-2023, omitting 2015)
2. **Monthly dynamics:** Monthly event study to trace adjustment path
3. **Continuous treatment:** Pre-devaluation import penetration ratio as dose
4. **Triple-difference:** Dollar vs. euro-denominated partner sources × BEC × Post
5. **Leave-one-out HS2:** Drop each HS2 chapter and re-estimate
6. **Extensive margin:** Probit/LPM on product entry/exit (does the devaluation kill product varieties?)
7. **Value vs. quantity:** Separate price from quantity effects using weight data
8. **Randomization inference:** Permute treatment timing across years
9. **Alternative BEC mappings:** Collapse to 2-way (intermediate vs. final) and verify

## Data Sources

1. **UN COMTRADE:** HS6 bilateral trade data, Egypt (818), imports, 2010-2023
2. **BEC Rev.5 concordance:** HS6 → BEC end-use mapping from UNSD
3. **World Bank WDI:** Exchange rate series (PA.NUS.FCRF) for Egypt
4. **World Bank Enterprise Survey:** Egypt 2016 and 2020 waves (mechanism validation)

## Exposure Alignment (DiD Requirements)

- **Who is treated:** All HS6 imported products — the treatment is the devaluation, applied to all
- **Cross-sectional variation:** BEC classification determines treatment intensity (how much demand adjusts)
- **Primary estimand:** Differential import response between intermediate inputs and final consumption goods
- **Placebo population:** Capital goods (intermediate response expected by theory)
- **Design:** Product-level event study with continuous BEC-category treatment interaction (not staggered DiD — single sharp event)

## Power Assessment

- **Pre-treatment periods:** 6 years (2010-2015), or ~72 months with monthly data
- **Treated clusters:** ~97 HS2 chapters (clustering level)
- **Post-treatment periods:** 7 years (2017-2023)
- **Sample size:** ~65,000 product-year observations (annual); ~780,000 product-month (monthly)
- **MDE:** With 5,000 products and 13 years, well-powered for moderate effects (>5% differential)
