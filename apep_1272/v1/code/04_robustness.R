## 04_robustness.R — Robustness checks and falsification
## apep_1272: Breaking the Gauge Barrier
##
## Tests:
## 1. Placebo: districts with no rail at all (should show no effect)
## 2. Dose-response: effect varies with zone's MG intensity
## 3. Economic Census cross-section (firms, employment)
## 4. Alternative outcome: max light (extensive margin)
## 5. Leave-one-zone-out sensitivity

source("00_packages.R")

data_dir <- "../data"
panel <- fread(file.path(data_dir, "analysis_panel.csv"))
ec05 <- fread(file.path(data_dir, "ec05_district.csv"))
ec13 <- fread(file.path(data_dir, "ec13_district.csv"))

# ── 1. Placebo: no-rail districts ──────────────────────────────────────

cat("=== Placebo: No-Rail Districts ===\n")

# Placebo: assign BG-only districts randomized fake treatment years
# drawn from the actual MG treatment-year distribution.
# If the result is driven by conversion, BG-only districts should show no effect.
set.seed(42)
bg_only <- panel[mg_exposed == 0]
mg_years <- c(2001L, 2004L, 2005L, 2006L, 2007L, 2010L)
bg_dists <- unique(bg_only$dist_id)
fake_assign <- data.table(
  dist_id = bg_dists,
  fake_treat = sample(mg_years, length(bg_dists), replace = TRUE)
)
bg_only <- merge(bg_only, fake_assign, by = "dist_id")
bg_only[, placebo_post := fifelse(year >= fake_treat, 1L, 0L)]

if (nrow(bg_only) > 100) {
  m_placebo <- feols(log_light ~ placebo_post | dist_id + year,
                     data = bg_only,
                     cluster = ~pc11_state_id)
  cat("Placebo (BG-only districts, random fake treatment years):\n")
  print(summary(m_placebo))
} else {
  cat("Insufficient BG-only districts for placebo test.\n")
  m_placebo <- NULL
}

# ── 2. Dose-response: MG share intensity ──────────────────────────────

cat("\n=== Dose-Response ===\n")

# Continuous treatment: mg_share × post
panel[, mg_dose_post := mg_share * fifelse(year >= treat_year & treat_year > 0,
                                             1, 0)]
m_dose <- feols(log_light ~ mg_dose_post | dist_id + year,
                data = panel,
                cluster = ~pc11_state_id)
cat("Dose-response (MG share × post):\n")
print(summary(m_dose))

# ── 3. Economic Census cross-section ──────────────────────────────────

cat("\n=== Economic Census Cross-Section ===\n")

# Construct EC change: 2013 vs 2005
# EC variables: count of firms, employment
ec05_vars <- names(ec05)
ec13_vars <- names(ec13)

# Find common variables that look like firm/employment counts
emp05_var <- grep("emp", ec05_vars, value = TRUE)[1]
emp13_var <- grep("emp", ec13_vars, value = TRUE)[1]
count05_var <- grep("count", ec05_vars, value = TRUE)[1]
count13_var <- grep("count", ec13_vars, value = TRUE)[1]

cat("EC05 columns: ", paste(head(ec05_vars, 20), collapse = ", "), "\n")
cat("EC13 columns: ", paste(head(ec13_vars, 20), collapse = ", "), "\n")

# Merge EC data with treatment assignment
districts <- unique(panel[, .(pc11_state_id, pc11_district_id,
                               mg_exposed, mg_share, treat_year)])

# EC05 uses pc01_* IDs, EC13 uses pc11_* IDs
# We can only merge EC13 with our panel (pc11_* IDs); EC05 needs crosswalk
# For simplicity, use EC13 cross-section (post-treatment) and test whether
# MG-exposed districts have different employment levels

ec13_emp <- ec13[, .(pc11_state_id, pc11_district_id, ec13_emp_all)]
ec13_emp <- merge(ec13_emp, districts, by = c("pc11_state_id", "pc11_district_id"))
ec13_emp[, log_emp := log(ec13_emp_all + 1)]

m_ec <- lm(log_emp ~ mg_exposed, data = ec13_emp)
cat("EC13 employment (cross-section), MG-exposed effect:\n")
print(summary(m_ec))

# ── 4. Alternative outcome: max light ─────────────────────────────────

cat("\n=== Alternative Outcome: Max Light ===\n")

panel[, log_max_light := log(max_light + 1)]
m_max <- feols(log_max_light ~ post | dist_id + year,
               data = panel,
               cluster = ~pc11_state_id)
cat("Max light (extensive margin proxy):\n")
print(summary(m_max))

# ── 5. Leave-one-zone-out ─────────────────────────────────────────────

cat("\n=== Leave-One-Zone-Out ===\n")

mg_zones <- c("NWR", "WR", "NER", "NFR", "SR", "SWR")
loo_results <- list()

for (drop_zone in mg_zones) {
  # Exclude districts whose primary MG zone is the dropped zone
  loo_data <- panel[is.na(primary_mg_zone) | primary_mg_zone != drop_zone]
  loo_fit <- feols(log_light ~ post | dist_id + year,
                   data = loo_data,
                   cluster = ~pc11_state_id)
  loo_results[[drop_zone]] <- data.table(
    dropped_zone = drop_zone,
    coef = coef(loo_fit)["post"],
    se = se(loo_fit)["post"]
  )
}
loo_dt <- rbindlist(loo_results)
cat("Leave-one-zone-out results:\n")
print(loo_dt)

# ── Save robustness results ──────────────────────────────────────────

rob_results <- list(
  placebo = m_placebo,
  dose_response = m_dose,
  ec_employment = m_ec,
  max_light = m_max,
  loo = loo_dt
)
saveRDS(rob_results, file.path(data_dir, "robustness_results.rds"))

cat("\nRobustness checks complete.\n")
