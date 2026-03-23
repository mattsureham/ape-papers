# Research Plan: Carbon Border Deflection

## Research Question
Does the EU's Carbon Border Adjustment Mechanism (CBAM) deflect high-carbon metal exports from major producers (China, India, Turkey, etc.) away from the EU toward non-CBAM markets (US, Japan, UK)? If so, unilateral carbon border pricing may simply rearrange global trade flows rather than reducing global emissions — a beggar-thy-neighbor externality.

## Identification Strategy
**Triple-difference (DDD):**

1. **First difference (time):** Pre-CBAM (Jan 2020 – Sep 2023) vs Post-CBAM (Oct 2023 – Dec 2024)
2. **Second difference (destination):** EU27-bound flows vs non-EU-bound flows (US, Japan, UK)
3. **Third difference (product):** CBAM-covered products (HS 72 iron/steel, HS 76 aluminum) vs uncovered products (HS 73 articles of iron/steel, HS 7604-7616 aluminum articles)

**Key identification assumptions:**
- Absent CBAM, covered and uncovered products would have evolved similarly across EU and non-EU destinations (triple parallel trends)
- No other product×destination-specific shock coincides with Oct 2023

**Placebo tests:**
- Uncovered products (HS 73) should show zero deflection
- Non-metal CBAM products (cement, fertilizer, electricity) face CBAM but different trade logistics — separate check
- Pre-period placebo treatment dates

**Dose-response:**
- Deflection should be monotonic in exporter carbon intensity (World Steel Association: CN ~1.8, IN ~2.0, JP ~1.0 tCO2/t crude steel)

## Expected Effects
- β(EU, covered) < 0: CBAM reduces covered imports into EU
- β(non-EU, covered) > 0: Deflection to non-CBAM destinations
- β(non-EU, uncovered) ≈ 0: No deflection for uncovered products
- Dose-response: Higher carbon-intensity exporters show larger deflection

## Primary Specification
```
log(trade_ijk_t) = α + β₁(Post_t × EU_j × Covered_k) + β₂(Post_t × EU_j) + β₃(Post_t × Covered_k)
                   + γ_{ij} + δ_{ik} + θ_{jk} + μ_t + ε_{ijk_t}

Where:
- i = exporter, j = destination, k = product, t = month
- Post_t = 1 if t ≥ October 2023
- EU_j = 1 if destination is EU27
- Covered_k = 1 if CBAM-covered (HS 72, 76)
- Fixed effects: exporter×destination, exporter×product, destination×product, month
```

SE clustered at exporter×destination level (32 clusters).

## Data Sources
1. **UN Comtrade** (primary): Bilateral monthly trade, HS 4-digit, via `comtradr` R package or direct API
2. **Eurostat Comext** (validation): EU27 imports, monthly, HS codes
3. **World Steel Association**: Carbon intensity by country

## Sample
- **Exporters:** CN, IN, TR, RU, UA, VN, TW, BR (8 major metal exporters)
- **Destinations:** EU27, US, JP, UK (4)
- **Products:** HS 72, 73, 76 at 2-digit; possibly 4-digit subcodes
- **Period:** Jan 2020 – Dec 2024 (60 months: 45 pre, 15 post)
- **Expected N:** ~7,680 exporter×destination×product×month observations

## Risks and Mitigations
| Risk | Mitigation |
|------|-----------|
| Russia/Ukraine war disrupts steel trade | Include exporter×time FE; robustness excluding RU/UA |
| US Section 232 steel tariffs | Absorbed by destination×product FE; robustness excluding US |
| China VAT export rebate changes (Oct 2021) | Absorbed by exporter×time FE |
| COVID disruption 2020-2021 | Start pre-period from 2021; robustness with 2022+ only |
| Comtrade data lag | Check coverage through Dec 2024 |
