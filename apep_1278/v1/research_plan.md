# Research Plan: The Compliance Lottery

## Research Question
Do VAT receipt lotteries — programs that incentivize consumers to request receipts by entering them into prize draws — reduce VAT compliance gaps? This paper exploits the staggered adoption (and cancellation) of receipt lottery programs across 10 EU member states between 2013 and 2021 to estimate the causal effect of consumer-as-auditor incentive mechanisms on tax compliance.

## Identification Strategy
**Staggered DiD with Callaway-Sant'Anna (2021)**, using never-treated EU member states as the comparison group.

- **Treated units (10):** Malta (1997), Slovakia (2013–2021), Portugal (2014), Romania (2015), Poland (2015–2017), Czech Republic (2017–2020), Greece (2017), Latvia (2019–2023), Lithuania (2019), Italy (2021)
- **Never-treated controls (17):** All other EU-27 member states
- **Cancellation reversals (3):** Slovakia (Feb 2021), Czech Republic (Apr 2020), Poland (~Mar 2017) — if lotteries reduce the gap, cancellation should reverse the effect

The key identifying assumption is parallel trends in VAT compliance outcomes between adopters and non-adopters, conditional on country and year fixed effects. The staggered timing (spanning 2013–2021) and the cancellation reversals strengthen identification by providing within-country variation.

Note: Malta (1997) will be excluded from the main Callaway-Sant'Anna analysis as it was treated before the panel begins (2000), but will be used as an always-treated robustness check.

## Expected Effects and Mechanisms
- **Primary mechanism:** Consumer-as-auditor (Gordon 1990). Lottery prizes incentivize consumers to request receipts, creating a paper trail that makes it harder for merchants to underreport sales.
- **Expected direction:** Negative effect on VAT gap (reduced non-compliance). Magnitude: Naritomi (2019, AER) found 22% revenue increase in São Paulo for new tax registrants.
- **Heterogeneity:** Effects should be larger in countries with larger baseline gaps (higher scope for compliance improvement) and in sectors with more cash transactions (retail, hospitality).

## Primary Specification
```
Y_{it} = α_i + γ_t + β × Lottery_{it} + ε_{it}
```
Where Y_{it} is the VAT gap (% of VTTL) or VAT revenue/GDP ratio for country i in year t. Using Callaway-Sant'Anna group-time ATT estimates aggregated to an overall ATT with not-yet-treated and never-treated as comparison groups.

## Exposure Alignment
Treatment (receipt lottery activation) is assigned at the country-year level — the same level as the outcome (VAT compliance gap). All businesses and consumers within a treated country are exposed to the lottery incentive. There is no sub-national variation in lottery availability within countries, so the treatment level matches the outcome level exactly. Cross-border shopping spillovers could attenuate effects if consumers in non-lottery countries shop in lottery countries (or vice versa), but intra-EU VAT is assessed at the point of sale, making this a second-order concern.

## Robustness
1. **Cancellation reversal test:** Separate event study around cancellation dates
2. **Wild cluster bootstrap:** With 27 clusters, supplement analytical SEs
3. **HonestDiD sensitivity:** Rambachan-Roth bounds for pre-trend violations
4. **Placebo outcomes:** Government spending categories unrelated to VAT (e.g., property tax revenue)
5. **Leave-one-out:** Drop each treated country iteratively

## Data Sources and Fetch Strategy
1. **VAT Gap (primary outcome):** EC/CASE VAT Gap reports (2000–2022). Published as PDF/Excel appendices by DG TAXUD. Will extract country-year panel of VAT gap (% of VTTL).
2. **VAT Revenue (secondary outcome):** Eurostat `gov_10a_taxag` — tax by main national accounts aggregates. D211 = VAT revenue. Annual, 2005–2023.
3. **GDP (denominator):** Eurostat `nama_10_gdp` — GDP at current prices. Annual.
4. **Treatment timing:** Hand-coded from legislation review (dates in idea manifest, verified against EC reports).
