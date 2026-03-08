# Replication Report

**Paper ID:** apep_0065
**Title:** Time to Give Back? Social Security Eligibility at Age 62 and Civic Engagement\thanks{We thank anonymous reviewers for helpful comments. This is a revision of APEP Working Paper 0081.
**Replication Date:** 2026-02-08
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
| `03b_first_stage.R` | R |
| `04_robustness.R` | R |
| `05_figures.R` | R |

---

## 3. Execution Results

| Script | Success | Duration | Exit Code |
|--------|---------|----------|-----------|
| `00_packages.R` | **No** | 324.5s | 1 |
| `01_fetch_data.R` | **No** | 223.9s | 1 |
| `02_clean_data.R` | **No** | 285.6s | 1 |
| `03_main_analysis.R` | **No** | 266.2s | 1 |
| `03b_first_stage.R` | **No** | 336.4s | 1 |
| `04_robustness.R` | **No** | 193.7s | 1 |
| `05_figures.R` | **No** | 168.6s | 1 |

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

Attaching package: ‘data.table’

The following objects are masked from ‘package:lubridate’:

    hour, isoweek, mday, minute, month, quarter, second, wday, week,
    yday, year

The following objects are masked from ‘package:dplyr’:

    between, first, last

The following object is masked from ‘package:purrr’:

    transpose

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

Installing package into ‘/opt/homebrew/lib/R/4.5/site-library’
(as ‘lib’ is unspecified)
Warning: unable to access index for repository https://cloud.r-project.org/src/contrib:
  download from 'https://cloud.r-project.org/src/contrib/PACKAGES' failed
Warning message:
package ‘devtools’ is not available for this version of R

A version of this package for your version of R might be available elsewhere,
see the ideas at
https://cran.r-project.org/doc/manuals/r-patched/R-admin.html#Installing-packages 
Installing package into ‘/opt/homebrew/lib/R/4.5/site-library’
(as ‘lib’ is unspecified)
Warning: unable to access index for repository https://cloud.r-project.org/src/contrib:
  download from 'https://cloud.r-project.org/src/contrib/PACKAGES' failed
Warning message:
package ‘rdlocrand’ is not available for this version of R

A version of this package for your version of R might be available elsewhere,
see the id
```

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

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

Installing package into ‘/opt/homebrew/lib/R/4.5/site-library’
(as ‘lib’ is unspecified)
also installing the dependencies ‘credentials’, ‘gitcreds’, ‘ini’, ‘sourcetools’, ‘fansi’, ‘diffobj’, ‘gert’, ‘gh’, ‘shiny’, ‘downlit’, ‘xopen’, ‘brew’, ‘brio’, ‘praise’, ‘waldo’, ‘usethis’, ‘desc’, ‘ellipsis’, ‘miniUI’, ‘pkgbuild’, ‘pkgdown’, ‘pkgload’, ‘profvis’, ‘rcmdcheck’, ‘roxygen2’, ‘rversions’, ‘sessioninfo’, ‘testthat’, ‘urlchecker’

trying URL 'https://cloud.r-project.org/src/contrib/credentials_2.0.3.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/gitcreds_0.1.2.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/ini_0.3.1.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/sourcetools_0.1.7-1.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/fansi_1.0.7.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/diffobj_0.3.6.tar.gz'
trying URL 'https://cloud.r-project.or
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

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

Installing package into ‘/opt/homebrew/lib/R/4.5/site-library’
(as ‘lib’ is unspecified)
Warning: unable to access index for repository https://cloud.r-project.org/src/contrib:
  download from 'https://cloud.r-project.org/src/contrib/PACKAGES' failed
Installing package into ‘/opt/homebrew/lib/R/4.5/site-library’
(as ‘lib’ is unspecified)
also installing the dependencies ‘nloptr’, ‘pbkrtest’, ‘lme4’, ‘car’, ‘AER’

trying URL 'https://cloud.r-project.org/src/contrib/nloptr_2.2.1.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/pbkrtest_0.5.5.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/lme4_1.1-38.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/car_3.1-5.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/AER_1.2-15.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/rdlocrand_1.1.tar.gz'
Warning in download.packages(pkgs, destdir = tmpd, available = availa
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

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

Installing package into ‘/opt/homebrew/lib/R/4.5/site-library’
(as ‘lib’ is unspecified)
Warning: unable to access index for repository https://cloud.r-project.org/src/contrib:
  download from 'https://cloud.r-project.org/src/contrib/PACKAGES' failed
Installing package into ‘/opt/homebrew/lib/R/4.5/site-library’
(as ‘lib’ is unspecified)
also installing the dependencies ‘nloptr’, ‘pbkrtest’, ‘lme4’, ‘car’, ‘AER’

trying URL 'https://cloud.r-project.org/src/contrib/nloptr_2.2.1.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/pbkrtest_0.5.5.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/lme4_1.1-38.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/car_3.1-5.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/AER_1.2-15.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/rdlocrand_1.1.tar.gz'
Warning in download.packages(pkgs, destdir = tmpd, available = availa
```

#### 03b_first_stage.R

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

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

Installing package into ‘/opt/homebrew/lib/R/4.5/site-library’
(as ‘lib’ is unspecified)
Warning: unable to access index for repository https://cloud.r-project.org/src/contrib:
  download from 'https://cloud.r-project.org/src/contrib/PACKAGES' failed
Installing package into ‘/opt/homebrew/lib/R/4.5/site-library’
(as ‘lib’ is unspecified)
Warning: unable to access index for repository https://cloud.r-project.org/src/contrib:
  download from 'https://cloud.r-project.org/src/contrib/PACKAGES' failed
Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
In addition: Warning messages:
1: package ‘devtools’ is not available for this version of R

A version of this package for your version of R might be available elsewhere,
see the ideas at
https://cran.r-project.org
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

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

Installing package into ‘/opt/homebrew/lib/R/4.5/site-library’
(as ‘lib’ is unspecified)
also installing the dependencies ‘fansi’, ‘gert’, ‘shiny’, ‘downlit’, ‘usethis’, ‘miniUI’, ‘pkgdown’, ‘rcmdcheck’, ‘rversions’, ‘sessioninfo’, ‘testthat’, ‘urlchecker’

trying URL 'https://cloud.r-project.org/src/contrib/fansi_1.0.7.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/gert_2.3.1.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/shiny_1.12.1.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/downlit_0.4.5.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/usethis_3.2.1.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/miniUI_0.1.2.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/pkgdown_2.2.0.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/rcmdcheck_1.4.0.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/rversions_3.0.0.tar.gz'

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

Loading required package: zoo

Attaching package: ‘zoo’

The following objects are masked from ‘package:data.table’:

    yearmon, yearqtr

The following objects are masked from ‘package:base’:

    as.Date, as.Date.numeric

Installing package into ‘/opt/homebrew/lib/R/4.5/site-library’
(as ‘lib’ is unspecified)
also installing the dependencies ‘gert’, ‘shiny’, ‘usethis’, ‘miniUI’, ‘pkgdown’, ‘rcmdcheck’, ‘sessioninfo’, ‘testthat’

trying URL 'https://cloud.r-project.org/src/contrib/gert_2.3.1.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/shiny_1.12.1.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/usethis_3.2.1.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/miniUI_0.1.2.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/pkgdown_2.2.0.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/rcmdcheck_1.4.0.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/sessioninfo_1.2.3.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/testthat_3.3.2.tar.gz'
trying URL 'https://cloud.r-project.org/src/contrib/devtools_2.4.6.tar.gz'
Warning in download.packages(pkgs, destdi
```


---

## 4. Figure Comparisons

| Figure | Original | Generated | Status |
|--------|----------|-----------|--------|
| `fig3_bandwidth.pdf` | Yes | **No** | NOT GENERATED |
| `fig_mccrary.pdf` | Yes | **No** | NOT GENERATED |
| `fig_first_stage_combined.pdf` | Yes | **No** | NOT GENERATED |
| `fig1_main_rdd.png` | Yes | **No** | NOT GENERATED |
| `fig1_volunteer_rate_raw.png` | Yes | **No** | NOT GENERATED |
| `fig2_first_stage.pdf` | Yes | **No** | NOT GENERATED |
| `fig1_volunteer_rate_raw.pdf` | Yes | **No** | NOT GENERATED |
| `fig5_grandchild_care.pdf` | Yes | **No** | NOT GENERATED |
| `fig1_main_rdd.pdf` | Yes | **No** | NOT GENERATED |
| `fig4_placebo_cutoffs.pdf` | Yes | **No** | NOT GENERATED |
| `fig2_volunteer_mins_raw.pdf` | Yes | **No** | NOT GENERATED |
| `fig_first_stage_employed.pdf` | Yes | **No** | NOT GENERATED |
| `fig6_inference_comparison.pdf` | Yes | **No** | NOT GENERATED |
| `fig_first_stage_work.pdf` | Yes | **No** | NOT GENERATED |
| `fig_placebo_cutoffs.pdf` | Yes | **No** | NOT GENERATED |
| `fig3_rdd_volunteer.pdf` | Yes | **No** | NOT GENERATED |
| `fig_first_stage_work.png` | Yes | **No** | NOT GENERATED |
| `fig_bandwidth_comparison.pdf` | Yes | **No** | NOT GENERATED |

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
- **Original Paper:** `/Users/dyanag/auto-policy-evals/papers/apep_0065/paper.pdf`
