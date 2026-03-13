# Research Plan: The Marginal Birth — Post-Dobbs Abortion Bans and Newborn Composition

## Research Question

Did state abortion bans enacted after the June 2022 Dobbs decision shift the composition of births toward unmarried, lower-education, Medicaid-funded, and higher-risk pregnancies?

This is a direct reverse test of Akerlof, Yellen, and Katz (1996, QJE): if reproductive technology availability changed marriage norms, does restricting it restore them? Myers et al. (2024, JPUBE) showed Dobbs increased birth *levels* by 2.3%. We study who these marginal births are.

## Identification Strategy

**Callaway-Sant'Anna (2021) staggered DiD.**

- **Treatment:** State enactment of near-total abortion ban post-Dobbs (June 24, 2022).
- **Treated states (total bans):** AL, AR, ID, KY, LA, MO, MS, OK, SD, TN, TX, WV (effective June-September 2022); IN, ND (effective 2023).
- **Additional treated (gestational limits):** GA, OH, SC (6-week bans); NC, FL (12-15 week limits).
- **Control:** ~22 states with no new restrictions (never-treated).
- **Pre-periods:** 2016-2021 (6 years).
- **Post-periods:** 2022-2023 (2 years, with 2023 as first fully affected year).

**Key timing nuance:** Dobbs was decided June 24, 2022. Births reflect conception ~9 months prior. The first "marginal births" (those that would have been aborted) appear ~March 2023. So:
- 2022 births: largely unaffected (conceived pre-Dobbs)
- 2023 births: first full year with substantially affected births

Treatment cohort assignment: states with bans effective in 2022 get `first_treat = 2022`; states with bans effective in 2023 get `first_treat = 2023`. The CS-DiD event study will reveal the biological lag.

## Expected Effects and Mechanisms

**Primary hypothesis:** Abortion bans disproportionately affect pregnancies that would have been terminated --- those to unmarried, younger, lower-education, lower-income mothers. Therefore:

1. **Unmarried birth share** should increase (strongest prediction)
2. **Medicaid-funded birth share** should increase (lower-income marginal births)
3. **Low birthweight share** may increase (selection on risk)
4. **Preterm birth share** may increase (correlated with maternal characteristics)
5. **Mother's education distribution** should shift toward lower education

**Akerlof-Yellen-Katz reversal:** If restricting abortion restores "shotgun marriages," the unmarried share might NOT increase --- or might even decrease. This would be a striking finding.

## Primary Specification

$$Y_{st} = \alpha_s + \gamma_t + \beta \cdot \text{Ban}_{st} + X_{st}'\delta + \varepsilon_{st}$$

Where:
- $Y_{st}$: birth composition outcome (e.g., unmarried share) in state $s$, year $t$
- $\text{Ban}_{st}$: indicator = 1 if state $s$ has an active total ban in year $t$
- $\alpha_s, \gamma_t$: state and year FE
- $X_{st}$: time-varying state controls (unemployment rate, Medicaid expansion status)
- Clustering at state level (51 clusters)

**CS-DiD:** Use `did` package with group-time ATTs aggregated to overall ATT.

## Robustness and Placebo Tests

1. **Temporal placebo:** Assign fake treatment in 2019 --- should be null.
2. **Population placebo:** Non-childbearing-age marriage rates (ages 45-64) --- should show no effect.
3. **Dose-response:** Total bans vs. gestational limits (total bans should have larger effects).
4. **Event study:** Dynamic treatment effects to check pre-trends.
5. **Sensitivity:** HonestDiD for violation of parallel trends.

## Data Sources

### Outcome: CDC WONDER Natality Data
- **Source:** CDC WONDER Expanded Natality database
- **Coverage:** 2016-2023, all 50 states + DC
- **Variables:** State-level tabulations of births by marital status, mother's education, payment source (Medicaid vs private vs other), birthweight, gestational age
- **Access:** CDC WONDER API (POST requests with XML query) or direct data request

### Treatment: Dobbs Ban Timing
- **Source:** Guttmacher Institute state policy tracker + KFF abortion policy tracker
- **Variables:** State, ban type (total/gestational limit), effective date
- **Access:** Published tables, manually compiled from Guttmacher/KFF

### Controls
- **State unemployment:** BLS LAUS via FRED API
- **Medicaid expansion status:** KFF tracker (known dates)

## Method Notes

The main challenge is that treatment timing is concentrated in a narrow window (June 2022 - early 2023), so there is limited staggering. Most total bans activated within 3 months of Dobbs via trigger laws. This means CS-DiD may effectively behave like a simple 2x2 DiD for the total-ban group.

The gestational-limit states provide additional timing variation but with a weaker treatment intensity.

Power considerations: With 51 states x 8 years = ~408 observations and ~21 treated states, the design has reasonable power for detecting effects on aggregate shares if effects are economically meaningful (e.g., 2+ pp shift in unmarried share).

## Exposure Alignment

**Who is actually affected by treatment?** The treatment (state-level abortion ban) affects all women of reproductive age who become pregnant and would have sought abortion in that state. The exposure population is:

- **Directly affected:** Women who would have obtained an abortion absent the ban. These are disproportionately unmarried, younger, lower-income, and earlier in pregnancy (Guttmacher patient surveys).
- **Partially affected:** Women who can travel out of state for abortion services — these are effectively untreated despite living in a ban state, attenuating the composition effect.
- **Indirectly affected:** All women of reproductive age through behavioral channels (increased contraception, changed sexual behavior) whether or not they become pregnant.

**Outcome alignment:** Our outcomes — state-year birth composition shares — capture the net effect on the full population of births in each state, not specifically the marginal births. A shift in shares requires that the marginal births (prevented abortions that become births) differ enough in composition from the average birth to move the state aggregate. With births increasing by only ~1.5%, even large compositional differences among marginal births may produce mechanically small shifts in statewide shares. This is a key limitation of aggregate analysis.

**Treatment timing alignment:** Bans enacted June-September 2022 first affect births in early 2023 (9-month gestation lag). We code first_treat = 2023 for these states in the annual birth panel, meaning 2023 births are the first treated year. Since bans took effect mid-year 2022, only pregnancies conceived after the ban contribute marginal births to the 2023 birth cohort, so 2023 is a partially treated year for births. The 2024 birth cohort would be the first fully treated year, but our data ends in 2023. This partial exposure further attenuates our estimates.
