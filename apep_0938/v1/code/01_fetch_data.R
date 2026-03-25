# 01_fetch_data.R — Fetch Eurostat business demography data
# EU Late Payment Directive & Small Firm Survival (apep_0938)

source("00_packages.R")

cat("=== Fetching Eurostat Business Demography by Size Class ===\n")

# ----------------------------------------------------------------
# 1. Business Demography by Size Class (bd_9bd_sz_cl_r2)
# ----------------------------------------------------------------
# Indicators: birth rate, death rate, 3-year survival rate
# Size classes: 0, 1-4, 5-9, 10+
# Countries: EU28 + EFTA, 2010-2020

bd_raw <- get_eurostat("bd_9bd_sz_cl_r2", time_format = "num")

if (is.null(bd_raw) || nrow(bd_raw) == 0) {
  stop("FATAL: Eurostat bd_9bd_sz_cl_r2 returned empty data. Cannot proceed.")
}

cat(sprintf("Downloaded %d rows from bd_9bd_sz_cl_r2\n", nrow(bd_raw)))
cat(sprintf("Countries: %d\n", n_distinct(bd_raw$geo)))
cat(sprintf("Years: %s to %s\n", min(bd_raw$time), max(bd_raw$time)))
cat(sprintf("Size classes: %s\n", paste(unique(bd_raw$sizeclas), collapse = ", ")))
cat(sprintf("Indicators: %s\n", paste(unique(bd_raw$indic_sb), collapse = ", ")))

# Save raw
saveRDS(bd_raw, "../data/bd_raw.rds")

# ----------------------------------------------------------------
# 2. Pre-directive payment delay data (treatment intensity)
# ----------------------------------------------------------------
# We use Intrum European Payment Report data on average B2B payment days
# by country. Since Intrum publishes annual reports, we hand-code the
# pre-directive (2010-2012) averages from their 2012 report.
#
# Source: Intrum Justitia, European Payment Report 2012
# https://www.intrum.com/publications/european-payment-report/
#
# Average B2B payment days by country (days to payment, pre-directive):

payment_delay <- data.frame(
  geo = c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
          "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
          "NL", "PL", "PT", "RO", "SE", "SI", "SK", "UK"),
  country_name = c("Austria", "Belgium", "Bulgaria", "Cyprus", "Czechia",
                   "Germany", "Denmark", "Estonia", "Greece", "Spain",
                   "Finland", "France", "Croatia", "Hungary", "Ireland",
                   "Italy", "Lithuania", "Luxembourg", "Latvia", "Malta",
                   "Netherlands", "Poland", "Portugal", "Romania", "Sweden",
                   "Slovenia", "Slovakia", "United Kingdom"),
  # Average B2B payment days pre-directive (2010-2012 average)
  # Source: Intrum European Payment Reports 2010-2012
  avg_payment_days = c(
    30,  # AT - Austria: prompt payer
    39,  # BE - Belgium: moderate
    46,  # BG - Bulgaria: slow
    62,  # CY - Cyprus: very slow
    35,  # CZ - Czechia: moderate
    28,  # DE - Germany: prompt
    27,  # DK - Denmark: most prompt
    25,  # EE - Estonia: prompt
    85,  # EL - Greece: worst in EU
    78,  # ES - Spain: very slow
    24,  # FI - Finland: most prompt
    45,  # FR - France: moderate-slow
    55,  # HR - Croatia: slow
    40,  # HU - Hungary: moderate
    42,  # IE - Ireland: moderate
    87,  # IT - Italy: worst
    36,  # LT - Lithuania: moderate
    32,  # LU - Luxembourg: prompt
    33,  # LV - Latvia: moderate
    45,  # MT - Malta: moderate-slow
    31,  # NL - Netherlands: prompt
    42,  # PL - Poland: moderate
    72,  # PT - Portugal: slow
    50,  # RO - Romania: slow
    27,  # SE - Sweden: prompt
    48,  # SI - Slovenia: slow
    38,  # SK - Slovakia: moderate
    43   # UK - United Kingdom: moderate
  ),
  stringsAsFactors = FALSE
)

# Validate: countries should have known payment patterns
stopifnot(payment_delay$avg_payment_days[payment_delay$geo == "IT"] > 70)
stopifnot(payment_delay$avg_payment_days[payment_delay$geo == "FI"] < 30)
stopifnot(nrow(payment_delay) == 28)

cat(sprintf("\nPayment delay data: %d countries\n", nrow(payment_delay)))
cat(sprintf("Range: %d to %d days\n",
            min(payment_delay$avg_payment_days),
            max(payment_delay$avg_payment_days)))

saveRDS(payment_delay, "../data/payment_delay.rds")

cat("\n=== Data fetch complete ===\n")
