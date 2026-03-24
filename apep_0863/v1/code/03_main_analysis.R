## 03_main_analysis.R — Primary regressions: WFO performance → tornado casualties
## apep_0863: The Forecaster Lottery

library(data.table)
library(fixest)
library(sandwich)
library(jsonlite)

args <- commandArgs(trailingOnly = FALSE)
script_dir <- dirname(sub("--file=", "", args[grep("--file=", args)]))
if (length(script_dir) > 0) setwd(file.path(script_dir, ".."))

## ============================================================
## 1. Load analysis data
## ============================================================

analysis <- fread("data/analysis_tornado_pairs.csv")
county_year <- fread("data/county_year_panel.csv")

cat("Analysis sample:", nrow(analysis), "tornado-pair obs\n")
cat("County-year panel:", nrow(county_year), "obs\n")

# Drop observations missing key variables
analysis <- analysis[!is.na(avg_lt_overall) & !is.na(pair_id)]
cat("After dropping missing:", nrow(analysis), "obs\n")

# Create additional controls
analysis[, ef_sq := ef_scale^2]
analysis[, log_pop := log(population + 1)]
analysis[, any_casualty := as.integer(casualties > 0)]
analysis[, any_death := as.integer(deaths > 0)]
analysis[, any_injury := as.integer(injuries > 0)]

# Standardize lead time for easier interpretation
analysis[, lt_std := (avg_lt_overall - mean(avg_lt_overall, na.rm = TRUE)) /
                      sd(avg_lt_overall, na.rm = TRUE)]

## ============================================================
## 2. Primary specification: Boundary-pair FE
## ============================================================
## Key regression: casualties = f(WFO lead time) + pair FE + tornado controls
## Clustering: two-way by WFO and year

cat("\n=== PRIMARY SPECIFICATIONS ===\n\n")

# Model 1: Simple OLS — casualties on lead time
m1 <- feols(casualties ~ avg_lt_overall | 0,
            data = analysis, cluster = ~wfo + year)
cat("M1 (simple OLS):\n")
print(summary(m1))

# Model 2: Add tornado controls (EF-scale, path length, path width)
m2 <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | 0,
            data = analysis, cluster = ~wfo + year)
cat("\nM2 (+ tornado controls):\n")
print(summary(m2))

# Model 3: Boundary-pair FE (key specification)
m3 <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id,
            data = analysis, cluster = ~wfo + year)
cat("\nM3 (+ pair FE — PRIMARY):\n")
print(summary(m3))

# Model 4: Pair FE + year FE
m4 <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
            data = analysis, cluster = ~wfo + year)
cat("\nM4 (+ pair FE + year FE):\n")
print(summary(m4))

# Model 5: Add population controls
m5 <- feols(casualties ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width +
              log_pop | pair_id + year,
            data = analysis, cluster = ~wfo + year)
cat("\nM5 (+ population):\n")
print(summary(m5))


## ============================================================
## 3. Separate outcomes: injuries vs deaths
## ============================================================

cat("\n=== SEPARATE OUTCOMES ===\n\n")

# Injuries (more powered)
m_inj <- feols(injuries ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
               data = analysis, cluster = ~wfo + year)
cat("Injuries:\n")
print(summary(m_inj))

# Deaths
m_death <- feols(deaths ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                 data = analysis, cluster = ~wfo + year)
cat("\nDeaths:\n")
print(summary(m_death))

# Extensive margin: any casualty
m_any <- feols(any_casualty ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
               data = analysis, cluster = ~wfo + year)
cat("\nAny casualty (extensive margin):\n")
print(summary(m_any))


## ============================================================
## 4. Placebo: Property damage (warnings can't prevent it)
## ============================================================

cat("\n=== PLACEBO: PROPERTY DAMAGE ===\n\n")

# Log property damage (should NOT respond to warning quality)
analysis[, log_damage := log(damage_property + 1)]

m_placebo <- feols(log_damage ~ avg_lt_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
                   data = analysis, cluster = ~wfo + year)
cat("Property damage (placebo — should be null):\n")
print(summary(m_placebo))

# EF-scale placebo (should be null — tornado intensity is meteorological)
m_ef_placebo <- feols(ef_scale ~ avg_lt_overall | pair_id + year,
                      data = analysis, cluster = ~wfo + year)
cat("\nEF-scale (placebo — should be null):\n")
print(summary(m_ef_placebo))


## ============================================================
## 5. POD as alternative treatment measure
## ============================================================

cat("\n=== POD SPECIFICATION ===\n\n")

m_pod <- feols(casualties ~ avg_pod_overall + ef_scale + ef_sq + path_length + path_width | pair_id + year,
               data = analysis, cluster = ~wfo + year)
cat("POD → casualties:\n")
print(summary(m_pod))


## ============================================================
## 6. Heterogeneity: nighttime vs daytime, mobile homes
## ============================================================

cat("\n=== HETEROGENEITY ===\n\n")

# Time of day (nighttime tornadoes are more deadly)
if ("nighttime" %in% names(analysis)) {
  m_night <- feols(casualties ~ avg_lt_overall * nighttime + ef_scale + ef_sq +
                     path_length + path_width | pair_id + year,
                   data = analysis, cluster = ~wfo + year)
  cat("Nighttime interaction:\n")
  print(summary(m_night))
}

# Mobile home vulnerability
if ("mobile_share" %in% names(analysis)) {
  analysis[, high_mobile := as.integer(mobile_share > median(mobile_share, na.rm = TRUE))]
  m_mobile <- feols(casualties ~ avg_lt_overall * high_mobile + ef_scale + ef_sq +
                      path_length + path_width | pair_id + year,
                    data = analysis, cluster = ~wfo + year)
  cat("\nMobile home interaction:\n")
  print(summary(m_mobile))
}

# EF-scale intensity (stronger tornadoes = more scope for warning to help)
analysis[, strong_tornado := as.integer(ef_scale >= 2)]
m_strong <- feols(casualties ~ avg_lt_overall * strong_tornado + ef_scale + ef_sq +
                    path_length + path_width | pair_id + year,
                  data = analysis, cluster = ~wfo + year)
cat("\nStrong tornado (EF2+) interaction:\n")
print(summary(m_strong))


## ============================================================
## 7. Save results and diagnostics
## ============================================================

# Store models for table generation
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5,
  m_inj = m_inj, m_death = m_death, m_any = m_any,
  m_placebo = m_placebo, m_ef_placebo = m_ef_placebo,
  m_pod = m_pod, m_strong = m_strong
)
if (exists("m_night")) results$m_night <- m_night
if (exists("m_mobile")) results$m_mobile <- m_mobile

saveRDS(results, "data/regression_results.rds")

# Diagnostics for validation
n_pairs <- uniqueN(analysis$pair_id)
n_wfos <- uniqueN(analysis$wfo)
year_range <- range(analysis$year)

diagnostics <- list(
  n_treated = n_wfos,  # number of WFOs (treatment units)
  n_pre = as.integer(year_range[2] - year_range[1]),  # years of data
  n_obs = nrow(analysis),
  n_pairs = n_pairs,
  n_unique_tornadoes = uniqueN(analysis, by = c("fips", "year", "begin_lat", "begin_lon")),
  mean_leadtime = round(mean(analysis$avg_lt_overall, na.rm = TRUE), 2),
  sd_leadtime = round(sd(analysis$avg_lt_overall, na.rm = TRUE), 2),
  mean_casualties = round(mean(analysis$casualties, na.rm = TRUE), 4),
  sd_casualties = round(sd(analysis$casualties, na.rm = TRUE), 4)
)

write_json(diagnostics, "data/diagnostics.json", auto_unbox = TRUE)
cat("\nDiagnostics saved to data/diagnostics.json\n")

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat("Primary coefficient (M4, pair+year FE):", round(coef(m4)["avg_lt_overall"], 5), "\n")
cat("SE:", round(sqrt(vcov(m4)["avg_lt_overall", "avg_lt_overall"]), 5), "\n")
