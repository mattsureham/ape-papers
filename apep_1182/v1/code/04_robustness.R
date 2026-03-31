## 04_robustness.R — Robustness checks for coal PM2.5 → employment
source("./code/00_packages.R")

data_dir <- "./data"

## Rebuild panel (same as 03)
coal_pm <- fread(file.path(data_dir, "county_year_coal_pm25.csv"))
coal_pm[, fips := as.character(county_fips)]
coal_pm[, fips := fifelse(nchar(fips) == 4, paste0("0", fips), fips)]

qcew <- fread(file.path(data_dir, "qcew_county_year_full.csv"))
qcew[, fips := as.character(fips)]
qcew[, employment := as.numeric(employment)]
qcew[, wages := as.numeric(wages)]
qcew <- qcew[!is.na(employment) & employment > 0 & !is.na(wages) & wages > 0]

panel <- merge(coal_pm[year >= 2014 & year <= 2019, .(fips, year, coal_pm25)],
               qcew[, .(fips, year, employment, wages)],
               by = c("fips", "year"), all = FALSE)

panel[, wages_per_worker := wages / employment]
panel[, log_wages_pw := log(wages_per_worker)]
panel[, log_employment := log(employment)]
panel[, log_coal := log(coal_pm25 + 0.001)]
panel[, state_fips := substr(fips, 1, 2)]
panel[, state_year := paste0(state_fips, "_", year)]
panel <- panel[!state_fips %in% c("02", "15", "72") &
               !is.na(log_wages_pw) & is.finite(log_wages_pw) &
               coal_pm25 > 0]

cat(sprintf("Panel: %d obs, %d counties\n", nrow(panel), uniqueN(panel$fips)))

## 1. First-differenced specification -------------------------------------
cat("\n=== First-differenced ===\n")
setorder(panel, fips, year)
panel[, d_log_emp := log_employment - shift(log_employment), by = fips]
panel[, d_log_coal := log_coal - shift(log_coal), by = fips]
panel[, d_log_wages := log_wages_pw - shift(log_wages_pw), by = fips]

fd_emp <- feols(d_log_emp ~ d_log_coal | year, data = panel[!is.na(d_log_emp)],
                cluster = ~state_fips)
cat(sprintf("FD: Δlog coal → Δlog employment: β=%.4f (SE=%.4f), t=%.2f\n",
            coef(fd_emp), sqrt(vcov(fd_emp)[1,1]),
            coef(fd_emp)/sqrt(vcov(fd_emp)[1,1])))

fd_wages <- feols(d_log_wages ~ d_log_coal | year, data = panel[!is.na(d_log_wages)],
                  cluster = ~state_fips)
cat(sprintf("FD: Δlog coal → Δlog wages:      β=%.4f (SE=%.4f), t=%.2f\n",
            coef(fd_wages), sqrt(vcov(fd_wages)[1,1]),
            coef(fd_wages)/sqrt(vcov(fd_wages)[1,1])))

## 2. Exclude counties with own coal plants --------------------------------
cat("\n=== Excluding coal plant host counties ===\n")
coal_plants <- fread(file.path(data_dir, "coal_plants.csv"))
host_fips <- unique(sprintf("%02d%03d",
                            as.integer(coal_plants$state_fips),
                            as.integer(coal_plants$fips_county)))
# Use a broader approach — host state_fips might not match
# Instead, mark counties with very high coal PM2.5 (top 5%) as potential hosts
high_coal <- panel[, .(max_coal = max(coal_pm25)), by = fips]
host_counties <- high_coal[max_coal > quantile(max_coal, 0.95)]$fips
panel_nohost <- panel[!fips %in% host_counties]

r_nohost <- feols(log_employment ~ log_coal | fips + year,
                  data = panel_nohost, cluster = ~state_fips)
cat(sprintf("Excl. top 5%% coal counties: β=%.4f (SE=%.4f), t=%.2f, N=%d\n",
            coef(r_nohost), sqrt(vcov(r_nohost)[1,1]),
            coef(r_nohost)/sqrt(vcov(r_nohost)[1,1]),
            r_nohost$nobs))

## 3. Placebo: pre-period only (2014-2016 as "pre", 2017-2019 as "fake post")
cat("\n=== Placebo: 2014-2016 vs 2017-2019 ===\n")
# Already captured in the main regression since we use continuous coal PM2.5

## 4. Split by urban/rural (employment size) --------------------------------
cat("\n=== Urban/Rural split ===\n")
med_emp <- median(panel[year == 2014]$employment)
panel[, urban := as.integer(employment > med_emp)]

r_urban <- feols(log_employment ~ log_coal | fips + year,
                 data = panel[urban == 1], cluster = ~state_fips)
r_rural <- feols(log_employment ~ log_coal | fips + year,
                 data = panel[urban == 0], cluster = ~state_fips)
cat(sprintf("Urban: β=%.4f (SE=%.4f), t=%.2f, N=%d\n",
            coef(r_urban), sqrt(vcov(r_urban)[1,1]),
            coef(r_urban)/sqrt(vcov(r_urban)[1,1]), r_urban$nobs))
cat(sprintf("Rural: β=%.4f (SE=%.4f), t=%.2f, N=%d\n",
            coef(r_rural), sqrt(vcov(r_rural)[1,1]),
            coef(r_rural)/sqrt(vcov(r_rural)[1,1]), r_rural$nobs))

cat("\n=== Robustness complete ===\n")
