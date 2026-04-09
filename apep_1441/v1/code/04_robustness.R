# 04_robustness.R — Robustness checks
# APEP-1441: Swiss cantonal minimum wages

source("00_packages.R")

panel <- read_csv("../data/panel.csv", show_col_types = FALSE)
results <- readRDS("../data/results.rds")

# ============================================================================
# 1. Bacon Decomposition
# ============================================================================
cat("=== Bacon Decomposition ===\n")

high_bite <- panel %>%
  filter(high_bite) %>%
  group_by(canton, year) %>%
  summarise(
    employment = sum(employment, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(
    panel %>% select(canton, year, first_treat, treated_canton) %>% distinct(),
    by = c("canton", "year")
  ) %>%
  mutate(
    log_emp = log(employment + 1),
    canton_id = as.integer(factor(canton)),
    treat_post = treated_canton * (year >= first_treat)
  )

bacon_out <- tryCatch({
  bacon(log_emp ~ treat_post,
        data = as.data.frame(high_bite),
        id_var = "canton_id",
        time_var = "year")
}, error = function(e) {
  cat("Bacon decomposition error:", e$message, "\n")
  cat("Skipping — this is common with staggered designs where bacondecomp needs balanced panels.\n")
  NULL
})

if (!is.null(bacon_out)) {
  cat("Bacon decomposition:\n")
  print(bacon_out)
  cat("\nWeighted estimate:", sum(bacon_out$estimate * bacon_out$weight), "\n")
} else {
  cat("Bacon decomposition skipped.\n")
}

# ============================================================================
# 2. Placebo: Low-bite (high-wage) sectors
# ============================================================================
cat("\n=== Placebo: Low-Bite Sectors ===\n")

low_bite <- panel %>%
  filter(low_bite) %>%
  group_by(canton, year) %>%
  summarise(
    employment = sum(employment, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(
    panel %>% select(canton, year, first_treat, treated_canton) %>% distinct(),
    by = c("canton", "year")
  ) %>%
  mutate(
    log_emp = log(employment + 1),
    canton_id = as.integer(factor(canton))
  )

cs_placebo <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "canton_id",
  gname = "first_treat",
  data = low_bite,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_placebo <- aggte(cs_placebo, type = "simple")
cat("Placebo ATT (low-bite sectors):\n")
summary(agg_placebo)

# ============================================================================
# 3. HonestDiD sensitivity
# ============================================================================
cat("\n=== HonestDiD Sensitivity ===\n")

es_emp <- results$es_emp

# Extract pre-treatment coefficients for sensitivity
pre_idx <- which(es_emp$egt < 0)
post_idx <- which(es_emp$egt >= 0)

if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
  # Construct the beta vector and variance-covariance matrix
  beta <- es_emp$att.egt
  V <- es_emp$att.egt %*% t(es_emp$att.egt)  # Simplified; use actual vcov if available

  # HonestDiD requires specific format
  # Use the CS object directly
  tryCatch({
    honest_result <- HonestDiD::createSensitivityResults(
      betahat = es_emp$att.egt,
      sigma = diag(es_emp$se.egt^2),
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01)
    )
    cat("HonestDiD results:\n")
    print(honest_result)

    saveRDS(honest_result, "../data/honest_did.rds")
  }, error = function(e) {
    cat("HonestDiD error:", e$message, "\n")
    cat("Proceeding without HonestDiD sensitivity.\n")
  })
} else {
  cat("Insufficient pre/post periods for HonestDiD.\n")
}

# ============================================================================
# 4. Excluding COVID period (Geneva adopted Nov 2020)
# ============================================================================
cat("\n=== Excluding COVID (2020-2021) ===\n")

high_bite_nocovid <- high_bite %>%
  filter(!(year %in% c(2020, 2021)))

cs_nocovid <- att_gt(
  yname = "log_emp",
  tname = "year",
  idname = "canton_id",
  gname = "first_treat",
  data = high_bite_nocovid,
  control_group = "nevertreated",
  anticipation = 0,
  base_period = "universal"
)

agg_nocovid <- aggte(cs_nocovid, type = "simple")
cat("ATT excluding COVID years:\n")
summary(agg_nocovid)

# ============================================================================
# 5. Individual sector analysis
# ============================================================================
cat("\n=== By Sector ===\n")

sector_results <- list()
for (sec in c("47_retail", "55_accommodation", "56_food_beverage")) {
  sec_data <- panel %>%
    filter(noga == sec) %>%
    mutate(canton_id = as.integer(factor(canton)))

  cs_sec <- tryCatch(
    att_gt(
      yname = "log_emp",
      tname = "year",
      idname = "canton_id",
      gname = "first_treat",
      data = sec_data,
      control_group = "nevertreated",
      anticipation = 0,
      base_period = "universal"
    ),
    error = function(e) { cat("  Error for", sec, ":", e$message, "\n"); NULL }
  )

  if (!is.null(cs_sec)) {
    agg_sec <- aggte(cs_sec, type = "simple")
    cat(sec, ": ATT =", round(agg_sec$overall.att, 4),
        " SE =", round(agg_sec$overall.se, 4), "\n")
    sector_results[[sec]] <- list(cs = cs_sec, agg = agg_sec)
  }
}

# ============================================================================
# 6. Save robustness results
# ============================================================================
rob_results <- list(
  bacon = bacon_out,
  placebo = list(cs = cs_placebo, agg = agg_placebo),
  nocovid = list(cs = cs_nocovid, agg = agg_nocovid),
  by_sector = sector_results
)

saveRDS(rob_results, "../data/robustness.rds")
cat("\nRobustness results saved.\n")
