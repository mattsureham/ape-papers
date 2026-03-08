# Replication Report

**Paper ID:** apep_0067
**Title:** Minimum Wage Increases and Teen Time Allocation:\\Evidence from the American Time Use Survey
**Replication Date:** 2026-02-08
**Replicator:** Claude Code

---

## Summary

**Classification:** FAILED REPLICATION

**Overall Assessment:**
No scripts executed successfully. Code requires fixes.

### Execution Summary

- **Total Scripts:** 12
- **Successful:** 0
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
**Python Scripts:** 1
**Main Script:** 00_packages.R

| Script | Language |
|--------|----------|
| `00_packages.R` | R |
| `01_fetch_data.R` | R |
| `02_clean_data.R` | R |
| `03_main_analysis.R` | R |
| `05_figures.R` | R |
| `07_inference.R` | R |
| `08_revised_analysis.R` | R |
| `09_modern_did.R` | R |
| `10_revised_analysis.R` | R |
| `11_modern_methods.R` | R |
| `12_modern_did_proper.R` | R |
| `fetch_atus_ipums.py` | Python |

---

## 3. Execution Results

| Script | Success | Duration | Exit Code |
|--------|---------|----------|-----------|
| `00_packages.R` | **No** | 1.2s | 1 |
| `01_fetch_data.R` | **No** | 1.2s | 1 |
| `02_clean_data.R` | **No** | 1.2s | 1 |
| `03_main_analysis.R` | **No** | 1.2s | 1 |
| `05_figures.R` | **No** | 1.2s | 1 |
| `07_inference.R` | **No** | 1.2s | 1 |
| `08_revised_analysis.R` | **No** | 1.2s | 1 |
| `09_modern_did.R` | **No** | 1.2s | 1 |
| `10_revised_analysis.R` | **No** | 1.3s | 1 |
| `11_modern_methods.R` | **No** | 1.1s | 1 |
| `12_modern_did_proper.R` | **No** | 1.1s | 1 |
| `fetch_atus_ipums.py` | **No** | 0.0s | 1 |

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

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

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

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

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

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
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

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
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

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 07_inference.R

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

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 08_revised_analysis.R

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

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 09_modern_did.R

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

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 10_revised_analysis.R

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

Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 11_modern_methods.R

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

Error in gzfile(file, "rb") : cannot open the connection
Calls: readRDS -> gzfile
In addition: Warning message:
In gzfile(file, "rb") :
  cannot open compressed file '../data/analysis_data.rds', probable reason 'No such file or directory'
Execution halted

```

#### 12_modern_did_proper.R

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

Loading required package: did2s
did2s (v1.2.0). For more information on the methodology, visit <https://www.kylebutts.github.io/did2s>

To cite did2s in publications use:

  Butts & Gardner, "The R Journal: did2s: Two-Stage
  Difference-in-Differences", The R Journal, 2022

A BibTeX entry for LaTeX users is

  @Manual{,
    title = {did2s: Two-Stage Difference-in-Differences Following Gardner (2021)},
    author = {Kyle Butts and John Gardner},
    year = {2021},
    url = {https://journal.r-project.org/articles/RJ-2022-048/},
  }


Loading required package: didimputation

Attaching package: ‘didimputation’

The following objects are masked from ‘package:did2s’:

    df_het, df_hom

Error in gzfile(file, "rb") : cannot open the connection
Calls: readRDS -> gzfile
In addition: Warning message:
In gzfile(file, "rb") :
  cannot open compressed file '../data/analysis_data.rds', probable reason 'No such file or directory'
Execution halted

```

#### fetch_atus_ipums.py

```
Traceback (most recent call last):
  File "/Users/dyanag/auto-policy-evals/output/replication_apep_0067/code/fetch_atus_ipums.py", line 20, in <module>
    from ipumspy import IpumsApiClient, MicrodataExtract
ModuleNotFoundError: No module named 'ipumspy'

```


---

## 4. Figure Comparisons

| Figure | Original | Generated | Status |
|--------|----------|-----------|--------|
| `fig1_mw_variation.png` | Yes | **No** | NOT GENERATED |
| `cs_event_study.pdf` | Yes | **No** | NOT GENERATED |
| `fig1_mw_variation.pdf` | Yes | **No** | NOT GENERATED |
| `cs_event_study_proper.pdf` | Yes | **No** | NOT GENERATED |
| `fig_event_study_work.pdf` | Yes | **No** | NOT GENERATED |
| `fig3_heterogeneity_age.png` | Yes | **No** | NOT GENERATED |
| `fig_event_study_work.png` | Yes | **No** | NOT GENERATED |
| `fig3_heterogeneity_age.pdf` | Yes | **No** | NOT GENERATED |
| `sc_gaps.pdf` | Yes | **No** | NOT GENERATED |
| `modern_did_comparison.pdf` | Yes | **No** | NOT GENERATED |
| `fig4_treatment_map.png` | Yes | **No** | NOT GENERATED |
| `fig4_treatment_map.pdf` | Yes | **No** | NOT GENERATED |
| `fig5_parallel_trends.pdf` | Yes | **No** | NOT GENERATED |
| `fig2_event_study.pdf` | Yes | **No** | NOT GENERATED |
| `permutation_distribution.pdf` | Yes | **No** | NOT GENERATED |
| `fig2_event_study.png` | Yes | **No** | NOT GENERATED |
| `fig5_parallel_trends.png` | Yes | **No** | NOT GENERATED |
| `all_figures.pdf` | Yes | **No** | NOT GENERATED |
| `fig_modern_did_comparison.pdf` | Yes | **No** | NOT GENERATED |

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
- **Original Paper:** `/Users/dyanag/auto-policy-evals/papers/apep_0067/paper.pdf`
