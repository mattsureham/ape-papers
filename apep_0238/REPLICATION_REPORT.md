# Replication Report

**Paper ID:** apep_0238
**Title:** Demand Recessions Scar, Supply Recessions Don't:\\ Evidence from State Labor Markets
**Replication Date:** 2026-02-12
**Replicator:** Claude Code

---

## Summary

**Classification:** PARTIAL REPLICATION

**Overall Assessment:**
All scripts executed successfully. Visual inspection of outputs required for full verification.

### Execution Summary

- **Total Scripts:** 7
- **Successful:** 7
- **Failed:** 0

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

**R Scripts:** 0
**Python Scripts:** 7
**Main Script:** None

| Script | Language |
|--------|----------|
| `00_packages.py` | Python |
| `01_fetch_data.py` | Python |
| `02_clean_data.py` | Python |
| `03_main_analysis.py` | Python |
| `05_model.py` | Python |
| `06_figures.py` | Python |
| `08_tables.py` | Python |

---

## 3. Execution Results

| Script | Success | Duration | Exit Code |
|--------|---------|----------|-----------|
| `00_packages.py` | Yes | 0.9s | 0 |
| `01_fetch_data.py` | Yes | 256.0s | 0 |
| `02_clean_data.py` | Yes | 3.1s | 0 |
| `03_main_analysis.py` | Yes | 0.6s | 0 |
| `05_model.py` | Yes | 0.6s | 0 |
| `06_figures.py` | Yes | 2.4s | 0 |
| `08_tables.py` | Yes | 0.6s | 0 |

---

## 4. Figure Comparisons

| Figure | Original | Generated | Status |
|--------|----------|-----------|--------|
| `fig9_cross_recession_comparison.pdf` | Yes | Yes | Visual inspection required |
| `fig8_jolts_decomposition.pdf` | Yes | Yes | Visual inspection required |
| `fig4_lp_ur_lfpr.pdf` | Yes | Yes | Visual inspection required |
| `fig2_aggregate_paths.pdf` | Yes | Yes | Visual inspection required |
| `fig11_welfare_decomposition.pdf` | Yes | Yes | Visual inspection required |
| `fig7_counterfactuals.pdf` | Yes | Yes | Visual inspection required |
| `fig10_recovery_speed_maps.pdf` | Yes | Yes | Visual inspection required |
| `fig3_lp_employment_irfs.pdf` | Yes | Yes | Visual inspection required |
| `fig6_model_vs_data.pdf` | Yes | Yes | Visual inspection required |
| `fig5_scatter_exposure.pdf` | Yes | Yes | Visual inspection required |
| `fig1_maps_recession_severity.pdf` | Yes | Yes | Visual inspection required |

---

## 5. Classification

### Final Classification: PARTIAL REPLICATION

**Justification:**
All scripts executed successfully. Visual inspection of outputs required for full verification.

---

## 6. Next Steps

1. Visually compare generated figures to published figures
2. Compare table values
3. Verify in-text numbers
4. Update classification to FULL if all match

---

## Appendix: File Locations

- **Execution Log:** `logs/execution.log`
- **Generated Figures:** `figures/`
- **Generated Tables:** `tables/`
- **Original Paper:** `/Users/dyanag/auto-policy-evals/papers/apep_0238/paper.pdf`
