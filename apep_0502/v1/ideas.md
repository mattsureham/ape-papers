# Research Ideas

## Idea 1: Clean Air, Dirty Power? NAAQS Nonattainment and the Clean Energy Transition

**Policy:** National Ambient Air Quality Standards (NAAQS) nonattainment designations under the Clean Air Act. Counties exceeding NAAQS thresholds for PM2.5 (annual: 15→12→9 μg/m³ across 1997/2012/2024 revisions) and ozone (8-hr: 80→75→70 ppb across 1997/2008/2015 revisions) are designated "nonattainment," triggering stringent New Source Review (NSR) permitting requirements for new and modified major stationary sources.

**Outcome:** Energy infrastructure investment decisions — new power plant construction, capacity additions, retirement timing, and fuel mix shifts (fossil vs renewable). Data from EIA Form 860 (generator inventory with county location, fuel type, capacity, operating/retirement dates) and EIA Form 923 (generation and fuel consumption). Supplemented with EPA AQS monitor data for the running variable and EPA Green Book for designation status.

**Identification:** Multi-cutoff sharp RDD using county-level PM2.5/ozone design values relative to NAAQS standards. Counties with design values just above the standard are designated nonattainment (facing NSR/LAER/offset requirements for new fossil plants); counties just below remain attainment (facing less stringent PSD/BACT). The running variable (ambient air quality) is determined by aggregate emissions from many sources, making individual facility manipulation implausible. Multiple standard revisions (PM2.5: 1997, 2012, 2024; Ozone: 1997, 2008, 2015) create internal replication across cutoffs.

**Why it's novel:** The entire nonattainment causal literature (Greenstone 2002 JPE; Walker 2013 QJE; Curtis 2018 REStat; Singer & Shapiro 2025 AEJ) studies manufacturing employment or air quality/housing outcomes. NO ONE has examined effects on energy infrastructure investment. The key mechanism is asymmetric regulatory cost: nonattainment raises costs for fossil plants (LAER + offsets + alternative site analysis) but NOT for renewable generators (zero criteria pollutant emissions = exempt from NSR). This creates a regulatory tilt toward clean energy in dirty-air counties — a "double dividend" where air quality regulation inadvertently accelerates the energy transition.

**Feasibility check:**
- Variation: Multiple NAAQS revisions create county × time variation across dozens of counties per revision (~119 counties affected by 2024 PM2.5 revision alone)
- Data: EIA API confirmed working (generator inventory with county, fuel type, capacity, dates); EPA Green Book and AQS summary data publicly downloadable
- Novelty: Not in APEP list; no published RDD of nonattainment on energy outcomes found in literature search
- Sample size: ~10,000 power plants with county locations, many near nonattainment counties
- Built-in placebo: Renewable projects (zero emissions) should show NO regulatory cost discontinuity at the NAAQS threshold, while fossil plants should show large effects

---

## Idea 2: Does Sunlight Disinfect? Mandatory GHG Reporting and Facility Emissions Behavior

**Policy:** EPA Greenhouse Gas Reporting Program (GHGRP), established 2009 under 40 CFR Part 98. Facilities emitting ≥25,000 metric tons CO2e per year must report detailed emissions to EPA, which publishes the data publicly. Below 25,000 tCO2e, facilities are exempt from reporting. First reporting year: 2010. Covers ~8,000 facilities across 41 industrial categories representing 85-90% of U.S. GHG emissions.

**Outcome:** Subsequent facility-level emissions trajectories (CO2e), technology investments, capacity changes, and facility exit/closure decisions. Data from EPA GHGRP database (facility-level, annual, geocoded, 2010-present via EPA Envirofacts API — confirmed working) and EIA Form 860/923 for power plant-specific outcomes.

**Identification:** RDD using facility-level CO2e emissions relative to the 25,000 tCO2e reporting threshold. For the cleanest design, use pre-GHGRP (2009) emissions from eGRID as the running variable for power plants, making it predetermined relative to the reporting requirement. For non-power-plant facilities, use initial reporting year emissions. Complement with bunching analysis (Kleven-Waseem) and donut RDD to address potential manipulation.

**Why it's novel:** Tomar (2023, Journal of Accounting Research) and Yang, Muller & Liang (2021, NBER WP) both study GHGRP effects using DiD. NO ONE has used RDD at the 25,000 tCO2e threshold. Yang et al. found strategic reallocation (firms shift emissions from reporting to non-reporting plants) — this is both a threat (manipulation) and an opportunity (bunching test as first stage). The time-varying angle — has the treatment effect intensified as ESG/climate activism has grown? — adds a novel dimension.

**Feasibility check:**
- Variation: Sharp threshold at 25,000 tCO2e, 8,000+ reporting facilities
- Data: EPA Envirofacts API confirmed working (facility-level emissions by gas, year, sector, county); eGRID for pre-GHGRP power plant emissions
- Novelty: RDD angle is genuinely new vs existing DiD papers; no published bunching study at this threshold
- Sample size: Thousands of facilities near the threshold across diverse industries
- Risk: Manipulation concern — facilities control their emissions. McCrary test + donut RDD + bunching analysis required. Multi-plant firms may strategically reallocate (Yang et al.)

---

## Idea 3: Cooling Down: Clean Water Act Section 316(b) and Power Plant Survival

**Policy:** EPA's Clean Water Act Section 316(b) rule (finalized 2014, 40 CFR 125 Subpart J). Existing power plants withdrawing ≥2 million gallons per day (MGD) of cooling water must implement "best technology available" (BTA) to reduce impingement and entrainment of aquatic organisms. Plants withdrawing ≥125 MGD must conduct comprehensive entrainment studies. Below 2 MGD, plants are exempt from 316(b) requirements.

**Outcome:** Plant retirement decisions, capacity factor changes, operating cost changes, and local environmental quality (fish populations, water temperature). Data from EIA Form 860 (cooling system type, water source) and EIA Form 923 (generation, water volumes).

**Identification:** RDD using plant-level cooling water withdrawal relative to the 2 MGD threshold. Plants just above must install BTA (modified traveling screens, fish handling systems); plants just below are exempt. The threshold is sharp and externally imposed. Additional analysis at the 125 MGD entrainment study threshold.

**Why it's novel:** The environmental economics literature on power plant water use focuses on thermal pollution and fisheries (Deschênes & Greenstone work on water quality), but the specific causal effect of 316(b) compliance requirements on plant survival and energy infrastructure has not been studied using RDD. The mechanism is straightforward: 316(b) compliance costs (potentially $10M-$100M per plant for cooling tower retrofits) may accelerate retirement of marginal coal plants.

**Feasibility check:**
- Variation: Sharp threshold at 2 MGD and 125 MGD
- Data: EIA Form 860 has cooling system data; EIA Form 923 Schedule 8 has water volumes (may require bulk download rather than API)
- Novelty: Not in APEP list; limited causal evidence on 316(b) effects
- Sample size: Uncertain — need to verify how many thermoelectric plants are near the 2 MGD threshold
- Risk: Water withdrawal volumes may not be consistently reported; threshold may be somewhat fuzzy in practice (measurement error in self-reported water volumes)
