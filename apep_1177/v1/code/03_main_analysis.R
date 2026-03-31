## 03_main_analysis.R — Main IV analysis
## apep_1177: The Conviction Lottery

source("./code/00_packages.R")

dt <- fread("./data/analysis_data.csv")
cat("Loaded", nrow(dt), "cases for analysis\n")

stopifnot("convicted" %in% names(dt))
stopifnot("vara_leniency" %in% names(dt))

## ---- Table 1: Summary Statistics ----
summ <- data.table(
  Variable = c("Convicted (Procedência)", "Pretrial Detention",
               "Case Duration (days)", "N Movements",
               "Vara Leniency (LOO)", "Filing Year"),
  Mean = c(mean(dt$convicted, na.rm = TRUE),
           mean(dt$pretrial_detained, na.rm = TRUE),
           mean(dt$case_duration_days, na.rm = TRUE),
           mean(dt$n_movements, na.rm = TRUE),
           mean(dt$vara_leniency, na.rm = TRUE),
           mean(dt$filing_year, na.rm = TRUE)),
  SD = c(sd(dt$convicted, na.rm = TRUE),
         sd(dt$pretrial_detained, na.rm = TRUE),
         sd(dt$case_duration_days, na.rm = TRUE),
         sd(dt$n_movements, na.rm = TRUE),
         sd(dt$vara_leniency, na.rm = TRUE),
         sd(dt$filing_year, na.rm = TRUE)),
  N = c(sum(!is.na(dt$convicted)),
        sum(!is.na(dt$pretrial_detained)),
        sum(!is.na(dt$case_duration_days)),
        sum(!is.na(dt$n_movements)),
        sum(!is.na(dt$vara_leniency)),
        nrow(dt))
)
summ[, Mean := round(Mean, 3)]
summ[, SD := round(SD, 3)]
cat("\n--- Table 1: Summary Statistics ---\n")
print(summ)

## ---- First Stage: Vara Leniency → Conviction ----
cat("\n--- First Stage ---\n")

# (1) No FE
fs_nfe <- feols(convicted ~ vara_leniency, data = dt,
                cluster = ~vara_codigo)

# (2) Pool × Year FE
fs_fe <- feols(convicted ~ vara_leniency | pool_year, data = dt,
               cluster = ~vara_codigo)

cat("First stage (no FE):\n")
print(summary(fs_nfe))
cat("\nFirst stage (pool × year FE):\n")
print(summary(fs_fe))

## ---- Reduced Form: Vara Leniency → Outcomes ----
cat("\n--- Reduced Form ---\n")

# Conviction (this IS the first stage; show for completeness)
rf_conv <- feols(convicted ~ vara_leniency | pool_year, data = dt,
                 cluster = ~vara_codigo)

# Pretrial detention
rf_detention <- feols(pretrial_detained ~ vara_leniency | pool_year,
                      data = dt, cluster = ~vara_codigo)

# Case duration (log)
dt[, log_duration := log(case_duration_days + 1)]
rf_duration <- feols(log_duration ~ vara_leniency | pool_year,
                     data = dt[!is.na(case_duration_days) & case_duration_days > 0],
                     cluster = ~vara_codigo)

cat("RF: Conviction\n")
print(summary(rf_conv))
cat("\nRF: Pretrial detention\n")
print(summary(rf_detention))
cat("\nRF: Log case duration\n")
print(summary(rf_duration))

## ---- Balance Tests ----
cat("\n--- Balance Tests ---\n")

# Filing month (should be balanced if sorteio is random)
bal_month <- feols(filing_month ~ vara_leniency | pool_year, data = dt,
                   cluster = ~vara_codigo)

# Number of movements (proxy for case complexity — should not predict leniency)
bal_mov <- feols(n_movements ~ vara_leniency | pool_year, data = dt,
                 cluster = ~vara_codigo)

cat("Balance: Filing month\n")
print(summary(bal_month))
cat("\nBalance: N movements (may reflect outcome, not truly pre-determined)\n")
print(summary(bal_mov))

## ---- Save regression objects ----
results <- list(
  first_stage_nfe = fs_nfe,
  first_stage_fe = fs_fe,
  rf_conviction = rf_conv,
  rf_detention = rf_detention,
  rf_duration = rf_duration,
  balance_month = bal_month,
  balance_movements = bal_mov,
  summary_stats = summ
)
saveRDS(results, "./data/regression_results.rds")

## ---- Write key numbers for diagnostics ----
fs_f <- fitstat(fs_fe, "ivf")
cat("\n--- Key Numbers ---\n")
cat("First-stage coefficient:", round(coef(fs_fe)["vara_leniency"], 4), "\n")
cat("N observations:", nobs(fs_fe), "\n")
cat("N varas:", uniqueN(dt$vara_codigo), "\n")
cat("N pools:", uniqueN(dt$comarca_code), "\n")
cat("Mean conviction rate:", round(mean(dt$convicted, na.rm = TRUE), 3), "\n")

# Update diagnostics
diag <- jsonlite::fromJSON("./data/diagnostics.json")
diag$n_treated <- sum(dt$convicted, na.rm = TRUE)
diag$n_obs <- nrow(dt)
diag$n_varas <- uniqueN(dt$vara_codigo)
diag$n_pools <- uniqueN(dt$comarca_code)
diag$conv_rate <- round(mean(dt$convicted, na.rm = TRUE), 4)
diag$fs_coef <- round(coef(fs_fe)["vara_leniency"], 4)
jsonlite::write_json(diag, "./data/diagnostics.json",
                     auto_unbox = TRUE, pretty = TRUE)
