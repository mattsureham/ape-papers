# ============================================================================
# 04_robustness.R — Robustness checks
# Denmark's 2013 Disability Pension Reform (apep_0599)
#
# Inputs:  ../data/panel_benefits.csv, panel_employment.csv,
#          auk01_sex_raw.csv, folk1c_raw.csv, reg_models.rds
# Outputs: ../data/rob_placebo.csv, rob_leave_one_out.csv,
#          rob_ri.csv, rob_alt_bandwidth.csv,
#          rob_sex_het.csv, rob_log_spec.csv
# ============================================================================

source("00_packages.R")

DATA_DIR <- "../data"

cat("=== 04_robustness.R: Robustness checks ===\n")

# ============================================================================
# 0. LOAD DATA
# ============================================================================

cat("\n--- Loading data ---\n")

panel <- fread(file.path(DATA_DIR, "panel_benefits.csv"))
panel_emp <- fread(file.path(DATA_DIR, "panel_employment.csv"))

cat(sprintf("  panel_benefits: %d rows, %d cols\n", nrow(panel), ncol(panel)))
cat(sprintf("  panel_employment: %d rows, %d cols\n", nrow(panel_emp), ncol(panel_emp)))

# Ensure factor types
panel[, treat_group := factor(treat_group,
                              levels = c("High (25-39)", "Moderate (40-49)",
                                         "Control (50-59)"))]
panel[, age_f := as.factor(age)]
panel[, yq_f := as.factor(yq)]
panel[, muni_f := as.factor(municipality)]

# DiD panel: exclude moderate group (40-49)
did_panel <- panel[!is.na(young)]
cat(sprintf("  DiD panel (excl. moderate): %d rows\n", nrow(did_panel)))

# Helper: extract coefficients from fixest model
extract_coefs <- function(model, outcome_name, spec_name = "") {
  ct <- as.data.table(coeftable(model), keep.rownames = "term")
  setnames(ct, c("term", "estimate", "std_error", "t_value", "p_value"))
  ct[, outcome := outcome_name]
  ct[, spec := spec_name]
  ct[, stars := fifelse(p_value < 0.001, "***",
                        fifelse(p_value < 0.01, "**",
                                fifelse(p_value < 0.05, "*",
                                        fifelse(p_value < 0.1, ".", ""))))]
  ct[, ci_lower := estimate - 1.96 * std_error]
  ct[, ci_upper := estimate + 1.96 * std_error]
  ct[, nobs := model$nobs]
  ct
}

# ============================================================================
# 1. PLACEBO TIMING TEST
# ============================================================================

cat("\n--- Section 1: Placebo Timing Test (reform at 2010Q1) ---\n")

# Move reform date to 2010Q1. Restrict data to pre-actual-reform period
# (2008Q1-2012Q4) so the placebo test is clean.
placebo_panel <- copy(did_panel[year <= 2012])
placebo_reform_yq <- 2010 + 0/4  # 2010Q1 = 2010.00
placebo_panel[, post_placebo := as.integer(yq >= placebo_reform_yq)]

# Re-create FE factors for the restricted panel
placebo_panel[, age_f := as.factor(age)]
placebo_panel[, yq_f := as.factor(yq)]

cat(sprintf("  Placebo panel (pre-2013 only): %d rows\n", nrow(placebo_panel)))
cat(sprintf("  Placebo post=1 obs: %d, post=0 obs: %d\n",
            sum(placebo_panel$post_placebo == 1),
            sum(placebo_panel$post_placebo == 0)))

placebo_results <- list()

# Disability pension (rate_fp)
mod_plac_fp <- feols(rate_fp ~ young:post_placebo | age_f + yq_f,
                     data = placebo_panel, cluster = ~municipality)
ct_fp <- extract_coefs(mod_plac_fp, "Disability Pension", "Placebo 2010Q1")
ct_fp <- ct_fp[grepl("young.*post_placebo|post_placebo.*young", term)]
placebo_results[["rate_fp"]] <- ct_fp

cat(sprintf("  DP placebo:  beta = %8.4f (SE = %.4f), p = %.4f %s\n",
            ct_fp$estimate[1], ct_fp$std_error[1], ct_fp$p_value[1], ct_fp$stars[1]))

# Flex jobs (rate_fl) — another pre-existing outcome
mod_plac_fl <- feols(rate_fl ~ young:post_placebo | age_f + yq_f,
                     data = placebo_panel, cluster = ~municipality)
ct_fl <- extract_coefs(mod_plac_fl, "Flex Jobs", "Placebo 2010Q1")
ct_fl <- ct_fl[grepl("young.*post_placebo|post_placebo.*young", term)]
placebo_results[["rate_fl"]] <- ct_fl

cat(sprintf("  FL placebo:  beta = %8.4f (SE = %.4f), p = %.4f %s\n",
            ct_fl$estimate[1], ct_fl$std_error[1], ct_fl$p_value[1], ct_fl$stars[1]))

# Note: Resource Scheme (rate_res) cannot be tested — the program was created by
# the 2013 reform, so all pre-reform values are exactly zero.
cat("  RES placebo: SKIPPED (program did not exist before 2013)\n")

rob_placebo <- rbindlist(placebo_results)
fwrite(rob_placebo, file.path(DATA_DIR, "rob_placebo.csv"))
cat(sprintf("  Saved rob_placebo.csv: %d rows\n", nrow(rob_placebo)))

# ============================================================================
# 2. LEAVE-ONE-MUNICIPALITY-OUT
# ============================================================================

cat("\n--- Section 2: Leave-One-Municipality-Out (DDD on rate_fp) ---\n")

# DDD specification from main analysis
munis <- sort(unique(did_panel$municipality))
n_munis <- length(munis)
cat(sprintf("  Running %d regressions (dropping one municipality each)...\n", n_munis))

loo_results <- data.table(
  dropped_muni = character(n_munis),
  estimate = numeric(n_munis),
  std_error = numeric(n_munis),
  p_value = numeric(n_munis),
  nobs = integer(n_munis)
)

for (m in seq_along(munis)) {
  loo_data <- did_panel[municipality != munis[m]]
  loo_data[, muni_f := droplevels(as.factor(municipality))]

  mod_loo <- tryCatch(
    feols(rate_fp ~ young:post:high_base_dp + young:post +
            young:high_base_dp + post:high_base_dp |
            age_f^muni_f + age_f^yq_f + muni_f^yq_f,
          data = loo_data, cluster = ~municipality),
    error = function(e) NULL
  )

  if (!is.null(mod_loo)) {
    ct <- coeftable(mod_loo)
    triple_row <- grep("young.*post.*high_base_dp", rownames(ct))
    if (length(triple_row) > 0) {
      set(loo_results, m, "dropped_muni", munis[m])
      set(loo_results, m, "estimate", ct[triple_row[1], 1])
      set(loo_results, m, "std_error", ct[triple_row[1], 2])
      set(loo_results, m, "p_value", ct[triple_row[1], 4])
      set(loo_results, m, "nobs", as.integer(mod_loo$nobs))
    }
  }

  if (m %% 20 == 0) cat(sprintf("    ... %d/%d done\n", m, n_munis))
}

# Remove any empty rows (failed models)
loo_results <- loo_results[dropped_muni != ""]

cat(sprintf("  LOO coefficient range: [%.4f, %.4f]\n",
            min(loo_results$estimate), max(loo_results$estimate)))
cat(sprintf("  LOO coefficient mean:  %.4f, SD: %.4f\n",
            mean(loo_results$estimate), sd(loo_results$estimate)))

fwrite(loo_results, file.path(DATA_DIR, "rob_leave_one_out.csv"))
cat(sprintf("  Saved rob_leave_one_out.csv: %d rows\n", nrow(loo_results)))

# ============================================================================
# 3. RANDOMIZATION INFERENCE
# ============================================================================

cat("\n--- Section 3: Randomization Inference (permuting young indicator) ---\n")

set.seed(20130101)
n_perms <- 500

# Run actual model first (DiD on rate_fp)
mod_actual <- feols(rate_fp ~ young:post | age_f + yq_f,
                    data = did_panel, cluster = ~municipality)
ct_actual <- coeftable(mod_actual)
actual_coef <- ct_actual[grep("young.*post|post.*young", rownames(ct_actual))[1], 1]
cat(sprintf("  Actual DiD coefficient (rate_fp): %.4f\n", actual_coef))

# Permutation loop: shuffle the young indicator within each quarter
# (preserving panel structure: each age group gets randomly assigned young/old)
ri_coefs <- numeric(n_perms)

# Pre-compute unique age-group labels and their young assignments
age_young_map <- unique(did_panel[, .(age, young)])
n_ages <- nrow(age_young_map)

cat(sprintf("  Running %d permutations...\n", n_perms))

for (p in seq_len(n_perms)) {
  # Permute the young indicator across age groups
  perm_young <- sample(age_young_map$young)
  perm_map <- data.table(age = age_young_map$age, young_perm = perm_young)

  perm_data <- merge(did_panel, perm_map, by = "age")

  mod_perm <- tryCatch(
    feols(rate_fp ~ young_perm:post | age_f + yq_f,
          data = perm_data, cluster = ~municipality),
    error = function(e) NULL
  )

  if (!is.null(mod_perm)) {
    ct_perm <- coeftable(mod_perm)
    perm_row <- grep("young_perm.*post|post.*young_perm", rownames(ct_perm))
    if (length(perm_row) > 0) {
      ri_coefs[p] <- ct_perm[perm_row[1], 1]
    }
  }

  if (p %% 100 == 0) cat(sprintf("    ... %d/%d done\n", p, n_perms))
}

# RI p-value: share of permuted coefficients at least as extreme as actual
ri_pvalue <- mean(abs(ri_coefs) >= abs(actual_coef))
cat(sprintf("  RI p-value (two-sided): %.4f\n", ri_pvalue))
cat(sprintf("  Permuted coefs: mean = %.4f, SD = %.4f\n",
            mean(ri_coefs), sd(ri_coefs)))

rob_ri <- data.table(
  permutation = c(0, seq_len(n_perms)),
  coefficient = c(actual_coef, ri_coefs),
  is_actual = c(TRUE, rep(FALSE, n_perms)),
  ri_pvalue = ri_pvalue
)

fwrite(rob_ri, file.path(DATA_DIR, "rob_ri.csv"))
cat(sprintf("  Saved rob_ri.csv: %d rows\n", nrow(rob_ri)))

# ============================================================================
# 4. ALTERNATIVE AGE BANDWIDTHS
# ============================================================================

cat("\n--- Section 4: Alternative Age Bandwidths ---\n")

# Narrow: 30-34 vs 50-54
narrow_ages <- c("30-34 years", "50-54 years")
narrow_panel <- panel[age %in% narrow_ages]
narrow_panel[, young_narrow := as.integer(age == "30-34 years")]
narrow_panel[, age_f := droplevels(as.factor(age))]
narrow_panel[, yq_f := as.factor(yq)]

cat(sprintf("  Narrow bandwidth (30-34 vs 50-54): %d rows\n", nrow(narrow_panel)))

# Wide: 25-39 vs 45-59 (include the moderate group in control)
wide_ages <- c("25-29 years", "30-34 years", "35-39 years",
               "45-49 years", "50-54 years", "55-59 years")
wide_panel <- panel[age %in% wide_ages]
wide_panel[, young_wide := as.integer(age %in% c("25-29 years", "30-34 years", "35-39 years"))]
wide_panel[, age_f := droplevels(as.factor(age))]
wide_panel[, yq_f := as.factor(yq)]

cat(sprintf("  Wide bandwidth (25-39 vs 45-59): %d rows\n", nrow(wide_panel)))

bw_results <- list()

# Narrow: rate_fp
mod_narrow_fp <- feols(rate_fp ~ young_narrow:post | age_f + yq_f,
                       data = narrow_panel, cluster = ~municipality)
ct <- extract_coefs(mod_narrow_fp, "Disability Pension", "Narrow (30-34 vs 50-54)")
ct <- ct[grepl("young_narrow.*post|post.*young_narrow", term)]
bw_results[["narrow_fp"]] <- ct

# Narrow: rate_res
mod_narrow_res <- feols(rate_res ~ young_narrow:post | age_f + yq_f,
                        data = narrow_panel, cluster = ~municipality)
ct <- extract_coefs(mod_narrow_res, "Resource Scheme", "Narrow (30-34 vs 50-54)")
ct <- ct[grepl("young_narrow.*post|post.*young_narrow", term)]
bw_results[["narrow_res"]] <- ct

# Wide: rate_fp
mod_wide_fp <- feols(rate_fp ~ young_wide:post | age_f + yq_f,
                     data = wide_panel, cluster = ~municipality)
ct <- extract_coefs(mod_wide_fp, "Disability Pension", "Wide (25-39 vs 45-59)")
ct <- ct[grepl("young_wide.*post|post.*young_wide", term)]
bw_results[["wide_fp"]] <- ct

# Wide: rate_res
mod_wide_res <- feols(rate_res ~ young_wide:post | age_f + yq_f,
                      data = wide_panel, cluster = ~municipality)
ct <- extract_coefs(mod_wide_res, "Resource Scheme", "Wide (25-39 vs 45-59)")
ct <- ct[grepl("young_wide.*post|post.*young_wide", term)]
bw_results[["wide_res"]] <- ct

rob_alt_bw <- rbindlist(bw_results)

cat("\nAlternative bandwidth results:\n")
print(rob_alt_bw[, .(outcome, spec, estimate, std_error, p_value, stars, nobs)])

fwrite(rob_alt_bw, file.path(DATA_DIR, "rob_alt_bandwidth.csv"))
cat(sprintf("  Saved rob_alt_bandwidth.csv: %d rows\n", nrow(rob_alt_bw)))

# ============================================================================
# 5. SEX HETEROGENEITY
# ============================================================================

cat("\n--- Section 5: Sex Heterogeneity ---\n")

# Read raw sex-disaggregated data and clean similarly to 02_clean_data.R
auk01_sex <- fread(file.path(DATA_DIR, "auk01_sex_raw.csv"), encoding = "UTF-8")
cat(sprintf("  Raw sex data: %d rows\n", nrow(auk01_sex)))

# Rename columns
setnames(auk01_sex, c("OMRÅDE", "YDELSESTYPE", "KØN", "ALDER", "TID", "INDHOLD",
                       "benefit_code", "sex_code"),
         c("municipality", "benefit_type_name", "sex_name", "age", "time", "value",
           "benefit_code", "sex_code"))

# Parse time
auk01_sex[, year := as.integer(substr(time, 1, 4))]
auk01_sex[, quarter := as.integer(substr(time, 6, 6))]
auk01_sex[, yq := year + (quarter - 1L) / 4]

# Filter to municipalities (drop aggregates)
aggregate_patterns <- "^(All Denmark|Region |Province |Abroad|Christiansø)"
auk01_sex <- auk01_sex[!grepl(aggregate_patterns, municipality)]

# Create age group categories
age_to_treat <- data.table(
  age = c("25-29 years", "30-34 years", "35-39 years",
          "40-44 years", "45-49 years",
          "50-54 years", "55-59 years"),
  treat_group = c(rep("High (25-39)", 3),
                  rep("Moderate (40-49)", 2),
                  rep("Control (50-59)", 2))
)
age_to_treat[, young := fifelse(treat_group == "High (25-39)", 1L,
                                fifelse(treat_group == "Control (50-59)", 0L, NA_integer_))]

auk01_sex <- merge(auk01_sex, age_to_treat, by = "age", all.x = TRUE)
auk01_sex <- auk01_sex[!is.na(treat_group)]

# Post and event time
auk01_sex[, post := as.integer(year > 2013 | (year == 2013 & quarter >= 1))]
reform_yq <- 2013 + 0/4
auk01_sex[, event_time := as.integer(round((yq - reform_yq) * 4))]

# Ensure numeric value
auk01_sex[, value := as.numeric(value)]

# Load population data (FOLK1C) — need sex-disaggregated population
# FOLK1C has sex column but we need to re-read it for sex-specific population
folk1c <- fread(file.path(DATA_DIR, "folk1c_raw.csv"), encoding = "UTF-8")
setnames(folk1c, c("OMRÅDE", "KØN", "ALDER", "HERKOMST", "TID", "INDHOLD"),
         c("municipality", "sex", "age", "origin", "time", "population"))

folk1c[, year := as.integer(substr(time, 1, 4))]
folk1c[, quarter := as.integer(substr(time, 6, 6))]
folk1c[, yq := year + (quarter - 1L) / 4]
folk1c <- folk1c[!grepl(aggregate_patterns, municipality)]
folk1c <- merge(folk1c, age_to_treat, by = "age", all.x = TRUE)
folk1c <- folk1c[!is.na(treat_group)]
folk1c[, population := as.numeric(population)]

# FOLK1C sex field is "Total" for the main panel — use total population
# for sex-disaggregated rates since we don't have sex-disaggregated population
pop_total <- folk1c[, .(population = sum(population, na.rm = TRUE)),
                    by = .(municipality, age, time, year, quarter)]

# Merge benefits with population
sex_panel <- merge(auk01_sex, pop_total,
                   by = c("municipality", "age", "time", "year", "quarter"),
                   all.x = TRUE)
sex_panel <- sex_panel[!is.na(population) & population > 0]

# Compute rate per 1000 population
sex_panel[, rate_per_1000 := (value / population) * 1000]

# Filter to DiD sample (exclude moderate)
sex_did <- sex_panel[!is.na(young)]

# Create FE factors
sex_did[, age_f := as.factor(age)]
sex_did[, yq_f := as.factor(yq)]
sex_did[, muni_f := as.factor(municipality)]

cat(sprintf("  Sex-disaggregated DiD panel: %d rows\n", nrow(sex_did)))
cat(sprintf("  Sex codes: %s\n", paste(unique(sex_did$sex_code), collapse = ", ")))
cat(sprintf("  Benefit codes: %s\n", paste(unique(sex_did$benefit_code), collapse = ", ")))

sex_results <- list()

for (sx in c("M", "K")) {
  sx_label <- ifelse(sx == "M", "Men", "Women")
  sx_data <- sex_did[sex_code == sx]

  for (bc in c("FP", "FL")) {
    bc_label <- ifelse(bc == "FP", "Disability Pension", "Flex Jobs")
    bc_data <- sx_data[benefit_code == bc]

    if (nrow(bc_data) < 100) {
      cat(sprintf("  Skipping %s x %s: only %d rows\n", sx_label, bc_label, nrow(bc_data)))
      next
    }

    mod_sex <- tryCatch(
      feols(rate_per_1000 ~ young:post | age_f + yq_f,
            data = bc_data, cluster = ~municipality),
      error = function(e) {
        cat(sprintf("  Error in %s x %s: %s\n", sx_label, bc_label, e$message))
        NULL
      }
    )

    if (!is.null(mod_sex)) {
      ct <- extract_coefs(mod_sex, bc_label, sx_label)
      ct <- ct[grepl("young.*post|post.*young", term)]
      ct[, sex := sx_label]
      ct[, benefit := bc]
      sex_results[[paste0(sx, "_", bc)]] <- ct

      cat(sprintf("  %s x %-20s: beta = %8.4f (SE = %.4f), p = %.4f %s\n",
                  sx_label, bc_label, ct$estimate[1], ct$std_error[1],
                  ct$p_value[1], ct$stars[1]))
    }
  }
}

rob_sex <- rbindlist(sex_results)
fwrite(rob_sex, file.path(DATA_DIR, "rob_sex_het.csv"))
cat(sprintf("  Saved rob_sex_het.csv: %d rows\n", nrow(rob_sex)))

# ============================================================================
# 6. LOG SPECIFICATION
# ============================================================================

cat("\n--- Section 6: Log Specification ---\n")

# Use log(rate + 0.1) to handle zeros and address different rate scales
log_panel <- copy(did_panel)
log_panel[, log_rate_fp := log(rate_fp + 0.1)]
log_panel[, log_rate_fl := log(rate_fl + 0.1)]

log_results <- list()

# Log disability pension
mod_log_fp <- feols(log_rate_fp ~ young:post | age_f + yq_f,
                    data = log_panel, cluster = ~municipality)
ct <- extract_coefs(mod_log_fp, "Disability Pension (log)", "Log(rate + 0.1)")
ct <- ct[grepl("young.*post|post.*young", term)]
log_results[["log_fp"]] <- ct

cat(sprintf("  Log DP:   beta = %8.4f (SE = %.4f), p = %.4f %s\n",
            ct$estimate[1], ct$std_error[1], ct$p_value[1], ct$stars[1]))

# Log flex jobs
mod_log_fl <- feols(log_rate_fl ~ young:post | age_f + yq_f,
                    data = log_panel, cluster = ~municipality)
ct <- extract_coefs(mod_log_fl, "Flex Jobs (log)", "Log(rate + 0.1)")
ct <- ct[grepl("young.*post|post.*young", term)]
log_results[["log_fl"]] <- ct

cat(sprintf("  Log Flex: beta = %8.4f (SE = %.4f), p = %.4f %s\n",
            ct$estimate[1], ct$std_error[1], ct$p_value[1], ct$stars[1]))

rob_log <- rbindlist(log_results)
fwrite(rob_log, file.path(DATA_DIR, "rob_log_spec.csv"))
cat(sprintf("  Saved rob_log_spec.csv: %d rows\n", nrow(rob_log)))

# ============================================================================
# 7. SUMMARY OF ALL ROBUSTNESS CHECKS
# ============================================================================

cat("\n============================================================\n")
cat("ROBUSTNESS CHECKS SUMMARY\n")
cat("============================================================\n")

cat("\n1. Placebo Timing Test (reform at 2010Q1, pre-period only):\n")
for (r in seq_len(nrow(rob_placebo))) {
  cat(sprintf("   %-22s: %+8.4f (%.4f) %s\n",
              rob_placebo$outcome[r], rob_placebo$estimate[r],
              rob_placebo$std_error[r], rob_placebo$stars[r]))
}

cat("\n2. Leave-One-Municipality-Out (DDD, rate_fp):\n")
cat(sprintf("   Coefficient range: [%.4f, %.4f]\n",
            min(loo_results$estimate), max(loo_results$estimate)))
cat(sprintf("   Mean: %.4f, SD: %.4f, Median: %.4f\n",
            mean(loo_results$estimate), sd(loo_results$estimate),
            median(loo_results$estimate)))
cat(sprintf("   All same sign: %s\n",
            ifelse(all(loo_results$estimate > 0) | all(loo_results$estimate < 0),
                   "YES", "NO")))

cat("\n3. Randomization Inference (500 permutations, rate_fp):\n")
cat(sprintf("   Actual coefficient: %.4f\n", actual_coef))
cat(sprintf("   RI p-value (two-sided): %.4f\n", ri_pvalue))
cat(sprintf("   Permutation distribution: mean = %.4f, SD = %.4f\n",
            mean(ri_coefs), sd(ri_coefs)))

cat("\n4. Alternative Age Bandwidths:\n")
for (r in seq_len(nrow(rob_alt_bw))) {
  cat(sprintf("   %-15s %-28s: %+8.4f (%.4f) %s\n",
              rob_alt_bw$outcome[r], rob_alt_bw$spec[r],
              rob_alt_bw$estimate[r], rob_alt_bw$std_error[r],
              rob_alt_bw$stars[r]))
}

cat("\n5. Sex Heterogeneity:\n")
if (nrow(rob_sex) > 0) {
  for (r in seq_len(nrow(rob_sex))) {
    cat(sprintf("   %-7s %-22s: %+8.4f (%.4f) %s\n",
                rob_sex$sex[r], rob_sex$outcome[r],
                rob_sex$estimate[r], rob_sex$std_error[r],
                rob_sex$stars[r]))
  }
}

cat("\n6. Log Specification:\n")
for (r in seq_len(nrow(rob_log))) {
  cat(sprintf("   %-28s: %+8.4f (%.4f) %s\n",
              rob_log$outcome[r], rob_log$estimate[r],
              rob_log$std_error[r], rob_log$stars[r]))
}

cat("\n============================================================\n")
cat("04_robustness.R complete.\n")
