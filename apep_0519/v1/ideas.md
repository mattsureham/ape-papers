# Research Ideas

## Idea 1: Mandating the Green Transition: Cantonal Building Energy Codes and Heat Pump Adoption in Switzerland

**Policy:** MuKEn 2014 (Mustervorschriften der Kantone im Energiebereich) — model energy prescriptions for buildings developed by the Conference of Cantonal Energy Directors (EnDK). Cantons adopted these prescriptions at staggered times from 2017 to 2024. As of 2023, 22 cantons have adopted at least some modules; 4 cantons have not yet adopted. The code mandates: (a) near-zero energy standard for new buildings, (b) partial replacement of fossil heating systems upon renovation, (c) renewable energy requirements for new construction, (d) building-integrated solar obligations. Crucially, cantons cherry-picked modules — creating variation in treatment intensity.

**Outcome:** Federal Register of Buildings and Dwellings (GWR) via opendata.swiss — building-level data on heating energy source (heat pump, oil, gas, wood, district heating, electric resistance), updated continuously. Aggregated by municipality and year. Also: BFS construction statistics (building permits, completions) at municipal level via PXWeb. Additionally: GEAK/CECB cantonal building energy certificates for energy performance ratings.

**Identification:** Staggered DiD exploiting differential cantonal adoption timing of MuKEn 2014 modules. 22 treated cantons vs. 4 never/late-treated cantons. At the municipal level: ~1,800 treated municipalities vs. ~300 control municipalities. CS-DiD estimator (Callaway & Sant'Anna) for heterogeneous timing. Modular adoption enables internal replication: compare effects of heating replacement module (16 cantons) vs. solar mandate (15 cantons) vs. envelope standards (18 cantons).

**Why it's novel:** Despite Switzerland being a global leader in building decarbonization and MuKEn being the primary regulatory instrument, NO causal quasi-experimental study exists on MuKEn 2014's effects. Existing work is either descriptive (ENDK monitoring reports), simulation-based (Brodnicke et al. 2025 agent-based model), or subsidy-focused (subsidy analysis in Vaud/Geneva). This would be the FIRST causal estimate of whether mandated building energy codes accelerate heat pump adoption or deter renovation activity — a question with direct relevance to the EU's EPBD recast and global building decarbonization.

**Feasibility check:** Confirmed: GWR building-level data with heating energy source on opendata.swiss (multiple formats including Parquet). BFS PXWeb has construction statistics at municipal level. ENDK publishes adoption dates and module-level implementation status by canton. 22 treated cantons exceeds the 20-unit threshold for DiD. Pre-treatment data available from 2012 (5+ years before first adopter in 2017).

**Key mechanisms to decompose:**
- New construction vs. renovation (extensive margin)
- Heat pump adoption vs. fossil heating phase-out (technology substitution)
- Module-specific effects (heating replacement vs. solar vs. envelope)
- Residential vs. commercial buildings

**Built-in placebos:**
- Existing buildings not undergoing renovation (unaffected by code)
- Cantons that adopted MuKEn 2008 but not 2014 (weaker/null treatment)
- Non-regulated building categories

**Welfare/counterfactual:** Implied carbon abatement cost per ton from mandated (vs. subsidy-driven) heat pump adoption.

---

## Idea 2: The Price of Scale: Municipal Mergers, Fiscal Efficiency, and Democratic Disengagement in Switzerland

**Policy:** Swiss municipal mergers (Gemeindefusionen) — 778 municipalities merged between 2000 and 2025, reducing the total from 2,899 to 2,121. Mergers are voluntary and typically approved by local referendum. Concentrated in Ticino, Fribourg, Graubünden, and Glarus.

**Outcome:** BFS municipal financial statistics (expenditure, revenue, tax multiplier, debt) via PXWeb. Voter turnout in federal referendums from swissdd R package. Population and demographic data from BFS.

**Identification:** Staggered DiD with 100+ merger events, each involving 2+ municipalities. CS-DiD clustered at the merger-group level. SMMT R package for panel harmonization across merger boundaries.

**Why it's novel:** While fiscal effects have been studied (Zell et al. 2025; Fritz 2016) and political participation examined for Glarus (Frey et al. 2023), NO paper combines fiscal + democratic + demographic outcomes in a comprehensive multi-margin welfare analysis using the full universe of Swiss mergers with modern CS-DiD methods. The novel angle: mergers as a fiscal-democratic TRADE-OFF — efficiency gains vs. democratic disengagement.

**Feasibility check:** SMMT package confirmed available on CRAN. BFS PXWeb has municipal-level financial data. swissdd provides municipal-level referendum turnout. 100+ treated merger groups well above 20-unit threshold. Pre-treatment panels from 1990+.

**Concern:** Significant existing literature on this topic may limit tournament novelty score.

---

## Idea 3: Does Education Harmonization Help or Hurt? Evidence from Switzerland's HarmoS Concordat

**Policy:** HarmoS (Harmonisierung der obligatorischen Schule) concordat adopted by 15 cantons in 2009-2015; rejected by 9-11 cantons (several by popular referendum). Harmonized: school entry age (4), structure (6+3), language instruction timing, national standards.

**Outcome:** BFS education statistics (enrollment, graduation rates, transition rates) at cantonal level. Possibly ÜGK (Überprüfung der Grundkompetenzen) national assessment data (2016+).

**Identification:** DiD comparing adopting vs. rejecting cantons before/after implementation. Referendum rejection provides plausibly exogenous control group. 15 treated cantons.

**Why it's novel:** No causal evidence on whether education harmonization in a federal system improves student outcomes. Tests the "laboratory of federalism" hypothesis.

**Feasibility check:** PARTIAL. Education outcome data at cantonal level exists via BFS. However, ÜGK assessments may not be publicly available at sufficient granularity. 15 treated cantons is below the 20-unit threshold — would need to use municipality level. Pre-treatment data limited for achievement outcomes.

---

## Idea 4: Physician Supply Restrictions and Healthcare Access: Evidence from Swiss Cantonal Moratoria

**Policy:** Cantonal moratoria on new physician (specialist) admissions to the statutory health insurance system. Federal law (KVG) allowed cantons to restrict new provider licenses. Multiple cantons adopted restrictions at different times from 2002 onward, with renewals and extensions through 2023.

**Outcome:** Physician density by canton (BFS/OBSAN), health expenditure per capita, hospital admission rates, waiting times.

**Identification:** Staggered DiD across cantons with varying moratorium timing and intensity. Could combine with geographic spillovers (physicians relocating to unrestricted cantons).

**Why it's novel:** While physician supply regulation is studied internationally, the Swiss setting provides unique variation because cantons CHOSE whether and when to implement the moratorium. The spillover/relocation channel is underexplored.

**Feasibility check:** UNCERTAIN. OBSAN publishes aggregate health statistics but detailed provider-level data may require special access. Need to verify publicly available physician density series on opendata.swiss/BFS PXWeb. Timing data requires careful documentation from cantonal sources.

---

## Idea 5: Do Harmonized Accounting Standards Discipline Local Governments? Evidence from Swiss HRM2 Adoption

**Policy:** Harmonized Accounting Model 2 (HRM2) — second-generation public sector accounting standard. Cantons adopted at staggered times: AR 2012, BS 2012, BL 2017, BE 2022, and others. Changes how municipal governments report assets, liabilities, depreciation, and investment.

**Outcome:** Municipal financial indicators (debt ratio, self-financing capacity, investment ratio) from BFS PXWeb. Possibly cantonal bond yields/credit ratings.

**Identification:** Staggered DiD comparing municipalities in cantons that adopted HRM2 earlier vs. later.

**Why it's novel:** Accounting standard changes in the public sector are rarely studied causally. The Swiss municipal setting allows testing whether transparency reforms alter fiscal behavior.

**Feasibility check:** Confirmed: BFS has municipal financial statistics via PXWeb. HRM2 adoption dates documented by Swiss Conference of Finance Directors. However, relatively few cantons adopted (4-6 with clear dates), which limits power. Topic may be too niche for tournament.
