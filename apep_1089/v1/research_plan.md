# Research Plan: Compliance Theater? EU NIS2 Cybersecurity Regulation and Firm Security Investment

## Research Question

Does the EU NIS2 Directive's 50-employee threshold increase cybersecurity investment among newly regulated medium-sized firms, or does it merely generate formal compliance documentation without changing technical security practices? We test whether firms respond to regulatory scope through substantive security improvements versus "compliance theater."

## Identification Strategy

**Primary Design: Difference-in-Differences by firm size class**

- **Treated group:** Firms with 50-249 employees (newly covered by NIS2, previously exempt under NIS1)
- **Control group:** Firms with 10-49 employees (exempt from NIS2)
- **Pre-treatment periods:** 2019, 2022 (Eurostat triennial ICT survey)
- **Post-treatment period:** 2024 (first survey wave after NIS2 entered into force Jan 2023)

The 50-employee threshold is statutory (Recommendation 2003/361/EC), creating a sharp regulatory boundary. Firms just below 50 employees face no NIS2 obligations; firms just above face mandatory risk management, incident reporting, and supply chain security requirements.

**Secondary Design: Triple-Difference (DDD)**

Interact the size-class DiD with cross-country transposition timing. By October 2024, ~10 member states had fully transposed NIS2 into national law (Belgium, Croatia, Czechia, Denmark, Estonia, Germany, Greece, Italy, Cyprus) while others (France, Spain, Ireland) had not. The DDD tests whether the regulatory effect is stronger in early-transposing countries.

**Dosage Test:** 250+ employee firms were already regulated under NIS1 (Directive 2016/1148). NIS2 intensified their obligations but did not newly cover them. We test whether 250+ firms show weaker effects than 50-249 firms (as predicted if NIS2 matters at the extensive margin of regulatory coverage).

## Expected Effects and Mechanisms

**If regulation works (substantive compliance):**
- Technical security measures (encryption, IDS, security testing) increase for 50-249 firms relative to 10-49
- Effects concentrated in early-transposing countries
- Both formal documentation AND technical measures increase

**If "compliance theater":**
- Formal documentation (security policies, risk assessments, staff training) increases
- Technical measures (encryption, IDS, penetration testing) do NOT increase
- Gap between documentation and technical investment widens

**Null hypothesis:** No effect — firms were already investing in cybersecurity at privately optimal levels, or NIS2 obligations are not yet binding.

## Primary Specification

$$Y_{cst} = \alpha + \beta \cdot \text{Post}_t \times \text{Treated}_s + \gamma_c + \delta_s + \theta_t + \mu_{ct} + \epsilon_{cst}$$

Where:
- $Y_{cst}$: cybersecurity measure adoption rate (%) for country $c$, size class $s$, year $t$
- $\text{Post}_t$: indicator for 2024
- $\text{Treated}_s$: indicator for 50-249 employee size class
- $\gamma_c$: country fixed effects
- $\delta_s$: size class fixed effects
- $\theta_t$: year fixed effects
- $\mu_{ct}$: country × year fixed effects (absorb country-specific ICT trends)
- Clustering: country level (26 clusters) with wild cluster bootstrap for inference

**DDD extension:** Add $\text{Post}_t \times \text{Treated}_s \times \text{Transposed}_c$ triple interaction.

## Data Source and Fetch Strategy

**Primary data:** Eurostat ICT security survey (`isoc_cisce_ra`)
- 33 cybersecurity indicators by country × size class × year
- Size classes: 10-49 (small), 50-249 (medium), 250+ (large)
- Years: 2019, 2022, 2024
- 26 EU countries with complete panels
- ~1,994 non-null observations confirmed in smoke test

**Outcome categories (for compliance theater test):**
- **Technical measures:** ICT security policy, risk assessment, security testing/audit, access controls, encryption, IDS/IPS, log maintenance, VPN, backup
- **Formal/documentation measures:** Documented security policy, staff awareness training, risk assessment documentation

**Secondary data:** `isoc_cisce_ic` (security incidents by size class) — tests whether regulation also reduces incidents

**Transposition data:** EUR-Lex CELLAR SPARQL via `eurlex` R package — NIS2 national implementation measures with notification dates

**Fetch plan:**
1. Eurostat `isoc_cisce_ra` via `eurostat` R package — all indicators, all countries, all size classes
2. Eurostat `isoc_cisce_ic` for incident data
3. CELLAR SPARQL for NIS2 transposition dates per member state
4. Manual coding of transposition status from official EUR-Lex records as backup
