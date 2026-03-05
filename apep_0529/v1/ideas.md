# Research Ideas

## Idea 1: Scale Mismatch — National Consensus vs Local Conflict on French Low-Emission Zones (ZFE)

**Policy:** Zones a Faibles Emissions-mobilite (ZFE-m), legislated nationally via LOM 2019 and Loi Climat et Resilience 2021, implemented locally in 43 agglomerations with staggered timing (July 2019 - January 2025). Treatment intensity varies by air-quality exceedance classification (2 "ZFE effectifs" vs 10 "vigilance with ZFE" vs 30 "new vigilance").

**Outcome:** Four primary indices of political divisiveness measured at two levels:
- *National:* (1) Party-line polarization in Assemblee nationale roll-call votes on ZFE/climate-transport legislation (Rice index across party groups); (2) Rhetorical polarization in debate transcripts (cross-party sentiment divergence on a fixed climate-policy dictionary).
- *Local:* (3) Electoral polarization in constituencies overlapping ZFE areas (effective number of parties, vote-share dispersion); (4) Anti-restriction party vote shares (RN + Reconquete) and green party (EELV/Les Ecologistes) vote shares in legislative and municipal elections, before vs after ZFE.

**Identification:** Event-study / staggered DiD comparing electoral polarization and vote shares in communes affected by ZFE vs. control communes, using externally mandated ZFE timing from air-quality exceedance rules as treatment assignment. Pre-2019 air quality levels (NO2 annual averages from Geodair) determined which cities were mandated early vs late. Spillback test: MPs from high-ZFE-exposure constituencies deviate from party lines on subsequent climate votes.

**Why it's novel:** Climate policy political economy literature focuses on national-level voting or cross-country comparisons. The scale-mismatch hypothesis — that nationally consensual policy becomes locally divisive when implementation costs are salient — is discussed qualitatively but never quantified with comparable indices across governance levels. France's ZFE offers a unique lab: same policy, national legislation, local implementation, staggered timing, detailed political data at both levels.

**Feasibility check:**
- Roll-call votes: JSON from data.assemblee-nationale.fr, no auth, MP-level (CONFIRMED)
- Debate transcripts: XML from data.assemblee-nationale.fr, no auth (CONFIRMED)
- Election results: CSV/Parquet from data.gouv.fr, bureau de vote level, 2002-2024 (CONFIRMED)
- Air quality: Geodair API, station-level NO2 annual averages (free registration required) (CONFIRMED)
- ZFE boundaries: GeoJSON from transport.data.gouv.fr (CONFIRMED)
- Vehicle fleet by Crit'Air category: SDES Excel files (CONFIRMED)
- ~25 ZFEs with pre-2024 implementation dates, 5+ pre-election periods

## Idea 2: Does the Green Backlash Travel Upward? Local ZFE Exposure and National Climate Votes

**Policy:** Same ZFE setting, but narrower scope: focus exclusively on the spillback channel.

**Outcome:** MP-level deviation from party line on national roll-call votes related to climate/transport, as a function of ZFE intensity in their constituency.

**Identification:** Two-way FE (MP x vote) with constituency ZFE exposure interacted with post-implementation indicator. Exploits within-MP variation over time as their constituency gets ZFE exposure.

**Why it's novel:** Tests a specific political economy prediction: local policy costs create electoral pressure that changes national legislative behavior. Cleaner than the full scale-mismatch paper but narrower contribution.

**Feasibility check:** Same data as Idea 1 (roll-call + elections + ZFE boundaries). Smaller scope = faster execution.

## Idea 3: Car Restrictions and the Rise of Anti-Green Voting — Evidence from French ZFEs

**Policy:** Same ZFE, but focused purely on local electoral outcomes.

**Outcome:** Anti-green party vote shares (RN, Reconquete) and green party vote shares (EELV) in legislative elections 2017-2024, at commune level within vs outside ZFE perimeters.

**Identification:** Spatial DiD: communes inside ZFE boundary vs. just outside, before vs after ZFE implementation. Can use GeoJSON boundaries for precise treatment assignment.

**Why it's novel:** Clean local political economy of environmental regulation. No national component. Literature on "green backlash" is mostly about energy transition; vehicle restrictions are understudied.

**Feasibility check:** Election data at bureau de vote level + ZFE GeoJSON boundaries allow precise spatial matching. ~25 ZFE cities, elections in 2017, 2022, 2024 (legislatives) and 2020 (municipales).
