# 03_main_analysis.R — Callaway-Sant'Anna DiD + Event Study
# apep_0660: FCC Cellular Lottery and Local Economic Development

source("00_packages.R")

data_dir <- "../data"
panel <- readRDS(file.path(data_dir, "analysis_panel.rds"))

cat("=== Main Analysis ===\n")
cat(sprintf("Panel: %d county-years, %d counties, %d states, cohorts: %s\n",
            nrow(panel), n_distinct(panel$fips), n_distinct(panel$state_fips),
            paste(sort(unique(panel$treat_year)), collapse = ",")))

# Create numeric county ID for CS
panel$county_id <- as.integer(factor(panel$fips))

# Balance: require counties present in all years
panel_bal <- panel %>%
  filter(!is.na(log_emp) & is.finite(log_emp)) %>%
  group_by(fips) %>%
  filter(n() >= 15) %>%
  ungroup()

cat(sprintf("Balanced panel: %d obs, %d counties\n",
            nrow(panel_bal), n_distinct(panel_bal$fips)))

panel_bal$county_id <- as.integer(factor(panel_bal$fips))

# ==============================================================================
# 1. Callaway-Sant'Anna: Log Employment
# ==============================================================================
cat("\n--- CS DiD: Log Employment ---\n")

cs_emp <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "county_id",
  gname = "treat_year",
  data = as.data.frame(panel_bal),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal",
  clustervars = "state_fips"
)

agg_emp <- aggte(cs_emp, type = "simple")
es_emp <- aggte(cs_emp, type = "dynamic", min_e = -3, max_e = 15)
group_emp <- aggte(cs_emp, type = "group")

p_emp <- 2 * pnorm(-abs(agg_emp$overall.att / agg_emp$overall.se))
cat(sprintf("CS ATT (log emp): %.4f (SE: %.4f, p=%.4f)\n",
            agg_emp$overall.att, agg_emp$overall.se, p_emp))

# ==============================================================================
# 2. Callaway-Sant'Anna: Log Establishments
# ==============================================================================
cat("\n--- CS DiD: Log Establishments ---\n")

cs_estab <- att_gt(
  yname = "log_estab",
  tname = "year",
  idname = "county_id",
  gname = "treat_year",
  data = as.data.frame(panel_bal),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal",
  clustervars = "state_fips"
)

agg_estab <- aggte(cs_estab, type = "simple")
es_estab <- aggte(cs_estab, type = "dynamic", min_e = -3, max_e = 15)

p_estab <- 2 * pnorm(-abs(agg_estab$overall.att / agg_estab$overall.se))
cat(sprintf("CS ATT (log estab): %.4f (SE: %.4f, p=%.4f)\n",
            agg_estab$overall.att, agg_estab$overall.se, p_estab))

# ==============================================================================
# 3. Callaway-Sant'Anna: Log Payroll
# ==============================================================================
cat("\n--- CS DiD: Log Payroll ---\n")

panel_pay <- panel_bal %>% filter(!is.na(log_payann) & is.finite(log_payann) & payann > 0)
panel_pay$county_id <- as.integer(factor(panel_pay$fips))

cs_pay <- att_gt(
  yname = "log_payann",
  tname = "year",
  idname = "county_id",
  gname = "treat_year",
  data = as.data.frame(panel_pay),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal",
  clustervars = "state_fips"
)

agg_pay <- aggte(cs_pay, type = "simple")
es_pay <- aggte(cs_pay, type = "dynamic", min_e = -3, max_e = 15)

p_pay <- 2 * pnorm(-abs(agg_pay$overall.att / agg_pay$overall.se))
cat(sprintf("CS ATT (log pay): %.4f (SE: %.4f, p=%.4f)\n",
            agg_pay$overall.att, agg_pay$overall.se, p_pay))

# ==============================================================================
# 4. TWFE benchmark
# ==============================================================================
cat("\n--- TWFE Benchmark ---\n")

twfe_emp <- feols(log_emp ~ treated | fips + year, data = panel_bal, cluster = ~state_fips)
twfe_estab <- feols(log_estab ~ treated | fips + year, data = panel_bal, cluster = ~state_fips)
twfe_pay <- feols(log_payann ~ treated | fips + year,
                  data = panel_pay, cluster = ~state_fips)

cat(sprintf("TWFE log emp:    %.4f (SE: %.4f, p=%.4f)\n",
            coef(twfe_emp)["treated"], se(twfe_emp)["treated"],
            pvalue(twfe_emp)["treated"]))
cat(sprintf("TWFE log estab:  %.4f (SE: %.4f, p=%.4f)\n",
            coef(twfe_estab)["treated"], se(twfe_estab)["treated"],
            pvalue(twfe_estab)["treated"]))
cat(sprintf("TWFE log pay:    %.4f (SE: %.4f, p=%.4f)\n",
            coef(twfe_pay)["treated"], se(twfe_pay)["treated"],
            pvalue(twfe_pay)["treated"]))

# ==============================================================================
# 5. Save results
# ==============================================================================
results <- list(
  cs_emp = cs_emp, cs_estab = cs_estab, cs_pay = cs_pay,
  agg_emp = agg_emp, agg_estab = agg_estab, agg_pay = agg_pay,
  es_emp = es_emp, es_estab = es_estab, es_pay = es_pay,
  group_emp = group_emp,
  twfe_emp = twfe_emp, twfe_estab = twfe_estab, twfe_pay = twfe_pay,
  panel_info = list(
    n_obs = nrow(panel_bal), n_counties = n_distinct(panel_bal$fips),
    n_states = n_distinct(panel_bal$state_fips),
    years = range(panel_bal$year),
    treat_years = sort(unique(panel_bal$treat_year))
  )
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Update diagnostics
diag <- fromJSON(file.path(data_dir, "diagnostics.json"))
diag$n_obs <- nrow(panel_bal)
diag$cs_att_emp <- round(agg_emp$overall.att, 4)
diag$cs_se_emp <- round(agg_emp$overall.se, 4)
write_json(diag, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE, pretty = TRUE)

cat("\n=== Main analysis complete ===\n")
