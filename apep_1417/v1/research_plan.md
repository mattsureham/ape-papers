# Research Plan: Pricing Out the World — Singapore's Foreign-Buyer Stamp Duty Escalation

## Research Question

Does escalating foreign-buyer taxation suppress housing prices and volumes, or does the demand simply spill over into rental markets? Singapore raised its Additional Buyer's Stamp Duty (ABSD) on foreign purchasers five times between 2011 and 2023 (from 0% to 60%), creating the most extreme foreign-buyer housing tax in any developed economy.

## Identification Strategy

**Segment-level DiD with dose-response escalation:**

- **Treated segment:** Core Central Region (CCR) — ~16% foreign-buyer share pre-ABSD
- **Control segments:** Outside Central Region (OCR) — ~3% foreign-buyer share; HDB public housing (zero foreign access)
- **5 treatment rounds** (staggered dose): 10% (Dec 2011), 15% (Jan 2013), 20% (Jul 2018), 30% (Dec 2021), 60% (Apr 2023)
- **Estimator:** Event-study DiD around each round + Callaway-Sant'Anna for the full staggered sequence
- **Pre-treatment:** 7+ quarters before each round
- **Placebos:** (1) Commercial property within CCR (unaffected by ABSD); (2) HDB resale (no foreign buyers)

**Key identifying assumption:** The ABSD rate hikes were sudden policy announcements — not anticipated or driven by differential trends across segments. Pre-trend tests verify parallel paths before each round.

## Expected Effects and Mechanisms

1. **Price suppression in CCR:** Higher ABSD should reduce foreign demand, lowering prices in CCR relative to OCR. The 60% rate (Apr 2023) should produce the largest effect.
2. **Volume collapse:** Transaction volumes in CCR should fall sharply post-ABSD, especially for foreign-buyer transactions.
3. **Rental spillover:** If foreign buyers are displaced from ownership to renting, rental prices in CCR should rise post-ABSD — the "capital control displacement" channel.
4. **Dose-response monotonicity:** Effects should be increasing in the ABSD rate — 60% > 30% > 20% > 15% > 10%.

## Primary Specification

$$\text{Price}_{st} = \alpha_s + \gamma_t + \sum_{k} \beta_k \cdot \mathbf{1}[\text{CCR}] \times \mathbf{1}[\text{Round } k \text{ active}]_t + \epsilon_{st}$$

Where $s$ indexes segments (CCR, RCR, OCR), $t$ indexes quarters. Event-study variant includes leads and lags around each announcement date.

## Data Sources

1. **URA Property Price Index** (data.gov.sg): Quarterly by segment (CCR/RCR/OCR), 2004-2025. ~80 quarters.
2. **URA Private Residential Transactions** (data.gov.sg): Individual transaction records with price, area, district, date.
3. **HDB Resale Prices** (data.gov.sg): 226K+ transaction records, 2017-present. Clean placebo.
4. **URA Rental Statistics** (data.gov.sg): Quarterly median rents by segment.

## Key Risks

- Segment-level analysis has only 3 units (CCR/RCR/OCR) for the price index — need to supplement with district-level or town-level data for adequate inference.
- Multiple overlapping policies (SSD, TDSR, LTV rules) — must control for concurrent measures or argue they affect all segments equally.
