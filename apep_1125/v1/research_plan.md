# Research Plan: Room to Breathe? The UK Debt Respite Scheme and Personal Insolvency

## Research Question

Does the introduction of the Breathing Space moratorium (May 4, 2021) — a statutory 60-day pause on creditor enforcement for over-indebted individuals in England and Wales — reduce personal insolvency rates?

## Identification Strategy

**Two-way fixed-effects DiD** exploiting the jurisdictional boundary between England/Wales (treated) and Scotland (control).

- **Treatment group:** 316 Local Authorities in England & Wales
- **Control group:** 32 Local Authorities in Scotland
- **Treatment date:** May 2021 (Debt Respite Scheme Regulations 2020 effective date)
- **Pre-treatment:** 2015–2020 (6 years)
- **Post-treatment:** 2021–2024 (4 years)

**Specification:**
Y_it = α_i + γ_t + β(EngWales_i × Post2021_t) + X_it'δ + ε_it

Where Y_it is the insolvency rate per 10,000 adults in LA i and year t.

**Key identifying assumption:** Absent Breathing Space, insolvency trends in England/Wales and Scotland would have followed parallel paths. Both nations shared UK-wide shocks (COVID furlough, energy crisis) that absorb into year FEs.

**Threats and mitigation:**
1. COVID asymmetry → Year FEs absorb UK-wide furlough/SEISS; event study checks for differential trends
2. Scotland has a distinct insolvency regime → Use total insolvencies (comparable) as primary; DRO-specific as secondary
3. DRO threshold changed June 2024 → Exclude 2024 for DRO-specific analysis
4. Composition → Triple-diff using pre-treatment debt levels as continuous treatment intensity

## Expected Effects and Mechanisms

**Primary hypothesis:** Breathing Space reduces formal insolvency by giving debtors time to negotiate informal repayment plans with creditors, avoiding the nuclear option of IVA/DRO/bankruptcy.

**Expected sign:** Negative (fewer insolvencies per capita in E/W vs Scotland after May 2021)

**Magnitude prior:** With ~89,000 registrations/year and ~100,000 insolvencies/year in E/W, a meaningful diversion rate of 10-20% of registrants avoiding insolvency would imply a 5-10% reduction.

**Mechanisms:**
1. Breathing space → informal debt solution (instead of formal insolvency)
2. Breathing space → mental health improvement → better financial decision-making
3. Breathing space → creditor negotiation window → partial repayment plans

## Primary Specification

1. **Main outcome:** Total individual insolvency rate per 10,000 adults (IVA + DRO + bankruptcy)
2. **Secondary outcomes:** Insolvency by type (IVA, DRO, bankruptcy separately)
3. **Event study:** Dynamic treatment effects for each year relative to 2020

## Data Sources

1. **England/Wales insolvencies:** Insolvency Service Individual Insolvency Statistics, LA-level, 2014-2024 (XLSX from gov.uk)
2. **Scotland insolvencies:** Accountant in Bankruptcy (AiB), LA-level, 2015-2025 (XLSX from gov.scot)
3. **Breathing Space registrations:** Insolvency Service Table 5a/5b, LA-level (for mechanism analysis)
4. **Population denominators:** ONS mid-year population estimates by LA (for rate construction)
5. **Controls:** NOMIS for unemployment rates by LA; ONS for deprivation

## Fetch Strategy

All data sources are publicly downloadable from gov.uk and gov.scot. No API keys required for the core insolvency data. ONS population estimates via the Beta API or NOMIS.
