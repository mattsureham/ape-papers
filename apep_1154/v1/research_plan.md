# Research Plan: The Implementation Gap — EU Transposition Delay and Firm Entry

## Research Question

Does late transposition of EU directives into national law suppress firm entry in affected sectors? When a directive's deadline passes but a member state has not yet transposed it, firms face regulatory uncertainty — the "implementation gap." This paper provides the first causal evidence on the economic costs of transposition delay, exploiting within-directive cross-country variation in transposition timing.

## Identification Strategy

**Design:** Staggered difference-in-differences exploiting the fact that different EU member states transpose the same directive at different times.

**Unit of observation:** Country × NACE sector × year

**Treatment:** Binary indicator for whether a country-sector is in "regulatory limbo" — the directive deadline has passed but national transposition has not occurred. Intensity measure: months of delay beyond the deadline.

**Key variation:** For the same directive, some countries transpose on time while others delay by months or years. Within-directive variation absorbs all directive-level confounds (content, ambition, political salience). Country × sector fixed effects absorb all time-invariant differences across regulatory environments.

**Estimator:** Callaway & Sant'Anna (2021) with staggered treatment timing. Treatment cohorts defined by the year a country enters "limbo" for a given directive-sector pair.

**Threats and responses:**
1. *Endogenous delay:* Countries may delay because of economic conditions → control for country × year FE; placebo in unaffected sectors
2. *Anticipation:* Firms may respond before the deadline → test for pre-trends; check for effects in years before deadline
3. *Heterogeneous treatment effects:* Different directives have different economic salience → weight by directive regulatory complexity

## Expected Effects and Mechanisms

**Primary hypothesis:** Transposition delay reduces firm entry (birth rate) in affected sectors. During limbo, entrepreneurs face uncertainty about which regulatory regime will apply — the old national rules or the forthcoming EU-mandated rules. This uncertainty raises the option value of waiting.

**Mechanism:** Regulatory uncertainty increases the cost of entry by making compliance requirements unpredictable. Firms cannot plan for a regulatory environment that doesn't yet exist in national law.

**Expected magnitude:** Moderate negative effect (SDE -0.05 to -0.15). The EU itself estimates transposition delay costs ~€6 billion annually, but no micro-level evidence exists.

**Heterogeneity:**
- Larger effects for regulatory-intensive sectors (finance, environment, energy)
- Larger effects in countries with weaker rule of law (more uncertainty about eventual implementation)
- Larger effects for complex directives (more articles, more discretionary provisions)

## Primary Specification

```
Y_{cst} = α + β × Limbo_{cst} + γ_{cs} + δ_{ct} + ε_{cst}
```

Where:
- Y_{cst} = firm birth rate in country c, sector s, year t
- Limbo_{cst} = 1 if directive deadline for sector s has passed but country c has not transposed
- γ_{cs} = country × sector fixed effects
- δ_{ct} = country × year fixed effects
- Clustering at country level (27 clusters) with wild cluster bootstrap

## Data Sources and Fetch Strategy

### 1. Transposition Data (CELLAR SPARQL via eurlex R package)
- All EU directives with transposition deadlines (2005-2024)
- National implementation measures with notification dates per member state
- Map directives to NACE sectors using EUR-Lex subject matter classifications
- Source: `eurlex::elx_make_query("directive", include_date_transpos = TRUE)`

### 2. Firm Entry Data (Eurostat Business Demography)
- Dataset: `bd_enace2_r3` — employer business demography by NACE Rev.2 at NUTS3 level
- Variables: firm births (V11920), active enterprises (V11910), employment in new firms (V16920)
- Coverage: ~1,250 NUTS3 × 11 NACE sectors × 13 years
- Source: `eurostat` R package

### 3. Controls
- GDP per capita by country (Eurostat `nama_10_gdp`)
- Regulatory quality index (World Bank WGI)
- Directive complexity: number of articles, recitals (from CELLAR metadata)

## Robustness Checks
1. Placebo sectors not targeted by the directive
2. Pre-trend tests (event study around deadline)
3. Continuous treatment (months of delay) instead of binary
4. Drop chronically late transposers (IT, FR, ES)
5. Wild cluster bootstrap for inference with 27 clusters
6. Sun & Abraham (2021) interaction-weighted estimator as alternative
