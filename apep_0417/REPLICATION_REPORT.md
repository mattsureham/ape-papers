# Replication Report

**Paper ID:** apep_0417
**Title:** Where Medicaid Goes Dark: A Claims-Based Atlas of Provider Deserts\\ and the Resilience of Supply to Enrollment Shocks
**Replication Date:** 2026-02-20
**Replicator:** Claude Code

---

## Summary

**Classification:** FAILED REPLICATION

**Overall Assessment:**
No scripts executed successfully. Code requires fixes.

### Execution Summary

- **Total Scripts:** 7
- **Successful:** 0
- **Failed:** 7

---

## 1. Computing Environment

- **Platform:** macOS-15.6.1-arm64-arm-64bit-Mach-O
- **Processor:** arm
- **Python Version:** 3.14.2
- **R Version:** R version 4.5.2 (2025-10-31) -- "[Not] Part in a Rumble"

### R Packages
```
> 
>         pkgs <- c("fixest", "rdrobust", "did", "ggplot2", "modelsummary", "haven", "tidyverse")
>         installed <- installed.packages()
>         for (p in pkgs) {
+             if (p %in% rownames(installed)) {
+                 cat(sprintf("%s: %s
+ ", p, installed[p, "Version"]))
+             }
+         }
fixest: 0.13.2
rdrobust: 3.0.0
did: 2.3.0
ggplot2: 4.0.2
modelsummary: 2.5.0
haven: 2.5.5
tidyverse: 2.0.0
>         
>
```

---

## 2. Code Inventory

**R Scripts:** 7
**Python Scripts:** 0
**Main Script:** 00_packages.R

| Script | Language |
|--------|----------|
| `00_packages.R` | R |
| `01_fetch_data.R` | R |
| `02_clean_data.R` | R |
| `03_main_analysis.R` | R |
| `04_robustness.R` | R |
| `05_figures.R` | R |
| `06_tables.R` | R |

---

## 3. Execution Results

| Script | Success | Duration | Exit Code |
|--------|---------|----------|-----------|
| `00_packages.R` | **No** | 2.4s | 1 |
| `01_fetch_data.R` | **No** | 1.6s | 1 |
| `02_clean_data.R` | **No** | 1.6s | 1 |
| `03_main_analysis.R` | **No** | 1.6s | 1 |
| `04_robustness.R` | **No** | 1.6s | 1 |
| `05_figures.R` | **No** | 1.7s | 1 |
| `06_tables.R` | **No** | 1.6s | 1 |

### Errors

#### 00_packages.R

```

Attaching package: ‘arrow’

The following object is masked from ‘package:utils’:

    timestamp


Attaching package: ‘dplyr’

The following objects are masked from ‘package:data.table’:

    between, first, last

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union


Attaching package: ‘lubridate’

The following objects are masked from ‘package:data.table’:

    hour, isoweek, isoyear, mday, minute, month, quarter, second, wday,
    week, yday, year

The following object is masked from ‘package:arrow’:

    duration

The following objects are masked from ‘package:base’:

    date, intersect, setdiff, union

Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘scales’

The following object is masked from ‘package:fixest’:

    pvalue

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal


Attaching package: ‘kableExtra’

The following object is masked from ‘package:dplyr’:

    group_rows

Error: T-MSIS parquet not found
Execution halted

```

#### 01_fetch_data.R

```

Attaching package: ‘arrow’

The following object is masked from ‘package:utils’:

    timestamp


Attaching package: ‘dplyr’

The following objects are masked from ‘package:data.table’:

    between, first, last

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union


Attaching package: ‘lubridate’

The following objects are masked from ‘package:data.table’:

    hour, isoweek, isoyear, mday, minute, month, quarter, second, wday,
    week, yday, year

The following object is masked from ‘package:arrow’:

    duration

The following objects are masked from ‘package:base’:

    date, intersect, setdiff, union

Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘scales’

The following object is masked from ‘package:fixest’:

    pvalue

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal


Attaching package: ‘kableExtra’

The following object is masked from ‘package:dplyr’:

    group_rows

Error: T-MSIS parquet not found
Execution halted

```

#### 02_clean_data.R

```

Attaching package: ‘arrow’

The following object is masked from ‘package:utils’:

    timestamp


Attaching package: ‘dplyr’

The following objects are masked from ‘package:data.table’:

    between, first, last

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union


Attaching package: ‘lubridate’

The following objects are masked from ‘package:data.table’:

    hour, isoweek, isoyear, mday, minute, month, quarter, second, wday,
    week, yday, year

The following object is masked from ‘package:arrow’:

    duration

The following objects are masked from ‘package:base’:

    date, intersect, setdiff, union

Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘scales’

The following object is masked from ‘package:fixest’:

    pvalue

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal


Attaching package: ‘kableExtra’

The following object is masked from ‘package:dplyr’:

    group_rows

Error: T-MSIS parquet not found
Execution halted

```

#### 03_main_analysis.R

```

Attaching package: ‘arrow’

The following object is masked from ‘package:utils’:

    timestamp


Attaching package: ‘dplyr’

The following objects are masked from ‘package:data.table’:

    between, first, last

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union


Attaching package: ‘lubridate’

The following objects are masked from ‘package:data.table’:

    hour, isoweek, isoyear, mday, minute, month, quarter, second, wday,
    week, yday, year

The following object is masked from ‘package:arrow’:

    duration

The following objects are masked from ‘package:base’:

    date, intersect, setdiff, union

Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘scales’

The following object is masked from ‘package:fixest’:

    pvalue

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal


Attaching package: ‘kableExtra’

The following object is masked from ‘package:dplyr’:

    group_rows

Error: T-MSIS parquet not found
Execution halted

```

#### 04_robustness.R

```

Attaching package: ‘arrow’

The following object is masked from ‘package:utils’:

    timestamp


Attaching package: ‘dplyr’

The following objects are masked from ‘package:data.table’:

    between, first, last

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union


Attaching package: ‘lubridate’

The following objects are masked from ‘package:data.table’:

    hour, isoweek, isoyear, mday, minute, month, quarter, second, wday,
    week, yday, year

The following object is masked from ‘package:arrow’:

    duration

The following objects are masked from ‘package:base’:

    date, intersect, setdiff, union

Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘scales’

The following object is masked from ‘package:fixest’:

    pvalue

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal


Attaching package: ‘kableExtra’

The following object is masked from ‘package:dplyr’:

    group_rows

Error: T-MSIS parquet not found
Execution halted

```

#### 05_figures.R

```

Attaching package: ‘arrow’

The following object is masked from ‘package:utils’:

    timestamp


Attaching package: ‘dplyr’

The following objects are masked from ‘package:data.table’:

    between, first, last

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union


Attaching package: ‘lubridate’

The following objects are masked from ‘package:data.table’:

    hour, isoweek, isoyear, mday, minute, month, quarter, second, wday,
    week, yday, year

The following object is masked from ‘package:arrow’:

    duration

The following objects are masked from ‘package:base’:

    date, intersect, setdiff, union

Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘scales’

The following object is masked from ‘package:fixest’:

    pvalue

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal


Attaching package: ‘kableExtra’

The following object is masked from ‘package:dplyr’:

    group_rows

Error: T-MSIS parquet not found
Execution halted

```

#### 06_tables.R

```

Attaching package: ‘arrow’

The following object is masked from ‘package:utils’:

    timestamp


Attaching package: ‘dplyr’

The following objects are masked from ‘package:data.table’:

    between, first, last

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union


Attaching package: ‘lubridate’

The following objects are masked from ‘package:data.table’:

    hour, isoweek, isoyear, mday, minute, month, quarter, second, wday,
    week, yday, year

The following object is masked from ‘package:arrow’:

    duration

The following objects are masked from ‘package:base’:

    date, intersect, setdiff, union

Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘scales’

The following object is masked from ‘package:fixest’:

    pvalue

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal


Attaching package: ‘kableExtra’

The following object is masked from ‘package:dplyr’:

    group_rows

Error: T-MSIS parquet not found
Execution halted

```


---

## 4. Figure Comparisons

| Figure | Original | Generated | Status |
|--------|----------|-----------|--------|
| `fig3_desert_maps.pdf` | Yes | **No** | NOT GENERATED |
| `fig2_indexed_trends.pdf` | Yes | **No** | NOT GENERATED |
| `fig5_urban_rural_deserts.pdf` | Yes | **No** | NOT GENERATED |
| `fig1_provider_trends.pdf` | Yes | **No** | NOT GENERATED |
| `fig7_unwinding_map.pdf` | Yes | **No** | NOT GENERATED |
| `fig6_ri_distribution.pdf` | Yes | **No** | NOT GENERATED |
| `fig4_event_study.pdf` | Yes | **No** | NOT GENERATED |

---

## 5. Classification

### Final Classification: FAILED REPLICATION

**Justification:**
No scripts executed successfully. Code requires fixes.

---

## 6. Next Steps

1. Review error messages in execution log
2. Fix package dependencies or path issues
3. Re-run replication

---

## Appendix: File Locations

- **Execution Log:** `logs/execution.log`
- **Generated Figures:** `figures/`
- **Generated Tables:** `tables/`
- **Original Paper:** `/Users/dyanag/auto-policy-evals/papers/apep_0417/paper.pdf`
