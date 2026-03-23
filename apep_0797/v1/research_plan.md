# Research Plan: The Tradability Tax — ECOWAS Sanctions and Food Market Fragmentation in Niger

## Research Question
Do trade sanctions fragment food markets by differentially inflating prices of imported versus locally produced commodities? We exploit the ECOWAS sanctions on Niger following the July 2023 coup to estimate the "tradability tax" — the excess price increase borne by consumers dependent on imported staples (rice) relative to those consuming locally produced grains (millet, sorghum).

## Identification Strategy
**Triple-difference design** exploiting three sources of variation:
1. **Country**: Niger (sanctioned) vs. Burkina Faso (unsanctioned ECOWAS member)
2. **Commodity**: Imported/tradable (rice) vs. locally produced (millet, sorghum)
3. **Time**: Pre-sanctions (Jan 2021 – Jul 2023) vs. post-sanctions (Aug 2023 – Dec 2024)

**Primary specification:**
```
P_{m,c,t} = α_{mc} + λ_{ct} + γ_{mt} + β · (Niger_m × Tradable_c × Post_t) + ε_{mct}
```

Where:
- `m` = market, `c` = commodity, `t` = month
- `α_{mc}` = market-commodity fixed effects (absorb level differences)
- `λ_{ct}` = commodity-time fixed effects (absorb global commodity trends)
- `γ_{mt}` = market-time fixed effects (absorb local inflation)
- `β` = the tradability tax (treatment effect)

**Key identifying assumption:** Absent ECOWAS sanctions, the rice-millet price gap in Niger markets would have evolved similarly to the rice-millet gap in Burkina Faso markets.

## Expected Effects and Mechanisms
- **Primary:** Large positive β — imported rice prices spike relative to local millet in Niger vs. Burkina Faso. Magnitude: ~25-30% based on raw price movements (+32% rice vs +5% millet).
- **Mechanism 1 — Border closure channel:** Rice is imported via Nigeria corridor; border closure directly restricts supply.
- **Mechanism 2 — Market integration breakdown:** Price dispersion across Niger's internal markets should increase for rice (fragmented supply) but not millet (local production unaffected).
- **Mechanism 3 — Partial reversal:** Sanctions partially lifted Feb 2024; we expect price convergence, providing a natural reversal test.

## Primary Specification
- **Estimator:** OLS with high-dimensional fixed effects (fixest::feols in R)
- **Clustering:** Two-way at market and month level (or market-commodity)
- **Heterogeneity:** Border proximity (markets near Nigeria border vs. interior), market size
- **Robustness:** (1) Cowpeas as additional local placebo; (2) Pre-trends event study; (3) Market-level price dispersion as secondary outcome; (4) Permutation inference

## Data Source and Fetch Strategy
**Primary:** WFP VAM (Vulnerability Analysis and Mapping) food price data
- API endpoint: `https://data.humdata.org/` (HDX) — WFP food prices dataset
- Alternative: Direct WFP API or bulk CSV downloads from HDX
- Coverage: 35+ markets in Niger, 40+ in Burkina Faso; monthly; 2005-present
- Commodities: Rice, millet, sorghum, cowpeas, oil

**Fetch approach:**
1. Download WFP food price CSVs from HDX (Niger country code: NER, Burkina Faso: BFA)
2. Filter to 2021-2024 study period
3. Keep key commodities: rice (treated), millet/sorghum/cowpeas (control)
4. Validate market coverage and temporal completeness
