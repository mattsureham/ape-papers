## 04_robustness.R — Robustness checks
## apep_1172: Cage-Free Egg Mandates

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
yearly <- results$yearly

cat("=== Robustness Checks ===\n")

# ============================================================
# 1. Bacon Decomposition (balanced panel required)
# ============================================================

cat("\n--- Bacon Decomposition ---\n")

# Balance the panel: keep only states present in ALL years
state_year_count <- yearly %>% count(state_id)
max_years <- max(state_year_count$n)
balanced_states <- state_year_count %>% filter(n == max_years) %>% pull(state_id)

bacon_data <- yearly %>%
  filter(state_id %in% balanced_states) %>%
  select(state_id, year, ln_layers, post)

cat("Balanced panel:", nrow(bacon_data), "obs,", n_distinct(bacon_data$state_id), "states\n")

bacon_out <- bacon(ln_layers ~ post, data = bacon_data,
                   id_var = "state_id", time_var = "year")
cat("Bacon decomposition weights:\n")
print(aggregate(weight ~ type, data = bacon_out, FUN = sum))

saveRDS(bacon_out, "../data/bacon_decomp.rds")

# ============================================================
# 2. Leave-one-out: Drop California
# ============================================================

cat("\n--- Leave-One-Out: Drop CA ---\n")

cs_data <- yearly %>% filter(!is.na(ln_layers))
cs_no_ca <- cs_data %>% filter(state != "CA")

cs_layers_no_ca <- att_gt(
  yname = "ln_layers", tname = "year", idname = "state_id",
  gname = "first_treat_year", data = cs_no_ca,
  control_group = "nevertreated", est_method = "dr", base_period = "universal"
)

agg_no_ca <- aggte(cs_layers_no_ca, type = "simple")
cat("ATT (layers, excl. CA):", round(agg_no_ca$overall.att, 4),
    "SE:", round(agg_no_ca$overall.se, 4), "\n")

# ============================================================
# 3. Leave-one-out: Drop each treated state
# ============================================================

cat("\n--- Leave-One-Out: Each Treated State ---\n")

treated_states <- unique(cs_data$state[cs_data$first_treat_year > 0])
loo_results <- list()

for (st in treated_states) {
  cs_loo <- cs_data %>% filter(state != st)

  tryCatch({
    cs_loo_fit <- att_gt(
      yname = "ln_layers", tname = "year", idname = "state_id",
      gname = "first_treat_year", data = cs_loo,
      control_group = "nevertreated", est_method = "dr", base_period = "universal"
    )
    agg_loo <- aggte(cs_loo_fit, type = "simple")
    loo_results[[st]] <- data.frame(dropped = st, att = agg_loo$overall.att, se = agg_loo$overall.se)
    cat("  Drop", st, "→ ATT:", round(agg_loo$overall.att, 4),
        "SE:", round(agg_loo$overall.se, 4), "\n")
  }, error = function(e) {
    cat("  Drop", st, "→ ERROR:", conditionMessage(e), "\n")
    loo_results[[st]] <<- data.frame(dropped = st, att = NA, se = NA)
  })
}

loo_df <- bind_rows(loo_results)
saveRDS(loo_df, "../data/loo_results.rds")

# ============================================================
# 4. Placebo outcome: Eggs per 100 layers
# ============================================================

cat("\n--- Placebo: Eggs per 100 Layers ---\n")
agg_epl <- results$agg_overall_epl
cat("ATT (eggs per 100):", round(agg_epl$overall.att, 4),
    "SE:", round(agg_epl$overall.se, 4), "\n")

# ============================================================
# 5. Wild Cluster Bootstrap
# ============================================================

cat("\n--- Wild Cluster Bootstrap ---\n")

# Re-estimate TWFE dropping singletons manually to avoid boottest error
yearly_nosingle <- yearly %>%
  filter(!is.na(ln_layers)) %>%
  group_by(state_id) %>%
  filter(n() > 1) %>%
  group_by(year) %>%
  filter(n() > 1) %>%
  ungroup()

twfe_wcb <- feols(ln_layers ~ post | state_id + year,
                  data = yearly_nosingle, cluster = ~state_id,
                  fixef.rm = "none")

tryCatch({
  boot_layers <- boottest(twfe_wcb, param = "post",
                          B = 9999, clustid = "state_id",
                          type = "webb")
  cat("WCB p-value (layers):", boot_layers$p_val, "\n")
  cat("WCB 95% CI:", boot_layers$conf_int, "\n")
}, error = function(e) {
  cat("WCB error:", conditionMessage(e), "\n")
  cat("Falling back to cluster-robust SE from CS estimator\n")
  boot_layers <<- list(p_val = NA, conf_int = c(NA, NA))
})

twfe_wcb_p <- feols(ln_production ~ post | state_id + year,
                    data = yearly_nosingle %>% filter(!is.na(ln_production)),
                    cluster = ~state_id, fixef.rm = "none")

tryCatch({
  boot_prod <- boottest(twfe_wcb_p, param = "post",
                        B = 9999, clustid = "state_id",
                        type = "webb")
  cat("WCB p-value (production):", boot_prod$p_val, "\n")
}, error = function(e) {
  cat("WCB error (production):", conditionMessage(e), "\n")
  boot_prod <<- list(p_val = NA, conf_int = c(NA, NA))
})

# ============================================================
# 6. Alternative: Not-yet-treated control
# ============================================================

cat("\n--- Not-Yet-Treated Control ---\n")

cs_nyt <- att_gt(
  yname = "ln_layers", tname = "year", idname = "state_id",
  gname = "first_treat_year", data = cs_data,
  control_group = "notyettreated", est_method = "dr", base_period = "universal"
)

agg_nyt <- aggte(cs_nyt, type = "simple")
cat("ATT (not-yet-treated):", round(agg_nyt$overall.att, 4),
    "SE:", round(agg_nyt$overall.se, 4), "\n")

# ============================================================
# 7. Hatching egg production (structural placebo)
# ============================================================

cat("\n--- Hatching Eggs Placebo ---\n")

analysis <- readRDS("../data/analysis_panel.rds")

# Check if hatching_production exists in the data
if ("hatching_production" %in% names(analysis)) {
  hatch_yearly <- analysis %>%
    filter(!is.na(hatching_production), hatching_production > 0) %>%
    group_by(state, state_id, year, treated_state, cohort_year) %>%
    summarise(
      hatching = mean(hatching_production, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      ln_hatching = log(hatching),
      first_treat_year = ifelse(treated_state, cohort_year, 0),
      post = ifelse(treated_state & year >= cohort_year, 1, 0)
    )

  if (n_distinct(hatch_yearly$state[hatch_yearly$first_treat_year > 0]) >= 2) {
    cs_hatch <- att_gt(
      yname = "ln_hatching", tname = "year", idname = "state_id",
      gname = "first_treat_year", data = hatch_yearly,
      control_group = "nevertreated", est_method = "dr", base_period = "universal"
    )
    agg_hatch <- aggte(cs_hatch, type = "simple")
    cat("ATT (hatching eggs):", round(agg_hatch$overall.att, 4),
        "SE:", round(agg_hatch$overall.se, 4), "\n")
  } else {
    cat("Too few treated states with hatching data\n")
    agg_hatch <- list(overall.att = NA, overall.se = NA)
  }
} else {
  cat("Hatching production not in data — using eggs per 100 as primary placebo\n")
  agg_hatch <- list(overall.att = NA, overall.se = NA)
}

# ============================================================
# Save all robustness results
# ============================================================

rob_results <- list(
  bacon = bacon_out,
  loo = loo_df,
  no_ca = list(att = agg_no_ca$overall.att, se = agg_no_ca$overall.se),
  wcb_layers = list(p = boot_layers$p_val, ci = boot_layers$conf_int),
  wcb_prod = list(p = boot_prod$p_val, ci = boot_prod$conf_int),
  nyt = list(att = agg_nyt$overall.att, se = agg_nyt$overall.se),
  placebo_epl = list(att = agg_epl$overall.att, se = agg_epl$overall.se),
  hatching = list(att = agg_hatch$overall.att, se = agg_hatch$overall.se)
)

saveRDS(rob_results, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
