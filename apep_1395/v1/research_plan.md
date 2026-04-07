# Research Plan: The Renovation Trap — Denmark's Anti-Speculation Reform and Rental Housing Investment

## Research Question
Does capping post-renovation rents (blocking the §5 stk. 2 renovation-to-relet arbitrage) deter housing investment, or does it protect tenants without materially reducing supply?

## Identification Strategy
**Difference-in-Differences** exploiting Denmark's 2020 Blackstone-Indgreb (June 2020). The law's default-on architecture with explicit municipal opt-outs creates the treatment/control variation:
- **Treatment (~80 municipalities):** Subject to anti-speculation cap (default-on). Includes all major cities (Copenhagen, Aarhus, Odense, Aalborg).
- **Control (18 opt-out municipalities):** Predominantly island/peripheral municipalities (Fanø, Læsø, Ærø, Samsø) where §5 stk. 2 arbitrage barely existed. Opted out due to irrelevance, not policy opposition.

Treatment timing: single activation date (July 2020), simplifying to canonical two-way DiD. Robustness via Callaway-Sant'Anna and synthetic control.

## Expected Effects & Mechanisms
1. **Renovation permits:** Sharp decline in §5 stk. 2 renovation applications in treated municipalities (the direct channel).
2. **Rental property transactions:** Decline in mid-size rental building transactions (10-50 units) — the typical arbitrage target.
3. **Rent levels:** Stabilization or decline in treated municipalities (direct tenant protection).
4. **Placebo:** Owner-occupied transactions should be unaffected.
5. **Mechanism:** If the renovation arbitrage channel is operative, effects should be concentrated in §5 stk. 2 permits specifically, not general construction.

## Primary Specification
$$Y_{mt} = \alpha + \beta \cdot \text{Treated}_m \times \text{Post}_t + \gamma_m + \delta_t + \epsilon_{mt}$$

Where $Y_{mt}$ is the outcome in municipality $m$ at time $t$, with municipality and time fixed effects. Clustering at municipality level. Pre-treatment: 2015-2020M06. Post-treatment: 2020M07-2024.

## Data Sources
1. **Statistics Denmark StatBank API (EJ131):** Monthly property transactions by municipality and property type (2006-2025). 234K+ rows confirmed accessible.
2. **Statistics Denmark StatBank API (BOL):** Rental market statistics.
3. **Statistics Denmark StatBank API (BYGV):** Building permits and construction activity.
4. **BBR (Building & Dwelling Register):** Construction/renovation permits via open API.

## Exposure Alignment
The treatment exposure is at the municipality level: all rental properties in treated municipalities are subject to the renovation cap. The affected population includes landlords and investors who would otherwise use §5 stk. 2 renovation-to-relet arbitrage, and tenants who benefit from rent stabilization. Building permits (BYGV11) are measured at the same municipality-quarter level as treatment assignment, ensuring clean geographic alignment between treatment and outcome. No triple-diff or sub-municipal variation is needed because the policy applies uniformly within each municipality.

## Fetch Strategy
- Use Statistics Denmark StatBank REST API (no authentication required for public tables)
- Endpoint: `https://api.statbank.dk/v1/data`
- Tables: EJ131 (transactions), BOL101/BOL201 (rents), BYGV01/BYGV11 (building permits)
- Format: JSON/CSV, monthly municipality-level panels
