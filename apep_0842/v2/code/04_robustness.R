# 04_robustness.R — Robustness checks
# apep_0842: The Safe Country Lottery

source("00_packages.R")

panel <- readRDS("../data/analysis_panel_final.rds")
results <- readRDS("../data/main_results.rds")

# ============================================================
# 1. Wild cluster bootstrap (few clusters)
# ============================================================

cat("=== Wild cluster bootstrap ===\n")
# With ~15-20 destination clusters, standard cluster SEs may be unreliable
# Use wild cluster bootstrap

m2_lm <- feols(recog_rate ~ sco | pair_id + origin_year + dest_year,
               data = panel, cluster = ~destination)

# Use pairs cluster bootstrap via manual resampling of destination clusters
set.seed(42)
n_boot <- 999
boot_betas <- numeric(n_boot)
dest_list <- unique(panel$destination)

for (b in seq_len(n_boot)) {
  boot_dests <- sample(dest_list, length(dest_list), replace = TRUE)
  boot_data <- lapply(seq_along(boot_dests), function(i) {
    d <- panel[panel$destination == boot_dests[i], ]
    d$destination_boot <- paste0(boot_dests[i], "_", i)
    d$pair_id_boot <- paste(d$origin, d$destination_boot, sep = "_")
    d
  })
  boot_data <- do.call(rbind, boot_data)
  boot_data$origin_year_boot <- paste(boot_data$origin, boot_data$year, sep = "_")
  boot_data$dest_year_boot <- paste(boot_data$destination_boot, boot_data$year, sep = "_")

  m_boot <- tryCatch({
    feols(recog_rate ~ sco | pair_id_boot + origin_year_boot + dest_year_boot,
          data = boot_data)
  }, error = function(e) NULL)

  if (!is.null(m_boot)) {
    boot_betas[b] <- coef(m_boot)["sco"]
  } else {
    boot_betas[b] <- NA
  }
}

boot_betas <- boot_betas[!is.na(boot_betas)]
boot_se <- sd(boot_betas)
boot_p <- mean(abs(boot_betas) >= abs(coef(m2_lm)["sco"]))
boot_ci <- quantile(boot_betas, c(0.025, 0.975))

cat(sprintf("  Pairs cluster bootstrap SE: %.4f\n", boot_se))
cat(sprintf("  Bootstrap p-value: %.4f\n", boot_p))
cat(sprintf("  Bootstrap 95%% CI: [%.4f, %.4f]\n", boot_ci[1], boot_ci[2]))

boot_result <- list(p = boot_p, ci = boot_ci, se = boot_se)

# ============================================================
# 2. Leave-one-destination-out
# ============================================================

cat("\n=== Leave-one-destination-out ===\n")

destinations <- unique(panel$destination)
loo_results <- data.frame(
  dropped = character(),
  beta = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (d in destinations) {
  m_loo <- tryCatch({
    feols(recog_rate ~ sco | pair_id + origin_year + dest_year,
          data = filter(panel, destination != d),
          cluster = ~destination)
  }, error = function(e) NULL)

  if (!is.null(m_loo)) {
    loo_results <- rbind(loo_results, data.frame(
      dropped = d,
      beta = coef(m_loo)["sco"],
      se = se(m_loo)["sco"]
    ))
  }
}

cat(sprintf("  LOO range: [%.4f, %.4f]\n", min(loo_results$beta), max(loo_results$beta)))
cat(sprintf("  Main estimate: %.4f\n", coef(results$m2)["sco"]))

# ============================================================
# 3. Leave-one-origin-out
# ============================================================

cat("\n=== Leave-one-origin-out ===\n")

origins <- unique(panel$origin[panel$sco == 1])
loo_origin_results <- data.frame(
  dropped = character(),
  beta = numeric(),
  se = numeric(),
  stringsAsFactors = FALSE
)

for (o in origins) {
  m_loo_o <- tryCatch({
    feols(recog_rate ~ sco | pair_id + origin_year + dest_year,
          data = filter(panel, origin != o),
          cluster = ~destination)
  }, error = function(e) NULL)

  if (!is.null(m_loo_o)) {
    loo_origin_results <- rbind(loo_origin_results, data.frame(
      dropped = o,
      beta = coef(m_loo_o)["sco"],
      se = se(m_loo_o)["sco"]
    ))
  }
}

cat(sprintf("  LOO-origin range: [%.4f, %.4f]\n",
            min(loo_origin_results$beta), max(loo_origin_results$beta)))

# ============================================================
# 4. Alternative outcome: Rejection rate
# ============================================================

cat("\n=== Alternative outcome: Rejection rate ===\n")
panel <- panel %>%
  mutate(reject_rate = ifelse(total_decisions > 0,
                              rejected_decisions / total_decisions, NA_real_))

m_reject <- feols(reject_rate ~ sco | pair_id + origin_year + dest_year,
                  data = panel, cluster = ~destination)
summary(m_reject)

# ============================================================
# 5. Placebo: Control origins only (should be null)
# ============================================================

cat("\n=== Placebo: Randomly permuted designation timing ===\n")
# Permute the designation year among treated pairs to test if the timing matters
set.seed(123)
sco_events_orig <- readRDS("../data/sco_events.rds")
treated_pairs <- sco_events_orig %>% select(destination, origin, year_designated) %>% distinct()

# Shuffle designation years across pairs
placebo_years <- sample(treated_pairs$year_designated)
placebo_events <- treated_pairs %>%
  mutate(year_designated_fake = placebo_years)

# Create placebo panel
placebo_panel <- panel %>%
  left_join(placebo_events %>% select(destination, origin, year_designated_fake),
            by = c("origin", "destination")) %>%
  mutate(fake_sco = ifelse(!is.na(year_designated_fake) & year >= year_designated_fake, 1L, 0L))

m_placebo <- feols(recog_rate ~ fake_sco | pair_id + origin_year + dest_year,
                   data = placebo_panel, cluster = ~destination)
summary(m_placebo)

# ============================================================
# 6. Restricted sample: Only 2010-2020 (avoiding COVID effects)
# ============================================================

cat("\n=== Restricted sample: 2010-2020 ===\n")
m_restricted <- feols(recog_rate ~ sco | pair_id + origin_year + dest_year,
                      data = filter(panel, year >= 2010 & year <= 2020),
                      cluster = ~destination)
summary(m_restricted)

# ============================================================
# 7. Randomization Inference (formal RI for the main estimate)
# ============================================================

cat("\n=== Randomization inference ===\n")
set.seed(314)
n_ri <- 999
ri_betas <- numeric(n_ri)

# Permute SCO treatment across pairs within each year
for (r in seq_len(n_ri)) {
  panel_ri <- panel %>%
    group_by(year) %>%
    mutate(sco_ri = sample(sco)) %>%
    ungroup()

  m_ri <- tryCatch({
    feols(recog_rate ~ sco_ri | pair_id + origin_year + dest_year,
          data = panel_ri)
  }, error = function(e) NULL)

  ri_betas[r] <- if (!is.null(m_ri)) coef(m_ri)["sco_ri"] else NA
}

ri_betas <- ri_betas[!is.na(ri_betas)]
ri_p <- mean(abs(ri_betas) >= abs(coef(results$m2)["sco"]))
cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_p))
cat(sprintf("  RI distribution: mean=%.4f, sd=%.4f\n", mean(ri_betas), sd(ri_betas)))

ri_result <- list(p = ri_p, betas = ri_betas)

# ============================================================
# 8. Callaway-Sant'Anna heterogeneity-robust estimator
# ============================================================

cat("\n=== Callaway-Sant'Anna staggered DiD ===\n")

# Prepare data for did::att_gt
# Need: panel-level data with unit ID, time, first treatment period, outcome
sco_events_orig <- readRDS("../data/sco_events.rds")
sco_first_treat <- sco_events_orig %>%
  select(destination, origin, year_designated) %>%
  distinct()

cs_panel <- panel %>%
  left_join(sco_first_treat, by = c("origin", "destination")) %>%
  mutate(
    first_treat = ifelse(is.na(year_designated), 0, year_designated),
    unit_id = as.integer(factor(pair_id))
  ) %>%
  filter(!is.na(recog_rate))

cs_result <- tryCatch({
  cs_out <- att_gt(
    yname = "recog_rate",
    tname = "year",
    idname = "unit_id",
    gname = "first_treat",
    data = as.data.frame(cs_panel),
    control_group = "nevertreated",
    base_period = "universal"
  )
  cs_agg <- aggte(cs_out, type = "simple")
  cat(sprintf("  CS ATT: %.4f (SE: %.4f)\n", cs_agg$overall.att, cs_agg$overall.se))
  list(att = cs_agg$overall.att, se = cs_agg$overall.se,
       ci = c(cs_agg$overall.att - 1.96 * cs_agg$overall.se,
              cs_agg$overall.att + 1.96 * cs_agg$overall.se),
       cs_out = cs_out, cs_agg = cs_agg)
}, error = function(e) {
  cat(sprintf("  CS estimation failed: %s\n", e$message))
  NULL
})

# ============================================================
# 9. Minimum Detectable Effect (MDE) at 80% power
# ============================================================

cat("\n=== Minimum Detectable Effect ===\n")

# MDE = (z_alpha/2 + z_beta) * SE
# For two-sided 5% test with 80% power: z_0.025 + z_0.20 = 1.96 + 0.84 = 2.8
mde_factor <- 2.8
se_main <- se(results$m2)["sco"]
mde <- mde_factor * se_main
sd_y <- sd(panel$recog_rate, na.rm = TRUE)
mde_sde <- mde / sd_y

cat(sprintf("  SE(main): %.4f\n", se_main))
cat(sprintf("  MDE (80%% power, 5%% two-sided): %.4f (%.1f pp)\n", mde, mde * 100))
cat(sprintf("  MDE as share of raw gap (27pp): %.1f%%\n", mde / 0.27 * 100))
cat(sprintf("  MDE in SDE units: %.3f\n", mde_sde))
cat(sprintf("  Bootstrap 95%% CI rules out effects > %.1f pp\n",
            max(abs(boot_ci)) * 100))

mde_result <- list(mde = mde, mde_pp = mde * 100, mde_sde = mde_sde,
                   se = se_main, share_of_gap = mde / 0.27)

# ============================================================
# Save robustness results
# ============================================================

robustness <- list(
  boot = boot_result,
  loo_dest = loo_results,
  loo_origin = loo_origin_results,
  m_reject = m_reject,
  m_placebo = m_placebo,
  m_restricted = m_restricted,
  ri = ri_result,
  cs = cs_result,
  mde = mde_result
)
saveRDS(robustness, "../data/robustness_results.rds")

cat("\n=== Robustness results saved ===\n")
