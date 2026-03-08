# Replication Report

**Paper ID:** apep_0073
**Title:** Do SNAP Work Requirements Increase Employment? \\ Evidence from Staggered Waiver Expiration
**Replication Date:** 2026-02-08
**Replicator:** Claude Code

---

## Summary

**Classification:** PARTIAL WITH ERRORS

**Overall Assessment:**
10 of 11 scripts failed. Results may be incomplete.

### Execution Summary

- **Total Scripts:** 11
- **Successful:** 1
- **Failed:** 10

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

**R Scripts:** 6
**Python Scripts:** 5
**Main Script:** 00_packages.R

| Script | Language |
|--------|----------|
| `00_packages.R` | R |
| `01_fetch_data.R` | R |
| `02_clean_data.R` | R |
| `03_main_analysis.R` | R |
| `04_robustness.R` | R |
| `05_figures.R` | R |
| `01_fetch_data.py` | Python |
| `05_figures.py` | Python |
| `analysis.py` | Python |
| `analysis_fast.py` | Python |
| `analysis_simulated.py` | Python |

---

## 3. Execution Results

| Script | Success | Duration | Exit Code |
|--------|---------|----------|-----------|
| `00_packages.R` | Yes | 1.4s | 0 |
| `01_fetch_data.R` | **No** | 599.9s | -1 |
| `02_clean_data.R` | **No** | 1.9s | 1 |
| `03_main_analysis.R` | **No** | 1.4s | 1 |
| `04_robustness.R` | **No** | 1.5s | 1 |
| `05_figures.R` | **No** | 1.4s | 1 |
| `01_fetch_data.py` | **No** | 0.1s | 1 |
| `05_figures.py` | **No** | 0.0s | 1 |
| `analysis.py` | **No** | 0.0s | 1 |
| `analysis_fast.py` | **No** | 0.0s | 1 |
| `analysis_simulated.py` | **No** | 0.0s | 1 |

### Errors

#### 01_fetch_data.R

```
TIMEOUT: Script exceeded 10 minute limit
```

#### 02_clean_data.R

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

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE
Error in gzfile(file, "rb") : cannot open the connection
Calls: readRDS -> gzfile
In addition: Warning message:
In gzfile(file, "rb") :
  cannot open compressed file '../data/pums_raw.rds', probable reason 'No such file or directory'
Execution halted

```

#### 03_main_analysis.R

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

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE
Error in gzfile(file, "rb") : cannot open the connection
Calls: readRDS -> gzfile
In addition: Warning message:
In gzfile(file, "rb") :
  cannot open compressed file '../data/state_year.rds', probable reason 'No such file or directory'
Execution halted

```

#### 04_robustness.R

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

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE
Error in gzfile(file, "rb") : cannot open the connection
Calls: readRDS -> gzfile
In addition: Warning message:
In gzfile(file, "rb") :
  cannot open compressed file '../data/state_year.rds', probable reason 'No such file or directory'
Execution halted

```

#### 05_figures.R

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

To enable caching of data, set `options(tigris_use_cache = TRUE)`
in your R script or .Rprofile.
Linking to GEOS 3.14.1, GDAL 3.12.1, PROJ 9.7.1; sf_use_s2() is TRUE
Error in gzfile(file, "rb") : cannot open the connection
Calls: readRDS -> gzfile
In addition: Warning message:
In gzfile(file, "rb") :
  cannot open compressed file '../data/cs_results.rds', probable reason 'No such file or directory'
Execution halted

```

#### 01_fetch_data.py

```
Traceback (most recent call last):
  File "/Users/dyanag/auto-policy-evals/output/replication_apep_0073/code/01_fetch_data.py", line 9, in <module>
    import pandas as pd
ModuleNotFoundError: No module named 'pandas'

```

#### 05_figures.py

```
Traceback (most recent call last):
  File "/Users/dyanag/auto-policy-evals/output/replication_apep_0073/code/05_figures.py", line 8, in <module>
    import pandas as pd
ModuleNotFoundError: No module named 'pandas'

```

#### analysis.py

```
Traceback (most recent call last):
  File "/Users/dyanag/auto-policy-evals/output/replication_apep_0073/code/analysis.py", line 9, in <module>
    import pandas as pd
ModuleNotFoundError: No module named 'pandas'

```

#### analysis_fast.py

```
Traceback (most recent call last):
  File "/Users/dyanag/auto-policy-evals/output/replication_apep_0073/code/analysis_fast.py", line 9, in <module>
    import pandas as pd
ModuleNotFoundError: No module named 'pandas'

```

#### analysis_simulated.py

```
Traceback (most recent call last):
  File "/Users/dyanag/auto-policy-evals/output/replication_apep_0073/code/analysis_simulated.py", line 9, in <module>
    import pandas as pd
ModuleNotFoundError: No module named 'pandas'

```


---

## 4. Figure Comparisons

| Figure | Original | Generated | Status |
|--------|----------|-----------|--------|
| `parallel_trends.png` | Yes | **No** | NOT GENERATED |
| `parallel_trends.pdf` | Yes | **No** | NOT GENERATED |
| `did_diagram.png` | Yes | **No** | NOT GENERATED |
| `did_diagram.pdf` | Yes | **No** | NOT GENERATED |
| `state_heterogeneity.pdf` | Yes | **No** | NOT GENERATED |
| `state_heterogeneity.png` | Yes | **No** | NOT GENERATED |
| `event_study.png` | Yes | **No** | NOT GENERATED |
| `event_study.pdf` | Yes | **No** | NOT GENERATED |

---

## 5. Classification

### Final Classification: PARTIAL WITH ERRORS

**Justification:**
10 of 11 scripts failed. Results may be incomplete.

---

## 6. Next Steps

1. Fix failing scripts
2. Re-run replication
3. Visually compare outputs

---

## Appendix: File Locations

- **Execution Log:** `logs/execution.log`
- **Generated Figures:** `figures/`
- **Generated Tables:** `tables/`
- **Original Paper:** `/Users/dyanag/auto-policy-evals/papers/apep_0073/paper.pdf`
