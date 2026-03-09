# Research Ideas

## Idea 1: The Price of Market Freedom: India's Farm Laws Pass-and-Repeal as a Symmetric Natural Experiment on Agricultural Market Deregulation
**Policy:** India's three farm laws (passed June 2020, Supreme Court stayed January 2021, formally repealed December 2021) created a 221-day symmetric on-off natural experiment in agricultural market deregulation. Key variation: Punjab, Rajasthan, Chhattisgarh blocked implementation; Bihar had abolished APMC in 2006; states with strong APMCs (MP, Gujarat, Maharashtra, Karnataka) most exposed. Continuous-treatment DiD with pre-existing APMC stringency as treatment intensity.
**Outcome:** Daily mandi-level commodity prices and arrivals from CEDA Ashoka AGMARKNET API: 36 states, 640 districts, 453 commodities, millions of daily records (2018-2023). Focus commodities: wheat, rice, onion, potato, tomato. MSP data for welfare analysis.
**Identification:** Continuous-treatment DiD with pre-existing APMC stringency as treatment intensity. ON phase (Jun 2020-Jan 2021) tests deregulation; OFF phase (Jan 2021+) tests reversibility. States blocking implementation (Punjab, Rajasthan, Chhattisgarh) serve as control. Bihar (no APMC since 2006) serves as built-in placebo. CS-DiD for staggered counter-legislation. Within-state cross-commodity comparisons absorb aggregate shocks.
**Why it's novel:** No published econometric study exploits the symmetric pass-and-repeal structure. Existing literature is qualitative or single-state. The symmetric design resolves the "did deregulation help or hurt farmers?" question — one of the most contested policy debates in modern India. No APEP paper on this topic.
**Feasibility check:** Confirmed — CEDA API returns daily prices and quantities for 453 commodities across 36 states. data.gov.in API confirmed (77M+ records). State APMC stringency variation documented. Bihar placebo confirmed. Sample: ~640 districts × 365 days × 3 years × 5 commodities = millions of observations.

## Idea 2: Feeding the Price Signal Home: India's Sequential Grain Export Bans and Mandi-Level Price Pass-Through
**Policy:** India's wheat export ban (May 2022) and non-basmati rice export ban (July 2023) provide two sequential commodity-specific shocks. Both remain India's most aggressive agricultural trade interventions in decades.
**Outcome:** 77 million daily mandi-level price records from Agmarknet API. Wheat (3.3M records), Rice (1.8M records), Maize (1.5M records) across 2,700+ mandis.
**Identification:** Triple-difference: commodity × district production intensity × time. Basmati rice (exempt) vs non-basmati rice (banned) in the same mandi as within-unit counterfactual. Internal replication across two bans 14 months apart.
**Why it's novel:** No DDD/event-study on mandi-level data for India's 2022-2023 export bans. Existing literature uses 4-zone retail GARCH — 3 orders of magnitude less granular.
**Feasibility check:** Confirmed — data.gov.in API returns 77.6M records. Overlaps with apep_0220 (rice ban paper) but adds wheat + triple-diff + internal replication.

## Idea 3: Banking the Unbanked Village: How Bank Branch Arrival Reshaped India's Rural Enterprise Landscape, 1990-2013
**Policy:** Three policy regimes created waves of branch arrivals: post-liberalization contraction (1991-2004), 2005 Branch Authorization Policy, 2011 mandate requiring 25% of new branches in unbanked rural centers. Treatment: transition from zero to one bank branch in a village.
**Outcome:** SHRUG Economic Census (1990/1998/2005/2013): enterprise counts, employment, female ownership, formalization. SHRUG RBI bank branches with exact opening dates. Nightlights (DMSP 1992-2013). All free from devdatalab.org.
**Identification:** Event-study DiD around timing of first bank branch arrival. Callaway-Sant'Anna (2021) with cohorts defined by EC period. Never-banked villages as comparison. 23-year panel enables proper pre-trend validation.
**Why it's novel:** Extends Burgess & Pande (AER 2005) from 16 state-year level to 500,000+ village-level observations. No paper exploits full 4-wave EC panel with geocoded branch opening dates.
**Feasibility check:** Confirmed — all SHRUG tables free at devdatalab.org. RBI branch data includes exact opening dates geocoded to shrug_id. 500K villages × 4 EC waves. Requires SHRUG download (~5GB).
