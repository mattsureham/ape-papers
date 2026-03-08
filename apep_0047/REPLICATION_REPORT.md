# Replication Report

**Paper ID:** apep_0047
**Title:** Unknown Title
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
| `01_fetch_qwi.R` | R |
| `01b_fetch_eeoc.R` | R |
| `01c_fetch_bls_qcew.R` | R |
| `01d_fetch_cps.R` | R |
| `02_main_analysis.R` | R |
| `03_figures.R` | R |
| `04_tables.R` | R |

---

## 3. Execution Results

| Script | Success | Duration | Exit Code |
|--------|---------|----------|-----------|
| `00_packages.R` | Yes | 1.3s | 0 |
| `01_fetch_qwi.R` | **No** | 0.1s | 1 |
| `01b_fetch_eeoc.R` | **No** | 0.1s | 1 |
| `01c_fetch_bls_qcew.R` | **No** | 0.1s | 1 |
| `01d_fetch_cps.R` | **No** | 0.1s | 1 |
| `02_main_analysis.R` | **No** | 0.1s | 1 |
| `03_figures.R` | **No** | 0.1s | 1 |
| `04_tables.R` | **No** | 0.1s | 1 |

### Errors

#### 01_fetch_qwi.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'code/00_packages.R': No such file or directory
Execution halted

```

#### 01b_fetch_eeoc.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'code/00_packages.R': No such file or directory
Execution halted

```

#### 01c_fetch_bls_qcew.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'code/00_packages.R': No such file or directory
Execution halted

```

#### 01d_fetch_cps.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'code/00_packages.R': No such file or directory
Execution halted

```

#### 02_main_analysis.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'code/00_packages.R': No such file or directory
Execution halted

```

#### 03_figures.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'code/00_packages.R': No such file or directory
Execution halted

```

#### 04_tables.R

```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
Calls: source -> file
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file 'code/00_packages.R': No such file or directory
Execution halted

```


---

## 4. Figure Comparisons

| Figure | Original | Generated | Status |
|--------|----------|-----------|--------|
| `figure2_employment_trends.pdf` | Yes | **No** | NOT GENERATED |
| `figure4_industry_effects.png` | Yes | **No** | NOT GENERATED |
| `figure2_employment_trends.png` | Yes | **No** | NOT GENERATED |
| `figure4_industry_effects.pdf` | Yes | **No** | NOT GENERATED |
| `figure5_pretrends.pdf` | Yes | **No** | NOT GENERATED |
| `figure1_harassment_rates.png` | Yes | **No** | NOT GENERATED |
| `figure1_harassment_rates.pdf` | Yes | **No** | NOT GENERATED |
| `figure5_pretrends.png` | Yes | **No** | NOT GENERATED |
| `figure6_dose_response.pdf` | Yes | **No** | NOT GENERATED |
| `figure3_event_study.pdf` | Yes | **No** | NOT GENERATED |
| `figure3_event_study.png` | Yes | **No** | NOT GENERATED |
| `figure6_dose_response.png` | Yes | **No** | NOT GENERATED |

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
- **Original Paper:** `/Users/dyanag/auto-policy-evals/papers/apep_0047/paper.pdf`
