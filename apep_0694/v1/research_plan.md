# Research Plan: Pulling Construction Forward or Creating It?

## Research Question

Did Australia's HomeBuilder grant ($25,000 for new builds under $750,000, June 2020–March 2021) genuinely stimulate housing construction, or merely shift building approvals forward in time? What was the fiscal cost per additional dwelling?

## Identification Strategy

**Strategy 1 — Interrupted Time Series (Primary):** The HomeBuilder grant had a sharp start (June 4, 2020) and sharp phase-down (January 1, 2021 → $15,000), then end (March 31, 2021). Monthly ABS building approval data (2018–2024) identifies the program effect through:
- Level shift during the program window (Jun 2020 – Mar 2021)
- "Hangover" effect: post-program approvals falling below the pre-program trend
- Net additionality = program surge minus post-program shortfall

**Strategy 2 — Cross-region DiD:** The $750,000 price cap binds differentially across Greater Capital City Statistical Areas (GCCSAs). In Sydney/Melbourne (median house price >$750K), the cap excludes most new builds. In Perth/Adelaide/Brisbane (median <$500K), the cap is non-binding. Treatment intensity = share of new builds below $750K.

**Strategy 3 — Within-region placebo:** Houses (eligible, <$750K) vs. apartments/other residential (ineligible, typically corporate-developed above cap). Apartments serve as a within-GCCSA control.

## Expected Effects and Mechanisms

- **Intertemporal substitution:** Builders and buyers accelerate decisions to capture the grant. Expect large positive effect during program, followed by "hangover" — approvals falling below trend.
- **Genuine demand creation:** Grant pushes marginal buyers into market who would not have built otherwise. Hangover is smaller than surge.
- **Net additionality:** Between 0% (pure pull-forward) and 100% (pure creation). Prior evidence on construction subsidies suggests 30–60% additionality.

## Primary Specification

ITS model:
```
Y_t = α + β₁·t + β₂·Program_t + β₃·Post_t + β₄·(t - T_end)·Post_t + ε_t
```

Cross-region:
```
Y_{rt} = α_r + α_t + β·(Intensity_r × Program_t) + ε_{rt}
```

## Exposure Alignment

**Who is treated:** Individual owner-occupiers building new homes priced below $750,000 with income below $125,000 (individual) or $200,000 (couple). The grant applies nationally — all 8 states/territories are treated simultaneously.

**Differential exposure:** The $750,000 price cap creates differential bite across regions. In affordable states (QLD, SA, WA, TAS, NT, ACT), most new builds qualify. In high-price states (NSW, VIC), the cap excludes many new builds, reducing effective treatment intensity.

**Dwelling-type exposure:** Houses (ABS code 110) are the primary treated category — individual owner-occupier builds. Apartments/other residential (ABS code 850) are largely ineligible because they are corporate-developed, above the price cap, or renovation-focused. This differential creates the DDD placebo.

**Timing:** Treatment = program active (June 2020–March 2021). Post-treatment = April 2021 onward. The lag between contract signing and building approval (2-4 months) means some approvals during the reduced-grant period reflect full-grant contracts.

## Data Sources

1. **ABS Building Approvals (8731.0):** Monthly, by GCCSA and dwelling type. SDMX API confirmed.
2. **ABS Lending to Households:** Monthly, for robustness.
3. **HomeBuilder program data:** 121,000 applications, $2.4B total cost (Treasury reports).
