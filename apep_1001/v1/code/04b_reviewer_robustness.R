## 04b_reviewer_robustness.R — Additional checks from reviewer feedback
## Addresses: COVID overlap, built-up area heterogeneity, non-holiday trading Sundays

source("00_packages.R")

cat("=== Reviewer-Requested Robustness ===\n")

# Reload full incidents for built-up area analysis
incidents <- fread("../data/incidents.csv", encoding = "UTF-8")
incidents[, datetime_parsed := as.POSIXct(datetime, format = "%Y-%m-%d %H:%M:%S")]
incidents[, date := as.Date(datetime_parsed)]
incidents[, year := year(date)]
incidents[, month := month(date)]
incidents[, dow := wday(date, week_start = 1)]
incidents[, is_sunday := (dow == 7)]

# Trading Sunday calendar
trading_sundays <- as.Date(c(
  "2020-01-26", "2020-04-05", "2020-04-26", "2020-06-28",
  "2020-08-30", "2020-12-13", "2020-12-20",
  "2021-01-31", "2021-03-28", "2021-04-25", "2021-06-27",
  "2021-08-29", "2021-12-12", "2021-12-19",
  "2022-01-30", "2022-04-10", "2022-04-24", "2022-06-26",
  "2022-08-28", "2022-12-11", "2022-12-18",
  "2023-01-29", "2023-04-02", "2023-04-23", "2023-06-25",
  "2023-08-27", "2023-12-17", "2023-12-24"
))

incidents[, is_trading_sunday := (date %in% trading_sundays)]
incidents[, non_trading := (is_sunday & !is_trading_sunday)]

sundays <- incidents[is_sunday == TRUE]

# ============================================================
# 1. EXCLUDE 2020 (COVID robustness)
# ============================================================
cat("\n--- Excluding 2020 (COVID) ---\n")

sun_no2020 <- sundays[year >= 2021]
daily_no2020 <- sun_no2020[, .(
  accidents = as.numeric(.N)
), by = .(voivodeship, date, year, month)]
daily_no2020[, voivodeship_f := as.factor(voivodeship)]
daily_no2020[, month_f := as.factor(month)]
daily_no2020[, year_f := as.factor(year)]
daily_no2020[, non_trading := as.numeric(!(date %in% trading_sundays))]

m_no2020 <- fepois(accidents ~ non_trading | voivodeship_f + month_f + year_f,
                   data = daily_no2020, vcov = ~voivodeship_f)

cat(sprintf("Excl. 2020: β = %.4f (SE = %.4f), IRR = %.3f, p = %.3f\n",
            coef(m_no2020)["non_trading"], se(m_no2020)["non_trading"],
            exp(coef(m_no2020)["non_trading"]), pvalue(m_no2020)["non_trading"]))

# ============================================================
# 2. BUILT-UP AREA HETEROGENEITY
# ============================================================
cat("\n--- Built-Up Area Heterogeneity ---\n")

# Check built_up_area field
cat(sprintf("Built-up area values: %s\n",
            paste(head(unique(sundays$built_up_area), 5), collapse = ", ")))

sundays[, is_urban := grepl("zabudowany", built_up_area, ignore.case = TRUE)]
cat(sprintf("Urban (built-up) incidents: %d (%.1f%%)\n",
            sum(sundays$is_urban), 100 * mean(sundays$is_urban)))

# Urban pedestrian accidents
ped_urban <- sundays[is_urban == TRUE & grepl("piesz", incident_type, ignore.case = TRUE)]
ped_rural <- sundays[is_urban == FALSE & grepl("piesz", incident_type, ignore.case = TRUE)]

daily_ped_urban <- ped_urban[, .(accidents = as.numeric(.N)),
                              by = .(voivodeship, date, year, month)]
daily_ped_urban[, voivodeship_f := as.factor(voivodeship)]
daily_ped_urban[, month_f := as.factor(month)]
daily_ped_urban[, year_f := as.factor(year)]
daily_ped_urban[, non_trading := as.numeric(!(date %in% trading_sundays))]

daily_ped_rural <- ped_rural[, .(accidents = as.numeric(.N)),
                              by = .(voivodeship, date, year, month)]
daily_ped_rural[, voivodeship_f := as.factor(voivodeship)]
daily_ped_rural[, month_f := as.factor(month)]
daily_ped_rural[, year_f := as.factor(year)]
daily_ped_rural[, non_trading := as.numeric(!(date %in% trading_sundays))]

m_ped_urban <- tryCatch({
  fepois(accidents ~ non_trading | voivodeship_f + month_f + year_f,
         data = daily_ped_urban, vcov = ~voivodeship_f)
}, error = function(e) { cat(sprintf("Urban ped error: %s\n", e$message)); NULL })

m_ped_rural <- tryCatch({
  fepois(accidents ~ non_trading | voivodeship_f + month_f + year_f,
         data = daily_ped_rural, vcov = ~voivodeship_f)
}, error = function(e) { cat(sprintf("Rural ped error: %s\n", e$message)); NULL })

if (!is.null(m_ped_urban)) {
  cat(sprintf("Pedestrian (built-up): β = %.4f (SE = %.4f), IRR = %.3f\n",
              coef(m_ped_urban)["non_trading"], se(m_ped_urban)["non_trading"],
              exp(coef(m_ped_urban)["non_trading"])))
}
if (!is.null(m_ped_rural)) {
  cat(sprintf("Pedestrian (non-built-up): β = %.4f (SE = %.4f), IRR = %.3f\n",
              coef(m_ped_rural)["non_trading"], se(m_ped_rural)["non_trading"],
              exp(coef(m_ped_rural)["non_trading"])))
}

# ============================================================
# 3. NON-HOLIDAY TRADING SUNDAYS ONLY
# ============================================================
cat("\n--- Non-Holiday Trading Sundays Only ---\n")

# Restrict to Jan, Apr, Jun, Aug trading Sundays (not Dec/Easter)
non_holiday_trading <- trading_sundays[month(trading_sundays) %in% c(1, 4, 6, 8)]
cat(sprintf("Non-holiday trading Sundays: %d\n", length(non_holiday_trading)))

# Compare these months only
daily_nohol <- sundays[month %in% c(1, 4, 6, 8), .(
  accidents = as.numeric(.N)
), by = .(voivodeship, date, year, month)]
daily_nohol[, voivodeship_f := as.factor(voivodeship)]
daily_nohol[, month_f := as.factor(month)]
daily_nohol[, year_f := as.factor(year)]
daily_nohol[, non_trading := as.numeric(!(date %in% trading_sundays))]

m_nohol_months <- fepois(accidents ~ non_trading | voivodeship_f + month_f + year_f,
                         data = daily_nohol, vcov = ~voivodeship_f)

cat(sprintf("Non-holiday months only: β = %.4f (SE = %.4f), IRR = %.3f, p = %.3f\n",
            coef(m_nohol_months)["non_trading"], se(m_nohol_months)["non_trading"],
            exp(coef(m_nohol_months)["non_trading"]), pvalue(m_nohol_months)["non_trading"]))

# ============================================================
# Save results
# ============================================================
reviewer_robustness <- list(
  no2020 = m_no2020,
  ped_urban = m_ped_urban,
  ped_rural = m_ped_rural,
  nohol_months = m_nohol_months
)
saveRDS(reviewer_robustness, "../data/reviewer_robustness.rds")

cat("\n=== Reviewer robustness complete ===\n")
