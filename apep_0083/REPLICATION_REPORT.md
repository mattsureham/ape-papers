# Replication Report

**Paper ID:** apep_0083
**Title:** Roads, Crashes, and Substances: A Geocoded Atlas of Western US Traffic Fatalities\footnote{This paper is a revision of APEP-0103. See \url{https://github.com/anthropics/auto-policy-evals/tree/main/papers/apep_0103
**Replication Date:** 2026-02-08
**Replicator:** Claude Code

---

## Summary

**Classification:** FAILED REPLICATION

**Overall Assessment:**
No scripts executed successfully. Code requires fixes.

### Execution Summary

- **Total Scripts:** 25
- **Successful:** 0
- **Failed:** 25

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

**R Scripts:** 23
**Python Scripts:** 2
**Main Script:** 00_packages.R

| Script | Language |
|--------|----------|
| `00_packages.R` | R |
| `01_fetch_fars.R` | R |
| `04_merge_policy.R` | R |
| `05_build_analysis.R` | R |
| `06_national_figures.R` | R |
| `07_zoom_figures.R` | R |
| `08_substance_figures.R` | R |
| `09_border_figures.R` | R |
| `10_tables.R` | R |
| `clean_and_fix_data.R` | R |
| `debug_thc.R` | R |
| `diagnose_thc_rates.R` | R |
| `fix_all_figure_labels.R` | R |
| `fix_all_figures.R` | R |
| `fix_figure_labels.R` | R |
| `fix_final_figures.R` | R |
| `fix_polysubstance_figure.R` | R |
| `fix_remaining_figures.R` | R |
| `fix_substance_data.R` | R |
| `fix_substance_figures.R` | R |
| `fix_testing_rate.R` | R |
| `regenerate_all_figures.R` | R |
| `regenerate_figures.R` | R |
| `02_fetch_osm.py` | Python |
| `03_snap_crashes.py` | Python |

---

## 3. Execution Results

| Script | Success | Duration | Exit Code |
|--------|---------|----------|-----------|
| `00_packages.R` | **No** | 2.1s | 1 |
| `01_fetch_fars.R` | **No** | 0.9s | 1 |
| `04_merge_policy.R` | **No** | 0.9s | 1 |
| `05_build_analysis.R` | **No** | 0.8s | 1 |
| `06_national_figures.R` | **No** | 0.8s | 1 |
| `07_zoom_figures.R` | **No** | 0.8s | 1 |
| `08_substance_figures.R` | **No** | 0.8s | 1 |
| `09_border_figures.R` | **No** | 0.8s | 1 |
| `10_tables.R` | **No** | 0.8s | 1 |
| `clean_and_fix_data.R` | **No** | 0.8s | 1 |
| `debug_thc.R` | **No** | 60.6s | 1 |
| `diagnose_thc_rates.R` | **No** | 0.9s | 1 |
| `fix_all_figure_labels.R` | **No** | 0.8s | 1 |
| `fix_all_figures.R` | **No** | 0.8s | 1 |
| `fix_figure_labels.R` | **No** | 0.8s | 1 |
| `fix_final_figures.R` | **No** | 0.8s | 1 |
| `fix_polysubstance_figure.R` | **No** | 0.8s | 1 |
| `fix_remaining_figures.R` | **No** | 0.8s | 1 |
| `fix_substance_data.R` | **No** | 0.8s | 1 |
| `fix_substance_figures.R` | **No** | 0.8s | 1 |
| `fix_testing_rate.R` | **No** | 0.8s | 1 |
| `regenerate_all_figures.R` | **No** | 0.8s | 1 |
| `regenerate_figures.R` | **No** | 0.8s | 1 |
| `02_fetch_osm.py` | **No** | 0.0s | 1 |
| `03_snap_crashes.py` | **No** | 0.1s | 1 |

### Errors

#### 00_packages.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 01_fetch_fars.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 04_merge_policy.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 05_build_analysis.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 06_national_figures.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 07_zoom_figures.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 08_substance_figures.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 09_border_figures.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 10_tables.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### clean_and_fix_data.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### debug_thc.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose


Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test

=== THC Data Pipeline Debug ===

Step 1: Downloading 2019 FARS data...
Error in download.file(url, temp_zip, mode = "wb", quiet = TRUE) : 
  download from 'https://static.nhtsa.gov/nhtsa/downloads/FARS/2019/National/FARS2019NationalCSV.zip' failed
In addition: Warning messages:
1: In download.file(url, temp_zip, mode = "wb", quiet = TRUE) :
  downloaded length 2865769 != reported length 26974033
2: In download.file(url, temp_zip, mode = "wb", quiet = TRUE) :
  URL 'https://static.nhtsa.gov/nhtsa/downloads/FARS/2019/National/FARS2019NationalCSV.zip': Timeout of 60 seconds was reached
Execution halted

```

#### diagnose_thc_rates.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### fix_all_figure_labels.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### fix_all_figures.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### fix_figure_labels.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### fix_final_figures.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### fix_polysubstance_figure.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### fix_remaining_figures.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### fix_substance_data.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### fix_substance_figures.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### fix_testing_rate.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### regenerate_all_figures.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### regenerate_figures.R

```
── Attaching core tidyverse packages ──────────────────────── tidyverse 2.0.0 ──
✔ dplyr     1.2.0     ✔ readr     2.1.6
✔ forcats   1.0.1     ✔ stringr   1.6.0
✔ ggplot2   4.0.2     ✔ tibble    3.3.1
✔ lubridate 1.9.4     ✔ tidyr     1.3.2
✔ purrr     1.2.1     
── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
✖ dplyr::filter() masks stats::filter()
✖ dplyr::lag()    masks stats::lag()
ℹ Use the conflicted package (<http://conflicted.r-lib.org/>) to force all conflicts to become errors
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
udunits database from /opt/homebrew/lib/R/4.5/site-library/units/share/udunits/udunits2.xml

Attaching package: ‘janitor’

The following objects are masked from ‘package:stats’:

    chisq.test, fisher.test


Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: viridisLite

Attaching package: ‘viridis’

The following object is masked from ‘package:scales’:

    viridis_pal

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 02_fetch_osm.py

```
Traceback (most recent call last):
  File "/Users/dyanag/auto-policy-evals/output/replication_apep_0083/code/02_fetch_osm.py", line 11, in <module>
    import geopandas as gpd
ModuleNotFoundError: No module named 'geopandas'

```

#### 03_snap_crashes.py

```
Traceback (most recent call last):
  File "/Users/dyanag/auto-policy-evals/output/replication_apep_0083/code/03_snap_crashes.py", line 12, in <module>
    import geopandas as gpd
ModuleNotFoundError: No module named 'geopandas'

```


---

## 4. Figure Comparisons

| Figure | Original | Generated | Status |
|--------|----------|-----------|--------|
| `fig08_testing_rate_by_state.png` | Yes | **No** | NOT GENERATED |
| `fig10_co_wy_border.png` | Yes | **No** | NOT GENERATED |
| `fig13_wa_id_border.png` | Yes | **No** | NOT GENERATED |
| `fig10_co_wy_border.pdf` | Yes | **No** | NOT GENERATED |
| `fig13_wa_id_border.pdf` | Yes | **No** | NOT GENERATED |
| `fig08_testing_rate_by_state.pdf` | Yes | **No** | NOT GENERATED |
| `fig25_thc_rate_border.png` | Yes | **No** | NOT GENERATED |
| `fig23_weekend_weekday.png` | Yes | **No** | NOT GENERATED |
| `fig02_annual_crashes.pdf` | Yes | **No** | NOT GENERATED |
| `fig23_weekend_weekday.pdf` | Yes | **No** | NOT GENERATED |
| `fig02_annual_crashes.png` | Yes | **No** | NOT GENERATED |
| `fig25_thc_rate_border.pdf` | Yes | **No** | NOT GENERATED |
| `fig27_event_study_by_state.png` | Yes | **No** | NOT GENERATED |
| `fig29_rdd_co_wy.png` | Yes | **No** | NOT GENERATED |
| `fig07_geocoding_quality.png` | Yes | **No** | NOT GENERATED |
| `fig20_polysubstance.png` | Yes | **No** | NOT GENERATED |
| `fig12_denver_metro.pdf` | Yes | **No** | NOT GENERATED |
| `fig20_polysubstance.pdf` | Yes | **No** | NOT GENERATED |
| `fig12_denver_metro.png` | Yes | **No** | NOT GENERATED |
| `fig27_event_study_by_state.pdf` | Yes | **No** | NOT GENERATED |
| `fig29_rdd_co_wy.pdf` | Yes | **No** | NOT GENERATED |
| `fig07_geocoding_quality.pdf` | Yes | **No** | NOT GENERATED |
| `fig26_event_study_thc.png` | Yes | **No** | NOT GENERATED |
| `fig06_crashes_by_dow.pdf` | Yes | **No** | NOT GENERATED |
| `fig09_crashes_by_state.png` | Yes | **No** | NOT GENERATED |
| `fig05_crashes_by_hour.pdf` | Yes | **No** | NOT GENERATED |
| `fig11_i25_corridor.pdf` | Yes | **No** | NOT GENERATED |
| `fig01_crash_density_map.png` | Yes | **No** | NOT GENERATED |
| `fig11_i25_corridor.png` | Yes | **No** | NOT GENERATED |
| `fig01_crash_density_map.pdf` | Yes | **No** | NOT GENERATED |
| `fig26_event_study_thc.pdf` | Yes | **No** | NOT GENERATED |
| `fig05_crashes_by_hour.png` | Yes | **No** | NOT GENERATED |
| `fig06_crashes_by_dow.png` | Yes | **No** | NOT GENERATED |
| `fig09_crashes_by_state.pdf` | Yes | **No** | NOT GENERATED |
| `fig19_thc_vs_alcohol_trend.png` | Yes | **No** | NOT GENERATED |
| `fig14_or_id_border.png` | Yes | **No** | NOT GENERATED |
| `fig14_or_id_border.pdf` | Yes | **No** | NOT GENERATED |
| `fig19_thc_vs_alcohol_trend.pdf` | Yes | **No** | NOT GENERATED |
| `fig16_nv_ut_border.png` | Yes | **No** | NOT GENERATED |
| `fig22_alcohol_by_hour.pdf` | Yes | **No** | NOT GENERATED |
| `fig24_crash_density_border.pdf` | Yes | **No** | NOT GENERATED |
| `fig03_thc_rate_over_time.pdf` | Yes | **No** | NOT GENERATED |
| `fig21_thc_before_after.pdf` | Yes | **No** | NOT GENERATED |
| `fig03_thc_rate_over_time.png` | Yes | **No** | NOT GENERATED |
| `fig21_thc_before_after.png` | Yes | **No** | NOT GENERATED |
| `fig16_nv_ut_border.pdf` | Yes | **No** | NOT GENERATED |
| `fig24_crash_density_border.png` | Yes | **No** | NOT GENERATED |
| `fig22_alcohol_by_hour.png` | Yes | **No** | NOT GENERATED |
| `fig18_bac_distribution.pdf` | Yes | **No** | NOT GENERATED |
| `fig28_border_pairs.png` | Yes | **No** | NOT GENERATED |
| `fig18_bac_distribution.png` | Yes | **No** | NOT GENERATED |
| `fig28_border_pairs.pdf` | Yes | **No** | NOT GENERATED |
| `fig15_ca_az_border.pdf` | Yes | **No** | NOT GENERATED |
| `fig04_alcohol_rate_over_time.png` | Yes | **No** | NOT GENERATED |
| `fig17_denver_day_night.pdf` | Yes | **No** | NOT GENERATED |
| `fig17_denver_day_night.png` | Yes | **No** | NOT GENERATED |
| `fig15_ca_az_border.png` | Yes | **No** | NOT GENERATED |
| `fig04_alcohol_rate_over_time.pdf` | Yes | **No** | NOT GENERATED |

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
- **Original Paper:** `/Users/dyanag/auto-policy-evals/papers/apep_0083/paper.pdf`
