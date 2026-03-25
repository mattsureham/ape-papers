# 03_main_analysis.R — Primary Regressions for apep_0892
# Moldova Wine Embargo: Bartik Shift-Share DiD

source("00_packages.R")
library(fixest)    # Primary estimation
library(data.table)

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
panel[, ym := as.Date(ym)]

# ═══════════════════════════════════════════════════════════════════════
# 1. Summary Statistics
# ═══════════════════════════════════════════════════════════════════════
cat("=== Summary Statistics ===\n")

# Pre-treatment means by high/low wine groups
pre <- panel[post == 0]
pre_stats <- pre[, .(
  mean_radiance = mean(mean, na.rm = TRUE),
  sd_radiance = sd(mean, na.rm = TRUE),
  mean_log = mean(log_mean, na.rm = TRUE),
  n = .N
), by = high_wine]

cat("Pre-treatment nightlight means:\n")
print(pre_stats)

# Overall pre-treatment SD of outcome (for SDE calculation)
pre_sd_mean <- sd(pre$mean, na.rm = TRUE)
pre_sd_log <- sd(pre$log_mean, na.rm = TRUE)
cat("\nPre-treatment SD(mean radiance):", round(pre_sd_mean, 4), "\n")
cat("Pre-treatment SD(log mean radiance):", round(pre_sd_log, 4), "\n")

# ═══════════════════════════════════════════════════════════════════════
# 2. Main Specification: Continuous Treatment (Bartik)
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Main Specification: Continuous Bartik ===\n")

# Y_rt = α_r + γ_t + β(VineShare_r × Post_t) + ε_rt
# Clustered at raion level

# Specification 1: Level outcome
m1 <- feols(mean ~ vine_per_cap:post | raion + ym_fe,
            data = panel, cluster = ~raion)

# Specification 2: Log outcome
m2 <- feols(log_mean ~ vine_per_cap:post | raion + ym_fe,
            data = panel, cluster = ~raion)

# Specification 3: Binary treatment (above-median)
m3 <- feols(mean ~ high_wine:post | raion + ym_fe,
            data = panel, cluster = ~raion)

# Specification 4: Log outcome, binary treatment
m4 <- feols(log_mean ~ high_wine:post | raion + ym_fe,
            data = panel, cluster = ~raion)

cat("Model 1 (levels, continuous):\n")
summary(m1)
cat("\nModel 2 (log, continuous):\n")
summary(m2)
cat("\nModel 3 (levels, binary):\n")
summary(m3)
cat("\nModel 4 (log, binary):\n")
summary(m4)

# ═══════════════════════════════════════════════════════════════════════
# 3. Event Study (Continuous Treatment)
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Event Study ===\n")

# Create event-time bins (bimonthly for cleaner display)
# Reference: month -1 (August 2013, last pre-treatment)
panel[, event_bin := floor(event_month / 2) * 2]

# Trim to reasonable event window: -20 to +24 months
panel_es <- panel[event_month >= -20 & event_month <= 24]

# Set reference period: event_bin = -2 (the bin containing month -1)
panel_es[, event_bin_f := factor(event_bin)]
panel_es[, event_bin_f := relevel(event_bin_f, ref = as.character(-2))]

# Event study: interact bimonthly bins with vineyard share
es_model <- feols(log_mean ~ i(event_bin, vine_per_cap, ref = -2) | raion + ym_fe,
                  data = panel_es, cluster = ~raion)

cat("Event study coefficients:\n")
summary(es_model)

# Save event study coefficients for table
es_coefs <- as.data.table(coeftable(es_model), keep.rownames = TRUE)
setnames(es_coefs, c("term", "estimate", "se", "tstat", "pvalue"))
fwrite(es_coefs, file.path(data_dir, "event_study_coefs.csv"))

# ═══════════════════════════════════════════════════════════════════════
# 4. Short-Run vs. Medium-Run Effects
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Short-Run vs. Medium-Run ===\n")

# Short-run: Sept 2013 - May 2014 (pre-EU Association Agreement)
# Medium-run: June 2014 - Dec 2016 (EU agreement + adjustment)
# Long-run: 2017-2024

panel[, period := fcase(
  ym < as.Date("2013-09-01"), "pre",
  ym >= as.Date("2013-09-01") & ym < as.Date("2014-06-01"), "short_run",
  ym >= as.Date("2014-06-01") & ym < as.Date("2017-01-01"), "medium_run",
  ym >= as.Date("2017-01-01"), "long_run"
)]

panel[, short_run := as.integer(period == "short_run")]
panel[, medium_run := as.integer(period == "medium_run")]
panel[, long_run := as.integer(period == "long_run")]

m_periods <- feols(log_mean ~ vine_per_cap:short_run +
                     vine_per_cap:medium_run +
                     vine_per_cap:long_run | raion + ym_fe,
                   data = panel, cluster = ~raion)

cat("Period-specific effects:\n")
summary(m_periods)

# ═══════════════════════════════════════════════════════════════════════
# 5. Wild Cluster Bootstrap (given 37 clusters)
# ═══════════════════════════════════════════════════════════════════════
cat("\n=== Wild Cluster Bootstrap ===\n")

# Use Webb weights for small number of clusters
set.seed(42)

# Bootstrap function for the main coefficient
boot_fn <- function(data, indices) {
  # Resample raions (cluster bootstrap)
  raion_ids <- unique(data$raion_id)
  boot_raions <- raion_ids[indices]

  # Build bootstrap sample
  boot_data <- data.table()
  for (i in seq_along(boot_raions)) {
    rd <- data[raion_id == boot_raions[i]]
    rd_copy <- copy(rd)
    rd_copy[, boot_raion := i]
    boot_data <- rbind(boot_data, rd_copy)
  }

  tryCatch({
    fit <- feols(log_mean ~ vine_per_cap:post | boot_raion + ym_fe,
                 data = boot_data, cluster = ~boot_raion)
    coef(fit)[1]
  }, error = function(e) NA_real_)
}

# Pairs cluster bootstrap
n_boot <- 999
boot_coefs <- numeric(n_boot)
raion_ids <- unique(panel$raion_id)
n_raions <- length(raion_ids)

for (b in 1:n_boot) {
  boot_sample <- sample(raion_ids, n_raions, replace = TRUE)
  boot_data <- data.table()
  for (i in seq_along(boot_sample)) {
    rd <- panel[raion_id == boot_sample[i]]
    rd_copy <- copy(rd)
    rd_copy[, boot_raion := i]
    boot_data <- rbind(boot_data, rd_copy)
  }
  tryCatch({
    fit <- feols(log_mean ~ vine_per_cap:post | boot_raion + ym_fe,
                 data = boot_data, cluster = ~boot_raion)
    boot_coefs[b] <- coef(fit)[1]
  }, error = function(e) {
    boot_coefs[b] <<- NA_real_
  })
}

boot_coefs <- boot_coefs[!is.na(boot_coefs)]
boot_se <- sd(boot_coefs)
boot_ci <- quantile(boot_coefs, c(0.025, 0.975))
boot_pval <- 2 * min(mean(boot_coefs >= 0), mean(boot_coefs <= 0))

cat("Main coefficient (analytic):", round(coef(m2)[1], 4), "\n")
cat("Analytic SE:", round(se(m2)[1], 4), "\n")
cat("Bootstrap SE:", round(boot_se, 4), "\n")
cat("Bootstrap 95% CI: [", round(boot_ci[1], 4), ",", round(boot_ci[2], 4), "]\n")
cat("Bootstrap p-value:", round(boot_pval, 4), "\n")

# ═══════════════════════════════════════════════════════════════════════
# 6. Save Diagnostics
# ═══════════════════════════════════════════════════════════════════════

n_treated <- sum(unique(panel[, .(raion, high_wine)])$high_wine)
n_pre <- length(unique(panel[post == 0, ym]))

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_raions = length(unique(panel$raion)),
  n_months = length(unique(panel$ym)),
  pre_sd_mean = pre_sd_mean,
  pre_sd_log = pre_sd_log,
  main_coef = coef(m2)[1],
  main_se = se(m2)[1],
  boot_se = boot_se,
  boot_ci_lo = boot_ci[1],
  boot_ci_hi = boot_ci[2],
  boot_pval = boot_pval
)

jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE, pretty = TRUE)

cat("\nDiagnostics saved.\n")

# Save key model objects for tables
save(m1, m2, m3, m4, m_periods, es_model,
     pre_sd_mean, pre_sd_log, boot_se, boot_ci, boot_pval,
     file = file.path(data_dir, "main_models.RData"))

cat("=== Main Analysis Complete ===\n")
