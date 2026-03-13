# Research Plan: Taxing the Transition

## Research Question

Do state EV-specific registration fees deter electric vehicle adoption? If so, how large is the deterrence effect, and does it scale with fee magnitude?

## Policy Context

As EVs erode gasoline tax revenue, 33 U.S. states have imposed annual registration surcharges ($50–$250) specifically targeting EVs. These fees represent a "stick" in a policy environment dominated by "carrots" (federal tax credits, state rebates). The staggered adoption of these fees across states (2011–2024) provides a natural experiment.

## Identification Strategy

**Staggered DiD with Callaway-Sant'Anna (2021).**

- **Treatment:** State enacts an EV-specific registration fee
- **Control group:** Not-yet-treated states (preferred) and never-treated states
- **Estimand:** ATT — the effect of imposing an EV registration fee on EV adoption in fee-adopting states
- **Parallel trends assumption:** Absent the fee, EV adoption trends in treated states would have paralleled not-yet-treated states. Federal EV tax credit ($7,500) is nationally uniform and differenced out. State-level controls for concurrent EV incentives.

## Expected Effects and Mechanisms

1. **Primary hypothesis:** EV registration fees reduce EV registrations by increasing annual ownership costs. Expected sign: negative.
2. **Dose-response:** Larger fees ($200+) should produce proportionally larger deterrence than smaller fees ($50–$100).
3. **Substitution:** Fees may shift demand from BEVs to PHEVs (which sometimes face lower fees or exemptions).

## Primary Specification

$$Y_{s,t} = \alpha_s + \gamma_t + \sum_g \sum_t \text{ATT}(g,t) \cdot \mathbf{1}[G_s = g] + \varepsilon_{s,t}$$

where $Y_{s,t}$ is log EV registrations in state $s$ at time $t$, $G_s$ is the treatment cohort (year of fee enactment), and ATT(g,t) is estimated via Callaway-Sant'Anna.

**Inference:** Cluster at the state level (51 clusters). Wild cluster bootstrap as robustness.

## Data Sources

1. **EV registrations:** Alternative Fuels Data Center (AFDC), derived from Experian vehicle registration data by NREL. State-year, 2016–2023, all 50 states + DC.
2. **Policy timing:** NREL AFDC Transportation Laws API — exact enactment dates, fee amounts, legislative citations for all 33 EV fee laws.
3. **Controls:** State GDP (BEA), gas prices (EIA), state EV purchase incentives (AFDC), charging stations (AFDC).

## Robustness Checks

1. Event study plot (pre-trends test)
2. HonestDiD sensitivity analysis
3. Bacon decomposition
4. Placebo: effect on conventional vehicle registrations (should be null)
5. Wild cluster bootstrap p-values
6. Alternative outcome: EV share of total registrations (instead of levels)
7. Dose-response: continuous treatment (fee amount)

## Exposure Alignment

**Who is exposed to treatment?** All EV owners in a state that enacts an EV registration fee are subject to the annual surcharge upon vehicle registration renewal. The treatment operates at the state-year level: once a state enacts a fee, all current and prospective EV owners face the additional annual cost.

**Mechanism of exposure:** The fee is paid annually at registration renewal. It affects the purchase decision of prospective EV buyers (making EV ownership costlier relative to ICE alternatives) and potentially the retention decision of existing EV owners (though deregistration is rare). The primary channel is the extensive margin: deterring new EV purchases.

**Alignment between treatment and outcome:** The outcome (cumulative BEV registration stock) captures the cumulative effect of the fee on both new purchases and the existing stock. Since the fee cannot cause existing vehicles to be deregistered (it is modest relative to vehicle value), the stock-based outcome primarily reflects the accumulated effect on new purchase flows. This creates mechanical attenuation: the treatment effect on new purchases is diluted by the large stock of pre-fee vehicles.

**Timing:** Fees typically take effect at the start of the fiscal year following enactment. The treatment timing variable uses the enactment year, which may precede the first fee payment by up to one year. This conservative coding biases toward finding null effects in the impact year.

## Key Risks

- Short panel (2016–2023): only 8 years, limiting pre-treatment periods for early adopters
- EV adoption is on a steep upward trend everywhere — need parallel trends in growth rates or log-levels
- Contemporaneous state policies (purchase rebates, ZEV mandates) may confound
- Federal $7,500 tax credit changes (IRA 2022) affect all states but may interact with fees
