# Research Plan: Paying on Time Saves Firms? The EU Late Payment Directive and Small Firm Survival

## Research Question

Does the EU Late Payment Directive (2011/7/EU) — which mandated 30-day public-authority payment, 8%+ late interest, and EUR 40 flat-rate compensation — improve small firm survival in countries with worse pre-directive payment cultures? The paper exploits the triple interaction of (i) the directive's near-simultaneous March 2013 transposition deadline, (ii) cross-country variation in pre-existing payment delay norms, and (iii) differential exposure across firm size classes (small firms lack credit lines to absorb late payments).

## Identification Strategy

**Triple-difference design:**

Y_{c,s,t} = country×size FE + country×year FE + size×year FE + β₁(Post_t × PayDelay_c × Small_s) + ε_{c,s,t}

- **First difference (time):** Pre (2010-2012) vs. post (2014-2020) the March 2013 transposition deadline
- **Second difference (payment culture):** Continuous treatment intensity from pre-directive average B2B/B2G payment delays by country (Intrum European Payment Report or similar)
- **Third difference (firm size):** Small firms (0-9 employees) vs. large firms (10+ employees) — small firms are most exposed to late payment liquidity shocks

The coefficient β₁ captures: the differential change in firm survival for small firms (relative to large) in countries with longer payment delays (relative to prompt payers) after the directive.

## Expected Effects and Mechanisms

**Primary hypothesis:** The directive should disproportionately improve small firm survival in high-delay countries, by:
1. Reducing liquidity constraints (faster public-sector payments)
2. Creating legal tools (interest + compensation claims) that shift bargaining power
3. Formalizing payment norms through legal codification

**Alternative hypothesis (null):** Legal mandates fail to change entrenched payment norms — compliance is low, enforcement is weak, and the directive is a "paper tiger." This is plausible given that as of 2023, average B2B payment was still 61.8 days vs. the 30-day mandate.

Either result is interesting and publishable.

## Primary Specification

Outcome: 3-year firm survival rate from Eurostat `bd_9bd_sz_cl_r2`, by country × size class × year.

Triple-diff with saturated fixed effects:
- Country × size class FE (absorb time-invariant country-size differences)
- Country × year FE (absorb common shocks within each country)
- Size class × year FE (absorb EU-wide size-specific trends)

Treatment intensity: pre-2013 average payment days by country (continuous).

Inference: Wild cluster bootstrap at the country level (28 clusters).

## Data Sources

1. **Eurostat bd_9bd_sz_cl_r2** — Business demography by size class: firm birth rate, death rate, 3-year survival rate. 35 countries, 2010-2020, ~205K values. Size classes: 0, 1-4, 5-9, 10+.

2. **Payment culture intensity** — Pre-directive average payment days. Options:
   - Intrum European Payment Report (B2B and B2G payment terms)
   - OECD "Timely payments" indicators
   - World Bank Doing Business "Time to resolve insolvency"
   - Constructed from Eurostat SBS payment data if available

3. **Eurostat sbs_sc_sca_r2** — Structural Business Statistics by size class (secondary: value added, employment, turnover)

## Fetch Strategy

1. Use `eurostat` R package to download `bd_9bd_sz_cl_r2` directly
2. Construct payment culture variable from publicly available payment delay data
3. Merge on country code, create triple-diff panel
4. All data accessible via R package or direct Eurostat API — no API keys needed

## Robustness Checks

- Event study: β₁ estimated separately for each year relative to 2013
- Leave-one-out: drop each country sequentially
- Alternative intensity measures (binary above/below median delay, OECD insolvency time)
- Placebo: firm size classes that should not be differentially affected (all 10+ vs. all 0-4)
- HonestDiD sensitivity analysis for parallel trends violations
- Sector-level heterogeneity (manufacturing vs. services)
