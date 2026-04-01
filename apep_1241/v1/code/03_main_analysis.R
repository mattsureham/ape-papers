## 03_main_analysis.R — Main DiD estimation
## apep_1241: Animal Welfare Havens

source("00_packages.R")

# --- Load cleaned data ---
mink <- read_csv("../data/mink_panel_balanced.csv", show_col_types = FALSE)
diversion <- read_csv("../data/diversion_panel.csv", show_col_types = FALSE)

cat("Mink panel:", nrow(mink), "obs,", n_distinct(mink$reporter), "countries\n")

# ============================================================
# TABLE 1: Summary Statistics
# ============================================================

# Compute summary stats by group
summ_stats <- mink |>
  filter(commodity == "430110" | is.na(commodity)) |>
  mutate(period = ifelse(year <= 2012, "Pre-2013", "Post-2013")) |>
  group_by(country_group, period) |>
  summarise(
    n_countries = n_distinct(reporter),
    mean_exports_m = mean(export_value, na.rm = TRUE) / 1e6,
    sd_exports_m = sd(export_value, na.rm = TRUE) / 1e6,
    median_exports_m = median(export_value, na.rm = TRUE) / 1e6,
    n_obs = n(),
    .groups = "drop"
  )

cat("\n=== Summary Statistics ===\n")
print(summ_stats)

# ============================================================
# MAIN SPECIFICATION: TWFE DiD (fixest)
# ============================================================

# Restrict to EU countries for main analysis (ban + control)
eu_panel <- mink |>
  filter(country_group %in% c("ban", "control_eu"))

cat("\nEU panel:", nrow(eu_panel), "obs\n")
cat("  Ban countries:", n_distinct(eu_panel$reporter[eu_panel$country_group == "ban"]), "\n")
cat("  Control countries:", n_distinct(eu_panel$reporter[eu_panel$country_group == "control_eu"]), "\n")

# --- Main DiD: log exports on ban indicator ---
# Exclude Denmark (COVID cull is different mechanism)
eu_nodnk <- eu_panel |> filter(reporter != "dnk")

m1 <- feols(log_exports ~ banned | country_id + year,
            data = eu_nodnk,
            cluster = ~reporter)

cat("\n=== Model 1: TWFE DiD (excl. Denmark) ===\n")
summary(m1)

# --- With Denmark ---
m2 <- feols(log_exports ~ banned | country_id + year,
            data = eu_panel,
            cluster = ~reporter)

cat("\n=== Model 2: TWFE DiD (incl. Denmark) ===\n")
summary(m2)

# --- Levels specification ---
m3 <- feols(export_value ~ banned | country_id + year,
            data = eu_nodnk,
            cluster = ~reporter)

cat("\n=== Model 3: TWFE DiD levels (excl. Denmark) ===\n")
summary(m3)

# ============================================================
# CALLAWAY-SANT'ANNA (heterogeneous treatment timing)
# ============================================================

# Prepare CS data: need first_treat = 0 for never-treated
cs_data <- eu_nodnk |>
  mutate(first_treat = ifelse(first_treat == 0, 0, first_treat))

# Remove cohorts outside the data range
cs_data <- cs_data |>
  filter(first_treat == 0 | (first_treat >= min(year) & first_treat <= max(year)))

cat("\nCS data:", nrow(cs_data), "obs\n")
cat("  Cohorts:", paste(sort(unique(cs_data$first_treat[cs_data$first_treat > 0])),
                        collapse = ", "), "\n")

tryCatch({
  cs_out <- att_gt(
    yname = "log_exports",
    tname = "year",
    idname = "country_id",
    gname = "first_treat",
    data = cs_data,
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "universal"
  )

  cat("\n=== Callaway-Sant'Anna Group-Time ATTs ===\n")
  summary(cs_out)

  # Aggregate to overall ATT
  cs_agg <- aggte(cs_out, type = "simple")
  cat("\n=== CS Overall ATT ===\n")
  summary(cs_agg)

  # Event study
  cs_es <- aggte(cs_out, type = "dynamic", min_e = -8, max_e = 10)
  cat("\n=== CS Event Study ===\n")
  summary(cs_es)

  # Save for later use
  saveRDS(cs_out, "../data/cs_results.rds")
  saveRDS(cs_es, "../data/cs_event_study.rds")

}, error = function(e) {
  cat("CS estimation error:", conditionMessage(e), "\n")
  cat("Proceeding with TWFE results only.\n")
})

# ============================================================
# TRADE DIVERSION TEST
# ============================================================

# Do non-banning EU producers (Poland, Finland) increase exports
# when neighboring countries ban?
cat("\n=== Trade Diversion Test ===\n")

# Poland and Finland exports over time
controls_over_time <- mink |>
  filter(reporter %in% c("pol", "fin"),
         commodity == "430110" | is.na(commodity)) |>
  group_by(reporter, year) |>
  summarise(export_value = sum(export_value, na.rm = TRUE), .groups = "drop")

cat("Poland exports:\n")
print(controls_over_time |> filter(reporter == "pol") |> arrange(year))

cat("\nFinland exports:\n")
print(controls_over_time |> filter(reporter == "fin") |> arrange(year))

# Global total test: does world fur trade decline?
global_total <- mink |>
  filter(commodity == "430110" | is.na(commodity)) |>
  group_by(year) |>
  summarise(total_exports = sum(export_value, na.rm = TRUE), .groups = "drop")

cat("\nGlobal mink furskin exports:\n")
print(global_total)

# ============================================================
# DIAGNOSTICS
# ============================================================

# ============================================================
# ACTIVE PRODUCERS ONLY (countries with pre-ban exports > $1M)
# ============================================================

# The TWFE is weak because most ban countries had zero fur industry.
# Restrict to countries that actually produced fur pre-ban.
active_producers <- c("dnk", "nld", "nor", "lva", "ltu", "irl", "bel", "gbr",
                       "fin", "pol", "grc")

eu_active <- mink |>
  filter(reporter %in% active_producers) |>
  mutate(country_id = as.integer(factor(reporter)))

eu_active_nodnk <- eu_active |> filter(reporter != "dnk")

m4 <- feols(log_exports ~ banned | country_id + year,
            data = eu_active_nodnk,
            cluster = ~reporter)

cat("\n=== Model 4: Active fur producers only (excl. DNK) ===\n")
summary(m4)

# Save this as the primary model
saveRDS(list(m1 = m1, m2 = m2, m3 = m3, m4 = m4), "../data/main_models.rds")

# Write diagnostics for validator
ban_dates <- tribble(
  ~reporter, ~ban_year,
  "gbr",     2003,
  "aut",     2005,
  "nld",     2013,
  "bel",     2019,
  "cze",     2019,
  "hun",     2020,
  "irl",     2022,
  "lva",     2022,
  "ltu",     2023,
  "nor",     2025,
  "dnk",     2020
)

# n_treated: number of treated country-year observations (staggered design)
n_treated <- sum(eu_active_nodnk$banned == 1)
# n_pre: median pre-treatment periods across cohorts
cohort_pre <- eu_active_nodnk |>
  filter(banned == 0, first_treat > 0) |>
  group_by(reporter) |>
  summarise(n_pre_years = n(), .groups = "drop")
n_pre <- as.integer(median(cohort_pre$n_pre_years))

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(eu_nodnk),
  twfe_coef = coef(m1)[["banned"]],
  twfe_se = sqrt(vcov(m1, type = "cluster")["banned", "banned"]),
  twfe_p = summary(m1)$coeftable["banned", "Pr(>|t|)"]
)

jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)

cat("\nDiagnostics saved.\n")
cat("  n_treated:", diagnostics$n_treated, "\n")
cat("  n_pre:", diagnostics$n_pre, "\n")
cat("  n_obs:", diagnostics$n_obs, "\n")
cat("  TWFE coef:", round(diagnostics$twfe_coef, 3), "\n")

# (Models already saved above with m4)

cat("\n=== Main analysis complete ===\n")
