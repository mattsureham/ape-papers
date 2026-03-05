# Research Ideas

## Idea 1: The Price of Pork — France's Dual-Mandate Ban and the Fiscal Cost of Local–National Connections

**Policy:** Loi organique n° 2014-125 du 14 février 2014, prohibiting the cumul of a parliamentary mandate with a local executive office. Fully effective at the June 2017 legislative elections. Before 2017, 476 of 577 deputies (82%) simultaneously held local executive offices (mostly mayorships). After 2017, all had to choose one mandate.

**Outcome:** Commune-level fiscal data from DGFiP Comptes individuels des communes (data.gouv.fr), covering annual revenue, capital expenditure, investment grants (DETR/DSIL), current spending, and debt. DVF property transactions (24M+ records) for real estate capitalization effects. Legislative and municipal election results for political competition outcomes.

**Identification:** Difference-in-differences comparing "cumulard communes" (communes whose député simultaneously served as local executive, primarily mayor) vs. "non-cumulard communes" before and after June 2017. Treatment defined at the constituency level (~476 treated constituencies vs. ~101 controls). Panel: 2008–2023 (9 pre-periods, 6 post-periods). Commune budgets aggregated to constituency level for primary spec, commune-level with constituency FE for mechanism analysis.

**Why it's novel:** No causal estimate exists in economics for the fiscal pork-barrel cost of dual mandates. The political science literature is entirely qualitative/descriptive (François 2017, Abel & Bouvet 2019). The economics of politician multi-tasking (dual mandates, part-time legislators) is understudied despite being central to constitutional design worldwide. France's 2017 ban is the cleanest natural experiment: a sharp, national reform with rich micro-data.

**Feasibility check:**
- **Variation confirmed:** 476 treated, 101 control constituencies. Large N.
- **Data accessible:** DGFiP commune budgets on data.gouv.fr (CSV, annual, 2000–2023). DVF bulk download. Assemblée nationale open data + NosDéputés.fr for deputy mandates (XIV legislature 2012-2017). Commune-constituency crosswalk on data.gouv.fr.
- **Not overstudied:** Zero economics papers found on Google Scholar or NBER.
- **DiD feasibility:** ≥20 treated units (476 constituencies), ≥5 pre-periods (2008–2016 = 9 years), ≥5 post-periods (2017–2023 = 7 years). Panel balanced.
- **Pre-trends testable:** Long pre-period enables rigorous parallel trends validation.
- **Placebo groups:** (i) Private-sector outcomes in the commune (should be unaffected by dual mandates). (ii) Communes in never-cumulard constituencies. (iii) "Fake ban" in 2012 (pre-ban placebo test).
- **Mechanism decomposition:** Investment grants vs. current spending; state transfers (DGF/DETR) vs. own-source revenue; capital spending on infrastructure vs. operating costs.
- **Trade-off discovery:** The ban may reduce local pork barrel (good for national efficiency) but worsen local public goods provision (bad for affected communes) — a genuine tension in constitutional design.

---

## Idea 2: Losing the Tax Lever — Taxe d'Habitation Abolition and Local Fiscal Autonomy

**Policy:** Progressive abolition of the taxe d'habitation on primary residences, announced October 2017, phased 2018–2023. 80% of households exempted by 2020, remaining 20% by 2023. Communes compensated with transfer of the département share of taxe foncière (property tax on buildings).

**Outcome:** DGFiP commune budgets (tax rates, revenue composition, spending), DVF property prices, municipal election outcomes (2020).

**Identification:** Differential-exposure DiD. Communes that relied heavily on taxe d'habitation revenue (high TH-to-total-revenue ratio pre-reform) experienced a larger fiscal shock than communes with low TH reliance. Continuous treatment intensity. Panel: 2012–2023.

**Why it's novel:** The largest French local tax reform in decades. No causal estimate of its effects on commune fiscal behavior. Related literature exists for property tax reforms (Lutz 2015, Adelino et al. 2017) but not for this specific reform. The question — how do local governments respond to losing a key tax instrument even when compensated — speaks to the Tiebout/fiscal federalism literature.

**Feasibility check:**
- **Variation confirmed:** TH share of revenue varies from <10% to >40% across communes.
- **Data accessible:** DGFiP commune budgets, DVF, election results — all on data.gouv.fr.
- **Concern:** COVID confound (2020-2021) overlaps with the reform window. Need to control for COVID effects or focus on the 2018-2019 initial phase. Also, compensation via taxe foncière transfer may make the net fiscal shock small.
- **DiD feasibility:** Continuous treatment, 35,000+ communes. Long pre-period.

---

## Idea 3: Does Scale Save? Evidence from France's Voluntary Municipal Mergers

**Policy:** Loi du 16 mars 2015 encouraging communes nouvelles (voluntary municipal mergers). ~2,500 communes merged into ~770 communes nouvelles between January 2016 and January 2019, reducing France's commune count by ~5%.

**Outcome:** DGFiP budgets (spending efficiency = per capita spending), DVF property prices, election results (turnout in merged vs. unmerged communes), service delivery indicators.

**Identification:** Staggered DiD (Callaway-Sant'Anna estimator) comparing communes that merged in wave t vs. never-merged communes. Waves: Jan 2016, Jan 2017, Jan 2018, Jan 2019.

**Why it's novel:** Municipal merger effects are studied for Denmark (Blom-Hansen et al. 2016), Germany (Reingewertz 2012), and Japan (Hirota & Yunoue 2017), but not for France's distinctive voluntary merger program. The voluntary nature creates endogeneity but also enables heterogeneity analysis by merger motivation (financial incentives vs. administrative efficiency vs. political consolidation).

**Feasibility check:**
- **Variation confirmed:** Staggered across 4 waves, ~2,500 treated communes.
- **Data accessible:** BANATIC for EPCI/merger tracking, DGFiP budgets, DVF.
- **Concern:** Selection into merger is voluntary → endogeneity. Would need IV (e.g., proximity to EPCI threshold creating merger pressure) or matching/weighting.
- **DiD feasibility:** 4 staggered cohorts, 2,500+ treated communes. Passes easily.

---

## Idea 4: Forced Together — Loi NOTRe, EPCI Mergers, and Intermunicipal Governance

**Policy:** Loi n° 2015-991 du 7 août 2015 (Loi NOTRe) raised the minimum population threshold for intercommunal structures (EPCI) from 5,000 to 15,000 inhabitants, forcing ~40% of EPCIs to merge by January 2017.

**Outcome:** EPCI-level budgets (DGFiP comptes des groupements), tax harmonization (convergence of local tax rates within merged EPCIs), service delivery.

**Identification:** DiD comparing EPCIs forced to merge (below 15,000 threshold) vs. EPCIs already above the threshold. The forced nature reduces selection concerns relative to Idea 3.

**Why it's novel:** Adds to intermunicipal cooperation literature with the first causal evidence from France's massive EPCI restructuring. Clean threshold-based treatment assignment.

**Feasibility check:**
- **Variation confirmed:** ~40% of EPCIs were below threshold. Large N of treated units.
- **Data accessible:** BANATIC (EPCI directory), DGFiP EPCI budgets.
- **Concern:** Concurrent reforms (region merging, competence transfers from départements to regions) may confound. The 15,000 threshold had derogations (mountain, island, low-density areas) which reduces the sharpness of the treatment.
- **DiD feasibility:** Not staggered (one-time 2017 implementation). But 2-period DiD with large N.

---

## Idea 5: The Métropole Effect — Urban Governance Consolidation and Local Economies

**Policy:** Loi MAPAM (2014) created 14+ métropoles with enhanced fiscal and planning powers (Grand Paris, Aix-Marseille, Lyon, etc.). Métropoles absorbed substantial competences from constituent communes and départements.

**Outcome:** Commune-level economic activity (firm creation from Sirene), DVF property prices, public investment, employment.

**Identification:** DiD comparing communes that joined métropoles vs. similar urban communes in large intercommunalities that did not become métropoles.

**Why it's novel:** Tests whether institutional scale-up in urban governance affects local economic outcomes. Relates to the "optimal city size" and agglomeration literatures.

**Feasibility check:**
- **Variation confirmed:** 14 métropoles vs. dozens of large communautés d'agglomération.
- **Data accessible:** Sirene, DGFiP, DVF.
- **Concern:** Very few treated units (14 métropoles). Likely underpowered. Also, métropoles are systematically the largest cities — selection on observables is challenging.
- **DiD feasibility:** Marginal. Only 14 treated clusters → need RI/wild bootstrap. May fail the ≥20 treated units gate.
