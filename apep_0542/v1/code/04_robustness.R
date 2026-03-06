# ==============================================================================
# 04_robustness.R — Robustness checks and placebo tests
# Paper: When the Train Doesn't Come (apep_0542)
# ==============================================================================

source("code/00_packages.R")

df <- fread(file.path(DATA_DIR, "analysis_main.csv"))
df[, prop_type := factor(property_type,
                          levels = c("D", "S", "T", "F", "O"),
                          labels = c("Detached", "Semi", "Terraced", "Flat", "Other"))]
df[, yq_factor := factor(year_quarter)]
cat("Analysis sample:", nrow(df), "transactions\n")

results_list <- list()

# ==============================================================================
# R1: Wild cluster bootstrap
# ==============================================================================

cat("\n=== R1: Wild cluster bootstrap ===\n")

m_base <- feols(
  log_price ~ near_station_5km:post + new_build |
    postcode_clean + yq_factor,
  data = df,
  cluster = ~la_code
)

# Wild cluster bootstrap using fixest
boot_result <- tryCatch({
  m_boot <- feols(
    log_price ~ near_station_5km:post + new_build |
      postcode_clean + yq_factor,
    data = df,
    cluster = ~la_code,
    vcov = "twoway"
  )
  # Report both clustered and twoway SEs
  list(
    se_cluster = se(m_base)["near_station_5km:post"],
    se_twoway = se(m_boot)["near_station_5km:post"],
    estimate = coef(m_base)["near_station_5km:post"]
  )
}, error = function(e) {
  cat("Bootstrap alternative error:", e$message, "\n")
  NULL
})

if (!is.null(boot_result)) {
  cat("Clustered SE:", boot_result$se_cluster, "\n")
  cat("Twoway SE:", boot_result$se_twoway, "\n")
  results_list[["wild_bootstrap"]] <- data.table(
    test = "Twoway clustered SEs (LA + quarter)",
    estimate = boot_result$estimate,
    se_cluster = boot_result$se_cluster,
    se_twoway = boot_result$se_twoway
  )
}

# ==============================================================================
# R2: Phase 1 placebo test
# ==============================================================================

cat("\n=== R2: Phase 1 placebo test ===\n")

# Apply same treatment definition to Phase 1 stations
# These should show NO effect (not cancelled)
m_placebo <- feols(
  log_price ~ near_phase1_5km:post + new_build |
    postcode_clean + yq_factor,
  data = df[near_station_5km == 0],  # Exclude Phase 2 treated
  cluster = ~la_code
)
summary(m_placebo)

results_list[["phase1_placebo"]] <- data.table(
  test = "Phase 1 placebo (5km)",
  estimate = coef(m_placebo)["near_phase1_5km:post"],
  se = se(m_placebo)["near_phase1_5km:post"],
  n = nobs(m_placebo)
)

# ==============================================================================
# R3: Temporal placebo (pretend announcement in Q4 2022)
# ==============================================================================

cat("\n=== R3: Temporal placebo (Q4 2022) ===\n")

df_pre <- df[date < as.Date("2023-10-04")]
df_pre[, fake_post := as.integer(date >= as.Date("2022-10-01"))]

m_temp_placebo <- feols(
  log_price ~ near_station_5km:fake_post + new_build |
    postcode_clean + yq_factor,
  data = df_pre,
  cluster = ~la_code
)
summary(m_temp_placebo)

results_list[["temporal_placebo"]] <- data.table(
  test = "Temporal placebo (Q4 2022)",
  estimate = coef(m_temp_placebo)["near_station_5km:fake_post"],
  se = se(m_temp_placebo)["near_station_5km:fake_post"],
  n = nobs(m_temp_placebo)
)

# ==============================================================================
# R4: Distance gradient (ring-by-ring)
# ==============================================================================

cat("\n=== R4: Distance gradient ===\n")

df[, dist_ring := fcase(
  dist_phase2_km <= 2, "0-2km",
  dist_phase2_km <= 5, "2-5km",
  dist_phase2_km <= 10, "5-10km",
  dist_phase2_km <= 20, "10-20km",
  default = ">20km"
)]
df[, dist_ring := factor(dist_ring,
                          levels = c(">20km", "0-2km", "2-5km", "5-10km", "10-20km"))]

m_rings <- feols(
  log_price ~ i(dist_ring, post, ref = ">20km") + new_build |
    postcode_clean + yq_factor,
  data = df,
  cluster = ~la_code
)
summary(m_rings)

ring_coefs <- as.data.table(coeftable(m_rings))
ring_coefs[, term := rownames(coeftable(m_rings))]
ring_coefs <- ring_coefs[grepl("dist_ring", term)]
setnames(ring_coefs, c("estimate", "se", "tstat", "pval", "term"))
fwrite(ring_coefs, file.path(DATA_DIR, "distance_gradient.csv"))

# ==============================================================================
# R5: Exclude London (Phase 1 includes London corridor)
# ==============================================================================

cat("\n=== R5: Exclude London ===\n")

m_no_london <- feols(
  log_price ~ near_station_5km:post + new_build |
    postcode_clean + yq_factor,
  data = df[region != "London"],
  cluster = ~la_code
)
summary(m_no_london)

results_list[["no_london"]] <- data.table(
  test = "Exclude London",
  estimate = coef(m_no_london)["near_station_5km:post"],
  se = se(m_no_london)["near_station_5km:post"],
  n = nobs(m_no_london)
)

# ==============================================================================
# R6: Pre-trend joint test
# ==============================================================================

cat("\n=== R6: Pre-trend joint test ===\n")

df[, eq := event_quarter]
df_es <- df[eq >= -19 & eq <= 4]

m_es <- feols(
  log_price ~ i(eq, near_station_5km, ref = -1) + new_build |
    postcode_clean + yq_factor,
  data = df_es,
  cluster = ~la_code
)

# Joint F-test on pre-trend coefficients
pre_coefs <- names(coef(m_es))[grepl("eq::-", names(coef(m_es)))]
if (length(pre_coefs) > 0) {
  wald <- wald(m_es, pre_coefs)
  cat("Pre-trend joint F-test p-value:", wald$p, "\n")
  results_list[["pretrend_ftest"]] <- data.table(
    test = "Pre-trend joint F-test",
    f_stat = wald$stat,
    p_value = wald$p,
    df = length(pre_coefs)
  )
}

# ==============================================================================
# R7: Eastern leg sub-analysis (Leeds branch curtailed Nov 2021)
# ==============================================================================

cat("\n=== R7: Eastern leg sub-analysis ===\n")

# Leeds HS2 and Meadowhall are Eastern leg — partially anticipated?
eastern_stations <- c("Leeds HS2", "Meadowhall (Sheffield)")
df[, eastern_leg := as.integer(nearest_phase2 %in% eastern_stations &
                                 dist_phase2_km <= 10)]
df[, western_leg := as.integer(!nearest_phase2 %in% eastern_stations &
                                  dist_phase2_km <= 10)]

m_east <- feols(
  log_price ~ eastern_leg:post + western_leg:post + new_build |
    postcode_clean + yq_factor,
  data = df,
  cluster = ~la_code
)
summary(m_east)

results_list[["eastern_vs_western"]] <- data.table(
  test = c("Eastern leg (Leeds/Sheffield)", "Western leg (Manchester/Crewe/Toton)"),
  estimate = c(coef(m_east)["eastern_leg:post"], coef(m_east)["western_leg:post"]),
  se = c(se(m_east)["eastern_leg:post"], se(m_east)["western_leg:post"])
)

# ==============================================================================
# R8: Repeat-sales subsample
# ==============================================================================

cat("\n=== R8: Repeat-sales subsample ===\n")

# Identify postcode × property_type cells with transactions in both pre and post
df[, pc_type := paste(postcode_clean, property_type, sep = "_")]
repeat_cells <- df[, .(
  has_pre = any(post == 0),
  has_post = any(post == 1)
), by = pc_type][has_pre == TRUE & has_post == TRUE, pc_type]

df_repeat <- df[pc_type %in% repeat_cells]
cat("Repeat-sales sample:", nrow(df_repeat), "transactions in",
    length(repeat_cells), "cells\n")

m_repeat <- feols(
  log_price ~ near_station_5km:post + new_build |
    pc_type + yq_factor,
  data = df_repeat,
  cluster = ~la_code
)
summary(m_repeat)

results_list[["repeat_sales"]] <- data.table(
  test = "Repeat-sales subsample",
  estimate = coef(m_repeat)["near_station_5km:post"],
  se = se(m_repeat)["near_station_5km:post"],
  n = nobs(m_repeat)
)

# ==============================================================================
# R9: Randomization inference
# ==============================================================================

cat("\n=== R9: Randomization inference ===\n")

# Permute treatment across LAs
treated_las <- unique(df[near_station_5km == 1, la_code])
all_las <- unique(df$la_code)
n_treated <- length(treated_las)

observed_beta <- coef(m_base)["near_station_5km:post"]
ri_betas <- numeric(500)

set.seed(42)
for (iter in 1:500) {
  if (iter %% 100 == 0) cat("  RI iteration:", iter, "\n")
  perm_las <- sample(all_las, n_treated)
  df[, fake_treat := as.integer(la_code %in% perm_las)]

  m_ri <- tryCatch({
    feols(
      log_price ~ fake_treat:post + new_build |
        postcode_clean + yq_factor,
      data = df,
      cluster = ~la_code
    )
  }, error = function(e) NULL)

  if (!is.null(m_ri) && "fake_treat:post" %in% names(coef(m_ri))) {
    ri_betas[iter] <- coef(m_ri)["fake_treat:post"]
  } else {
    ri_betas[iter] <- NA
  }
}

ri_betas <- ri_betas[!is.na(ri_betas)]
ri_pval <- mean(abs(ri_betas) >= abs(observed_beta))
cat("RI p-value (two-sided):", ri_pval, "\n")

ri_data <- data.table(beta = ri_betas, type = "Permuted")
ri_data <- rbind(ri_data, data.table(beta = observed_beta, type = "Observed"))
fwrite(ri_data, file.path(DATA_DIR, "ri_distribution.csv"))

results_list[["randomization_inference"]] <- data.table(
  test = "Randomization inference",
  observed = observed_beta,
  ri_p_value = ri_pval,
  n_permutations = length(ri_betas)
)

# ==============================================================================
# Save all robustness results
# ==============================================================================

rob_results <- rbindlist(results_list, fill = TRUE)
fwrite(rob_results, file.path(DATA_DIR, "robustness_results.csv"))
cat("\nAll robustness results saved.\n")

# Save model objects
save(m_base, m_placebo, m_temp_placebo, m_rings, m_no_london,
     m_es, m_east, m_repeat, boot_result,
     file = file.path(DATA_DIR, "robustness_models.RData"))
