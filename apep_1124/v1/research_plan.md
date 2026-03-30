# Research Plan: Sanctions at Sea — EU IUU Fishing Cards and Satellite-Measured Fishing Effort

## Research Question

Do EU illegal, unreported, and unregulated (IUU) fishing "yellow card" trade-sanction threats reduce actual fishing effort by sanctioned countries' fleets, as measured by satellite AIS tracking? Prior literature measures IUU carding effects only through trade flows (Vatsov 2023 finds 23% seafood export decline). No paper has measured whether sanctioned fleets actually change fishing behavior — the trade decline could reflect EU import substitution rather than fishing deterrence.

## Identification Strategy

**Staggered difference-in-differences** comparing fishing effort (fishing hours) of carded vs. never-carded flag-state fleets before and after yellow card issuance.

- **Treatment:** EU yellow card issuance date for each country (27 countries carded at staggered dates, 2012–2023)
- **Unit of observation:** Flag state × year (or flag state × quarter)
- **Outcome:** Total fishing hours by flag-state fleet (from GFW satellite data)
- **Estimator:** Callaway and Sant'Anna (2021) — handles staggered adoption, avoids negative weighting of TWFE
- **Clustering:** Flag state level (27 clusters → wild cluster bootstrap for conservative inference)
- **Key robustness:** (1) Placebo using non-EU-exporting fleets; (2) Heterogeneity by EU export dependence; (3) Event study for pre-trend validation; (4) Drop early/late cohorts

## Expected Effects and Mechanisms

**Primary hypothesis:** Yellow cards reduce total fishing hours of carded fleets (negative effect).

**Mechanisms:**
1. **Deterrence channel:** Threat of EU market loss (EU is world's largest seafood importer) incentivizes governments to enforce fisheries law → reduced IUU fishing → lower total effort
2. **Displacement channel:** Effort shifts from EU-monitored waters to non-monitored waters (net effect on total hours ambiguous)
3. **Fleet contraction:** Sanctioned countries decommission or reflag vessels

**Null alternative:** Yellow cards are cheap talk — governments make cosmetic regulatory changes without enforcement, and fleets fish as before. The 23% trade decline reflects EU importer substitution, not behavioral change.

## Exposure Alignment

**Who is actually affected by treatment?** The EU yellow card targets the *government* of the flag state, threatening to ban seafood imports from that country unless fisheries governance improves. The treatment therefore operates through a chain: EU → national government → enforcement agencies → individual fishers/vessel operators. The key alignment question is whether the government has both the incentive and capacity to translate the trade threat into behavioral change at the vessel level.

**Exposure variation:** Not all carded countries are equally exposed. Countries with high EU seafood export shares (e.g., Thailand, Vietnam) face greater economic incentives to reform than those with diversified markets (e.g., South Korea, which exports primarily to Japan). The treatment is binary (yellow card issued or not), but the economic bite varies with pre-treatment EU market dependence. Countries with low EU exposure may receive yellow cards but face minimal economic pressure to enforce changes.

**Outcome alignment:** The outcome (total AIS-detected fishing hours) captures all fishing effort by a flag state's fleet, not just IUU fishing or fishing for EU-bound catch. This is broader than the policy target and may attenuate effects if yellow cards reduce IUU fishing specifically while total effort is maintained through legal fishing expansion.

## Primary Specification

$$Y_{it} = \alpha_i + \lambda_t + \beta \cdot \text{Carded}_{it} + \varepsilon_{it}$$

Where $Y_{it}$ is log fishing hours for flag state $i$ in year $t$, with flag-state and year fixed effects. CS estimator aggregates cohort-specific ATTs.

## Data Sources

### 1. Global Fishing Watch (GFW) — Fishing Effort
- **Source:** GFW public dataset on BigQuery (`global-fishing-watch.gfw_public_data`)
- **Coverage:** 2012–2024, 190K+ vessels, daily resolution
- **Key table:** `fishing_effort` — aggregated fishing hours by flag state, date, gear type
- **Strategy:** Query BigQuery to aggregate flag_state × year fishing hours (avoids 26 GB download)
- **Alternative:** If BigQuery access fails, download fishing-vessels-v3.csv (110 MB) from Zenodo and fleet-daily aggregate CSVs

### 2. EU IUU Carding Decisions
- **Source:** European Commission IUU carding press releases (hand-coded from official decisions)
- **Treatment panel:** 27 countries with yellow/red card dates
- **Key countries:** Thailand (Apr 2015), Vietnam (Oct 2017), South Korea (Nov 2013), Philippines (Jun 2014), Taiwan (Oct 2015), Cameroon (Feb 2021), etc.

### 3. EU Seafood Trade (for heterogeneity)
- **Source:** UN Comtrade via API (HS codes 03, 1604, 1605)
- **Purpose:** Measure pre-treatment EU export dependence for heterogeneity analysis

## Fetch Strategy

1. Query GFW BigQuery for flag_state × year × gear_type fishing hours (small result set, ~5K rows)
2. Construct treatment panel from EU Commission IUU carding history
3. Query Comtrade for seafood exports to EU by country × year
4. Merge and construct analysis panel
