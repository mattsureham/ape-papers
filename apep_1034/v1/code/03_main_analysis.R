## 03_main_analysis.R — Main DiD estimation
## apep_1034: Norway Wind Resource Rent Tax

source("00_packages.R")
library(fixest)

# ============================================================
# Load analysis panels
# ============================================================
monthly_panel <- readRDS("../data/monthly_panel.rds")
county_panel <- readRDS("../data/county_panel.rds")
pre_stats <- readRDS("../data/pre_stats.rds")

# ============================================================
# 1. Main specification: National monthly Wind vs Hydro DiD
# ============================================================
cat("=== MAIN SPECIFICATION: Monthly Wind vs Hydro DiD ===\n\n")

# Specification 1: Simple DiD (levels)
m1 <- feols(gwh ~ treat | sector + date, data = monthly_panel)
cat("Model 1: DiD in levels (GWh)\n")
summary(m1)

# Specification 2: DiD in logs
m2 <- feols(log_gwh ~ treat | sector + date, data = monthly_panel)
cat("\nModel 2: DiD in logs\n")
summary(m2)

# Specification 3: DiD with sector-specific trends
monthly_panel <- monthly_panel %>%
  mutate(ym_trend = as.numeric(date - min(date)) / 365.25)

m3 <- feols(log_gwh ~ treat + wind:ym_trend | sector + date, data = monthly_panel)
cat("\nModel 3: DiD in logs with sector-specific linear trends\n")
summary(m3)

# ============================================================
# 2. Event study specification
# ============================================================
cat("\n=== EVENT STUDY ===\n")

# Create event-time indicators (relative to Dec 2022)
# Bin endpoints at -24 and +24
monthly_panel <- monthly_panel %>%
  mutate(
    event_time = month_idx,
    event_time_binned = pmax(pmin(event_time, 24), -24)
  )

# Event study with month-level event time
# Reference period: month -1 (Nov 2022, just before announcement)
es_model <- feols(
  log_gwh ~ i(event_time_binned, wind, ref = -1) | sector + date,
  data = monthly_panel
)

cat("Event study model:\n")
summary(es_model)

# Extract event study coefficients for the table
es_coefs <- as.data.frame(coeftable(es_model))
es_coefs$term <- rownames(es_coefs)
es_wind <- es_coefs[grep("wind", es_coefs$term), ]

cat(sprintf("\nEvent study: %d coefficients estimated\n", nrow(es_wind)))

# ============================================================
# 3. County-level DiD (geographic variation)
# ============================================================
cat("\n=== COUNTY-LEVEL DiD ===\n")

# County DiD with county x sector and year FE
m_county <- feols(
  log_gwh ~ treat | county_sector + year,
  data = county_panel,
  cluster = ~region_code
)
cat("County DiD (clustered by county):\n")
summary(m_county)

# ============================================================
# 4. Wild cluster bootstrap (essential with ~10-15 clusters)
# ============================================================
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

# For county-level regression with small clusters
n_counties <- length(unique(county_panel$region_code))
cat(sprintf("Number of county clusters: %d\n", n_counties))

# Wild cluster bootstrap using fwildclusterboot
tryCatch({
  boot_county <- fwildclusterboot::boottest(
    m_county,
    param = "treat",
    clustid = ~region_code,
    B = 9999,
    type = "rademacher",
    impose_null = TRUE
  )
  cat("Wild cluster bootstrap result:\n")
  print(summary(boot_county))
  boot_p <- boot_county$p_val
  boot_ci <- c(boot_county$conf_int[1], boot_county$conf_int[2])
  cat(sprintf("  Bootstrap p-value: %.4f\n", boot_p))
  cat(sprintf("  Bootstrap 95%% CI: [%.4f, %.4f]\n", boot_ci[1], boot_ci[2]))
}, error = function(e) {
  cat(sprintf("  Wild cluster bootstrap error: %s\n", e$message))
  cat("  Proceeding with cluster-robust SEs only.\n")
  boot_p <<- NA
  boot_ci <<- c(NA, NA)
})

# ============================================================
# 5. Extract key estimates for tables and SDE
# ============================================================

# Main estimate (log specification, national monthly)
beta_main <- coef(m2)["treat"]
se_main <- se(m2)["treat"]

# Pre-treatment SD of log(GWh) for wind sector
sd_y_wind <- pre_stats$pre_sd_log[pre_stats$sector == "wind"]

cat("\n=== KEY ESTIMATES ===\n")
cat(sprintf("Main DiD (log): beta = %.4f, SE = %.4f\n", beta_main, se_main))
cat(sprintf("Pre-treatment SD(log GWh, wind): %.4f\n", sd_y_wind))
cat(sprintf("SDE = beta / SD(Y) = %.4f\n", beta_main / sd_y_wind))
cat(sprintf("Interpretation: %.1f%% change in wind production relative to hydro\n",
            (exp(beta_main) - 1) * 100))

# County estimate
beta_county <- coef(m_county)["treat"]
se_county <- se(m_county)["treat"]

# ============================================================
# 6. Write diagnostics.json
# ============================================================
n_treated_months <- sum(monthly_panel$wind == 1 & monthly_panel$post == 1)
n_pre_months <- length(unique(monthly_panel$date[monthly_panel$post == 0]))
n_obs_total <- nrow(monthly_panel)
n_county_treated <- sum(county_panel$wind == 1 & county_panel$post == 1)

diagnostics <- list(
  n_treated = as.integer(n_treated_months),
  n_pre = as.integer(n_pre_months),
  n_obs = as.integer(n_obs_total),
  n_county_clusters = as.integer(n_counties),
  n_county_treated = as.integer(n_county_treated),
  beta_main = round(beta_main, 6),
  se_main = round(se_main, 6),
  beta_county = round(beta_county, 6),
  se_county = round(se_county, 6)
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nDiagnostics written to data/diagnostics.json\n")

# ============================================================
# Save model objects
# ============================================================
saveRDS(list(
  m1 = m1, m2 = m2, m3 = m3,
  es_model = es_model,
  m_county = m_county,
  beta_main = beta_main, se_main = se_main,
  beta_county = beta_county, se_county = se_county,
  sd_y_wind = sd_y_wind,
  boot_p = if (exists("boot_p")) boot_p else NA,
  boot_ci = if (exists("boot_ci")) boot_ci else c(NA, NA)
), "../data/model_results.rds")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
