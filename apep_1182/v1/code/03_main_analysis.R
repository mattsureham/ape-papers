## 03_main_analysis.R — Reduced-form: Coal PM2.5 → Labor market outcomes
## Design: Within-county variation in HyADS coal PM2.5 (2014-2019)
source("./code/00_packages.R")

data_dir <- "./data"

## Load coal PM2.5 (full panel) and QCEW (2014-2019) ----------------------
coal_pm <- fread(file.path(data_dir, "county_year_coal_pm25.csv"))
coal_pm[, fips := as.character(county_fips)]
coal_pm[, fips := fifelse(nchar(fips) == 4, paste0("0", fips), fips)]

# Load QCEW (2014-2019 from API + 2016-2019 from earlier file)
qcew_api <- fread(file.path(data_dir, "qcew_county_year_full.csv"))
qcew_api[, fips := as.character(fips)]
qcew_api[, employment := as.numeric(employment)]
qcew_api[, wages := as.numeric(wages)]
qcew_api <- qcew_api[!is.na(employment) & employment > 0 & !is.na(wages) & wages > 0]

# Merge coal PM2.5 with QCEW
panel <- merge(coal_pm[year >= 2014 & year <= 2019, .(fips, year, coal_pm25)],
               qcew_api[, .(fips, year, employment, wages)],
               by = c("fips", "year"), all = FALSE)

panel[, wages_per_worker := wages / employment]
panel[, log_wages_pw := log(wages_per_worker)]
panel[, log_employment := log(employment)]
panel[, log_coal := log(coal_pm25 + 0.001)]  # add small constant for zeros
panel[, state_fips := substr(fips, 1, 2)]
panel[, state_year := paste0(state_fips, "_", year)]

# Filter contiguous US
panel <- panel[!state_fips %in% c("02", "15", "72") &
               !is.na(log_wages_pw) & is.finite(log_wages_pw) &
               coal_pm25 > 0]

cat(sprintf("=== Analysis Panel: %d obs, %d counties, years %d-%d ===\n",
            nrow(panel), uniqueN(panel$fips),
            min(panel$year), max(panel$year)))

## Within-county variation check -------------------------------------------
within_sd <- panel[, .(sd_coal = sd(coal_pm25), mean_coal = mean(coal_pm25)), by = fips]
cat(sprintf("Within-county coal PM2.5: mean SD=%.4f, mean level=%.4f\n",
            mean(within_sd$sd_coal, na.rm=TRUE),
            mean(within_sd$mean_coal, na.rm=TRUE)))

## =========================================================================
## 1. REDUCED FORM: Coal PM2.5 → Labor outcomes (county + year FE)
## =========================================================================
cat("\n=== REDUCED FORM: County + Year FE ===\n")

# Main: log coal PM2.5 → log wages per worker
rf1 <- feols(log_wages_pw ~ log_coal | fips + year,
             data = panel, cluster = ~state_fips)
cat("Coal PM2.5 → Log wages/worker:\n")
summary(rf1)

# Employment
rf2 <- feols(log_employment ~ log_coal | fips + year,
             data = panel, cluster = ~state_fips)
cat("\nCoal PM2.5 → Log employment:\n")
summary(rf2)

## =========================================================================
## 2. REDUCED FORM with State × Year FE (Codex specification)
## =========================================================================
cat("\n=== REDUCED FORM: County + State×Year FE ===\n")

rf3 <- feols(log_wages_pw ~ log_coal | fips + state_year,
             data = panel, cluster = ~state_fips)
cat("Coal PM2.5 → Log wages/worker (State×Year FE):\n")
summary(rf3)

rf4 <- feols(log_employment ~ log_coal | fips + state_year,
             data = panel, cluster = ~state_fips)
cat("\nCoal PM2.5 → Log employment (State×Year FE):\n")
summary(rf4)

## =========================================================================
## 3. Also run with levels instead of logs
## =========================================================================
cat("\n=== LEVELS SPECIFICATION ===\n")

rf5 <- feols(wages_per_worker ~ coal_pm25 | fips + year,
             data = panel, cluster = ~state_fips)
cat(sprintf("Coal PM2.5 (levels) → Wages/worker: β=%.1f (SE=%.1f), t=%.2f\n",
            coef(rf5), sqrt(vcov(rf5)[1,1]),
            coef(rf5)/sqrt(vcov(rf5)[1,1])))

rf6 <- feols(wages_per_worker ~ coal_pm25 | fips + state_year,
             data = panel, cluster = ~state_fips)
cat(sprintf("Coal PM2.5 (levels, State×Year) → Wages/worker: β=%.1f (SE=%.1f), t=%.2f\n",
            coef(rf6), sqrt(vcov(rf6)[1,1]),
            coef(rf6)/sqrt(vcov(rf6)[1,1])))

## =========================================================================
## 4. Save results
## =========================================================================
results <- list(
  rf_loglog_wages = list(
    coefficient = as.numeric(coef(rf1)),
    se = as.numeric(sqrt(vcov(rf1)[1,1])),
    n_obs = rf1$nobs,
    n_counties = uniqueN(panel$fips)
  ),
  rf_loglog_emp = list(
    coefficient = as.numeric(coef(rf2)),
    se = as.numeric(sqrt(vcov(rf2)[1,1]))
  ),
  rf_sxy_wages = list(
    coefficient = as.numeric(coef(rf3)),
    se = as.numeric(sqrt(vcov(rf3)[1,1]))
  ),
  rf_sxy_emp = list(
    coefficient = as.numeric(coef(rf4)),
    se = as.numeric(sqrt(vcov(rf4)[1,1]))
  ),
  rf_levels_wages = list(
    coefficient = as.numeric(coef(rf5)),
    se = as.numeric(sqrt(vcov(rf5)[1,1]))
  ),
  mean_coal_pm25 = mean(panel$coal_pm25),
  sd_coal_pm25 = sd(panel$coal_pm25),
  mean_wages = mean(panel$wages_per_worker),
  sd_wages = sd(panel$wages_per_worker)
)

jsonlite::write_json(results, file.path(data_dir, "main_results.json"),
                     auto_unbox = TRUE, digits = 8)

# Update diagnostics
diagnostics <- list(
  n_treated = uniqueN(panel$fips),
  n_pre = 6,
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

cat("\n=== Main analysis complete ===\n")
