## 04_robustness.R — Robustness checks for bunching analysis
## (1) Multiple placebo thresholds, (2) By property type, (3) By region,
## (4) Power calculation, (5) Round-number effects

source("00_packages.R")

DATA_DIR <- "../data"
treatment <- fread(file.path(DATA_DIR, "treatment_timing.csv"))

# Reload transaction data
cat("--- Loading transaction data ---\n")
ppd_dir <- file.path(DATA_DIR, "ppd")
ppd_files <- list.files(ppd_dir, pattern = "pp-20.*\\.csv$", full.names = TRUE)

all_txns <- list()
for (f in ppd_files) {
  yr <- as.integer(gsub(".*pp-(\\d{4})\\.csv", "\\1", f))
  dt <- fread(f, header = FALSE, select = c(2, 3, 5, 6, 13))
  setnames(dt, c("price", "date", "prop_type", "old_new", "district"))
  dt[, price := as.numeric(price)]
  dt[, date := as.Date(date)]
  dt[, year := year(date)]
  dt[, post_lisa := fifelse(date >= as.Date("2017-04-01"), 1L, 0L)]
  all_txns[[as.character(yr)]] <- dt
}
txns <- rbindlist(all_txns)
cat(sprintf("Loaded %d transactions\n", nrow(txns)))

# ===========================================================================
# 1. Multiple placebo thresholds: £250K, £300K, £350K, £500K, £550K, £600K
# ===========================================================================
cat("\n--- Placebo Thresholds ---\n")

thresholds <- c(250000, 300000, 350000, 400000, 450000, 500000, 550000, 600000)
placebo_results <- data.frame(
  threshold = integer(), pre_ratio = numeric(), post_ratio = numeric(),
  diff = numeric(), se = numeric(), p = numeric()
)

for (thr in thresholds) {
  lower <- thr - 10000
  upper <- thr + 10000

  yr_data <- txns[price >= lower & price <= upper, .(
    n_below = sum(price >= lower & price < thr),
    n_above = sum(price >= thr & price <= upper)
  ), by = .(year, post_lisa)]

  yr_data[, ratio := n_below / n_above]
  yr_data <- yr_data[is.finite(ratio)]

  if (nrow(yr_data) < 5) next

  m <- lm(ratio ~ post_lisa, data = yr_data)
  pre_r <- mean(yr_data[post_lisa == 0, ratio])
  post_r <- mean(yr_data[post_lisa == 1, ratio])

  placebo_results <- rbind(placebo_results, data.frame(
    threshold = thr,
    pre_ratio = pre_r,
    post_ratio = post_r,
    diff = coef(m)["post_lisa"],
    se = summary(m)$coefficients["post_lisa", "Std. Error"],
    p = summary(m)$coefficients["post_lisa", "Pr(>|t|)"]
  ))
}

cat("Bunching ratio changes across thresholds:\n")
placebo_results$sig <- ifelse(placebo_results$p < 0.05, "*", "")
print(placebo_results)

# Is £450K special? Compare its coefficient to the distribution of placebos
non_450k <- placebo_results[placebo_results$threshold != 450000, ]
lisa_diff <- placebo_results$diff[placebo_results$threshold == 450000]
mean_placebo <- mean(non_450k$diff)
sd_placebo <- sd(non_450k$diff)
z_score <- (lisa_diff - mean_placebo) / sd_placebo
cat(sprintf("\n£450K diff vs placebo distribution: z = %.2f (not unusual if |z| < 2)\n", z_score))

# ===========================================================================
# 2. By property type: Flats vs Detached
# ===========================================================================
cat("\n--- By Property Type ---\n")

for (ptype in c("F", "D", "S", "T")) {
  sub <- txns[prop_type == ptype]
  yr_data <- sub[, .(
    n_below = sum(price >= 440000 & price < 450000),
    n_above = sum(price >= 450000 & price < 460000)
  ), by = .(year, post_lisa)]
  yr_data[, ratio := n_below / n_above]
  yr_data <- yr_data[is.finite(ratio) & n_below > 10]

  if (nrow(yr_data) < 5) {
    cat(sprintf("  %s: insufficient data\n", ptype))
    next
  }

  m <- lm(ratio ~ post_lisa, data = yr_data)
  cat(sprintf("  %s: diff = %+.4f (SE = %.4f, p = %.4f), pre = %.3f, post = %.3f\n",
              ptype, coef(m)["post_lisa"],
              summary(m)$coefficients["post_lisa", "Std. Error"],
              summary(m)$coefficients["post_lisa", "Pr(>|t|)"],
              mean(yr_data[post_lisa == 0, ratio]),
              mean(yr_data[post_lisa == 1, ratio])))
}

# ===========================================================================
# 3. By region: London vs South East vs Rest
# ===========================================================================
cat("\n--- By Region ---\n")

# Link districts to approximate regions using treatment data
london_las <- treatment[grepl("^E09", la_code), la_name]
se_las <- treatment[grepl("Surrey|Kent|Sussex|Hampshire|Berkshire|Buckingham|Oxford|Hertford",
                          la_name, ignore.case = TRUE), la_name]

txns[, region := "Rest of England"]
txns[district %in% london_las, region := "London"]
txns[district %in% se_las, region := "South East"]

for (reg in c("London", "South East", "Rest of England")) {
  sub <- txns[region == reg]
  yr_data <- sub[, .(
    n_below = sum(price >= 440000 & price < 450000),
    n_above = sum(price >= 450000 & price < 460000)
  ), by = .(year, post_lisa)]
  yr_data[, ratio := n_below / n_above]
  yr_data <- yr_data[is.finite(ratio) & n_below > 10]

  if (nrow(yr_data) < 5) {
    cat(sprintf("  %s: insufficient data\n", reg))
    next
  }

  m <- lm(ratio ~ post_lisa, data = yr_data)
  cat(sprintf("  %s: diff = %+.4f (SE = %.4f, p = %.4f)\n",
              reg, coef(m)["post_lisa"],
              summary(m)$coefficients["post_lisa", "Std. Error"],
              summary(m)$coefficients["post_lisa", "Pr(>|t|)"]))
}

# ===========================================================================
# 4. Power calculation: How large a bunching response could we detect?
# ===========================================================================
cat("\n--- Power Analysis ---\n")

# Under the null, the bunching ratio should be ~0.85
# With 15 annual observations, what effect size can we detect at alpha=0.05?
n_years <- 15
se_estimate <- summary(lm(
  ratio ~ post_lisa,
  data = txns[, .(
    n_below = sum(price >= 440000 & price < 450000),
    n_above = sum(price >= 450000 & price < 460000),
    post_lisa = fifelse(year >= 2017, 1, 0)
  ), by = year][, ratio := n_below / n_above]
))$coefficients["post_lisa", "Std. Error"]

mde <- se_estimate * 2.8  # 80% power at alpha = 0.05
cat(sprintf("Standard error: %.4f\n", se_estimate))
cat(sprintf("Minimum detectable effect (80%% power): %.4f\n", mde))
cat(sprintf("As %% of pre-LISA ratio (0.85): %.1f%%\n", 100 * mde / 0.85))

# Translation: how many transactions would need to shift?
avg_above <- mean(txns[year >= 2017 & price >= 450000 & price < 460000, .N, by = year]$N)
implied_shift <- mde * avg_above
cat(sprintf("Implied shift per year: ~%.0f transactions\n", implied_shift))

# ===========================================================================
# 5. Round-number effects: Is there general bunching at round numbers?
# ===========================================================================
cat("\n--- Round-Number Effects ---\n")

# Check density at round-number multiples of £50K vs nearby bins
round_numbers <- seq(250000, 600000, 50000)
round_effect <- data.frame()

for (rn in round_numbers) {
  n_at <- sum(txns$price >= rn & txns$price < rn + 5000)
  n_below <- sum(txns$price >= rn - 5000 & txns$price < rn)
  n_above <- sum(txns$price >= rn + 5000 & txns$price < rn + 10000)
  avg_nearby <- (n_below + n_above) / 2

  round_effect <- rbind(round_effect, data.frame(
    threshold = rn,
    n_at = n_at,
    avg_nearby = avg_nearby,
    excess = (n_at / avg_nearby) - 1
  ))
}

cat("Round-number density spikes (excess over neighbors):\n")
round_effect$label <- sprintf("£%dK", round_effect$threshold / 1000)
print(round_effect[, c("label", "n_at", "avg_nearby", "excess")])

# ===========================================================================
# 6. Save placebo results for tables
# ===========================================================================
fwrite(as.data.table(placebo_results), file.path(DATA_DIR, "placebo_results.csv"))
fwrite(as.data.table(round_effect), file.path(DATA_DIR, "round_number_effects.csv"))

# Update diagnostics
diag <- jsonlite::fromJSON(file.path(DATA_DIR, "diagnostics.json"))
diag$mde_bunching <- mde
diag$z_score_450k <- z_score
diag$n_placebo_thresholds <- nrow(non_450k)
jsonlite::write_json(diag, file.path(DATA_DIR, "diagnostics.json"), auto_unbox = TRUE)

cat("\n=== ROBUSTNESS COMPLETE ===\n")
