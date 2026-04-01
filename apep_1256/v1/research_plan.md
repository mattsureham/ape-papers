# Research Plan: apep_1256

## Research Question

Does electing a donor-funded mayor cause a system-level shift in municipal procurement from competitive to discretionary modalities? The distinction between individual contract favoritism and institutional capture has profound implications for anti-corruption policy design.

## Identification Strategy

**Close-election RDD** on 2019 Colombian mayoral vote margins. Treatment variable: donor funding intensity = share of winning candidate's reported income from external donors (Cuentas Claras).

**Difference-in-discontinuity** design: Quarterly panel (Q1 2019 – Q4 2022) centered on inauguration (Q1 2020). Compare procurement composition shifts in municipalities where high-donor-funded candidates barely won vs. barely lost.

**Running variable:** Vote margin = (winner votes – runner-up votes) / total valid votes. Treatment = winner has above-median donor share among close races.

**Key assumption:** Near the threshold, whether a donor-funded candidate barely wins or barely loses is quasi-random.

## Expected Effects and Mechanisms

**Primary hypothesis:** Donor-funded mayors shift procurement toward contratación directa (direct award), increasing discretionary share by 5-15 pp.

**Mechanisms:**
1. *Institutional capture*: Donor-funded mayors systematically restructure procurement rules to favor discretion
2. *Contract splitting*: More numerous, smaller contracts to stay below competitive thresholds
3. *Contractor concentration*: Higher Herfindahl index indicating fewer, favored contractors
4. *Crowding out competition*: Higher single-bidder share in remaining competitive processes

**Null interpretation:** If no system-level shift, corruption operates through individual steering within existing rules (consistent with Gulzar et al. 2022).

## Primary Specification

Y_{it} = α + τ × D_i × Post_t + f(margin_i) × Post_t + γ_i + δ_t + ε_{it}

Where:
- Y_{it}: share of procurement spending via contratación directa in municipality i, quarter t
- D_i: indicator for high-donor-funding winner (above-median external donor share)
- Post_t: indicator for post-inauguration (Q1 2020+)
- f(margin_i): RD polynomial in vote margin, interacted with Post_t
- γ_i, δ_t: municipality and quarter fixed effects

Bandwidth: Optimal CCT bandwidth on margin; robustness to ±5pp, ±10pp, ±15pp.

## Data Sources

1. **SECOP II** (Colombian public procurement): Socrata dataset `jbjy-vk9h` at datos.gov.co
   - 5.6M records, includes modality, value, municipality, contractor, dates
   - No authentication needed (Socrata SODA API)

2. **Cuentas Claras 2019** (Campaign finance): CNE disclosure at datos.gov.co
   - 188K records, 4,918 candidates, 16,679 donors, 1,020 municipalities
   - Fields: candidate, municipality, income source, amount, donor type
   
3. **2019 election results**: Registraduría/datos.gov.co for vote margins

## Fetch Strategy

1. Query Cuentas Claras for 2019 Alcaldía races → compute donor funding intensity per candidate-municipality
2. Query election results → compute vote margins per municipality
3. Query SECOP II for territorial contracts 2019-2022 → compute quarterly modality shares per municipality
4. Merge on municipality code (DIVIPOLA)

## Robustness Battery

- Bandwidth sensitivity (CCT, ±5pp, ±10pp, ±15pp)
- Polynomial order (local linear, local quadratic)
- Placebo threshold tests (0 margin with fake treatment)
- McCrary density test
- Pre-period balance (Q1-Q4 2019 procurement composition)
- Donut-hole RDD (exclude ±1pp)
- Placebo outcome: infrastructure spending composition (should not change)
