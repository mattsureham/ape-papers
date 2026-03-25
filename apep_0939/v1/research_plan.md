# Research Plan: The Employment Costs of Seismicity Regulation

## Research Question

Did Oklahoma's geographically targeted wastewater injection volume caps (2015-2017) reduce local employment in oil-and-gas support services, and did these losses spill over to non-extractive industries?

## Context and Motivation

Oklahoma experienced a dramatic surge in induced seismicity from 2009-2015, driven by high-volume wastewater injection into the Arbuckle formation. The state went from 2 M3+ earthquakes per year (2009) to 886 (2015). The Oklahoma Corporation Commission (OCC) responded with 33 geographically targeted directives between November 2015 and February 2017, mandating 40% reductions in injection volumes across three areas:

- **OWRA** (Oklahoma Western Reduction Area): ~234 wells, November 2015
- **OCRA** (Oklahoma Central Reduction Area): ~266 wells, February-March 2016
- **AOI** (Area of Interest): ~38 high-volume wells, February 2017

This created county-level variation in regulatory exposure: 20 counties had Arbuckle disposal wells subject to volume caps; 57 did not.

## Identification Strategy

**Staggered spatial DiD** using Callaway-Sant'Anna (2021):

- **Treatment intensity**: Pre-directive injection volume per county (continuous) or binary (has regulated wells vs. does not)
- **Timing**: Three staggered cohorts — Nov 2015, Feb/Mar 2016, Feb 2017
- **Unit**: County-quarter
- **Estimator**: Callaway-Sant'Anna with not-yet-treated as controls

**Key threat — oil price crash**: Oil prices collapsed from $100/bbl (June 2014) to $26/bbl (February 2016). This affects ALL Oklahoma counties, not just regulated ones. Time FEs absorb aggregate oil price effects. The identifying variation is *differential* employment decline in regulated vs. unregulated counties, conditional on time effects.

**Mechanism tests**:
1. NAICS 213 (Support Activities for Mining) should decline differentially in regulated counties
2. NAICS 211 (Extraction) should be less affected (extraction wells not regulated, only disposal)
3. Non-oil industries test local multiplier spillovers

## Expected Effects and Mechanisms

- **Primary**: Negative employment effect in NAICS 213 (injection well operators, well services)
- **Secondary**: Possible negative spillover to local services/retail via reduced income
- **Magnitude prior**: 40% volume reduction → proportional reduction in disposal well operations. Oklahoma NAICS 213 employed ~30,000 statewide (2015). Regulated counties held a large share.

## Primary Specification

$$Y_{ct} = \alpha_c + \gamma_t + \beta \cdot Treatment_{ct} + \varepsilon_{ct}$$

Where $Y_{ct}$ is log employment in county $c$, quarter $t$. $Treatment_{ct}$ = 1 after county's first directive date if county has regulated wells.

CS-DiD group-time ATTs aggregated to event-study and overall effects.

## Data Sources

1. **BLS QCEW** (via API): County-quarter employment by NAICS sector, all 77 Oklahoma counties, 2012-2020
2. **Census QWI** (via API): County-quarter hires, separations, earnings by NAICS, 2012-2020
3. **OCC Form 1012D**: Daily well-level injection volumes (for first-stage and treatment mapping)
4. **USGS Earthquake Catalog** (via API): M3+ Oklahoma earthquakes, 2010-2023 (for context/mechanism)
5. **FHFA County HPI** (via API): House price index for wealth channel

## Robustness Checks

1. Event-study pre-trends (8+ pre-quarters for earliest cohort)
2. Placebo: non-oil industries (NAICS 44-45 retail, 72 accommodation) as pseudo-treatment
3. Leave-one-out by county
4. Alternative treatment definitions (binary vs. continuous injection volume)
5. Wild cluster bootstrap (20 treated clusters is borderline — supplement with WCB)
6. HonestDiD sensitivity for parallel trends violations

## Risk Assessment

- **Oil price confounder**: Mitigated by time FEs and within-state variation, but differential oil exposure across counties could correlate with injection regulation exposure. Will test by controlling for pre-period extraction employment share.
- **Small number of treated counties (20)**: Borderline for cluster-robust inference. Wild cluster bootstrap essential.
- **Data granularity**: County-quarter is moderate. Cannot observe firm-level outcomes from public QCEW/QWI.
