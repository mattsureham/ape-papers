# Replication Report

**Paper ID:** apep_0084
**Title:** The Price of Distance: Cannabis Dispensary Access and the Composition of Fatal Crashes
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

**R Scripts:** 6
**Python Scripts:** 2
**Main Script:** 00_packages.R

| Script | Language |
|--------|----------|
| `00_packages.R` | R |
| `01_fetch_fars.R` | R |
| `04_build_analysis_data.R` | R |
| `05_main_analysis.R` | R |
| `06_figures.R` | R |
| `07_tables.R` | R |
| `02_fetch_dispensaries.py` | Python |
| `03_compute_driving_times.py` | Python |

---

## 3. Execution Results

| Script | Success | Duration | Exit Code |
|--------|---------|----------|-----------|
| `00_packages.R` | Yes | 149.1s | 0 |
| `01_fetch_fars.R` | **No** | 1.3s | 1 |
| `04_build_analysis_data.R` | **No** | 1.0s | 1 |
| `05_main_analysis.R` | **No** | 1.0s | 1 |
| `06_figures.R` | **No** | 1.1s | 1 |
| `07_tables.R` | **No** | 1.0s | 1 |
| `02_fetch_dispensaries.py` | **No** | 0.0s | 1 |
| `03_compute_driving_times.py` | **No** | 0.0s | 1 |

### Errors

#### 01_fetch_fars.R

```
Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 04_build_analysis_data.R

```
Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 05_main_analysis.R

```
Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 06_figures.R

```
Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 07_tables.R

```
Error: package or namespace load failed for ‘modelsummary’ in loadNamespace(i, c(lib.loc, .libPaths()), versionCheck = vI[[i]]):
 namespace ‘data.table’ 1.16.4 is already loaded, but >= 1.17.8 is required
Execution halted

```

#### 02_fetch_dispensaries.py

```
Traceback (most recent call last):
  File "/Users/dyanag/auto-policy-evals/output/replication_apep_0084/code/02_fetch_dispensaries.py", line 12, in <module>
    import pandas as pd
ModuleNotFoundError: No module named 'pandas'

```

#### 03_compute_driving_times.py

```
Traceback (most recent call last):
  File "/Users/dyanag/auto-policy-evals/output/replication_apep_0084/code/03_compute_driving_times.py", line 7, in <module>
    import numpy as np
ModuleNotFoundError: No module named 'numpy'

```


---

## 4. Figure Comparisons

| Figure | Original | Generated | Status |
|--------|----------|-----------|--------|
| `fig06_coefficient_plot.pdf` | Yes | **No** | NOT GENERATED |
| `fig07_heterogeneity_distance.pdf` | Yes | **No** | NOT GENERATED |
| `fig04_time_series.pdf` | Yes | **No** | NOT GENERATED |
| `fig02_treatment_intensity.pdf` | Yes | **No** | NOT GENERATED |
| `fig01_study_region.pdf` | Yes | **No** | NOT GENERATED |
| `fig05_border_zoom_wy_co.pdf` | Yes | **No** | NOT GENERATED |
| `fig03_binscatter.pdf` | Yes | **No** | NOT GENERATED |

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
- **Original Paper:** `/Users/dyanag/auto-policy-evals/papers/apep_0084/paper.pdf`
