# Research Plan: The Upgrading Dividend — Workers' Compensation and Occupational Risk-Sorting in Progressive-Era America

## Research Question

Did America's first social insurance program — workers' compensation — enable workers to sort *into* higher-paying but more dangerous occupations? Standard moral hazard predicts that insurance reduces care; we ask whether it also reduces the *career cost* of risk, enabling occupational upgrading that was previously too dangerous without a safety net.

## Identification Strategy

**Design:** Cross-cohort staggered difference-in-differences using individual-level linked census data.

**Treatment:** Staggered adoption of workers' compensation laws across 43 US states, 1911–1920. Five states (AR, FL, MS, NC, SC) never adopted by 1920, serving as the never-treated control group.

**Treatment timing cohorts:**
- 1911: 10 states (including WI, first adopter)
- 1912: 3 states
- 1913: 9 states
- 1914: 2 states
- 1915: 8 states
- 1917: 5 states
- 1918: 1 state
- 1919–1920: 5 states

**Data:** IPUMS MLP (Multigenerational Longitudinal Panel) linked census panels on Azure:
- `linked_1910_1920.parquet` (4.0 GB, 43.9M individuals) — treatment period
- `linked_1900_1910.parquet` (3.0 GB, 33.9M individuals) — pre-period (placebo)

**Unit of analysis:** Individual men aged 18–50, employed in 1910 (for treatment panel) or 1900 (for pre-period panel).

**Estimand:** ATT of workers' compensation on occupational risk-sorting, estimated via Callaway–Sant'Anna (2021) with individual-level data collapsed to state-cohort cells.

**Primary specification:**
1. Construct binary outcome: entry into hazardous industry (manufacturing/mining) between census rounds
2. Treatment group = workers in 1910 state that adopted WC by 1920 (all but 5 states)
3. Exploit staggered timing: dose = years of WC exposure by 1920
4. Pre-trend validation: same analysis on 1900–1910 panel (no WC existed)

## Expected Effects and Mechanisms

**Primary hypothesis:** WC adoption increases entry into hazardous occupations (manufacturing, mining) by reducing the downside risk of workplace injury.

**Mechanism:** Before WC, injured workers bore the full cost of lost wages and medical bills. WC provides 50–66% wage replacement, making dangerous-but-higher-paying jobs more attractive. This is the *upgrading dividend*: social insurance enables occupational mobility up the risk-return frontier.

**Expected magnitude:** Smoke test shows manufacturing entry rate of 11.1% in early-adopting states vs. 5.3% in never-treated (1910–1920), with stable pre-period rates (11.2% vs. 4.2% in 1900–1910). DiD estimate should be positive, moderate magnitude.

**Secondary outcomes:**
- OCCSCORE change (occupational income proxy)
- Self-employment exit (WC covers only wage workers)
- Interstate mobility (mover indicator)

**Heterogeneity:**
- Age (young vs. old — young workers more able to sort)
- Race (Black vs. White — differential access to covered employment)
- Initial sector (farm vs. non-farm origin)

## Data Source and Fetch Strategy

All data from Azure Blob Storage via DuckDB (no IPUMS API extract needed):
1. Read MLP linked panels from Azure using `scripts/lib/azure_data.R`
2. Filter to employed men aged 18–50
3. Merge with historical WC adoption dates (coded from Fishback & Kantor 2000)
4. Classify hazardous occupations using ind1950 codes (manufacturing: 306–499, mining: 206–299)
5. Construct outcome variables: ΔHazardous, ΔOCCSCORE, ΔSelfEmployed, Mover

**Key risk:** Link quality selection — MLP links are not random. Linked individuals tend to be more stable/literate. Will test for differential link rates by treatment status and report bounds.
