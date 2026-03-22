# Research Plan: Delivering Discontent — Maternity Ward Closures and Populist Voting in France

## Research Question

Does the closure of a local maternity ward increase support for the Rassemblement National (RN) in subsequent elections? If so, through what mechanism — perceived state abandonment, actual health access deterioration, or broader service-decline salience?

## Identification Strategy

**Staggered event-study DiD** using commune-level election returns.

- **Treatment:** Commune's nearest maternity ward closes (or commune previously hosting a maternity ward loses it)
- **Treatment measure:** Distance-to-nearest-maternity increase after closure (continuous intensity)
- **Estimator:** Callaway-Sant'Anna (2021) with cohort-specific treatment timing
- **Unit:** Commune × election round
- **Pre-trends:** 2-3 election cycles before closure (validated via event-study plot)
- **Clustering:** Département level (79 départements with closures)

## Expected Effects and Mechanisms

1. **State abandonment channel:** Closure signals the state retreating from rural/periurban areas → increased RN vote share (strongest in small communes, rural areas)
2. **Health access channel:** Increased travel time to nearest maternity → worse birth outcomes → dissatisfaction
3. **Salience channel:** Media coverage of closures activates latent grievances even in communes where practical impact is small

Expected sign: **positive** (closures increase RN vote share). Effect likely 1-3 pp per closure event.

## Primary Specification

Y_{c,t} = α_c + γ_t + β × Post(Closure)_{c,t} + X'_{c,t}δ + ε_{c,t}

Where:
- Y = RN first-round presidential vote share (%)
- Treatment = nearest maternity closure (staggered by year)
- FE: commune, election year
- Controls: log(population), unemployment rate, immigrant share, median income
- SE clustered at département level

## Data Sources and Fetch Strategy

### 1. Maternity Facility Data (DREES-SAE)
- **Source:** DREES Statistique Annuelle des Établissements (SAE)
- **API:** data.drees.solidarites-sante.gouv.fr (tested, returns 2013-2024)
- **Variables:** Facility name, commune code, total deliveries (acctot), open/closed status
- **Coverage:** Annual, 2000-2024 (Excel for pre-2013, API for 2013+)
- **Key:** Track each maternity ward's last active year to construct closure events

### 2. Election Results
- **Source:** data.gouv.fr elections dataset (Parquet, 150.8 MB)
- **Coverage:** Presidential 1st round: 2002, 2007, 2012, 2017, 2022 at commune level
- **Variables:** Candidate votes, registered voters, abstentions by commune
- **RN candidates:** Le Pen (2002, 2007, 2012, 2017, 2022)

### 3. Commune Controls (INSEE)
- **Source:** INSEE RP (Recensement de la Population) and Filosofi
- **Variables:** Population, unemployment, immigrant share, median income
- **Coverage:** Commune-level, decennial census + annual estimates

### 4. Commune Coordinates
- **Source:** INSEE/IGN commune centroids (COG)
- **Purpose:** Calculate distance from each commune to nearest maternity ward

## Analysis Plan

1. **Data construction:** Build commune × maternity distance panel (2000-2024)
2. **Event coding:** Identify closure year for each maternity ward; assign communes to closure cohort based on when nearest maternity closed
3. **Main DiD:** CS-DiD on 5 presidential elections (2002-2022)
4. **Event study:** Dynamic treatment effects ±2 election cycles
5. **Mechanism tests:**
   - Small (< 2,000 pop) vs large communes
   - Communes with vs without alternative maternity within 30km
   - Interior/rural vs urban
6. **Placebo:** Effect on La France Insoumise (LFI) vote share (left populist — should be null or opposite if mechanism is right-populist specific)
7. **Robustness:** Continuous distance treatment, alternative bandwidth, dropping Paris/Île-de-France
