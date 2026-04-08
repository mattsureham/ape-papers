# Research Plan: The Digitization Dividend — One-Stop-Shop Government and the Collapse of Petty Corruption in Azerbaijan

## Research Question

Does centralizing and digitizing government services eliminate petty corruption? Azerbaijan's ASAN (Azerbaijan Service and Assessment Network) reform bundled ~360 government services under electronic one-stop-shop centers, rolling out geographically from Baku (2012) to 25+ rayons by 2020. We exploit this staggered rollout using firm-level panel data from the World Bank's Business Environment and Enterprise Performance Survey (BEEPS) to identify the causal effect on bribery incidence, informal payments, and formal sector entry.

## Identification Strategy

**Design:** Staggered geographic difference-in-differences using three BEEPS survey waves (2009, 2013, 2019) and ASAN rollout timing across Azerbaijan's regional strata.

- **Wave 1 (2009):** Pre-ASAN — all firms are controls
- **Wave 2 (2013):** ASAN operational in Baku only — Baku firms treated, regional firms control
- **Wave 3 (2019):** ASAN operational nationwide — all regions treated (staggered timing)

The key comparison is Baku firms vs. non-Baku firms across waves, leveraging the staggered geographic expansion. With only 4 regional strata in BEEPS, we use the Baku vs. rest-of-country contrast for the primary specification.

**Built-in placebo:** ASAN covers specific services (registration, licensing, permits, property). Services NOT covered (labor inspections, sector-specific environmental permits) should show smaller or null effects — a within-firm placebo test.

## Expected Effects and Mechanisms

1. **Direct effect:** Electronic payments and logged transactions eliminate opportunities for bribe solicitation → bribery incidence falls
2. **Entry effect:** Lower corruption barriers → more formal business registrations
3. **Heterogeneity:** Smaller firms face higher extortion risk → larger ASAN effect for SMEs
4. **Service heterogeneity:** Effects concentrated in ASAN-covered services vs. excluded services

## Primary Specification

$$Y_{i,r,t} = \alpha + \beta \cdot \text{ASAN}_{r,t} + \gamma_r + \delta_t + \mathbf{X}_{i,t}'\theta + \varepsilon_{i,r,t}$$

Where:
- $Y_{i,r,t}$: bribery outcome for firm $i$ in region $r$ at wave $t$
- $\text{ASAN}_{r,t}$: indicator = 1 if region $r$ has an ASAN center at wave $t$
- $\gamma_r$: region fixed effects
- $\delta_t$: wave fixed effects
- $\mathbf{X}_{i,t}$: firm controls (size, age, sector, ownership)
- Clustering: region level (4 clusters → wild cluster bootstrap for inference)

## Data Source and Fetch Strategy

1. **BEEPS microdata:** World Bank Microdata Library — Azerbaijan 2009, 2013, 2019 waves. Contains firm-level bribery questions (b7a, j2, j7a), region strata, firm characteristics. Download via World Bank API or direct file access.

2. **Aggregate indicators (supplementary):**
   - IC.FRM.BRIB.ZS (% firms experiencing bribery) from WDI
   - IC.BUS.NREG (new business registrations) from WDI
   - These provide country-level context and time-series evidence

3. **ASAN rollout timeline:** From official ASAN sources and media reports — hand-coded mapping of center opening dates to BEEPS regional strata.

## Exposure Alignment

**Who is treated:** All firms, citizens, and government agencies in Azerbaijan, starting December 2012 when ASAN became operational. The treatment is national in scope. **Treatment-eligible population:** All entities interacting with government services bundled under ASAN (~360 services). **Exposure timing:** Sharp at December 2012. Cross-country design treats the national launch as the treatment event. **Who responds:** Government effectiveness captures bureaucratic quality perceived by firms, experts, and citizens. Business registrations capture formal entry decisions. Bribery captures firm-level corruption experience.

## Key Risks

1. **Small sample:** ~300-360 firms per wave, 4 regional strata. Wild cluster bootstrap essential.
2. **Only 1 pre-treatment period:** Cannot test pre-trends formally.
3. **Repeated cross-section vs. panel:** BEEPS may not track same firms across waves — treat as repeated cross-sections.
4. **Concurrent reforms:** Oil price crash (2014-2016), currency devaluation (2015) — need to argue these affected all regions equally or control for them.
