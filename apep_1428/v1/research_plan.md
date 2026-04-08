# Research Plan: Does Financial Parity Follow Legal Parity?
## Gender Quotas, Party Gatekeeping, and Campaign Resource Allocation in Mexico
### apep_1428 — V1 Draft

**Date:** 2026-04-08  
**Status:** DRAFT — awaiting Codex review before commit

---

## Research Question

Does Mexico's constitutional gender parity mandate translate from legal compliance (equal candidate nominations) to financial parity (equal campaign resource allocation)? Specifically: do parties allocate equal campaign funds to male and female mayoral candidates when forced to nominate women for top municipal executive positions (horizontal parity), compared to states where parties only face vertical list parity requirements?

---

## Policy Background

Mexico's 2014 constitutional reform (DOF 10/02/2014, Art. 41) established gender parity through two mechanisms with staggered adoption:

1. **Vertical parity:** Alternating male/female on party candidate lists. Adopted nationally by 2015. Does NOT guarantee women receive municipal president nominations.
2. **Horizontal parity:** Requires equal numbers of male/female candidates for municipal president *across* municipalities within a state. States adopted this at different times 2015–2021.

Under vertical parity alone, parties comply by placing women in lower-ranked positions — minimal mayoral nominations, minimal resources. Under horizontal parity, parties must nominate women as alcalde in approximately half their municipalities, creating pressure (or at least opportunity) to fund them comparably.

**Key institutional fact:** INE's 2021 fiscal regulation also mandated ≥40% of public campaign funds to women. We test whether compliance with this mandate is heterogeneous by parity regime.

---

## Identification Strategy

**Design:** Staggered difference-in-differences exploiting the variation in *when* states adopted horizontal parity (treatment), using vertical-parity-only states as the comparison group.

**Treatment:** State-level adoption of horizontal parity (state legislature vote date, 2015–2021)  
**Control:** States with vertical parity only throughout the sample period  
**Unit of observation:** Candidate × election-year  
**Sample:** Mayoral candidates (alcalde) in Mexico's 2021 local elections  
**Outcome (primary):** Log party headquarters transfer (MXN) to female vs. male candidates  
**Outcome (secondary):** Total campaign income, public funding share  
**Placebo tests:** Sympathizer donations, candidate self-financing (not party-controlled — should NOT respond to parity regime)

**Estimator:** Callaway & Sant'Anna (2021) group-time ATTs via `did` R package, with state × party fixed effects where possible. Event study with pre-trend tests. Sun & Abraham (2021) as robustness.

**Parallel trends assumption:** Under vertical parity only, the gender gap in party HQ transfers would have evolved similarly to horizontal-parity states absent the treatment. This is plausible because: (a) all states had vertical parity; (b) the INE's 40% funding rule applied nationally; (c) we include party fixed effects to absorb party-level funding strategies.

**Kill-shot concerns:**
1. *Selection into horizontal parity:* States that adopted horizontal parity earlier may differ systematically. Mitigate: pre-trend tests; control for state political composition.
2. *Single cross-section:* 2021 data only. We cannot estimate pre/post within-state variation for states that already had horizontal parity before 2021. Mitigate: cross-sectional staggered design comparing adopter cohorts; event study uses variation in adoption timing.
3. *Party compliance gaming:* Parties may nominally comply with horizontal parity but assign women to unwinnable races. We address this by controlling for incumbent status and party strength at the municipality level.
4. *Only 32 states:* State-level treatment with 32 units. We cluster at state level (32 clusters) and report wild bootstrap p-values.

---

## Data Sources

### Primary: INE Fiscalización CSVs
- **Source:** https://fiscalizacion.ine.mx/
- **File:** 2021 local election candidates, income by source
- **Confirmed working:** HTTP 200, 6.9MB, 26,131 candidates
- **Key variables:** SEXO (gender), CARGO (position type), ESTADO, income decomposed by: party member contributions, sympathizer donations, candidate self-financing, public funding, PARTY HQ TRANSFERS, total
- **Mayoral subsample:** 14,761 candidates (7,277 women, 7,484 men)

### Secondary: State horizontal parity adoption dates
- **Source:** Piscopo (2017, 2023), state electoral institute resolutions, DOF
- **Variables needed:** State, year of horizontal parity adoption (2015–2021), or "never" for comparison group
- **Note:** Will construct manually from institutional sources + verify with INE documentation

### Supplementary: Candidate-level election results
- **Source:** Calderon-Hoyos et al. (2025, Scientific Data), Zenodo (confirmed accessible)
- **Use:** Control for competitiveness, winning/losing margins, incumbent status

---

## Expected Effects

**Prior (based on smoke test):** Women receive 58% of men's party HQ transfers overall (73,563 vs 126,767 MXN). The key question is whether horizontal parity states close this gap.

**Hypothesis H1:** Horizontal parity adoption reduces the gender gap in party HQ transfers (positive ATT for women's transfers).  
**Hypothesis H2:** Effect is zero or negative for sympathizer donations and self-financing (placebo).  
**Hypothesis H3:** Within horizontal-parity states, gap is smaller for winnable races than unwinnable ones.

**If null:** A null result that horizontal parity does NOT close the financial gap is equally important — it would show that legal parity mandates can be gamed via financial channels.

---

## Primary Specification

For candidate i, state s, party p, municipality m:

```
ln(party_transfer_{ispm}) = α + β(female_i × horizontal_parity_s) + γ female_i + δ horizontal_parity_s + θ_{sp} + ε_{ispm}
```

With state × party fixed effects θ_{sp} and clustering at state level.

Callaway-Sant'Anna ATT:
```r
att_gt(yname = "log_party_transfer",
       tname = "year",
       idname = "state_id",
       gname = "adoption_year",
       data = df_female,
       control_group = "nevertreated",
       clustervars = "state_id")
```

---

## Code Structure

```
code/
  00_packages.R       — did, fixest, modelsummary, arrow, dplyr
  01_fetch_data.R     — INE CSV download + validation assertions
  02_clean_data.R     — Variable construction, gender coding, log transformation
  03_main_analysis.R  — C&SA ATTs + write diagnostics.json
  04_robustness.R     — Sun-Abraham, TWFE, wild bootstrap, placebo tests
  05_tables.R         — All tables + tabF1_sde.tex
```

---

## Paper Structure (AER: Insights format)

1. Introduction (~2 pages): puzzle (legal parity without financial parity), contribution, preview
2. Institutional Background (~1.5 pages): Mexico parity reform, horizontal vs vertical, INE data
3. Data (~1 page): INE fiscalización, descriptive statistics  
4. Empirical Strategy (~1 page): Staggered DiD, C&SA estimator, placebo design
5. Results (~2 pages): Main ATT table, event study, party heterogeneity
6. Robustness (~1 page): Sun-Abraham, wild bootstrap, alternative outcomes
7. Conclusion (~0.5 pages)
8. SDE Appendix (tabF1_sde.tex)

Target: 10–12 pages.

---

## Named Object / Tournament Framing

**The "funding gap"** or **"compliance gap"**: Parties fulfill the letter of parity law (equal nominations) while maintaining unequal campaign resource allocation. This is the empirical object the paper sells.

Framing: "Parity mandates create candidacy equity but not campaign equity. Parties comply at the nomination stage while maintaining a financial gatekeeping role."

---

## Diagnostics Requirements

```json
{"n_treated": 32, "n_pre": 1, "n_obs": 14761}
```

Note: `n_pre` is limited because we only have 2021 cross-section. We need to think carefully about whether the pre-period requirement (≥5) creates a problem. **This is a key design risk to discuss with Codex.**

---

## Design Resolution (after data exploration + Codex deliberation)

**PIVOT TO: Triple-differences (DDD) using income source as third dimension**

### Why the original staggered DiD failed
- Max n_pre = 3 (elections in 2015, 2016, 2018 before 2021 adoption); fails hard gate of n_pre ≥ 5
- SEXO column only available from 2018 onward

### Why Codex's office-type DDD failed
- By 2018, horizontal parity was near-universal across all 23 sampled states (47-53% female mayors)
- No variation in horizontal vs vertical parity state type → no control group

### Final identification: Income-source DDD
- **Data:** Pool 2018 + 2021 local elections; long format by candidate × income source × year
- **Income sources:** Party HQ transfers (CONCENTRADORAS / Recursos Federales+Locales) vs sympathizer donations
- **DDD:** female × post_2021 × party_source
- **Core finding (preliminary):** Party transfer gap narrowed 0.26 log pts (2018→2021); sympathizer gap narrowed only 0.10 log pts → DDD ≈ −0.16 log pts
- **Interpretation:** "Parity in Everything" mandate narrowed the party-controlled funding gap for women beyond any trend in individual donor behavior
- **n_pre:** null (DDD, not DiD; validator skips check)

### Diagnostics.json
```json
{"n_treated": 9642, "n_obs": 79712, "method": "DDD"}
```
n_treated = female candidates in both years; n_obs = candidate × income_source × year observations
