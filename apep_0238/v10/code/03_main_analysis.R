# ── apep_0238 v10: Main Analysis ───────────────────────────────────────────
# Single estimand + LP IRFs + pooled interaction + IV + horse race

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
gr <- dat$analysis_gr
covid <- dat$analysis_covid

set.seed(42)

# ══════════════════════════════════════════════════════════════════════════
# 1. SINGLE ESTIMAND: Average EPOP months 48-120
# ══════════════════════════════════════════════════════════════════════════

cat("=== Single Estimand Regressions ===\n")

# GR: avg log employment change months 48-120 on HPI boom
if ("avg_d_log_emp" %in% names(gr)) {
  fit_gr_main <- lm(avg_d_log_emp ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region),
                    data = gr)
  cat("GR main (avg 48-120):\n")
  print(coeftest(fit_gr_main, vcov = vcovHC(fit_gr_main, type = "HC1")))

  # Permutation inference
  N_PERM <- 2000
  observed_gr <- coef(fit_gr_main)["hpi_boom"]
  perm_coefs_gr <- replicate(N_PERM, {
    gr_perm <- copy(gr)
    gr_perm$hpi_boom <- sample(gr_perm$hpi_boom)
    coef(lm(avg_d_log_emp ~ hpi_boom + log_emp_peak_gr + pre_growth_gr + factor(region),
            data = gr_perm))["hpi_boom"]
  })
  perm_p_gr <- mean(abs(perm_coefs_gr) >= abs(observed_gr))
  cat(sprintf("  Permutation p-value: %.4f\n", perm_p_gr))
}

# COVID: avg log employment change months 24-48 on Bartik (standardized)
if ("avg_d_log_emp" %in% names(covid)) {
  fit_covid_main <- lm(avg_d_log_emp ~ bartik_covid_sd + log_emp_peak_covid +
                         pre_growth_covid + factor(region), data = covid)
  cat("\nCOVID main (avg 24-48):\n")
  print(coeftest(fit_covid_main, vcov = vcovHC(fit_covid_main, type = "HC1")))

  observed_covid <- coef(fit_covid_main)["bartik_covid_sd"]
  perm_coefs_covid <- replicate(N_PERM, {
    covid_perm <- copy(covid)
    covid_perm$bartik_covid_sd <- sample(covid_perm$bartik_covid_sd)
    coef(lm(avg_d_log_emp ~ bartik_covid_sd + log_emp_peak_covid +
              pre_growth_covid + factor(region), data = covid_perm))["bartik_covid_sd"]
  })
  perm_p_covid <- mean(abs(perm_coefs_covid) >= abs(observed_covid))
  cat(sprintf("  Permutation p-value: %.4f\n", perm_p_covid))
}

# ══════════════════════════════════════════════════════════════════════════
# 2. LP IRFs (horizon-by-horizon, for dynamic figure)
# ══════════════════════════════════════════════════════════════════════════

cat("\n=== LP Impulse Response Functions ===\n")

run_lp <- function(data, dep_prefix, exposure_var, controls, horizons) {
  results <- list()
  for (h in horizons) {
    dep_var <- paste0(dep_prefix, h)
    if (!dep_var %in% names(data)) next
    fml <- as.formula(paste(dep_var, "~", exposure_var, "+", paste(controls, collapse = " + ")))
    fit <- lm(fml, data = data)
    hc1 <- vcovHC(fit, type = "HC1")
    ct <- coeftest(fit, vcov = hc1)
    idx <- which(rownames(ct) == exposure_var)
    results[[as.character(h)]] <- data.table(
      horizon = h,
      coef = ct[idx, 1],
      se = ct[idx, 2],
      pval = ct[idx, 4],
      r2 = summary(fit)$r.squared,
      n = nobs(fit)
    )
  }
  rbindlist(results)
}

HORIZONS_GR <- c(0, 3, 6, 12, 24, 36, 48, 60, 84, 120)
HORIZONS_COVID <- c(0, 3, 6, 12, 24, 36, 48)
CONTROLS_BASE <- c("log_emp_peak_gr", "pre_growth_gr", "factor(region)")
CONTROLS_COVID <- c("log_emp_peak_covid", "pre_growth_covid", "factor(region)")

lp_gr <- run_lp(gr, "d_log_emp_", "hpi_boom", CONTROLS_BASE, HORIZONS_GR)
lp_covid <- run_lp(covid, "d_log_emp_", "bartik_covid_sd", CONTROLS_COVID, HORIZONS_COVID)

cat("GR LP results:\n")
print(lp_gr[, .(horizon, coef = round(coef, 4), se = round(se, 4), pval = round(pval, 3))])
cat("\nCOVID LP results:\n")
print(lp_covid[, .(horizon, coef = round(coef, 4), se = round(se, 4), pval = round(pval, 3))])

# Permutation p-values for each horizon
cat("\nPermutation inference for LP horizons...\n")
compute_perm_p <- function(data, dep_prefix, exposure_var, controls, horizons, n_perm = 1000) {
  perm_results <- list()
  for (h in horizons) {
    dep_var <- paste0(dep_prefix, h)
    if (!dep_var %in% names(data)) next
    fml <- as.formula(paste(dep_var, "~", exposure_var, "+", paste(controls, collapse = " + ")))
    observed <- coef(lm(fml, data = data))[exposure_var]
    perm_dist <- replicate(n_perm, {
      d <- copy(data)
      d[[exposure_var]] <- sample(d[[exposure_var]])
      coef(lm(fml, data = d))[exposure_var]
    })
    perm_results[[as.character(h)]] <- data.table(
      horizon = h, perm_p = mean(abs(perm_dist) >= abs(observed))
    )
  }
  rbindlist(perm_results)
}

perm_gr <- compute_perm_p(gr, "d_log_emp_", "hpi_boom", CONTROLS_BASE, HORIZONS_GR)
perm_covid <- compute_perm_p(covid, "d_log_emp_", "bartik_covid_sd", CONTROLS_COVID, HORIZONS_COVID)

lp_gr <- merge(lp_gr, perm_gr, by = "horizon", all.x = TRUE)
lp_covid <- merge(lp_covid, perm_covid, by = "horizon", all.x = TRUE)

# ══════════════════════════════════════════════════════════════════════════
# 3. POOLED INTERACTION
# ══════════════════════════════════════════════════════════════════════════

cat("\n=== Pooled Interaction ===\n")

# Stack GR and COVID single-estimand outcomes
# Standardize exposure to SD=1 for both
if ("avg_d_log_emp" %in% names(gr) && "avg_d_log_emp" %in% names(covid)) {
  gr_stack <- gr[, .(state, avg_y = avg_d_log_emp,
                     exposure_sd = hpi_boom_sd,
                     episode = "GR")]
  covid_stack <- covid[, .(state, avg_y = avg_d_log_emp,
                           exposure_sd = bartik_covid_sd,
                           episode = "COVID")]
  pooled <- rbind(gr_stack, covid_stack)
  pooled[, is_gr := as.integer(episode == "GR")]
  pooled[, exposure_x_gr := exposure_sd * is_gr]

  fit_pooled <- lm(avg_y ~ exposure_sd + exposure_x_gr + is_gr, data = pooled)
  cat("Pooled interaction:\n")
  print(coeftest(fit_pooled, vcov = vcovHC(fit_pooled, type = "HC1")))
}

# ══════════════════════════════════════════════════════════════════════════
# 4. SAIZ IV (GR only)
# ══════════════════════════════════════════════════════════════════════════

cat("\n=== Saiz IV ===\n")

if (requireNamespace("ivreg", quietly = TRUE)) {
  library(ivreg)
} else {
  install.packages("ivreg", repos = "https://cloud.r-project.org")
  library(ivreg)
}

# First stage
fs <- lm(hpi_boom ~ saiz + log_emp_peak_gr + pre_growth_gr + factor(region), data = gr)
fs_f <- summary(fs)$fstatistic[1]
cat(sprintf("First-stage F: %.1f\n", fs_f))

# 2SLS for selected horizons
iv_results <- list()
for (h in c(12, 24, 48)) {
  dep_var <- paste0("d_log_emp_", h)
  if (!dep_var %in% names(gr)) next
  fml <- as.formula(paste(dep_var, "~ log_emp_peak_gr + pre_growth_gr + factor(region) |",
                          "hpi_boom | saiz"))
  fit_iv <- ivreg(fml, data = gr)
  s <- summary(fit_iv)
  iv_results[[as.character(h)]] <- data.table(
    horizon = h,
    ols = lp_gr[horizon == h]$coef,
    iv = coef(fit_iv)["hpi_boom"],
    iv_se = s$coefficients["hpi_boom", "Std. Error"]
  )
}
iv_dt <- rbindlist(iv_results)
cat("IV estimates:\n")
print(iv_dt)

# ══════════════════════════════════════════════════════════════════════════
# 5. HORSE RACE: HPI vs GR Bartik
# ══════════════════════════════════════════════════════════════════════════

cat("\n=== Horse Race: HPI vs GR Bartik ===\n")

# Construct GR-era Bartik
# National industry shock Feb 2007 to trough (Jun 2009)
ind <- readRDS(file.path(DATA_DIR, "raw_data.rds"))$industry
feb2007 <- ind[year(date) == 2007 & month(date) == 12, .(state, industry, emp_pre = ind_emp)]
jun2009 <- ind[year(date) == 2009 & month(date) == 6, .(state, industry, emp_post = ind_emp)]

gr_ind <- merge(feb2007, jun2009, by = c("state", "industry"))

# 2006 shares
shares_2006 <- ind[year(date) == 2006, .(avg_emp = mean(ind_emp, na.rm = TRUE)),
                   by = .(state, industry)]
total_2006 <- shares_2006[, .(total = sum(avg_emp)), by = state]
shares_2006 <- merge(shares_2006, total_2006, by = "state")
shares_2006[, omega := avg_emp / total]

gr_bartik_list <- list()
for (st in STATES) {
  other <- gr_ind[state != st]
  nat_chg <- other[, .(delta_nat = (sum(emp_post, na.rm = TRUE) - sum(emp_pre, na.rm = TRUE)) /
                         sum(emp_pre, na.rm = TRUE)), by = industry]
  st_shares <- shares_2006[state == st, .(industry, omega)]
  merged <- merge(st_shares, nat_chg, by = "industry", all.x = TRUE)
  merged[is.na(delta_nat), delta_nat := 0]
  gr_bartik_list[[st]] <- data.table(state = st, bartik_gr = sum(merged$omega * merged$delta_nat))
}
bartik_gr_dt <- rbindlist(gr_bartik_list)

gr <- merge(gr, bartik_gr_dt, by = "state", all.x = TRUE)

# Horse race regression at selected horizons
horse_results <- list()
for (h in c(6, 12, 24, 48)) {
  dep_var <- paste0("d_log_emp_", h)
  if (!dep_var %in% names(gr)) next
  fml <- as.formula(paste(dep_var, "~ hpi_boom + bartik_gr + log_emp_peak_gr + pre_growth_gr + factor(region)"))
  fit <- lm(fml, data = gr)
  ct <- coeftest(fit, vcov = vcovHC(fit, type = "HC1"))
  horse_results[[as.character(h)]] <- data.table(
    horizon = h,
    hpi_coef = ct["hpi_boom", 1], hpi_se = ct["hpi_boom", 2], hpi_p = ct["hpi_boom", 4],
    bartik_coef = ct["bartik_gr", 1], bartik_se = ct["bartik_gr", 2], bartik_p = ct["bartik_gr", 4]
  )
}
horse_dt <- rbindlist(horse_results)
cat("Horse race:\n")
print(horse_dt[, .(horizon, hpi = round(hpi_coef, 4), hpi_p = round(hpi_p, 3),
                   bartik = round(bartik_coef, 4), bartik_p = round(bartik_p, 3))])

# ══════════════════════════════════════════════════════════════════════════
# 6. PRE-TRENDS
# ══════════════════════════════════════════════════════════════════════════

cat("\n=== Pre-Trend Tests ===\n")

panel <- dat$panel
PRE_HORIZONS <- c(-36, -24, -12)

# GR pre-trends
gr_pre_outcomes <- list()
for (h in PRE_HORIZONS) {
  target_date <- GR_PEAK %m+% months(h)
  base_date <- GR_PEAK %m+% months(h - 12)  # 12-month change ending at h
  t1 <- panel[date == base_date, .(state, emp1 = nonfarm_emp)]
  t2 <- panel[date == target_date, .(state, emp2 = nonfarm_emp)]
  if (nrow(t1) == 0 || nrow(t2) == 0) next
  merged <- merge(t1, t2, by = "state")
  merged[, (paste0("pre_", abs(h))) := log(emp2) - log(emp1)]
  gr_pre_outcomes[[as.character(h)]] <- merged[, c("state", paste0("pre_", abs(h))), with = FALSE]
}

if (length(gr_pre_outcomes) > 0) {
  gr_pre_dt <- Reduce(function(a, b) merge(a, b, by = "state"), gr_pre_outcomes)
  gr_pre_dt <- merge(gr_pre_dt, dat$exposure, by = "state")

  for (h in PRE_HORIZONS) {
    dep <- paste0("pre_", abs(h))
    if (!dep %in% names(gr_pre_dt)) next
    fml <- as.formula(paste(dep, "~ hpi_boom + factor(region)"))
    fit <- lm(fml, data = gr_pre_dt)
    ct <- coeftest(fit, vcov = vcovHC(fit, type = "HC1"))
    cat(sprintf("  GR pre-trend h=%d: coef=%.4f, p=%.3f\n",
                h, ct["hpi_boom", 1], ct["hpi_boom", 4]))
  }
}

# ══════════════════════════════════════════════════════════════════════════
# 7. Save results
# ══════════════════════════════════════════════════════════════════════════

results <- list(
  lp_gr = lp_gr,
  lp_covid = lp_covid,
  iv_dt = iv_dt,
  horse_dt = horse_dt,
  perm_p_gr_main = if (exists("perm_p_gr")) perm_p_gr else NULL,
  perm_p_covid_main = if (exists("perm_p_covid")) perm_p_covid else NULL,
  fit_gr_main = if (exists("fit_gr_main")) summary(fit_gr_main) else NULL,
  fit_covid_main = if (exists("fit_covid_main")) summary(fit_covid_main) else NULL,
  fit_pooled = if (exists("fit_pooled")) summary(fit_pooled) else NULL,
  fs_f = fs_f,
  analysis_gr = gr,
  analysis_covid = covid
)
saveRDS(results, file.path(DATA_DIR, "main_results.rds"))
cat("\nMain analysis complete. Results saved.\n")
