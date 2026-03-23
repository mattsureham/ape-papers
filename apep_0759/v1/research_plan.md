# Research Plan: Simplified to Compete

## Research Question

Does simplifying federal procurement procedures increase competition, reduce costs, and accelerate contract awards? We exploit the August 2020 increase in the Simplified Acquisition Threshold (SAT) from $150,000 to $250,000 — shifting ~75,000 contracts per year from full-and-open competition to Simplified Acquisition Procedures.

## Identification Strategy

**Difference-in-differences with a band treatment.**

- **Treated band:** Contracts valued $150K–$250K (shifted from full-and-open to simplified procedures)
- **Control below:** $50K–$150K (already simplified pre-reform — no procedure change)
- **Control above:** $250K–$500K (still full-and-open post-reform — no procedure change)
- **Pre-period:** FY2015–FY2020 (6 fiscal years)
- **Post-period:** FY2021–FY2024 (4 fiscal years)

The identifying assumption: absent the SAT increase, contract outcomes in the $150K–$250K band would have trended parallel to the control bands. We validate this with:
1. Pre-trend tests (event study)
2. Placebo thresholds at $100K and $200K
3. Excluding COVID-coded contracts (DEFC codes L–P)
4. Donut exclusion around $150K and $250K boundaries (manipulation test)

## Expected Effects and Mechanisms

**Theoretical ambiguity (the puzzle):** Standard procurement theory (Bulow & Klemperer 1996) predicts more competition → lower prices. But simplified procedures reduce compliance costs, potentially attracting more bidders. Two competing channels:

1. **Compliance cost channel:** Simplified procedures lower entry barriers → more offers → lower prices, faster awards
2. **Oversight reduction channel:** Less documentation → less accountability → higher costs, more sole-source

Which channel dominates is an empirical question with $30B/year at stake.

**Expected direction:** The compliance cost channel likely dominates for the treated band (moderate-value contracts where documentation costs are proportionally high). We expect:
- More offers received (positive)
- Faster award timelines (negative days)
- Small business share: ambiguous (mandatory set-aside expands, but simplified procedures may attract larger firms)
- Cost growth: ambiguous (less oversight vs. more competition)

## Primary Specification

$$Y_{ijt} = \alpha + \beta \cdot \text{Treated}_i \times \text{Post}_t + \gamma_j + \delta_t + X'_{it}\theta + \varepsilon_{ijt}$$

Where:
- $i$ = individual contract
- $j$ = NAICS sector (or agency)
- $t$ = fiscal year-quarter
- $\text{Treated}_i$ = 1 if contract obligation in $150K–$250K band
- $\text{Post}_t$ = 1 if FY2021+
- $\gamma_j$ = NAICS (or agency) fixed effects
- $\delta_t$ = fiscal year-quarter fixed effects
- $X_{it}$ = contract-level controls (pricing type, set-aside status, place of performance)

Clustering: two-way by NAICS sector and fiscal year-quarter.

## Data Source and Fetch Strategy

**Primary:** USAspending.gov bulk award data (FPDS-NG contracts)
- Endpoint: `https://api.usaspending.gov/api/v2/search/spending_by_award/`
- Also: bulk download files from `https://files.usaspending.gov/`
- Fields needed: total_obligation, number_of_offers_received, solicitation_procedures, extent_competed, date_signed, period_of_performance_start_date, naics, type_set_aside, awarding_agency, funding_agency, disaster_emergency_fund_codes
- Sample: All definitive contracts ($50K–$500K), FY2015–FY2024
- Expected N: ~2,000,000+ contracts

**Strategy:** Use bulk download files (one per fiscal year per agency) for complete coverage. The API has pagination limits; bulk files give full extracts. Download FY2015–FY2024 contract data, filter to $50K–$500K obligation range.

## Key Outcomes

| Outcome | Variable | Source Field |
|---------|----------|-------------|
| Competition intensity | Number of offers received | `number_of_offers_received` |
| Extent competed | Categorical: full, partial, not competed | `extent_competed` |
| Award speed | Days from solicitation to award | `date_signed` - `solicitation_date` |
| Cost growth | Final obligation / initial award | `total_obligation` / `base_and_all_options_value` |
| Small business share | Indicator for SB set-aside award | `type_set_aside` |
