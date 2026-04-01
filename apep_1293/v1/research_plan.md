# Research Plan: apep_1293

## Research Question

Does firearm liberalization increase homicide, and does subsequent restriction reverse it? Specifically: is the relationship between gun access and violence symmetric, or does liberalization create irreversible changes in the weapons stock, criminal networks, or social norms that persist after policy reversal?

## Institutional Background

Brazil experienced one of the most dramatic gun policy reversals in modern history:

**Liberalization (2019-2022, Bolsonaro):** Beginning January 2019, President Bolsonaro issued 30+ executive decrees that:
- Raised household firearms from 2 to 4, then to 6 per civilian
- Authorized 9mm pistols and expanded ammunition allowances (50 → 200 rounds/year)
- Created the CAC (Caçadores, Atiradores e Colecionadores) category enabling semi-automatic weapons
- Relaxed shooting club licensing, causing proliferation from ~151 registered clubs (2018) to ~2,095 (2022)
- Tripled registered gun ownership from ~700K to ~2.2M

**Re-restriction (2023, Lula):** Upon taking office, President Lula signed comprehensive reversal decrees:
- January 2023: Initial executive orders restricting new acquisitions
- July 2023: Comprehensive decree reducing firearms from 6 → 2 per civilian, banning 9mm for civilians, cutting ammunition to 50 rounds/year, imposing 1km school buffer zones, transferring CAC oversight to Federal Police
- Effect: New registrations dropped 82% within 6 months

## Identification Strategy

### Primary Design: Shift-Share DiD + DDD

**Shift (exogenous):** National policy changes — Bolsonaro decrees (Jan 2019) and Lula reversal (Jan/Jul 2023). These are plausibly exogenous to municipality-level violence trends.

**Share (predetermined):** Pre-2019 municipality-level shooting club density (clubs per 100K population, from CNPJ data). Clubs that existed before 2019 reflect historical gun culture/sport, not the Bolsonaro policy. The national policy channeled firearms into communities through clubs — municipalities with more clubs had greater exposure to the liberalization.

**Triple difference:** Firearm homicide (ICD-10 X93-X95) vs non-firearm homicide (ICD-10 X85-X92, X96-Y09). The DDD controls for municipality-specific time trends common to all violence types.

### Symmetric Prediction (Built-in Falsification)

The design generates a testable asymmetry prediction:
- **Liberalization period (2019-2022):** High-club-density municipalities should show LARGER increases in firearm homicide relative to low-club-density municipalities
- **Restriction period (2023-2024):** The sign should FLIP — high-club-density municipalities should show larger DECREASES
- If the relationship is perfectly symmetric, the restriction coefficient should equal (in absolute value) the liberalization coefficient
- Asymmetry (|β_restriction| < |β_liberalization|) would indicate hysteresis — guns once distributed are hard to recall

### Primary Specification

$$Y_{mt} = \alpha_m + \gamma_t + \beta_1(\text{Post2019}_t \times \text{ClubDensity}_m) + \beta_2(\text{Post2023}_t \times \text{ClubDensity}_m) + X'_{mt}\delta + \varepsilon_{mt}$$

Where:
- $Y_{mt}$ = firearm homicide rate per 100K in municipality $m$, year $t$
- $\alpha_m$ = municipality fixed effects
- $\gamma_t$ = year fixed effects
- $\text{ClubDensity}_m$ = shooting clubs per 100K pop in 2018 (pre-treatment)
- $\text{Post2019}_t$ = 1 for years 2019-2024
- $\text{Post2023}_t$ = 1 for years 2023-2024 (restriction net of liberalization)
- $X_{mt}$ = time-varying controls (GDP per capita, urbanization rate)

**Key coefficients:**
- $\beta_1$ = liberalization effect on high-exposure municipalities
- $\beta_1 + \beta_2$ = net effect in the restriction period
- $\beta_2$ = incremental restriction effect (should be negative if reversal works)

### DDD Extension

$$Y_{mct} = \alpha_{mc} + \gamma_{ct} + \delta_{mt} + \beta_1^{DDD}(\text{Post2019}_t \times \text{ClubDensity}_m \times \text{Firearm}_c) + \beta_2^{DDD}(\text{Post2023}_t \times \text{ClubDensity}_m \times \text{Firearm}_c) + \varepsilon_{mct}$$

Where $c \in \{\text{firearm}, \text{non-firearm}\}$ is homicide category. This absorbs municipality×time trends that affect all homicide types equally.

### Design Integrity Checklist
- **Treatment timing:** Bolsonaro decrees begin Jan 2019; Lula reversal Jan/Jul 2023
- **In-sample treated count:** Need 20+ municipalities with high club density (to verify in smoke test)
- **Unit of observation:** Municipality × year (or municipality × cause × year for DDD)
- **Denominator:** IBGE SIDRA population estimates, municipality level
- **Clustering:** State level (27 states) — policies are national but club density varies within states
- **Pre-periods:** 2013-2018 (6 years, satisfying ≥5 requirement)

### Kill-Shot Question
**Strongest skeptic attack:** "Shooting club density proxies for gun culture, not policy exposure. Places with more clubs were already on different violence trajectories before 2019."

**Response:** (1) Pre-trends test — event study showing parallel trends 2013-2018. (2) DDD — non-firearm homicide should not show the same pattern. (3) Symmetric prediction — if clubs proxy for culture rather than policy exposure, there is no reason for the sign to flip in 2023. (4) Club density exploded 151→2,095 during 2019-2022, meaning most "treatment intensity" is policy-driven entry, not legacy culture.

## Data Sources

1. **DATASUS SIM** (Mortality Information System): Municipality-level mortality by ICD-10 cause, age, sex, race. FTP download (.dbc format). Years: 2013-2024 (or latest available).

2. **IBGE SIDRA API**: Municipality-level population estimates (denominators for rates).

3. **Receita Federal CNPJ** (dados.gov.br): Business registry with CNAE codes. Shooting clubs/ranges identified by CNAE 9312-3/00 or similar. Municipality (IBGE code) and opening date available.

4. **Controls (if needed):** IBGE municipal GDP, urbanization rate from Census.

## Expected Effects

- **Liberalization ($\beta_1 > 0$):** Firearm homicide increases more in high-club-density municipalities
- **Restriction ($\beta_2 < 0$):** Partial reversal — some reduction but likely smaller in magnitude than the increase (hysteresis)
- **DDD:** Non-firearm homicide should NOT respond to club density × policy interactions
- **Null result interpretation:** If $\beta_1 \approx 0$, gun access does not causally affect homicide through the club channel. This would be an important null — contradicting the premise that more guns = more violence.

## Feasibility Assessment

- 5,570 municipalities × 12 years = 66,840 municipality-years
- Smoke-tested: DATASUS FTP accessible, IBGE SIDRA API working, CNPJ data accessible
- R packages: `read.dbc`, `data.table`, `fixest`, `did` (if using CS estimator)
- Hardware: Standard — no special RAM/CPU requirements for this panel size
