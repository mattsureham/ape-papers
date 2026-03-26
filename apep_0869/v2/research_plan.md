# Research Plan: The Litigation Tax on Biometrics — Evidence from Illinois's Rosenbach Ruling

## Research Question

Did the 2019 Illinois Supreme Court ruling in *Rosenbach v. Six Flags* — which eliminated the injury requirement for BIPA lawsuits and unleashed a wave of biometric privacy litigation — reduce technology-sector employment and business formation in Illinois relative to neighboring states?

## Policy Background

Illinois enacted the Biometric Information Privacy Act (BIPA) in 2008, but the law remained largely dormant until January 25, 2019, when the Illinois Supreme Court ruled in *Rosenbach v. Six Flags Entertainment Corp.* that plaintiffs need not allege actual injury to sue under BIPA — a mere procedural violation suffices. This ruling transformed BIPA from a paper tiger into the most actively litigated privacy statute in the US:
- Lawsuits surged from <60/year pre-ruling to 300+/year post-ruling
- Settlements exceeded $1.6 billion (Facebook $650M, BNSF $228M, TikTok $92M)
- The ruling created strict liability for any collection of fingerprints, face scans, iris scans, or voiceprints without prior written consent

## Identification Strategy

**Primary: Border-County Triple-Difference**

The core design exploits three sources of variation:
1. **Geographic**: Illinois border counties vs. adjacent counties in neighboring states (Indiana, Wisconsin, Iowa, Missouri, Kentucky)
2. **Industry**: Biometric-exposed industries (Information NAICS 51, Professional/Technical Services NAICS 54, Manufacturing NAICS 31-33) vs. BIPA-exempt industries (Healthcare NAICS 62, Finance NAICS 52)
3. **Time**: Pre-Rosenbach (2015Q1–2018Q4) vs. post-Rosenbach (2019Q1–2023Q4)

**Triple-diff specification:**
Y_{cit} = α + β₁(IL_c × Exposed_i × Post_t) + β₂(IL_c × Post_t) + β₃(Exposed_i × Post_t) + β₄(IL_c × Exposed_i) + γ_c + δ_i + τ_t + ε_{cit}

The identifying assumption: absent the Rosenbach ruling, biometric-exposed industries would have evolved similarly in IL border counties and adjacent out-of-state counties relative to non-exposed industries.

**Secondary: State-Level Event Study**
Event study comparing Illinois to a synthetic or matched control group of states, tracing quarterly employment dynamics around the ruling.

## Expected Effects and Mechanisms

**Primary mechanism — Litigation risk premium:** Firms in biometric-exposed sectors face expected damages of $1,000-$5,000 per violation (per scan, per person). For a warehouse using fingerprint time clocks with 500 employees scanning twice daily, annual exposure could exceed $3.6 billion. This creates a strong incentive to:
- Relocate operations to neighboring states
- Avoid establishing new operations in Illinois
- Substitute away from biometric technologies

**Expected direction:** Negative effect on employment and establishments in biometric-exposed industries in Illinois. Potentially positive spillover to border-state counties (firms relocating).

**Null result interpretation:** If null, this suggests biometric technology is sufficiently embedded that firms absorb litigation costs rather than relocate — implying BIPA achieves deterrence without destroying jobs.

## Primary Specification

DiD with county × industry × quarter data:
- **Outcome:** log(employment), log(establishments), log(average weekly wage)
- **Treatment:** IL × Exposed_industry × Post_2019Q1
- **Fixed effects:** County, Industry, Quarter (or County×Industry + Quarter)
- **Clustering:** State level (conservative, accounting for policy-level variation)
- **Sample:** Border counties only (counties sharing a state border), 2015Q1–2023Q4
- **COVID robustness:** Re-estimate on 2015Q1–2019Q4 (pre-COVID only, 4 clean post-treatment quarters)

## Data Source and Fetch Strategy

**Primary: BLS Quarterly Census of Employment and Wages (QCEW)**
- Quarterly county × NAICS sector data
- Employment, establishments, average weekly wage
- Available through BLS QCEW data files (CSV downloads by year)
- States: IL (17), IN (18), WI (55), MO (29), IA (19), KY (21)
- Years: 2015–2023
- NAICS: 2-digit sector codes (51, 52, 54, 62, 31-33)

**Secondary: Census Business Formation Statistics (BFS)**
- Monthly/quarterly business applications by state
- Available via Census API
- Captures new business formation response

**Border county identification:**
- Use FIPS codes to identify IL counties on state borders
- Match to adjacent out-of-state counties using Census county adjacency file

## Robustness Checks

1. Pre-trend event study (quarterly leads/lags, 12+ pre-periods)
2. Pre-COVID subsample (2015Q1–2019Q4)
3. Leave-one-border-state-out
4. Alternative industry classifications for "biometric-exposed"
5. Callaway-Sant'Anna not needed (single sharp treatment date)
6. Wild cluster bootstrap (6 state clusters is low)
7. Permutation inference (reassign treatment to other border pairs)
