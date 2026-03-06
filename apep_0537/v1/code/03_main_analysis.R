## 03_main_analysis.R — Main regressions for apep_0537
## GenAI as Seniority-Biased Technological Change

source("00_packages.R")
data_dir <- "../data/"

# ===========================================================================
# Load analysis datasets
# ===========================================================================
ddd_panel <- fread(file.path(data_dir, "ddd_panel.csv"))
qcew_analysis <- fread(file.path(data_dir, "qcew_analysis.csv"))
oews_ind_sen <- fread(file.path(data_dir, "oews_industry_seniority.csv"))
oews_ind_ai <- fread(file.path(data_dir, "oews_industry_ai_seniority.csv"))

cat("=== Main Analysis ===\n\n")

# ===========================================================================
# Analysis 1: OEWS — Entry-Level Employment Share
# ===========================================================================
cat("--- Analysis 1: OEWS Entry-Level Employment Share ---\n")

# Panel at NAICS 2-digit × year (unit = NAICS 2d)
entry_share <- oews_ind_sen[seniority == "Entry-Level",
  .(entry_share = emp_share, entry_emp = total_emp, industry_total),
  by = .(naics_3d, naics_2d, oews_year)
]

# Aggregate to naics_2d level
entry_2d <- entry_share[,
  .(entry_emp = sum(entry_emp, na.rm = TRUE),
    total_emp = sum(industry_total, na.rm = TRUE)),
  by = .(naics_2d, oews_year)
]
entry_2d[, entry_share := entry_emp / total_emp]

# Merge AIOE
ind_aioe <- unique(ddd_panel[!is.na(aioe_industry), .(naics_2d, aioe_industry)])
entry_2d <- merge(entry_2d, ind_aioe, by = "naics_2d", all.x = TRUE)
entry_2d <- entry_2d[!is.na(aioe_industry)]

entry_2d[, `:=`(
  post = as.integer(oews_year >= 2023),
  high_aioe = as.integer(aioe_industry > median(aioe_industry, na.rm = TRUE)),
  ln_entry_emp = log(entry_emp + 1),
  ln_total_emp = log(total_emp + 1)
)]

# Spec 1a: Entry-level share ~ AIOE × Post (industry + year FE)
m1a <- feols(entry_share ~ aioe_industry:post | naics_2d + oews_year,
             data = entry_2d, cluster = ~naics_2d)

# Spec 1b: Event study — entry share ~ AIOE × year dummies (with year FE)
m1b <- feols(entry_share ~ aioe_industry:i(oews_year, ref = 2022) | naics_2d + oews_year,
             data = entry_2d, cluster = ~naics_2d)

# Spec 1c: Binary treatment
m1c <- feols(entry_share ~ high_aioe:post | naics_2d + oews_year,
             data = entry_2d, cluster = ~naics_2d)

# Spec 1d: Log entry-level employment
m1d <- feols(ln_entry_emp ~ aioe_industry:post | naics_2d + oews_year,
             data = entry_2d, cluster = ~naics_2d)

cat("\n--- Spec 1a: Entry-Level Share ~ AIOE × Post ---\n")
print(summary(m1a))

cat("\n--- Spec 1b: Event Study ---\n")
print(summary(m1b))

cat("\n--- Spec 1c: Binary (High AIOE × Post) ---\n")
print(summary(m1c))

cat("\n--- Spec 1d: Log Entry Employment ~ AIOE × Post ---\n")
print(summary(m1d))

saveRDS(list(m1a = m1a, m1b = m1b, m1c = m1c, m1d = m1d),
        file.path(data_dir, "results_oews_entry_share.rds"))

# Also compute senior employment share for comparison
senior_2d <- oews_ind_sen[seniority == "Senior",
  .(senior_emp = sum(total_emp, na.rm = TRUE),
    total_emp = sum(industry_total, na.rm = TRUE)),
  by = .(naics_2d, oews_year)
]
senior_2d[, senior_share := senior_emp / total_emp]
senior_2d <- merge(senior_2d, ind_aioe, by = "naics_2d", all.x = TRUE)
senior_2d <- senior_2d[!is.na(aioe_industry)]
senior_2d[, post := as.integer(oews_year >= 2023)]

m1e <- feols(senior_share ~ aioe_industry:post | naics_2d + oews_year,
             data = senior_2d, cluster = ~naics_2d)

cat("\n--- Spec 1e: Senior Share ~ AIOE × Post (comparison) ---\n")
print(summary(m1e))

# ===========================================================================
# Analysis 2: Triple-Diff — Industry × Seniority × Post
# ===========================================================================
cat("\n--- Analysis 2: Triple-Difference ---\n")

ddd_panel[, `:=`(
  entry = as.integer(seniority == "Entry-Level"),
  mid = as.integer(seniority == "Mid-Level"),
  sen = as.integer(seniority == "Senior")
)]

# Triple-diff: AIOE × Junior × Post
m2a <- feols(ln_emp ~ aioe_industry:junior:post +
               aioe_industry:post + junior:post |
               ind_sen + oews_year,
             data = ddd_panel[!is.na(aioe_industry)],
             cluster = ~naics_2d)

# Event study version
m2b <- feols(ln_emp ~ aioe_industry:junior:i(oews_year, ref = 2022) +
               aioe_industry:i(oews_year, ref = 2022) +
               junior:i(oews_year, ref = 2022) |
               ind_sen,
             data = ddd_panel[!is.na(aioe_industry)],
             cluster = ~naics_2d)

# Binary treatment
m2c <- feols(ln_emp ~ high_aioe:junior:post +
               high_aioe:post + junior:post |
               ind_sen + oews_year,
             data = ddd_panel[!is.na(aioe_industry)],
             cluster = ~naics_2d)

cat("\n--- Spec 2a: DDD (ln Emp ~ AIOE × Junior × Post) ---\n")
print(summary(m2a))

cat("\n--- Spec 2c: DDD Binary ---\n")
print(summary(m2c))

saveRDS(list(m2a = m2a, m2b = m2b, m2c = m2c),
        file.path(data_dir, "results_ddd.rds"))

# ===========================================================================
# Analysis 3: QCEW — Quarterly Employment
# ===========================================================================
cat("\n--- Analysis 3: QCEW Quarterly Event Study ---\n")

qcew_3d <- qcew_analysis[naics_len == 3 & !is.na(aioe_industry) & emp > 0]

qcew_3d[, `:=`(
  ln_emp = log(emp),
  high_aioe = as.integer(aioe_industry > median(aioe_industry, na.rm = TRUE))
)]

if ("avg_wage" %in% names(qcew_3d)) {
  qcew_3d[, ln_wage := log(pmax(avg_wage, 1))]
}

# DiD: AIOE × Post
m3a <- feols(ln_emp ~ aioe_industry:post_chatgpt | naics_code + time_idx,
             data = qcew_3d, cluster = ~naics_2d)

# Event study
m3b <- feols(ln_emp ~ aioe_industry:i(time_idx, ref = 32) | naics_code,
             data = qcew_3d, cluster = ~naics_2d)

# Binary
m3c <- feols(ln_emp ~ high_aioe:post_chatgpt | naics_code + time_idx,
             data = qcew_3d, cluster = ~naics_2d)

cat("\n--- Spec 3a: QCEW DiD (ln Emp ~ AIOE × Post) ---\n")
print(summary(m3a))

cat("\n--- Spec 3c: QCEW Binary ---\n")
print(summary(m3c))

# Wage specification
if ("ln_wage" %in% names(qcew_3d)) {
  m3d <- feols(ln_wage ~ aioe_industry:post_chatgpt | naics_code + time_idx,
               data = qcew_3d[is.finite(ln_wage)], cluster = ~naics_2d)
  cat("\n--- Spec 3d: QCEW Wages ---\n")
  print(summary(m3d))
} else {
  m3d <- NULL
}

saveRDS(list(m3a = m3a, m3b = m3b, m3c = m3c, m3d = m3d),
        file.path(data_dir, "results_qcew.rds"))

# ===========================================================================
# Analysis 4: Heterogeneity
# ===========================================================================
cat("\n--- Analysis 4: Heterogeneity ---\n")

het_panel <- oews_ind_ai[!is.na(seniority) & !is.na(ai_exposure)]
het_panel[, `:=`(
  post = as.integer(oews_year >= 2023),
  junior = as.integer(seniority == "Entry-Level"),
  high_ai = as.integer(ai_exposure == "High"),
  cell_id = paste(naics_2d, seniority, ai_exposure, sep = "_"),
  ln_emp = log(total_emp + 1)
)]

m4a <- feols(ln_emp ~ high_ai:junior:post +
               high_ai:post + junior:post |
               cell_id + oews_year,
             data = het_panel, cluster = ~naics_2d)

cat("\n--- Spec 4a: High AI × Junior × Post ---\n")
print(summary(m4a))

saveRDS(list(m4a = m4a), file.path(data_dir, "results_heterogeneity.rds"))

# ===========================================================================
# Summary of all coefficients
# ===========================================================================
cat("\n=== KEY RESULTS SUMMARY ===\n\n")

all_models <- list(
  "1a: Entry Share DiD" = m1a,
  "1c: Entry Share Binary" = m1c,
  "1d: Ln Entry Emp" = m1d,
  "1e: Senior Share" = m1e,
  "2a: DDD Continuous" = m2a,
  "2c: DDD Binary" = m2c,
  "3a: QCEW DiD" = m3a,
  "3c: QCEW Binary" = m3c,
  "4a: Heterogeneity" = m4a
)

for (nm in names(all_models)) {
  m <- all_models[[nm]]
  ct <- coeftable(m)
  cat(sprintf("  %-25s: coef = %8.4f, se = %8.4f, t = %6.2f\n",
              nm, ct[1, 1], ct[1, 2], ct[1, 3]))
}

# Save coefficients table
coef_table <- lapply(names(all_models), function(nm) {
  m <- all_models[[nm]]
  ct <- as.data.table(coeftable(m), keep.rownames = TRUE)
  ct$model <- nm
  ct
})
coef_df <- rbindlist(coef_table, fill = TRUE)
fwrite(coef_df, file.path(data_dir, "all_coefficients.csv"))

cat("\n=== Main analysis complete ===\n")
