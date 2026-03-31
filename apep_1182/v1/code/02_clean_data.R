## 02_clean_data.R — Build analysis panel: HyADS coal PM2.5 + CDC PM2.5 + QCEW
source("./code/00_packages.R")

data_dir <- "./data"

## 1. HyADS coal PM2.5 (county-year, 1999-2020) ---------------------------
cat("=== Loading HyADS coal PM2.5 ===\n")
coal_pm <- fread(file.path(data_dir, "county_year_coal_pm25.csv"))
coal_pm[, fips := as.character(county_fips)]
coal_pm[, fips := fifelse(nchar(fips) == 4, paste0("0", fips), fips)]
cat(sprintf("  %d obs, %d counties, years %d-%d\n",
            nrow(coal_pm), uniqueN(coal_pm$fips),
            min(coal_pm$year), max(coal_pm$year)))

## 2. CDC PM2.5 (county-year, 2016-2019) ----------------------------------
cat("=== Loading CDC total PM2.5 ===\n")
pm25 <- fread("/tmp/county_year_pm25_2001_2019.csv")
pm25[, fips := sprintf("%02d%03d", as.integer(statefips), as.integer(countyfips))]
pm25[, pm25 := as.numeric(pm25_annual)]
pm25 <- pm25[!is.na(pm25), .(fips, year, pm25)]
cat(sprintf("  %d obs, years %s\n", nrow(pm25), paste(unique(pm25$year), collapse=",")))

## 3. QCEW labor outcomes (county-year, 2016-2019) -----------------------
cat("=== Loading QCEW ===\n")
qcew <- fread(file.path(data_dir, "qcew_county_year.csv"))
qcew[, fips := as.character(fips)]
qcew[, employment := as.numeric(employment)]
qcew[, wages := as.numeric(wages)]
qcew <- qcew[!is.na(employment) & employment > 0 & !is.na(wages) & wages > 0]
cat(sprintf("  %d obs\n", nrow(qcew)))

## 4. Merge ----------------------------------------------------------------
cat("=== Merging ===\n")
# Core merge: coal PM2.5 + total PM2.5 + QCEW (common years: 2016-2019)
panel <- merge(coal_pm[, .(fips, year, coal_pm25)],
               pm25, by = c("fips", "year"), all = FALSE)
panel <- merge(panel, qcew, by = c("fips", "year"), all.x = TRUE)

# Construct outcome variables
panel[, wages_per_worker := wages / employment]
panel[, log_wages_pw := log(wages_per_worker)]
panel[, log_employment := log(employment)]
panel[, state_fips := substr(fips, 1, 2)]
panel[, state_year := paste0(state_fips, "_", year)]

# Filter: valid, contiguous US
panel <- panel[!is.na(log_wages_pw) & is.finite(log_wages_pw) &
               !is.na(coal_pm25) & coal_pm25 > 0 &
               !state_fips %in% c("02", "15", "72")]

cat(sprintf("  Panel: %d obs, %d counties, years %s\n",
            nrow(panel), uniqueN(panel$fips),
            paste(sort(unique(panel$year)), collapse=",")))

## 5. Summary statistics ---------------------------------------------------
cat("\n=== Summary Statistics ===\n")
cat(sprintf("  Total PM2.5 (μg/m³):  mean=%.2f, sd=%.2f\n",
            mean(panel$pm25), sd(panel$pm25)))
cat(sprintf("  Coal PM2.5 (μg/m³):   mean=%.3f, sd=%.3f\n",
            mean(panel$coal_pm25), sd(panel$coal_pm25)))
cat(sprintf("  Wages/worker ($):     mean=%.0f, sd=%.0f\n",
            mean(panel$wages_per_worker), sd(panel$wages_per_worker)))
cat(sprintf("  Employment:           mean=%.0f, median=%.0f\n",
            mean(panel$employment), median(panel$employment)))

# Within-county coal PM2.5 variation
within_sd <- panel[, .(sd_coal = sd(coal_pm25)), by = fips]
cat(sprintf("  Within-county coal PM2.5 SD: %.3f\n", mean(within_sd$sd_coal, na.rm=T)))

## 6. Also build full 1999-2020 coal PM2.5 panel for long first stage -----
# We don't have total PM2.5 for all years, but coal PM2.5 alone is the instrument
cat("\n=== Also: full coal PM2.5 panel (1999-2020) ===\n")
coal_full <- coal_pm[!substr(fips, 1, 2) %in% c("02", "15", "72")]
cat(sprintf("  Full coal panel: %d obs, %d counties, %d years\n",
            nrow(coal_full), uniqueN(coal_full$fips), uniqueN(coal_full$year)))

# Time series: national average coal PM2.5 by year
nat_avg <- coal_full[, .(mean_coal = mean(coal_pm25)), by = year]
cat("\n  National avg coal PM2.5 by year:\n")
for (i in 1:nrow(nat_avg)) {
  cat(sprintf("    %d: %.3f μg/m³\n", nat_avg$year[i], nat_avg$mean_coal[i]))
}

## 7. Save diagnostics and panel -------------------------------------------
diagnostics <- list(
  n_treated = uniqueN(panel$fips),
  n_pre = 0,
  n_obs = nrow(panel)
)
jsonlite::write_json(diagnostics, file.path(data_dir, "diagnostics.json"),
                     auto_unbox = TRUE)

fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\n=== Panel saved ===\n")
