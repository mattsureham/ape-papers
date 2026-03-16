# ==============================================================================
# 04_robustness.R — Placebo and robustness checks
# ==============================================================================

source("00_packages.R")

women <- readRDS("../data/analysis_sample.rds")
setDT(women)
women[, exposure_std := (exposure - mean(exposure)) / sd(exposure)]

results <- readRDS("../data/main_results.rds")

# --------------------------------------------------------------------------
# Robustness 1: Placebo — 1910-1920 (pre-Act period)
# If exposure predicts LFP changes before 1924, the design fails
# --------------------------------------------------------------------------
cat("\n=== PLACEBO: 1910-1920 ===\n")

placebo <- readRDS("../data/placebo_sample.rds")
setDT(placebo)
placebo[, exposure_std := (exposure - mean(exposure)) / sd(exposure)]

p1 <- feols(d_lfp ~ exposure_std + age_1910 + I(age_1910^2) +
              lit_1910 + nchild_1910 | state,
            data = placebo, cluster = ~county_id)

p2 <- feols(d_lfp ~ exposure_std + age_1910 + I(age_1910^2) +
              lit_1910 + nchild_1910 | state,
            data = placebo[married_1910 == 1], cluster = ~county_id)

p3 <- feols(d_lfp ~ exposure_std + age_1910 + I(age_1910^2) +
              lit_1910 + nchild_1910 | state,
            data = placebo[married_1910 == 0], cluster = ~county_id)

cat("Placebo - All:\n"); print(summary(p1))
cat("Placebo - Married:\n"); print(summary(p2))
cat("Placebo - Unmarried:\n"); print(summary(p3))

# --------------------------------------------------------------------------
# Robustness 2: Urban/Rural heterogeneity
# --------------------------------------------------------------------------
cat("\n=== Urban/Rural Heterogeneity ===\n")

u1 <- feols(d_lfp ~ exposure_std + age_1920 + I(age_1920^2) +
              lit_1920 + nchild_1920 | state,
            data = women[urban_1920 == 1 & married_1920 == 1], cluster = ~county_id)

u2 <- feols(d_lfp ~ exposure_std + age_1920 + I(age_1920^2) +
              lit_1920 + nchild_1920 | state,
            data = women[urban_1920 == 0 & married_1920 == 1], cluster = ~county_id)

cat("Urban married:\n"); print(summary(u1))
cat("Rural married:\n"); print(summary(u2))

# --------------------------------------------------------------------------
# Robustness 3: Non-movers only (address selection)
# --------------------------------------------------------------------------
cat("\n=== Non-Movers Only ===\n")

nm1 <- feols(d_lfp ~ exposure_std + age_1920 + I(age_1920^2) +
              lit_1920 + i(farm_1920) + nchild_1920 | state,
            data = women[mover == 0], cluster = ~county_id)

nm2 <- feols(d_lfp ~ exposure_std + age_1920 + I(age_1920^2) +
              lit_1920 + i(farm_1920) + nchild_1920 | state,
            data = women[mover == 0 & married_1920 == 1], cluster = ~county_id)

cat("Non-movers all:\n"); print(summary(nm1))
cat("Non-movers married:\n"); print(summary(nm2))

# --------------------------------------------------------------------------
# Robustness 4: Alternative exposure — domestic servants specifically
# --------------------------------------------------------------------------
cat("\n=== Domestic Servant Exposure ===\n")

women[, exposure_dom_std := (exposure_domestic - mean(exposure_domestic)) / sd(exposure_domestic)]

ds1 <- feols(d_lfp ~ exposure_dom_std + age_1920 + I(age_1920^2) +
              lit_1920 + i(farm_1920) + nchild_1920 | state,
            data = women[married_1920 == 1], cluster = ~county_id)

cat("Domestic servant exposure:\n"); print(summary(ds1))

# --------------------------------------------------------------------------
# Robustness 5: Covariate balance — exposure should not predict 1920 levels
# --------------------------------------------------------------------------
cat("\n=== Covariate Balance ===\n")

bal <- list(
  age = feols(age_1920 ~ exposure_std | state, data = women, cluster = ~county_id),
  lit = feols(I(lit_1920 == 4) ~ exposure_std | state, data = women, cluster = ~county_id),
  married = feols(married_1920 ~ exposure_std | state, data = women, cluster = ~county_id),
  nchild = feols(nchild_1920 ~ exposure_std | state, data = women, cluster = ~county_id),
  farm = feols(I(farm_1920 == 2) ~ exposure_std | state, data = women, cluster = ~county_id)
)

for (nm in names(bal)) {
  cat(nm, ": coef =", round(coef(bal[[nm]])["exposure_std"], 4),
      " se =", round(se(bal[[nm]])["exposure_std"], 4), "\n")
}

# --------------------------------------------------------------------------
# Save robustness results
# --------------------------------------------------------------------------
rob <- list(
  placebo_all = p1, placebo_married = p2, placebo_unmarried = p3,
  urban_married = u1, rural_married = u2,
  nonmover_all = nm1, nonmover_married = nm2,
  domestic_exposure = ds1,
  balance = bal,
  n_placebo = nrow(placebo),
  n_nonmovers = sum(women$mover == 0)
)

saveRDS(rob, "../data/robustness_results.rds")

cat("Robustness checks complete.\n")
