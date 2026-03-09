# Initial Research Plan: Do Export Controls Have Teeth?

## Research Question
Do targeted export controls effectively reduce the rerouting of sanctioned dual-use technology to Russia through transit countries? Specifically, did the Common High Priority Items List (CHPL) — designating 50 HS6 product codes found in Russian weapons systems — reduce circumvention of Western sanctions?

## Identification Strategy
**Triple-difference (DDD):**
1. **Time:** Pre-sanctions (2015-2021) vs. post-sanctions/pre-enforcement (2022-May 2023) vs. post-CHPL enforcement (2024)
2. **Product:** CHPL-listed HS6 codes (50 products found in Russian weapons) vs. non-CHPL sanctioned products in the same HS2 chapters (built-in placebo)
3. **Geography:** Transit countries (Kyrgyzstan, Kazakhstan, Armenia, Georgia, Turkey, UAE) vs. neutral non-sanctioning comparators with low historical Russia trade

**Key estimand:** β_CHPL×Post-enforcement — the differential change in rerouting for CHPL-targeted products relative to non-CHPL sanctioned goods after enforcement began.

## Expected Effects and Mechanisms
- **Sanctions effect (2022):** Massive increase in transit-country exports of dual-use tech to Russia, as Western supply chain reroutes through intermediaries. Expected β > 0.
- **CHPL enforcement effect (2023-2024):** Targeted decline in CHPL product rerouting as enforcement identifies and disrupts specific supply chains. Expected β_CHPL < 0.
- **Displacement mechanism:** Rerouting may shift from CHPL products to close substitutes or from highly-monitored transit countries (Turkey, UAE) to less-monitored ones (Georgia, Armenia).
- **Sanctions leakage rate:** Fraction of pre-sanctions Western tech exports to Russia reconstituted through rerouting.

## Primary Specification
$$\log(Trade_{cpt} + 1) = \alpha + \beta_1 (Transit_c \times Post2022_t) + \beta_2 (Transit_c \times CHPL_p \times Post2022_t) + \beta_3 (Transit_c \times CHPL_p \times PostCHPL_t) + \gamma_{cp} + \delta_{pt} + \mu_{ct} + \varepsilon_{cpt}$$

Where:
- c = country, p = HS6 product, t = year
- γ_cp = country × product FE
- δ_pt = product × year FE
- μ_ct = country × year FE
- β_3 is the key parameter: CHPL enforcement effect on transit-country rerouting

## Data Sources
1. **UN Comtrade** (public API): Annual bilateral trade at HS6 level, 2015-2024
2. **CHPL product list** (EU PDF): 50 HS6 codes from weapons forensics
3. **EU sanctions regulations** (EUR-Lex): Full sanctioned product universe for control group construction

## Planned Robustness Checks
1. **Intensive margin:** Restrict to country×product pairs with positive pre-sanctions trade
2. **Poisson PPML:** Address zero-trade observations without log(x+1) transformation
3. **Leave-one-country-out:** Drop each transit country to test sensitivity
4. **Product substitution test:** Check if non-CHPL products spike after CHPL enforcement (displacement)
5. **Mirror statistics validation:** Cross-check importer vs exporter reports where both available
6. **Alternative control groups:** Use different sets of neutral countries
7. **Event study:** Pre-trends test using 2015-2021 data with placebo treatment dates

## Power Assessment
- CHPL products: 50 HS6 codes
- Transit countries: 6-15 countries
- Years: 10 (2015-2024), including 7 pre-treatment
- Control products: ~200+ non-CHPL sanctioned products in same HS2 chapters
- Variation observed: 2,300x increases (Kyrgyzstan HS 8542), 91-100% declines after CHPL
- MDE: With this variation magnitude, statistical significance is virtually assured. The concern is identification, not power.
