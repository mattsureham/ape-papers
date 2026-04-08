# Research Plan: The Annuity Squeeze — Switzerland's BVG Conversion Rate Reduction and the Capital-vs-Annuity Choice

## Research Question

Did Switzerland's phased reduction of the BVG mandatory pension conversion rate from 7.2% to 6.8% (2005-2014) shift retirees from annuity payouts toward lump-sum capital withdrawals? The conversion rate mechanically determines the annual annuity per franc of accumulated pension capital. A lower rate reduces annuity generosity, potentially making lump-sum withdrawal relatively more attractive — particularly for workers whose pension wealth is predominantly in the mandatory BVG portion.

## Policy Background

The Berufliches Vorsorgegesetz (BVG, SR 831.40) mandates occupational pensions (Pillar 2) for Swiss workers. The federal minimum conversion rate translates mandatory pension capital into annual annuity:

| Period | Conversion Rate | Cumulative Cut from 7.2% |
|--------|----------------|--------------------------|
| 2002-2004 | 7.2% | — |
| 2005-2006 | 7.1% | -1.4% |
| 2007-2009 | 7.0% | -2.8% |
| 2010-2013 | 6.9% | -4.2% |
| 2014+ | 6.8% | -5.6% |

A 2010 referendum to lower further to 6.4% was defeated (Swissvotes ballot 538).

## Identification Strategy

**Cohort x Conversion Rate Exposure DiD:**

Workers retiring at statutory age (65 for men, 64 for women) in year t face conversion rate r(t). This creates cohort-based variation:

- **Pre-reform cohorts** (retiring 1999-2004): all faced 7.2% — serve as control
- **Reform cohorts** (retiring 2005-2014): faced progressively lower rates — treatment intensity varies by retirement year

**Primary specification:**
Y_{t} = alpha + beta * ConversionRateCut_{t} + X_{t}' * gamma + epsilon_{t}

Where Y_{t} is the capital-withdrawal share (capital beneficiaries / total beneficiaries) and ConversionRateCut_{t} is the cumulative percentage point reduction from 7.2%.

**Key identification assumption:** Absent the conversion rate reduction, the capital-vs-annuity choice trend would have continued along its pre-reform trajectory. Supported by: no simultaneous changes to AHV/AVS reference age or contribution rates during 2005-2014.

**Placebo tests:**
1. Cohorts retiring 2008-2009 (between the 2007 and 2010 steps) — no rate change
2. Disability pensions (not affected by conversion rate) as placebo outcome
3. Pre-reform trend test (1999-2004 should show no structural break)

## Expected Effects

- **Primary:** Lower conversion rate → higher capital withdrawal share. A 5.6% cut in annuity generosity should push marginal retirees toward lump-sum withdrawal, especially those with small mandatory balances.
- **Mechanism:** The effect should be stronger for pension funds with lower above-mandatory buffers (more exposure to the mandatory rate).
- **Magnitude prior:** Based on Bütler & Teppa (2007) finding that annuity take-up responds to conversion rates, expect moderate positive effect on capital share (SDE 0.05-0.15).

## Data Sources

### Primary: BFS Pensionskassenstatistik
- **Table px-x-1303030000_141:** Benefits table — annual counts of capital payment beneficiaries vs. current annuity beneficiaries, 2004-2024
- **Table px-x-1303030000_101:** Pension fund assets — capital payment amounts and exit benefits
- Access: BFS PXWeb API (no authentication needed)
- Unit: aggregate by year and gender

### Secondary: BFS Employment Statistics
- Canton-level employment rates by age group (55-70) from STATPOP/SAKE
- For retirement timing analysis

## Primary Specification (R)

```r
# Callaway-Sant'Anna not needed here (single treatment timing per cohort)
# Use simple OLS with cohort-year panel

# Main regression: capital share on conversion rate cut
feols(capital_share ~ conversion_rate_cut | gender, 
      data = panel, vcov = "hetero")

# Event study: year dummies relative to 2004
feols(capital_share ~ i(year, ref = 2004) | gender,
      data = panel, vcov = "hetero")
```

## Robustness Checks

1. Gender-specific estimates (men retire at 65, women at 64)
2. Placebo: disability pension beneficiaries
3. Pre-trend test (1999-2004)
4. Structural break test at each step (2005, 2007, 2010, 2014)
5. Capital amount per beneficiary (intensive margin)
6. Post-2014 stability check (rate fixed at 6.8%)

## Figure Plan (≥5)

1. **Event study:** Capital withdrawal share by year, with conversion rate steps marked
2. **Binscatter:** Conversion rate cut vs. capital share change
3. **Time series:** Capital vs. annuity beneficiary counts over time, by gender
4. **Structural break:** Pre-reform trend extrapolation vs. actual
5. **Placebo:** Disability pension trends (should show no break)
6. **Mechanism:** Capital share by pension fund size (proxy for mandatory share exposure)
