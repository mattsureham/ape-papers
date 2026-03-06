## 04_robustness.R — Robustness checks for apep_0537
## GenAI as Seniority-Biased Technological Change

source("00_packages.R")
data_dir <- "../data/"

ddd_panel <- fread(file.path(data_dir, "ddd_panel.csv"))
qcew_analysis <- fread(file.path(data_dir, "qcew_analysis.csv"))
oews_ind_sen <- fread(file.path(data_dir, "oews_industry_seniority.csv"))
ind_aioe <- unique(ddd_panel[!is.na(aioe_industry), .(naics_2d, aioe_industry)])

# Reconstruct entry_2d
entry_2d <- oews_ind_sen[seniority == "Entry-Level",
  .(entry_emp = sum(total_emp, na.rm = TRUE),
    total_emp = sum(industry_total, na.rm = TRUE)),
  by = .(naics_2d, oews_year)
]
entry_2d[, entry_share := entry_emp / total_emp]
entry_2d <- merge(entry_2d, ind_aioe, by = "naics_2d", all.x = TRUE)
entry_2d <- entry_2d[!is.na(aioe_industry)]
entry_2d[, `:=`(
  post = as.integer(oews_year >= 2023),
  high_aioe = as.integer(aioe_industry > median(aioe_industry, na.rm = TRUE))
)]

# Senior share
senior_2d <- oews_ind_sen[seniority == "Senior",
  .(senior_emp = sum(total_emp, na.rm = TRUE),
    total_emp = sum(industry_total, na.rm = TRUE)),
  by = .(naics_2d, oews_year)
]
senior_2d[, senior_share := senior_emp / total_emp]
senior_2d <- merge(senior_2d, ind_aioe, by = "naics_2d", all.x = TRUE)
senior_2d <- senior_2d[!is.na(aioe_industry)]
senior_2d[, post := as.integer(oews_year >= 2023)]

cat("=== Robustness Checks ===\n\n")

# ===========================================================================
# R1: Placebo — Pre-ChatGPT (fake treatment at 2020)
# ===========================================================================
cat("--- R1: Placebo (fake post at 2020) ---\n")

entry_pre <- entry_2d[oews_year <= 2022]
entry_pre[, placebo_post := as.integer(oews_year >= 2020)]

r1 <- feols(entry_share ~ aioe_industry:placebo_post | naics_2d + oews_year,
            data = entry_pre, cluster = ~naics_2d)
cat(sprintf("  Placebo (entry share): coef = %.4f, se = %.4f, t = %.2f\n",
            coef(r1), se(r1), tstat(r1)))

# ===========================================================================
# R2: Excluding Tech and Professional Services (NAICS 51, 54)
# ===========================================================================
cat("\n--- R2: Excluding NAICS 51 & 54 ---\n")

r2_entry <- feols(entry_share ~ aioe_industry:post | naics_2d + oews_year,
                  data = entry_2d[!naics_2d %in% c("51", "54")],
                  cluster = ~naics_2d)
r2_senior <- feols(senior_share ~ aioe_industry:post | naics_2d + oews_year,
                   data = senior_2d[!naics_2d %in% c("51", "54")],
                   cluster = ~naics_2d)
cat(sprintf("  Entry share excl tech: coef = %.4f, se = %.4f, t = %.2f\n",
            coef(r2_entry), se(r2_entry), tstat(r2_entry)))
cat(sprintf("  Senior share excl tech: coef = %.4f, se = %.4f, t = %.2f\n",
            coef(r2_senior), se(r2_senior), tstat(r2_senior)))

# ===========================================================================
# R3: Healthcare Placebo (NAICS 62 — high AI discussion, no displacement)
# ===========================================================================
cat("\n--- R3: Healthcare Placebo ---\n")

hc_entry <- entry_2d[naics_2d == "62"]
if (nrow(hc_entry) > 2) {
  cat(sprintf("  Healthcare entry share trend:\n"))
  print(hc_entry[order(oews_year), .(oews_year, entry_share)])
}

# ===========================================================================
# R4: Alternative post-period (2022 instead of 2023)
# ===========================================================================
cat("\n--- R4: Alternative post-period (post = 2022+) ---\n")

entry_2d[, post_2022 := as.integer(oews_year >= 2022)]
r4 <- feols(entry_share ~ aioe_industry:post_2022 | naics_2d + oews_year,
            data = entry_2d, cluster = ~naics_2d)
cat(sprintf("  Entry share (post=2022+): coef = %.4f, se = %.4f, t = %.2f\n",
            coef(r4), se(r4), tstat(r4)))

# ===========================================================================
# R5: Continuous treatment intensity (AIOE score)
# ===========================================================================
cat("\n--- R5: Tercile treatment ---\n")

entry_2d[, aioe_tercile := fcase(
  aioe_industry >= quantile(aioe_industry, 0.67), "High",
  aioe_industry >= quantile(aioe_industry, 0.33), "Medium",
  default = "Low"
)]

r5 <- feols(entry_share ~ i(aioe_tercile, post, ref = "Low") | naics_2d + oews_year,
            data = entry_2d, cluster = ~naics_2d)
cat("  Tercile results:\n")
print(coeftable(r5))

# ===========================================================================
# R6: QCEW — Placebo at 2020Q1
# ===========================================================================
cat("\n--- R6: QCEW Placebo (fake post at 2020Q1) ---\n")

qcew_3d <- qcew_analysis[naics_len == 3 & !is.na(aioe_industry) & emp > 0]
qcew_3d[, `:=`(
  ln_emp = log(emp),
  placebo_post = as.integer(yearqtr >= 2020.0)
)]

qcew_pre <- qcew_3d[yearqtr < 2023.0]
r6 <- feols(ln_emp ~ aioe_industry:placebo_post | naics_code + time_idx,
            data = qcew_pre, cluster = ~naics_2d)
cat(sprintf("  QCEW placebo (pre-2023): coef = %.4f, se = %.4f, t = %.2f\n",
            coef(r6), se(r6), tstat(r6)))

# ===========================================================================
# R7: DDD with different seniority cutoffs
# ===========================================================================
cat("\n--- R7: DDD with alternative seniority thresholds ---\n")

ddd_panel[, `:=`(
  junior = as.integer(seniority == "Entry-Level"),
  high_aioe = as.integer(aioe_industry > median(aioe_industry, na.rm = TRUE)),
  post = as.integer(oews_year >= 2023)
)]

# Entry + Mid vs Senior
ddd_panel[, non_senior := as.integer(seniority != "Senior")]
r7 <- feols(ln_emp ~ aioe_industry:non_senior:post +
              aioe_industry:post + non_senior:post |
              ind_sen + oews_year,
            data = ddd_panel[!is.na(aioe_industry)],
            cluster = ~naics_2d)
cat(sprintf("  DDD (non-senior vs senior): coef = %.4f, se = %.4f, t = %.2f\n",
            coef(r7)[1], se(r7)[1], tstat(r7)[1]))

# ===========================================================================
# Save all robustness results
# ===========================================================================
# ===========================================================================
# R8: Wild Cluster Bootstrap p-values
# ===========================================================================
cat("\n--- R8: Wild Cluster Bootstrap ---\n")

# Main DiD (entry share, continuous)
m_main <- feols(entry_share ~ aioe_industry:post | naics_2d + oews_year,
                data = entry_2d, cluster = ~naics_2d)

# Permutation inference: randomly reassign AIOE across industries
set.seed(42)
B <- 999
industries <- unique(entry_2d$naics_2d)
actual_coef <- coef(m_main)

perm_coefs <- numeric(B)
for (b in seq_len(B)) {
  perm_map <- data.table(naics_2d = industries,
                         aioe_perm = sample(unique(entry_2d[, .(naics_2d, aioe_industry)])$aioe_industry))
  d_perm <- merge(entry_2d[, .(naics_2d, oews_year, entry_share, post)],
                  perm_map, by = "naics_2d")
  m_perm <- tryCatch(
    feols(entry_share ~ aioe_perm:post | naics_2d + oews_year, data = d_perm, cluster = ~naics_2d),
    error = function(e) NULL
  )
  if (!is.null(m_perm)) perm_coefs[b] <- coef(m_perm) else perm_coefs[b] <- NA
}

perm_p <- mean(abs(perm_coefs) >= abs(actual_coef), na.rm = TRUE)
cat(sprintf("  Entry share (continuous): permutation p = %.4f (conventional p = %.4f)\n",
            perm_p, summary(m_main)$coeftable[1, 4]))

# Binary treatment permutation
m_binary <- feols(entry_share ~ high_aioe:post | naics_2d + oews_year,
                  data = entry_2d, cluster = ~naics_2d)
actual_binary <- coef(m_binary)

perm_binary <- numeric(B)
for (b in seq_len(B)) {
  perm_map <- data.table(naics_2d = industries,
                         ha_perm = sample(unique(entry_2d[, .(naics_2d, high_aioe)])$high_aioe))
  d_perm <- merge(entry_2d[, .(naics_2d, oews_year, entry_share, post)],
                  perm_map, by = "naics_2d")
  m_perm <- tryCatch(
    feols(entry_share ~ ha_perm:post | naics_2d + oews_year, data = d_perm, cluster = ~naics_2d),
    error = function(e) NULL
  )
  if (!is.null(m_perm)) perm_binary[b] <- coef(m_perm) else perm_binary[b] <- NA
}

perm_p_binary <- mean(abs(perm_binary) >= abs(actual_binary), na.rm = TRUE)
cat(sprintf("  Entry share (binary): permutation p = %.4f (conventional p = %.4f)\n",
            perm_p_binary, summary(m_binary)$coeftable[1, 4]))

# Senior share permutation
m_senior_cont <- feols(senior_share ~ aioe_industry:post | naics_2d + oews_year,
                       data = senior_2d, cluster = ~naics_2d)
actual_senior <- coef(m_senior_cont)

perm_senior <- numeric(B)
for (b in seq_len(B)) {
  perm_map <- data.table(naics_2d = industries,
                         aioe_perm = sample(unique(senior_2d[, .(naics_2d, aioe_industry)])$aioe_industry))
  d_perm <- merge(senior_2d[, .(naics_2d, oews_year, senior_share, post)],
                  perm_map, by = "naics_2d")
  m_perm <- tryCatch(
    feols(senior_share ~ aioe_perm:post | naics_2d + oews_year, data = d_perm, cluster = ~naics_2d),
    error = function(e) NULL
  )
  if (!is.null(m_perm)) perm_senior[b] <- coef(m_perm) else perm_senior[b] <- NA
}

perm_p_senior <- mean(abs(perm_senior) >= abs(actual_senior), na.rm = TRUE)
cat(sprintf("  Senior share (continuous): permutation p = %.4f (conventional p = %.4f)\n",
            perm_p_senior, summary(m_senior_cont)$coeftable[1, 4]))

# Save permutation results
perm_results <- data.table(
  spec = c("Entry Share (Continuous)", "Entry Share (Binary)", "Senior Share (Continuous)"),
  coef = c(actual_coef, actual_binary, actual_senior),
  conventional_p = c(summary(m_main)$coeftable[1,4],
                     summary(m_binary)$coeftable[1,4],
                     summary(m_senior_cont)$coeftable[1,4]),
  permutation_p = c(perm_p, perm_p_binary, perm_p_senior)
)
fwrite(perm_results, file.path(data_dir, "permutation_results.csv"))
cat("  Permutation results:\n")
print(perm_results)

# ===========================================================================
# R9: Industry-Specific Linear Trends
# ===========================================================================
cat("\n--- R9: Industry-Specific Linear Trends ---\n")

entry_2d[, year_c := oews_year - 2019]  # center for numerical stability
senior_2d[, year_c := oews_year - 2019]

r9 <- feols(entry_share ~ aioe_industry:post | naics_2d[year_c] + oews_year,
            data = entry_2d, cluster = ~naics_2d)
cat(sprintf("  Entry share with industry trends: coef = %.4f, se = %.4f, t = %.2f\n",
            coef(r9), se(r9), tstat(r9)))

r9_senior <- feols(senior_share ~ aioe_industry:post | naics_2d[year_c] + oews_year,
                   data = senior_2d, cluster = ~naics_2d)
cat(sprintf("  Senior share with industry trends: coef = %.4f, se = %.4f, t = %.2f\n",
            coef(r9_senior), se(r9_senior), tstat(r9_senior)))

# Joint F-test for pre-trend coefficients
cat("\n--- Joint pre-trend F-test ---\n")
m_event <- feols(entry_share ~ aioe_industry:i(oews_year, ref = 2022) | naics_2d + oews_year,
                 data = entry_2d, cluster = ~naics_2d)
# Test all pre-period interactions jointly
pre_coefs <- grep("2015|2016|2017|2018|2019|2020|2021", names(coef(m_event)), value = TRUE)
if (length(pre_coefs) > 0) {
  wt <- wald(m_event, pre_coefs)
  cat(sprintf("  Joint F-test (pre-2022 coefficients): F = %.2f, p = %.4f\n",
              wt$stat, wt$p))
}

cat("\n=== ROBUSTNESS SUMMARY ===\n")

rob_results <- data.table(
  spec = c("R1: Placebo 2020", "R2: Excl Tech (Entry)", "R2: Excl Tech (Senior)",
           "R4: Post=2022", "R6: QCEW Placebo", "R7: Non-senior DDD"),
  coef = c(coef(r1), coef(r2_entry), coef(r2_senior),
           coef(r4), coef(r6), coef(r7)[1]),
  se = c(se(r1), se(r2_entry), se(r2_senior),
         se(r4), se(r6), se(r7)[1]),
  t_stat = c(tstat(r1), tstat(r2_entry), tstat(r2_senior),
             tstat(r4), tstat(r6), tstat(r7)[1])
)

print(rob_results)
fwrite(rob_results, file.path(data_dir, "robustness_results.csv"))

saveRDS(list(r1 = r1, r2_entry = r2_entry, r2_senior = r2_senior,
             r4 = r4, r5 = r5, r6 = r6, r7 = r7),
        file.path(data_dir, "results_robustness.rds"))

cat("\n=== Robustness checks complete ===\n")
