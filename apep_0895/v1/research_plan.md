# Research Plan: Does AML Regulation Actually Detect Money Laundering?

## Research Question

Does the EU's 5th Anti-Money Laundering Directive (5AMLD, 2018/843) increase detection of money laundering offences? By exploiting staggered transposition across 22 EU member states (January 2019 – February 2021), we estimate the causal effect of enhanced AML requirements on police-recorded money laundering offences and examine whether the effect reflects improved detection or merely relabeling.

## Identification Strategy

**Staggered Difference-in-Differences** using Callaway and Sant'Anna (2021) estimator.

- **Treatment:** National transposition date of 5AMLD, obtained from CELLAR SPARQL (notification_date of national implementing measures).
- **Treatment timing:** 9 countries transposed before the January 10, 2020 deadline; 13 after (through February 2021). This 2-year window provides clean staggered variation.
- **Unit of observation:** Country × year.
- **Outcome:** Police-recorded money laundering offences (Eurostat crim_off_cat, ICCS code 07041).

**Key identification assumptions:**
1. Parallel trends in money laundering offences absent 5AMLD transposition.
2. No anticipation effects (offence recording responds to legal implementation, not announcement).
3. Treatment timing exogenous to crime trends (driven by legislative capacity, not crime).

## Expected Effects and Mechanisms

**Detection hypothesis (positive effect):** Enhanced beneficial ownership transparency and expanded due diligence requirements increase suspicious activity reports → more police-recorded offences. Expected SDE: +0.05 to +0.15 (moderate positive).

**Deterrence hypothesis (negative effect):** Heightened regulatory scrutiny deters money laundering activity → fewer actual crimes. Expected SDE: −0.05 to −0.15 (moderate negative).

**Relabeling hypothesis (null on detection, positive on specific):** Transposition merely reclassifies existing financial crimes as money laundering. Testable via placebo on unrelated crime categories.

## Primary Specification

$$Y_{it} = \alpha_i + \gamma_t + \beta \cdot \text{Post}_{it} + \varepsilon_{it}$$

Estimated via Callaway-Sant'Anna (2021) with:
- Group-time ATTs aggregated to overall ATT
- Never-treated or not-yet-treated as comparison group
- Clustering at country level

**Continuous treatment variant:** Months of transposition delay as treatment intensity.

## Exposure Alignment

The treatment — national transposition of the 5AMLD — directly affects all financial institutions, virtual currency providers, and beneficial ownership registries within the transposing country. Police-recorded money laundering offences capture offences recorded by national police forces within that same jurisdiction. The unit of observation (country-year) aligns with the unit of treatment assignment (country) and the unit of outcome measurement (country). There is no exposure mismatch: a country that transposes the directive in year t sees its entire financial sector subject to new AML obligations from that year forward, and the crime statistics for that country-year reflect offences recorded under the new regime.

Potential cross-border spillovers (criminals shifting activity to not-yet-transposed countries) would bias estimates toward finding an effect in early transposers (increased detection) and decreased offences in late transposers. The null result is thus unlikely to be explained by spillover contamination.

## Robustness and Diagnostics

1. **Pre-trend event study:** Group-time ATT plots for 3+ pre-periods
2. **Placebo outcomes:** Property crimes (ICCS 0501), assault (ICCS 0201) — should show no effect
3. **Leave-one-out:** Drop each country sequentially to check sensitivity
4. **Umbrella legislation exclusion:** Some countries transposed via omnibus bills — test excluding these
5. **Wild cluster bootstrap:** Address finite-cluster inference (22 countries)
6. **HonestDiD/Rambachan-Roth:** Sensitivity to violations of parallel trends

## Secondary Outcomes

1. **House price index** (Eurostat prc_hpi_a): Real estate is a primary money laundering channel. If AML works, suspicious real estate transactions should decline → house price effects.
2. **Financial sector employment** (Eurostat lfst_r_lfe2en2, NACE K): Compliance burden creates jobs in financial services.

## Data Sources

| Source | Dataset | Variables | Access |
|--------|---------|-----------|--------|
| CELLAR SPARQL / eurlex | NIMs for 32018L0843 | Transposition dates by country | Open, no key |
| Eurostat | crim_off_cat (ICCS07041) | Money laundering offences | Open, no key |
| Eurostat | crim_off_cat (ICCS0501, ICCS0201) | Placebo crime outcomes | Open, no key |
| Eurostat | prc_hpi_a | House price index | Open, no key |
| Eurostat | lfst_r_lfe2en2 | Employment by NACE sector | Open, no key |

## Fetch Strategy

1. Use `eurlex` R package to query CELLAR SPARQL for 5AMLD national implementation measures
2. Use `eurostat` R package to download crime statistics, house prices, and employment
3. Merge on country code (ISO 2-letter ↔ Eurostat geo codes)
4. Panel: ~22 countries × 7-8 years (2015–2022)
