# =============================================================================
# 04_robustness.R — Robustness and placebo tests
# Paper: The Inertia Break (apep_1279)
# =============================================================================

source("00_packages.R")

cat("Loading analysis data...\n")
con_local <- dbConnect(duckdb())
dt <- as.data.table(dbGetQuery(con_local, "SELECT * FROM '../data/analysis.parquet'"))
dbDisconnect(con_local)

# -----------------------------------------------------------------------
# 1. McCrary Density Test
# -----------------------------------------------------------------------
cat("\n=== McCrary Density Test ===\n")
dens_test <- rddensity(X = dt$age_centered, c = 0)
cat(sprintf("McCrary p-value: %.4f\n", dens_test$test$p_jk))
# If p > 0.05, no evidence of manipulation at cutoff (expected — age isn't manipulable)

# -----------------------------------------------------------------------
# 2. Covariate Balance at Cutoff
# -----------------------------------------------------------------------
cat("\n=== Covariate Balance ===\n")

rd_narrow <- dt[age_1910 %between% c(10, 18)]

covariates <- c("white", "native_born", "literate", "married_1910", "on_farm_1910")
cov_labels <- c("White", "Native Born", "Literate", "Married", "On Farm (1910)")

balance_results <- list()
for (i in seq_along(covariates)) {
  cov_fit <- feols(as.formula(paste(covariates[i], "~ draft_eligible + age_centered + draft_eligible:age_centered | statefip_1910")),
                   data = rd_narrow,
                   cluster = ~statefip_1910)
  balance_results[[covariates[i]]] <- list(
    coef = coef(cov_fit)["draft_eligible"],
    se = se(cov_fit)["draft_eligible"],
    pval = pvalue(cov_fit)["draft_eligible"]
  )
  cat(sprintf("  %s: coef=%.4f, se=%.4f, p=%.3f\n",
              cov_labels[i],
              coef(cov_fit)["draft_eligible"],
              se(cov_fit)["draft_eligible"],
              pvalue(cov_fit)["draft_eligible"]))
}

# -----------------------------------------------------------------------
# 3. Placebo Cutoffs
# -----------------------------------------------------------------------
cat("\n=== Placebo Cutoffs ===\n")

# Test at ages 10, 11, 12 (all below true cutoff) — should be zero
placebo_data <- dt[age_1910 %between% c(8, 13)]  # Entirely below true cutoff

placebo_results <- list()
for (placebo_age in c(10, 11, 12)) {
  placebo_data[, placebo_treat := as.integer(age_1910 >= placebo_age)]
  placebo_data[, placebo_centered := age_1910 - placebo_age]

  pfit <- feols(farm_exit ~ placebo_treat + placebo_centered +
                  placebo_treat:placebo_centered | statefip_1910,
                data = placebo_data,
                cluster = ~statefip_1910)
  placebo_results[[as.character(placebo_age)]] <- list(
    coef = coef(pfit)["placebo_treat"],
    se = se(pfit)["placebo_treat"],
    pval = pvalue(pfit)["placebo_treat"]
  )
  cat(sprintf("  Placebo at age %d: coef=%.4f, se=%.4f, p=%.3f\n",
              placebo_age,
              coef(pfit)["placebo_treat"],
              se(pfit)["placebo_treat"],
              pvalue(pfit)["placebo_treat"]))
}

# -----------------------------------------------------------------------
# 4. Bandwidth Sensitivity
# -----------------------------------------------------------------------
cat("\n=== Bandwidth Sensitivity ===\n")

bw_results <- list()
for (bw in c(3, 4, 5, 6)) {
  bw_data <- dt[abs(age_centered) <= bw]
  bw_fit <- feols(farm_exit ~ draft_eligible + age_centered +
                    draft_eligible:age_centered | statefip_1910,
                  data = bw_data,
                  cluster = ~statefip_1910)
  bw_results[[as.character(bw)]] <- list(
    coef = coef(bw_fit)["draft_eligible"],
    se = se(bw_fit)["draft_eligible"],
    n = nrow(bw_data)
  )
  cat(sprintf("  BW=%d: coef=%.4f, se=%.4f, N=%s\n",
              bw,
              coef(bw_fit)["draft_eligible"],
              se(bw_fit)["draft_eligible"],
              format(nrow(bw_data), big.mark = ",")))
}

# -----------------------------------------------------------------------
# 5. Donut-Hole RD (exclude ages exactly at cutoff)
# -----------------------------------------------------------------------
cat("\n=== Donut-Hole RD ===\n")

donut_data <- dt[age_1910 %between% c(10, 18) & !(age_1910 %in% c(13, 14))]
donut_fit <- feols(farm_exit ~ draft_eligible + age_centered +
                     draft_eligible:age_centered | statefip_1910,
                   data = donut_data,
                   cluster = ~statefip_1910)
cat("Donut-hole RD (excluding ages 13-14):\n")
summary(donut_fit)

# -----------------------------------------------------------------------
# 6. Quadratic RD
# -----------------------------------------------------------------------
cat("\n=== Quadratic RD ===\n")

rd_narrow[, age_centered_sq := age_centered^2]
quad_farm <- feols(farm_exit ~ draft_eligible + age_centered + age_centered_sq +
                     draft_eligible:age_centered + draft_eligible:age_centered_sq |
                     statefip_1910,
                   data = rd_narrow,
                   cluster = ~statefip_1910)
cat("Quadratic RD — Farm Exit:\n")
summary(quad_farm)

quad_occ <- feols(delta_occscore ~ draft_eligible + age_centered + age_centered_sq +
                    draft_eligible:age_centered + draft_eligible:age_centered_sq |
                    statefip_1910,
                  data = rd_narrow,
                  cluster = ~statefip_1910)
cat("Quadratic RD — Delta Occ Score:\n")
summary(quad_occ)

# -----------------------------------------------------------------------
# Save robustness results
# -----------------------------------------------------------------------
save(dens_test, balance_results, placebo_results, bw_results,
     donut_fit, quad_farm, quad_occ,
     file = "../data/robustness_results.RData")

cat("\nAll robustness checks complete.\n")
