## 03_main_analysis.R — Main results for apep_1291
## Border-county DiD: Nebraska deregulation and farm consolidation

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
border_panel <- readRDS("../data/border_panel.rds")

cat("=== Main Analysis: Border-County DiD ===\n")

# ---- Table 1: Summary Statistics ----
cat("Computing summary statistics...\n")

sumstats <- border_panel |>
  group_by(treat_label = ifelse(in_nebraska, "Nebraska (treated)", "Neighbors (control)")) |>
  summarise(
    n_county_years = n(),
    n_counties = n_distinct(fips),
    mean_farms = mean(n_farms, na.rm = TRUE),
    sd_farms = sd(n_farms, na.rm = TRUE),
    mean_avg_size = mean(avg_farm_size, na.rm = TRUE),
    sd_avg_size = sd(avg_farm_size, na.rm = TRUE),
    mean_land = mean(land_acres, na.rm = TRUE),
    sd_land = sd(land_acres, na.rm = TRUE),
    mean_share_large = mean(share_large, na.rm = TRUE),
    sd_share_large = sd(share_large, na.rm = TRUE),
    mean_dist_km = mean(dist_to_ne_border_km, na.rm = TRUE),
    .groups = "drop"
  )
print(sumstats)

# Save summary stats for tables
saveRDS(sumstats, "../data/sumstats.rds")

# Record unconditional SDs for SDE computation
sd_farms <- sd(border_panel$n_farms, na.rm = TRUE)
sd_avg_size <- sd(border_panel$avg_farm_size, na.rm = TRUE)
sd_share_large <- sd(border_panel$share_large, na.rm = TRUE)
sd_log_farms <- sd(log(border_panel$n_farms + 1), na.rm = TRUE)

cat(sprintf("\nUnconditional SDs: farms=%.1f, avg_size=%.1f, share_large=%.4f\n",
            sd_farms, sd_avg_size, sd_share_large))

# ---- Main regressions: Border-county DiD ----

# Prepare data
bp <- border_panel |>
  mutate(
    log_farms = log(n_farms + 1),
    log_avg_size = log(avg_farm_size + 1),
    fips_fe = factor(fips),
    year_fe = factor(year)
  )

cat("\n--- Model 1: Number of farms (levels) ---\n")
m1 <- feols(n_farms ~ treat_post | fips + year, data = bp, cluster = ~STUSPS)
summary(m1)

cat("\n--- Model 2: Log number of farms ---\n")
m2 <- feols(log_farms ~ treat_post | fips + year, data = bp, cluster = ~STUSPS)
summary(m2)

cat("\n--- Model 3: Average farm size (acres) ---\n")
m3 <- feols(avg_farm_size ~ treat_post | fips + year, data = bp, cluster = ~STUSPS)
summary(m3)

cat("\n--- Model 4: Share of large farms (1000+ acres) ---\n")
# Share_large has sparse coverage across years; restrict to years with sufficient data
bp_size <- bp |> filter(!is.na(share_large))
cat(sprintf("  share_large obs available: %d of %d\n", nrow(bp_size), nrow(bp)))
m4 <- NULL
if (nrow(bp_size) > 20 && n_distinct(bp_size$year[bp_size$post == 0]) >= 1 &&
    n_distinct(bp_size$year[bp_size$post == 1]) >= 1) {
  m4 <- tryCatch(
    feols(share_large ~ treat_post | fips + year, data = bp_size, cluster = ~STUSPS),
    error = function(e) { cat("  share_large model failed:", e$message, "\n"); NULL }
  )
  if (!is.null(m4)) summary(m4)
} else {
  cat("  Insufficient share_large data for estimation\n")
}

cat("\n--- Model 5: Land in farms (acres) ---\n")
m5 <- feols(land_acres ~ treat_post | fips + year, data = bp, cluster = ~STUSPS)
summary(m5)

# ---- Wider bandwidth samples ----
cat("\n=== Bandwidth Sensitivity ===\n")

bw_results <- list()
for (bw in c(50, 100, 150)) {
  bw_data <- panel |>
    filter(dist_to_ne_border_km <= bw) |>
    mutate(log_farms = log(n_farms + 1))

  m_bw <- feols(avg_farm_size ~ treat_post | fips + year,
                data = bw_data, cluster = ~STUSPS)
  bw_results[[as.character(bw)]] <- m_bw
  cat(sprintf("  BW=%dkm: β=%.1f (SE=%.1f), N=%d counties\n",
              bw, coef(m_bw)["treat_post"], se(m_bw)["treat_post"],
              n_distinct(bw_data$fips)))
}

# ---- Event study specification ----
cat("\n=== Event Study ===\n")

# Create year dummies interacted with treatment
# Omit 2007 (last pre-treatment Census)
# Include all available Census years (1987-2022)
available_years <- sort(unique(bp$year))
es_years <- setdiff(available_years, 2007)  # all years except omitted base
cat(sprintf("Event study years: %s (omit 2007)\n", paste(es_years, collapse = ", ")))

bp_es <- bp
for (yr in es_years) {
  bp_es[[paste0("yr_", yr)]] <- as.integer(bp_es$year == yr) * bp_es$treat
}

es_formula_farms <- as.formula(paste("log_farms ~",
  paste(paste0("yr_", es_years), collapse = " + "), "| fips + year"))
es_formula_size <- as.formula(paste("avg_farm_size ~",
  paste(paste0("yr_", es_years), collapse = " + "), "| fips + year"))
es_formula_share <- as.formula(paste("share_large ~",
  paste(paste0("yr_", es_years), collapse = " + "), "| fips + year"))

m_es_farms <- feols(es_formula_farms, data = bp_es, cluster = ~STUSPS)
cat("Event study (log farms):\n")
summary(m_es_farms)

m_es_size <- feols(es_formula_size, data = bp_es, cluster = ~STUSPS)
cat("Event study (avg farm size):\n")
summary(m_es_size)

m_es_share <- tryCatch(
  feols(es_formula_share, data = bp_es |> filter(!is.na(share_large)), cluster = ~STUSPS),
  error = function(e) { cat("Event study share_large failed:", e$message, "\n"); NULL }
)
if (!is.null(m_es_share)) {
  cat("Event study (share large):\n")
  summary(m_es_share)
}

# ---- Save all model objects ----
models <- list(
  m1_farms = m1, m2_log_farms = m2, m3_avg_size = m3,
  m4_share_large = m4,  # may be NULL if data insufficient
  m5_land = m5,
  bw_results = bw_results,
  es_farms = m_es_farms, es_size = m_es_size, es_share = m_es_share
)
saveRDS(models, "../data/models.rds")

# ---- Diagnostics for validator ----
cat("\n=== Writing diagnostics.json ===\n")

diagnostics <- list(
  n_treated = n_distinct(bp$fips[bp$treat == 1]),
  n_control = n_distinct(bp$fips[bp$treat == 0]),
  n_pre = length(unique(bp$year[bp$year <= 2007])),  # all Census years through 2007
  n_post = length(unique(bp$year[bp$year >= 2012])),  # 2012, 2017, 2022
  n_obs = nrow(bp),
  n_counties = n_distinct(bp$fips),
  sd_farms = sd_farms,
  sd_avg_size = sd_avg_size,
  sd_share_large = sd_share_large,
  sd_log_farms = sd_log_farms,
  treatment_year = 2007
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat(sprintf("Diagnostics: %d treated, %d control, %d pre, %d post, %d obs\n",
            diagnostics$n_treated, diagnostics$n_control,
            diagnostics$n_pre, diagnostics$n_post, diagnostics$n_obs))
cat("\n=== Main analysis complete ===\n")
