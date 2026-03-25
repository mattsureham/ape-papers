# Research Plan: The Product-Scope Loophole — CBAM's Downstream Leakage in EU Metal Imports

## Research Question

Does the EU Carbon Border Adjustment Mechanism's product-scope boundary — covering raw metals (HS 72, HS 7601–7603) but exempting downstream articles (HS 73, HS 7604–7616) — induce trade diversion from covered to uncovered product codes, particularly among high-carbon-intensity exporters?

## Identification Strategy

**Triple-Difference (DDD):**

Y_{pct} = β(Covered_p × HighCarbon_c × Post_t) + ProductxTime FE + PartnerxTime FE + ProductxPartner FE + ε_{pct}

- **Product dimension:** CBAM-covered HS 4-digit codes (HS 72xx: iron/steel; HS 7601–7603: unwrought aluminum) vs. exempt downstream codes (HS 73xx: articles of iron/steel; HS 7604–7616: aluminum articles). Same material base, different processing stage — the regulatory boundary is sharp.
- **Partner dimension:** High-carbon exporters (China, India, Turkey: ~1.5–2.0 tCO2/t steel) vs. low-carbon exporters (Japan, South Korea: ~0.8–1.2 tCO2/t). High-carbon partners face greater CBAM exposure.
- **Time dimension:** Pre-treatment (Jan 2020 – Sep 2023) vs. post-treatment (Oct 2023 – Dec 2024). Treatment = CBAM transitional phase start (Oct 1, 2023).

**Built-in placebos:**
1. Exempt products (HS 73) should show no differential decline — they serve as the product-level control
2. Low-carbon partners should show smaller responses — they face less CBAM exposure
3. Intra-EU trade should show no response — CBAM applies only to extra-EU imports

## Expected Effects

- **Primary:** Decline in EU imports of covered raw metals (HS 72) from high-carbon partners, relative to exempt downstream articles (HS 73) from the same partners
- **Mechanism:** Exporters shift processing upstream, converting raw materials to articles before shipping to avoid CBAM reporting/charges
- **Sign prediction:** β < 0 (covered × high-carbon × post = relative decline in covered imports)
- **Magnitude prior:** Based on smoke test, China HS72 fell 19% while HS73 rose 9% — expecting moderate-to-large SDE

## Primary Specification

```
log(imports_value_{pct}) = β(Covered_p × HighCarbon_c × Post_t)
                         + γ_{pt} + δ_{ct} + μ_{pc} + ε_{pct}
```

Where p = HS 4-digit product, c = partner country, t = month-year. Cluster SEs at product×partner level.

## Data Source and Fetch Strategy

**Primary:** UN Comtrade API (v2) — HS 4-digit level imports
- Reporter: EU-27 (aggregate) or individual large EU importers (Germany, Italy, France)
- Partners: CN, IN, TR, RU, UA, VN, TW, BR (high-carbon); JP, KR (low-carbon)
- Products: HS 72xx, 73xx, 76xx at 4-digit level
- Period: 2020–2024, annual frequency (monthly if available)
- Variables: Import value (USD), import quantity (kg)

**Secondary:** Eurostat industrial production (sts_inpr_m) for EU domestic C24 metals — to check whether import shifts reflect production substitution.

**Fallback:** If Comtrade monthly unavailable, use annual data with quarterly Eurostat Comext bulk files.
