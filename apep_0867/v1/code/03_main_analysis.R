## 03_main_analysis.R — Callaway-Sant'Anna DiD + DDD
## apep_0867: Upload Filters and the Creative Economy

source("00_packages.R")

panel <- readRDS("../data/panel_balanced.rds")

cat("=== Main Analysis ===\n")
cat(sprintf("Panel: %d obs, %d countries, years %s\n",
            nrow(panel), n_distinct(panel$country),
            paste(range(panel$year), collapse = "-")))

# -------------------------------------------------------------------
# 1. Callaway-Sant'Anna: NACE J (Information & Communication)
#    Using notyettreated as control (never-treated group has only 4 countries)
# -------------------------------------------------------------------
cat("\n--- CS-DiD: NACE J log employment ---\n")

panel_j <- panel %>%
  filter(nace == "J") %>%
  mutate(id = as.integer(factor(country)))

cs_log <- att_gt(
  yname = "log_empl",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = panel_j,
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)

cat("\nGroup-time ATTs (log):\n")
print(summary(cs_log))

agg_log_simple <- aggte(cs_log, type = "simple")
cat("\nSimple ATT (log):\n")
print(summary(agg_log_simple))

agg_log_dynamic <- aggte(cs_log, type = "dynamic")
cat("\nDynamic ATT (log):\n")
print(summary(agg_log_dynamic))

# -------------------------------------------------------------------
# 2. CS-DiD: Employment share
# -------------------------------------------------------------------
cat("\n--- CS-DiD: NACE J employment share ---\n")

cs_share <- att_gt(
  yname = "empl_share",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = panel_j,
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)

agg_share_simple <- aggte(cs_share, type = "simple")
cat("\nSimple ATT (share):\n")
print(summary(agg_share_simple))

agg_share_dynamic <- aggte(cs_share, type = "dynamic")

# -------------------------------------------------------------------
# 3. CS-DiD: Levels
# -------------------------------------------------------------------
cat("\n--- CS-DiD: NACE J employment (levels) ---\n")

cs_levels <- att_gt(
  yname = "employment",
  tname = "year",
  idname = "id",
  gname = "first_treat",
  data = panel_j,
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "universal"
)

agg_simple <- aggte(cs_levels, type = "simple")
cat("\nSimple ATT (levels):\n")
print(summary(agg_simple))

agg_dynamic <- aggte(cs_levels, type = "dynamic")

# -------------------------------------------------------------------
# 4. DDD: NACE J vs NACE K (TWFE for DDD)
# -------------------------------------------------------------------
cat("\n--- DDD: NACE J vs NACE K (TWFE) ---\n")

panel_ddd <- panel %>%
  mutate(
    country_nace = paste0(country, "_", nace),
    country_year = paste0(country, "_", year)
  )

# DDD specification:
# Y_cst = alpha_cs + lambda_st + gamma_ct + beta * D_ct * I(s=J) + eps
ddd_model <- feols(
  employment ~ did_treat |
    country^nace + nace^year + country^year,
  data = panel_ddd,
  cluster = ~country
)
cat("\nDDD (levels):\n")
print(summary(ddd_model))

# DDD in logs
ddd_log <- feols(
  log_empl ~ did_treat |
    country^nace + nace^year + country^year,
  data = panel_ddd,
  cluster = ~country
)
cat("\nDDD (log):\n")
print(summary(ddd_log))

# DDD in shares
ddd_share <- feols(
  empl_share ~ did_treat |
    country^nace + nace^year + country^year,
  data = panel_ddd,
  cluster = ~country
)
cat("\nDDD (share):\n")
print(summary(ddd_share))

# -------------------------------------------------------------------
# 5. TWFE DiD (for comparison with CS-DiD)
# -------------------------------------------------------------------
cat("\n--- TWFE DiD: NACE J ---\n")

twfe_j <- feols(
  log_empl ~ treated | country + year,
  data = panel_j,
  cluster = ~country
)
cat("\nTWFE (NACE J, log):\n")
print(summary(twfe_j))

# -------------------------------------------------------------------
# 6. Save results for tables
# -------------------------------------------------------------------
results <- list(
  cs_levels = cs_levels,
  cs_log = cs_log,
  cs_share = cs_share,
  agg_simple = agg_simple,
  agg_log_simple = agg_log_simple,
  agg_share_simple = agg_share_simple,
  agg_dynamic = agg_dynamic,
  agg_log_dynamic = agg_log_dynamic,
  agg_share_dynamic = agg_share_dynamic,
  ddd_model = ddd_model,
  ddd_log = ddd_log,
  ddd_share = ddd_share,
  twfe_j = twfe_j
)
saveRDS(results, "../data/main_results.rds")

# -------------------------------------------------------------------
# 7. Write diagnostics.json
# -------------------------------------------------------------------
n_treated <- panel_j %>%
  filter(first_treat > 0) %>%
  distinct(country) %>%
  nrow()

n_pre <- panel_j %>%
  filter(year < min(panel_j$first_treat[panel_j$first_treat > 0])) %>%
  distinct(year) %>%
  nrow()

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_countries = n_distinct(panel$country),
  n_years = n_distinct(panel$year),
  outcome_sd_pre = sd(panel_j$employment[panel_j$treated == 0], na.rm = TRUE),
  outcome_sd_pre_log = sd(panel_j$log_empl[panel_j$treated == 0], na.rm = TRUE),
  outcome_sd_pre_share = sd(panel_j$empl_share[panel_j$treated == 0], na.rm = TRUE)
)

write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE)
cat(sprintf("\nDiagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))

cat("\n=== Main analysis complete ===\n")
