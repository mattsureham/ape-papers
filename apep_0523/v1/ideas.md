# Research Ideas

## Idea 1: Does Taxing Vacant Housing Put Homes on the Market? Evidence from France's 2023 TLV Expansion

**Policy:** France's *Taxe sur les Logements Vacants* (TLV) — a national tax on properties vacant for over one year in designated "zones tendues" (tight housing markets). The *Décret n° 2023-822* of August 25, 2023, expanded TLV coverage from 1,138 communes to 3,693 communes, adding ~2,555 communes overnight. The newly covered communes fall into two categories: "zone tendue" (330 communes) and "zone touristique et tendue" (2,260 communes). Tax rates are 17% of rental value in year one of vacancy, 34% from year two onward (increased from 12.5%/25% by the 2023 loi de finances). A further decree in December 2025 expanded coverage again.

**Outcome:** Demandes de Valeurs Foncières (DVF) — the universe of property transactions in metropolitan France, published as geocoded open data. Variables include: transaction price, date, property type, surface area, commune code, latitude/longitude. Available 2020–2025 (~5M+ transactions per year). Supplemented with Sirene establishment data on real estate/construction firm dynamics.

**Identification:** Staggered difference-in-differences exploiting the August 2023 expansion. Treatment group: ~2,555 communes newly subject to TLV. Control group: ~31,000 communes that remain outside TLV zones. Placebo group: ~1,100 communes already subject to TLV since 2013 (no new treatment in 2023). Design uses Callaway-Sant'Anna (2021) estimator with commune-level clustering. Pre-period: 2020 Q1–2023 Q2 (~14 quarters). Post-period: 2024 Q1–2025 Q2+ (~6+ quarters).

**Why it's novel:** Vacancy taxes are a live global policy debate (Vancouver 2017, Melbourne 2018, Barcelona 2024, UK discussion), yet there is no rigorous causal evaluation using universe transaction data with quasi-experimental design. Bono & Trannoy (2012) studied the original TLV with limited data and design. This paper provides the first credible causal estimate by exploiting the sharp 2023 expansion, the universe of transactions (DVF), and rich within-France variation.

**Key mechanisms to decompose:**
1. *Supply release:* Does TLV push vacant properties onto the sale/rental market? (Transaction volume effect)
2. *Price capitalization:* Does TLV reduce sale prices in treated communes? (Seller concession due to holding costs)
3. *Composition shift:* Are transacted properties in treated communes different post-TLV? (Size, type, quality)
4. *Construction response:* Does the tax stimulus encourage renovation/new construction? (Sirene firm creation)

**Built-in placebos:**
- Already-treated communes (subject since 2013): should show no effect from 2023 decree
- "Zone touristique" vs. "zone tendue" heterogeneity: tourist areas may have different vacancy drivers (second homes vs. speculative vacancy)
- 35 communes that *lost* TLV status in 2023: reverse treatment

**Feasibility check:** CONFIRMED. DVF bulk data tested (2020–2025, dept-level CSV.gz files, ~80K rows/year for Paris alone). TLV commune zoning CSV downloaded from data.gouv.fr with exact 2013/2023 status for all 34,875 communes. Sirene establishment Parquet available (2.2GB). All data is freely accessible without API keys.

---

## Idea 2: Low Emission Zones and Urban Property Markets: Spatial Evidence from France's ZFE Expansion

**Policy:** France's *Zones à Faibles Émissions* (ZFE) restrict older, polluting vehicles from designated urban areas based on Crit'Air sticker categories. The Loi d'Orientation des Mobilités (2019) required ZFEs in 11 metro areas; the Loi Climat (2021) extended the mandate to 43 agglomerations by 2025. Implementation is staggered: Paris (2015/2017), Lyon (2020), Strasbourg (2021), plus 25+ new cities in January 2025 with varying stringency.

**Outcome:** DVF for property transaction prices and volumes. Geocoded transactions allow precise assignment of properties to inside/outside ZFE boundaries.

**Identification:** Spatial DiD combining (1) temporal staggering across cities and (2) within-city boundary discontinuity at ZFE perimeters. Triple-difference: city × inside/outside ZFE × pre/post implementation. Properties inside ZFE boundaries experience both air quality improvement (amenity) and vehicle access restriction (cost).

**Why it's novel:** LEZs have been studied in London (Sahlqvist et al.), Berlin (Wolff 2014), and Stockholm, but almost entirely on air quality outcomes. This paper asks: do LEZs capitalize into property values, and is there evidence of "green gentrification" — price appreciation inside ZFEs accompanied by sorting of lower-income residents to periphery?

**Feasibility check:** DVF 2020–2025 confirmed, geocoded. ZFE boundaries likely available as geographic data on ecologie.gouv.fr/data.gouv.fr (needs verification). Concern: only ~12 cities implemented before Jan 2025, so temporal variation is limited. Spatial boundary design compensates. DiD gate: ~12 treated cities pre-2025 is below the 20-unit threshold; relies on within-city spatial variation for power.

---

## Idea 3: The Price of an Energy Label: How France's Rental Ban Announcements Capitalized into Property Values

**Policy:** The Loi Climat et Résilience (August 2021) announced staggered bans on renting properties by DPE (Diagnostic de Performance Énergétique) rating: rent freeze for G-rated from Jan 2023, rental ban for G from Jan 2025, F from Jan 2028, E from Jan 2034. This is a "scarlet letter" that permanently devalues poorly-rated housing stock.

**Outcome:** DVF transaction prices crossed with commune-level DPE exposure from ADEME's DPE database (publicly available). Treatment intensity measured as commune-level share of properties rated G, F, or E.

**Identification:** Shift-share DiD: national announcement (August 2021) × commune-level exposure (share of poor DPE stock). Communes with more G-rated housing face greater treatment intensity. Event study around the August 2021 announcement and the January 2023/2025 implementation dates.

**Why it's novel:** Energy performance labeling effects have been studied (Brounen & Kok 2011, Frondel et al. 2019), but never in a context where labels carry a *regulatory ban* on rental use. This converts the DPE from information to regulation, creating much stronger capitalization incentives.

**Feasibility check:** DVF 2020–2025 confirmed. ADEME DPE database available as open data (needs verification of commune-level aggregates). Concern: the shift-share design requires strong instruments diagnostics (Goldsmith-Pinkham et al. 2020). The shares (DPE composition) might be endogenous to housing market conditions.

---

## Idea 4: Did Removing France's Famous Growth Barrier Work? Firm Size Dynamics After Loi PACTE

**Policy:** The Loi PACTE (May 2019) reformed France's notoriously costly employee-count thresholds. Before PACTE, crossing 50 employees triggered mandatory works councils (CSE), profit-sharing obligations, and additional taxes. This caused well-documented "bunching" at 49 employees (Garicano, Lelarge, Van Reenen 2016, ReStud). PACTE changed the trigger: thresholds now apply only if exceeded for 5 consecutive calendar years, effectively giving firms a grace period to grow.

**Outcome:** Sirene establishment data — universe of French firms with employee size brackets (trancheEffectifs: 20-49, 50-99, etc.), creation dates, cessation dates, sector codes (NAF). Supplemented with INSEE BDM aggregate employment statistics by firm size.

**Identification:** DiD around the May 2019 reform, comparing the rate of firms transitioning from the 20-49 bracket to the 50-99 bracket before vs. after PACTE. Triple-diff: transition rates for the 20-49→50-99 boundary (treated) vs. the 10-19→20-49 boundary (placebo — no major threshold). Event study with pre-trends validation.

**Why it's novel:** Garicano et al. (2016) documented the bunching problem; several papers have discussed the PACTE reform theoretically. No rigorous causal evaluation exists using universe firm-level data to test whether the reform actually changed firm growth dynamics. If bunching persists despite the grace period, it suggests regulatory salience rather than compliance costs drive firm behavior.

**Feasibility check:** Sirene Parquet available (2.2GB, updated monthly). Size brackets are categorical (not exact counts), limiting precision. But bracket-transition analysis is feasible. Pre-period: several years of Sirene data pre-2019. Post-period: 6+ years. The 5-year grace period means full effects may emerge only after 2024 (firms that crossed 50 in 2019 would face obligations in 2024).

---

## Idea 5: Rent Control Returns: The Staggered Expansion of France's Encadrement des Loyers

**Policy:** France's *encadrement des loyers* (rent control) was first implemented in Paris (August 2015), struck down by court (November 2017), reinstated (July 2019), then expanded to Lille (March 2020), Lyon/Villeurbanne (November 2021), Montpellier (July 2022), Bordeaux (July 2022), and several more cities in 2023-2024. The on-off-on pattern in Paris plus staggered city adoption creates rich temporal variation.

**Outcome:** DVF property transaction prices in controlled vs. uncontrolled cities. Also: Sirene for real estate/construction firm dynamics, potentially rental listing data.

**Identification:** Staggered DiD across ~10 adopting cities, with Paris's on-off-on history as a natural reversal experiment. Control cities are comparable metro areas that did not adopt rent control.

**Why it's novel:** Rich literature on rent control (Diamond et al. 2019 on San Francisco; Autor et al. 2014 on Cambridge) but little rigorous work on France's unique regime, and no study exploits the Paris reversal. The temporary removal in Paris (2017-2019) provides a natural "de-control" experiment that is exceptionally rare in the literature.

**Feasibility check:** DVF 2020–2025 covers the reinstatement and expansions. Paris's initial adoption (2015) and removal (2017) require pre-2020 DVF data, which would need DVF+ from CEREMA. The number of treated cities (~10) is below the 20-unit DiD threshold but is within the range of synthetic control / few-cluster designs with RI inference. The policy is well-documented with precise implementation dates.
