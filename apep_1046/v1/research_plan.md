# Research Plan: The Safety Balloon

## Research Question

When OSHA launches a National Emphasis Program (NEP) targeting a specific workplace hazard, do injuries from *non-targeted* hazard categories increase at inspected establishments? If so, this constitutes cross-hazard injury substitution — firms reallocate limited safety budgets toward the inspected hazard at the expense of others.

## Identification Strategy

**Triple-difference within establishment:**
1. **Establishment dimension:** NEP-inspected vs. never/not-yet-inspected establishments (same 4-digit NAICS × state)
2. **Time dimension:** Pre vs. post first NEP inspection
3. **Hazard dimension:** Targeted hazard category vs. non-targeted categories

The key test: if OSHA inspections reduce injuries uniformly, non-targeted categories should not increase. An increase in non-targeted injuries *conditional on* targeted-category improvement is direct evidence of cross-hazard substitution.

**Placebos:**
- Complaint-driven inspections (not hazard-specific) should show no differential effect across hazard types
- NAICS sectors never targeted by any active NEP

## Expected Effects and Mechanisms

- **Targeted hazard injuries:** Decline (established in literature — Levine et al. 2012)
- **Non-targeted hazard injuries:** Increase if substitution is real; null if firms have slack
- **Mechanism:** Fixed safety budgets — compliance with targeted hazard crowds out investment in other hazards
- **Heterogeneity:** Stronger substitution at small firms (tighter budget constraints)

## Primary Specification

```
Y_{i,h,t} = α_i + γ_{h,t} + β₁·Post_{i,t} + β₂·NonTargeted_h + β₃·(Post_{i,t} × NonTargeted_h) + ε_{i,h,t}
```

Where:
- i = establishment, h = hazard category, t = year
- Post = 1 after first NEP inspection
- NonTargeted = 1 for hazard categories NOT targeted by the NEP that triggered the inspection
- β₃ is the coefficient of interest: differential change in non-targeted vs. targeted injuries post-inspection
- Cluster SEs at establishment level

## Data Sources and Fetch Strategy

### 1. OSHA ITA Form 300A (Injury Tracking Application)
- URL: https://www.osha.gov/Establishment-Specific-Injury-and-Illness-Data
- Years: 2016-2024 (9 years)
- Unit: Establishment-year
- Variables: Total injuries, skin disorders, respiratory conditions, poisonings, hearing loss, other illnesses, DAFW, DJTR, deaths
- ~396,000 establishments/year
- Download: Annual CSV/ZIP files

### 2. OSHA Enforcement Data (IMIS)
- URL: https://enforcedata.dol.gov/views/data_summary.php
- Variables: Inspection number, establishment name/address, NAICS, inspection type (programmed/complaint/referral), NEP flag, open date, close date, violations by standard
- Download: Bulk CSV files

### 3. Linkage Strategy
- Match ITA establishments to IMIS inspections via establishment_id or name+address+NAICS fuzzy matching
- Flag NEP inspections using activity_nr coding or related_activity fields in IMIS
- Classify inspections by targeted hazard category using NEP program codes

## Analysis Pipeline
1. `01_fetch_data.R` — Download ITA and IMIS data
2. `02_clean_data.R` — Link establishments, classify NEP inspections by hazard type, construct panel
3. `03_main_analysis.R` — Triple-diff estimation, event study
4. `04_robustness.R` — Placebo tests, heterogeneity by firm size, alternative specifications
5. `05_tables.R` — Generate all tables including SDE appendix
