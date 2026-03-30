# Research Plan: Fiscal Guardrails or Growth Brakes? Cantonal Debt Brakes and Public Investment Composition in Switzerland

## Research Question

Do cantonal debt brakes reshape the *functional composition* of public spending — shifting expenditure away from investment-intensive categories (transport infrastructure, education capital) toward current consumption (administration, transfers) — or do they achieve fiscal discipline through proportional cuts?

## Identification Strategy

**Callaway-Sant'Anna staggered DiD** exploiting the fact that Swiss cantons adopted debt brakes (Schuldenbremsen) at different times from the 1990s through the 2010s.

- **Treatment**: Year of cantonal debt brake adoption/tightening
- **Treated cantons**: ~20-22 cantons that adopted formal fiscal rules during 1990-2015
- **Control group**: Never-treated cantons (those without formal debt brakes as of 2020) + not-yet-treated cantons
- **Estimator**: Callaway & Sant'Anna (2021) with not-yet-treated comparison
- **Clustering**: Canton level (26 clusters — will use wild cluster bootstrap)

### Known adoption timeline (from literature):
- St. Gallen: 1929 (tightened 1990s)
- Fribourg: 1960 (codified 1994)
- Solothurn: 1994
- Graubünden: 1998
- Appenzell AR, Bern, Lucerne, Nidwalden, Obwalden, Schaffhausen, Thurgau, Zurich: 2000s
- Federal level: 2003 (not used as cantonal treatment)
- Remaining cantons: 2000s-2010s

## Expected Effects and Mechanisms

1. **Composition shift** (main hypothesis): Debt brakes are easier to comply with by cutting investment (long gestation, diffuse beneficiaries) than current spending (visible services, concentrated beneficiaries). We expect the share of spending on infrastructure/transport to fall post-adoption.

2. **Administrative growth**: If debt brakes create compliance costs (monitoring, reporting, rule design), administration spending may increase.

3. **Null composition**: If fiscal rules induce proportional austerity, functional shares remain stable — the debt brake constrains the level but not the mix.

## Primary Specification

$$Y_{ct} = \text{ATT}(g,t) \text{ via CS estimator}$$

Where $Y_{ct}$ is the share of function $f$ in total cantonal expenditure for canton $c$ in year $t$. Group $g$ = adoption cohort.

**Outcomes (functional shares):**
- Education (Bildung)
- Health (Gesundheit)
- Social welfare (Soziale Wohlfahrt)
- Transport/infrastructure (Verkehr)
- Public safety (Öffentliche Sicherheit)
- General administration (Allgemeine Verwaltung)
- Culture/recreation (Kultur, Sport und Freizeit)

**Robustness:**
1. Sun & Abraham (2021) estimator
2. Placebo on administration spending (should NOT decrease)
3. Triple-difference by rule stringency (hard vs soft rules)
4. Event-study plots for pre-trend validation
5. Wild cluster bootstrap for inference with 26 clusters

## Data Source and Fetch Strategy

### Primary: BFS Public Finance Statistics
- **Source**: BFS PXWeb API — Öffentliche Finanzen der Kantone (cantonal public finances)
- **Variables**: Expenditure by functional classification and canton, annual
- **Period**: 1990-2023 (or latest available)
- **Access**: No API key needed

### Debt Brake Adoption Timing
- Compile from academic literature: Feld & Kirchgässner (2008), Luechinger & Schaltegger (2013), Burret & Feld (2018)
- Cross-reference with rcds/swiss_legislation HuggingFace dataset
- Hand-code adoption year for each canton

### Population/Controls
- BFS cantonal population and demographic data
- Cantonal GDP/income from BFS regional accounts
