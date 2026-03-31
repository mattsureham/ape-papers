## 04_robustness.R — Robustness checks
## apep_1220: Denmark Property Tax Reform and Housing Market Lock-in

source("00_packages.R")

data_dir <- "../data"

panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))
dose <- readRDS(file.path(data_dir, "treatment_dose.rds"))

# Analysis sample
analysis <- panel %>%
  filter(year >= 2016, year <= 2025) %>%
  filter(!is.na(dose_pct_change)) %>%
  filter(!is.na(total_property_tax_1000kr))

# ============================================================
# 1. Alternative treatment measures
# ============================================================

cat("=== Robustness 1: Alternative treatment measures ===\n")

# Use absolute change in grundskyld instead of percentage
m_abs <- feols(log_total_tax ~ dose_abs_change:post |
                 municipality + year, data = analysis,
               cluster = ~municipality)
cat("Absolute dose:\n")
print(summary(m_abs))

# Use 2023 grundskyld level as treatment intensity
analysis <- analysis %>%
  mutate(dose_level = gs_2023)

m_level <- feols(log_total_tax ~ dose_level:post |
                   municipality + year, data = analysis,
                 cluster = ~municipality)
cat("2023 level as dose:\n")
print(summary(m_level))

# Forced sales with alternative doses
analysis_fs <- panel %>%
  filter(year >= 2016, year <= 2025) %>%
  filter(!is.na(dose_pct_change)) %>%
  filter(!is.na(forced_sales))

m_fs_abs <- feols(forced_sales ~ dose_abs_change:post |
                    municipality + year, data = analysis_fs,
                  cluster = ~municipality)
cat("Forced sales (absolute dose):\n")
print(summary(m_fs_abs))

m_fs_level <- feols(forced_sales ~ gs_2023:post |
                      municipality + year, data = analysis_fs %>%
                      filter(!is.na(gs_2023)),
                    cluster = ~municipality)
cat("Forced sales (2023 level dose):\n")
print(summary(m_fs_level))

# ============================================================
# 2. Placebo reform year (2020)
# ============================================================

cat("\n=== Robustness 2: Placebo reform at 2020 ===\n")

pre_only <- analysis %>%
  filter(year <= 2023) %>%
  mutate(placebo_post = as.integer(year >= 2020))

m_placebo_tax <- feols(log_total_tax ~ dose_pct_change:placebo_post |
                         municipality + year, data = pre_only,
                       cluster = ~municipality)
cat("Placebo reform 2020 (tax):\n")
print(summary(m_placebo_tax))

m_placebo_fs <- feols(forced_sales ~ dose_pct_change:placebo_post |
                        municipality + year,
                      data = panel %>%
                        filter(year >= 2016, year <= 2023) %>%
                        filter(!is.na(dose_pct_change), !is.na(forced_sales)) %>%
                        mutate(placebo_post = as.integer(year >= 2020)),
                      cluster = ~municipality)
cat("Placebo reform 2020 (forced sales):\n")
print(summary(m_placebo_fs))

# ============================================================
# 3. Different pre-period windows
# ============================================================

cat("\n=== Robustness 3: Different pre-period windows ===\n")

# Short window: 2020-2025
short <- panel %>%
  filter(year >= 2020, year <= 2025) %>%
  filter(!is.na(dose_pct_change), !is.na(total_property_tax_1000kr))

m_short <- feols(log_total_tax ~ dose_pct_change:post |
                   municipality + year, data = short,
                 cluster = ~municipality)
cat("Short window (2020-2025):\n")
print(summary(m_short))

# Long window: 2007-2025
long <- panel %>%
  filter(year >= 2007, year <= 2025) %>%
  filter(!is.na(dose_pct_change), !is.na(total_property_tax_1000kr))

m_long <- feols(log_total_tax ~ dose_pct_change:post |
                  municipality + year, data = long,
                cluster = ~municipality)
cat("Long window (2007-2025):\n")
print(summary(m_long))

# ============================================================
# 4. Top vs bottom tercile comparison
# ============================================================

cat("\n=== Robustness 4: Tercile comparison ===\n")

# Split municipalities into terciles by dose
dose_terciles <- dose %>%
  filter(!is.na(dose_pct_change)) %>%
  mutate(tercile = ntile(dose_pct_change, 3))

analysis_tercile <- analysis %>%
  left_join(dose_terciles %>% select(municipality, tercile),
            by = "municipality") %>%
  filter(!is.na(tercile))

# Compare top tercile (biggest cuts) to bottom tercile (smallest cuts)
extreme <- analysis_tercile %>%
  filter(tercile %in% c(1, 3)) %>%
  mutate(high_dose = as.integer(tercile == 1))  # tercile 1 = most negative = biggest cut

m_tercile_tax <- feols(log_total_tax ~ high_dose:post |
                         municipality + year, data = extreme,
                       cluster = ~municipality)
cat("Tercile comparison (tax):\n")
print(summary(m_tercile_tax))

# Forced sales tercile
extreme_fs <- panel %>%
  filter(year >= 2016, year <= 2025) %>%
  filter(!is.na(dose_pct_change), !is.na(forced_sales)) %>%
  left_join(dose_terciles %>% select(municipality, tercile),
            by = "municipality") %>%
  filter(tercile %in% c(1, 3)) %>%
  mutate(high_dose = as.integer(tercile == 1))

m_tercile_fs <- feols(forced_sales ~ high_dose:post |
                        municipality + year, data = extreme_fs,
                      cluster = ~municipality)
cat("Tercile comparison (forced sales):\n")
print(summary(m_tercile_fs))

# ============================================================
# 5. Wild cluster bootstrap (small N inference)
# ============================================================

cat("\n=== Robustness 5: Wild cluster bootstrap ===\n")

# 98 clusters is OK but let's check with wild bootstrap
# Using the fwildclusterboot package if available

if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  m1_main <- feols(log_total_tax ~ dose_pct_change:post |
                     municipality + year, data = analysis,
                   cluster = ~municipality)

  boot_result <- tryCatch({
    boottest(m1_main, param = "dose_pct_change:post",
             clustid = ~municipality, B = 999, type = "mammen")
  }, error = function(e) {
    cat(sprintf("  Bootstrap error: %s\n", e$message))
    NULL
  })

  if (!is.null(boot_result)) {
    cat("Wild cluster bootstrap (log tax):\n")
    print(summary(boot_result))
  }
} else {
  cat("  fwildclusterboot not installed, skipping\n")
  cat("  (98 clusters should be adequate for cluster-robust inference)\n")
}

# ============================================================
# Save robustness results
# ============================================================

saveRDS(list(
  m_abs = m_abs,
  m_level = m_level,
  m_fs_abs = m_fs_abs,
  m_fs_level = m_fs_level,
  m_placebo_tax = m_placebo_tax,
  m_placebo_fs = m_placebo_fs,
  m_short = m_short,
  m_long = m_long,
  m_tercile_tax = m_tercile_tax,
  m_tercile_fs = m_tercile_fs
), file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
