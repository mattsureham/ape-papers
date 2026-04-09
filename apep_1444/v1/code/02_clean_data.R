# 02_clean_data.R — Construct analysis sample for Ecuador pension RDD
source("00_packages.R")

df <- as.data.table(readRDS("../data/enemdu_raw_stacked.rds"))
cat(sprintf("Raw data: %s observations\n", format(nrow(df), big.mark = ",")))

# --- Variable construction ---

# Age: p03 (integer years)
df[, age := as.integer(p03)]

# Running variable: centered at 65
df[, age_c := age - 65L]

# Treatment: age >= 65
df[, above65 := as.integer(age >= 65)]

# Sex: p02 (1=male, 2=female)
df[, female := as.integer(p02 == 2)]

# Area: 1=urban, 2=rural
df[, urban := as.integer(area == 1)]

# Labor force participation: condact 1-3 = economically active
df[, lfp := as.integer(condact %in% c(1, 2, 3))]

# Employment: condact 1 = employed (adequate), 2 = underemployed
df[, employed := as.integer(condact %in% c(1, 2))]

# Hours worked (conditional on working; 0 for non-workers)
df[, hours := fifelse(is.na(p42) | p42 < 0, 0, as.numeric(p42))]
df[condact %in% c(4:9), hours := 0]

# Government transfer receipt: p72a (1=yes, 2=no)
df[, receives_transfer := as.integer(p72a == 1)]

# Transfer amount: p72b (in USD)
df[, transfer_amount := fifelse(is.na(p72b) | p72b < 0, 0, as.numeric(p72b))]

# Labor income
df[, labor_income := fifelse(is.na(ingrl) | ingrl < 0, 0, as.numeric(ingrl))]

# Per capita income (for poverty proxy)
df[, pc_income := as.numeric(ingpc)]

# Social security affiliation: p24 codes — complex, but key is "no affiliation"
# p24=40 appears to be "ninguno" (none) — the largest category for elderly
df[, no_social_security := as.integer(p24 == 40)]

# Education: p10a (years of schooling or level)
df[, education := as.numeric(p10a)]

# Household size variable if available
hh_vars <- grep("^nmiemb|^p01|^tamhog", names(df), value = TRUE, ignore.case = TRUE)
if (length(hh_vars) > 0) {
  df[, hh_size := as.numeric(get(hh_vars[1]))]
} else {
  df[, hh_size := NA_real_]
}

# --- Sample restrictions ---
# Keep ages 55-75 (±10 years around cutoff)
df_rdd <- df[age >= 55 & age <= 75]
cat(sprintf("After age 55-75 restriction: %s\n", format(nrow(df_rdd), big.mark = ",")))

# Drop if age is missing
df_rdd <- df_rdd[!is.na(age)]

# Keep key variables only
keep_vars <- c("age", "age_c", "above65", "female", "urban", "lfp", "employed",
               "hours", "receives_transfer", "transfer_amount", "labor_income",
               "pc_income", "no_social_security", "education", "hh_size",
               "year", "quarter", "yq")
df_rdd <- df_rdd[, ..keep_vars]

cat(sprintf("Analysis sample: %s observations\n", format(nrow(df_rdd), big.mark = ",")))
cat(sprintf("Ages: %d to %d\n", min(df_rdd$age), max(df_rdd$age)))
cat(sprintf("Quarters: %s\n", paste(sort(unique(df_rdd$yq)), collapse = ", ")))

# --- Summary statistics by age group ---
cat("\n=== Key outcomes by age group ===\n")
summary_tab <- df_rdd[, .(
  N = .N,
  LFP = mean(lfp, na.rm = TRUE),
  Employed = mean(employed, na.rm = TRUE),
  Hours = mean(hours, na.rm = TRUE),
  Transfer_rate = mean(receives_transfer, na.rm = TRUE),
  Transfer_amt = mean(transfer_amount, na.rm = TRUE),
  Labor_inc = mean(labor_income, na.rm = TRUE)
), by = age]
setorder(summary_tab, age)
print(summary_tab)

# --- Poverty subsample (bottom quintile of per capita income) ---
# Use full sample's income distribution for the cutoff
pov_cutoff <- quantile(df_rdd$pc_income, 0.40, na.rm = TRUE)
cat(sprintf("\nPoverty cutoff (40th percentile of pc_income): %.1f\n", pov_cutoff))
df_rdd[, poor := as.integer(pc_income <= pov_cutoff)]
cat(sprintf("Poor subsample: %s (%0.1f%%)\n",
            format(sum(df_rdd$poor, na.rm=TRUE), big.mark=","),
            100 * mean(df_rdd$poor, na.rm=TRUE)))

# Save analysis dataset
saveRDS(df_rdd, "../data/analysis_sample.rds")
cat(sprintf("\nSaved analysis sample: ../data/analysis_sample.rds\n"))
