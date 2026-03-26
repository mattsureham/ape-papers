# Research Plan: Throwing Away the Throwbacks

## Research Question

Does the EU Landing Obligation (Regulation 1380/2013, Article 15) reduce discards and improve fisheries sustainability, or does it primarily reduce total catches through choke-species constraints while relabeling remaining discards as landings?

## Policy Background

The EU Common Fisheries Policy (CFP) 2013 reform introduced a Landing Obligation requiring all catches of regulated species to be landed and counted against quotas, replacing the prior practice of discarding unwanted fish at sea. Implementation was phased by species group:

- **January 2015:** Pelagic species (mackerel, herring, sprat, horse mackerel)
- **January 2016:** Demersal species (cod, haddock, sole, hake, plaice, Norway lobster)
- **January 2017:** Remaining Baltic and Mediterranean species
- **January 2019:** All remaining regulated species

Exemptions exist for de minimis (up to 5% of total catch) and high-survivability species.

## Identification Strategy

**Staggered species-group DiD using Callaway-Sant'Anna (2021).**

- **Unit of observation:** Country × species-group × year
- **Treatment:** Landing Obligation activation, varying by species group (2015/2016/2017/2019)
- **Control:** Not-yet-treated species groups within the same country serve as within-country controls
- **Pre-treatment period:** 2000–2014 (14+ years for earliest cohort)
- **Post-treatment period:** Up to 2024 (5–9 years depending on cohort)

**Key identification assumption:** Absent the Landing Obligation, catch trends for pelagic and demersal species within the same country would have evolved in parallel. The 14-year pre-period allows extensive pre-trend testing.

**Placebo/robustness:**
1. Non-EU countries (Norway, Iceland) fishing the same ICES Area 27 waters — they face no Landing Obligation
2. Exempted species within treated groups as within-group placebo
3. HonestDiD sensitivity analysis for violation of parallel trends

## Expected Effects and Mechanisms

1. **Catch reduction (choke effect):** If binding quota constraints on bycatch species force vessels to stop fishing before exhausting target-species quotas, total catches should decline for mixed-fishery species groups (demersal) more than single-species fisheries (pelagic).

2. **Composition shift:** Landing Obligation should increase the share of previously-discarded species in total landings (mechanical relabeling effect) while potentially reducing high-value target species catches.

3. **Fleet restructuring:** Vessels may exit or shift gear types to reduce bycatch exposure. Fleet capacity (GT, kW) may decline in treated segments.

## Primary Specification

```
Y_{cgt} = α + Σ_k β_k × 1[t - G_g = k] + γ_{cg} + δ_{ct} + ε_{cgt}
```

Where:
- Y = log catches (tonnes), landing share, or fleet capacity
- c = country, g = species group, t = year
- G_g = year species group g first treated
- γ_{cg} = country × species-group fixed effects
- δ_{ct} = country × year fixed effects (absorbs country-level shocks)
- Clustering: country level (conservative, ~25 clusters)

## Outcomes

1. **Log total catches** (tonnes) by country × species group × year
2. **Landing-to-catch ratio** (landings / (landings + estimated discards)) from STECF
3. **Fleet capacity** (gross tonnage, engine power) by fleet segment
4. **Species composition** (Herfindahl index of species within group)

## Data Sources

1. **Eurostat `fish_ca_main`:** Catches by species, ICES area, country, year (2000–2024). ~32,000 rows. No API key.
2. **Eurostat `fish_ld_main`:** Landings by species, area, country, year.
3. **STECF Fleet Data Initiative (FDI):** Effort, landings, catches, discards (scientific observer estimates), capacity by country × species × gear (2013–2024). CSV from JRC.
4. **Eurostat `fish_fleet_gp`:** Fleet capacity (number, GT, kW) by country, year.

## Data Fetch Strategy

1. Use `eurostat` R package to pull `fish_ca_main` and `fish_ld_main` via Eurostat JSON API
2. Download STECF FDI data from JRC data portal (CSV)
3. Aggregate species into 4 treatment groups based on Landing Obligation phasing
4. Restrict to ICES Area 27 (Northeast Atlantic) for main analysis — this is where the LO primarily binds
5. Include Norway and Iceland as non-EU controls

## Key Risk

The main risk is that Eurostat catch data may not separately identify discards vs. landings at sufficient granularity, making it hard to distinguish genuine discard reduction from relabeling. The STECF FDI data has discard estimates from scientific observers but only from 2013 — limiting the pre-period for discard-specific outcomes to 2 years. Mitigation: use total catches as the primary outcome (long pre-period) and discard ratios as a mechanism test (shorter panel).
