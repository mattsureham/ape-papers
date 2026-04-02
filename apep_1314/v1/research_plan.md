# Research Plan: The Prudential Backlash — Bank Branch Closures and Populist Voting in Europe

## Research Question

Did EU regions that lost the most bank branches after the CRD IV/Basel III capital requirements experience the largest increases in populist party vote shares? We test whether prudential financial regulation — designed to stabilize the banking system — creates geographically concentrated political costs by producing "branch deserts" in peripheral regions.

## Identification Strategy

**Bartik (shift-share) design.** We exploit the interaction of:
- **Shift:** Country-level branch closure rates driven by CRD IV/Basel III implementation (2013-2016), which imposed capital adequacy, liquidity coverage, and leverage requirements disproportionately burdening small/cooperative banks.
- **Share:** Pre-shock (2008) NUTS2-level financial sector employment shares (Eurostat NACE Rev. 2 Section K), which proxy for regional dependence on bank branch networks.

The identifying assumption is that pre-shock financial employment shares are uncorrelated with post-shock populist voting trends, conditional on controls. This is plausible because pre-2008 financial employment reflects historical banking structure (cooperative bank presence, branch density norms) rather than political preferences.

**Additional variation:** SSM (Single Supervisory Mechanism, November 2014) applied only to Eurozone countries, creating a partial-treatment group. Non-Eurozone EU members (Poland, Hungary, Czech Republic, Sweden, Denmark, Romania, Bulgaria, Croatia) experienced CRD IV but not SSM supervision, providing a useful comparison.

## Expected Effects and Mechanisms

1. **Main effect:** Regions with higher predicted branch losses show larger increases in populist party vote shares in national and European Parliament elections.
2. **Mechanism — financial exclusion:** Branch closures reduce access to credit and basic banking services, disproportionately affecting SMEs, elderly, and rural populations. This creates a "left behind" grievance that populist parties exploit.
3. **Heterogeneity:** Effects should be stronger in regions with (a) lower broadband penetration (less digital banking substitution), (b) higher elderly population shares, (c) higher pre-shock cooperative bank dependence.

## Primary Specification

$$\Delta \text{PopulistVote}_{r,t} = \beta \cdot \widehat{\text{BranchLoss}}_{r,t} + X'_{r,t}\gamma + \alpha_c + \delta_t + \varepsilon_{r,t}$$

Where $r$ indexes NUTS2 regions, $t$ indexes election periods, $\widehat{\text{BranchLoss}}_{r,t}$ is the Bartik-predicted branch loss (pre-shock financial employment share $\times$ national closure rate), $\alpha_c$ is country fixed effects, and $\delta_t$ is election-period fixed effects.

## Data Sources

| Source | Variable | Level | Years | Access |
|--------|----------|-------|-------|--------|
| ECB SSI (SDMX) | Bank offices per country | Country-year | 1997-2024 | Open API |
| Eurostat lfst_r_lfe2en2 | Employment by NACE section | NUTS2-year | 2008-2023 | Open API |
| EU-NED | Election results by party | NUTS2-election | Various | Open download |
| PopuList | Populist party classification | Party-level | Through 2023 | Open |
| Eurostat demo_r_d2jan | Population by age | NUTS2-year | 2008-2023 | Open API |
| Eurostat isoc_r_iuse_i | Internet use by region | NUTS2-year | 2008-2023 | Open API |

## Fetch Strategy

1. ECB SSI via SDMX REST API (JSON format)
2. Eurostat via `eurostat` R package
3. EU-NED: download CSV files from Harvard Dataverse
4. PopuList: download party classification from popu-list.org

## Exposure Alignment

The treatment is the interaction of the 2008 NACE K financial employment share at the NUTS2 level with a post-CRD IV indicator (2014+). The unit of observation is the NUTS2-year panel. The treatment affects regions through two channels: (1) direct financial sector employment losses from branch closures and bank consolidation; (2) indirect effects through reduced credit access for local businesses and households. However, as the paper demonstrates, the NACE K employment share is a poor proxy for branch banking exposure because it conflates retail banking with insurance, asset management, and investment banking. Regions with high NACE K shares (financial centers) are fundamentally different from branch-dependent peripheral regions. This exposure misalignment is the paper's central finding.

## Key Risks

1. **NUTS2 branch allocation:** ECB SSI is country-level. Bartik allocation introduces measurement error. Mitigated by using NACE K employment as a well-measured proxy.
2. **Populist party classification:** Boundary of "populist" is contested. Mitigated by using PopuList (expert-coded, standard in literature) and showing robustness to alternative classifications.
3. **Confounders:** Post-2008 austerity, migration crisis, other shocks. Mitigated by country × period FEs and regional controls.
