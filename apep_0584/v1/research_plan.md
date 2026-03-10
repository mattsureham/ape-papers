# Research Plan: The Symmetric Test

## Research Question
Did Oregon's drug decriminalization (Measure 110, Feb 2021) causally increase overdose deaths, or was the observed increase driven by the concurrent fentanyl wave? Oregon's subsequent recriminalization (HB 4002, Sep 2024) provides a unique symmetric test: if decriminalization was causal, recriminalization should reverse it.

## Identification Strategy
Augmented Synthetic Control Method (Ben-Michael, Feller, Rothstein 2021) applied twice:

**Design 1 — Decriminalization (Feb 2021):**
- Treated: Oregon
- Donor pool: 49 states + DC
- Pre-period: Jan 2015 – Jan 2021 (73 months)
- Post-period: Feb 2021 – Aug 2024 (43 months)

**Design 2 — Recriminalization (Sep 2024):**
- Treated: Oregon
- Donor pool: same states, re-weighted
- Pre-period: Feb 2021 – Aug 2024 (43 months)
- Post-period: Sep 2024 – latest available (~13 months)

**Design 3 — Symmetric Test:**
- H0: τ_decrim + τ_recrim = 0 (full causal reversal)
- H1: τ_decrim + τ_recrim ≠ 0 (hysteresis, confounding, or partial reversal)
- Under confounding (fentanyl drove both): τ_recrim ≈ 0
- Under causal: τ_decrim > 0 and τ_recrim < 0

## Expected Effects and Mechanisms
- **If causal:** Decriminalization increased overdose deaths by removing criminal deterrence; recriminalization should decrease them. Expect symmetric effects of opposite sign.
- **If fentanyl confounding:** Both Oregon and donors experienced the fentanyl wave. The decriminalization "effect" is spurious. Recriminalization should show null effect since fentanyl remains prevalent.
- **If hysteresis:** Decriminalization established drug markets and supply chains that persist after recriminalization. Expect |τ_recrim| < |τ_decrim|.

## Primary Specification
Augmented SCM with time-varying covariates:
- Overdose death rate per 100K (primary outcome)
- Matching on: pre-treatment overdose trajectory, synthetic opioid share, population, urbanization
- Ridge-augmented to reduce bias from imperfect pre-treatment fit

## Planned Robustness
1. Standard SCM (Abadie et al. 2010) without augmentation
2. Permutation inference: both designs for all 49 donor states as placebos
3. Leave-one-out donor stability
4. Restricted donor pool (Western states only: WA, CA, NV, ID, AZ, CO, MT, UT, NM, WY)
5. Fentanyl exposure control: include synthetic opioid share as time-varying covariate
6. Rolling pre-period windows (3, 4, 5, 6 years)
7. COVID-19 controls

## Mechanism Tests (Placebo/Decomposition)
1. **Drug decomposition:** Separate SCM for fentanyl deaths, heroin deaths, psychostimulant deaths, cocaine deaths. If effect is concentrated in fentanyl deaths → confounding more likely. If spread across drug types → deterrence channel more likely.
2. **Treatment channel:** Test whether TEDS admissions changed (SAMHSA data, 2006-2023)

## Data Sources
- CDC VSRR: Socrata endpoint xkb8-kh2a (monthly state overdose counts, 2015-2025)
- Census population estimates via API
- Drug-specific indicators from same VSRR endpoint

## Power Assessment
- Single treated unit (Oregon) — requires permutation-based inference
- 73 pre-treatment months for Design 1 (strong)
- 43 pre-treatment months for Design 2 (adequate)
- 13+ post-treatment months for Design 2 (short but growing)
- Outcome variance: Oregon's death rate moved from ~10/100K to ~25/100K — large signal
