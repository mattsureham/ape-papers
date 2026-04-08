# Research Plan: apep_1425

## Research Question

Did Brazil's 2017 labor reform (Lei 13.467) compress random-assignment heterogeneity in labor court adjudication? We estimate whether pre-reform court leniency — measured as a court unit's tendency to rule in favor of plaintiffs under verified random case assignment — predicts case outcomes less strongly after the reform shifted litigation costs to losing plaintiffs.

## Identification Strategy

**Court leniency design exploiting verified random case assignment (sorteio).**

DataJud records confirm that first-instance labor cases are assigned to varas by mandated lottery (Article 285 CPC), verified via `movimentos.complementosTabelados.nome = 'sorteio'` in API data. Each vara has one titular judge.

**Pre-reform court leniency measure:** For each vara $j$, compute the leave-one-out pro-worker verdict rate using pre-reform data (cases filed before November 11, 2017). Apply empirical Bayes shrinkage to address noise from small-sample varas. Validate with split-sample (odd vs. even pre-reform years).

**Main specification (case-level):**
$$Y_{ijpt} = \alpha_{\text{pool} \times \text{month}} + \beta L_j + \gamma (\text{Post}_t \times L_j) + X_i + \varepsilon_{ijpt}$$

Where:
- $Y_{ijpt}$: binary pro-worker verdict (Procedência or Procedência em Parte vs. Improcedência)
- $L_j$: pre-reform leave-one-out court leniency (EB-shrunk)
- $\text{Post}_t$: indicator for cases filed on or after November 11, 2017
- $\alpha_{\text{pool} \times \text{month}}$: assignment pool × calendar month fixed effects
- $X_i$: case-level controls (case class, subject codes)
- Pool defined as: forum/comarca × case class (rito ordinário, rito sumaríssimo)

**Key estimand:** $\gamma$ — the change in the predictive power of pre-reform court leniency on plaintiff wins. If $\gamma < 0$, leniency compressed after the reform. The complementary visual evidence is the distribution of court fixed effects pre vs. post.

**No IV second stage.** This is a reduced-form court-environment paper. $L_j$ is a fixed pre-reform trait, not an instrument.

## Expected Effects and Mechanisms

**Primary hypothesis:** $\gamma < 0$. Court leniency predicts plaintiff wins less after the reform because:
1. *Plaintiff selection*: Workers with weak claims stop filing when they bear costs of losing, shrinking the gap between courts' effective caseloads
2. *Judicial response*: Judges in lenient courts tighten standards when the equilibrium filing pool changes
3. *Settlement channel*: Lenient courts see more settlement post-reform as both parties adjust to new cost regime

**Null interpretation:** $\gamma \approx 0$ means court heterogeneity is structural (judicial ideology) rather than responsive to incentive design. This is informative for legal reform debates.

**Key heterogeneity:** Compression should be strongest in:
- High-discretion claim types (ambiguous labor disputes) vs. low-discretion (clear statutory violations)
- Small-value claims (where filing costs are proportionally larger)
- Courts with highest pre-reform leniency (most room to compress)

## Primary Specification Details

### Assignment-Pool Audit
Before any estimation, verify within-pool random assignment:
1. Identify pools: forum/comarca × case class (rito)
2. Within each pool, test covariate balance: subject-matter distribution, filing month, claimant characteristics across varas
3. McCrary density test on leniency measure (no bunching)
4. Frandsen et al. (2023) monotonicity test

### Vara Stability Check
Audit whether titular judge turnover contaminates the leniency measure:
1. Check if DataJud provides any magistrate identifier
2. If not, test stability of vara-level verdict rates over time (autocorrelation)
3. Exclude varas with high year-to-year verdict-rate volatility (suggesting judge turnover)

### Mean-Reversion Guard
1. Compute $L_j$ from odd pre-reform years; validate on even pre-reform years
2. Apply empirical Bayes shrinkage (grand mean + precision-weighted vara mean)
3. Show that split-sample $L_j$ predicts out-of-sample pre-reform outcomes before using it to estimate $\gamma$

### Plaintiff Composition Control
Post-reform filing pool changed (20% drop in filings). Control for:
1. Case subject composition (assuntos field)
2. Case class (rito ordinário vs. sumaríssimo)
3. Filing month trends

## Data Sources

### DataJud API (Primary)
- **Endpoint:** `https://api-publica.datajud.cnj.jus.br/api_publica_trt{N}/_search`
- **Coverage:** 24 TRTs, confirmed ~17M+ records across 5 major TRTs (TRT1: 2.6M, TRT2: 5.0M, TRT3: 4.1M, TRT4: 2.0M, TRT15: 3.6M)
- **Key fields:** `grau` (G1), `orgaoJulgador` (vara code, name, codigoMunicipioIBGE), `movimentos` (distribution/verdict codes), `complementosTabelados` (sorteio confirmation), `assuntos`, `classe`, `dataAjuizamento`
- **Verdict codes:** 219 (Procedência), 220 (Improcedência), 221 (Procedência em Parte)
- **Distribution code:** 26 (Distribuição) with complemento `sorteio`
- **Authentication:** Public API key (confirmed working)
- **No party identifiers** in public API (confirmed — no defendant CNPJ, no plaintiff name)

### CAGED on BigQuery (Secondary — municipality-level employment context only)
- **Dataset:** `basedosdados-dev.br_me_caged.microdados_movimentacao` (196.5M records, 2020-2026)
- **Dataset:** `basedosdados-dev.br_me_caged.microdados_antigos` (372M records, 2007-2019)
- **Purpose:** Descriptive context on municipality employment levels (not causal second stage)

## Fetch Strategy

1. Query all 24 TRT endpoints for G1 cases with `sorteio` distribution
2. Extract: case number, vara code, municipality IBGE code, filing date, all movement codes (distribution + verdicts), case class, subjects
3. Paginate using `search_after` (10K record API limit per query)
4. Store as parquet files by TRT
5. Compute vara-level verdict rates, pool-level assignment balance tests
6. Split pre/post November 11, 2017

## Key Literature

- Kling (2006, AER): Original judge leniency IV design
- Dobbie & Song (2015, AER): Bankruptcy judge leniency
- Dobbie, Goldin & Yang (2018, AER): Pretrial detention judge leniency
- Corbi, Narita, Ferreira & Souza (2022, SSRN): São Paulo labor court judge assignment — closest precursor (single courthouse, proprietary data)
- Cahuc, Carcillo, Patault & Moreau (2024, JEEA): French labor court judge bias and firm performance
- Araujo et al. (2023, JFE): Brazilian bankruptcy court random assignment and labor effects
- Frandsen, Lefgren & Leslie (2023, AER): Validity tests for judge IV designs

## What's New

1. **Scale:** National DataJud API (30M+ cases, 24 TRTs, 1,500+ varas) vs. Corbi et al.'s single courthouse
2. **Question:** Whether reform compressed heterogeneity (institutional response to incentive design) vs. Corbi et al.'s firm-level effects of judge leniency
3. **Infrastructure:** First economics paper using the DataJud public API for causal inference
