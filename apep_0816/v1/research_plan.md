# Research Plan: apep_0816

## Research Question

How fast do native workers adjust to skilled immigration restrictions? Specifically, what are the quarterly dynamics of native employment, hiring, separations, and earnings in H-1B-dependent county labor markets following the FY2004 cap reduction (195,000 → 65,000) and the FY2008 lottery introduction?

## Identification Strategy

**Triple-Difference (DDD)** exploiting three dimensions of variation:

1. **Cross-county**: Pre-shock tech employment share (NAICS 51+54 as share of total, measured 2002Q1) captures differential H-1B dependence
2. **Within-county age groups**: Workers aged 25-34 (high H-1B substitutability) vs 45-54 (low substitutability, within-county control)
3. **Across industries**: Professional/Technical services (NAICS 54, H-1B intensive) vs non-tech sectors

**Key specification:**
$$Y_{c,i,a,t} = \alpha_{c,i,a} + \gamma_t + \sum_{\tau} \beta_\tau \cdot \text{TechShare}_c \times \text{Young}_a \times \mathbf{1}(t=\tau) + X_{c,t}\delta + \varepsilon_{c,i,a,t}$$

Where:
- $Y_{c,i,a,t}$: log employment/hires/separations/earnings in county $c$, industry $i$, age group $a$, quarter $t$
- $\text{TechShare}_c$: 2002Q1 county tech employment share (continuous treatment intensity)
- $\text{Young}_a$: indicator for 25-34 age group (vs 45-54 control)
- $\tau$: quarterly event-time indicators relative to 2003Q4

**Why identification is credible:**
- FY2004 cap reduction was a mechanical sunset provision (Congress let the temporary increase expire), not a response to labor market conditions
- DDD controls for: (a) county-level shocks via age-group differencing, (b) national age-specific trends via county differencing, (c) industry-common shocks via county-age differencing
- Pre-trends testable at quarterly frequency (12 quarters pre-treatment)

## Expected Effects and Mechanisms

**Immediate (1-2 quarters):** Native hiring increases in high-tech counties as firms substitute toward domestic workers. Young workers benefit most as closest substitutes for H-1B holders.

**Medium-run (3-6 quarters):** Equilibrium adjustment — earnings rise for native tech workers if substitution is imperfect, or flatten if elastic supply.

**Long-run (8+ quarters):** Full adjustment — either persistent native employment gains (complementarity story) or reversion to baseline (adjustment dynamics).

**Key economic object: Adjustment half-life** — how many quarters until half the initial employment displacement dissipates?

## Primary Specification

Event-study DDD with continuous treatment intensity. Cluster standard errors at the state level (51 clusters).

**Robustness:**
1. Binary treatment (top vs bottom quartile tech share)
2. Alternative age-group comparisons (35-44 vs 45-54)
3. Bartik-style shift-share using pre-period industry composition
4. Dropping top-5 tech hubs (Silicon Valley, Seattle, Austin, Boston, DC)
5. Placebo outcomes: government employment (NAICS 92), mining (NAICS 21)
6. Pre-trend tests at quarterly frequency

## Data Source and Fetch Strategy

**Primary:** QWI (Quarterly Workforce Indicators) from Azure blob storage
- Path: `az://derived/qwi/sa/ns/*.parquet`
- Dimensions: county × quarter × NAICS sector × age group
- Period: 2000Q1-2025Q4
- Variables: Emp, HirA, HirN, Sep, EarnS

**Treatment construction:**
- County tech share = (NAICS 51 + NAICS 54 employment) / total employment, measured 2002Q1
- Read from same QWI data

**No additional data downloads needed** — everything is in Azure.
