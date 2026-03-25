## 03_main_analysis.R — Main DiD estimation
## apep_0942: Dominican Republic MIPYME Procurement Set-Asides

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "panel.rds"))

## ============================================================
## 1. Summary statistics table
## ============================================================

# Pre-period means by treatment intensity tercile
treatment <- readRDS(file.path(data_dir, "treatment.rds"))
panel_t <- merge(panel, treatment[, .(agency, delta_mipyme)], by = "agency", suffixes = c("", ".dup"))
panel_t[, delta_mipyme := delta_mipyme.dup]
panel_t[, delta_mipyme.dup := NULL]

# Wait — delta_mipyme already exists in panel. Let me just use it.
panel[, tercile := cut(delta_mipyme,
                       breaks = quantile(delta_mipyme, probs = c(0, 1/3, 2/3, 1), na.rm = TRUE),
                       labels = c("Low shift", "Medium shift", "High shift"),
                       include.lowest = TRUE)]

pre_stats <- panel[post == 0, .(
  n_agencies = uniqueN(agency),
  mean_processes = mean(n_processes),
  mean_suppliers = mean(n_unique_suppliers),
  mean_hhi = mean(hhi, na.rm = TRUE),
  mean_first_time = mean(share_first_time, na.rm = TRUE),
  mean_mipyme_share = mean(mipyme_share)
), by = tercile]

cat("=== Pre-Period Means by Treatment Intensity Tercile ===\n")
print(pre_stats)

## ============================================================
## 2. Main specification: continuous treatment DiD
## ============================================================

# Outcome 1: Log unique suppliers
m1 <- feols(log_suppliers ~ delta_mipyme:post | agency + yq,
            data = panel, cluster = ~agency)

# Outcome 2: HHI (concentration)
m2 <- feols(hhi ~ delta_mipyme:post | agency + yq,
            data = panel, cluster = ~agency)

# Outcome 3: Share first-time winners
m3 <- feols(share_first_time ~ delta_mipyme:post | agency + yq,
            data = panel, cluster = ~agency)

# Outcome 4: Share new firms (created after 2020)
m4 <- feols(share_new_firm ~ delta_mipyme:post | agency + yq,
            data = panel, cluster = ~agency)

# Outcome 5: Share MIPYME-certified suppliers among winners
m5 <- feols(share_mipyme_supplier ~ delta_mipyme:post | agency + yq,
            data = panel, cluster = ~agency)

cat("\n=== Main Results ===\n")
etable(m1, m2, m3, m4, m5,
       headers = c("Log Suppliers", "HHI", "First-Time", "New Firm", "MIPYME Supplier"),
       se.below = TRUE)

## ============================================================
## 3. Pre-trend test: interact treatment with year indicators
## ============================================================

panel[, year_factor := factor(year)]
# Omit 2019 as reference (last full pre-treatment year)
panel[, year_rel := relevel(year_factor, ref = "2019")]

m_event <- feols(log_suppliers ~ i(year_factor, delta_mipyme, ref = "2019") | agency + yq,
                 data = panel, cluster = ~agency)

cat("\n=== Event Study (Log Suppliers) ===\n")
print(summary(m_event))

## ============================================================
## 4. Alternative: binary treatment (above/below median shift)
## ============================================================

panel[, high_shift := as.integer(delta_mipyme > median(delta_mipyme, na.rm = TRUE))]

m_binary <- feols(log_suppliers ~ high_shift:post | agency + yq,
                  data = panel, cluster = ~agency)

cat("\n=== Binary Treatment (Above-Median Shift) ===\n")
print(summary(m_binary))

## ============================================================
## 5. First stage: MIPYME share response
## ============================================================

m_fs <- feols(mipyme_share ~ delta_mipyme:post | agency + yq,
              data = panel, cluster = ~agency)

cat("\n=== First Stage: MIPYME Share ===\n")
print(summary(m_fs))

## ============================================================
## 6. Save results
## ============================================================

results <- list(
  main = list(m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5),
  event = m_event,
  binary = m_binary,
  first_stage = m_fs,
  pre_stats = pre_stats
)

saveRDS(results, file.path(data_dir, "results.rds"))

## ============================================================
## 7. Write diagnostics.json for validator
## ============================================================

diag <- list(
  n_treated = uniqueN(panel$agency[panel$delta_mipyme > 0]),
  n_pre = length(unique(panel$yq[panel$post == 0])),
  n_obs = nrow(panel)
)
jsonlite::write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\nDiagnostics:", paste(names(diag), unlist(diag), sep = "=", collapse = ", "), "\n")
cat("Main analysis complete.\n")
