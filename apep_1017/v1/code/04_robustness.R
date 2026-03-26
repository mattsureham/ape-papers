# 04_robustness.R — Robustness checks
# apep_1017: EU Fourth Railway Package and Rail Fares

source("00_packages.R")

cat("=== Loading data ===\n")
df <- readRDS("data/monthly_panel.rds")
results <- readRDS("data/main_results.rds")

# ---- 1. Pre-COVID robustness (early transposers only, Jul 2019 - Feb 2020) ----
cat("\n=== Pre-COVID robustness (early transposers, post-period ends Feb 2020) ===\n")

# Use only early transposers (treatment in 2019) with post-period through Feb 2020
pre_covid <- df[date <= as.Date("2020-02-29")]
pre_covid_early <- pre_covid[cohort == "early"]

# TWFE on early cohort, pre-COVID window
rob_precovid <- feols(log_rail ~ post | geo + ym,
                      data = pre_covid_early, cluster = ~geo)
cat("Pre-COVID early transposers:\n"); print(summary(rob_precovid))

# ---- 2. Exclude countries with pre-existing open access (SE, CZ) ----
cat("\n=== Excluding pre-existing open access (SE, CZ) ===\n")

# Sweden and Czechia already had open rail markets before the directive
rob_no_preopen <- feols(log_rail ~ post | geo + ym,
                        data = df[!geo %in% c("SE", "CZ")], cluster = ~geo)
cat("Excluding SE, CZ:\n"); print(summary(rob_no_preopen))

# ---- 3. Wild cluster bootstrap (small number of clusters) ----
cat("\n=== Wild cluster bootstrap ===\n")

twfe_for_boot <- feols(log_rail ~ post | geo + ym, data = df[!is.na(log_rail)], cluster = ~geo)

boot_result <- tryCatch({
  boottest(twfe_for_boot, param = "post", clustid = "geo",
           B = 9999, type = "webb")
}, error = function(e) {
  cat("Wild bootstrap error:", conditionMessage(e), "\n")
  NULL
})

if (!is.null(boot_result)) {
  cat("Wild cluster bootstrap:\n")
  print(summary(boot_result))
}

# ---- 4. Alternative time windows ----
cat("\n=== Alternative time windows ===\n")

# Short window: 12 months pre/post
df[, rel_month := as.integer(difftime(date, transposition_date, units = "days")) %/% 30]

rob_short <- feols(log_rail ~ post | geo + ym,
                   data = df[abs(rel_month) <= 12 & !is.na(log_rail)], cluster = ~geo)
cat("12-month window:\n"); print(summary(rob_short))

# Long window: full sample
rob_long <- feols(log_rail ~ post | geo + ym,
                  data = df[!is.na(log_rail)], cluster = ~geo)
cat("Full sample:\n"); print(summary(rob_long))

# ---- 5. Control for GDP per capita ----
cat("\n=== Controlling for GDP per capita ===\n")

rob_gdp <- feols(log_rail ~ post + log(gdp_pc) | geo + ym,
                 data = df[!is.na(log_rail) & !is.na(gdp_pc) & gdp_pc > 0], cluster = ~geo)
cat("With GDP control:\n"); print(summary(rob_gdp))

# ---- 6. Levels specification (not logs) ----
cat("\n=== Levels specification ===\n")

rob_levels <- feols(rail_fare ~ post | geo + ym,
                    data = df[!is.na(rail_fare)], cluster = ~geo)
cat("Rail fare levels:\n"); print(summary(rob_levels))

# ---- 7. Save robustness results ----
cat("\n=== Saving robustness results ===\n")

rob_results <- list(
  precovid = rob_precovid,
  no_preopen = rob_no_preopen,
  boot_result = boot_result,
  short_window = rob_short,
  long_window = rob_long,
  gdp_control = rob_gdp,
  levels = rob_levels
)
saveRDS(rob_results, "data/robustness_results.rds")

cat("Robustness checks complete.\n")
