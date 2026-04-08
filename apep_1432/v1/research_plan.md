# Research Plan: From the Streets to the Checkbooks

## Research Question
Do larger protests cause spikes in local small-dollar campaign contributions? We test whether street mobilization has financial spillovers that reshape fundraising, using rainfall as an instrument for protest attendance.

## Identification Strategy
**Weather IV (Madestam, Shoag, Veuger & Yanagizawa-Drott 2013, QJE).**

- Rainfall on protest day/location reduces attendance but is plausibly exogenous to donation demand
- CCC provides GPS coordinates for 43K+ protest events (2017-2023)
- NOAA ISD provides daily precipitation at weather stations near protest sites
- City-week panel with city FE and week FE
- IV: average precipitation on protest days within city-week cells

Key extension from Madestam et al.: (1) continuous panel of 43K+ heterogeneous events vs single Tea Party event; (2) financial mobilization channel vs electoral outcome; (3) crowd size estimates available for ~57% of events.

## Expected Effects and Mechanisms
- **Primary hypothesis:** Larger protests increase local small-dollar donations (complementarity between street and financial mobilization)
- **Mechanism 1 — Attention:** Protests generate local media coverage, making political causes salient
- **Mechanism 2 — Social pressure:** Seeing neighbors protest creates reciprocity pressure to contribute
- **Mechanism 3 — Information:** Protests signal organizational capacity, reducing donor uncertainty about efficacy
- **Alternative:** Protests may substitute for donations (crowds give time instead of money) — empirically testable

## Primary Specification
```
Donations_{c,w} = beta * ProtestSize_{c,w} + gamma * X_{c,w} + alpha_c + delta_w + epsilon_{c,w}

First stage: ProtestSize_{c,w} = pi * Rainfall_{c,w} + gamma * X_{c,w} + alpha_c + delta_w + nu_{c,w}
```
- Unit: city-week
- Treatment: log(1 + total crowd size) in city c during week w
- Instrument: average precipitation (mm) on protest days in city c during week w
- Outcome: log(1 + count of contributions < $200), log(1 + total $ amount < $200)
- FE: city, week, state x month
- Cluster: city level

## Data Sources
1. **Crowd Counting Consortium (CCC):** Open CSV, 43K+ US protest events 2017-2023, GPS-coded, crowd size estimates for ~57%
2. **FEC Schedule A (individual contributions):** API with bulk download, contributor city/state/zip, amount, date, committee
3. **NOAA Integrated Surface Database (ISD):** Daily precipitation at weather stations, free public access

## Fetch Strategy
1. Download CCC CSV directly
2. Query FEC bulk data API for Schedule A contributions (< $200 threshold for small-dollar)
3. Download NOAA ISD daily precipitation for stations nearest to protest locations
4. Link by city-day, aggregate to city-week panels
