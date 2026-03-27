# ── apep_0238 v10: Mechanism Analysis — The Duration Trap ──────────────────
# CPS-derived mechanism variables: LTU share, temp layoff share, U→E flows
# Duration-trap attenuation exercise

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
raw <- readRDS(file.path(DATA_DIR, "raw_data.rds"))
results <- readRDS(file.path(DATA_DIR, "main_results.rds"))
gr <- results$analysis_gr
covid <- results$analysis_covid

set.seed(42)

# ══════════════════════════════════════════════════════════════════════════
# 1. NATIONAL MECHANISM EVIDENCE
# ══════════════════════════════════════════════════════════════════════════

cat("=== National Mechanism Evidence ===\n")

# LTU share (27+ weeks / total unemployed) — national
if (!is.null(raw$ltu_national)) {
  ltu_nat <- raw$ltu_national
  # GR window
  ltu_gr <- ltu_nat[date >= "2007-01-01" & date <= "2012-12-01"]
  cat(sprintf("  GR peak LTU share: %.1f%%\n", max(ltu_gr$ltu_share, na.rm = TRUE) * 100))

  # COVID window
  ltu_covid <- ltu_nat[date >= "2019-01-01" & date <= "2023-06-01"]
  cat(sprintf("  COVID peak LTU share: %.1f%%\n", max(ltu_covid$ltu_share, na.rm = TRUE) * 100))
}

# Temp layoff share — national
if (!is.null(raw$temp_layoff_national)) {
  temp_nat <- raw$temp_layoff_national
  temp_gr <- temp_nat[date >= "2007-01-01" & date <= "2012-12-01"]
  temp_covid <- temp_nat[date >= "2019-01-01" & date <= "2023-06-01"]
  cat(sprintf("  GR peak temp layoff share: %.1f%%\n", max(temp_gr$temp_layoff_share, na.rm = TRUE) * 100))
  cat(sprintf("  COVID peak temp layoff share: %.1f%%\n", max(temp_covid$temp_layoff_share, na.rm = TRUE) * 100))
}

# ══════════════════════════════════════════════════════════════════════════
# 2. STATE-LEVEL MECHANISM VARIABLES
# ══════════════════════════════════════════════════════════════════════════

cat("\n=== State-Level Mechanism Variables ===\n")

panel <- dat$panel

# ── 2a. UR persistence by state (proxy for duration trap) ──
# The UR persistence ratio (UR at h=48 / UR at h=12) captures whether
# unemployment deepens over time (duration trap) or resolves (recall)

compute_ur_outcomes <- function(panel, peak_date, horizons) {
  peak_ur <- panel[date == peak_date, .(state, ur_peak = ur)]
  outcomes <- list()
  for (h in horizons) {
    target_date <- peak_date %m+% months(h)
    target <- panel[date == target_date, .(state, ur)]
    if (nrow(target) == 0) next
    merged <- merge(peak_ur, target, by = "state")
    merged[, (paste0("d_ur_", h)) := ur - ur_peak]
    outcomes[[as.character(h)]] <- merged[, c("state", paste0("d_ur_", h)), with = FALSE]
  }
  if (length(outcomes) == 0) return(NULL)
  Reduce(function(a, b) merge(a, b, by = "state"), outcomes)
}

ur_gr <- compute_ur_outcomes(panel, GR_PEAK, c(6, 12, 24, 36, 48, 60, 84, 120))
ur_covid <- compute_ur_outcomes(panel, COVID_PEAK, c(6, 12, 24, 36, 48))

# ── 2b. UR LP regressions ──
if (!is.null(ur_gr)) {
  ur_gr_merged <- merge(dat$exposure, ur_gr, by = "state")
  ur_lp_gr <- list()
  for (h in c(6, 12, 24, 36, 48, 60, 84, 120)) {
    dep <- paste0("d_ur_", h)
    if (!dep %in% names(ur_gr_merged)) next
    fml <- as.formula(paste(dep, "~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region)"))
    fit <- lm(fml, data = ur_gr_merged)
    ct <- coeftest(fit, vcov = vcovHC(fit, type = "HC1"))
    ur_lp_gr[[as.character(h)]] <- data.table(
      horizon = h, coef = ct["hpi_boom", 1], se = ct["hpi_boom", 2], pval = ct["hpi_boom", 4]
    )
  }
  ur_lp_gr <- rbindlist(ur_lp_gr)
  cat("UR LP — GR:\n")
  print(ur_lp_gr[, .(horizon, coef = round(coef, 3), p = round(pval, 3))])

  # UR persistence ratio
  if (all(c("d_ur_12", "d_ur_48") %in% names(ur_gr_merged))) {
    ur_gr_merged[, ur_persist := d_ur_48 / d_ur_12]
    cat(sprintf("  GR UR persistence ratio (48/12): median=%.2f\n",
                median(ur_gr_merged$ur_persist, na.rm = TRUE)))
  }
}

if (!is.null(ur_covid)) {
  ur_covid_merged <- merge(dat$exposure, ur_covid, by = "state")
  ur_lp_covid <- list()
  for (h in c(6, 12, 24, 36, 48)) {
    dep <- paste0("d_ur_", h)
    if (!dep %in% names(ur_covid_merged)) next
    fml <- as.formula(paste(dep, "~ bartik_covid_sd + log_emp_peak_covid + pre_growth_covid + factor(region)"))
    fit <- lm(fml, data = ur_covid_merged)
    ct <- coeftest(fit, vcov = vcovHC(fit, type = "HC1"))
    ur_lp_covid[[as.character(h)]] <- data.table(
      horizon = h, coef = ct["bartik_covid_sd", 1], se = ct["bartik_covid_sd", 2],
      pval = ct["bartik_covid_sd", 4]
    )
  }
  ur_lp_covid <- rbindlist(ur_lp_covid)
  cat("\nUR LP — COVID:\n")
  print(ur_lp_covid[, .(horizon, coef = round(coef, 3), p = round(pval, 3))])
}

# ── 2c. LFPR outcomes ──
compute_lfpr_outcomes <- function(panel, peak_date, horizons) {
  peak_lfpr <- panel[date == peak_date, .(state, lfpr_peak = lfpr)]
  outcomes <- list()
  for (h in horizons) {
    target_date <- peak_date %m+% months(h)
    target <- panel[date == target_date, .(state, lfpr)]
    if (nrow(target) == 0) next
    merged <- merge(peak_lfpr, target, by = "state")
    merged[, (paste0("d_lfpr_", h)) := lfpr - lfpr_peak]
    outcomes[[as.character(h)]] <- merged[, c("state", paste0("d_lfpr_", h)), with = FALSE]
  }
  if (length(outcomes) == 0) return(NULL)
  Reduce(function(a, b) merge(a, b, by = "state"), outcomes)
}

lfpr_gr <- compute_lfpr_outcomes(panel, GR_PEAK, c(12, 24, 48, 84, 120))
lfpr_covid <- compute_lfpr_outcomes(panel, COVID_PEAK, c(12, 24, 48))

# ══════════════════════════════════════════════════════════════════════════
# 3. DURATION-TRAP ATTENUATION
# ══════════════════════════════════════════════════════════════════════════

cat("\n=== Duration-Trap Attenuation ===\n")

# Key test: does controlling for UR persistence reduce the GR scarring coefficient?
# If duration explains scarring, adding duration-trap proxies should attenuate π

if (!is.null(ur_gr) && "avg_d_log_emp" %in% names(gr)) {
  gr_mech <- merge(gr, ur_gr, by = "state")

  # Use UR at h=24 as "duration trap" proxy
  # (UR 2 years after peak captures accumulated nonemployment)
  if ("d_ur_24" %in% names(gr_mech)) {
    # Baseline: employment on HPI
    fit_base <- lm(avg_d_log_emp ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region),
                   data = gr_mech)
    coef_base <- coef(fit_base)["hpi_boom"]

    # With UR mediator
    fit_med <- lm(avg_d_log_emp ~ hpi_boom + d_ur_24 + log_emp_peak_gr + pre_growth_gr + factor(region),
                  data = gr_mech)
    coef_med <- coef(fit_med)["hpi_boom"]

    attenuation <- 1 - coef_med / coef_base
    cat(sprintf("  Baseline HPI coef: %.4f\n", coef_base))
    cat(sprintf("  With UR(24) mediator: %.4f\n", coef_med))
    cat(sprintf("  Attenuation: %.1f%%\n", attenuation * 100))

    # First stage: HPI → UR(24)
    fit_fs <- lm(d_ur_24 ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region),
                 data = gr_mech)
    cat(sprintf("  HPI → UR(24): coef=%.3f, p=%.4f\n",
                coef(fit_fs)["hpi_boom"],
                coeftest(fit_fs, vcov = vcovHC(fit_fs, type = "HC1"))["hpi_boom", 4]))
  }

  # Also test with UR at h=48
  if ("d_ur_48" %in% names(gr_mech)) {
    fit_med48 <- lm(avg_d_log_emp ~ hpi_boom + d_ur_48 + log_emp_peak_gr + pre_growth_gr + factor(region),
                    data = gr_mech)
    coef_med48 <- coef(fit_med48)["hpi_boom"]
    attenuation48 <- 1 - coef_med48 / coef_base
    cat(sprintf("  With UR(48) mediator: %.4f (attenuation %.1f%%)\n",
                coef_med48, attenuation48 * 100))
  }
}

# ══════════════════════════════════════════════════════════════════════════
# 4. BLS DURATION DATA (if available)
# ══════════════════════════════════════════════════════════════════════════

if (!is.null(raw$ltu_duration) && nrow(raw$ltu_duration) > 0) {
  cat("\n=== State-Level LTU Analysis ===\n")
  ltu_state <- raw$ltu_duration

  # Average LTU share in first 2 years post-peak
  ltu_gr_state <- ltu_state[date >= GR_PEAK & date <= GR_PEAK %m+% months(24)]
  avg_ltu_gr <- ltu_gr_state[, .(avg_ltu_share = mean(ltu_share, na.rm = TRUE)), by = state]

  ltu_covid_state <- ltu_state[date >= COVID_PEAK & date <= COVID_PEAK %m+% months(24)]
  avg_ltu_covid <- ltu_covid_state[, .(avg_ltu_share = mean(ltu_share, na.rm = TRUE)), by = state]

  # LTU share on exposure
  gr_ltu <- merge(dat$exposure, avg_ltu_gr, by = "state")
  fit_ltu_gr <- lm(avg_ltu_share ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region),
                   data = gr_ltu)
  ct_ltu <- coeftest(fit_ltu_gr, vcov = vcovHC(fit_ltu_gr, type = "HC1"))
  cat(sprintf("  HPI → LTU share: coef=%.4f, p=%.3f\n", ct_ltu["hpi_boom", 1], ct_ltu["hpi_boom", 4]))
}

# ══════════════════════════════════════════════════════════════════════════
# 5. Save mechanism results
# ══════════════════════════════════════════════════════════════════════════

mech_results <- list(
  ur_lp_gr = if (exists("ur_lp_gr")) ur_lp_gr else NULL,
  ur_lp_covid = if (exists("ur_lp_covid")) ur_lp_covid else NULL,
  attenuation = if (exists("attenuation")) attenuation else NULL,
  attenuation48 = if (exists("attenuation48")) attenuation48 else NULL,
  coef_base = if (exists("coef_base")) coef_base else NULL,
  coef_med = if (exists("coef_med")) coef_med else NULL,
  ltu_national = raw$ltu_national,
  temp_national = raw$temp_layoff_national,
  lfpr_gr = lfpr_gr,
  lfpr_covid = lfpr_covid
)
saveRDS(mech_results, file.path(DATA_DIR, "mechanism_results.rds"))
cat("\nMechanism analysis complete.\n")
