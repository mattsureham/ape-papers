# Research Plan: The Capitalization of Reproductive Rights

## Research Question

Does the loss of reproductive rights get capitalized into residential property values? Specifically, does the overnight activation of Missouri's trigger-law abortion ban (June 24, 2022) cause a measurable decline in home values on the Missouri side of the Missouri-Illinois border relative to the Illinois side?

## Identification Strategy

**Geographic Difference-in-Discontinuities (Butts 2021; Grembi, Nannicini & Troiano 2016)**

The Missouri-Illinois border in the St. Louis metropolitan area creates a sharp geographic discontinuity in reproductive policy after *Dobbs v. Jackson* (June 24, 2022). Missouri's trigger law imposed a total abortion ban overnight; Illinois's Reproductive Health Act (2019) codified abortion as a fundamental right.

The diff-in-disc estimand is:

τ = [lim_{x→0+} E[Y|x, Post=1] - lim_{x→0-} E[Y|x, Post=1]] - [lim_{x→0+} E[Y|x, Post=0] - lim_{x→0-} E[Y|x, Post=0]]

where x is signed distance to the state border (positive = Missouri/ban, negative = Illinois/protection).

This differences out:
1. Time-invariant MO-IL differences (pre-existing cross-border discontinuity)
2. Common time trends (monthly FEs)
3. Smooth spatial trends in property values

**Key identifying assumption:** The change in the border discontinuity in home values at Dobbs is driven by the abortion ban, not by coincident policies or shocks at the border.

## Expected Effects and Mechanisms

1. **Direct capitalization:** If reproductive rights are valued as an amenity, home values on the MO side should decline relative to IL side
2. **Tiebout sorting gradient:** Effects should be concentrated near the border where relocation costs are lowest
3. **State-level amenity vs. local amenity:** If uniform across MO, this is state-level valuation; if concentrated at border, this is Tiebout sorting

## Primary Specification

Panel diff-in-disc at ZIP-month level:

Y_{it} = μ_i + λ_t + τ · MO_i × Post_t + f(dist_i) × Post_t + ε_{it}

where μ_i = ZIP fixed effects, λ_t = month fixed effects, MO_i = Missouri indicator, Post_t = post-June 2022, f(dist_i) = polynomial in distance to border interacted with Post.

Standard errors clustered at ZIP level.

## Data Sources

1. **Zillow Home Value Index (ZHVI):** ZIP-level, monthly, all homes. ~26,000 ZIPs nationally, 223 in St. Louis MSA (CBSA 41180), 188 in Kansas City MSA (CBSA 28140).
2. **Census Gazetteer / ZCTA centroids:** Latitude and longitude for each ZIP code.
3. **Census ACS:** Tract-level demographics for covariate balance.
4. **HUD ZIP-CBSA crosswalk:** To identify MSA membership.

## Exposure and Affected Population

The treatment is Missouri's state-level abortion ban, which affects all residents. The treated population for the housing market outcome is homeowners and prospective buyers in Missouri ZIP codes. The Tiebout sorting mechanism requires that households who value reproductive access either discount Missouri properties or increase demand for Illinois properties, generating a relative price shift at the border. The key exposure consideration is that border communities have easy cross-state access to Illinois clinics (20-minute drive from many St. Louis ZIP codes), which may blunt the sorting incentive relative to interior Missouri communities far from protection-state clinics.

## Analysis Outline

1. Download and merge Zillow ZHVI with ZIP centroids
2. Filter to St. Louis MSA, compute signed distance to MO-IL border
3. Estimate diff-in-disc (panel and cross-sectional)
4. Event study by month (dynamic treatment effects)
5. Robustness: bandwidth sensitivity, placebo cutoffs, covariate balance
6. Replication at Kansas City border (MO-KS, where Kansas protected abortion via Aug 2022 referendum)
7. Heterogeneity: income quartiles, racial composition
