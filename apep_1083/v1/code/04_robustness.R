# 04_robustness.R — Robustness checks and RDD
source("00_packages.R")

paper_root <- normalizePath(file.path(getwd(), ".."), mustWork = FALSE)
if (file.exists(file.path(paper_root, "data"))) setwd(paper_root)

panel <- readRDS("data/panel.rds")
panel <- panel %>% mutate(event_time = year - 2012)

cat("=== Robustness Checks ===\n")

# ---------------------------------------------------------------
# 1) Canton × Year FE (absorb regional trends)
# ---------------------------------------------------------------
cat("\n--- Canton × Year Fixed Effects ---\n")

# Create canton-year interaction
panel <- panel %>%
  mutate(canton_year = paste0(canton, "_", year))

outcomes <- c("log_residential", "log_commercial", "log_total",
              "log_non_residential", "log_roads")
labels <- c("Residential", "Commercial", "Total", "Non-Residential", "Roads (Placebo)")

canton_results <- list()
for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  # Binary DiD with canton×year FE
  fml <- as.formula(paste0(y, " ~ treat_post | muni_code + canton^year"))
  fit <- feols(fml, data = panel, cluster = "muni_code")
  cat(sprintf("  %s: Beta = %.4f (SE = %.4f), p = %.4f\n", labels[i],
    coef(fit)["treat_post"], se(fit)["treat_post"], pvalue(fit)["treat_post"]))
  canton_results[[y]] <- fit
}

# Event study with canton×year FE
cat("\n--- Event Study with Canton×Year FE ---\n")
es_canton_res <- feols(
  log_residential ~ i(event_time, treated, ref = -1) | muni_code + canton^year,
  data = panel, cluster = "muni_code"
)

es_canton_com <- feols(
  log_commercial ~ i(event_time, treated, ref = -1) | muni_code + canton^year,
  data = panel, cluster = "muni_code"
)

# Pre-trend test with canton×year FE
pre_test_canton <- wald(es_canton_res,
  paste0("event_time::", -18:-2, ":treated"))
cat(sprintf("Pre-trend F-test (canton×year): F=%.2f, p=%.4f\n",
  pre_test_canton$stat, pre_test_canton$p))

# ---------------------------------------------------------------
# 2) Continuous intensity DiD with canton×year FE
# ---------------------------------------------------------------
cat("\n--- Continuous Intensity with Canton×Year FE ---\n")

for (i in seq_along(outcomes)) {
  y <- outcomes[i]
  fml <- as.formula(paste0(y, " ~ intensity_post | muni_code + canton^year"))
  fit <- feols(fml, data = panel, cluster = "muni_code")
  cat(sprintf("  %s: Beta = %.4f (SE = %.4f), p = %.4f\n", labels[i],
    coef(fit)["intensity_post"], se(fit)["intensity_post"], pvalue(fit)["intensity_post"]))
}

# ---------------------------------------------------------------
# 3) RDD at 20% threshold
# ---------------------------------------------------------------
cat("\n--- RDD at 20% Second-Home Threshold ---\n")

# Construct RDD dataset: change in construction investment around 2012
# Outcome: difference in mean investment (2013-2018) vs (2006-2011)
rdd_data <- panel %>%
  mutate(period = ifelse(year %in% 2006:2011, "pre", ifelse(year %in% 2013:2018, "post", NA))) %>%
  filter(!is.na(period)) %>%
  group_by(muni_code, period) %>%
  summarise(
    mean_residential = mean(residential, na.rm = TRUE),
    mean_commercial = mean(commercial, na.rm = TRUE),
    mean_total = mean(total, na.rm = TRUE),
    second_home_share = first(second_home_share),
    pct_second_home = first(pct_second_home),
    treated = first(treated),
    canton = first(canton),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = period,
    values_from = c(mean_residential, mean_commercial, mean_total),
    names_sep = "_"
  ) %>%
  mutate(
    # Change in investment
    delta_residential = log(mean_residential_post + 1) - log(mean_residential_pre + 1),
    delta_commercial = log(mean_commercial_post + 1) - log(mean_commercial_pre + 1),
    delta_total = log(mean_total_post + 1) - log(mean_total_pre + 1),
    # Running variable centered at 20%
    running = pct_second_home - 20
  )

cat(sprintf("RDD dataset: %d municipalities\n", nrow(rdd_data)))
cat(sprintf("  Below 20%%: %d, Above 20%%: %d\n",
  sum(rdd_data$running < 0, na.rm = TRUE), sum(rdd_data$running >= 0, na.rm = TRUE)))

# Sharp RDD
if (sum(rdd_data$running >= 0, na.rm = TRUE) >= 20) {
  rdd_res <- rdrobust(rdd_data$delta_residential, rdd_data$running, c = 0)
  cat(sprintf("\nRDD: Residential (rdrobust)\n"))
  cat(sprintf("  Estimate = %.4f (SE = %.4f), p = %.4f\n",
    rdd_res$coef[1], rdd_res$se[1], rdd_res$pv[1]))
  cat(sprintf("  Bandwidth: %.2f (h=%.2f)\n", rdd_res$bws[1,1], rdd_res$bws[1,2]))
  cat(sprintf("  N below: %d, N above: %d\n", rdd_res$N_h[1], rdd_res$N_h[2]))

  rdd_com <- rdrobust(rdd_data$delta_commercial, rdd_data$running, c = 0)
  cat(sprintf("\nRDD: Commercial (rdrobust)\n"))
  cat(sprintf("  Estimate = %.4f (SE = %.4f), p = %.4f\n",
    rdd_com$coef[1], rdd_com$se[1], rdd_com$pv[1]))

  rdd_tot <- rdrobust(rdd_data$delta_total, rdd_data$running, c = 0)
  cat(sprintf("\nRDD: Total (rdrobust)\n"))
  cat(sprintf("  Estimate = %.4f (SE = %.4f), p = %.4f\n",
    rdd_tot$coef[1], rdd_tot$se[1], rdd_tot$pv[1]))

  # Density test at cutoff
  dens_test <- rddensity(rdd_data$running)
  cat(sprintf("\nDensity test at cutoff: T=%.3f, p=%.4f\n",
    dens_test$test$t_jk, dens_test$test$p_jk))
} else {
  cat("Insufficient observations above threshold for RDD\n")
  rdd_res <- NULL; rdd_com <- NULL; rdd_tot <- NULL
}

# ---------------------------------------------------------------
# 4) Heterogeneity: Alpine vs Non-Alpine cantons
# ---------------------------------------------------------------
cat("\n--- Heterogeneity: Alpine vs Non-Alpine ---\n")

alpine_cantons <- c("VS", "GR", "UR", "OW", "NW", "GL", "TI", "BE", "SZ")
panel <- panel %>%
  mutate(alpine = as.integer(canton %in% alpine_cantons))

# Split regressions
for (alp in c(1, 0)) {
  label <- if (alp == 1) "Alpine" else "Non-Alpine"
  sub <- panel %>% filter(alpine == alp)
  fit <- feols(log_total ~ treat_post | muni_code + year,
               data = sub, cluster = "muni_code")
  cat(sprintf("  %s: Beta = %.4f (SE = %.4f), n_treated = %d, n_control = %d\n",
    label, coef(fit)["treat_post"], se(fit)["treat_post"],
    n_distinct(sub$muni_code[sub$treated == 1]),
    n_distinct(sub$muni_code[sub$treated == 0])))
}

# ---------------------------------------------------------------
# 5) Save robustness results
# ---------------------------------------------------------------
robustness <- list(
  canton_fe = canton_results,
  es_canton_res = es_canton_res,
  es_canton_com = es_canton_com,
  rdd_data = rdd_data,
  rdd_res = if (exists("rdd_res")) rdd_res else NULL,
  rdd_com = if (exists("rdd_com")) rdd_com else NULL,
  rdd_tot = if (exists("rdd_tot")) rdd_tot else NULL
)
saveRDS(robustness, "data/robustness.rds")
cat("\nSaved data/robustness.rds\n")
