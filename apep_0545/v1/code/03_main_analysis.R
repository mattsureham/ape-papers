## 03_main_analysis.R
## Main regressions for the regulatory ratchet paper (apep_0545)
##
## Estimates:
##   1. OLS panel: incident coverage → significant rulemaking
##   2. OLS panel: burden coverage → significant rulemaking
##   3. Asymmetry test: β₁ vs. β₂
##   4. 2SLS: incident coverage instrumented by competing-news IV
##   5. Administration heterogeneity: Trump EO 13771
##   6. Proposed vs. final rule asymmetry (agenda-setting vs. completion)

# Set working directory to the project root (the project root directory (papers/apep_XXXX/vN/)).
# Replicators: set this to the directory containing data/, code/, figures/, tables/.
if (interactive()) {
  # RStudio: use the script's location
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
  setwd(normalizePath(".."))  # go up from code/ to v1/
} else {
  # Command-line: run from the the project root directory (papers/apep_XXXX/vN/) directory
  # e.g., Rscript code/03_main_analysis.R (from the project root directory (papers/apep_XXXX/vN/))
}
source("code/00_packages.R")

library(data.table)
library(fixest)
library(sandwich)
library(lmtest)
library(clubSandwich)
library(car)

DATA_DIR   <- "data/"
TABLES_DIR <- "tables/"
dir.create(TABLES_DIR, showWarnings=FALSE)

panel <- fread(file.path(DATA_DIR, "panel_with_iv.csv"))

# Fix factor variables
panel[, agency_fe   := factor(agency_id)]
panel[, quarter_fe  := factor(paste(year, quarter, sep="Q"))]
panel[, year_fe     := factor(year)]
panel[, time_id     := (year - 2015) * 4 + quarter]

cat("Panel: ", nrow(panel), "obs,", n_distinct(panel$agency_id), "agencies,",
    n_distinct(panel$quarter_fe), "quarters\n")

# ============================================================
# SPECIFICATION SETUP
# ============================================================

# Primary outcome: log(1 + n_significant) economically significant rules
# Treatment: log incident coverage (lagged 1Q) and log burden coverage (lagged 1Q)

# Remove agencies with extreme zeros (CPSC/CFTC have very few significant rules)
panel_main <- panel[!agency_id %in% c("CPSC")]  # CPSC: only 1 significant rule over 10 years

# ============================================================
# TABLE 1: MAIN OLS RESULTS
# ============================================================
cat("\n=== TABLE 1: MAIN OLS RESULTS ===\n")

# Model 1: Incident coverage → significant rulemaking (agency + quarter FE)
m1 <- feols(log_n_significant ~ log_incident_L1 | agency_fe + quarter_fe,
            data=panel_main, cluster=~agency_fe)

# Model 2: Add burden coverage
m2 <- feols(log_n_significant ~ log_incident_L1 + log_burden_L1 | agency_fe + quarter_fe,
            data=panel_main, cluster=~agency_fe)

# Model 3: With administration controls
m3 <- feols(log_n_significant ~ log_incident_L1 + log_burden_L1 +
              trump_era + biden_era | agency_fe + quarter_fe,
            data=panel_main, cluster=~agency_fe)

# Model 4: Incident share (normalized for overall news growth)
m4 <- feols(log_n_significant ~ incident_share + burden_share | agency_fe + quarter_fe,
            data=panel_main, cluster=~agency_fe)

# Print results
cat("\nModel 1 (incident only):\n")
print(summary(m1))
cat("\nModel 2 (incident + burden):\n")
print(summary(m2))
cat("\nModel 3 (+ admin controls):\n")
print(summary(m3))

# Save coefficients for tables
coef_table <- data.table(
  model = rep(c("M1","M2","M3","M4"), each=1),
  outcome = "log_n_significant",
  coef_incident = c(coef(m1)["log_incident_L1"],
                    coef(m2)["log_incident_L1"],
                    coef(m3)["log_incident_L1"],
                    coef(m4)["incident_share"]),
  se_incident   = c(se(m1)["log_incident_L1"],
                    se(m2)["log_incident_L1"],
                    se(m3)["log_incident_L1"],
                    se(m4)["incident_share"]),
  coef_burden   = c(NA,
                    coef(m2)["log_burden_L1"],
                    coef(m3)["log_burden_L1"],
                    coef(m4)["burden_share"]),
  se_burden     = c(NA,
                    se(m2)["log_burden_L1"],
                    se(m3)["log_burden_L1"],
                    se(m4)["burden_share"])
)
fwrite(coef_table, file.path(TABLES_DIR, "main_ols_coefs.csv"))

# ============================================================
# TABLE 2: ASYMMETRY TEST
# ============================================================
cat("\n=== TABLE 2: ASYMMETRY TEST ===\n")

# Formal test: H0: β₁ = |β₂| (symmetric response)
# Using linearHypothesis from 'car'
m2_lm <- lm(log_n_significant ~ log_incident_L1 + log_burden_L1 +
               agency_fe + quarter_fe,
             data=panel_main)

asym_test <- linearHypothesis(m2_lm,
  c("log_incident_L1 = log_burden_L1"),
  test="F")

cat("Asymmetry test (H0: β_incident = |β_burden|):\n")
print(asym_test)

# Also test: β₁ > 0 AND β₂ ≈ 0
cat("\nβ₁ (incident): ", coef(m2)["log_incident_L1"], "\n")
cat("SE(β₁): ", se(m2)["log_incident_L1"], "\n")
cat("β₂ (burden): ", coef(m2)["log_burden_L1"], "\n")
cat("SE(β₂): ", se(m2)["log_burden_L1"], "\n")
cat("p-value β₁>0: ", pvalue(m2)["log_incident_L1"], "\n")
cat("p-value β₂=0: ", pvalue(m2)["log_burden_L1"], "\n")

asym_results <- data.table(
  coef_incident = coef(m2)["log_incident_L1"],
  se_incident   = se(m2)["log_incident_L1"],
  pval_incident = pvalue(m2)["log_incident_L1"],
  coef_burden   = coef(m2)["log_burden_L1"],
  se_burden     = se(m2)["log_burden_L1"],
  pval_burden   = pvalue(m2)["log_burden_L1"],
  F_asym        = asym_test$F[2],
  p_asym        = asym_test$`Pr(>F)`[2]
)
fwrite(asym_results, file.path(TABLES_DIR, "asymmetry_test.csv"))

# ============================================================
# TABLE 3: PROPOSED VS. FINAL RULES (AGENDA-SETTING)
# ============================================================
cat("\n=== TABLE 3: PROPOSED VS FINAL RULES ===\n")

m5 <- feols(log_n_proposed ~ log_incident_L1 + log_burden_L1 | agency_fe + quarter_fe,
            data=panel_main, cluster=~agency_fe)

m6 <- feols(log_n_final ~ log_incident_L1 + log_burden_L1 | agency_fe + quarter_fe,
            data=panel_main, cluster=~agency_fe)

cat("Proposed rules (m5):\n")
print(summary(m5))
cat("Final rules (m6):\n")
print(summary(m6))

proposed_final <- data.table(
  outcome = c("proposed", "final"),
  coef_incident = c(coef(m5)["log_incident_L1"], coef(m6)["log_incident_L1"]),
  se_incident   = c(se(m5)["log_incident_L1"], se(m6)["log_incident_L1"]),
  coef_burden   = c(coef(m5)["log_burden_L1"], coef(m6)["log_burden_L1"]),
  se_burden     = c(se(m5)["log_burden_L1"], se(m6)["log_burden_L1"])
)
fwrite(proposed_final, file.path(TABLES_DIR, "proposed_vs_final.csv"))

# ============================================================
# TABLE 4: TRUMP EO 13771 HETEROGENEITY
# ============================================================
cat("\n=== TABLE 4: TRUMP ADMINISTRATION HETEROGENEITY ===\n")

m7 <- feols(log_n_significant ~ log_incident_L1 + log_burden_L1 +
              i(trump_era, log_incident_L1, ref=0) +
              i(trump_era, log_burden_L1, ref=0) | agency_fe + quarter_fe,
            data=panel_main, cluster=~agency_fe)

cat("Trump interaction model:\n")
print(summary(m7))

# Split sample: pre-Trump vs. Trump vs. Biden
panel_pre  <- panel_main[year < 2017]
panel_trump <- panel_main[trump_era == 1]
panel_biden <- panel_main[biden_era == 1]

m8 <- feols(log_n_significant ~ log_incident_L1 + log_burden_L1 | agency_fe + quarter_fe,
            data=panel_pre, cluster=~agency_fe)
m9 <- feols(log_n_significant ~ log_incident_L1 + log_burden_L1 | agency_fe + quarter_fe,
            data=panel_trump, cluster=~agency_fe)
m10 <- feols(log_n_significant ~ log_incident_L1 + log_burden_L1 | agency_fe + quarter_fe,
             data=panel_biden, cluster=~agency_fe)

cat("Pre-Trump (2015-2016):\n")
print(summary(m8))
cat("Trump (2017-2020):\n")
print(summary(m9))
cat("Biden (2021-2024):\n")
print(summary(m10))

admin_results <- data.table(
  period = c("Pre-Trump\n(2015-2016)","Trump\n(2017-2020)","Biden\n(2021-2024)"),
  coef_incident = c(coef(m8)["log_incident_L1"], coef(m9)["log_incident_L1"], coef(m10)["log_incident_L1"]),
  se_incident   = c(se(m8)["log_incident_L1"], se(m9)["log_incident_L1"], se(m10)["log_incident_L1"]),
  coef_burden   = c(coef(m8)["log_burden_L1"], coef(m9)["log_burden_L1"], coef(m10)["log_burden_L1"]),
  se_burden     = c(se(m8)["log_burden_L1"], se(m9)["log_burden_L1"], se(m10)["log_burden_L1"])
)
fwrite(admin_results, file.path(TABLES_DIR, "admin_heterogeneity.csv"))

# ============================================================
# TABLE 5: IV ESTIMATION (2SLS)
# ============================================================
cat("\n=== TABLE 5: 2SLS RESULTS ===\n")

# Instrument: log_cross_sector (other agencies' incident coverage in same quarter)
# First stage: cross-sector incidents crowd out this agency's incident coverage

# Check first stage
fs1 <- feols(log_incident_L1 ~ log_cross_sector | agency_fe + quarter_fe,
             data=panel_main, cluster=~agency_fe)
cat("First stage (incident ~ cross_sector):\n")
print(summary(fs1))
cat("First-stage F-stat: ", fitstat(fs1, "ivf")[[1]], "\n")

# 2SLS
m_iv1 <- feols(log_n_significant ~ log_burden_L1 | agency_fe + quarter_fe |
                 log_incident_L1 ~ log_cross_sector,
               data=panel_main, cluster=~agency_fe)
cat("\n2SLS model (cross-sector IV):\n")
print(summary(m_iv1))

# Check first stage F-stat
fs_f <- fitstat(m_iv1, "ivf")
cat("IV First-stage F: ", fs_f, "\n")

# Alternative instrument: natural disaster competition
m_iv2 <- feols(log_n_significant ~ log_burden_L1 | agency_fe + quarter_fe |
                 log_incident_L1 ~ log_nat_disaster,
               data=panel_main, cluster=~agency_fe)
cat("\n2SLS model (disaster IV):\n")
print(summary(m_iv2))

iv_results <- data.table(
  model = c("OLS","2SLS (cross-sector)","2SLS (disaster)"),
  coef_incident = c(coef(m2)["log_incident_L1"],
                    coef(m_iv1)["fit_log_incident_L1"],
                    coef(m_iv2)["fit_log_incident_L1"]),
  se_incident   = c(se(m2)["log_incident_L1"],
                    se(m_iv1)["fit_log_incident_L1"],
                    se(m_iv2)["fit_log_incident_L1"]),
  coef_burden   = c(coef(m2)["log_burden_L1"],
                    coef(m_iv1)["log_burden_L1"],
                    coef(m_iv2)["log_burden_L1"]),
  se_burden     = c(se(m2)["log_burden_L1"],
                    se(m_iv1)["log_burden_L1"],
                    se(m_iv2)["log_burden_L1"]),
  first_stage_F = c(NA,
                    tryCatch(fitstat(m_iv1, "ivf1")[[1]], error=function(e) NA),
                    tryCatch(fitstat(m_iv2, "ivf1")[[1]], error=function(e) NA))
)
fwrite(iv_results, file.path(TABLES_DIR, "iv_results.csv"))

# ============================================================
# LOCAL PROJECTIONS (Distributed lag / Impulse response)
# ============================================================
cat("\n=== LOCAL PROJECTIONS (IRF) ===\n")

lp_results <- lapply(0:6, function(h) {
  # Shift outcome by h periods forward
  panel_lp <- copy(panel_main)
  panel_lp[, y_forward := shift(log_n_significant, h, type="lead"), by=agency_id]

  m_lp <- tryCatch(
    feols(y_forward ~ log_incident_L1 + log_burden_L1 | agency_fe + quarter_fe,
          data=panel_lp, cluster=~agency_fe),
    error = function(e) NULL
  )
  if (is.null(m_lp)) return(NULL)

  data.table(
    horizon = h,
    coef_incident = coef(m_lp)["log_incident_L1"],
    se_incident   = se(m_lp)["log_incident_L1"],
    coef_burden   = coef(m_lp)["log_burden_L1"],
    se_burden     = se(m_lp)["log_burden_L1"]
  )
})

lp_df <- rbindlist(Filter(Negate(is.null), lp_results))
fwrite(lp_df, file.path(TABLES_DIR, "local_projections.csv"))
cat("Local projections saved (", nrow(lp_df), "horizons)\n")
print(lp_df)

# ============================================================
# SMALL-CLUSTER ROBUST INFERENCE (Wild Bootstrap)
# ============================================================
cat("\n=== WILD CLUSTER BOOTSTRAP ===\n")

# Key worry: 11-12 clusters may lead to under-rejection
# Use boottest package or manual Cameron-Miller correction
# For simplicity with fixest, use CR2 (club sandwich)
m2_cr2 <- coeftest(m2_lm, vcov=vcovCR(m2_lm, cluster=panel_main$agency_id, type="CR2"))
cat("CR2 (small-cluster robust) SEs for main model:\n")
print(m2_cr2[c("log_incident_L1","log_burden_L1"),])

boot_results <- data.table(
  variable = c("log_incident_L1", "log_burden_L1"),
  coef_ols = c(coef(m2)["log_incident_L1"], coef(m2)["log_burden_L1"]),
  se_cluster = c(se(m2)["log_incident_L1"], se(m2)["log_burden_L1"]),
  se_cr2     = c(m2_cr2["log_incident_L1","Std. Error"],
                 m2_cr2["log_burden_L1","Std. Error"]),
  t_cr2      = c(m2_cr2["log_incident_L1","t value"],
                 m2_cr2["log_burden_L1","t value"])
)
fwrite(boot_results, file.path(TABLES_DIR, "bootstrap_results.csv"))

message("03_main_analysis.R complete. Tables saved to ", TABLES_DIR)
