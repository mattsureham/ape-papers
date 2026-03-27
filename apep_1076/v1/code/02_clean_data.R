## 02_clean_data.R — Clean YRBSS data and merge with treatment panel
## apep_1076: Conversion Therapy Bans and Adolescent Mental Health

source("00_packages.R")

data_dir <- "../data"

# =============================================================================
# 1. Load raw YRBSS data
# =============================================================================

yrbss <- fread(file.path(data_dir, "yrbss_combined.csv"))
cat("Loaded", nrow(yrbss), "observations from YRBSS combined dataset.\n")

# =============================================================================
# 2. Identify state from sitecode
# =============================================================================

# YRBSS sitecodes: check what format they are
cat("\nUnique sitecodes:\n")
print(sort(unique(yrbss$sitecode)))

# sitecodes include state abbreviations (2-letter) and some with suffixes
# In the state SADC files, multi-letter codes like "AZB" and "NYA" are state-level
# data (not district/city). Map these to standard 2-letter abbreviations.
yrbss[, state_abbr := substr(sitecode, 1, 2)]

cat("After mapping sitecodes to state abbreviations:", nrow(yrbss), "observations\n")
cat("Sitecode mapping:\n")
print(unique(yrbss[, .(sitecode, state_abbr)])[order(sitecode)])

# =============================================================================
# 3. Create outcome variables
# =============================================================================

# YRBSS binary QN variables: 1 = yes (at-risk behavior), 2 = no
# Recode to 0/1 where 1 = at-risk behavior
yrbss[, bullied_school := fifelse(qn24 == 1, 1L, fifelse(qn24 == 2, 0L, NA_integer_))]
yrbss[, bullied_electronic := fifelse(qn25 == 1, 1L, fifelse(qn25 == 2, 0L, NA_integer_))]
yrbss[, sad_hopeless := fifelse(qn26 == 1, 1L, fifelse(qn26 == 2, 0L, NA_integer_))]
yrbss[, considered_suicide := fifelse(qn27 == 1, 1L, fifelse(qn27 == 2, 0L, NA_integer_))]
yrbss[, suicide_plan := fifelse(qn28 == 1, 1L, fifelse(qn28 == 2, 0L, NA_integer_))]
yrbss[, suicide_attempt := fifelse(qn29 == 1, 1L, fifelse(qn29 == 2, 0L, NA_integer_))]

cat("\nOutcome prevalence (overall):\n")
cat("  Sad/hopeless:       ", round(mean(yrbss$sad_hopeless, na.rm = TRUE) * 100, 1), "%\n")
cat("  Considered suicide:  ", round(mean(yrbss$considered_suicide, na.rm = TRUE) * 100, 1), "%\n")
cat("  Suicide plan:        ", round(mean(yrbss$suicide_plan, na.rm = TRUE) * 100, 1), "%\n")
cat("  Suicide attempt:     ", round(mean(yrbss$suicide_attempt, na.rm = TRUE) * 100, 1), "%\n")

# =============================================================================
# 4. Create sexual identity indicator
# =============================================================================

# sexid: 1=Heterosexual, 2=Gay/Lesbian, 3=Bisexual, 4=Not sure, 5=Other(*)
# Create LGB indicator (2 or 3) vs Heterosexual (1)
yrbss[, lgb := fifelse(sexid %in% c(2, 3), 1L,
              fifelse(sexid == 1, 0L, NA_integer_))]

# Also create broader sexual minority indicator (2, 3, 4, 5 vs 1)
yrbss[, sexual_minority := fifelse(sexid %in% c(2, 3, 4, 5), 1L,
                           fifelse(sexid == 1, 0L, NA_integer_))]

cat("\nSexual identity distribution (among non-missing):\n")
cat("  Heterosexual:", sum(yrbss$lgb == 0, na.rm = TRUE), "\n")
cat("  LGB:         ", sum(yrbss$lgb == 1, na.rm = TRUE), "\n")
cat("  Missing:     ", sum(is.na(yrbss$lgb)), "\n")

# Check which years have sexual identity data
cat("\nSexual identity availability by year:\n")
si_by_year <- yrbss[, .(n_total = .N, n_sexid = sum(!is.na(sexid)),
                         pct_available = round(sum(!is.na(sexid)) / .N * 100, 1)),
                     by = year][order(year)]
print(si_by_year)

# =============================================================================
# 5. Create demographic controls
# =============================================================================

# Sex: 1=Female, 2=Male
yrbss[, female := fifelse(sex == 1, 1L, 0L)]

# Grade: 1=9th, 2=10th, 3=11th, 4=12th
yrbss[, grade_clean := fifelse(grade %in% 1:4, grade, NA_integer_)]

# Race: 4-category (1=White, 2=Black, 3=Hispanic, 4=Other)
yrbss[, race_clean := fifelse(race4 %in% 1:4, race4, NA_integer_)]

# =============================================================================
# 6. Merge with treatment panel
# =============================================================================

treatment <- fread(file.path(data_dir, "treatment_panel.csv"))

# Merge
yrbss <- merge(yrbss, treatment[, .(state_abbr, ban_year)],
               by = "state_abbr", all.x = TRUE)

# Create treatment indicator: ban effective before or during survey year
yrbss[, treated := fifelse(!is.na(ban_year) & is.finite(ban_year) & year >= ban_year, 1L, 0L)]

# For CS estimator: cohort variable (year of ban adoption; 0 = never treated)
yrbss[, cohort := fifelse(is.finite(ban_year), as.integer(ban_year), 0L)]

cat("\nTreatment status by year:\n")
treat_by_year <- yrbss[, .(n_total = .N, n_treated = sum(treated),
                            pct_treated = round(sum(treated) / .N * 100, 1)),
                        by = year][order(year)]
print(treat_by_year)

# =============================================================================
# 7. Restrict to analysis sample
# =============================================================================

# Keep years 2015-2023 (when sexual identity question is more widely available)
# This gives us 5 biennial waves
analysis <- yrbss[year >= 2015]
cat("\nAnalysis sample (2015-2023):", nrow(analysis), "observations\n")

# Check state coverage in analysis window
cat("\nStates in analysis sample by year:\n")
states_by_year <- analysis[, .(n_states = uniqueN(state_abbr)), by = year]
print(states_by_year)

cat("\nUnique states in analysis sample:", uniqueN(analysis$state_abbr), "\n")
cat("States with bans in sample:", uniqueN(analysis[treated == 1, state_abbr]), "\n")
cat("Never-treated states in sample:", uniqueN(analysis[cohort == 0, state_abbr]), "\n")

# DDD subsample: observations with non-missing sexual identity
ddd_sample <- analysis[!is.na(lgb)]
cat("\nDDD subsample (non-missing sexual identity):", nrow(ddd_sample), "observations\n")
cat("  LGB:", sum(ddd_sample$lgb == 1), "(", round(mean(ddd_sample$lgb) * 100, 1), "%)\n")
cat("  Heterosexual:", sum(ddd_sample$lgb == 0), "\n")

# Outcome prevalence by LGB status
cat("\nOutcome prevalence by sexual identity (DDD sample):\n")
prev <- ddd_sample[, .(
  sad_hopeless = round(mean(sad_hopeless, na.rm = TRUE) * 100, 1),
  considered_suicide = round(mean(considered_suicide, na.rm = TRUE) * 100, 1),
  suicide_plan = round(mean(suicide_plan, na.rm = TRUE) * 100, 1),
  suicide_attempt = round(mean(suicide_attempt, na.rm = TRUE) * 100, 1)
), by = lgb]
print(prev)

# Save analysis datasets
fwrite(analysis, file.path(data_dir, "analysis_sample.csv"))
fwrite(ddd_sample, file.path(data_dir, "ddd_sample.csv"))

cat("\n=== Cleaning complete ===\n")
cat("Analysis sample:", nrow(analysis), "obs across", uniqueN(analysis$state_abbr), "states\n")
cat("DDD sample:", nrow(ddd_sample), "obs with sexual identity data\n")
