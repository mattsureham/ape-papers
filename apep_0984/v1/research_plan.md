# Research Plan: The Deterrence Dividend

## Research Question

When palladium prices tripled between 2019 and 2021, catalytic converter thefts surged 1,632% — from 3,721 insurance claims to 64,433. Thirty-two states rushed to pass anti-theft laws. But prices then collapsed 66% by 2024. **Who deserves credit for the subsequent decline in theft — legislators or the market?**

This paper decomposes the decline in catalytic converter theft into a **price effect** (commodity prices reduce criminal incentives per Becker 1968) and a **deterrence dividend** (the additional crime reduction attributable to legislation beyond what price movements alone predict). We exploit staggered state adoption of anti-theft laws (2021–2024) using Callaway and Sant'Anna (2021) difference-in-differences, interacted with palladium price variation.

## Identification Strategy

**Primary:** Staggered DiD (Callaway-Sant'Anna 2021) across 32+ states that adopted catalytic converter anti-theft laws at different times between 2021 and 2024.

**Commodity price decomposition:** Include state × palladium-price interactions to separate:
- (a) **Price effect:** Mechanical decline in theft as palladium value drops
- (b) **Law effect:** Deterrence holding prices constant
- (c) **Interaction:** Do laws bind more when criminal incentives (prices) are high?

**Key identification assumption:** Conditional on state and time fixed effects, the timing of law adoption is uncorrelated with state-specific trends in catalytic converter theft. Early adopters (TX June 2021, before price peak) provide the cleanest test.

**Built-in placebo:** Other property crimes (burglary, shoplifting, non-automotive larceny) should not respond to catalytic converter anti-theft laws.

## Expected Effects and Mechanisms

1. **Negative price effect on theft:** Higher palladium prices → more theft (Becker 1968 prediction). As prices fall, theft declines mechanically.
2. **Negative law effect (deterrence):** Laws that enhance penalties, regulate scrap dealers, and require documentation should reduce theft beyond what prices predict.
3. **Positive interaction:** Laws may be more effective when prices (and thus criminal incentives) are high — the "deterrence dividend" is largest when it costs the most to steal.

## Primary Specification

```
Y_{st} = α_s + α_t + β₁ · Law_{st} + β₂ · log(Palladium_t) + β₃ · Law_{st} × log(Palladium_t) + X_{st}γ + ε_{st}
```

Where:
- Y_{st} = catalytic converter theft rate (or property crime proxy) in state s, period t
- Law_{st} = indicator for anti-theft law in effect
- Palladium_t = monthly average palladium price
- X_{st} = state-level controls (unemployment, population, policing expenditure)

Plus Callaway-Sant'Anna group-time ATT estimates for the law effect.

## Data Sources

1. **Palladium prices:** Yahoo Finance (PA=F futures), monthly 2016–2026. Already smoke-tested: 103 obs, peak $2,958 April 2021, trough $993 Jan 2024.

2. **Crime data — Primary:** FBI Crime Data Explorer API (NIBRS offense-level data by state). Offense type: "Theft of Motor Vehicle Parts or Accessories." Fallback: FBI UCR estimated property crime by state-year (Table 5, Crime in the United States).

3. **Law adoption dates:** NCSL Catalytic Converter Theft Prevention Laws tracker + individual state legislative records. 32+ states confirmed.

4. **Controls:** BLS LAUS (unemployment by state-month), Census population estimates, UCR police employment data.

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| NIBRS data access | Fallback to UCR aggregate larceny-theft; Google Trends proxy |
| Short post-treatment for late adopters | Focus on early adopters (2021–2022) with 2+ years post |
| COVID confound (2020–2021) | Drop 2020; use other property crimes as placebo |
| Law heterogeneity (penalties vs. dealer regs) | Decompose by law type in robustness |
| Few pre-treatment periods for early adopters | Use 2016–2020 as pre-period (4+ years) |
