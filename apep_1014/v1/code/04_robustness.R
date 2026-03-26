# =============================================================================
# 04_robustness.R — Placebo tests, wild cluster bootstrap, leave-one-out
# =============================================================================

source("00_packages.R")

analysis <- arrow::read_parquet("../data/analysis_sample.parquet")
placebo <- arrow::read_parquet("../data/placebo_sample.parquet")
load("../data/models.RData")

# ============================================================================
# 1. PLACEBO: Healthcare (NAICS 62) — no tipping
# ============================================================================

placebo_health <- placebo %>%
  filter(industry == "62") %>%
  filter(!is.na(bw_ratio)) %>%
  mutate(
    reform_state = as.integer(state_fips == "04"),
    post = as.integer(year >= 2017)
  ) %>%
  filter(state_fips == "04" | tipped_group == "LowTipped")

placebo_health_reg <- feols(
  bw_ratio ~ reform_state:post | state_fips + year + quarter,
  data = placebo_health,
  cluster = ~state_fips
)

cat("\n=== Placebo: Healthcare B-W Ratio (AZ) ===\n")
summary(placebo_health_reg)

# ============================================================================
# 2. PLACEBO: Professional Services (NAICS 54)
# ============================================================================

placebo_prof <- placebo %>%
  filter(industry == "54") %>%
  filter(!is.na(bw_ratio)) %>%
  mutate(
    reform_state = as.integer(state_fips == "04"),
    post = as.integer(year >= 2017)
  ) %>%
  filter(state_fips == "04" | tipped_group == "LowTipped")

placebo_prof_reg <- feols(
  bw_ratio ~ reform_state:post | state_fips + year + quarter,
  data = placebo_prof,
  cluster = ~state_fips
)

cat("\n=== Placebo: Professional Services B-W Ratio (AZ) ===\n")
summary(placebo_prof_reg)

# ============================================================================
# 3. PLACEBO: White Earnings DD (food services only — should capture MW, not race)
# ============================================================================

# If the racial gap narrowing is real, white earnings should NOT show differential
# changes relative to Black earnings in reform states
ww_food <- analysis %>%
  filter(industry == "72", tipped_group %in% c("Reform", "LowTipped")) %>%
  mutate(
    treated = as.integer(tipped_group == "Reform"),
    post = post_reform,
    yearq = paste0(year, "Q", quarter)
  )

# DD on white earnings (levels, not racial gap)
ww_did <- feols(
  ln_earn_white ~ treated:post | state_fips + yearq,
  data = ww_food,
  cluster = ~state_fips
)

cat("\n=== Placebo: White Earnings DD in Food Services ===\n")
summary(ww_did)

# ============================================================================
# 4. WILD CLUSTER BOOTSTRAP (few treated clusters)
# ============================================================================

cat("\n=== Wild Cluster Bootstrap for DDD ===\n")

# DDD with explicit reform state dummies for WCB
ddd_for_wcb <- analysis %>%
  filter(tipped_group %in% c("Reform", "LowTipped")) %>%
  mutate(
    reform_state = as.integer(tipped_group == "Reform"),
    food_svc = food_services,
    post = as.integer(year >= 2017),
    treat_ddd = reform_state * food_svc * post,
    yearq_id = as.integer(factor(paste0(year, quarter)))
  )

# Run bootstrap
ddd_wcb_model <- feols(
  ln_bw_gap ~ treat_ddd + reform_state:food_svc + reform_state:post + food_svc:post |
    state_fips + yearq_id + industry,
  data = ddd_for_wcb,
  cluster = ~state_fips
)

tryCatch({
  boot_result <- boottest(
    ddd_wcb_model,
    param = "treat_ddd",
    clustid = "state_fips",
    B = 9999,
    type = "rademacher"
  )
  cat(sprintf("WCB p-value: %.4f\n", boot_result$p_val))
  cat(sprintf("WCB 95%% CI: [%.4f, %.4f]\n", boot_result$conf_int[1], boot_result$conf_int[2]))
  wcb_pval <- boot_result$p_val
  wcb_ci <- boot_result$conf_int
}, error = function(e) {
  cat(sprintf("WCB failed: %s\n", e$message))
  cat("Falling back to cluster-robust only.\n")
  wcb_pval <<- NA
  wcb_ci <<- c(NA, NA)
})

# ============================================================================
# 5. LEAVE-ONE-OUT (drop each treated state)
# ============================================================================

treated_states <- c("04", "11", "26")
loo_results <- list()

for (st in treated_states) {
  loo_data <- ddd_for_wcb %>% filter(state_fips != st)
  loo_model <- feols(
    ln_bw_gap ~ treat_ddd + reform_state:food_svc + reform_state:post + food_svc:post |
      state_fips + yearq_id + industry,
    data = loo_data,
    cluster = ~state_fips
  )
  loo_results[[st]] <- list(
    dropped = st,
    coef = coef(loo_model)[["treat_ddd"]],
    se = sqrt(vcov(loo_model)[["treat_ddd", "treat_ddd"]]),
    pval = pvalue(loo_model)[["treat_ddd"]]
  )
  cat(sprintf("LOO (drop %s): coef=%.4f, se=%.4f, p=%.4f\n",
              st, loo_results[[st]]$coef, loo_results[[st]]$se, loo_results[[st]]$pval))
}

# ============================================================================
# 6. CALLAWAY-SANT'ANNA (staggered DiD)
# ============================================================================

cs_data <- analysis %>%
  filter(industry == "72") %>%
  filter(tipped_group %in% c("Reform", "LowTipped")) %>%
  filter(!is.na(bw_ratio)) %>%
  filter(quarter == 1) %>%  # annual for CS
  mutate(
    id = as.integer(factor(state_fips)),
    first_treat_cs = ifelse(first_treat == 0, 0, first_treat)
  )

cs_result <- tryCatch({
  att_gt(
    yname = "bw_ratio",
    tname = "year",
    idname = "id",
    gname = "first_treat_cs",
    data = cs_data,
    control_group = "nevertreated",
    est_method = "dr"
  )
}, error = function(e) {
  cat(sprintf("CS failed: %s\n", e$message))
  NULL
})

if (!is.null(cs_result)) {
  cs_agg <- aggte(cs_result, type = "simple")
  cat("\n=== Callaway-Sant'Anna: ATT (simple) ===\n")
  summary(cs_agg)

  cs_dynamic <- aggte(cs_result, type = "dynamic")
  cat("\n=== CS Dynamic ===\n")
  summary(cs_dynamic)
}

# Save robustness results
robustness <- list(
  placebo_health_coef = coef(placebo_health_reg)[["reform_state:post"]],
  placebo_health_pval = pvalue(placebo_health_reg)[["reform_state:post"]],
  placebo_prof_coef = coef(placebo_prof_reg)[["reform_state:post"]],
  placebo_prof_pval = pvalue(placebo_prof_reg)[["reform_state:post"]],
  ww_placebo_coef = coef(ww_did)[["treated:post"]],
  ww_placebo_pval = pvalue(ww_did)[["treated:post"]],
  wcb_pval = if (exists("wcb_pval")) wcb_pval else NA,
  loo = loo_results,
  cs_att = if (!is.null(cs_result)) cs_agg$overall.att else NA,
  cs_se = if (!is.null(cs_result)) cs_agg$overall.se else NA
)

save(placebo_health_reg, placebo_prof_reg, ww_did, ddd_wcb_model,
     loo_results, cs_result, robustness,
     file = "../data/robustness.RData")

cat("\nRobustness results saved.\n")
