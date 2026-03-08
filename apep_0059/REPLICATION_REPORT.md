# Replication Report

**Paper ID:** apep_0059
**Title:** Self-Employment and Health Insurance Coverage in the Post-ACA Era:\\ Evidence from the American Community Survey
**Replication Date:** 2026-02-08
**Replicator:** Claude Code

---

## Summary

**Classification:** PARTIAL WITH ERRORS

**Overall Assessment:**
12 of 13 scripts failed. Results may be incomplete.

### Execution Summary

- **Total Scripts:** 13
- **Successful:** 1
- **Failed:** 12

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

**R Scripts:** 11
**Python Scripts:** 2
**Main Script:** 00_packages.R

| Script | Language |
|--------|----------|
| `00_packages.R` | R |
| `01_fetch_data.R` | R |
| `02_clean_data.R` | R |
| `03_analysis.R` | R |
| `03_analysis_fast.R` | R |
| `03_main_analysis.R` | R |
| `04_robustness.R` | R |
| `05_figures.R` | R |
| `06_tables.R` | R |
| `07_complete_outputs.R` | R |
| `08_heterogeneity.R` | R |
| `01_fetch_data.py` | Python |
| `02_clean_data.py` | Python |

---

## 3. Execution Results

| Script | Success | Duration | Exit Code |
|--------|---------|----------|-----------|
| `00_packages.R` | Yes | 1.1s | 0 |
| `01_fetch_data.R` | **No** | 107.4s | 1 |
| `02_clean_data.R` | **No** | 1.1s | 1 |
| `03_analysis.R` | **No** | 1.0s | 1 |
| `03_analysis_fast.R` | **No** | 0.6s | 1 |
| `03_main_analysis.R` | **No** | 1.0s | 1 |
| `04_robustness.R` | **No** | 1.0s | 1 |
| `05_figures.R` | **No** | 1.0s | 1 |
| `06_tables.R` | **No** | 1.1s | 1 |
| `07_complete_outputs.R` | **No** | 10.6s | 1 |
| `08_heterogeneity.R` | **No** | 0.6s | 1 |
| `01_fetch_data.py` | **No** | 0.1s | 1 |
| `02_clean_data.py` | **No** | 0.0s | 1 |

### Errors

#### 01_fetch_data.R

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

Loading required package: nnls
Loading required package: gam
Loading required package: splines
Loading required package: foreach

Attaching package: ‘foreach’

The following objects are masked from ‘package:purrr’:

    accumulate, when

Loaded gam 1.22-7

Super Learner
Version: 2.0-40
Package created on 2025-12-14

See details in:
Carlos Cinelli and Chad Hazlett (2020). Making Sense of Sensitivity: Extending Omitted Variable Bias. Journal of the Royal Statistical Society, Series B (Statistical Methodology).

Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric


Attaching package: ‘jsonlite’

The following object is masked from ‘package:purrr’:

    flatten

Error in curl::curl_fetch_memory(url, handle = handle) : 
  Failure when receiving data from the peer [api.census.gov]:
Recv failure: Connect
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

Loading required package: nnls
Loading required package: gam
Loading required package: splines
Loading required package: foreach

Attaching package: ‘foreach’

The following objects are masked from ‘package:purrr’:

    accumulate, when

Loaded gam 1.22-7

Super Learner
Version: 2.0-40
Package created on 2025-12-14

See details in:
Carlos Cinelli and Chad Hazlett (2020). Making Sense of Sensitivity: Extending Omitted Variable Bias. Journal of the Royal Statistical Society, Series B (Statistical Methodology).

Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

Error in gzfile(file, "rb") : cannot open the connection
Calls: readRDS -> gzfile
In addition: Warning message:
In gzfile(file, "rb") :
  cannot open compressed file 'data//pums_raw_2018_2022.rds', probable reason 'No such file or directory
```

#### 03_analysis.R

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
Loading required package: nnls
Loading required package: gam
Loading required package: splines
Loading required package: foreach

Attaching package: ‘foreach’

The following objects are masked from ‘package:purrr’:

    accumulate, when

Loaded gam 1.22-7

Super Learner
Version: 2.0-40
Package created on 2025-12-14

See details in:
Carlos Cinelli and Chad Hazlett (2020). Making Sense of Sensitivity: Extending Omitted Variable Bias. Journal of the Royal Statistical Society, Series B (Statistical Methodology).
Error: 'data/pums_clean.csv' does not exist in current working directory ('/Users/dyanag/auto-policy-evals/output/replication_apep_0059/code').
Execution halted

```

#### 03_analysis_fast.R

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
Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

See details in:
Carlos Cinelli and Chad Hazlett (2020). Making Sense of Sensitivity: Extending Omitted Variable Bias. Journal of the Royal Statistical Society, Series B (Statistical Methodology).
Error: 'data/pums_clean.csv' does not exist in current working directory ('/Users/dyanag/auto-policy-evals/output/replication_apep_0059/code').
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

Loading required package: nnls
Loading required package: gam
Loading required package: splines
Loading required package: foreach

Attaching package: ‘foreach’

The following objects are masked from ‘package:purrr’:

    accumulate, when

Loaded gam 1.22-7

Super Learner
Version: 2.0-40
Package created on 2025-12-14

See details in:
Carlos Cinelli and Chad Hazlett (2020). Making Sense of Sensitivity: Extending Omitted Variable Bias. Journal of the Royal Statistical Society, Series B (Statistical Methodology).

Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

Error in gzfile(file, "rb") : cannot open the connection
Calls: readRDS -> gzfile
In addition: Warning message:
In gzfile(file, "rb") :
  cannot open compressed file 'data//pums_clean.rds', probable reason 'No such file or directory'
Execut
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

Loading required package: nnls
Loading required package: gam
Loading required package: splines
Loading required package: foreach

Attaching package: ‘foreach’

The following objects are masked from ‘package:purrr’:

    accumulate, when

Loaded gam 1.22-7

Super Learner
Version: 2.0-40
Package created on 2025-12-14

See details in:
Carlos Cinelli and Chad Hazlett (2020). Making Sense of Sensitivity: Extending Omitted Variable Bias. Journal of the Royal Statistical Society, Series B (Statistical Methodology).

Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

Error in gzfile(file, "rb") : cannot open the connection
Calls: readRDS -> gzfile
In addition: Warning message:
In gzfile(file, "rb") :
  cannot open compressed file 'data//pums_clean.rds', probable reason 'No such file or directory'
Execut
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

Loading required package: nnls
Loading required package: gam
Loading required package: splines
Loading required package: foreach

Attaching package: ‘foreach’

The following objects are masked from ‘package:purrr’:

    accumulate, when

Loaded gam 1.22-7

Super Learner
Version: 2.0-40
Package created on 2025-12-14

See details in:
Carlos Cinelli and Chad Hazlett (2020). Making Sense of Sensitivity: Extending Omitted Variable Bias. Journal of the Royal Statistical Society, Series B (Statistical Methodology).

Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

Error in gzfile(file, "rb") : cannot open the connection
Calls: readRDS -> gzfile
In addition: Warning message:
In gzfile(file, "rb") :
  cannot open compressed file 'data//pums_clean.rds', probable reason 'No such file or directory'
Execut
```

#### 06_tables.R

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

Loading required package: nnls
Loading required package: gam
Loading required package: splines
Loading required package: foreach

Attaching package: ‘foreach’

The following objects are masked from ‘package:purrr’:

    accumulate, when

Loaded gam 1.22-7

Super Learner
Version: 2.0-40
Package created on 2025-12-14

See details in:
Carlos Cinelli and Chad Hazlett (2020). Making Sense of Sensitivity: Extending Omitted Variable Bias. Journal of the Royal Statistical Society, Series B (Statistical Methodology).

Attaching package: ‘scales’

The following object is masked from ‘package:purrr’:

    discard

The following object is masked from ‘package:readr’:

    col_factor

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric


Attaching package: ‘kableExtra’

The following object is masked from ‘package:dplyr’:

    group_rows

Error in gzfile(file, "rb") : cannot open the connection
Calls: readRDS -> gzfile
In addition: Warning message:
In gzfile(file, "rb") :

```

#### 07_complete_outputs.R

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
Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

See details in:
Carlos Cinelli and Chad Hazlett (2020). Making Sense of Sensitivity: Extending Omitted Variable Bias. Journal of the Royal Statistical Society, Series B (Statistical Methodology).
Error: Failed to fetch data
Execution halted

```

#### 08_heterogeneity.R

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
Error: '/Users/dyanag/auto-policy-evals/output/paper_1/data/pums_sample.csv' does not exist.
Execution halted

```

#### 01_fetch_data.py

```
Traceback (most recent call last):
  File "/Users/dyanag/auto-policy-evals/output/replication_apep_0059/code/01_fetch_data.py", line 9, in <module>
    import pandas as pd
ModuleNotFoundError: No module named 'pandas'

```

#### 02_clean_data.py

```
Traceback (most recent call last):
  File "/Users/dyanag/auto-policy-evals/output/replication_apep_0059/code/02_clean_data.py", line 7, in <module>
    import pandas as pd
ModuleNotFoundError: No module named 'pandas'

```


---

## 4. Figure Comparisons

| Figure | Original | Generated | Status |
|--------|----------|-----------|--------|
| `fig4_heterogeneity_income.png` | Yes | **No** | NOT GENERATED |
| `fig2_coefficient_plot.png` | Yes | **No** | NOT GENERATED |
| `fig3_heterogeneity_expansion.png` | Yes | **No** | NOT GENERATED |
| `fig1_coverage_by_employment.png` | Yes | **No** | NOT GENERATED |

---

## 5. Classification

### Final Classification: PARTIAL WITH ERRORS

**Justification:**
12 of 13 scripts failed. Results may be incomplete.

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
- **Original Paper:** `/Users/dyanag/auto-policy-evals/papers/apep_0059/paper.pdf`
