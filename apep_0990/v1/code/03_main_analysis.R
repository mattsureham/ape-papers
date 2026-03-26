# 03_main_analysis.R — Callaway-Sant'Anna staggered DiD
# apep_0990: Nebraska groundwater allocations and crop adaptation

source("00_packages.R")

panel <- readRDS("../data/analysis_panel.rds")

cat("=== Main Analysis ===\n")
cat("Panel: ", nrow(panel), " county-years\n")
cat("Counties: ", n_distinct(panel$county_fips), "\n")
cat("Treatment groups: ", n_distinct(panel$first_treat[panel$first_treat > 0]), "\n")

# --- Handle always-treated units ---
# Upper Republican NRD adopted in 1979 but our data starts 1990.
# These counties are always-treated and cannot be used for CS.
# Recode them: they become a separate group that CS drops automatically.
# Also exclude them from TWFE to keep comparisons consistent.

always_treated <- panel %>%
  filter(first_treat > 0, first_treat < min(panel$year)) %>%
  distinct(county_fips) %>%
  pull(county_fips)

cat("Always-treated counties (treatment before sample start):",
    length(always_treated), "\n")

# For CS: keep them in (CS auto-drops always-treated)
# For TWFE: exclude them
panel_twfe <- panel %>%
  filter(!county_fips %in% always_treated)

# --- Descriptive: treatment rollout ---
treat_summary <- panel %>%
  filter(first_treat > 0) %>%
  distinct(county_fips, nrd_name, first_treat) %>%
  group_by(nrd_name, first_treat) %>%
  summarise(n_counties = n(), .groups = "drop") %>%
  arrange(first_treat)

cat("\nTreatment rollout:\n")
print(treat_summary)

# --- Helper function for CS ---
run_cs <- function(outcome_var, data, label) {
  cat("\n--- CS DiD:", label, "---\n")

  d <- data %>% filter(!is.na(.data[[outcome_var]]))

  cs <- att_gt(
    yname = outcome_var,
    tname = "year",
    idname = "county_id",
    gname = "first_treat",
    data = d,
    control_group = "notyettreated",
    anticipation = 0,
    base_period = "universal",
    allow_unbalanced_panel = TRUE
  )

  es <- aggte(cs, type = "dynamic", min_e = -10, max_e = 15, na.rm = TRUE)
  att <- aggte(cs, type = "simple", na.rm = TRUE)

  cat("Overall ATT (", label, "):", att$overall.att,
      " SE:", att$overall.se, "\n")

  list(cs = cs, es = es, att = att)
}

# --- Main specifications ---
res_corn <- run_cs("corn_share", panel, "Corn share")
res_sorghum <- run_cs("sorghum_share", panel, "Sorghum share")
res_drought <- run_cs("drought_tolerant_share", panel, "Drought-tolerant share")
res_wheat <- run_cs("wheat_share", panel, "Wheat share")

# Log total acres
panel_acres <- panel %>%
  filter(!is.na(total_crop_acres), total_crop_acres > 0) %>%
  mutate(log_total_acres = log(total_crop_acres))

res_acres <- run_cs("log_total_acres", panel_acres, "Log total crop acres")

# --- TWFE comparison ---
cat("\n--- TWFE comparison (excluding always-treated) ---\n")

twfe_corn <- feols(corn_share ~ treated | county_id + year,
                   data = panel_twfe, cluster = ~nrd_name)
cat("TWFE (corn share):\n")
summary(twfe_corn)

twfe_sorghum <- feols(sorghum_share ~ treated | county_id + year,
                      data = panel_twfe, cluster = ~nrd_name)
twfe_drought <- feols(drought_tolerant_share ~ treated | county_id + year,
                      data = panel_twfe, cluster = ~nrd_name)

# --- TWFE Event Study (for SEs that CS can't provide) ---
cat("\n--- TWFE Event Study ---\n")

# Create event-time indicators
panel_es <- panel_twfe %>%
  filter(is.finite(treat_year) | first_treat == 0) %>%
  mutate(
    event_time = ifelse(first_treat > 0, year - first_treat, NA_integer_)
  )

# For never-treated: set event_time = NA (absorbed by year FE)
# Create dummies for event times -8 to +12, omitting -1
event_times <- -8:12
for (e in event_times) {
  if (e == -1) next  # omit reference period
  varname <- paste0("et_", ifelse(e < 0, "m", "p"), abs(e))
  panel_es[[varname]] <- ifelse(!is.na(panel_es$event_time) & panel_es$event_time == e, 1, 0)
}

# Build formula
et_vars <- paste0("et_", c(paste0("m", 8:2), paste0("p", 0:12)))
fml <- as.formula(paste("corn_share ~", paste(et_vars, collapse = " + "), "| county_id + year"))

twfe_es <- feols(fml, data = panel_es, cluster = ~nrd_name)
cat("TWFE Event Study (corn share):\n")
summary(twfe_es)

# Also for drought-tolerant share
fml_dt <- as.formula(paste("drought_tolerant_share ~", paste(et_vars, collapse = " + "), "| county_id + year"))
twfe_es_dt <- feols(fml_dt, data = panel_es, cluster = ~nrd_name)

# --- Save results ---
results <- list(
  cs_corn = res_corn$cs,
  cs_sorghum = res_sorghum$cs,
  cs_drought = res_drought$cs,
  cs_wheat = res_wheat$cs,
  cs_acres = res_acres$cs,
  es_corn = res_corn$es,
  es_sorghum = res_sorghum$es,
  es_drought = res_drought$es,
  es_wheat = res_wheat$es,
  es_acres = res_acres$es,
  att_corn = res_corn$att,
  att_sorghum = res_sorghum$att,
  att_drought = res_drought$att,
  att_wheat = res_wheat$att,
  att_acres = res_acres$att,
  twfe_corn = twfe_corn,
  twfe_sorghum = twfe_sorghum,
  twfe_drought = twfe_drought,
  twfe_es_corn = twfe_es,
  twfe_es_drought = twfe_es_dt,
  panel_es = panel_es,
  panel = panel,
  panel_twfe = panel_twfe,
  always_treated = always_treated
)

saveRDS(results, "../data/main_results.rds")

# --- Diagnostics for validator ---
n_treated <- n_distinct(panel$county_fips[panel$first_treat > 0])
# Pre-periods: years before the earliest in-sample treatment
earliest_in_sample <- min(panel$first_treat[panel$first_treat >= min(panel$year)])
n_pre <- length(unique(panel$year[panel$year < earliest_in_sample]))
n_obs <- nrow(panel)

jsonlite::write_json(
  list(n_treated = n_treated, n_pre = n_pre, n_obs = n_obs),
  "../data/diagnostics.json",
  auto_unbox = TRUE
)

cat("\n=== Main analysis complete ===\n")
cat("Diagnostics: n_treated =", n_treated, ", n_pre =", n_pre, ", n_obs =", n_obs, "\n")
