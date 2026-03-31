# Research Plan: Defect Queue Congestion — Investigation Workload and Auto Safety Recall Delays at NHTSA

## Research Question

Does NHTSA investigation congestion — measured by the volume of concurrent open safety investigations — causally delay vehicle recall issuance, and what is the injury cost of these delays?

## Institutional Background

The National Highway Traffic Safety Administration's Office of Defects Investigation (ODI) employs approximately 90 investigators responsible for monitoring safety across 280+ million registered vehicles. Investigations follow a structured pipeline: consumer complaints trigger a Preliminary Evaluation (PE), which may escalate to an Engineering Analysis (EA), which may result in a manufacturer recall. A 2023 DOT Inspector General audit found that ODI fails timeliness goals across all investigation types. High-profile cases (Takata airbags, Tesla Autopilot) consume disproportionate bandwidth, backing up the pipeline for other defects.

## Identification Strategy

**Instrument:** Volume of concurrent open NHTSA investigations at the time a new complaint cluster emerges. The fixed investigator pool (~90) creates a bandwidth bottleneck: when more investigations are open simultaneously, each receives less examiner time.

**First stage:** More concurrent investigations → longer PE-to-EA-to-recall pipeline duration for a given investigation.

**Second stage:** Delayed investigation → delayed recall → more consumer injuries from known defects during the delay window.

**Exclusion restriction:** Queue congestion from OTHER vehicle makes/components (excluding own-manufacturer and own-component investigations) affects the focal investigation only through the examiner bandwidth channel, conditional on own-defect severity indicators (complaint volume, crash/fire/injury/death flags).

**Threats and responses:**
1. *Correlated safety shocks:* Queue length could rise during periods of generally poor vehicle safety. We exclude own-manufacturer and own-component investigations from the instrument and control for calendar-year FEs and defect severity.
2. *Strategic manufacturer behavior:* Manufacturers might delay cooperation during busy regulatory periods. We control for manufacturer size and historical recall propensity.
3. *Complaint composition:* Busy periods might attract different complaint types. We control for defect component category and complaint severity indicators.

## Expected Effects

- **First stage:** 10 additional concurrent investigations → 2-4 month increase in PE-to-recall duration (F-stat target: >10)
- **Main effect:** Each month of investigation delay → X additional injuries/complaints per 100,000 affected vehicles
- **Direction:** Positive (more congestion → longer delays → more injuries)
- **Mechanism:** Fixed regulatory capacity creates an implicit triage system where low-profile defects wait while high-profile cases consume bandwidth

## Primary Specification

**Reduced form (OLS):**
$$\text{Duration}_{i} = \alpha + \beta \cdot \text{ConcurrentInv}_{i} + X_i'\gamma + \delta_t + \epsilon_i$$

**IV (2SLS):**
- First stage: $\text{Duration}_{i} = \pi_0 + \pi_1 \cdot \text{OtherQueue}_{i} + X_i'\phi + \delta_t + \nu_i$
- Second stage: $\text{Injuries}_{i} = \alpha + \beta \cdot \widehat{\text{Duration}}_{i} + X_i'\gamma + \delta_t + \epsilon_i$

Where:
- $i$ indexes investigations
- $\text{OtherQueue}_{i}$ = count of concurrent open investigations excluding own-manufacturer/component
- $X_i$ = controls: complaint count, crash/fire/injury/death flags, component category, manufacturer size
- $\delta_t$ = year-quarter fixed effects

**Clustering:** Standard errors clustered by manufacturer (primary) and by year-quarter (robustness).

## Data Sources

All data from NHTSA static flat files (no authentication required):

1. **Investigations:** `static.nhtsa.gov` flat files — 5,330 unique investigations with open/close dates, investigation type (PE/EA), component, manufacturer, outcomes
2. **Complaints:** `static.nhtsa.gov` flat files — 2.19M complaints with crash/fire/injury/death flags, dates, vehicle info
3. **Recalls:** NHTSA Recalls API — recall dates, affected vehicles, linked investigations
4. **Vehicle registrations:** For normalization (IHS Markit or FHWA estimates)

## Fetch Strategy

1. Download NHTSA flat files from `static.nhtsa.gov/nhtsa/downloads/`
2. Download recalls via NHTSA API (`api.nhtsa.gov`)
3. Link investigations to recalls via NHTSA Campaign Number
4. Construct concurrent investigation count for each investigation's open date
5. Merge complaint-level severity indicators to investigation level
