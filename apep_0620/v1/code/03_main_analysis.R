# 03_main_analysis.R — Main regressions
# apep_0620: Second-generation refugee dispersal outcomes in Denmark

source("00_packages.R")

analysis <- readRDS("../data/analysis_cross_section.rds")
panel <- readRDS("../data/analysis_panel.rds")
historical <- readRDS("../data/analysis_historical.rds")

cat("=== Main Analysis ===\n")
cat(sprintf("Cross-section: %d municipalities\n", nrow(analysis)))

# ─────────────────────────────────────────────────────────────────────────────
# 1. Main specification: Employment rate
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Employment Regressions ---\n")

# (1) Bivariate OLS
m1_emp <- feols(emp_rate_desc ~ imm_share_2008, data = analysis,
  vcov = "hetero")

# (2) + log population control
m2_emp <- feols(emp_rate_desc ~ imm_share_2008 + log_pop, data = analysis,
  vcov = "hetero")

# (3) + total employment rate control
m3_emp <- feols(emp_rate_desc ~ imm_share_2008 + log_pop + total_emp_rate,
  data = analysis, vcov = "hetero")

# (4) + region FE
m4_emp <- feols(emp_rate_desc ~ imm_share_2008 + log_pop + total_emp_rate | region,
  data = analysis, vcov = "hetero")

cat("Employment results:\n")
etable(m1_emp, m2_emp, m3_emp, m4_emp,
  keep = "imm_share",
  headers = c("(1)", "(2)", "(3)", "(4)"))

# ─────────────────────────────────────────────────────────────────────────────
# 2. Main specification: Education (tertiary share)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Education Regressions ---\n")

# (1) Bivariate
m1_edu <- feols(share_tertiary ~ imm_share_2008, data = analysis,
  vcov = "hetero")

# (2) + controls
m2_edu <- feols(share_tertiary ~ imm_share_2008 + log_pop, data = analysis,
  vcov = "hetero")

# (3) + total employment
m3_edu <- feols(share_tertiary ~ imm_share_2008 + log_pop + total_emp_rate,
  data = analysis, vcov = "hetero")

# (4) + region FE
m4_edu <- feols(share_tertiary ~ imm_share_2008 + log_pop + total_emp_rate | region,
  data = analysis, vcov = "hetero")

cat("Education results:\n")
etable(m1_edu, m2_edu, m3_edu, m4_edu,
  keep = "imm_share",
  headers = c("(1)", "(2)", "(3)", "(4)"))

# ─────────────────────────────────────────────────────────────────────────────
# 3. Employment gap (vs Danish origin) — key mechanism outcome
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Employment Gap Regressions ---\n")

# (1) Bivariate
m1_gap <- feols(emp_gap ~ imm_share_2008, data = analysis,
  vcov = "hetero")

# (2) + controls
m2_gap <- feols(emp_gap ~ imm_share_2008 + log_pop, data = analysis,
  vcov = "hetero")

# (3) + region FE
m3_gap <- feols(emp_gap ~ imm_share_2008 + log_pop | region, data = analysis,
  vcov = "hetero")

cat("Employment gap results:\n")
etable(m1_gap, m2_gap, m3_gap,
  keep = "imm_share",
  headers = c("(1)", "(2)", "(3)"))

# ─────────────────────────────────────────────────────────────────────────────
# 4. Primary-only education (low education share)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Low Education Regressions ---\n")

m1_prim <- feols(share_primary ~ imm_share_2008, data = analysis,
  vcov = "hetero")

m2_prim <- feols(share_primary ~ imm_share_2008 + log_pop + total_emp_rate | region,
  data = analysis, vcov = "hetero")

cat("Primary education results:\n")
etable(m1_prim, m2_prim, keep = "imm_share")

# ─────────────────────────────────────────────────────────────────────────────
# 5. Panel analysis: employment over time
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Panel: Employment Trends ---\n")

# Ensure numeric types
panel$emp_rate_desc <- as.numeric(panel$emp_rate_desc)
panel$year <- as.numeric(panel$year)
panel$log_pop <- log(panel$total_pop)

# Create interaction: treatment × year (to see if gaps widen or narrow)
panel_model <- feols(emp_rate_desc ~ imm_share_2008:i(year, ref = 2008) +
  log_pop | year,
  data = panel %>% filter(!is.na(emp_rate_desc)),
  vcov = ~muni)

cat("Panel interaction results:\n")
summary(panel_model)

# ─────────────────────────────────────────────────────────────────────────────
# 6. Pre-dispersal balance check (BEF3 historical data)
# ─────────────────────────────────────────────────────────────────────────────
cat("\n--- Pre-Dispersal Balance Check ---\n")

# Check if 1980-1985 immigrant share predicts 2008 treatment
hist_1985 <- historical %>%
  filter(year == 1985) %>%
  select(muni, imm_share_1985 = imm_share, imm_share_2008)

hist_1980 <- historical %>%
  filter(year == 1980) %>%
  select(muni, imm_share_1980 = imm_share)

balance <- hist_1985 %>%
  left_join(hist_1980, by = "muni") %>%
  mutate(imm_change_80_85 = imm_share_1985 - imm_share_1980)

cat(sprintf("  Balance check sample: %d municipalities\n", nrow(balance)))

# Pre-dispersal level should NOT strongly predict post-dispersal treatment
bal_test <- lm(imm_share_2008 ~ imm_share_1985, data = balance)
cat("\n  Pre-dispersal (1985) → Treatment (2008):\n")
cat(sprintf("    Coefficient: %.4f (SE: %.4f, p = %.4f)\n",
  coef(bal_test)[2], sqrt(vcov(bal_test)[2, 2]),
  summary(bal_test)$coefficients[2, 4]))
cat(sprintf("    R-squared: %.3f\n", summary(bal_test)$r.squared))

# Pre-dispersal CHANGE should be orthogonal to treatment
bal_test2 <- lm(imm_share_2008 ~ imm_change_80_85, data = balance)
cat("\n  Pre-dispersal change (1980-85) → Treatment (2008):\n")
cat(sprintf("    Coefficient: %.4f (SE: %.4f, p = %.4f)\n",
  coef(bal_test2)[2], sqrt(vcov(bal_test2)[2, 2]),
  summary(bal_test2)$coefficients[2, 4]))
cat(sprintf("    R-squared: %.3f\n", summary(bal_test2)$r.squared))

# ─────────────────────────────────────────────────────────────────────────────
# Save diagnostics
# ─────────────────────────────────────────────────────────────────────────────
n_treated <- sum(analysis$imm_share_2008 > median(analysis$imm_share_2008))
n_pre <- length(unique(historical$year[historical$year < 1986]))

diag <- list(
  n_treated = n_treated,
  n_pre = n_pre,
  n_obs = nrow(analysis),
  n_municipalities = nrow(analysis),
  n_panel_obs = nrow(panel),
  mean_treatment = mean(analysis$imm_share_2008),
  sd_treatment = sd(analysis$imm_share_2008),
  mean_emp_rate = mean(analysis$emp_rate_desc, na.rm = TRUE),
  sd_emp_rate = sd(analysis$emp_rate_desc, na.rm = TRUE),
  mean_edu_tertiary = mean(analysis$share_tertiary, na.rm = TRUE),
  sd_edu_tertiary = sd(analysis$share_tertiary, na.rm = TRUE)
)
jsonlite::write_json(diag, "../data/diagnostics.json", auto_unbox = TRUE, pretty = TRUE)

# Save model objects for table generation
saveRDS(list(
  emp = list(m1 = m1_emp, m2 = m2_emp, m3 = m3_emp, m4 = m4_emp),
  edu = list(m1 = m1_edu, m2 = m2_edu, m3 = m3_edu, m4 = m4_edu),
  gap = list(m1 = m1_gap, m2 = m2_gap, m3 = m3_gap),
  primary = list(m1 = m1_prim, m2 = m2_prim),
  panel = panel_model,
  balance = list(level = bal_test, change = bal_test2)
), "../data/model_objects.rds")

cat("\n=== Analysis complete. Models saved. ===\n")
