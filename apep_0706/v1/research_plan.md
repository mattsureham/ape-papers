# Research Plan: Does Money Buy Safety? FPM Fiscal Windfalls and Homicide Rates in Brazilian Municipalities

## Research Question

Do unconditional fiscal transfers to subnational governments reduce violent crime? We exploit Brazil's Fundo de Participação dos Municípios (FPM), which distributes federal tax revenue to municipalities based on 17 sharp population thresholds (Decreto-Lei 1.881/81), creating ~20% per-capita transfer jumps. We estimate the causal effect of these fiscal windfalls on municipal homicide rates using a multi-cutoff RDD on 27 years of cause-of-death microdata.

## Identification Strategy

**Design:** Multi-cutoff sharp RDD following Cattaneo et al. (2016) normalizing-and-pooling approach.

**Running variable:** IBGE official population estimate minus the nearest FPM threshold (10,189; 13,585; 16,981; 23,773; 30,564; 37,356; 44,148; 50,940; 61,128; 71,316; 81,504; 91,692; 101,880; 115,464; 129,048; 142,632; 156,216).

**Treatment:** Discrete jump in FPM per-capita transfers (~20% increase at each threshold). This is a sharp design — the FPM coefficient is a deterministic function of IBGE population.

**Key assumptions:**
1. Municipalities cannot precisely manipulate IBGE population estimates near thresholds — IBGE uses census projections, not self-reported counts. McCrary test verifies this.
2. No other policy discontinuity at the same thresholds (we exclude cutoffs coinciding with council-size thresholds per Corbi et al. 2019).
3. Continuity of potential outcomes at the threshold.

**Compound treatment concern:** Some FPM thresholds coincide with council-size thresholds (which also shift through population). We address this by: (a) testing council size as a separate outcome at FPM thresholds; (b) estimating separately at thresholds that do NOT coincide with council-size changes.

## Expected Effects and Mechanisms

**Ambiguous prediction:**
- *Employment channel* (reduces crime): Corbi et al. (2019) find FPM fiscal multipliers of 1.4-1.8x. Higher local employment → higher opportunity cost of crime → fewer homicides.
- *Corruption channel* (increases crime): Brollo et al. (2013) find 12pp increase in corruption at FPM thresholds. Resource competition and rent-seeking may fuel violence.
- Net effect is an empirical question.

**Mechanism tests:**
1. Public employment (RAIS data) — does local government hiring increase?
2. Youth employment — are young men (15-29, peak homicide age) specifically affected?
3. Nighttime lights (VIIRS) — does economic activity broadly increase?

## Primary Specification

$$\text{HomicideRate}_{it} = \alpha + \tau \cdot \mathbf{1}[\text{Pop}_i > c_k] + f(\text{Pop}_i - c_k) + \varepsilon_{it}$$

where $c_k$ is the nearest threshold, $f(\cdot)$ is a local linear polynomial estimated separately on each side, and the bandwidth is MSE-optimal (rdrobust). We normalize all cutoffs and pool following Cattaneo et al. (2016).

**Clustering:** Standard errors clustered at the municipality level.

**Outcome:** Homicide rate per 100,000 population (ICD-10 codes X85-Y09), averaged over the panel to maximize precision.

## Robustness

1. Individual cutoff-by-cutoff estimates (not just pooled)
2. Donut-hole RDD (exclude municipalities within 500 of threshold)
3. McCrary density test at each threshold
4. Placebo cutoffs (midpoints between real thresholds)
5. Covariate balance (geographic, demographic characteristics)
6. Bandwidth sensitivity (50%, 75%, 100%, 125%, 150% of optimal)
7. Placebo outcomes: non-violent deaths (natural causes), traffic accidents

## Data Source and Fetch Strategy

1. **Mortality microdata:** DATASUS SIM (Sistema de Informação sobre Mortalidade), 1996-2022. FTP: `ftp://ftp.datasus.gov.br/dissemin/publicos/SIM/CID10/DORES/`. State-year DBC files. Process with `microdatasus` R package. ICD-10 homicide codes: X85-Y09.

2. **Population estimates:** IBGE API for municipality population estimates (determines FPM bracket assignment). Also used for rate denominators.

3. **FPM transfer data:** Brazilian National Treasury (Tesouro Nacional) — STN transfer portal. Municipality-level annual FPM receipts to verify first stage.

4. **Covariates:** IBGE Census 2000/2010 for municipality characteristics (urbanization, education, income).

**Fetch order:**
1. IBGE population estimates → assign FPM brackets → construct running variable
2. DATASUS SIM mortality → construct homicide rates
3. Verify FPM first stage with Treasury data
4. Census covariates for balance tests
