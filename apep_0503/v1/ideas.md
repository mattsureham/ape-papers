# Research Ideas

## Idea 1: Banned from the Market — Energy Labels, Rental Prohibitions, and Property Price Capitalization in France

**Policy:** France's Loi Climat et Résilience (2021) created a phased rental ban based on DPE (Diagnostic de Performance Énergétique) energy labels. Properties rated G (>420 kWh/m²/year under new DPE) were banned from rental starting January 2023 (extreme G >450 kWh) and January 2025 (all G). Class F faces a ban in January 2028, class E in January 2034. The DPE reform of July 2021 introduced a double-seuil system (worst of energy consumption or GHG emissions determines the label).

**Outcome:** Property transaction prices from DVF (Demandes de Valeurs Foncières), 2019–2025. The running variable is energy consumption per m² (kWh/m²/year) and GHG emissions per m² (kg CO₂eq/m²/year). The treatment is regulatory status attached to each DPE band.

**Identification:** Multi-cutoff sharp RDD at each DPE band boundary. The key design exploits the fact that properties just above and below each cutoff have nearly identical physical characteristics but face different regulatory treatment:
- **G/F boundary (420 kWh):** Active rental ban — properties just below are banned, just above are legal. This captures the capitalization of a regulatory prohibition.
- **F/E boundary (330 kWh):** Anticipated ban (2028) — properties in F face an announced future ban. This captures anticipation/forward-looking capitalization.
- **E/D boundary (250 kWh):** Distant anticipated ban (2034) — weaker anticipation signal.
- **D/C, C/B, B/A boundaries:** No regulatory consequence — pure information/salience effects.

**Built-in placebo:** Owner-occupied properties are not subject to the rental ban. If price discontinuities at G/F and F/E appear only for properties in the rental sector (or in high-rental communes) but not for owner-occupied properties, this confirms the regulatory channel.

**Mechanism decomposition:**
1. Information/salience effect (at all cutoffs, including non-regulatory ones)
2. Current regulatory effect (at G/F, where ban is active)
3. Anticipated regulatory effect (at F/E and E/D, where future bans are announced)
4. Heterogeneity by binding dimension (energy vs. CO₂ under double-seuil)

**Why it's novel:**
- Sejas-Portillo et al. (2025, AEJ:Applied) studied UK EPC labels as information — pure salience effects, no regulatory bite. France has an actual **rental prohibition**, creating a much stronger treatment and enabling the first causal test of regulatory vs. informational capitalization at energy-label cutoffs.
- Chareyron (2024, TEPP WP) studied French DPE labels pre-ban (2016–2021) and found label effects. My paper extends to the post-ban period (2023–2025) and decomposes the regulatory effect from the pre-existing label effect.
- The phased ban schedule (G→F→E over 12 years) creates a unique natural experiment in anticipation dynamics — no other paper has tested how announced future bans at different horizons capitalize into current prices.
- The double-seuil (worst of energy or CO₂) enables heterogeneity analysis by binding constraint dimension.
- Trade-off discovery angle: Did the ban force renovation (intended effect), or did it mainly displace properties from rental to sales markets (substitution), increasing vacancies and reducing rental supply?

**Feasibility check:**
- ✅ ADEME DPE database: 14.17M records post-July 2021, continuous energy scores, DPE labels, commune codes, property characteristics. API confirmed working.
- ✅ DVF: Complete property transaction records since 2019, prices, addresses, commune codes. Download confirmed (departmental CSVs).
- ✅ Linkage: DPE → DVF via commune code + address matching (demonstrated by Chareyron 2024).
- ✅ Label distribution: G=504K, F=879K, E=2.27M, D=4.42M, C=5.21M — massive samples near each cutoff.
- ✅ Running variable is continuous (kWh/m²/year), enabling standard RDD estimation.
- ⚠️ Potential bunching at cutoffs (testable with McCrary density test).
- ⚠️ Double-seuil complicates running variable dimensionality — can focus on energy-bound properties (majority) or implement bivariate RDD.

---

## Idea 2: What's a Mayor Worth? Politician Compensation, Governance Quality, and the Compound Treatment Problem in French Communes

**Policy:** French mayoral compensation (indemnités) is set by law as a percentage of a civil service pay index, with discrete jumps at population thresholds: <500 (25.5%), 500+ (40.3%, +58% jump), 1,000+ (51.6%, +28%), 3,500+ (55.0%, +7%), 10,000+ (65.0%, +18%), 20,000+ (90.0%, +38%), 50,000+ (110.0%, +22%), 100,000+ (145.0%, +32%). The December 2025 Gatel Law added further increases for small communes.

**Outcome:** Commune-level fiscal data from DGFiP (Comptes individuels des communes, 2000–2024): operating expenditure, investment spending, personnel costs, debt, tax rates. Electoral data: candidate quality proxied by profession codes from Répertoire National des Élus, electoral competitiveness, turnout.

**Identification:** Multi-cutoff RDD at each population threshold. The key challenge is compound treatment: every salary threshold coincides with a council size change (different thresholds in the CGCT). The identification strategy exploits differential "dosage":
- At 20,000: salary jumps +38% but council size only +6% (35→37 members) — salary-dominated threshold.
- At 3,500: salary jumps only +7% but council size jumps +17% (23→27) — council-dominated threshold.
- Council-size-only thresholds (1,500; 2,500; 5,000) where NO salary change occurs serve as placebos.
- If fiscal outcomes respond at salary thresholds but not at council-size-only thresholds, this supports the salary interpretation.

**Why it's novel:**
- The "French Gagliarducci-Nannicini" has never been done. Gagliarducci & Nannicini (2013, JEEA) exploited Italy's clean 5,000 threshold (salary-only). France has no pure salary-only threshold, but the compound treatment problem can be addressed through differential dosage analysis and placebo thresholds.
- Gavoille (2021, Public Choice) studied the 20,000 threshold for campaign spending only. No one has studied governance quality, fiscal outcomes, or candidate selection.
- The December 2025 Gatel Law provides a natural pre/post reform event at the lower thresholds.

**Feasibility check:**
- ✅ Commune fiscal data: 69,877 commune-year records, API confirmed working (data.economie.gouv.fr).
- ✅ Population data: INSEE populations légales, annual.
- ✅ Electoral data: data.gouv.fr, multiple election years.
- ✅ RNE: Profession codes for elected officials.
- ⚠️ Compound treatment problem is serious — Eggers et al. (2018, AJPS) specifically warns about French population thresholds.
- ⚠️ ~35,000 communes total; sample near any single threshold may be small.

---

## Idea 3: Drawing the Line — Flood Risk Zone Designations and Property Value Capitalization in France

**Policy:** Plans de Prévention des Risques d'Inondation (PPRI) create legally binding geographic boundaries. Properties inside a PPRI zone face mandatory flood insurance disclosure, construction restrictions, and building code requirements. Properties just outside face none of these constraints. PPRIs have been adopted at different times across France (staggered implementation since the 1995 Barnier Law).

**Outcome:** Property transaction prices from DVF. The running variable is geographic distance to the nearest PPRI boundary.

**Identification:** Spatial RDD at PPRI boundaries. Compare transactions just inside vs. just outside PPRI zones, controlling for distance to the boundary. The sharpness comes from the legal discontinuity: the zone boundary creates an immediate change in regulatory status, insurance requirements, and disclosure obligations.

**Why it's novel:**
- While flood risk capitalization has been studied (e.g., Bin et al. 2008 on FEMA zones in the US), no one has used spatial RDD at French PPRI boundaries with DVF data.
- The staggered adoption of PPRIs across communes enables a combined RDD + DiD design (before/after zone designation × distance to boundary).
- The disclosure requirement creates an information channel distinct from the actual flood risk.

**Feasibility check:**
- ✅ DVF confirmed accessible.
- ⚠️ PPRI shapefiles: Available from Georisques (georisques.gouv.fr) but need to verify downloadability and format.
- ⚠️ Spatial matching between DVF transactions and PPRI boundaries requires GIS processing.
- ⚠️ PPRI boundaries may be drawn along natural features (rivers, flood plains) that independently affect property values — identification concern.
- ⚠️ Less developed than Ideas 1 and 2; would need significant additional validation.
