# Research Ideas

## Idea 1: Does Candidate Wealth Buy Development? Close-Election Evidence from Indian State Assemblies

**Policy:** India's mandatory candidate affidavit disclosure (Supreme Court order 2003; effective from 2004 elections) requires all candidates to declare total assets, liabilities, movable/immovable property, criminal cases, and education. This creates a uniquely precise measure of politician wealth.

**Outcome:** Constituency-level economic activity (DMSP/VIIRS nightlights, 2001–2021), MGNREGA spending (nrega.nic.in, 2006+), educational infrastructure (UDISE+), and public goods provision.

**Identification:** Sharp RDD at the vote margin = 0 threshold. For each constituency-election, identify the top-2 candidates, determine who is wealthier (total assets), and use the wealthier candidate's vote margin as the running variable. Positive margin = wealthier candidate won; negative = lost. Standard close-election design as in Prakash et al. (2019, JDE) and Asher & Novosad (2017, AEJ:Applied).

**Why it's novel:** The RDD literature on Indian elections has studied the effects of politician **criminality** (Prakash et al. 2019 JDE), **education** (Jain et al. 2023 JCE), and **party alignment** (Asher & Novosad 2017 AEJ:Applied) — but **never wealth as the main treatment variable**. Wealth appears only as a heterogeneity dimension in existing work. This is a first-order gap: wealth is the most precisely measured politician characteristic (continuous, auditable) and connects to fundamental questions about elite capture, political selection, and democratic accountability.

**Theoretical ambiguity makes this genuinely interesting:**
- **Resource channel (+):** Wealthy politicians bring connections, attract private investment, self-finance visible projects
- **Elite capture channel (–):** Wealthy politicians redirect spending to benefit their own land/businesses, are less responsive to poor voters
- **Corruption channel (?):** May need to steal less (already rich) OR steal more (better at extraction)
- Mechanism decomposition: visible infrastructure vs invisible human capital spending; elite-benefiting vs mass-benefiting public goods

**Feasibility check:**
- *Variation:* Asset variation is enormous — candidates range from Rs. 50,000 to Rs. 500+ crore
- *Data:* Lok Dhaba (TCPD) provides election results CSV for all state assemblies (1962+); MyNeta.info provides affidavit data (assets, criminal cases) for all candidates since 2004; multiple GitHub scrapers exist; constituency boundary shapefiles from DataMeet; nightlights from NOAA VIIRS/DMSP
- *Sample:* ~20,000+ constituency-elections across 28 states (2004–2024), ~3,000–4,000 near cutoff
- *Not overstudied:* No existing paper uses wealth as main RDD treatment. Gap confirmed via Google Scholar and SSRN search
- *Published precedent:* Fisman, Schulz & Vig (2014 JPE) used the exact same ADR affidavit data for a close-election RDD — validates data quality for top journals

**Built-in placebos:**
1. Elections between similar-wealth candidates (no wealth discontinuity expected)
2. Placebo outcomes unrelated to politician behavior (e.g., rainfall, temperature)
3. Pre-election nightlights trends (should be parallel)

---

## Idea 2: Banking the Unbanked — Financial Inclusion Mandates and Village Development

**Policy:** RBI's Financial Inclusion Plan (FIP) mandated banking access for all habitations with population ≥2,000 by March 2012 (extended to ≥1,000 by 2015). Multi-threshold design.

**Outcome:** Bank branch presence, nightlights, Census village amenities, MGNREGA uptake.

**Identification:** Sharp RDD at population 2,000 threshold (first phase) and 1,000 (second phase). Running variable is habitation population from Census 2001 (pre-treatment). Multi-cutoff provides internal replication.

**Why it's novel:** First village-level RDD of India's banking inclusion mandate. Extends Burgess & Pande (2005) with sharp identification instead of state-level variation. Built-in placebo: villages already banked before the mandate.

**Feasibility check:**
- *Variation:* Clear population thresholds
- *Data:* Requires SHRUG download (bank branches, nightlights, Census) — not currently available locally; need to download from devdatalab.org portal
- *Sample:* ~640,000 villages, many near thresholds
- *Risk:* SHRUG data not yet downloaded; unclear whether threshold was sharply enforced or a guideline

---

## Idea 3: Reservation and Resource Allocation — Multi-Threshold Evidence from India's 2008 Delimitation

**Policy:** India's 2008 delimitation reassigned constituency boundaries and reservation status (SC/ST) based on 2001 Census SC/ST population shares. The specific constituencies reserved were ranked by SC/ST concentration, creating a sharp cutoff.

**Outcome:** Nightlights, UDISE+ school metrics, public goods provision.

**Identification:** RDD at the SC/ST population share threshold determining reservation assignment. Multi-cutoff (SC and ST separate thresholds). Can study effects of GAINING vs LOSING reservation in the 2008 reassignment.

**Why it's novel:** Updates Pande (2003) and Chin & Prakash (2011) with the 2008 delimitation event and modern data. Multi-cutoff design provides internal replication.

**Feasibility check:**
- *Variation:* Clean institutional threshold
- *Data:* TCPD elections + constituency SC/ST shares + nightlights
- *Sample:* ~4,120 state assembly constituencies
- *Risk:* Similar to existing literature — must clearly differentiate contribution. Need constituency-level SC/ST population share data, which may require digitization

---

## Idea 4: Does Urban Classification Matter? Population Thresholds and the Governance of India's Census Towns

**Policy:** India's Census classification system identifies "Census Towns" — settlements that meet urban criteria (population 5,000+, density >400/sq km, >75% non-agricultural male workers) but are governed as rural panchayats. These 3,892 settlements (2011) receive neither urban infrastructure funds nor urban governance.

**Outcome:** Nightlights, infrastructure (roads, drainage, water supply), economic activity.

**Identification:** RDD at the population 5,000 threshold (and other criteria). Estimates the effect of urban classification status on development.

**Why it's novel:** The "missing middle" between rural and urban governance is a major policy issue. No existing RDD studies this threshold.

**Feasibility check:**
- *Variation:* Population threshold exists but assignment also depends on density and workforce composition — fuzzy, multi-dimensional
- *Data:* SHRUG has town data + Census; nightlights available
- *Sample:* ~3,892 Census Towns vs villages near threshold
- *Risk:* Multiple assignment criteria make this a complex fuzzy RDD; requires SHRUG
