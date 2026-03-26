# 04_robustness.R — Robustness checks and placebos
# apep_0990: Nebraska groundwater allocations and crop adaptation

source("00_packages.R")

results <- readRDS("../data/main_results.rds")
panel <- results$panel

cat("=== Robustness Checks ===\n")

# --- 1. HonestDiD sensitivity for corn share ---
cat("\n--- 1. HonestDiD Rambachan-Roth bounds (corn share) ---\n")

tryCatch({
  es_corn_obj <- results$es_corn

  # Extract pre-treatment coefficients and variance-covariance
  betahat <- es_corn_obj$att.egt
  sigma <- es_corn_obj$att.egt.se

  # Get event times
  e_times <- es_corn_obj$egt

  # Pre-treatment indices
  pre_idx <- which(e_times < 0)
  post_idx <- which(e_times >= 0)

  if (length(pre_idx) >= 2 && length(post_idx) >= 1) {
    # Create diagonal variance matrix (CS reports pointwise SEs)
    V <- diag(sigma^2)

    honest_results <- HonestDiD::createSensitivityResults(
      betahat = betahat,
      sigma = V,
      numPrePeriods = length(pre_idx),
      numPostPeriods = length(post_idx),
      Mvec = seq(0, 0.05, by = 0.01),
      method = "C-LF"
    )

    cat("HonestDiD sensitivity results:\n")
    print(honest_results)
    saveRDS(honest_results, "../data/honestdid_corn.rds")
  } else {
    cat("  Insufficient pre/post periods for HonestDiD\n")
  }
}, error = function(e) {
  cat("  HonestDiD failed:", e$message, "\n")
  cat("  Continuing with other robustness checks.\n")
})

# --- 2. Bootstrap inference for main results ---
cat("\n--- 2. Bootstrap inference (block bootstrap at NRD level) ---\n")

tryCatch({
  # Block bootstrap at NRD level for corn share TWFE
  nrd_list <- unique(panel$nrd_name)
  n_nrds <- length(nrd_list)
  B <- 999
  boot_coefs <- numeric(B)

  for (b in 1:B) {
    boot_nrds <- sample(nrd_list, n_nrds, replace = TRUE)
    boot_data <- do.call(rbind, lapply(seq_along(boot_nrds), function(i) {
      d <- panel[panel$nrd_name == boot_nrds[i], ]
      d$county_id <- d$county_id + i * 10000L  # unique IDs per bootstrap draw
      d
    }))
    boot_fit <- tryCatch(
      feols(corn_share ~ treated | county_id + year, data = boot_data),
      error = function(e) NULL
    )
    if (!is.null(boot_fit)) boot_coefs[b] <- coef(boot_fit)["treated"]
  }

  boot_se <- sd(boot_coefs, na.rm = TRUE)
  orig_coef <- coef(results$twfe_corn)["treated"]
  boot_pval <- mean(abs(boot_coefs) >= abs(orig_coef), na.rm = TRUE)

  cat("Block bootstrap (corn share):\n")
  cat("  Point estimate:", orig_coef, "\n")
  cat("  Bootstrap SE:", boot_se, "\n")
  cat("  Bootstrap p-value:", boot_pval, "\n")
  cat("  Bootstrap 95% CI:", quantile(boot_coefs, c(0.025, 0.975), na.rm = TRUE), "\n")

  saveRDS(list(coefs = boot_coefs, se = boot_se, p_val = boot_pval),
          "../data/boot_corn.rds")
}, error = function(e) {
  cat("  Bootstrap failed:", e$message, "\n")
})

# --- 3. Placebo: Soybean share (water-intensive but not primary irrigation crop) ---
cat("\n--- 3. Placebo: soybean share ---\n")

twfe_soybean <- feols(soybean_share ~ treated | county_id + year,
                      data = panel, cluster = ~nrd_name)
cat("TWFE placebo (soybean share):\n")
summary(twfe_soybean)

# --- 4. Leave-one-out: Drop Upper Republican (earliest adopter, 1979) ---
cat("\n--- 4. Leave-one-out: Drop Upper Republican NRD ---\n")

panel_loo <- panel %>%
  filter(nrd_name != "Upper Republican") %>%
  mutate(county_id = as.integer(as.factor(county_fips)))

twfe_loo <- feols(corn_share ~ treated | county_id + year,
                  data = panel_loo, cluster = ~nrd_name)
cat("TWFE without Upper Republican:\n")
summary(twfe_loo)

# --- 5. Alternative control group: never-treated only ---
cat("\n--- 5. CS with never-treated control group ---\n")

tryCatch({
  cs_corn_nt <- att_gt(
    yname = "corn_share",
    tname = "year",
    idname = "county_id",
    gname = "first_treat",
    data = panel %>% filter(!is.na(corn_share)),
    control_group = "nevertreated",
    anticipation = 0,
    base_period = "universal",
    allow_unbalanced_panel = TRUE
  )

  att_corn_nt <- aggte(cs_corn_nt, type = "simple", na.rm = TRUE)
  cat("ATT with never-treated controls:", att_corn_nt$overall.att,
      "SE:", att_corn_nt$overall.se, "\n")

  saveRDS(cs_corn_nt, "../data/cs_corn_nevertreated.rds")
}, error = function(e) {
  cat("  Never-treated CS failed:", e$message, "\n")
})

# --- 6. Group-specific ATTs by adoption cohort ---
cat("\n--- 6. Group-specific effects ---\n")

tryCatch({
  group_atts <- aggte(results$cs_corn, type = "group", na.rm = TRUE)
  cat("Group-specific ATTs (corn share):\n")
  summary(group_atts)
  saveRDS(group_atts, "../data/group_atts_corn.rds")
}, error = function(e) {
  cat("  Group ATTs failed:", e$message, "\n")
})

# --- Save robustness results ---
robustness <- list(
  twfe_soybean_placebo = twfe_soybean,
  twfe_loo = twfe_loo
)

saveRDS(robustness, "../data/robustness_results.rds")

cat("\n=== Robustness checks complete ===\n")
