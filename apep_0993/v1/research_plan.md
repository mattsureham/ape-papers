# Research Plan: apep_0993

## Research Question

Did South Korea's 52-hour workweek cap (2018–2021) causally reduce actual working hours, or does the dramatic aggregate decline reflect secular trends and COVID? How did effects vary across firm sizes and industries?

## Policy Background

The Act on the Standards for Employment was amended March 2018 to cut the maximum weekly hours from 68 to 52 (40 regular + 12 overtime). Staggered implementation by firm size:
- **Wave 1 (July 2018):** Firms with 300+ employees + public sector
- **Wave 2 (January 2020):** Firms with 50–299 employees
- **Wave 3 (July 2021):** Firms with 5–49 employees

Criminal penalties: up to 2 years imprisonment or KRW 20M fine.

## Identification Strategy

### Primary: Industry-Level Shift-Share DiD

Industries dominated by large firms (300+) were exposed earlier and more intensely. Cross-industry variation in treatment timing identifies the law's causal effect.

**Construction:**
1. From OECD SDBS, obtain pre-reform (2017) employment shares by firm-size class for each Korean industry.
2. Construct continuous treatment intensity: `Treatment_it = Σ_s (share_is × D_st)`
3. Estimate: `Hours_it = α_i + γ_t + β × Treatment_it + ε_it`

### Secondary: Cross-Country Comparison
Compare Korea's hours trajectory to OECD peers with no comparable reform.

### Falsification
1. Placebo industries already below 52 hours
2. Pre-trend tests (2010–2017)
3. Cross-country placebo
4. COVID disentanglement (Wave 2 overlap)

## Data Sources
1. ILO ILOSTAT API — weekly hours by economic activity for Korea
2. OECD Stats — hours worked, employment by firm size and industry
3. ILO employment by economic activity (for weighting)
4. OECD comparator countries

## Exposure Alignment
The 52-hour cap directly constrains workers who previously worked 52-68 hours per week. High-hours industries (Transport, Manufacturing, Accommodation) have a disproportionate share of such workers because their industry averages (45-48 hours) imply fat right tails above 52 hours. Low-hours industries (Education, Public Admin) have averages in the 35-40 range, meaning few workers are constrained. The treatment is exposure intensity — not a binary on/off — measured by pre-reform industry-level average hours as a proxy for the share of workers affected by the cap.

## Expected Effects
- Large firms (300+): Sharp hours decline post-July 2018
- Medium firms (50–299): Decline post-January 2020, partially confounded by COVID
- Small firms (5–49): Smaller/delayed effect post-July 2021
- Declining treatment effects across waves (compliance cascade)
