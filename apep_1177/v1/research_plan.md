# Research Plan: apep_1177 (V1)
## Updated 2026-03-31 after Codex review + data audit

## Research Question

Does random assignment of drug trafficking cases to judicial varas of varying severity create a **conviction lottery** in Brazil, where identical defendants face 5–15 years prison or acquittal based on which vara they draw?

**Framing note (post-audit):** We originally targeted "classification lottery" (Art. 33→28 reclassification), but DataJud does not record crime reclassification in a usable way (Mudança de classe tracks procedural class changes, not crime type; Desclassificação movement appears in only 19 of 87,757 cases). The observable treatment is binary conviction (Procedência = 1), which still captures the core phenomenon: massive arbitrariness in drug trafficking outcomes driven by random vara assignment.

## Background

Brazil's Lei 11.343 (2006) eliminated prison for drug possession/use while raising the minimum trafficking sentence to 5 years. Critically, **no objective criteria** (quantity thresholds, weight cutoffs) distinguish "user" from "trafficker." Judges evaluate "the nature and quantity of the substance seized, the location and conditions of the arrest, and the social and personal circumstances of the agent." This produces enormous within-court variation: Assunção & Trecenti (SBE 2023) document a 30-percentage-point gap between the 10th and 90th percentile courtrooms.

Brazil has 920,000 incarcerated people (3rd globally), with 28% convicted of drug offenses. The Supreme Federal Tribunal (STF) is actively deliberating whether to adopt quantity thresholds (RE 635659). No causal evidence exists on what the classification lottery does to defendants.

## Identification Strategy

### Design Family
**Leniency / judge IV** (Kling 2006; Dobbie, Goldin & Yang AER 2018).

### Assignment Story
Cases in São Paulo state (TJSP) are assigned to criminal varas via **sorteio eletrônico** (electronic lottery), explicitly recorded in the DataJud system as a "Distribuição" movement with "sorteio" complement. We restrict to **comarcas with 2+ criminal varas** — the assignment pool where within-comarca randomization is cleanest. Single-vara comarcas add no identifying variation.

### Instrument
**Leave-one-out (LOO) vara leniency**: for case $i$ assigned to vara $j$ in assignment pool $p$ (comarca or foro), the instrument is the average trafficking conviction rate of vara $j$ computed from **all other cases across the full sample** in that pool, excluding case $i$.

$$Z_{ijp} = \frac{1}{N_{jp} - 1} \sum_{k \neq i, k \in j,p} \mathbb{1}[\text{Convicted}_k]$$

**Per Codex review:** Leniency is computed from the full sample (not same-year), making it a more stable measure. Assignment-pool × year FE absorb contemporaneous shocks. UJIVE / split-sample jackknife is mandatory to address many-instrument bias.

### Bias Story (Why OLS Is Biased)
Naive OLS of incarceration on defendant outcomes confounds judge severity with defendant characteristics. More severe cases (larger drug quantities, prior records, arrest circumstances) simultaneously increase conviction probability and worsen outcomes. The vara assignment is orthogonal to these confounders.

### Exclusion Story and Bundle Problem (Per Codex Review)
**Critical design limitation:** A harsher vara is a *bundle* — detention practices, plea pressure, case management, evidentiary standards, AND conviction rates all co-vary. The exclusion restriction "vara affects Y only through conviction" is NOT credible for court-process outcomes like case duration or pretrial detention.

**Therefore, the V1 paper is framed as reduced-form evidence on arbitrariness, NOT as a 2SLS paper estimating causal effects of conviction on downstream outcomes.**

The core contribution is:
1. **First stage + reduced form:** vara assignment (random) dramatically affects conviction probability
2. **Magnitude of arbitrariness:** 10th-90th percentile spread in vara conviction rates
3. **Balance:** case characteristics are balanced across vara leniency quartiles (proving randomization)
4. **Policy implication:** absence of objective criteria creates systematic arbitrariness

2SLS for downstream outcomes (case duration, recidivism, employment) is a V2 question requiring RAIS data and a more careful exclusion argument.

### Estimand
**Reduced-form:** the effect of vara leniency assignment on conviction probability and other observable outcomes. Under average monotonicity (stricter varas weakly increase conviction for all defendants), this has a clean LATE interpretation for the conviction margin. For court-process outcomes, we report reduced-form effects of assignment without forcing a 2SLS interpretation.

### Expected Effects
- **Primary (conviction rate):** Expect large cross-vara variation (30pp at the 10-90 spread based on Assunção & Trecenti 2023). The arbitrariness itself is the finding.
- **Secondary (pretrial detention):** Harsher varas likely detain more. We report as reduced-form effect of assignment, NOT as effect of conviction.
- **Secondary (case duration):** Expect longer duration in harsher varas (more contested cases, longer proceedings).

## Primary Specification

### Main Equation (Reduced Form)
$$Y_{ijpt} = \alpha_0 + \alpha_1 Z_{ijp} + \mathbf{X}'_{ijpt}\gamma + \delta_{pt} + \epsilon_{ijpt}$$

Where:
- $i$ = case, $j$ = vara, $p$ = assignment pool (comarca/foro), $t$ = filing year
- $Z_{ijp}$ = LOO vara leniency (full-sample, within pool)
- $\delta_{pt}$ = assignment-pool × year FE
- $\mathbf{X}_{ijpt}$ = case-level controls (number of assuntos, filing month)
- $Y$ = binary conviction (Procedência), pretrial detention, case duration

### First Stage (For Conviction Margin)
$$\text{Convicted}_{ijpt} = \gamma_0 + \gamma_1 Z_{ijp} + \mathbf{X}'_{ijpt}\pi + \mu_{pt} + \nu_{ijpt}$$

Report first-stage F, UJIVE estimate, and first-stage visualization (conviction rate by vara leniency quintile).

### Inference
Cluster at vara level (unit of treatment assignment). Report: (1) clustered SEs, (2) UJIVE as benchmark for many-instrument bias, (3) Anderson-Rubin weak-IV-robust CIs if first-stage F < 50.

## Data Source + Fetch Strategy

### Primary Data
**CNJ DataJud Public API** (api-publica.datajud.cnj.jus.br)
- Index: `api_publica_tjsp`
- Free API key (already verified working)
- Elasticsearch query interface
- **Verified fields:** `numeroProcesso`, `orgaoJulgador` (vara ID + name), `assuntos` (crime classification), `movimentos` (timestamped procedural movements including sorteio, conviction, class changes, final disposition), `dataAjuizamento` (filing date), `classe` (case type), `grau` (court level)

### Sample Definition
1. Filter: `assuntos.codigo = 3608` (Tráfico de Drogas e Condutas Afins), `grau = G1` (first instance), `classe.codigo = 283` (Ação Penal - Procedimento Ordinário)
2. Verified count: **87,757 cases** in TJSP
3. Further restrict to comarcas with 2+ criminal varas handling drug cases (identifying variation requires within-comarca randomization)
4. Verify sorteio distribution flag in movimentos for each case

### Outcome Construction (from movimentos)
| Movement Code | Name | Meaning |
|--------------|------|---------|
| 219 | Procedência | Prosecution succeeded (convicted) |
| 220 | Improcedência | Prosecution failed (acquitted) |
| 10966 | Mudança de classe | Class change (may include Art. 33→28 reclassification) |
| 848 | Trânsito em julgado | Judgment final |
| 246 | Definitivo | Case resolved |
| 11878 | Prescrição | Statute of limitations |
| 26 | Distribuição | Case assigned (with sorteio complement) |

Primary outcome: **binary conviction** (Procedência = 1).
Secondary outcomes: case duration (filing date to Definitivo/Trânsito), binary pretrial detention (presence of cod 12140).

### Fetch Plan
1. Python script to paginate through DataJud API (Elasticsearch scroll API)
2. Extract: case ID, vara, comarca, filing date, assuntos, all movements with timestamps
3. Save as Parquet for R analysis
4. Rate limit: API accepts ~1 request/2 seconds; expect ~4-8 hours for full extraction
5. **Fallback:** If API pagination is slow, subset to 2018-2022 filing years first (estimated ~40K cases)

## Design Integrity Checklist
- [ ] Treatment timing: classification at sentencing (not at filing)
- [ ] In-sample treated count: ≥20 (expect thousands of varas × years)
- [ ] Unit of observation: case level
- [ ] Clustering level: vara
- [ ] Monotonicity check: plot conviction rates by vara leniency quintile
- [ ] Balance: pre-determined case characteristics by vara leniency
- [ ] First stage F: expect >>100 given 60K convictions across 30+ varas

## Kill-Shot Question
**Can we observe the judicial outcome (conviction/acquittal/reclassification) cleanly enough from movement codes to construct the treatment variable?** If Procedência (cod=219) is systematically absent from cases that were actually convicted (e.g., because outcomes are recorded differently in some varas), the design fails. We verify this by checking that Procedência + Definitivo covers >90% of cases with sufficient timeline.

## Co-Author Notes
- Codex proposed: restrict to multi-vara comarcas, TJSP only, RAIS = V2 extension ✅
- Mudança de classe audit: tracks procedural class changes, NOT crime reclassification. Desclassificação appears in only 19/87,757 cases. **Downshift confirmed: "conviction lottery" framing.** ✅
- Codex pushback on exclusion: vara is a bundle (detention + conviction + case management). Do NOT treat case duration as clean 2SLS outcome. Frame as reduced-form arbitrariness evidence. ✅
- Instrument: compute leniency from full sample (not same-year), use pool × year FE. UJIVE mandatory. ✅
- Strongest skeptic attacks: (1) bundle problem — vara moves more than just conviction; (2) documentation differences across varas masquerading as leniency
- Fetch strategy: two-pass approach recommended — thin first (no movimentos) to map sample structure, then full fetch for retained cases only
