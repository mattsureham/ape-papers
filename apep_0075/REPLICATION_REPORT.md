# Replication Report

**Paper ID:** apep_0075
**Title:** Gray Wages: The Employment Effects of Minimum Wage Increases on Older Workers
**Replication Date:** 2026-02-08
**Replicator:** Claude Code

---

## Summary

**Classification:** PARTIAL WITH ERRORS

**Overall Assessment:**
7 of 8 scripts failed. Results may be incomplete.

### Execution Summary

- **Total Scripts:** 8
- **Successful:** 1
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

**R Scripts:** 8
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
| `regen_figures.R` | R |

---

## 3. Execution Results

| Script | Success | Duration | Exit Code |
|--------|---------|----------|-----------|
| `00_packages.R` | Yes | 2.0s | 0 |
| `01_fetch_data.R` | **No** | 0.1s | 1 |
| `02_clean_data.R` | **No** | 0.1s | 1 |
| `03_main_analysis.R` | **No** | 0.1s | 1 |
| `04_robustness.R` | **No** | 0.1s | 1 |
| `05_figures.R` | **No** | 0.1s | 1 |
| `06_tables.R` | **No** | 0.1s | 1 |
| `regen_figures.R` | **No** | 0.5s | 1 |

### Errors

#### 01_fetch_data.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'output/paper_102/code/00_packages.R': No such file or directory
Execution halted

```

#### 02_clean_data.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'output/paper_102/code/00_packages.R': No such file or directory
Execution halted

```

#### 03_main_analysis.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'output/paper_102/code/00_packages.R': No such file or directory
Execution halted

```

#### 04_robustness.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'output/paper_102/code/00_packages.R': No such file or directory
Execution halted

```

#### 05_figures.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'output/paper_102/code/00_packages.R': No such file or directory
Execution halted

```

#### 06_tables.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'output/paper_102/code/00_packages.R': No such file or directory
Execution halted

```

#### regen_figures.R

```

Attaching package: ‘dplyr’

The following objects are masked from ‘package:stats’:

    filter, lag

The following objects are masked from ‘package:base’:

    intersect, setdiff, setequal, union

Error in `ggsave()`:
! Cannot find directory 'output/paper_102/figures'.
ℹ Please supply an existing directory or use `create.dir = TRUE`.
Backtrace:
    ▆
 1. └─ggplot2::ggsave(...)
 2.   └─ggplot2:::validate_path(path, filename, create.dir)
 3.     └─cli::cli_abort(...)
 4.       └─rlang::abort(...)
Execution halted

```


---

## 4. Figure Comparisons

| Figure | Original | Generated | Status |
|--------|----------|-----------|--------|
| `fig1_mw_variation.pdf` | Yes | **No** | NOT GENERATED |
| `fig3_treatment_timing.pdf` | Yes | **No** | NOT GENERATED |
| `fig2_states_above_fed.pdf` | Yes | **No** | NOT GENERATED |

---

## 5. Classification

### Final Classification: PARTIAL WITH ERRORS

**Justification:**
7 of 8 scripts failed. Results may be incomplete.

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
- **Original Paper:** `/Users/dyanag/auto-policy-evals/papers/apep_0075/paper.pdf`
