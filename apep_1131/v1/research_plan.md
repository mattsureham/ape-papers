# Research Plan: The Hollow Safety Net

## Research Question

Does erosion of state administrative capacity cause delays in unemployment insurance (UI) first payments? When recession-driven demand surges collide with staffing cuts, how much does payment timeliness deteriorate, and what are the downstream consequences for workers?

## Identification Strategy

**Shift-share (Bartik) instrumental variable** for the demand shock, interacted with pre-recession administrative capacity.

**Step 1 — Predicted UI claims shock (Bartik instrument):**
For each state *s* in quarter *t*, construct predicted claims using pre-recession (2006) industry employment shares and leave-one-out national industry-level claims growth:

$$\widehat{\Delta Claims}_{st} = \sum_k \omega_{sk}^{2006} \cdot \Delta Claims_{-s,kt}$$

where $\omega_{sk}^{2006}$ is state *s*'s employment share in industry *k* (from QWI 2006) and $\Delta Claims_{-s,kt}$ is the national (leave-out-s) claims change in industry *k*.

**Step 2 — Capacity interaction:**
The instrument is the Bartik predicted shock interacted with pre-recession administrative "thinness": UI staff per 1,000 covered employees (from Census ASPEP 2007). States with thinner staffing are predicted to experience larger processing delays for a given demand shock.

**First stage:**
$$\text{ActualDelays}_{st} = \alpha + \beta_1 \widehat{\Delta Claims}_{st} \times \text{Thinness}_s + \gamma X_{st} + \delta_s + \theta_t + \epsilon_{st}$$

**Second stage:**
$$Y_{st} = \alpha + \beta \widehat{\text{Delays}}_{st} + \gamma X_{st} + \delta_s + \theta_t + \epsilon_{st}$$

**Key identifying assumptions:**
1. Pre-recession industry composition affects UI timeliness only through the claims channel (standard Bartik exclusion)
2. Pre-recession staffing levels are exogenous to unobserved determinants of processing quality conditional on state and time FE

## Expected Effects and Mechanisms

- **Primary:** States with thinner pre-recession staffing that face larger predicted claims surges should show larger declines in first-payment timeliness (share paid within 14/21 days)
- **Mechanism:** Administrative bottleneck — fixed staffing capacity cannot scale with demand, creating queuing delays
- **Downstream:** Delayed UI payments should increase SNAP enrollment (liquidity-constrained workers substitute) and reduce consumption
- **Magnitude prior:** National mean timeliness fell ~5pp; states with thin staffing likely fell 10-15pp more

## Primary Specification

Panel: 51 states × quarterly, 2006-Q1 to 2012-Q4 (8 pre-recession quarters, 20 recession/recovery quarters).

Outcome: Share of intrastate UI first payments made within 14 days of first compensable week (BTQ Category 1).

Treatment: Continuous — predicted claims shock × pre-recession staffing thinness.

Controls: State FE, quarter FE, state-specific linear trends, log state population, unemployment rate (as separate control, not in instrument).

Inference: Borusyak-Hull-Jaravel (2022) shift-share robust SEs; Rotemberg weight diagnostics.

## Data Sources

| Source | Variables | Access |
|--------|-----------|--------|
| DOL BTQ reports | First payment timeliness by state-month | POST request to oui.doleta.gov |
| DOL ETA 539 | Initial claims, continued claims by state-week | CSV download |
| Census ASPEP | State government employment by function | Zip download |
| Census QWI | Industry employment by state-quarter | API |
| Census ACS | SNAP enrollment by state-year | API |
| BEA | State personal income/consumption | API |

## Robustness Plan

1. Rotemberg weights to identify influential sectors
2. Leave-one-industry-out Bartik (remove top Rotemberg weight sectors)
3. Placebo test: 2004-2007 period (pre-recession, no capacity crunch)
4. Alternative timeliness thresholds (21 days, 28 days)
5. Event study around Lehman collapse (2008-Q4)
6. Wild cluster bootstrap (51 clusters)
