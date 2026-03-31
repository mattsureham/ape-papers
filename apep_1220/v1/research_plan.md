# Research Plan: The Lock-in Discount — Property Tax Reform and Housing Market Liquidity in Denmark

## Research Question

Does assessment-based property tax lock-in reduce housing market liquidity? Denmark's 2024 Boligskattereform simultaneously reassessed all properties and introduced a permanent incumbent discount (lost upon sale), creating municipality-varying wedges between incumbent and new-buyer effective tax rates.

## Framing: The Lock-in Discount

Denmark's January 2024 property tax reform cut nominal tax rates dramatically but froze the difference between old and new taxes as an automatic discount for current homeowners — a discount that disappears the moment you sell. This creates a tax penalty for moving: the longer you stay, the larger the discount becomes relative to what a new buyer would pay. In Copenhagen, grundskyld (land tax) fell from 34‰ to 5.1‰, but a new buyer in future years will face reassessed values while incumbents retain their grandfathered rate. The mechanism — "move and lose your tax discount" — is identical to California's Proposition 13, but Denmark's reform arrived overnight for 98 municipalities with excellent administrative data.

If lock-in reduces mobility (as Ferreira 2010 AER showed for Prop 13), we should see: (1) falling sales volume in high-treatment municipalities; (2) rising prices as supply contracts; (3) falling forced sales as tax burdens drop for incumbents. The treatment dose varies enormously across municipalities because the reassessment and rate changes hit different areas differently.

## Identification Strategy

**Primary: Dose-Response DiD**

- Treatment intensity: municipality-specific change in effective grundskyld rate (2023 to 2024), normalized by 2023 level
- High-dose: municipalities where rates fell most (Copenhagen: 34‰ → 5.1‰)
- Low-dose: municipalities where rates fell least (already near new caps)
- Municipality FE + year FE. Main specification interacts treatment dose with post-2024 indicator
- Pre-period: 2016–2023 (8 years); Post-period: 2024–2025+ (2+ years)
- Event study: annual coefficients from 2016–2025 relative to 2023

**Key assumption:** Municipalities with different tax rate cuts would have followed parallel trends absent the reform. Testable with 8 years of pre-data.

**Diagnostics:**
- Pre-trend test (2016–2023): no differential trends by treatment dose
- Covariate balance: population, income, urbanization should not predict treatment dose after controlling for pre-reform grundskyld rate
- Placebo doses: randomize municipality treatment assignments; should find no effect

## Expected Effects

1. **Prices (house price index)**: Positive — tax cuts capitalize into prices (Prop 13 literature predicts 3-5% per $1000 annual tax reduction)
2. **Sales volume**: Ambiguous — lower taxes attract buyers (demand ↑), but lock-in discourages incumbents from selling (supply ↓). Net effect is the key test.
3. **Forced sales**: Negative — lower tax burdens reduce financial distress
4. **First-time buyer share**: Positive — if incumbents hold on, turnover shifts toward first-time buyers

## Exposure Alignment

The treatment operates at the municipality level: each municipality sets a grundskyld rate that applies to all properties within its boundaries. The reform changed these rates municipality-wide on January 1, 2024. All homeowners within a municipality are equally exposed to the rate change — there is no within-municipality variation in treatment. The outcomes (forced sales, total property tax revenue, and assessment values) are measured at the same municipality level where treatment is assigned, ensuring tight treatment-outcome alignment. Homeowners cannot easily relocate across municipality borders to avoid treatment, as property tax liability is determined by property location, not owner residence.

## Primary Specification

$$Y_{mt} = \alpha_m + \gamma_t + \beta \cdot (Dose_m \times Post_t) + \epsilon_{mt}$$

where $Y_{mt}$ is the outcome in municipality $m$, year $t$; $Dose_m$ is the percentage change in effective grundskyld rate (2023→2024); $Post_t = \mathbb{1}[t \geq 2024]$.

## Data Source and Fetch Strategy

### Statistics Denmark Open API (api.statbank.dk — no registration)

| Table | Content | Years |
|-------|---------|-------|
| EJDSK2 | Grundskyld rates by municipality | 2007–2026 |
| ESKAT | Property taxes, assessments | 2010–2024 |
| EJ131 | House prices by province | 2005–2025 |
| LABY22 | Prices + first-time buyer share | 2012–2024 |
| TVANG3 | Forced sales by municipality | 2012–2025 |
| EJENEU | House price index quarterly | 2005–2025 |

All accessible via `https://api.statbank.dk/v1/data/{TABLE}/CSV?...`. Response format is CSV with variables and time dimensions as parameters.

### Risk Assessment

- **Short post-period**: Only 2024–2025 post-treatment. But housing markets respond fast to tax changes. Even 1-2 years should show capitalization effects.
- **Province vs municipality**: Some tables (EJ131) are at province level (11 regions), not municipality (98). Need EJDSK2 at municipality level for treatment, EJENEU or LABY22 for outcomes.
- **System-wide reform**: No pure control group — all municipalities affected. Design relies on dose variation, not treated/untreated comparison.
