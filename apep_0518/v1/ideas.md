# Research Ideas

## Idea 1: Does Place-Based Policy Create or Relocate? Evidence from France's Neighborhood Redesignation

**Policy:** In 2014, France replaced 751 Zones Urbaines Sensibles (ZUS) with 1,514 Quartiers Prioritaires de la Politique de la Ville (QPV). The redesignation used an entirely new methodology (grid-based low-income concentration vs. composite socioeconomic indicators). Some former ZUS neighborhoods lost their priority status (no QPV overlap), others transitioned to QPV, and entirely new neighborhoods gained QPV designation. The reform took effect January 1, 2015.

**Outcome:** Firm creation and destruction via SIRENE establishment data (geocoded, historical since 1973). Secondary: property transaction values via DVF (2020-2025 geocoded; 2014-2019 via archived data). Both are freely available on data.gouv.fr.

**Identification:** Panel DiD comparing neighborhoods that lost ZUS status (treatment) vs. neighborhoods that transitioned ZUS→QPV (control). Both groups were previously treated, ensuring pre-treatment comparability. SIRENE provides 5+ pre-treatment years (2010-2014) for parallel trends. For displacement testing: compare firm creation gains in newly designated QPV neighborhoods against losses in former ZUS neighborhoods, testing whether place-based policy creates net new activity or merely relocates it.

**Why it's novel:** Existing French enterprise zone literature (Gobillon et al. 2012 JPubE; Mayer et al. 2017 JEG; Charnoz 2012 RSUE) studies the effects of GAINING zone status. No causal study examines what happens when neighborhoods LOSE priority designation. The 2014 QPV redesignation provides the first large-scale natural experiment of priority status removal. Moreover, Mayer et al. found ~2/3 of ZFU firm creation was displacement — this paper directly tests the reverse.

**Feasibility check:** Confirmed: QPV and ZUS shapefiles both available on data.gouv.fr (sig.ville.gouv.fr); SIRENE bulk parquet updated monthly; DVF geocoded available; overlap computation via spatial join is straightforward in R (sf package). ~300+ neighborhoods lost ZUS status, well above DiD minimums. 100 ZFU neighborhoods can be excluded or analyzed separately to control for tax exemption confounds.

---

## Idea 2: Do Social Housing Mandates Lower Property Values? Evidence from France's SRU Quota Increase

**Policy:** The 2013 Duflot Law raised social housing quotas from 20% to 25% for communes with ≥3,500 inhabitants (≥1,500 in Île-de-France) in urban agglomerations of ≥50,000. Communes between 20-25% social housing became newly non-compliant overnight, facing escalating financial penalties.

**Outcome:** Property transaction values via DVF (need pre-2013 data). Social housing construction via RPLS (Répertoire des Logements Locatifs des Bailleurs Sociaux, available since 2011).

**Identification:** DiD comparing communes newly made non-compliant (20-25% social housing in 2013) vs. always-compliant communes (>25%). Pre-trends in RPLS and property values before 2013 reform.

**Why it's novel:** While Maaoui (2021, Housing Studies) and Chapelle/Gobillon/Vignolles (CEPR DP17535) studied social housing production effects, no paper explicitly estimates property price capitalization of the quota increase. Pedrotti (NYU JMP) uses a structural model but focuses on prefect enforcement discretion, not price effects.

**Feasibility check:** DVF only starts 2014 (post-treatment) — pre-treatment property data requires archival notarial indices, limiting the design. RPLS available from 2011. ~400 communes were between 20-25% social housing in 2013 (treatment group). Moderate concern about novelty given 3 existing papers.

---

## Idea 3: Does Losing Rural Revitalization Status Deter Firm Creation? Evidence from France's 2017 ZRR Reclassification

**Policy:** France's Zones de Revitalisation Rurale (ZRR) provide tax exemptions to firms in designated rural communes. The 2015 decree (effective 2017) reclassified thousands of communes based on updated population and income criteria. Some communes lost ZRR status and its associated tax breaks.

**Outcome:** Firm creation via SIRENE. Local employment via INSEE BDM commune-level indicators.

**Identification:** DiD comparing communes that lost ZRR status in 2017 vs. those that retained it, with pre-trends from 2012-2016. The reclassification was formula-based (population density × median income), reducing endogeneity concerns.

**Why it's novel:** No causal study of ZRR reclassification effects exists. The rural enterprise zone literature is thin compared to urban enterprise zones.

**Feasibility check:** ZRR commune lists available on data.gouv.fr. Need to verify the exact number of communes that lost status in the 2017 reclassification — could be several hundred. SIRENE data fully available. Risk: rural communes have few firm creation events, potentially underpowered.

---

## Idea 4: Commune Nouvelle Mergers and Local Public Finance — Evidence from France's 2015 Municipal Consolidation Law

**Policy:** France's 2015 "Commune Nouvelle" law incentivized voluntary municipal mergers through fiscal bonuses (guaranteed DGF for 3 years, population-bracket upgrades). Over 2,500 communes merged into ~770 new entities between 2016-2019, with staggered adoption.

**Outcome:** Local public finance (DGF, local tax rates, spending per capita) via DGCL/Ministry of Interior. Property values via DVF. Firm creation via SIRENE.

**Identification:** DiD comparing merged communes vs. matched non-merged communes (propensity score matching on pre-treatment characteristics). Staggered adoption across years provides event-study variation.

**Why it's novel:** French municipal mergers are understudied in English-language economics. Nordic and Japanese merger literature exists (Blom-Hansen et al. 2016, Nakazawa 2016) but French institutional context is distinctive (voluntary, incentivized).

**Feasibility check:** Commune Nouvelle lists available from DGCL. SIRENE and DVF available. Main risk: self-selection into merging is strong (fiscal incentive × political willingness), threatening parallel trends even with matching.

---

## Idea 5: Business Tax Abolition and Firm Location — Evidence from France's CVAE Phase-Out

**Policy:** France is phasing out the CVAE (Cotisation sur la Valeur Ajoutée des Entreprises), a local business value-added tax: rate halved in 2023, further reduced in 2024, full abolition planned for 2027. The CVAE was paid by firms with turnover >€500K, with revenue flowing to local governments.

**Outcome:** Firm creation and relocation via SIRENE. Local government fiscal response (tax substitution) via DGCL data.

**Identification:** Continuous-treatment DiD exploiting differential commune exposure to CVAE revenue (communes with high CVAE dependence = more treated). Alternatively, firm-level RDD at the €500K turnover threshold.

**Why it's novel:** The CVAE phase-out is one of France's largest business tax reforms (~€8B annual). No causal study exists yet.

**Feasibility check:** CVAE revenue by commune may be available from DGCL/DGFIP. SIRENE available. Main risk: only 2-3 years of post-treatment data (2023-2025) limits power. National policy without geographic stagger means reliance on exposure-based DiD, which faces shift-share credibility concerns.
