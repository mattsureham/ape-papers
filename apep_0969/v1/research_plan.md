# Research Plan: The Compliance Cliff

## Research Question

When Japan's five-year overtime exemption for transport, construction, and healthcare expired in April 2024, did binding overtime caps actually reduce hours worked — or did firms shift to unpaid overtime, eroding worker welfare gains?

## Identification Strategy

**Industry-level Difference-in-Differences.** The 2018 Work Style Reform Act imposed overtime caps (720h/year, 100h/month) on most industries starting April 2019 (large firms) and April 2020 (SMEs). Three sectors — transport, construction, and medical/healthcare — were explicitly exempted until April 2024, with sector-specific caps (960h/year for transport and doctors, 720h/year for construction).

**Treatment:** April 2024 application of overtime caps to the three exempted industries.
**Control:** 13+ industries already subject to caps since 2019.
**Pre-period:** April 2019 – March 2024 (60 months).
**Post-period:** April 2024 – latest available (target: 6-12 months).

**Key design features:**
- Treatment timing is legislatively predetermined (set in 2018 law), eliminating endogeneity concerns about adoption timing
- Monthly frequency enables precise event study
- Within-exempted-sector variation in cap levels (960h vs 720h) provides treatment intensity variation
- "Already-treated" industries serve as control group — they experienced the regulatory shock 5 years earlier

**Estimator:** TWFE is appropriate here because treatment timing is common for the treated group (all three exempted sectors treated simultaneously in April 2024). No staggered adoption concerns. Industry × month panel with industry and year-month fixed effects.

## Expected Effects and Mechanisms

1. **Primary:** Overtime hours fall in exempt industries relative to control after April 2024
2. **Mechanism decomposition:** (a) reduced paid overtime, (b) potential rise in "service overtime" (unpaid), (c) additional hiring to compensate lost hours
3. **Earnings:** Total earnings may fall if overtime premium reduction outweighs base pay adjustments
4. **Heterogeneity:** Transport (highest baseline overtime at 20.9h/month) should show largest effects; construction seasonal patterns may dilute

## Primary Specification

$$Y_{it} = \alpha_i + \gamma_t + \beta \cdot (\text{Exempt}_i \times \text{Post}_t) + \varepsilon_{it}$$

Where:
- $Y_{it}$: monthly overtime hours (or total hours, earnings) for industry $i$ in month $t$
- $\alpha_i$: industry fixed effects
- $\gamma_t$: year-month fixed effects
- $\text{Exempt}_i$: indicator for transport, construction, or healthcare
- $\text{Post}_t$: indicator for April 2024 onwards
- Cluster SEs at industry level; supplement with wild cluster bootstrap (few treated clusters)

## Data Source and Fetch Strategy

**Primary:** MHLW Monthly Labour Survey (毎月勤労統計調査) via Japan's e-Stat API (ESTAT_APP_ID available in .env)
- Table ID: Survey covers 16 major industries
- Variables: total hours worked, scheduled hours, overtime hours, contractual earnings, overtime pay
- Establishment size breakdowns (5-29, 30-99, 100-499, 500+)
- Monthly frequency, January 2018 – latest available

**Fetch approach:**
1. Query e-Stat API for Monthly Labour Survey tables
2. Download industry × month × establishment size data
3. Construct panel: industry-size-month cells
4. Define treatment: transport (運輸業), construction (建設業), healthcare (医療・福祉)

## Exposure Alignment

The treatment (overtime cap application) targets all workers in the three exempt industries. The Labour Force Survey outcome — average monthly hours worked — is measured at the industry level for all employed workers. This creates alignment between treatment and measurement: all workers in the exempt industries are exposed to the cap, and the LFS captures hours for all employed workers in each industry. The caps are industry-wide regulations (not firm-specific or worker-specific), so industry-level measurement matches the treatment assignment level. The potential concern is that within-industry heterogeneity (e.g., some sub-occupations were more affected) is averaged out at the industry level, but this is inherent to the policy's design — the exemption applied to entire industries.

## Risks and Mitigations

1. **Few treated clusters (N=3 industries):** Use randomization inference (permutation of treatment assignment across industries) and wild cluster bootstrap. Report both.
2. **COVID contamination of pre-period:** Essential sectors (transport, construction, healthcare) had different COVID trajectories. Include COVID mobility controls or restrict event study interpretation to post-COVID window (2022-2024 vs 2024+).
3. **Anticipation effects:** Caps were pre-announced in 2018 with 5-year delay. Firms may have begun adjusting before April 2024. Test for pre-trends in final 12 months before treatment.
4. **Measurement:** Monthly Labour Survey measures paid overtime hours. Unpaid "service overtime" is a known phenomenon but not directly observed.
