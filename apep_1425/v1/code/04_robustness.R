## 04_robustness.R — apep_1425
## Robustness checks: heterogeneity by claim type, bandwidth, placebo

this_script <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("--file=", args, value = TRUE)
  if (length(file_arg) > 0) normalizePath(sub("--file=", "", file_arg)) else getwd()
})
SCRIPT_DIR <- dirname(this_script)
source(file.path(SCRIPT_DIR, "00_packages.R"))
WORK_DIR <- file.path(SCRIPT_DIR, "..")

# ── Load analysis sample with leniency ──
dt <- as.data.table(fread(file.path(WORK_DIR, "data", "analysis_sample.csv")))

# Recompute L_j (same as 03_main_analysis.R)
REFORM_DATE <- as.POSIXct("2017-11-11", tz = "America/Sao_Paulo")
dt[, filing_date_str := as.character(filing_date)]
dt[, filing_dt := as.POSIXct(filing_date_str, format = "%Y%m%d%H%M%S", tz = "America/Sao_Paulo")]
dt[is.na(filing_dt), filing_dt := as.POSIXct(filing_date_str, format = "%Y-%m-%dT%H:%M:%S", tz = "America/Sao_Paulo")]
dt[, filing_date_str := NULL]
dt[, post := as.integer(filing_dt >= REFORM_DATE)]
dt[, filing_ym := as.integer(format(filing_dt, "%Y%m"))]
dt[, filing_year := year(filing_dt)]
dt[, pro_worker := as.integer(verdict_code %in% c(219L, 221L))]
dt[, rito := fifelse(grepl("Sumar", classe, ignore.case = TRUE), "sumarissimo",
                     fifelse(grepl("Ordin", classe, ignore.case = TRUE), "ordinario", "other"))]
dt[, pool := paste0(muni_ibge, "_", rito)]

pre <- dt[post == 0]
grand_mean <- pre[, mean(pro_worker, na.rm = TRUE)]
vara_leniency <- pre[, .(pre_pro_worker = mean(pro_worker), pre_n = .N), by = vara_code]
s2_between <- var(vara_leniency[pre_n >= 50]$pre_pro_worker)
s2_within <- grand_mean * (1 - grand_mean)
vara_leniency[, w_j := s2_between / (s2_between + s2_within / pre_n)]
vara_leniency[, L_j := w_j * pre_pro_worker + (1 - w_j) * grand_mean]

dt <- merge(dt, vara_leniency[, .(vara_code, L_j, pre_n)], by = "vara_code", all.x = TRUE)
dt <- dt[!is.na(L_j) & pre_n >= 30]
dt[, L_j_std := (L_j - mean(L_j)) / sd(L_j)]

cat(sprintf("Robustness sample: %d cases, %d varas\n", nrow(dt), uniqueN(dt$vara_code)))

# ══════════════════════════════════════════════════════════════
# Robustness 1: Heterogeneity by claim type (high vs low discretion)
# ══════════════════════════════════════════════════════════════
cat("\n=== HETEROGENEITY BY CLAIM TYPE ===\n")

# Classify subjects into high-discretion vs low-discretion
# High discretion: Rescisão indireta, dano moral, horas extras (ambiguous claims)
# Low discretion: Verbas rescisórias, FGTS, seguro-desemprego (statutory, clear-cut)
dt[, high_discretion := as.integer(
  grepl("Rescis.o Indireta|Dano Moral|Indeniza|Horas Extras|Justa Causa",
        subject_names, ignore.case = TRUE)
)]
dt[, low_discretion := as.integer(
  grepl("Verbas Rescis|FGTS|Seguro.Desemprego|Aviso Pr.vio|F.rias",
        subject_names, ignore.case = TRUE)
)]

cat(sprintf("High-discretion cases: %d (%.1f%%)\n",
            sum(dt$high_discretion), 100 * mean(dt$high_discretion)))
cat(sprintf("Low-discretion cases: %d (%.1f%%)\n",
            sum(dt$low_discretion), 100 * mean(dt$low_discretion)))

# Run separately
if (sum(dt$high_discretion) > 1000 & sum(dt$low_discretion) > 1000) {
  m_high <- feols(pro_worker ~ L_j_std:post | vara_code + filing_ym,
                  data = dt[high_discretion == 1], cluster = ~vara_code)
  m_low <- feols(pro_worker ~ L_j_std:post | vara_code + filing_ym,
                 data = dt[low_discretion == 1], cluster = ~vara_code)

  cat("High-discretion claims:\n")
  cat(sprintf("  gamma = %.4f (SE = %.4f)\n",
              coef(m_high)["L_j_std:post"], se(m_high)["L_j_std:post"]))
  cat("Low-discretion claims:\n")
  cat(sprintf("  gamma = %.4f (SE = %.4f)\n",
              coef(m_low)["L_j_std:post"], se(m_low)["L_j_std:post"]))
}

# ══════════════════════════════════════════════════════════════
# Robustness 2: By rito (ordinário vs sumaríssimo)
# ══════════════════════════════════════════════════════════════
cat("\n=== HETEROGENEITY BY RITO ===\n")

for (r in c("ordinario", "sumarissimo")) {
  sub <- dt[rito == r]
  if (nrow(sub) > 1000) {
    m_rito <- feols(pro_worker ~ L_j_std:post | vara_code + filing_ym,
                    data = sub, cluster = ~vara_code)
    cat(sprintf("Rito %s: gamma = %.4f (SE = %.4f, N = %d)\n",
                r, coef(m_rito)["L_j_std:post"],
                se(m_rito)["L_j_std:post"], nrow(sub)))
  }
}

# ══════════════════════════════════════════════════════════════
# Robustness 3: Placebo test — false reform date at Jan 1, 2016
# ══════════════════════════════════════════════════════════════
cat("\n=== PLACEBO TEST: FALSE REFORM AT 2016-01-01 ===\n")

pre_only <- dt[post == 0]
PLACEBO_DATE <- as.POSIXct("2016-01-01", tz = "America/Sao_Paulo")
pre_only[, placebo_post := as.integer(filing_dt >= PLACEBO_DATE)]

if (sum(pre_only$placebo_post == 0) > 1000 & sum(pre_only$placebo_post == 1) > 1000) {
  m_placebo <- feols(pro_worker ~ L_j_std:placebo_post | vara_code + filing_ym,
                     data = pre_only, cluster = ~vara_code)
  cat(sprintf("Placebo gamma = %.4f (SE = %.4f)\n",
              coef(m_placebo)["L_j_std:placebo_post"],
              se(m_placebo)["L_j_std:placebo_post"]))
} else {
  cat("Insufficient pre-placebo observations.\n")
}

# ══════════════════════════════════════════════════════════════
# Robustness 4: Different leniency thresholds (30, 50, 100 min cases)
# ══════════════════════════════════════════════════════════════
cat("\n=== SENSITIVITY TO MINIMUM CASE THRESHOLD ===\n")

for (min_n in c(30, 50, 100, 200)) {
  dt_sub <- dt[pre_n >= min_n]
  if (nrow(dt_sub) > 1000 & uniqueN(dt_sub$vara_code) > 10) {
    m_thresh <- feols(pro_worker ~ L_j_std:post | vara_code + filing_ym,
                      data = dt_sub, cluster = ~vara_code)
    cat(sprintf("Min cases = %d: gamma = %.4f (SE = %.4f, varas = %d)\n",
                min_n, coef(m_thresh)["L_j_std:post"],
                se(m_thresh)["L_j_std:post"],
                uniqueN(dt_sub$vara_code)))
  }
}

# ══════════════════════════════════════════════════════════════
# Robustness 5: Settlement as alternative outcome
# ══════════════════════════════════════════════════════════════
cat("\n=== SETTLEMENT OUTCOME ===\n")

# Include settlement cases in denominator
dt_all <- as.data.table(fread(file.path(WORK_DIR, "data", "analysis_sample.csv")))
dt_all[, filing_date_str := as.character(filing_date)]
dt_all[, filing_dt := as.POSIXct(filing_date_str, format = "%Y%m%d%H%M%S", tz = "America/Sao_Paulo")]
dt_all[is.na(filing_dt), filing_dt := as.POSIXct(filing_date_str, format = "%Y-%m-%dT%H:%M:%S", tz = "America/Sao_Paulo")]
dt_all[, filing_date_str := NULL]
dt_all[, post := as.integer(filing_dt >= REFORM_DATE)]
dt_all[, filing_ym := as.integer(format(filing_dt, "%Y%m"))]
dt_all[, settled := as.integer(has_settlement)]

dt_all <- merge(dt_all, vara_leniency[, .(vara_code, L_j, pre_n)], by = "vara_code", all.x = TRUE)
dt_all <- dt_all[!is.na(L_j) & pre_n >= 30]
dt_all[, L_j_std := (L_j - mean(L_j)) / sd(L_j)]

# Only keep cases with some outcome
dt_outcome <- dt_all[!is.na(verdict_code) | has_settlement]
if (nrow(dt_outcome) > 1000 && sd(dt_outcome$settled, na.rm = TRUE) > 0) {
  m_settle <- feols(settled ~ L_j_std:post | vara_code + filing_ym,
                    data = dt_outcome, cluster = ~vara_code)
  cat(sprintf("Settlement: gamma = %.4f (SE = %.4f)\n",
              coef(m_settle)["L_j_std:post"],
              se(m_settle)["L_j_std:post"]))
} else {
  cat("Settlement: no variation in outcome (all FALSE), skipping.\n")
  m_settle <- NULL
}

# ── Save robustness results to JSON ──
cat("\n=== SAVING ROBUSTNESS RESULTS ===\n")

rob_results <- list()

# Main spec (from 03 results for reference)
main_res <- fread(file.path(WORK_DIR, "data", "main_results.csv"))
rob_results$main <- list(
  gamma = main_res$gamma[4], se = main_res$se[4],
  n = main_res$n_cases[4], varas = main_res$n_varas[4]
)

# Heterogeneity
if (exists("m_high") && exists("m_low")) {
  rob_results$high_disc <- list(
    gamma = unname(coef(m_high)["L_j_std:post"]),
    se = unname(se(m_high)["L_j_std:post"]),
    n = nobs(m_high), varas = uniqueN(dt[high_discretion == 1]$vara_code)
  )
  rob_results$low_disc <- list(
    gamma = unname(coef(m_low)["L_j_std:post"]),
    se = unname(se(m_low)["L_j_std:post"]),
    n = nobs(m_low), varas = uniqueN(dt[low_discretion == 1]$vara_code)
  )
  # Difference computed from separate regressions
  diff_gamma <- rob_results$high_disc$gamma - rob_results$low_disc$gamma
  diff_se <- sqrt(rob_results$high_disc$se^2 + rob_results$low_disc$se^2)
  rob_results$disc_diff <- list(gamma = diff_gamma, se = diff_se)
}

# Placebo
if (exists("m_placebo")) {
  rob_results$placebo <- list(
    gamma = unname(coef(m_placebo)["L_j_std:placebo_post"]),
    se = unname(se(m_placebo)["L_j_std:placebo_post"]),
    n = nobs(m_placebo), varas = uniqueN(pre_only$vara_code)
  )
}

# Thresholds
for (min_n in c(50, 100, 200)) {
  dt_sub <- dt[pre_n >= min_n]
  if (nrow(dt_sub) > 1000 & uniqueN(dt_sub$vara_code) > 10) {
    m_thresh <- feols(pro_worker ~ L_j_std:post | vara_code + filing_ym,
                      data = dt_sub, cluster = ~vara_code)
    rob_results[[paste0("min", min_n)]] <- list(
      gamma = unname(coef(m_thresh)["L_j_std:post"]),
      se = unname(se(m_thresh)["L_j_std:post"]),
      n = nobs(m_thresh), varas = uniqueN(dt_sub$vara_code)
    )
  }
}

# Settlement
if (exists("m_settle") && !is.null(m_settle)) {
  rob_results$settlement <- list(
    gamma = unname(coef(m_settle)["L_j_std:post"]),
    se = unname(se(m_settle)["L_j_std:post"]),
    n = nobs(m_settle), varas = uniqueN(dt_outcome$vara_code)
  )
}

# Rito heterogeneity
for (r in c("ordinario", "sumarissimo")) {
  sub <- dt[rito == r]
  if (nrow(sub) > 1000 && uniqueN(sub$vara_code) > 5) {
    tryCatch({
      m_rito <- feols(pro_worker ~ L_j_std:post | vara_code + filing_ym,
                      data = sub, cluster = ~vara_code)
      rob_results[[paste0("rito_", r)]] <- list(
        gamma = unname(coef(m_rito)["L_j_std:post"]),
        se = unname(se(m_rito)["L_j_std:post"]),
        n = nobs(m_rito), varas = uniqueN(sub$vara_code)
      )
    }, error = function(e) {
      cat(sprintf("  Rito %s regression failed: %s\n", r, e$message))
    })
  }
}

# SD(Y) for SDE
rob_results$sd_y <- list(
  pro_worker = sd(dt$pro_worker, na.rm = TRUE),
  full_pro = sd(as.integer(dt$verdict_code == 219L), na.rm = TRUE),
  settlement = if (exists("dt_outcome")) sd(dt_outcome$settled, na.rm = TRUE) else NA
)
if (sum(dt$high_discretion) > 100) {
  rob_results$sd_y$high_disc <- sd(dt[high_discretion == 1]$pro_worker, na.rm = TRUE)
}
if (sum(dt$low_discretion) > 100) {
  rob_results$sd_y$low_disc <- sd(dt[low_discretion == 1]$pro_worker, na.rm = TRUE)
}
rob_results$sd_y$ordinario <- if (nrow(dt[rito == "ordinario"]) > 100) sd(dt[rito == "ordinario"]$pro_worker, na.rm = TRUE) else NA

# Full procedencia regression for SDE
dt[, full_pro_worker := as.integer(verdict_code == 219L)]
m_full <- feols(full_pro_worker ~ L_j_std:post | vara_code + filing_ym,
                data = dt, cluster = ~vara_code)
rob_results$full_pro <- list(
  gamma = unname(coef(m_full)["L_j_std:post"]),
  se = unname(se(m_full)["L_j_std:post"]),
  n = nobs(m_full)
)

write(jsonlite::toJSON(rob_results, auto_unbox = TRUE, pretty = TRUE),
      file.path(WORK_DIR, "data", "robustness_results.json"))
cat("Saved robustness_results.json\n")
cat("\n=== ROBUSTNESS COMPLETE ===\n")
