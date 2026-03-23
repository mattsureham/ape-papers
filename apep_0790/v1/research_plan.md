# Research Plan: The Air Quality Cost of Fireworks Deregulation

## Research Question

Does state-level legalization of consumer fireworks increase July 4th PM2.5 concentrations? What is the magnitude of the air quality externality from fireworks deregulation?

## Identification Strategy

**Staggered DiD with within-year differencing.**

The key insight: within each monitor-year, July 4-5 PM2.5 minus a baseline window (June 25-July 2, July 6-10) nets out monitor-specific annual conditions (geography, long-run pollution trends, local industry). The excess PM2.5 on July 4-5 captures holiday-specific pollution, primarily from fireworks. Treatment is the state legalizing consumer fireworks.

**Estimator:** Callaway-Sant'Anna (2021) group-time ATTs, using the within-year excess PM2.5 as the outcome. This handles staggered adoption cleanly.

**Treatment groups:**
- Indiana (2006), Michigan (2011), New Hampshire (2011), Utah (2011), Maine (2012), New York (2014, sparklers only), Georgia (2015), West Virginia (2016), Pennsylvania (2017), New Jersey (2017, sparklers only), Iowa (2017), Delaware (2018), Ohio (2022)

**Control group:** Never-treated states that maintained fireworks restrictions throughout the sample period (e.g., Massachusetts).

## Expected Effects and Mechanisms

**Primary:** Legalization → increased consumer fireworks sales → higher particulate emissions on July 4th. Expected positive effect on excess PM2.5.

**Dose-response:** States legalizing aerial/consumer-grade fireworks (e.g., PA, GA, OH) should show larger effects than sparklers-only states (NY, NJ).

**Mechanisms:**
1. Extensive margin: more households participate in fireworks use
2. Intensive margin: legal access → larger/more fireworks per household
3. Temporal concentration: celebrations shift from organized municipal displays to dispersed private use

## Primary Specification

$$Y_{mt} = \text{ExcessPM2.5}_{mt} = \overline{\text{PM2.5}}_{m,\text{Jul4-5},t} - \overline{\text{PM2.5}}_{m,\text{baseline},t}$$

Where $m$ indexes EPA monitors and $t$ indexes years. Callaway-Sant'Anna ATTs estimated on $Y_{mt}$ with treatment defined by state legalization year.

## Robustness

1. **Placebo holidays:** New Year's Eve, Memorial Day, Labor Day (excess PM2.5 should not change with fireworks legalization)
2. **Placebo dates:** Random July dates (July 12-13, July 18-19) — no spike expected
3. **Weather controls:** Temperature, wind speed, precipitation on July 4
4. **Wildfire smoke:** Drop monitor-years with NOAA HMS smoke plumes over monitor location
5. **Bandwidth sensitivity:** Vary baseline window width (3-day, 5-day, 7-day)
6. **Alternative clustering:** State-level vs monitor-level

## Exposure Alignment

The treatment is state-level fireworks legalization. The affected population is all residents and visitors within the state's borders on July 4th. EPA PM2.5 monitors measure ambient outdoor air quality at fixed locations, capturing the pollution externality experienced by the surrounding population. The exposure alignment is direct: legalization permits consumers to purchase and use fireworks within the state, generating particulate emissions that are measured by monitors in the same state. Monitors in control states provide the counterfactual — what ambient PM2.5 would look like in the treatment window absent legalization. The within-year differencing further sharpens alignment by comparing each monitor to itself on adjacent non-holiday days.

## Data Source and Fetch Strategy

**EPA Air Quality System (AQS) daily data:**
- Parameter: 88101 (PM2.5 FRM/FEM Mass)
- Years: 2003-2023 (gives pre-periods for all treated states)
- Format: Annual CSV zip files from EPA website
- URL pattern: `https://aqs.epa.gov/aqdat/api/rawData?param=88101&bdate=YYYYMMDD&edate=YYYYMMDD&email=...&key=...`
- Alternative: Pre-generated daily CSV files from EPA AQS

**EPA AQS API** (preferred for targeted downloads):
- Register for API key at AQS website
- Daily data by state: `/dailyData/byState?param=88101&bdate=YYYYMMDD&edate=YYYYMMDD&state=XX`
- Will download June-July data for each year 2003-2023

**Monitor metadata:** EPA AQS monitor listing for latitude/longitude, county FIPS, state.
