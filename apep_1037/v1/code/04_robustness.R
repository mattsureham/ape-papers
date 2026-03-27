# 04_robustness.R — Robustness checks for Taiwan CGT analysis
# apep_1037: The Round-Trip Tax

source("00_packages.R")

data_dir <- "../data"

taiex_m <- readRDS(file.path(data_dir, "taiex_monthly_panel.rds"))

taiex_reg <- taiex_m %>%
  mutate(
    cgt_active = as.integer(yq >= 20131 & yq <= 20153),
    post_repeal = as.integer(yq >= 20154),
    announce = as.integer(yq >= 20122 & yq < 20131),
    time_trend = 1:n()
  )

# ============================================================================
# 1. Exclude announcement period
# ============================================================================

cat("=== Robustness 1: Exclude Announcement Period ===\n")
rob1 <- lm(log_daily_vol ~ cgt_active + post_repeal,
           data = taiex_reg %>% filter(!(yq >= 20122 & yq < 20131)))
nw_rob1 <- sqrt(diag(sandwich::NeweyWest(rob1, lag = 6)))
cat(sprintf("  CGT: %.4f (NW SE: %.4f)\n", coef(rob1)["cgt_active"], nw_rob1["cgt_active"]))
cat(sprintf("  Repeal: %.4f (NW SE: %.4f)\n", coef(rob1)["post_repeal"], nw_rob1["post_repeal"]))

# ============================================================================
# 2. Log total quarterly volume instead of daily average
# ============================================================================

cat("\n=== Robustness 2: Quarterly Total Volume ===\n")
taiex_q <- readRDS(file.path(data_dir, "taiex_quarterly_panel.rds"))
rob2 <- lm(log_vol ~ announce + cgt_active + post_repeal,
           data = taiex_q %>% mutate(announce = as.integer(yq >= 20122 & yq < 20131)))
nw_rob2 <- sqrt(diag(sandwich::NeweyWest(rob2, lag = 3)))
cat(sprintf("  Announce: %.4f (NW SE: %.4f)\n", coef(rob2)["announce"], nw_rob2["announce"]))
cat(sprintf("  CGT: %.4f (NW SE: %.4f)\n", coef(rob2)["cgt_active"], nw_rob2["cgt_active"]))
cat(sprintf("  Repeal: %.4f (NW SE: %.4f)\n", coef(rob2)["post_repeal"], nw_rob2["post_repeal"]))

# ============================================================================
# 3. Quadratic trend
# ============================================================================

cat("\n=== Robustness 3: Quadratic Trend ===\n")
taiex_reg$time_sq <- taiex_reg$time_trend^2
rob3 <- lm(log_daily_vol ~ announce + cgt_active + post_repeal + time_trend + time_sq,
           data = taiex_reg)
nw_rob3 <- sqrt(diag(sandwich::NeweyWest(rob3, lag = 6)))
cat(sprintf("  Announce: %.4f (NW SE: %.4f)\n", coef(rob3)["announce"], nw_rob3["announce"]))
cat(sprintf("  CGT: %.4f (NW SE: %.4f)\n", coef(rob3)["cgt_active"], nw_rob3["cgt_active"]))
cat(sprintf("  Repeal: %.4f (NW SE: %.4f)\n", coef(rob3)["post_repeal"], nw_rob3["post_repeal"]))

# ============================================================================
# 4. Placebo: pseudo-announcement at 2011Q1
# ============================================================================

cat("\n=== Robustness 4: Placebo Pre-Trend Test ===\n")
pre_only <- taiex_reg %>%
  filter(yq < 20122) %>%
  mutate(placebo = as.integer(yq >= 20111))

rob4 <- lm(log_daily_vol ~ placebo, data = pre_only)
nw_rob4 <- sqrt(diag(sandwich::NeweyWest(rob4, lag = 4)))
cat(sprintf("  Placebo: %.4f (NW SE: %.4f, p=%.4f)\n",
            coef(rob4)["placebo"], nw_rob4["placebo"],
            2 * pt(abs(coef(rob4)["placebo"] / nw_rob4["placebo"]),
                   df = nrow(pre_only) - 2, lower.tail = FALSE)))

# ============================================================================
# 5. Log transactions instead of volume
# ============================================================================

cat("\n=== Robustness 5: Log Transactions ===\n")

clean_num <- function(x) {
  x <- gsub(",", "", x)
  suppressWarnings(as.numeric(x))
}

taiex_raw <- readRDS(file.path(data_dir, "taiex_monthly_raw.rds"))

trans_monthly <- taiex_raw %>%
  mutate(
    trans = clean_num(n_transactions),
    quarter = ceiling(month / 3),
    yq = year * 10 + quarter
  ) %>%
  filter(!is.na(trans), trans > 0) %>%
  group_by(year, month) %>%
  summarise(
    avg_daily_trans = mean(trans, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    yq = year * 10 + ceiling(month / 3),
    log_daily_trans = log(avg_daily_trans),
    cgt_active = as.integer(yq >= 20131 & yq <= 20153),
    post_repeal = as.integer(yq >= 20154),
    announce = as.integer(yq >= 20122 & yq < 20131)
  )

if (nrow(trans_monthly) > 20) {
  rob5 <- lm(log_daily_trans ~ announce + cgt_active + post_repeal, data = trans_monthly)
  nw_rob5 <- sqrt(diag(sandwich::NeweyWest(rob5, lag = 6)))
  cat(sprintf("  Announce: %.4f (NW SE: %.4f)\n", coef(rob5)["announce"], nw_rob5["announce"]))
  cat(sprintf("  CGT: %.4f (NW SE: %.4f)\n", coef(rob5)["cgt_active"], nw_rob5["cgt_active"]))
  cat(sprintf("  Repeal: %.4f (NW SE: %.4f)\n", coef(rob5)["post_repeal"], nw_rob5["post_repeal"]))
} else {
  cat("  Insufficient transaction data\n")
  rob5 <- NULL
}

# ============================================================================
# Save robustness models
# ============================================================================

rob_models <- list(
  rob1_exclude_announce = rob1,
  rob2_quarterly = rob2,
  rob3_quadratic = rob3,
  rob4_placebo = rob4,
  rob5_transactions = rob5,
  nw_rob1 = nw_rob1,
  nw_rob2 = nw_rob2,
  nw_rob3 = nw_rob3,
  nw_rob4 = nw_rob4
)
rob_models <- rob_models[!sapply(rob_models, is.null)]
saveRDS(rob_models, file.path(data_dir, "robustness_models.rds"))

cat("\nRobustness checks complete.\n")
