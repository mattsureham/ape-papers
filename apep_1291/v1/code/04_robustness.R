## 04_robustness.R — Robustness checks for apep_1291
## Placebo borders, bandwidth sensitivity, additional specifications

source("00_packages.R")

panel <- readRDS("../data/panel.rds")
border_panel <- readRDS("../data/border_panel.rds")
models <- readRDS("../data/models.rds")

cat("=== Robustness Checks ===\n")

bp <- border_panel |>
  mutate(
    log_farms = log(n_farms + 1),
    log_avg_size = log(avg_farm_size + 1)
  )

# ---- 1. Placebo border: SD-IA (no NE involvement) ----
cat("\n--- Placebo: SD vs IA interior counties ---\n")

# Counties in SD and IA NOT on the NE border
placebo_data <- panel |>
  filter(STUSPS %in% c("SD", "IA"), !is_border) |>
  mutate(
    placebo_treat = as.integer(STUSPS == "SD"),
    placebo_post = as.integer(year >= 2012),
    placebo_treat_post = placebo_treat * placebo_post,
    log_farms = log(n_farms + 1)
  )

cat(sprintf("  SD interior counties: %d, IA interior counties: %d\n",
    n_distinct(placebo_data$fips[placebo_data$STUSPS == "SD"]),
    n_distinct(placebo_data$fips[placebo_data$STUSPS == "IA"])))

m_placebo_size <- feols(avg_farm_size ~ placebo_treat_post | fips + year,
                        data = placebo_data, vcov = "hetero")
cat("Placebo (SD vs IA interior, avg farm size):\n")
summary(m_placebo_size)

m_placebo_farms <- feols(log_farms ~ placebo_treat_post | fips + year,
                         data = placebo_data, vcov = "hetero")
cat("Placebo (SD vs IA interior, log farms):\n")
summary(m_placebo_farms)

# ---- 2. Placebo timing: pre-treatment period ----
cat("\n--- Placebo timing: 2002-2007 (pre-treatment) ---\n")

bp_pre <- bp |>
  filter(year <= 2007) |>
  mutate(
    fake_post = as.integer(year >= 2007),
    fake_treat_post = treat * fake_post
  )

m_placebo_time <- feols(avg_farm_size ~ fake_treat_post | fips + year,
                        data = bp_pre, cluster = ~STUSPS)
cat("Placebo timing (avg farm size, pre-2007):\n")
summary(m_placebo_time)

# ---- 3. Wider bandwidth samples ----
cat("\n--- All outcomes at different bandwidths ---\n")

bw_results_avg <- list()
bw_results_share <- list()
bw_results_log <- list()

for (bw in c(50, 75, 100, 150)) {
  bw_data <- panel |>
    filter(dist_to_ne_border_km <= bw) |>
    mutate(log_farms = log(n_farms + 1))

  m_a <- feols(avg_farm_size ~ treat_post | fips + year,
               data = bw_data, cluster = ~STUSPS)
  m_s <- tryCatch(
    feols(share_large ~ treat_post | fips + year,
          data = bw_data |> filter(!is.na(share_large)), cluster = ~STUSPS),
    error = function(e) NULL
  )
  m_l <- feols(log_farms ~ treat_post | fips + year,
               data = bw_data, cluster = ~STUSPS)

  bw_results_avg[[as.character(bw)]] <- m_a
  bw_results_share[[as.character(bw)]] <- m_s
  bw_results_log[[as.character(bw)]] <- m_l

  share_str <- if (!is.null(m_s)) sprintf("%.4f (%.4f)", coef(m_s)["treat_post"], se(m_s)["treat_post"]) else "NA"
  cat(sprintf("  BW=%dkm: avg_size=%.1f (%.1f), share_large=%s, N=%d\n",
              bw, coef(m_a)["treat_post"], se(m_a)["treat_post"],
              share_str, n_distinct(bw_data$fips)))
}

# ---- 4. Excluding urban counties ----
cat("\n--- Excluding counties with large cities ---\n")

farm_quartile <- quantile(bp$n_farms[bp$year == 2007], 0.25, na.rm = TRUE)
bp_rural <- bp |> filter(n_farms >= farm_quartile | is.na(n_farms))

m_rural <- feols(avg_farm_size ~ treat_post | fips + year,
                 data = bp_rural, cluster = ~STUSPS)
cat("Rural only (excluding low-farm-count counties):\n")
summary(m_rural)

# ---- 5. Using heteroskedasticity-robust SEs instead ----
cat("\n--- Heteroskedasticity-robust SEs ---\n")

m_robust <- feols(avg_farm_size ~ treat_post | fips + year,
                  data = bp, vcov = "hetero")
cat("HC-robust SEs (avg farm size):\n")
summary(m_robust)

m_robust_farms <- feols(log_farms ~ treat_post | fips + year,
                        data = bp, vcov = "hetero")
cat("HC-robust SEs (log farms):\n")
summary(m_robust_farms)

# ---- 6. Leave-one-state-out ----
cat("\n--- Leave-one-state-out ---\n")

neighbor_states <- c("IA", "KS", "SD", "MO")
loo_results <- list()
for (leave_st in neighbor_states) {
  loo_data <- bp |> filter(STUSPS != leave_st)
  if (n_distinct(loo_data$fips) < 10) next
  m_loo <- feols(avg_farm_size ~ treat_post | fips + year,
                 data = loo_data, cluster = ~STUSPS)
  loo_results[[leave_st]] <- m_loo
  cat(sprintf("  Drop %s: β=%.1f (SE=%.1f), N=%d counties\n",
              leave_st, coef(m_loo)["treat_post"], se(m_loo)["treat_post"],
              n_distinct(loo_data$fips)))
}

# ---- 7. Joint F-test of pre-treatment event study coefficients ----
cat("\n--- Joint F-test of pre-treatment ES coefficients ---\n")

# Pre-treatment coefficients: yr_1997 and yr_2002 (yr_2007 is omitted reference)
pre_treat_pattern <- "yr_1|yr_200[0-6]"

pre_coefs_size <- grep(pre_treat_pattern, names(coef(models$es_size)), value = TRUE)
pre_coefs_farms <- grep(pre_treat_pattern, names(coef(models$es_farms)), value = TRUE)

cat(sprintf("  Pre-treatment coefficients (size): %s\n", paste(pre_coefs_size, collapse = ", ")))
cat(sprintf("  Pre-treatment coefficients (farms): %s\n", paste(pre_coefs_farms, collapse = ", ")))

wald_size <- wald(models$es_size, keep = pre_treat_pattern)
wald_farms <- wald(models$es_farms, keep = pre_treat_pattern)

cat("\nWald test — ES avg_farm_size (H0: pre-treatment coefficients jointly = 0):\n")
print(wald_size)

cat("\nWald test — ES log_farms (H0: pre-treatment coefficients jointly = 0):\n")
print(wald_farms)

# ---- 8. Wild cluster bootstrap p-values ----
cat("\n--- Wild cluster bootstrap p-values ---\n")

if (requireNamespace("fwildclusterboot", quietly = TRUE)) {
  library(fwildclusterboot)

  cat("Using fwildclusterboot (Rademacher weights, full enumeration for 7 clusters)\n")

  # fwildclusterboot requires numeric cluster/FE variables — convert from character
  bp_boot <- as.data.frame(bp |>
    mutate(
      log_farms = log(n_farms + 1),
      fips_num = as.numeric(as.factor(fips)),
      state_num = as.numeric(as.factor(STUSPS))
    ))

  # Re-estimate models with numeric FE/cluster for boottest compatibility
  m_boot_size <- feols(avg_farm_size ~ treat_post | fips_num + year,
                       data = bp_boot, cluster = ~state_num)
  m_boot_farms <- feols(log_farms ~ treat_post | fips_num + year,
                        data = bp_boot, cluster = ~state_num)

  # Bootstrap for avg_farm_size
  cat("\nBootstrapping avg_farm_size (treat_post)...\n")
  boot_size <- tryCatch({
    boottest(m_boot_size,
             param = "treat_post",
             clustid = ~state_num,
             B = 9999,
             type = "rademacher",
             impose_null = TRUE)
  }, error = function(e) {
    cat("  fwildclusterboot error:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(boot_size)) {
    cat(sprintf("  avg_farm_size: boot p-value = %.4f, CI = [%.2f, %.2f]\n",
                pval(boot_size),
                boot_size$conf_int[1], boot_size$conf_int[2]))
  }

  # Bootstrap for log_farms
  cat("\nBootstrapping log_farms (treat_post)...\n")
  boot_farms <- tryCatch({
    boottest(m_boot_farms,
             param = "treat_post",
             clustid = ~state_num,
             B = 9999,
             type = "rademacher",
             impose_null = TRUE)
  }, error = function(e) {
    cat("  fwildclusterboot error:", conditionMessage(e), "\n")
    NULL
  })

  if (!is.null(boot_farms)) {
    cat(sprintf("  log_farms: boot p-value = %.4f, CI = [%.2f, %.2f]\n",
                pval(boot_farms),
                boot_farms$conf_int[1], boot_farms$conf_int[2]))
  }
} else {
  cat("fwildclusterboot not available — using boot package with cluster bootstrap\n")
  library(boot)

  bp_boot <- bp |> mutate(log_farms = log(n_farms + 1))
  clusters <- unique(bp_boot$STUSPS)

  cluster_boot_fn <- function(data, indices, dep_var) {
    sampled_clusters <- clusters[indices]
    boot_data <- do.call(rbind, lapply(sampled_clusters, function(cl) {
      data[data$STUSPS == cl, ]
    }))
    m <- fixest::feols(as.formula(paste(dep_var, "~ treat_post | fips + year")),
                       data = boot_data, vcov = "hetero")
    coef(m)["treat_post"]
  }

  set.seed(42)
  boot_size <- boot(data = bp_boot, statistic = function(d, i) cluster_boot_fn(d, i, "avg_farm_size"),
                    R = 999, sim = "ordinary")
  boot_farms <- boot(data = bp_boot, statistic = function(d, i) cluster_boot_fn(d, i, "log_farms"),
                     R = 999, sim = "ordinary")

  orig_size <- coef(models$m3_avg_size)["treat_post"]
  orig_farms <- coef(models$m2_log_farms)["treat_post"]
  p_size <- mean(abs(boot_size$t) >= abs(orig_size))
  p_farms <- mean(abs(boot_farms$t) >= abs(orig_farms))

  cat(sprintf("  avg_farm_size: cluster bootstrap p-value = %.4f\n", p_size))
  cat(sprintf("  log_farms: cluster bootstrap p-value = %.4f\n", p_farms))
}

# ---- Save robustness results ----
rob_models <- list(
  placebo_size = m_placebo_size,
  placebo_farms = m_placebo_farms,
  placebo_time = m_placebo_time,
  rural_only = m_rural,
  robust_se = m_robust,
  robust_se_farms = m_robust_farms,
  bw_avg = bw_results_avg,
  bw_share = bw_results_share,
  bw_log = bw_results_log,
  loo = loo_results,
  wald_pretreat_size = wald_size,
  wald_pretreat_farms = wald_farms,
  boot_size = if (exists("boot_size")) boot_size else NULL,
  boot_farms = if (exists("boot_farms")) boot_farms else NULL
)
saveRDS(rob_models, "../data/rob_models.rds")

cat("\n=== Robustness checks complete ===\n")
