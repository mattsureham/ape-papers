## 03_main_analysis.R — Main regressions for apep_0729
## Press subsidies and voter turnout in Norway

source("00_packages.R")

data_dir <- "../data"
df <- fread(file.path(data_dir, "analysis_panel.csv"))

# ============================================================
# 1. SUMMARY STATISTICS
# ============================================================
cat("=== SUMMARY STATISTICS ===\n")

# Overall
cat(sprintf("Total observations: %d\n", nrow(df)))
cat(sprintf("Municipalities: %d (treated=%d, control=%d)\n",
            uniqueN(df$region_code),
            uniqueN(df[treated == TRUE, region_code]),
            uniqueN(df[treated == FALSE, region_code])))

# By election type
cat("\nBy election type:\n")
print(df[, .(
  mean_turnout = round(mean(turnout, na.rm = TRUE), 2),
  sd_turnout = round(sd(turnout, na.rm = TRUE), 2),
  n_obs = .N,
  n_munis = uniqueN(region_code)
), by = election_type])

# By treatment × election type
cat("\nBy treatment × election type:\n")
print(df[, .(
  mean_turnout = round(mean(turnout, na.rm = TRUE), 2),
  sd_turnout = round(sd(turnout, na.rm = TRUE), 2),
  n_obs = .N
), by = .(treated, election_type)])

# Treatment intensity
cat("\nSubsidy intensity among treated:\n")
print(df[treated == TRUE, .(
  mean_subsidy_nok = round(mean(total_subsidy_nok)),
  mean_subsidy_pc = round(mean(subsidy_per_capita), 1),
  mean_circulation = round(mean(total_circulation)),
  mean_pop = round(mean(population_2021))
)])

# Pre-treatment standard deviations for SDE
cat("\nSD(Y) for SDE calculation:\n")
sd_overall <- sd(df$turnout, na.rm = TRUE)
sd_storting <- sd(df[election_type == "storting", turnout], na.rm = TRUE)
sd_local <- sd(df[election_type == "local", turnout], na.rm = TRUE)
cat(sprintf("  Overall: %.3f\n", sd_overall))
cat(sprintf("  Storting: %.3f\n", sd_storting))
cat(sprintf("  Local: %.3f\n", sd_local))

# ============================================================
# 2. MAIN SPECIFICATIONS
# ============================================================
cat("\n=== MAIN REGRESSIONS ===\n")

# Specification 1: Naive OLS
m1 <- feols(turnout ~ treated, data = df, vcov = ~region_code)

# Specification 2: + Year FE
m2 <- feols(turnout ~ treated | year, data = df, vcov = ~region_code)

# Specification 3: + Year FE + County FE
m3 <- feols(turnout ~ treated | year + county_code, data = df, vcov = ~region_code)

# Specification 4: + Year FE + County FE + Population controls
m4 <- feols(turnout ~ treated + log_pop | year + county_code,
            data = df, vcov = ~region_code)

# Specification 5: + Election type interaction
m5 <- feols(turnout ~ treated * i(election_type, ref = "storting") + log_pop |
              year + county_code,
            data = df, vcov = ~region_code)

# Specification 6: County × Year FE (most demanding — within-county variation)
m6 <- feols(turnout ~ treated + log_pop | county_code^year + election_type,
            data = df, vcov = ~region_code)

cat("Model 1 (Naive OLS):\n")
print(summary(m1))
cat("\nModel 4 (Year + County FE + Pop):\n")
print(summary(m4))
cat("\nModel 6 (County×Year FE):\n")
print(summary(m6))

# ============================================================
# 3. SUBSIDY INTENSITY (CONTINUOUS TREATMENT)
# ============================================================
cat("\n=== SUBSIDY INTENSITY ===\n")

# Subsidy per capita (NOK per resident)
m7 <- feols(turnout ~ subsidy_per_capita + log_pop | year + county_code,
            data = df, vcov = ~region_code)

# Subsidy per capita with county×year FE
m8 <- feols(turnout ~ subsidy_per_capita + log_pop | county_code^year + election_type,
            data = df, vcov = ~region_code)

# Log subsidy (+ 1) for elasticity
df[, log_subsidy := log(subsidy_per_capita + 1)]
m9 <- feols(turnout ~ log_subsidy + log_pop | year + county_code,
            data = df, vcov = ~region_code)

cat("Model 7 (Subsidy per capita, Year + County FE):\n")
print(summary(m7))

# ============================================================
# 4. ELECTION TYPE HETEROGENEITY
# ============================================================
cat("\n=== BY ELECTION TYPE ===\n")

# Storting elections only
m_storting <- feols(turnout ~ treated + log_pop | year + county_code,
                    data = df[election_type == "storting"],
                    vcov = ~region_code)

# Local elections only
m_local <- feols(turnout ~ treated + log_pop | year + county_code,
                 data = df[election_type == "local"],
                 vcov = ~region_code)

cat("Storting elections:\n")
cat(sprintf("  Coef: %.3f, SE: %.3f, p: %.3f\n",
            coef(m_storting)["treatedTRUE"],
            sqrt(vcov(m_storting)["treatedTRUE","treatedTRUE"]),
            2 * pnorm(-abs(coef(m_storting)["treatedTRUE"] /
                             sqrt(vcov(m_storting)["treatedTRUE","treatedTRUE"])))))

cat("Local elections:\n")
cat(sprintf("  Coef: %.3f, SE: %.3f, p: %.3f\n",
            coef(m_local)["treatedTRUE"],
            sqrt(vcov(m_local)["treatedTRUE","treatedTRUE"]),
            2 * pnorm(-abs(coef(m_local)["treatedTRUE"] /
                             sqrt(vcov(m_local)["treatedTRUE","treatedTRUE"])))))

# ============================================================
# 5. SAVE RESULTS FOR TABLES
# ============================================================
results <- list(
  m1 = m1, m2 = m2, m3 = m3, m4 = m4, m5 = m5, m6 = m6,
  m7 = m7, m8 = m8, m9 = m9,
  m_storting = m_storting, m_local = m_local,
  sd_overall = sd_overall, sd_storting = sd_storting, sd_local = sd_local
)
saveRDS(results, file.path(data_dir, "main_results.rds"))

# Write diagnostics.json for validation
diagnostics <- list(
  n_treated = uniqueN(df[treated == TRUE, region_code]),
  n_pre = length(unique(df$year[df$year < 2021])),
  n_obs = nrow(df)
)
write_json(diagnostics, file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("\nResults saved.\n")
cat(sprintf("Diagnostics: n_treated=%d, n_pre=%d, n_obs=%d\n",
            diagnostics$n_treated, diagnostics$n_pre, diagnostics$n_obs))
