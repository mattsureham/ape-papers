## 03_main_analysis.R — apep_1425
## Main analysis: Leniency compression after 2017 reform

this_script <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("--file=", args, value = TRUE)
  if (length(file_arg) > 0) normalizePath(sub("--file=", "", file_arg)) else getwd()
})
SCRIPT_DIR <- dirname(this_script)
source(file.path(SCRIPT_DIR, "00_packages.R"))
WORK_DIR <- file.path(SCRIPT_DIR, "..")

# ── Load analysis sample ──
dt <- as.data.table(fread(file.path(WORK_DIR, "data", "analysis_sample.csv")))
cat(sprintf("Analysis sample: %d cases\n", nrow(dt)))

# ── Step 1: Compute pre-reform court leniency L_j ──
cat("\n=== COMPUTING PRE-REFORM COURT LENIENCY ===\n")

pre <- dt[post == 0]

# Raw vara-level pro-worker rate (leave-one-out not needed at this scale)
vara_leniency_raw <- pre[, .(
  pre_pro_worker = mean(pro_worker, na.rm = TRUE),
  pre_n = .N
), by = vara_code]

cat(sprintf("Pre-reform varas: %d\n", nrow(vara_leniency_raw)))
cat(sprintf("Pre-reform cases: %d\n", sum(vara_leniency_raw$pre_n)))

# Empirical Bayes shrinkage
# L_j^EB = w_j * L_j^raw + (1 - w_j) * L_grand
# w_j = s2_between / (s2_between + s2_within/n_j)
grand_mean <- pre[, mean(pro_worker, na.rm = TRUE)]
s2_between <- var(vara_leniency_raw[pre_n >= 50]$pre_pro_worker)
# Approximate within-vara variance as p*(1-p) for binary outcome
s2_within <- grand_mean * (1 - grand_mean)

vara_leniency_raw[, w_j := s2_between / (s2_between + s2_within / pre_n)]
vara_leniency_raw[, L_j := w_j * pre_pro_worker + (1 - w_j) * grand_mean]

cat(sprintf("Grand mean pro-worker rate: %.3f\n", grand_mean))
cat(sprintf("Between-vara variance: %.5f\n", s2_between))
cat(sprintf("EB shrinkage range: w_j in [%.3f, %.3f]\n",
            min(vara_leniency_raw$w_j), max(vara_leniency_raw$w_j)))
cat(sprintf("L_j range: [%.3f, %.3f]\n",
            min(vara_leniency_raw$L_j), max(vara_leniency_raw$L_j)))

# ── Step 2: Split-sample validation ──
cat("\n=== SPLIT-SAMPLE VALIDATION ===\n")

# Odd years vs even years
pre[, odd_year := filing_year %% 2 == 1]

L_odd <- pre[odd_year == TRUE, .(L_odd = mean(pro_worker, na.rm = TRUE), n_odd = .N), by = vara_code]
L_even <- pre[odd_year == FALSE, .(L_even = mean(pro_worker, na.rm = TRUE), n_even = .N), by = vara_code]

split_val <- merge(L_odd, L_even, by = "vara_code")
split_val <- split_val[n_odd >= 10 & n_even >= 10]

split_cor <- cor(split_val$L_odd, split_val$L_even)
cat(sprintf("Split-sample correlation (odd vs even years): %.3f\n", split_cor))
cat(sprintf("  (n=%d varas with 30+ cases in both splits)\n", nrow(split_val)))

# ── Step 3: Merge leniency to full dataset ──
dt <- merge(dt, vara_leniency_raw[, .(vara_code, L_j, pre_n)], by = "vara_code", all.x = TRUE)

# Drop varas with too few pre-reform cases for reliable leniency
dt <- dt[!is.na(L_j) & pre_n >= 30]
cat(sprintf("After dropping thin varas: %d cases, %d varas\n",
            nrow(dt), uniqueN(dt$vara_code)))

# Standardize L_j for interpretation
dt[, L_j_std := (L_j - mean(L_j)) / sd(L_j)]

# ── Step 4: Main regression ──
cat("\n=== MAIN REGRESSIONS ===\n")

# Model 1: Baseline (no pool FE)
m1 <- feols(pro_worker ~ L_j_std * post | filing_ym, data = dt,
            cluster = ~vara_code)
cat("Model 1: L_j × Post, year-month FE, clustered by vara\n")
print(summary(m1))

# Model 2: Pool × month FE
m2 <- feols(pro_worker ~ L_j_std * post | pool + filing_ym, data = dt,
            cluster = ~vara_code)
cat("\nModel 2: + pool FE\n")
print(summary(m2))

# Model 3: Pool × month FE + case controls
m3 <- feols(pro_worker ~ L_j_std * post + i(rito) | pool + filing_ym, data = dt,
            cluster = ~vara_code)
cat("\nModel 3: + rito controls\n")
print(summary(m3))

# Model 4: Pool × year-month interaction FE (most saturated)
# Create pool-yearmonth interaction
dt[, pool_ym := paste0(pool, "_", filing_ym)]
m4 <- feols(pro_worker ~ L_j_std:post | vara_code + filing_ym, data = dt,
            cluster = ~vara_code)
cat("\nModel 4: Vara FE + year-month FE (absorbs L_j main effect)\n")
print(summary(m4))

# ── Step 5: Save coefficients for tables ──
results <- data.table(
  model = c("M1", "M2", "M3", "M4"),
  gamma = c(coef(m1)["L_j_std:post"],
            coef(m2)["L_j_std:post"],
            coef(m3)["L_j_std:post"],
            coef(m4)["L_j_std:post"]),
  se = c(se(m1)["L_j_std:post"],
         se(m2)["L_j_std:post"],
         se(m3)["L_j_std:post"],
         se(m4)["L_j_std:post"]),
  n_cases = c(nobs(m1), nobs(m2), nobs(m3), nobs(m4)),
  n_varas = c(uniqueN(dt$vara_code), uniqueN(dt$vara_code),
              uniqueN(dt$vara_code), uniqueN(dt$vara_code))
)
results[, pval := 2 * pnorm(-abs(gamma / se))]
results[, stars := fifelse(pval < 0.01, "***",
                           fifelse(pval < 0.05, "**",
                                   fifelse(pval < 0.1, "*", "")))]

cat("\n=== RESULTS SUMMARY ===\n")
print(results)

fwrite(results, file.path(WORK_DIR, "data", "main_results.csv"))

# ── Step 6: Pre-reform leniency distribution stats ──
cat("\n=== LENIENCY DISTRIBUTION ===\n")
cat(sprintf("Mean L_j: %.3f\n", mean(vara_leniency_raw$L_j)))
cat(sprintf("SD L_j: %.3f\n", sd(vara_leniency_raw$L_j)))
cat(sprintf("P10: %.3f  P25: %.3f  P50: %.3f  P75: %.3f  P90: %.3f\n",
            quantile(vara_leniency_raw$L_j, 0.10),
            quantile(vara_leniency_raw$L_j, 0.25),
            quantile(vara_leniency_raw$L_j, 0.50),
            quantile(vara_leniency_raw$L_j, 0.75),
            quantile(vara_leniency_raw$L_j, 0.90)))

# ── Step 7: Post-reform compression measure ──
cat("\n=== POST-REFORM COMPRESSION ===\n")

# Compute post-reform vara effects
post_data <- dt[post == 1]
vara_post <- post_data[, .(
  post_pro_worker = mean(pro_worker, na.rm = TRUE),
  post_n = .N
), by = vara_code]
vara_post <- vara_post[post_n >= 30]

# Merge with pre
comp <- merge(vara_leniency_raw[pre_n >= 30, .(vara_code, L_j, pre_pro_worker)],
              vara_post, by = "vara_code")

cat(sprintf("Varas in both periods (30+ cases each): %d\n", nrow(comp)))
cat(sprintf("Pre-reform SD of raw rates: %.4f\n", sd(comp$pre_pro_worker)))
cat(sprintf("Post-reform SD of raw rates: %.4f\n", sd(comp$post_pro_worker)))
cat(sprintf("Compression ratio (post/pre SD): %.3f\n",
            sd(comp$post_pro_worker) / sd(comp$pre_pro_worker)))

# Regression to the mean check: pre-post correlation
pre_post_cor <- cor(comp$pre_pro_worker, comp$post_pro_worker)
cat(sprintf("Pre-post correlation (raw): %.3f\n", pre_post_cor))

# EB version — L_j already in comp from first merge
cat(sprintf("Pre-post correlation (EB leniency vs post raw): %.3f\n",
            cor(as.numeric(comp$L_j), as.numeric(comp$post_pro_worker))))

# Save compression stats
fwrite(comp, file.path(WORK_DIR, "data", "compression_stats.csv"))

# ── Update diagnostics.json ──
diag <- list(
  n_treated = uniqueN(dt$vara_code),
  n_pre = length(unique(dt[post == 0]$filing_ym)),
  n_obs = nrow(dt)
)
write(jsonlite::toJSON(diag, auto_unbox = TRUE, pretty = TRUE),
      file.path(WORK_DIR, "data", "diagnostics.json"))
cat(sprintf("\ndiagnostics.json updated: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diag$n_treated, diag$n_pre, diag$n_obs))
