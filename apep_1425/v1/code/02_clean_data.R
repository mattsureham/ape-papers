## 02_clean_data.R — apep_1425
## Clean DataJud cases, construct variables, audit assignment pools

this_script <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("--file=", args, value = TRUE)
  if (length(file_arg) > 0) normalizePath(sub("--file=", "", file_arg)) else getwd()
})
SCRIPT_DIR <- dirname(this_script)
source(file.path(SCRIPT_DIR, "00_packages.R"))
WORK_DIR <- file.path(SCRIPT_DIR, "..")

# ── Load combined data ──
dt <- as.data.table(fread(file.path(WORK_DIR, "data", "all_cases.csv")))
cat(sprintf("Loaded %d cases\n", nrow(dt)))

# ── Parse dates ──
# filing_date comes as numeric e.g. 20230917143020 or string ISO format
dt[, filing_date_str := as.character(filing_date)]
dt[, filing_dt := as.POSIXct(filing_date_str, format = "%Y%m%d%H%M%S", tz = "America/Sao_Paulo")]
# Try ISO format if above failed
dt[is.na(filing_dt), filing_dt := as.POSIXct(filing_date_str, format = "%Y-%m-%dT%H:%M:%S", tz = "America/Sao_Paulo")]
dt[, filing_date_str := NULL]
dt[, filing_ym := as.integer(format(filing_dt, "%Y%m"))]
dt[, filing_year := year(filing_dt)]
dt[, filing_month := month(filing_dt)]
dt[, filing_quarter := quarter(filing_dt)]

# ── Treatment variable: Post Nov 11, 2017 ──
REFORM_DATE <- as.POSIXct("2017-11-11", tz = "America/Sao_Paulo")
dt[, post := as.integer(filing_dt >= REFORM_DATE)]

# ── Outcome: Pro-worker verdict ──
# 219 = Procedência (full plaintiff win)
# 220 = Improcedência (defendant wins)
# 221 = Procedência em Parte (partial plaintiff win)
dt[, pro_worker := as.integer(verdict_code %in% c(219L, 221L))]
dt[, full_pro_worker := as.integer(verdict_code == 219L)]
dt[, defendant_wins := as.integer(verdict_code == 220L)]

# ── Filter: keep only cases with a verdict ──
cat(sprintf("Cases with verdict: %d / %d (%.1f%%)\n",
            sum(!is.na(dt$verdict_code)), nrow(dt),
            100 * sum(!is.na(dt$verdict_code)) / nrow(dt)))

# Keep cases with verdict OR settlement for denominator
dt[, has_outcome := !is.na(verdict_code) | has_settlement]
cat(sprintf("Cases with any outcome (verdict or settlement): %d / %d (%.1f%%)\n",
            sum(dt$has_outcome), nrow(dt),
            100 * sum(dt$has_outcome) / nrow(dt)))

# ── Case class (rito) ──
# Rito Ordinário, Rito Sumaríssimo, etc.
dt[, rito := fifelse(
  grepl("Sumar", classe, ignore.case = TRUE), "sumarissimo",
  fifelse(grepl("Ordin", classe, ignore.case = TRUE), "ordinario", "other")
)]
cat("Case class distribution:\n")
print(dt[, .N, by = rito][order(-N)])

# ── Extract TRT from vara_code or case_id ──
# Case ID format: NNNNNNN-DD.AAAA.J.TT.OOOO
# TRT is positions 14-15 in the CNJ numbering
dt[, trt_code := substr(case_id, 14, 15)]
dt[, trt_code := as.integer(trt_code)]

# ── Assignment pool: forum/municipality × rito ──
# Pool = muni_ibge × rito
dt[, pool := paste0(muni_ibge, "_", rito)]

# ── Filter to analysis sample ──
# Keep cases with: verdict, valid vara, valid filing date, pre-2024
analysis <- dt[!is.na(verdict_code) & !is.na(vara_code) &
               !is.na(filing_dt) & filing_year >= 2012 & filing_year <= 2023]

cat(sprintf("\nAnalysis sample: %d cases\n", nrow(analysis)))
cat(sprintf("Unique varas: %d\n", uniqueN(analysis$vara_code)))
cat(sprintf("Unique pools: %d\n", uniqueN(analysis$pool)))
cat(sprintf("Date range: %s to %s\n",
            min(analysis$filing_dt), max(analysis$filing_dt)))
cat(sprintf("Pre-reform: %d | Post-reform: %d\n",
            sum(analysis$post == 0), sum(analysis$post == 1)))

# ── Assignment pool audit ──
cat("\n=== ASSIGNMENT POOL AUDIT ===\n")

# 1. Within-pool balance: subject distribution across varas
# For each pool with 2+ varas, test if subject distribution differs across varas
pool_vara_counts <- analysis[, .(n_varas = uniqueN(vara_code), n_cases = .N), by = pool]
multi_vara_pools <- pool_vara_counts[n_varas >= 2]
cat(sprintf("Pools with 2+ varas: %d (%.0f%% of cases)\n",
            nrow(multi_vara_pools),
            100 * sum(multi_vara_pools$n_cases) / nrow(analysis)))

# 2. Within-pool balance test: chi-squared test of subject distribution
set.seed(42)
sample_pools <- multi_vara_pools[n_cases >= 100][sample(.N, min(.N, 50))]$pool

balance_pvals <- numeric(length(sample_pools))
for (i in seq_along(sample_pools)) {
  p <- sample_pools[i]
  pool_data <- analysis[pool == p]
  # Get top 5 subjects
  top_subjects <- pool_data[, .N, by = subject_codes][order(-N)][1:min(.N, 5)]$subject_codes
  pool_data[, subj_cat := fifelse(subject_codes %in% top_subjects, subject_codes, "other")]
  tab <- table(pool_data$vara_code, pool_data$subj_cat)
  if (nrow(tab) >= 2 && ncol(tab) >= 2) {
    test <- chisq.test(tab, simulate.p.value = TRUE, B = 1000)
    balance_pvals[i] <- test$p.value
  } else {
    balance_pvals[i] <- NA
  }
}

cat(sprintf("Balance test: %d/%d pools pass at 5%% (expect ~95%%)\n",
            sum(balance_pvals > 0.05, na.rm = TRUE),
            sum(!is.na(balance_pvals))))
cat(sprintf("Median p-value: %.3f\n", median(balance_pvals, na.rm = TRUE)))

# 3. Vara stability check: autocorrelation of annual verdict rates
cat("\n=== VARA STABILITY CHECK ===\n")
vara_year <- analysis[, .(
  pro_worker_rate = mean(pro_worker, na.rm = TRUE),
  n_cases = .N
), by = .(vara_code, filing_year)]

# Require at least 30 cases per vara-year
vara_year <- vara_year[n_cases >= 30]

# Compute year-to-year correlation
vara_year[, lag_rate := shift(pro_worker_rate, 1), by = vara_code]
acf_result <- vara_year[!is.na(lag_rate), cor(pro_worker_rate, lag_rate)]
cat(sprintf("Year-to-year autocorrelation of vara verdict rate: %.3f\n", acf_result))
cat("  (High autocorrelation suggests stable judge assignment within varas)\n")

# Compute within-vara variance vs between-vara variance
vara_means <- analysis[, .(mean_rate = mean(pro_worker, na.rm = TRUE), n = .N), by = vara_code]
vara_means <- vara_means[n >= 50]
cat(sprintf("Between-vara SD in pro-worker rate: %.3f\n", sd(vara_means$mean_rate)))

# ── Save cleaned analysis dataset ──
fwrite(analysis, file.path(WORK_DIR, "data", "analysis_sample.csv"))
cat(sprintf("\nSaved analysis sample: %d cases\n", nrow(analysis)))

# ── Summary stats for diagnostics.json ──
# Use filing_year for pre-period count since design uses annual leniency variation
diag <- list(
  n_treated = uniqueN(analysis$vara_code),
  n_pre = length(unique(analysis[post == 0]$filing_year)),
  n_obs = nrow(analysis)
)
write(jsonlite::toJSON(diag, auto_unbox = TRUE, pretty = TRUE),
      file.path(WORK_DIR, "data", "diagnostics.json"))
cat(sprintf("diagnostics.json: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))
