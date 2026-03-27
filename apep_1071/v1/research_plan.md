# Research Plan: apep_1071

## Research Question
Did Portugal's Golden Visa program (ARI, October 2012) cause existing dwelling prices to diverge from new dwelling prices, by channeling foreign investment overwhelmingly into the existing-housing segment?

## Identification Strategy
**Triple-difference (DDD):**
1. **Housing segment:** Existing vs. new dwellings (within-market variation)
2. **Country:** Portugal vs. Spain, Italy, Ireland (no comparable real estate golden visa 2012–2016)
3. **Time:** Pre-golden-visa (2008-Q1 to 2012-Q3) vs. post (2012-Q4 to 2019-Q4)

The identifying assumption: absent the Golden Visa, the existing–new dwelling price gap would have evolved similarly across Portugal and comparator countries. Testable with 16 pre-treatment quarters.

**Second natural experiment:** The February 2023 suspension of residential real estate from the Golden Visa provides a reversal test — if the mechanism is correct, the existing–new gap should begin to close after 2023.

## Expected Effects and Mechanisms
- **Primary:** Positive effect on existing dwelling prices relative to new dwellings in Portugal (relative to comparators). Golden Visa investors prefer existing dwellings because: (a) immediate availability for residency requirements, (b) prime urban locations, (c) established rental yields.
- **Mechanism test:** The 2023 suspension should attenuate the gap.
- **Magnitude:** The raw data shows a 67-point swing in Portugal's existing–new gap vs. -12.6 in Spain. The DDD estimate will isolate the causal component.

## Primary Specification
$$Y_{cdt} = \alpha + \beta_1 (\text{Portugal}_c \times \text{Existing}_d \times \text{Post}_t) + \gamma_{cd} + \delta_{ct} + \lambda_{dt} + \varepsilon_{cdt}$$

Where:
- $Y_{cdt}$: House Price Index for country $c$, dwelling type $d$, quarter $t$
- $\gamma_{cd}$: Country × dwelling-type fixed effects
- $\delta_{ct}$: Country × quarter fixed effects (absorbs all country-specific time shocks)
- $\lambda_{dt}$: Dwelling-type × quarter fixed effects (absorbs global existing-new trends)
- $\beta_1$: The DDD coefficient — the causal effect of Golden Visa on existing vs. new prices in Portugal

**Inference:** With only 4 country clusters, standard clustered SEs are unreliable. Will use:
1. Randomization inference (permuting the treatment assignment across countries)
2. Wild cluster bootstrap (Cameron, Gelbach, Miller 2008)
3. Report both RI p-values and conventional clustered SEs

## Robustness
1. **Pre-trends test:** Event-study DDD with quarterly leads
2. **Placebo treatments:** Test with pre-period fake treatment dates
3. **Leave-one-out:** Drop each comparator country in turn
4. **2023 reversal:** Test whether gap attenuates post-suspension
5. **Exclude COVID:** Restrict to pre-2020 to avoid pandemic confounding

## Data Source and Fetch Strategy
- **Source:** Eurostat `prc_hpi_q` (House Price Index, quarterly)
- **Access:** REST API, no authentication required
- **Variables:** HPI by dwelling type (DW_NEW, DW_EXST), 2015=100 base
- **Countries:** Portugal (PT), Spain (ES), Italy (IT), Ireland (IE)
- **Period:** 2005-Q1 to 2025-Q3 (83 quarters)
- **Observations:** ~664 (2 types × 4 countries × 83 quarters)
