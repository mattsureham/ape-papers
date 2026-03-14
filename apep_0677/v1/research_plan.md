# Research Plan: Deforestation by Regulation

## Research Question

Does the EU Deforestation Regulation (EUDR, 2023/1115) reduce deforestation-linked commodity imports into Europe, or merely redirect them to unregulated destinations — particularly China?

## Policy Background

The EUDR entered into force June 29, 2023, prohibiting EU market placement of seven tropical commodities (cattle, cocoa, coffee, palm oil, rubber, soy, wood) linked to post-2020 deforestation. Enforcement was postponed to December 2026 via the "Stop the Clock" Directive (2025/794). Country risk classifications were announced May 2025 (140 low-risk, 50 standard-risk including Brazil and Indonesia, 4 high-risk).

Key timeline:
- November 2021: Commission proposal published
- June 2023: Regulation enters into force
- May 2025: Country risk classifications
- December 2026: Enforcement begins (large operators)

## Identification Strategy

**Triple-difference (DDD):**
1. **Commodity dimension:** 7 EUDR-regulated commodities vs 5 non-regulated close substitutes
2. **Destination dimension:** EU-27 imports vs non-EU destinations (China, India, US, other)
3. **Time dimension:** Pre-proposal (2018-2021) vs post-proposal/passage (2022-2024)

The DDD absorbs:
- Common shocks to all commodities (COVID, shipping costs) via commodity × time
- Common shocks to EU trade (EU demand) via destination × time
- Persistent commodity-destination trade patterns via commodity × destination

**Event study:** Quarterly event-study coefficients around:
- Q4-2021 (proposal)
- Q2-2023 (entry into force)

**Placebo tests:**
- Non-regulated commodities should show no EU→non-EU diversion
- Non-EUDR destinations (e.g., Japan, South Korea) used as additional controls

## Expected Effects

1. **Negative:** EU imports of regulated commodities decline post-EUDR relative to controls
2. **Positive:** Non-EU (especially China) imports of regulated commodities increase
3. **Net:** If global exports of regulated commodities are unchanged, pure diversion; if total exports decline, partial deterrence
4. **Mechanism:** Anticipatory compliance — firms redirect supply chains before enforcement

## Data Sources

**Primary:** UN Comtrade bilateral trade data (HS4/HS6)
- EUDR regulated: HS 0901 (coffee), 1201 (soybeans), 1511 (palm oil), 180100 (cocoa), 400110/400121 (rubber), 440399 (wood), 0102 (cattle)
- Controls: HS 0902 (tea), 0904 (pepper), 1513 (coconut oil), 2009 (fruit juice), 2401 (tobacco)
- 5 major exporters: Brazil, Indonesia, Colombia, Côte d'Ivoire, Malaysia
- ~163 destination countries, 2018-2024
- Access: Comtrade API with key (confirmed in .env)

**Secondary:** Eurostat ext_lt_maineu (EU trade validation)

## Primary Specification

```
ln(Trade_cdt) = α + β₁(Regulated_c × EU_d × Post_t) + γ(Commodity × Destination FE)
                + δ(Commodity × Time FE) + η(Destination × Time FE) + ε_cdt
```

Where:
- c = commodity, d = destination, t = year-quarter
- Regulated_c = 1 for EUDR commodities
- EU_d = 1 for EU-27 destinations
- Post_t = 1 for Q4-2021+ (proposal) or Q3-2023+ (passage)
- β₁ is the DDD coefficient: differential change in EU-destined regulated commodity trade

Clustering: two-way at commodity and destination level.

## Outcomes

1. **Trade value** (ln USD): Primary
2. **Trade quantity** (ln kg): Secondary (rules out price effects)
3. **EU import share** of each commodity-exporter pair
4. **China/non-EU import share** (mirror of EU share)

## Robustness Checks

1. Alternative post-period: proposal (2021) vs entry-into-force (2023)
2. Drop individual commodities one at a time (leave-one-out)
3. Exporter-level heterogeneity: Brazil/Indonesia (standard-risk) vs others
4. Synthetic DDD: permute commodity treatment assignment
5. Intensive vs extensive margin: new trade relationships vs existing ones
