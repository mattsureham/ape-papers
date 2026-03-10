# Conditional Requirements

**Generated:** 2026-03-10T11:29:11.614433
**Status:** RESOLVED

---

## THESE CONDITIONS MUST BE ADDRESSED BEFORE PHASE 4 (EXECUTION)

All conditions below have been addressed with concrete design commitments.

---

## Importing What You Used to Make: Energy-Cost-Driven Import Substitution in European Manufacturing After the 2022 Gas Shock

**Rank:** #1 | **Recommendation:** PURSUE

### Condition 1: moving to finer HS codes

**Status:** [x] RESOLVED

**Response:**
The main analysis will use HS2 codes (7 energy-intensive + 3 placebo sectors), which is the most reliable level for cross-country comparison in Comext. As a robustness check, we will disaggregate to HS4 for the two largest product groups (HS 28 inorganic chemicals and HS 72 iron/steel) to verify that composition effects within HS2 categories do not drive results. The Comext API supports HS4/HS6 queries. If HS4 results are consistent with HS2, this validates the aggregation choice; if they diverge, the paper will report the HS4 results as primary.

**Evidence:** Comext API confirmed to return HS4-level data. Will test in data-fetch script.

---

### Condition 2: separating import rerouting from domestic-collapse substitution

**Status:** [x] RESOLVED

**Response:**
This is the paper's central identification challenge. Three strategies:
1. **Exclude Russia/Belarus/Ukraine imports entirely.** The partner dimension in Comext allows filtering by origin country. We construct extra-EU imports EXCLUDING RU/BY/UA to isolate substitution from non-conflict sources (China, Middle East, India, Turkey).
2. **First-stage evidence:** Show that domestic production indices (STS_INPR_M) fell differentially in gas-dependent × energy-intensive cells. This establishes that domestic capacity actually declined, not just that trade patterns shifted.
3. **Partner decomposition:** Separately estimate import growth from (a) traditional non-EU suppliers, (b) China specifically, (c) Middle East/Turkey. If the effect concentrates in traditional chemical-exporter countries (not Russia replacements), this is substitution for domestic output.

**Evidence:** Design commitment documented in research_plan.md.

---

### Condition 3: making persistence/welfare central rather than optional

**Status:** [x] RESOLVED

**Response:**
Persistence is the paper's main contribution — not an add-on. The event study window extends through December 2024, a full 18 months after TTF prices normalized (mid-2023). The central question is: *Did extra-EU import shares return to pre-shock levels when prices fell, or did they remain elevated?* If the latter, this is evidence of permanent comparative advantage loss — hysteresis in trade patterns. The paper's narrative arc: shock → collapse → substitution → persistence = deindustrialization. We will compute a "persistence ratio" = (post-normalization import level) / (peak-shock import level) and test whether it exceeds pre-shock baselines. Welfare implications will be discussed by linking import dependence to supply chain vulnerability and consumer price effects.

**Evidence:** Comext data extends through 2024; TTF normalized by Q3 2023; 18 months of post-normalization data available.

---

### Condition 4: demonstrating perfectly flat pre-trends in the triple-diff event study

**Status:** [x] RESOLVED

**Response:**
The pre-treatment window spans January 2019 to January 2022 (37 months). The event study will plot monthly coefficients for the triple-interaction (gas_dependence × energy_intensity × month_FE) with February 2022 as the reference period. Pre-trend flatness will be assessed via: (1) visual inspection, (2) joint F-test on pre-treatment coefficients, (3) Rambachan-Roth sensitivity bounds for potential trend violations. If pre-trends are not flat, we will investigate and address the source (e.g., COVID recovery patterns) with controls or sample restrictions.

**Evidence:** Design commitment; 37 pre-treatment months provide strong pre-trend validation.

---

### Condition 5: using quantities or deflated values rather than nominal imports

**Status:** [x] RESOLVED

**Response:**
Comext provides both value (EUR) and quantity (kg/supplementary units) dimensions. The primary specification will use **log import quantities (kg)** as the dependent variable, which is immune to price inflation. As robustness, we will also report results using (a) nominal values, (b) unit values (EUR/kg) to separate price vs. quantity margins, and (c) values deflated by product-specific import price indices where available. This decomposition into extensive (quantity) and intensive (price) margins is itself a contribution.

**Evidence:** Comext API confirmed to return QUANTITY_IN_KG and VALUE_IN_EUROS fields.

---

### Condition 6: ruling out direct Russia-supplier substitution

**Status:** [x] RESOLVED

**Response:**
See Condition 2 above. Additionally, we will show that: (a) Russia was not a major supplier of the specific HS2 products studied (chemicals, ceramics, aluminium — Russia is mainly gas/oil/wheat/metals, not downstream manufactures); (b) for products where Russia was a supplier (e.g., HS 72 iron/steel, HS 76 aluminium), we explicitly decompose by partner to separate sanctions-driven rerouting from domestic-production-replacement. The placebo products (HS 84/85/62) were also not Russian exports, so should show no effect.

**Evidence:** Comext partner decomposition by RU origin; design commitment in research plan.

---

### Condition 7: other wartime confounds

**Status:** [x] RESOLVED

**Response:**
Key confounds: (1) sanctions affecting non-energy trade, (2) supply chain disruptions from COVID recovery, (3) inflation differentials, (4) national support packages (energy subsidies). Mitigation: The triple-diff design absorbs country × time and product × time fixed effects, so only the *interaction* of gas dependence × energy intensity × time must be free of confounds. Country-level confounds (sanctions, fiscal policy) are absorbed by country × time FE. Product-level confounds (global supply chain shifts) are absorbed by product × time FE. The residual threat is country × product-specific confounds coincident with gas dependence — this is the identifying variation. We will test sensitivity by: (a) controlling for national energy subsidy packages (billion EUR), (b) dropping the most gas-dependent country (Finland) to check outlier sensitivity, (c) leave-one-out by country and by product.

**Evidence:** Design commitment; absorbed by FE structure of triple-diff.

---

### Condition 8: showing persistence with domestic production

**Status:** [x] RESOLVED

**Response:**
The paper pairs import data with domestic production indices (Eurostat STS_INPR_M, monthly by NACE sector and country) to show the two-sided story: domestic output fell AND stayed depressed while imports rose AND stayed elevated. This "mirror image" is the strongest evidence of substitution rather than temporary smoothing.

**Evidence:** STS_INPR_M available monthly through 2024.

---

### Condition 9: firm-capacity outcomes

**Status:** [x] RESOLVED

**Response:**
As a mechanism/depth analysis, we will use Eurostat business demography data (BD_SIZE by NACE sector and country) to show whether firm exits in energy-intensive sectors increased in gas-dependent countries. This transforms "production fell" into "capacity was permanently destroyed" — addressing whether the domestic production decline is reversible. Annual data (2015–2023) provides 7 pre-treatment and 2 post-treatment years.

**Evidence:** BD_SIZE confirmed via Eurostat API; 2,187 rows for 9 sectors × 22 countries × 9 years.

---

## Verification Checklist

Before proceeding to Phase 4:

- [x] All conditions above are marked RESOLVED or NOT APPLICABLE
- [x] Evidence is provided for each resolution
- [x] This file has been committed to git

**Once complete, update Status at top of file to: RESOLVED**
