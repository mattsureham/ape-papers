# Research Plan: Abolishing the Tax Haven Next Door

## Research Question

Does terminating a preferential tax regime for foreign residents reduce local housing prices? We study Portugal's abrupt January 2024 abolition of the Non-Habitual Resident (NHR) tax regime—which had attracted 74,000+ beneficiaries with a flat 20% tax rate and foreign-income exemption—to estimate the causal effect of preferential expat taxation on housing markets.

## Identification Strategy

**Primary: Cross-country event study (DiD)**
- Treatment: Portugal (NHR abolished Jan 1, 2024, announced Sep 6, 2023)
- Controls: Spain, Italy, Netherlands, Ireland, Greece (EU countries with similar housing dynamics but no equivalent policy shock in 2023-2024)
- Outcome: Eurostat House Price Index (HPI), quarterly, 2015Q1–2025Q3
- Specification: Event study around announcement date (2023Q3) with country and quarter FEs
- Key test: Pre-trend parallel between Portugal and controls (2015-2023Q2)

**Secondary: Within-Portugal continuous-treatment DiD**
- Treatment intensity: Pre-2023 foreign buyer share by NUTS3 region (proxy for NHR beneficiary concentration)
- High-exposure: Algarve, Greater Lisbon, Madeira, Porto metro
- Low-exposure: Interior regions with minimal foreign buyer activity
- Outcome: INE regional house price indices (quarterly, ~25 NUTS3 regions)
- Specification: Region FE + quarter FE + (foreign_buyer_share × post_announcement)

**Placebo tests:**
1. Spain and Italy HPI around same dates (no equivalent regime change)
2. Commercial property prices in Portugal (NHR was residential/income-focused)
3. Pre-announcement "event study" at earlier placebo dates

## Expected Effects and Mechanisms

**Primary hypothesis:** NHR termination reduces housing price growth in high-exposure regions relative to low-exposure regions.

**Mechanism:** NHR attracted high-income foreign residents (primarily French, British, Scandinavian retirees) who concentrated in Lisbon, Algarve, and Porto. Their demand exit should:
1. Reduce purchase pressure → lower price growth
2. Shift rental market as expats leave → lower rents in premium segments
3. Create anticipation effects between announcement (Sep 2023) and effective date (Jan 2024)

**Alternative mechanisms to test:**
- Pure anticipation vs gradual adjustment
- Ownership vs rental segment differential
- Tourism vs residential demand confusion (NHR ≠ golden visa, but related)

## Primary Specification

Y_{ct} = α_c + γ_t + β × (Portugal_c × Post_t) + ε_{ct}

Where Y is log HPI, α_c is country FE, γ_t is quarter FE, Post = 1 after 2023Q3 (announcement).

Event study version with leads and lags for pre-trend validation.

## Data Sources

1. **Eurostat HPI** (prc_hpi_q): Quarterly house price index, 2005Q1-2025Q3, all EU countries. JSON-stat API, no auth. ~83 quarters × 30+ countries.
2. **INE Portugal** (Índice de Preços da Habitação): NUTS3-level quarterly HPI. API at ine.pt.
3. **Eurostat HPI by new/existing** (prc_hpi_oo): Distinguishes new vs existing dwellings—mechanism test.
4. **OECD HPI** (backup): Annual/quarterly for non-EU comparators if needed.

## Feasibility Assessment

- **Sample size:** 30+ countries × 83 quarters = 2,400+ country-quarter obs (cross-country); 25 NUTS3 × ~40 quarters (within-Portugal)
- **Treatment intensity:** 74,000+ NHR beneficiaries, €1.7B annual tax expenditure → economically meaningful
- **Pre-periods:** 8+ years quarterly data before announcement
- **Post-periods:** ~8 quarters after announcement (through 2025Q3)
- **Key risk:** Other housing policies (Mais Habitação package, STR restrictions, golden visa changes) may confound—need to carefully control or argue orthogonality
