## 03_main_analysis.R — Callaway-Sant'Anna DiD for cigarette tax spillovers
## APEP-0606: Cross-Substance Spillovers of Cigarette Excise Taxes

source("00_packages.R")

panel <- readRDS("../data/panel_clean.rds")
cat("Loaded panel:", nrow(panel), "state-year obs\n")

# =============================================================================
# 1. Callaway-Sant'Anna: Total alcohol consumption
# =============================================================================
cat("\n=== CS-DiD: TOTAL ETHANOL ===\n")

cs_total <- att_gt(
  yname = "total",
  tname = "year",
  idname = "state_id",
  gname = "first_treat_year",
  data = as.data.frame(panel),
  control_group = "notyettreated",
  anticipation = 0,
  base_period = "varying"
)

es_total <- aggte(cs_total, type = "dynamic", min_e = -5, max_e = 5)
att_total <- aggte(cs_total, type = "simple")

cat("Simple ATT (total):", att_total$overall.att,
    "(SE:", att_total$overall.se, ")\n")

saveRDS(cs_total, "../data/cs_total.rds")
saveRDS(es_total, "../data/es_total.rds")
saveRDS(att_total, "../data/att_total.rds")

# =============================================================================
# 2. CS-DiD: By beverage type
# =============================================================================
beverages <- c("beer", "wine", "spirits")
cs_results <- list()
es_results <- list()
att_results <- list()

for (bev in beverages) {
  cat(sprintf("\n=== CS-DiD: %s ===\n", toupper(bev)))

  cs_bev <- att_gt(
    yname = bev,
    tname = "year",
    idname = "state_id",
    gname = "first_treat_year",
    data = as.data.frame(panel),
    control_group = "notyettreated",
    anticipation = 0,
    base_period = "varying"
  )

  es_bev <- aggte(cs_bev, type = "dynamic", min_e = -5, max_e = 5)
  att_bev <- aggte(cs_bev, type = "simple")

  cat(sprintf("  ATT(%s) = %.4f (SE = %.4f)\n", bev,
              att_bev$overall.att, att_bev$overall.se))

  cs_results[[bev]] <- cs_bev
  es_results[[bev]] <- es_bev
  att_results[[bev]] <- att_bev
}

saveRDS(cs_results, "../data/cs_by_beverage.rds")
saveRDS(es_results, "../data/es_by_beverage.rds")
saveRDS(att_results, "../data/att_by_beverage.rds")

# =============================================================================
# 3. TWFE comparison
# =============================================================================
cat("\n=== TWFE COMPARISON ===\n")
panel[, treated := as.integer(first_treat_year > 0 & year >= first_treat_year)]

twfe_total <- feols(total ~ treated | state_id + year, data = panel,
                    cluster = ~state_id)
cat("TWFE (total):", round(coef(twfe_total)["treated"], 4),
    "(SE:", round(se(twfe_total)["treated"], 4), ")\n")

twfe_results <- list(total = twfe_total)
for (bev in beverages) {
  twfe_bev <- feols(as.formula(paste0(bev, " ~ treated | state_id + year")),
                    data = panel, cluster = ~state_id)
  twfe_results[[bev]] <- twfe_bev
  cat(sprintf("TWFE (%s): %.4f (SE: %.4f)\n",
              bev, coef(twfe_bev)["treated"], se(twfe_bev)["treated"]))
}
saveRDS(twfe_results, "../data/twfe_results.rds")

# =============================================================================
# 4. Diagnostics for validation
# =============================================================================
n_states <- length(unique(panel$state_name))
n_treated <- length(unique(panel[first_treat_year > 0]$state_name))
n_never <- length(unique(panel[first_treat_year == 0]$state_name))
n_pre <- length(unique(panel[year < 2001]$year))

diagnostics <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(panel),
  n_states = n_states,
  n_never_treated = n_never,
  n_treatment_events = nrow(readRDS("../data/first_increase.rds")),
  att_total = att_total$overall.att,
  att_total_se = att_total$overall.se,
  att_beer = att_results$beer$overall.att,
  att_wine = att_results$wine$overall.att,
  att_spirits = att_results$spirits$overall.att
)
jsonlite::write_json(diagnostics, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

cat("\n=== MAIN ANALYSIS COMPLETE ===\n")
cat(sprintf("ATT (total):   %.4f (SE: %.4f)\n",
            att_total$overall.att, att_total$overall.se))
cat(sprintf("ATT (beer):    %.4f (SE: %.4f)\n",
            att_results$beer$overall.att, att_results$beer$overall.se))
cat(sprintf("ATT (wine):    %.4f (SE: %.4f)\n",
            att_results$wine$overall.att, att_results$wine$overall.se))
cat(sprintf("ATT (spirits): %.4f (SE: %.4f)\n",
            att_results$spirits$overall.att, att_results$spirits$overall.se))
