# Research Plan: The Reallocation Mirage

## Research Question

Does banning second-home construction redirect investment toward commercial/hotel sectors, or does it freeze investment across all sectors? Switzerland's 2012 Second Home Initiative (Zweitwohnungsinitiative) banned new second homes in ~337 municipalities where second homes exceed 20% of housing stock. The core policy justification — that constraining residential construction frees capital for productive tourist infrastructure — has never been tested causally.

## Identification Strategy

**Primary: Continuous difference-in-differences with exposure intensity.**

Treatment intensity = pre-2012 municipality-level second-home share (continuous). Municipalities above 20% are directly constrained; those further above face greater binding constraints. Control group: municipalities below 20% (untreated). The surprise referendum outcome (polls predicted defeat, final margin 50.6%-49.4%) strengthens the case against anticipatory behavior.

**Specification:**
$$\log(Y_{it}) = \alpha_i + \gamma_t + \beta \cdot \text{SecondHomeShare}_i \times \text{Post}_t + \varepsilon_{it}$$

where $Y_{it}$ is construction investment in municipality $i$, year $t$, measured in CHF. Municipality and year fixed effects absorb level differences and national trends. Standard errors clustered at the municipality level.

**Complementary RDD:** The 20% threshold creates a sharp cutoff for treatment assignment. Municipalities just above vs. just below 20% provide local causal estimates.

## Expected Effects and Mechanisms

- **Residential construction:** Strong negative effect (direct ban). This is the "first stage."
- **Commercial/hotel construction:** Two competing hypotheses:
  - *Reallocation hypothesis:* Positive effect — freed land and capital redirect to tourism infrastructure
  - *Investment freeze hypothesis:* Negative effect — second-home demand was the anchor for local construction ecosystems; removing it collapses demand for contractors, materials, planning services
- **Mechanism test:** If β_commercial < 0 despite β_residential < 0, this rules out reallocation and supports the "investment ecosystem" channel.

## Primary Specification

1. **Main DiD:** Continuous treatment × post on log residential investment, log commercial investment, log total investment
2. **Event study:** Year-by-year interaction of second-home share × year dummies (1994-2023), omitting 2011
3. **RDD:** Running variable = second-home share, cutoff at 20%, outcome = change in construction investment 2012-2018 vs. 2006-2011
4. **Placebo:** Infrastructure investment (roads, utilities) should be unaffected by the second-home ban

## Data Sources and Fetch Strategy

1. **BFS Construction Investment Statistics** (PxWeb API)
   - Table `px-x-0904010000_201`: Municipal construction investment by sector, 1994-2023
   - Table `px-x-0904010000_203`: Alternative breakdown
   - ~2,100 municipalities × 30 years × 12 sectors

2. **ARE Second-Home Shares** (geo.admin.ch REST API)
   - Municipality-level second-home share (%)
   - Used to assign treatment intensity and 20% cutoff status

3. **BFS Population Statistics** (PxWeb API)
   - Municipal population for per-capita normalization
   - Table: `px-x-0102020000_201` or similar

## Key Risks

- BFS PxWeb API may have rate limits or require specific table IDs
- Municipal mergers between 1994-2023 require crosswalk (BFS SMMT)
- Some small municipalities may have zero construction in many years (use IHS transformation or extensive margin)
- ARE API format may require careful parsing
