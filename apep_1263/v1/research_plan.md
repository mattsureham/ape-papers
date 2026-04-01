# Research Plan: The Opt-Out Illusion — Deemed Consent and the Organ Supply Paradox

## Research Question

Does opt-out organ donation legislation increase actual organ transplantation, or does it merely raise measured consent rates while leaving the binding constraint — family override and clinical suitability — unchanged? We exploit the UK's uniquely staggered rollout of deemed consent across three devolved nations (Wales 2015, England 2020, Scotland 2021) with Northern Ireland as a never-treated control.

## Motivation

Johnson and Goldstein (2003) established the canonical stylized fact: opt-out countries have dramatically higher donation rates. But this cross-country correlation conflates institutions, culture, and healthcare capacity. Abadie and Gay (2006) use synthetic control across countries but cannot eliminate healthcare-system heterogeneity. The UK's staggered rollout within a single healthcare system (NHS) with shared transplantation infrastructure (NHSBT) provides the cleanest test of the default-effect hypothesis in organ donation.

The paradox: Wales adopted opt-out in 2015, and consent rates rose from ~58% to ~78%. But deceased donor rates per million population did not increase proportionally. If the default effect operates as theorized, we should see consent → donors → transplants. If consent rises but transplants don't, the binding constraint is elsewhere — family override, clinical suitability, or the "deemed consent" label itself may crowd out active registration.

## Identification Strategy

**Design:** Staggered difference-in-differences with three treatment cohorts and one never-treated unit.

| Nation | Treatment Date | Role |
|--------|---------------|------|
| Wales | December 1, 2015 | First mover |
| England | May 20, 2020 | Largest unit (COVID confound) |
| Scotland | March 26, 2021 | Third mover |
| Northern Ireland | Never | Control |

**Primary estimator:** Given only 4 units, standard CS DiD inference is unreliable. I will use:

1. **Event study specification** at the nation-year level with nation and year fixed effects
2. **Randomization inference (RI):** Permute treatment assignment (which nations are treated and when) across all possible allocations. With 4 nations and 3 treatment dates, this gives a finite set of permutations for exact p-values.
3. **Wild cluster bootstrap** (Cameron, Gelbach, Miller 2008) with 4 clusters
4. **Leave-one-out sensitivity:** Drop each nation and show results are not driven by any single unit

**COVID confound for England:** England's opt-out took effect May 20, 2020 — during COVID-19 lockdown. This is a serious confound since transplant activity dropped sharply in 2020. I address this by:
- Showing pre-COVID trends (Jan-Feb 2020) vs post-COVID recovery (2021+)
- Using Scotland (March 2021, post-COVID) as the cleanest test
- Presenting England results with explicit COVID caveats
- Wales (2015, pre-COVID) provides the unconfounded baseline estimate

## Expected Effects

**Canonical prediction (Johnson & Goldstein):** Opt-out → higher consent → more donors → more transplants.

**Alternative hypothesis (The Opt-Out Illusion):** Opt-out raises *measured* consent (since non-responders are now counted as consenting) but does not change *effective* supply because:
- Families can still override deemed consent (~50% family override rate in UK)
- Clinical suitability is the binding constraint, not willingness
- Active opt-in registrations may decline ("crowding out of explicit consent")

## Primary Specification

```
Y_{nt} = α_n + γ_t + β·OptOut_{nt} + ε_{nt}
```

Where:
- Y = deceased donors per million population (primary), consent rate (secondary), transplants per million (secondary), waiting list size (tertiary)
- n ∈ {Wales, England, Scotland, Northern Ireland}
- t = year (or year-quarter if monthly data insufficient)
- α_n = nation fixed effects
- γ_t = year fixed effects
- OptOut_{nt} = 1 if nation n has deemed consent in year t

## Data Sources

1. **NHSBT Activity Data** (primary): Annual/quarterly organ donation statistics by UK nation
   - URL: https://www.odt.nhs.uk/statistics-and-reports/organ-donation-and-transplantation-data/
   - Variables: deceased donors, consent rate, transplants, waiting list
   - Coverage: 2009–2024, nation-level

2. **ONS Population Estimates** (denominator): Mid-year population by nation
   - URL: ONS API or bulk download
   - For per-million-population rates

3. **NHSBT Organ Donation Register** (mechanism): Active registrations on the ODR
   - To test crowding-out hypothesis (do active registrations decline post-opt-out?)

## Fetch Strategy

1. Download NHSBT annual activity reports (PDF tables) and extract nation-level data
2. Cross-validate with NHSBT's online data portal
3. Download ONS population estimates for rate denominators
4. Construct nation × year panel

## Robustness

1. **Placebo test:** Use transplant types that should NOT respond to consent changes (e.g., living donor transplants — these don't involve deceased consent)
2. **Event study:** Show dynamic treatment effects (leads and lags)
3. **Leave-one-out:** Drop each nation separately
4. **Alternative outcomes:** Waiting list deaths (welfare measure)
5. **COVID adjustment:** Exclude 2020 or include COVID controls

## Exposure Alignment

Treatment is at the nation level: all adults who die in circumstances suitable for organ donation in a given nation are exposed to the deemed consent regime. The treatment directly affects the legal basis for proceeding with organ retrieval when the deceased has not made an explicit registration. Families of all potential deceased donors are exposed through the bedside conversation with Specialist Nurses for Organ Donation (SN-ODs), who inform them of the deemed consent status. The outcome (deceased donors per million population) is measured at the same nation level as treatment assignment. Living donors (placebo) are not exposed because living donation operates through a separate consent process unrelated to deemed consent legislation.

## Key Risk

The 4-cluster problem is the main threat to credibility. I mitigate with RI and transparency about inference limitations. The paper's contribution is less about precise causal magnitudes and more about documenting the paradox pattern across all three rollouts within a single system.
