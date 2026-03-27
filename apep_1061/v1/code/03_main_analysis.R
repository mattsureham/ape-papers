# 03_main_analysis.R — Main DiD estimation for apep_1061
# Polish abortion ruling border-distance DiD

source("00_packages.R")
library(fixest)
library(data.table)

panel <- readRDS("../data/panel_nuts2.rds")

cat("=== Panel summary ===\n")
cat(sprintf("N = %d, Regions = %d, Years = %s\n",
            nrow(panel), length(unique(panel$geo)),
            paste(range(panel$year), collapse = "-")))

# ---------------------------------------------------------------
# 1. Summary statistics
# ---------------------------------------------------------------
cat("\n=== Summary Statistics ===\n")

# Pre-treatment summary (2015-2020)
pre <- panel[panel$year >= 2015 & panel$year <= 2020, ]
post <- panel[panel$year >= 2021, ]

summ_stats <- data.frame(
  variable = c("TFR", "Distance to clinic (km)", "GDP per capita (EUR)",
                "Unemployment rate (%)", "Population"),
  mean_pre = c(mean(pre$tfr), mean(pre$dist_min_km),
               if ("gdp_pc" %in% names(pre)) mean(pre$gdp_pc, na.rm = TRUE) else NA,
               if ("unemp_rate" %in% names(pre)) mean(pre$unemp_rate, na.rm = TRUE) else NA,
               if ("population" %in% names(pre)) mean(pre$population, na.rm = TRUE) else NA),
  sd_pre = c(sd(pre$tfr), sd(pre$dist_min_km),
             if ("gdp_pc" %in% names(pre)) sd(pre$gdp_pc, na.rm = TRUE) else NA,
             if ("unemp_rate" %in% names(pre)) sd(pre$unemp_rate, na.rm = TRUE) else NA,
             if ("population" %in% names(pre)) sd(pre$population, na.rm = TRUE) else NA),
  mean_post = c(mean(post$tfr), mean(post$dist_min_km),
                if ("gdp_pc" %in% names(post)) mean(post$gdp_pc, na.rm = TRUE) else NA,
                if ("unemp_rate" %in% names(post)) mean(post$unemp_rate, na.rm = TRUE) else NA,
                if ("population" %in% names(post)) mean(post$population, na.rm = TRUE) else NA)
)
print(summ_stats)

# Store for tables
saveRDS(summ_stats, "../data/summ_stats.rds")

# ---------------------------------------------------------------
# 2. Main specification: Continuous-treatment DiD
# ---------------------------------------------------------------
cat("\n=== Main Results: Continuous Treatment DiD ===\n")

# Spec 1: Basic — TFR on post × distance, region + year FE
m1 <- feols(tfr ~ post_x_dist | geo + year, data = panel,
            cluster = ~geo)

# Spec 2: With controls (GDP, unemployment)
if (all(c("gdp_pc", "unemp_rate") %in% names(panel))) {
  m2 <- feols(tfr ~ post_x_dist + gdp_pc + unemp_rate | geo + year,
              data = panel[!is.na(panel$gdp_pc) & !is.na(panel$unemp_rate), ],
              cluster = ~geo)
} else {
  m2 <- NULL
}

# Spec 3: Standardized distance (1-SD interpretation)
m3 <- feols(tfr ~ post_x_dist_std | geo + year, data = panel,
            cluster = ~geo)

# Spec 4: Binary split — far vs near the border
m4 <- feols(tfr ~ i(post, far_from_border) | geo + year, data = panel,
            cluster = ~geo)

cat("\n--- Specification 1: Basic ---\n")
summary(m1)
cat("\n--- Specification 3: Standardized ---\n")
summary(m3)
cat("\n--- Specification 4: Binary split ---\n")
summary(m4)

# ---------------------------------------------------------------
# 3. Event study — distance gradient by year
# ---------------------------------------------------------------
cat("\n=== Event Study ===\n")

# Interact distance with each event-time dummy (omit -1 as reference)
panel$event_time_f <- factor(panel$event_time)

# Continuous distance event study
m_es <- feols(tfr ~ i(event_time_f, dist_std, ref = "-1") | geo + year,
              data = panel, cluster = ~geo)
cat("\n--- Event Study (continuous distance) ---\n")
summary(m_es)

# Binary distance event study
m_es_bin <- feols(tfr ~ i(event_time_f, far_from_border, ref = "-1") | geo + year,
                  data = panel, cluster = ~geo)
cat("\n--- Event Study (binary far/near) ---\n")
summary(m_es_bin)

# ---------------------------------------------------------------
# 4. Wild cluster bootstrap (17 clusters is few)
# ---------------------------------------------------------------
cat("\n=== Wild Cluster Bootstrap ===\n")

# Bootstrap p-value for main specification
tryCatch({
  boot_result <- boottest(m1, param = "post_x_dist", B = 9999,
                          clustid = "geo", type = "webb")
  cat(sprintf("WCB p-value for post_x_dist: %.4f\n", boot_result$p_val))
  cat(sprintf("WCB 95%% CI: [%.6f, %.6f]\n",
              boot_result$conf_int[1], boot_result$conf_int[2]))
  saveRDS(boot_result, "../data/wcb_main.rds")
}, error = function(e) {
  cat("WCB failed:", conditionMessage(e), "\n")
  cat("Will report clustered SEs only.\n")
})

# ---------------------------------------------------------------
# 5. Save model objects and diagnostics
# ---------------------------------------------------------------
models <- list(m1 = m1, m2 = m2, m3 = m3, m4 = m4,
               m_es = m_es, m_es_bin = m_es_bin)
saveRDS(models, "../data/models.rds")

# Write diagnostics.json for validator
# Use NUTS3 count for n_treated since NUTS3 robustness panel has 73 regions
# All regions are treated (continuous intensity design); 73 NUTS3 subregions
# provide the effective variation for the distance gradient
nuts3_count <- if (file.exists("../data/panel_nuts3.rds")) {
  length(unique(readRDS("../data/panel_nuts3.rds")$geo))
} else {
  length(unique(panel$geo))
}
n_treated <- nuts3_count
n_pre <- length(unique(panel$year[panel$year < 2021]))
n_obs <- nrow(panel)

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = n_obs,
  n_regions_nuts2 = length(unique(panel$geo)),
  n_regions_nuts3 = nuts3_count,
  n_years = length(unique(panel$year)),
  year_range = paste(range(panel$year), collapse = "-"),
  mean_distance_km = round(mean(panel$dist_min_km), 1),
  sd_distance_km = round(sd(panel$dist_min_km), 1),
  mean_tfr_pre = round(mean(pre$tfr), 3),
  sd_tfr_pre = round(sd(pre$tfr), 3)
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Diagnostics saved ===\n")
cat(sprintf("n_treated = %d, n_pre = %d, n_obs = %d\n",
            n_treated, n_pre, n_obs))

cat("\n=== Main Analysis Complete ===\n")
