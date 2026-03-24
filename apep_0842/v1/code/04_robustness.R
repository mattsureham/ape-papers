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
# Save robustness results
# ============================================================

robustness <- list(
  boot = boot_result,
  loo_dest = loo_results,
  loo_origin = loo_origin_results,
  m_reject = m_reject,
  m_placebo = m_placebo,
  m_restricted = m_restricted
)
saveRDS(robustness, "../data/robustness_results.rds")

cat("\n=== Robustness results saved ===\n")
