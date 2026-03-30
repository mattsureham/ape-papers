# Research Plan: Banning Loyalty Penalties in Insurance

## Research Question

Does banning price-walking (loyalty penalties) in insurance reduce consumer harm? The FCA's General Insurance Pricing Practices (GIPP) reform, effective January 1, 2022, prohibited UK insurers from charging renewal customers more than equivalent new-business prices for home and motor insurance. This paper estimates the causal effect on consumer complaints and insurer underwriting outcomes using a cross-product difference-in-differences design.

## Identification Strategy

**Cross-product DiD.** The pricing remedy applies only to motor and home (property) insurance. Other general insurance lines — pet, travel, medical/health, warranty, legal expenses, assistance — face the same macroeconomic environment but were not subject to the ban. This creates a sharp treatment/control comparison at a single national implementation date.

- **Treatment group:** Motor & transport, Property (home) insurance
- **Control group:** Pet, Travel, Medical/health, Warranty, Assistance, Legal expenses
- **Treatment date:** January 1, 2022 (sharp, single date)
- **Pre-period:** 2016 H2 – 2021 H2 (10 half-year periods in FCA data)
- **Post-period:** 2022 H1 – 2025 H1 (7 half-year periods)

**Identifying assumption:** Absent the ban, complaint trends in motor/home would have evolved parallel to untreated insurance lines. Testable with 10 pre-treatment periods.

**Threats and solutions:**
- COVID: Disproportionately affects travel insurance (lockdown claims). Exclude travel in robustness, or include COVID-period dummies.
- Consumer Duty (July 2023): Applies to ALL insurance lines equally → captured by time FE.
- Inflation: Affects all lines similarly → captured by time FE.

## Expected Effects and Mechanisms

1. **Complaints should decline** for treated products if price-walking was a primary source of consumer harm. The ban forces insurers to offer renewal prices ≤ ENBP, reducing the "loyalty penalty."
2. **Insurer profitability** may adjust: net written premium could fall in treated lines (lower renewal prices), loss ratios could improve or worsen depending on how firms adjust underwriting.
3. **FOS escalation** may decline for treated products as fewer disputes arise from pricing practices.
4. **Mechanism:** The ban eliminates the asymmetric pricing channel. If complaints fall, it confirms that price-walking was a binding source of consumer detriment.

## Primary Specification

```
Y_{pt} = α_p + λ_t + β · (Treated_p × Post_t) + ε_{pt}
```

Where p indexes product line, t indexes time period, α_p are product FE, λ_t are time FE. β captures the treatment effect of the price-walking ban on treated relative to untreated insurance lines.

**Inference:** Product-level clustering with wild cluster bootstrap (few clusters). Randomization inference as additional robustness.

## Data Sources

### Primary: FCA Aggregate Complaints Data
- Source: fca.org.uk/data (free Excel downloads)
- Coverage: 2016 H2 – 2025 H1 (18 half-year periods)
- Variables: Complaints opened, closed, upheld, redress paid, by insurance sub-product
- Products: Motor & transport, Property, Pet, Travel, Medical/health, Warranty, Assistance

### Secondary: Bank of England Insurance Aggregate Data
- Source: bankofengland.co.uk (CSV download)
- Coverage: 2017 Q1 – 2025 Q3 (35 quarters)
- Variables: Net Written Premium, Loss Ratio by line of business
- Lines: Motor liability, Motor other, Property, Medical expense, Legal expenses, Assistance

### Tertiary: Financial Ombudsman Service Quarterly Data
- Source: financial-ombudsman.org.uk
- Coverage: Q1 2021/22 onward (quarterly)
- Variables: Product-level complaint volumes

## Robustness Checks

1. Exclude travel insurance (COVID-confounded)
2. Drop 2020 H1 – 2020 H2 (COVID acute period)
3. Synthetic control for motor and home separately
4. Placebo test: apply "treatment" to untreated lines
5. Event study with half-year leads and lags
6. Triple-diff exploiting within-treated variation (motor vs. home)
