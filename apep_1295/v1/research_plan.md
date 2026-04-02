# Research Plan: Sunshine Through the Alps

## Research Question

Does bilateral tax transparency — via Automatic Exchange of Information (AEOI) agreements — causally reduce cross-border deposit holdings in international financial centers? Or does money merely shift to non-reporting jurisdictions (the "waterbed effect")?

## Policy Background

Liechtenstein's AEOI law (LGBl 2015/355) entered force January 1, 2016, with exchanges staggered:
- **2017-Q3:** First exchanges with EU/EEA members (~15 bilateral pairs among BIS reporters)
- **2019-Q1:** 28 additional jurisdictions activated
- **2020–2022:** Further expansions to 121 total partners

Each bilateral activation is a discrete information shock: Liechtenstein banks must automatically report foreign client account details (balances, interest, dividends) to the partner jurisdiction's tax authority. This eliminates bank secrecy for depositors from that jurisdiction.

## Identification Strategy

**Bilateral staggered DiD.** Unit of observation: reporting-country × quarter. Treatment: the quarter in which AEOI is activated for each bilateral pair.

- **Treatment group:** Country-quarters after AEOI activation
- **Control group:** Not-yet-treated and never-treated country-quarters
- **Estimator:** Callaway and Sant'Anna (2021) for heterogeneous treatment timing
- **Fixed effects:** Country FE + quarter FE (two-way)

**Why this works:**
1. Activation timing is driven by multilateral treaty schedules, not bilateral deposit trends
2. Liechtenstein is small enough that its AEOI decisions don't affect partner-country macro conditions
3. Staggered rollout provides clean temporal variation within the same financial center

**Exposure alignment — who is treated:** The treatment (AEOI activation) directly affects all banking relationships between Liechtenstein and the partner country. The affected population includes any entity (bank, non-bank financial, corporate, or household) holding cross-border positions with Liechtenstein-resident counterparties. BIS data measure aggregate banking positions, which capture the full bilateral financial relationship rather than individual depositors. The treatment is applied at the country level, and all banking positions from that country to Liechtenstein are equally exposed once AEOI activates.

## Expected Effects and Mechanisms

**Main hypothesis:** AEOI activation reduces bilateral deposit claims on Liechtenstein from the reporting country.

**Mechanism decomposition:**
1. *Repatriation effect:* Deposits return to home-country banks (→ decline in LI claims)
2. *Waterbed effect:* Deposits shift to non-AEOI jurisdictions (→ increase in other IFC claims from same country)
3. *Anticipation effect:* Deposits may decline before formal activation (treaty announcement)

**Expected magnitude:** Johannesen and Zucman (2014 AEJ) found 8% decline in Swiss deposits post-2005 EU Savings Directive. We expect similar or larger effects given AEOI's broader scope.

## Primary Specification

```
Y_{c,t} = α_c + γ_t + β · AEOI_{c,t} + ε_{c,t}
```

Where:
- Y_{c,t} = log bilateral claims/liabilities of country c on Liechtenstein in quarter t
- AEOI_{c,t} = 1 if AEOI is active for country c in quarter t
- α_c = country fixed effects
- γ_t = quarter fixed effects

**Inference:** Wild cluster bootstrap (27 clusters). Randomization inference as robustness.

## Data Source and Fetch Strategy

**Primary:** BIS Locational Banking Statistics (LBS)
- Quarterly bilateral claims/liabilities
- 27 reporting countries × Liechtenstein as counterparty
- Sectoral breakdown: banks, non-bank financial, non-financial, households
- Available: 1977–2025 (varies by reporter)
- Access: Free CSV bulk download from BIS website

**Treatment timing:** Liechtenstein AEOI activation dates from:
- LGBl 2015/355 (original law)
- Liechtenstein Tax Office published exchange partner list
- OECD CRS Implementation Status (public matrix)

**Steps:**
1. Download BIS LBS bulk CSV
2. Filter for counterparty = Liechtenstein (LI)
3. Construct bilateral panel: reporter × quarter
4. Merge AEOI activation dates from OECD CRS matrix
5. Construct treatment indicators and event-time variables

## Robustness Checks

1. **Event study:** Dynamic treatment effects with leads/lags (−8 to +12 quarters)
2. **Sector decomposition:** Non-bank private vs. bank vs. household deposits
3. **Waterbed test:** Do claims on other IFCs (Switzerland, Singapore, Hong Kong) increase post-AEOI from same reporter?
4. **Placebo:** AEOI activation should not affect interbank claims (banks don't evade taxes)
5. **Anticipation:** Test for pre-activation decline (treaty signing vs. first exchange)
6. **Leave-one-out:** Drop each country sequentially to check single-country influence
7. **Wild cluster bootstrap:** Webb (2023) 6-point distribution for 27 clusters
8. **Randomization inference:** Permute activation dates within staggered structure
