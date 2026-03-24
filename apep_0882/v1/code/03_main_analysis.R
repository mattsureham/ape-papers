## 03_main_analysis.R — Main regressions for apep_0882
## Event study + DiD: Shale exposure × Drug overdose mortality

library(tidyverse)
library(data.table)
library(fixest)
library(jsonlite)

data_dir <- file.path(dirname(getwd()), "data")
tables_dir <- file.path(dirname(getwd()), "tables")
dir.create(tables_dir, showWarnings = FALSE)

panel <- fread(file.path(data_dir, "panel.csv"))
panel[, fips := as.character(fips)]
panel[, state_fips := as.character(state_fips)]

cat("=== Panel Summary ===\n")
cat("Obs:", nrow(panel), "Counties:", uniqueN(panel$fips),
    "Years:", min(panel$year), "-", max(panel$year), "\n")
cat("Oil counties:", uniqueN(panel$fips[panel$has_oil == 1]),
    "Non-oil:", uniqueN(panel$fips[panel$has_oil == 0]), "\n")
cat("High oil:", uniqueN(panel$fips[panel$high_oil == 1]), "\n\n")


cat("=== 1. Event Study: Binary Treatment (has_oil × year) ===\n")

# Reference year: 2004 (last pre-boom year)
es_binary <- feols(
  drug_od_rate ~ i(year, has_oil, ref = 2004) | fips + year,
  data = panel,
  cluster = ~state_fips
)

cat("Event study coefficients (binary):\n")
print(coeftable(es_binary)[, 1:4])


cat("\n=== 2. Event Study: Continuous Treatment (log_estab × year) ===\n")

es_cont <- feols(
  drug_od_rate ~ i(year, log_estab, ref = 2004) | fips + year,
  data = panel,
  cluster = ~state_fips
)

cat("Event study coefficients (continuous):\n")
print(coeftable(es_cont)[, 1:4])


cat("\n=== 3. Event Study: High Oil Counties Only ===\n")

es_high <- feols(
  drug_od_rate ~ i(year, high_oil, ref = 2004) | fips + year,
  data = panel,
  cluster = ~state_fips
)

cat("Event study coefficients (high oil):\n")
print(coeftable(es_high)[, 1:4])


cat("\n=== 4. Period DiD: Boom and Bust Effects ===\n")

# Specification 1: Binary treatment
did_binary <- feols(
  drug_od_rate ~ has_oil_x_boom + has_oil_x_bust | fips + year,
  data = panel,
  cluster = ~state_fips
)

# Specification 2: Continuous treatment (log establishments)
did_cont <- feols(
  drug_od_rate ~ estab_x_boom + estab_x_bust | fips + year,
  data = panel,
  cluster = ~state_fips
)

# Specification 3: High oil × period
panel[, high_x_boom := high_oil * boom]
panel[, high_x_bust := high_oil * bust]
did_high <- feols(
  drug_od_rate ~ high_x_boom + high_x_bust | fips + year,
  data = panel,
  cluster = ~state_fips
)

# Specification 4: Oil share × period
did_share <- feols(
  drug_od_rate ~ oil_x_boom + oil_x_bust | fips + year,
  data = panel,
  cluster = ~state_fips
)

cat("Binary DiD:\n")
print(coeftable(did_binary))
cat("\nContinuous DiD:\n")
print(coeftable(did_cont))
cat("\nHigh Oil DiD:\n")
print(coeftable(did_high))
cat("\nOil Share DiD:\n")
print(coeftable(did_share))


cat("\n=== 5. Asymmetry Test ===\n")

# Test H0: |bust coefficient| = |boom coefficient|
# For binary: bust - boom > 0 means bust effect exceeds boom
for (spec_name in c("Binary", "Continuous", "High Oil")) {
  mod <- switch(spec_name,
    "Binary"     = did_binary,
    "Continuous"  = did_cont,
    "High Oil"   = did_high
  )

  coefs <- coef(mod)
  vcov_mat <- vcov(mod)

  boom_coef <- coefs[1]
  bust_coef <- coefs[2]

  # Wald test: bust - boom = 0
  diff <- bust_coef - boom_coef
  se_diff <- sqrt(vcov_mat[1,1] + vcov_mat[2,2] - 2 * vcov_mat[1,2])
  t_stat <- diff / se_diff
  p_val <- 2 * pt(abs(t_stat), df = Inf, lower.tail = FALSE)

  cat(sprintf("  %s: Boom=%.3f, Bust=%.3f, Diff=%.3f (SE=%.3f), p=%.4f\n",
              spec_name, boom_coef, bust_coef, diff, se_diff, p_val))
}


cat("\n=== 6. Triple-Diff: Oil × Boom/Bust × High Drug OD Baseline ===\n")

# Counties with above-median pre-boom drug OD rate
preboom_rate <- panel[year <= 2004, .(preboom_drug = mean(drug_od_rate, na.rm = TRUE)), by = fips]
med_rate <- median(preboom_rate$preboom_drug, na.rm = TRUE)
preboom_rate[, high_drug := as.integer(preboom_drug >= med_rate)]

panel <- merge(panel, preboom_rate[, .(fips, preboom_drug, high_drug)], by = "fips", all.x = TRUE)

# Triple-diff: oil × period × high baseline drug
panel[, oil_boom_highdrug := has_oil * boom * high_drug]
panel[, oil_bust_highdrug := has_oil * bust * high_drug]
panel[, oil_boom := has_oil * boom]
panel[, oil_bust := has_oil * bust]
panel[, drug_boom := high_drug * boom]
panel[, drug_bust := high_drug * bust]

did_triple <- feols(
  drug_od_rate ~ oil_boom + oil_bust + drug_boom + drug_bust +
    oil_boom_highdrug + oil_bust_highdrug | fips + year,
  data = panel,
  cluster = ~state_fips
)

cat("Triple-diff results:\n")
print(coeftable(did_triple))


cat("\n=== 7. Save Model Objects and Diagnostics ===\n")

# Store key estimates for tables
results <- list(
  es_binary = es_binary,
  es_cont = es_cont,
  es_high = es_high,
  did_binary = did_binary,
  did_cont = did_cont,
  did_high = did_high,
  did_share = did_share,
  did_triple = did_triple
)

saveRDS(results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json for validator
n_treated <- uniqueN(panel$fips[panel$has_oil == 1])
n_pre <- sum(panel$year[1] <= 2004)
n_obs <- nrow(panel)

write_json(
  list(
    n_treated = n_treated,
    n_pre = length(unique(panel$year[panel$year <= 2004])),
    n_obs = n_obs
  ),
  file.path(data_dir, "diagnostics.json"),
  auto_unbox = TRUE
)

cat("  Diagnostics: n_treated =", n_treated, ", n_pre =",
    length(unique(panel$year[panel$year <= 2004])), ", n_obs =", n_obs, "\n")

# Save updated panel
fwrite(panel, file.path(data_dir, "panel.csv"))

cat("\n=== Main analysis complete ===\n")
