## 04_robustness.R — Robustness checks: placebo, IV, heterogeneity, MDE

source("00_packages.R")

data_dir <- "../data"
load(file.path(data_dir, "main_results.RData"))

cat("=== ROBUSTNESS CHECKS ===\n")
cat(sprintf("Analysis sample: %d obs, %d municipalities\n\n",
            nrow(analysis_full), uniqueN(analysis_full$bfsnr)))

# ── 1. Placebo: Natural-person Steuerfuss → spending ────────────────────────
cat("--- 1. Placebo: Natural-person Steuerfuss ---\n")
cor_rates <- cor(analysis_full$stf_corp, analysis_full$stf_nat, use = "complete.obs")
cat(sprintf("Correlation corp vs nat-person rate: %.3f\n", cor_rates))

placebo_results <- list()
for (y in c("total_exp_pc", "education_pc", "social_pc", "tax_revenue_pc")) {
  if (!y %in% names(analysis_full) || sum(!is.na(analysis_full[[y]])) < 50) next
  fml <- as.formula(paste0(y, " ~ stf_nat + pop_growth | bfsnr + year"))
  fit <- feols(fml, data = analysis_full, cluster = ~bfsnr)
  placebo_results[[y]] <- fit
  cat(sprintf("  %s: β(stf_nat) = %.3f (%.3f), p = %.3f\n",
              y, coef(fit)["stf_nat"], se(fit)["stf_nat"], pvalue(fit)["stf_nat"]))
}

# Horse race: both rates simultaneously
cat("\n--- Horse race ---\n")
horse_results <- list()
for (y in c("total_exp_pc", "education_pc", "social_pc", "tax_revenue_pc")) {
  if (!y %in% names(analysis_full) || sum(!is.na(analysis_full[[y]])) < 50) next
  fml <- as.formula(paste0(y, " ~ stf_corp + stf_nat + pop_growth | bfsnr + year"))
  fit <- feols(fml, data = analysis_full, cluster = ~bfsnr)
  horse_results[[y]] <- fit
  cat(sprintf("  %s: β(corp)=%.2f(%.2f), β(nat)=%.2f(%.2f)\n",
              y, coef(fit)["stf_corp"], se(fit)["stf_corp"],
              coef(fit)["stf_nat"], se(fit)["stf_nat"]))
}

# ── 2. Neighbor-rate IV (Parchet 2019) ──────────────────────────────────────
cat("\n--- 2. Neighbor-rate IV ---\n")
# Use district (Bezirk) as neighbor definition
analysis_full[, district := floor(bfsnr / 100)]
analysis_full[, n_in_district := .N, by = .(district, year)]
analysis_full[, sum_stf_district := sum(stf_corp, na.rm = TRUE), by = .(district, year)]
analysis_full[, neighbor_stf := (sum_stf_district - stf_corp) / (n_in_district - 1)]

iv_data <- analysis_full[!is.na(neighbor_stf) & n_in_district > 2 & is.finite(neighbor_stf)]
cat(sprintf("IV sample: %d obs, %d districts\n", nrow(iv_data), uniqueN(iv_data$district)))

iv_results <- list()
if (nrow(iv_data) > 100) {
  # First stage
  fs <- feols(stf_corp ~ neighbor_stf + pop_growth | bfsnr + year,
              data = iv_data, cluster = ~bfsnr)
  f_stat <- fitstat(fs, "ivf")[[1]]
  cat(sprintf("First stage: β(neighbor) = %.3f (%.3f), F = %.1f\n",
              coef(fs)["neighbor_stf"], se(fs)["neighbor_stf"], f_stat))

  for (y in c("total_exp_pc", "education_pc", "social_pc", "tax_revenue_pc")) {
    if (!y %in% names(iv_data) || sum(!is.na(iv_data[[y]])) < 50) next
    fml <- as.formula(paste0(y, " ~ pop_growth | bfsnr + year | stf_corp ~ neighbor_stf"))
    fit <- tryCatch(
      feols(fml, data = iv_data, cluster = ~bfsnr),
      error = function(e) { cat(sprintf("  IV failed for %s\n", y)); NULL }
    )
    if (!is.null(fit)) {
      iv_results[[y]] <- fit
      cat(sprintf("  IV %s: β = %.2f (%.2f)\n",
                  y, coef(fit)["fit_stf_corp"], se(fit)["fit_stf_corp"]))
    }
  }
}

# ── 3. Heterogeneity by fiscal capacity ────────────────────────────────────
cat("\n--- 3. Heterogeneity: fiscal capacity ---\n")

first_rev <- analysis_full[!is.na(tax_revenue_pc),
                            .(first_rev = first(tax_revenue_pc)), by = bfsnr]
med_rev <- median(first_rev$first_rev, na.rm = TRUE)
first_rev[, high_capacity := as.integer(first_rev > med_rev)]
cat(sprintf("Median initial tax revenue p.c.: CHF %.0f\n", med_rev))

analysis_full <- merge(analysis_full, first_rev[, .(bfsnr, high_capacity)],
                        by = "bfsnr", all.x = TRUE)

het_results <- list()
for (y in c("total_exp_pc", "education_pc", "social_pc")) {
  if (!y %in% names(analysis_full)) next
  for (h in c(0, 1)) {
    label <- ifelse(h == 1, "High", "Low")
    sub <- analysis_full[high_capacity == h & !is.na(get(y))]
    if (nrow(sub) < 30) next
    fml <- as.formula(paste0(y, " ~ stf_corp + pop_growth | bfsnr + year"))
    fit <- feols(fml, data = sub, cluster = ~bfsnr)
    het_results[[paste0(y, "_cap_", h)]] <- fit
    cat(sprintf("  %s (%s cap): β = %.2f (%.2f), N = %d\n",
                y, label, coef(fit)["stf_corp"], se(fit)["stf_corp"], fit$nobs))
  }
}

# ── 4. Heterogeneity by population size ────────────────────────────────────
cat("\n--- 4. Heterogeneity: population size ---\n")

first_pop <- analysis_full[!is.na(population),
                            .(first_pop = first(population)), by = bfsnr]
med_pop <- median(first_pop$first_pop, na.rm = TRUE)
first_pop[, large_muni := as.integer(first_pop > med_pop)]
cat(sprintf("Median initial population: %.0f\n", med_pop))

analysis_full <- merge(analysis_full, first_pop[, .(bfsnr, large_muni)],
                        by = "bfsnr", all.x = TRUE)

for (y in c("total_exp_pc", "education_pc")) {
  if (!y %in% names(analysis_full)) next
  for (h in c(0, 1)) {
    label <- ifelse(h == 1, "Large", "Small")
    sub <- analysis_full[large_muni == h & !is.na(get(y))]
    if (nrow(sub) < 30) next
    fml <- as.formula(paste0(y, " ~ stf_corp + pop_growth | bfsnr + year"))
    fit <- feols(fml, data = sub, cluster = ~bfsnr)
    het_results[[paste0(y, "_size_", h)]] <- fit
    cat(sprintf("  %s (%s): β = %.2f (%.2f), N = %d\n",
                y, label, coef(fit)["stf_corp"], se(fit)["stf_corp"], fit$nobs))
  }
}

# ── 5. Additional robustness ───────────────────────────────────────────────
cat("\n--- 5. Additional robustness ---\n")

# a) Exclude Zurich city (outlier)
for (y in c("total_exp_pc", "education_pc")) {
  if (!y %in% names(analysis_full)) next
  fml <- as.formula(paste0(y, " ~ stf_corp + pop_growth | bfsnr + year"))
  fit <- feols(fml, data = analysis_full[bfsnr != 261 & !is.na(get(y))], cluster = ~bfsnr)
  het_results[[paste0(y, "_no_zurich")]] <- fit
  cat(sprintf("  %s (excl. Zurich city): β = %.2f (%.2f)\n",
              y, coef(fit)["stf_corp"], se(fit)["stf_corp"]))
}

# b) Winsorize at 5/95
for (y in c("total_exp_pc", "education_pc")) {
  if (!y %in% names(analysis_full)) next
  q05 <- quantile(analysis_full[[y]], 0.05, na.rm = TRUE)
  q95 <- quantile(analysis_full[[y]], 0.95, na.rm = TRUE)
  sub <- analysis_full[get(y) >= q05 & get(y) <= q95]
  fml <- as.formula(paste0(y, " ~ stf_corp + pop_growth | bfsnr + year"))
  fit <- feols(fml, data = sub, cluster = ~bfsnr)
  het_results[[paste0(y, "_win5_95")]] <- fit
  cat(sprintf("  %s (5/95 winsorized): β = %.2f (%.2f)\n",
              y, coef(fit)["stf_corp"], se(fit)["stf_corp"]))
}

# ── 6. Minimum Detectable Effects ─────────────────────────────────────────
cat("\n--- 6. Minimum Detectable Effects (80% power) ---\n")
for (y in c("total_exp_pc", "education_pc", "social_pc", "transport_pc", "tax_revenue_pc")) {
  if (!y %in% names(results)) next
  se_hat <- se(results[[y]])["stf_corp"]
  dep_mean <- mean(analysis_full[[y]], na.rm = TRUE)
  mde_1pp <- 2.8 * se_hat  # 80% power, two-sided 5%
  mde_10pp <- mde_1pp * 10

  cat(sprintf("  %s: MDE = %.1f CHF p.c. per 1pp (%.1f per 10pp = %.1f%% of mean)\n",
              y, mde_1pp, mde_10pp, 100 * mde_10pp / dep_mean))
}

# ── Save all results ────────────────────────────────────────────────────────
save(results, es_results, placebo_results, horse_results, iv_results,
     het_results, analysis_full, file = file.path(data_dir, "all_results.RData"))

cat("\nRobustness checks complete.\n")
