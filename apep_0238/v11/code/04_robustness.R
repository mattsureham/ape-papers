# ── apep_0238 v10: Robustness ─────────────────────────────────────────────
# Window robustness, richer controls, placebos, leave-one-out

# Source packages - detect script dir robustly
.args <- commandArgs(trailingOnly = FALSE)
.file_arg <- grep("^--file=", .args, value = TRUE)
if (length(.file_arg) > 0) {
  .script_dir <- dirname(normalizePath(sub("^--file=", "", .file_arg)))
} else {
  .script_dir <- getwd()
}
source(file.path(.script_dir, "00_packages.R"))
library(lubridate)
dat <- readRDS(file.path(DATA_DIR, "analysis_data.rds"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
gr <- results$analysis_gr
panel <- dat$panel

set.seed(42)

# ══════════════════════════════════════════════════════════════════════════
# 1. WINDOW ROBUSTNESS
# ══════════════════════════════════════════════════════════════════════════

cat("=== Window Robustness ===\n")

compute_avg_outcome_window <- function(panel, peak_date, h_start, h_end, step = 3) {
  horizons <- seq(h_start, h_end, by = step)
  peak_emp <- panel[date == peak_date, .(state, emp_peak = nonfarm_emp)]
  all_outcomes <- list()
  for (h in horizons) {
    target_date <- peak_date %m+% months(h)
    target <- panel[date == target_date]
    if (nrow(target) == 0) next
    target <- target[, .(state, nonfarm_emp)]
    merged <- merge(peak_emp, target, by = "state")
    merged[, d_log_emp := log(nonfarm_emp) - log(emp_peak)]
    all_outcomes[[as.character(h)]] <- merged[, .(state, d_log_emp)]
  }
  if (length(all_outcomes) == 0) return(NULL)
  stacked <- rbindlist(all_outcomes, idcol = "horizon")
  stacked[, .(avg_y = mean(d_log_emp, na.rm = TRUE)), by = state]
}

windows <- list(
  "36-96" = c(36, 96),
  "48-96" = c(48, 96),
  "48-120" = c(48, 120),
  "60-120" = c(60, 120)
)

window_results <- list()
for (wname in names(windows)) {
  w <- windows[[wname]]
  avg <- compute_avg_outcome_window(panel, GR_PEAK, w[1], w[2])
  if (is.null(avg)) next
  merged <- merge(dat$exposure, avg, by = "state")
  fit <- lm(avg_y ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region), data = merged)
  ct <- coeftest(fit, vcov = vcovHC(fit, type = "HC1"))
  # Permutation p
  obs <- ct["hpi_boom", 1]
  perm_dist <- replicate(1000, {
    d <- copy(merged)
    d$hpi_boom <- sample(d$hpi_boom)
    coef(lm(avg_y ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region), data = d))["hpi_boom"]
  })
  window_results[[wname]] <- data.table(
    window = wname,
    coef = ct["hpi_boom", 1],
    se = ct["hpi_boom", 2],
    pval = ct["hpi_boom", 4],
    perm_p = mean(abs(perm_dist) >= abs(obs))
  )
  cat(sprintf("  Window %s: coef=%.4f, p=%.3f, perm_p=%.3f\n",
              wname, ct["hpi_boom", 1], ct["hpi_boom", 4], window_results[[wname]]$perm_p))
}
window_dt <- rbindlist(window_results)

# ══════════════════════════════════════════════════════════════════════════
# 2. RICHER CONTROLS
# ══════════════════════════════════════════════════════════════════════════

cat("\n=== Richer Controls ===\n")

if ("avg_d_log_emp" %in% names(gr)) {
  # Baseline
  fit_base <- lm(avg_d_log_emp ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region),
                 data = gr)
  ct_base <- coeftest(fit_base, vcov = vcovHC(fit_base, type = "HC1"))

  # + construction & manufacturing shares
  fit_ind <- lm(avg_d_log_emp ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region) +
                  cons_share_2006 + mfg_share_2006, data = gr)
  ct_ind <- coeftest(fit_ind, vcov = vcovHC(fit_ind, type = "HC1"))

  cat(sprintf("  Baseline: %.4f (p=%.3f)\n", ct_base["hpi_boom", 1], ct_base["hpi_boom", 4]))
  cat(sprintf("  + Industry shares: %.4f (p=%.3f)\n", ct_ind["hpi_boom", 1], ct_ind["hpi_boom", 4]))

  control_results <- data.table(
    spec = c("Baseline", "+ Industry shares"),
    coef = c(ct_base["hpi_boom", 1], ct_ind["hpi_boom", 1]),
    se = c(ct_base["hpi_boom", 2], ct_ind["hpi_boom", 2]),
    pval = c(ct_base["hpi_boom", 4], ct_ind["hpi_boom", 4])
  )
}

# ══════════════════════════════════════════════════════════════════════════
# 3. DROP SAND STATES
# ══════════════════════════════════════════════════════════════════════════

cat("\n=== Drop Sand States ===\n")

SAND_STATES <- c("NV", "AZ", "FL", "CA")
if ("avg_d_log_emp" %in% names(gr)) {
  gr_nosand <- gr[!state %in% SAND_STATES]
  fit_nosand <- lm(avg_d_log_emp ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region),
                   data = gr_nosand)
  ct_nosand <- coeftest(fit_nosand, vcov = vcovHC(fit_nosand, type = "HC1"))
  cat(sprintf("  Drop Sand States (N=%d): %.4f (p=%.3f)\n",
              nrow(gr_nosand), ct_nosand["hpi_boom", 1], ct_nosand["hpi_boom", 4]))
}

# ══════════════════════════════════════════════════════════════════════════
# 4. LEAVE-ONE-OUT
# ══════════════════════════════════════════════════════════════════════════

cat("\n=== Leave-One-Out ===\n")

if ("avg_d_log_emp" %in% names(gr)) {
  loo_coefs <- sapply(STATES, function(st) {
    d <- gr[state != st]
    coef(lm(avg_d_log_emp ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region),
            data = d))["hpi_boom"]
  })
  cat(sprintf("  LOO range: [%.4f, %.4f]\n", min(loo_coefs), max(loo_coefs)))
  cat(sprintf("  Most influential state: %s (dropping shifts coef by %.4f)\n",
              names(which.max(abs(loo_coefs - coef(fit_base)["hpi_boom"]))),
              max(abs(loo_coefs - coef(fit_base)["hpi_boom"]))))
}

# ══════════════════════════════════════════════════════════════════════════
# 5. PLACEBO: PRE-PERIOD OUTCOMES
# ══════════════════════════════════════════════════════════════════════════

cat("\n=== Placebo: Pre-Period Outcome ===\n")

# Average employment change months -48 to -12 before GR peak
placebo_avg <- compute_avg_outcome_window(panel, GR_PEAK, -48, -12)
if (!is.null(placebo_avg)) {
  placebo_merged <- merge(dat$exposure, placebo_avg, by = "state")
  fit_placebo <- lm(avg_y ~ hpi_boom + factor(region), data = placebo_merged)
  ct_placebo <- coeftest(fit_placebo, vcov = vcovHC(fit_placebo, type = "HC1"))
  cat(sprintf("  Pre-period placebo: coef=%.4f, p=%.3f\n",
              ct_placebo["hpi_boom", 1], ct_placebo["hpi_boom", 4]))
}

# ══════════════════════════════════════════════════════════════════════════
# 6. Save
# ══════════════════════════════════════════════════════════════════════════

rob_results <- list(
  window_dt = window_dt,
  control_results = if (exists("control_results")) control_results else NULL,
  nosand_coef = if (exists("ct_nosand")) ct_nosand["hpi_boom", ] else NULL,
  loo_coefs = if (exists("loo_coefs")) loo_coefs else NULL,
  placebo = if (exists("ct_placebo")) ct_placebo["hpi_boom", ] else NULL
)
saveRDS(rob_results, file.path(DATA_DIR, "robustness_results.rds"))
cat("\nRobustness analysis complete.\n")
