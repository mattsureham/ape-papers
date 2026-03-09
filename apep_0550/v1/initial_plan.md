# Initial Research Plan: The Price of Market Freedom

## Research Question
Did India's 2020 farm laws — which allowed agricultural trade outside the regulated APMC mandi system — actually change commodity prices and trading volumes? And did the Supreme Court stay and subsequent repeal reverse those effects?

## Policy Setting
India's three farm laws (Farmers' Produce Trade and Commerce Act, Farmers Agreement on Price Assurance Act, Essential Commodities Amendment Act) were:
- **Enacted:** September 20, 2020 (ordinances from June 5, 2020)
- **Stayed:** January 12, 2021 (Supreme Court)
- **Repealed:** December 1, 2021

The laws permitted agricultural trade outside the Agricultural Produce Market Committee (APMC) mandi system. This was revolutionary: in most states, all wholesale agricultural trade was legally required to occur through regulated mandis, which charged commission fees (2-8.5%) and required licensed intermediaries.

### Treatment Variation
States vary dramatically in APMC regulation stringency:
- **Strong APMC:** Punjab (8.5% total charges), Haryana, Maharashtra, MP, Gujarat, Karnataka
- **Weak/No APMC:** Bihar (abolished 2006), Kerala (most commodities exempt), some NE states
- **Blocked implementation:** Punjab, Rajasthan, Chhattisgarh passed counter-legislation

## Identification Strategy

### Primary: Continuous-Treatment DiD
$$Y_{mct} = \alpha + \beta_1 \cdot \text{APMCStringency}_s \times \text{ON}_t + \beta_2 \cdot \text{APMCStringency}_s \times \text{OFF}_t + \gamma_{mc} + \delta_{ct} + \varepsilon_{mct}$$

Where:
- $Y_{mct}$ = log modal price or log arrivals at mandi $m$, commodity $c$, day/month $t$
- $\text{APMCStringency}_s$ = pre-existing state-level APMC regulation index (continuous)
- $\text{ON}_t$ = indicator for June 2020–January 2021 (deregulation period)
- $\text{OFF}_t$ = indicator for post-January 2021 (re-regulation period)
- $\gamma_{mc}$ = mandi × commodity fixed effects
- $\delta_{ct}$ = commodity × month fixed effects

**Key coefficients:**
- $\beta_1$ (ON phase): Effect of deregulation. If farm laws expanded market access, we expect lower prices in high-APMC states (more competition, lower intermediation costs).
- $\beta_2$ (OFF phase): Reversal test. If $\beta_2 \approx 0$, the ON-phase effect was truly driven by deregulation, not a trend.

### Alternative: Event-Study
Weekly coefficients around the enactment date (June 2020) and stay date (January 2021) to trace dynamics.

### Placebo Tests
1. **Bihar placebo:** Already deregulated since 2006. Should show β₁ ≈ 0.
2. **Exempt commodities:** Fruits and vegetables are exempt from APMC regulation in many states. Should show β₁ ≈ 0.
3. **Pre-trend test:** Weekly event-study coefficients should be flat before June 2020.

## Expected Effects and Mechanisms
1. **Price effect (primary):** Deregulation → entry of private buyers → competition → lower intermediation margins → EITHER lower consumer prices OR higher farmgate prices (direction depends on who captures the mandi rent)
2. **Arrivals effect:** Deregulation → trade moves outside mandis → LOWER mandi arrivals in high-APMC states
3. **Price dispersion:** More trading points → reduced price dispersion across mandis (law of one price)

## Data
- **CEDA AGMARKNET API:** Daily mandi-level prices and arrivals, 36 states, 640 districts, 453 commodities, 2006-2025
- **data.gov.in API:** Same database, alternative endpoint (77M+ records)
- **APMC stringency index:** Constructed from state agricultural marketing laws, APMC cess rates, and number of regulated commodities

## Primary Specification
- Unit: mandi × commodity × month (aggregate daily to monthly to reduce noise)
- Sample: January 2018–December 2022 (2 years pre, 2.5 years spanning both phases)
- Treatment: continuous APMC stringency index × phase dummies
- FE: mandi × commodity, commodity × month
- Clustering: state level (treatment varies at state level)
- Focus commodities: wheat, rice, onion, potato, tomato, maize (high volume, politically salient)

## Planned Robustness Checks
1. Drop Punjab/Haryana (protest-affected states)
2. Weekly event-study (instead of monthly)
3. Binary treatment (high- vs low-APMC states) instead of continuous
4. Callaway-Sant'Anna with counter-legislation dates as staggered treatment timing
5. Permutation inference (placebo treatment dates)
6. Bandwidth sensitivity (expand/contract sample window)
7. Bihar-only placebo (flat coefficients expected)
8. Exempt commodity placebo (fruits/vegetables in states where they're not APMC-regulated)
9. HonestDiD sensitivity bounds for pre-trend violations
10. Price dispersion analysis (SD of prices across mandis for same commodity)

## Exposure Alignment
- **Who is actually treated?** States with high APMC stringency (high commission/cess rates, mandatory mandi trading). Treatment is continuous, measured by pre-existing APMC regulation index.
- **Primary estimand population:** State-commodity-month price observations in states where APMC regulation was binding before deregulation.
- **Placebo/control population:** States with weak/no APMC regulation (Bihar abolished in 2006, Kerala exempts most commodities, NE states).
- **Design:** DiD with continuous treatment intensity (APMC stringency × phase dummies). Not staggered — all states treated simultaneously by federal law.

## Power Assessment
- ~2,700 mandis × 6 focus commodities × 60 months = ~970,000 mandi-commodity-month observations
- State-level clustering: ~30 clusters (adequate for cluster-robust inference)
- Expected MDE: APMC charges average ~5% of commodity value; even if deregulation captures half this margin, effect should be ~2.5% of prices — well within detection limits given the sample size
