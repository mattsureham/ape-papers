# Research Plan: The Relabeling Illusion — Procurement Set-Asides and Small Firm Market Access in the Dominican Republic

## Research Question

Do government procurement set-aside mandates for small firms actually expand market access to new entrants, or do they merely relabel incumbent suppliers? We study the Dominican Republic's 20% MIPYME (micro, small, and medium enterprise) procurement reservation (Decree 543-12), exploiting the sharp enforcement surge following the August 2020 presidential transition from Danilo Medina (PLD) to Luis Abinader (PRM).

## Identification Strategy

**Generalized DiD with continuous treatment intensity.** The mandate existed from 2012 but was unenforced (1-4% compliance) until the Abinader administration's anti-corruption push drove compliance from 3% to 17%. Cross-agency variation in compliance shifts (+0pp to +71pp) provides a rich dose-response gradient.

- **Unit:** Agency-quarter panel, 2016Q1-2025Q4
- **Treatment:** Change in MIPYME-directed share from pre-period (2016-2020H1) to post-period (2020H2-2025)
- **Identifying assumption:** The post-transition compliance surge reflects top-down political pressure, not endogenous agency response to supplier market conditions
- **Key threats:** (1) Selection — agencies that shifted most may differ. Control with agency FE + pre-period characteristics. (2) Composition — mechanical increase in supplier count from MIPYME channeling. Test genuine new entrants vs. relabeled incumbents using firm creation dates.

## Expected Effects and Mechanisms

- **First stage:** Agencies with larger MIPYME share increases should see more procurement processes directed to small firms (mechanical)
- **Main outcome:** Unique supplier count per agency-quarter. If genuine expansion, more unique suppliers; if relabeling, similar suppliers relabeled as MIPYME
- **Mechanism test:** Decompose new suppliers into (a) firms created after the mandate enforcement (genuine new entrants), (b) firms that existed before but never won contracts (newly participating), (c) firms that already won contracts but got newly certified as MIPYME (relabeled)
- **Concentration:** HHI of contract values per agency-quarter — genuine expansion should reduce concentration
- **First-time winners:** Share of contracts going to suppliers with no prior government contracting history

## Primary Specification

$$Y_{a,t} = \alpha_a + \gamma_t + \beta \cdot \Delta \text{MIPYME}_a \times \text{Post}_t + X_{a,t}'\delta + \varepsilon_{a,t}$$

Where $\Delta \text{MIPYME}_a$ is the change in MIPYME-directed share for agency $a$ between pre/post periods, $\text{Post}_t = \mathbf{1}[t \geq \text{2020Q3}]$, and $X_{a,t}$ includes log total procurement volume.

Clustering: agency level (256 clusters after filtering to agencies with ≥4 quarters in both pre and post periods).

## Exposure Alignment

Treatment is the change in MIPYME-directed procurement share at the agency level. This affects: (1) the pool of eligible firms for MIPYME-directed processes, (2) the procurement modality choices available to agencies, and (3) the certification incentives for existing suppliers. The treated population is government contracting agencies and their supplier networks. The outcome (unique suppliers per agency-quarter) is measured at the same agency level where treatment varies, ensuring alignment between exposure and outcome measurement. One concern is that ΔMIPYME is a realized choice rather than an externally assigned treatment; the identifying assumption is that the post-2020 variation reflects top-down political enforcement pressure from the new administration rather than agency-specific responses to supplier market conditions. Pre-trends, placebo tests, and trend controls support this assumption.

## Data Source and Fetch Strategy

Three CSV files from DGCP (Dirección General de Contrataciones Públicas):

1. **Adjudicaciones (Awards):** `https://www.dgcp.gob.do/new_dgcp/documentos/da/actualizados/adjudicaciones-secp.csv` — 655K rows, contract awards with supplier ID, value, date
2. **Procesos (Processes):** `https://www.dgcp.gob.do/new_dgcp/documentos/da/actualizados/datos-procesos-publicados.csv` — 576K rows, procurement processes with MIPYME flag, agency code
3. **Proveedores (Providers):** `https://www.dgcp.gob.do/new_dgcp/documentos/da/actualizados/proveedores-del-estado.csv` — 132K rows, supplier registry with MIPYME status, firm creation date

All confirmed accessible via curl in the smoke test.
