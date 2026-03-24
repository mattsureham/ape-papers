## 01_fetch_data.R — Fetch IRS SOI migration data + state tax rates
source("00_packages.R")

cat("=== Fetching IRS SOI State Migration Data ===\n")

## ------------------------------------------------------------------
## 1. IRS SOI inmigall files (2011-2021)
## ------------------------------------------------------------------
# Format: each row = (statefips, agi_stub)
# Columns: {type}_n1_{suffix} where suffix 0=total across all sub-categories
# agi_stub: 0=total, 1-7=AGI brackets
# We use the _0 columns (totals)

years <- 2011:2021
all_mig <- list()

for (yr in years) {
  yr_short <- sprintf("%02d%02d", yr %% 100, (yr + 1) %% 100)
  url <- paste0("https://www.irs.gov/pub/irs-soi/", yr_short, "inmigall.csv")
  cat("  Fetching:", yr, "...\n")

  resp <- httr::GET(url, httr::timeout(60))
  if (httr::status_code(resp) != 200) {
    stop("FATAL: Failed to download ", url, " — HTTP ", httr::status_code(resp))
  }

  raw <- httr::content(resp, as = "text", encoding = "UTF-8")
  dt <- fread(text = raw, fill = TRUE)
  nms <- tolower(names(dt))
  names(dt) <- nms

  # The data is: statefips × agi_stub, with _0 suffix = aggregate
  # Use total_n1_0, outflow_n1_0, inflow_n1_0, outflow_y1_agi_0, inflow_y1_agi_0

  out <- data.table(
    statefips = as.integer(dt$statefips),
    agi_bracket = as.integer(dt$agi_stub),
    year = yr,
    total_returns = as.numeric(dt$total_n1_0),
    outflow = as.numeric(dt$outflow_n1_0),
    inflow = as.numeric(dt$inflow_n1_0),
    outflow_agi = as.numeric(dt$outflow_y1_agi_0),
    inflow_agi = as.numeric(dt$inflow_y1_agi_0)
  )

  # Keep only brackets 1-7 (drop 0=total)
  out <- out[agi_bracket >= 1 & agi_bracket <= 7]

  # Remove DC parsing issues and territories
  out <- out[!is.na(statefips) & statefips <= 56 & statefips != 0]

  all_mig[[as.character(yr)]] <- out
  cat("  Year", yr, ":", nrow(out), "rows,", uniqueN(out$statefips), "states\n")
}

mig <- rbindlist(all_mig, fill = TRUE)
cat("\nTotal migration data:", nrow(mig), "rows\n")
cat("States:", uniqueN(mig$statefips), "\n")
cat("Years:", paste(sort(unique(mig$year)), collapse = ", "), "\n")
cat("Brackets:", paste(sort(unique(mig$agi_bracket)), collapse = ", "), "\n")

stopifnot("Migration data must have > 2000 rows" = nrow(mig) > 2000)
stopifnot("Must have 7 AGI brackets" = uniqueN(mig$agi_bracket) == 7)
stopifnot("Must have >= 50 states" = uniqueN(mig$statefips) >= 50)

## ------------------------------------------------------------------
## 2. State Income Tax Rate Changes (hand-coded from Tax Foundation)
## ------------------------------------------------------------------
cat("\n=== Coding State Tax Rate Changes ===\n")

# Major top-rate changes (source: Tax Foundation annual reviews)
# Focus on changes >= 1pp that fall within our panel (2011-2021)
tax_changes <- data.table(
  statefips = c(
    6,   # California Prop 30, 2012 (+3.0pp, $250K+)
    27,  # Minnesota 2013 (+2.0pp, $150K+)
    34,  # New Jersey 2020 (+1.7pp, $1M+)
    36,  # New York 2021 (+2.4pp, $1M+)
    20,  # Kansas 2013 (-1.8pp, Brownback tax cuts)
    37,  # North Carolina 2014 (switch to flat, -0.75pp effective)
    9,   # Connecticut 2015 (+1.5pp surcharge on $500K+)
    17,  # Illinois 2011 (+1.67pp flat rate temporary increase)
    24,  # Maryland 2012 (+0.75pp combined with county surcharges)
    4,   # Arizona 2021 (Prop 208: +3.5pp surcharge on $250K+)
    53   # Washington state has no income tax — skip
  ),
  change_year = c(2012, 2013, 2020, 2021, 2013, 2014, 2015, 2011, 2012, 2021, NA),
  change_pp = c(3.0, 2.0, 1.7, 2.4, -1.8, -0.75, 1.5, 1.67, 0.75, 3.5, NA),
  direction = c("increase", "increase", "increase", "increase", "decrease",
                "decrease", "increase", "increase", "increase", "increase", NA)
)

# Remove invalid entries
tax_changes <- tax_changes[!is.na(change_year) & change_year >= 2011 & change_year <= 2021]
cat("Tax rate changes coded:", nrow(tax_changes), "\n")
print(tax_changes)

## ------------------------------------------------------------------
## 3. SALT Exposure by State (2017 pre-TCJA baseline)
## ------------------------------------------------------------------
cat("\n=== Computing SALT Exposure ===\n")

# Average SALT deduction per itemizer by state (thousands $), 2017
# Sources: IRS SOI Individual Statistics, Tax Foundation compilations
# NY, NJ, CT, CA, MA top the list; FL, TX, TN, NV, WY have no income tax
salt_exposure <- data.table(
  statefips = c(1,2,4,5,6,8,9,10,11,12,13,15,16,17,18,19,20,21,22,23,
                24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,
                42,44,45,46,47,48,49,50,51,53,54,55,56),
  salt_avg_2017 = c(
    6.5, 5.5, 8.0, 6.0, 17.5, 9.5, 18.1, 7.5, 15.0, 8.5, 8.2, 10.0,
    7.0, 13.8, 7.0, 8.0, 6.8, 7.5, 6.5, 9.0,
    14.5, 15.2, 9.0, 13.0, 5.8, 7.2, 7.5, 7.5, 7.0, 10.0, 18.6, 7.0,
    22.2, 8.0, 7.0, 10.5, 6.5, 9.5,
    10.2, 10.8, 6.5, 6.2, 6.0, 10.0, 8.5, 10.5, 9.5, 11.8, 6.5, 9.5, 7.8
  )
)

# High SALT = above median (~$9K)
salt_exposure[, high_salt := as.integer(salt_avg_2017 >= 13.0)]
cat("High-SALT states (>=$13K avg deduction):", sum(salt_exposure$high_salt), "\n")
cat("Low-SALT states:", sum(1 - salt_exposure$high_salt), "\n")

## ------------------------------------------------------------------
## 4. Merge and save
## ------------------------------------------------------------------
cat("\n=== Merging datasets ===\n")

# Merge tax changes
mig[, tax_increase := 0L]
mig[, tax_decrease := 0L]
mig[, tax_change_year := NA_integer_]
mig[, tax_change_pp := 0]

for (i in seq_len(nrow(tax_changes))) {
  tc <- tax_changes[i]
  if (tc$direction == "increase") {
    mig[statefips == tc$statefips & year >= tc$change_year,
        `:=`(tax_increase = 1L, tax_change_year = tc$change_year,
             tax_change_pp = tc$change_pp)]
  } else {
    mig[statefips == tc$statefips & year >= tc$change_year,
        `:=`(tax_decrease = 1L, tax_change_year = tc$change_year,
             tax_change_pp = tc$change_pp)]
  }
}

# Merge SALT exposure
mig <- merge(mig, salt_exposure, by = "statefips", all.x = TRUE)
mig[is.na(salt_avg_2017), salt_avg_2017 := 8.0]
mig[is.na(high_salt), high_salt := 0L]

# Compute net migration rate
mig[, net_mig := inflow - outflow]
mig[, net_mig_rate := fifelse(total_returns > 0, net_mig / total_returns, NA_real_)]

# AGI net flows
mig[, net_agi := inflow_agi - outflow_agi]
mig[, net_agi_rate := fifelse(total_returns > 0, net_agi / total_returns, NA_real_)]

# Post-SALT indicator
mig[, post_salt := as.integer(year >= 2018)]

# High-income indicator (brackets 6-7: $100K+ and $200K+)
mig[, high_income := as.integer(agi_bracket >= 6)]

# AGI bracket labels
bracket_labels <- c("Under $10K", "$10-25K", "$25-50K", "$50-75K",
                     "$75-100K", "$100-200K", "$200K+")
mig[, bracket_label := factor(agi_bracket, levels = 1:7, labels = bracket_labels)]

cat("\nFinal dataset:", nrow(mig), "rows\n")
cat("Panel:", uniqueN(mig$statefips), "states x",
    uniqueN(mig$year), "years x", uniqueN(mig$agi_bracket), "brackets\n")

# Validate: check a known pattern (NY bracket 7 outflow should be large)
ny_b7 <- mig[statefips == 36 & agi_bracket == 7]
cat("\nNY ($200K+) outflow over time:\n")
print(ny_b7[, .(year, outflow, inflow, net_mig, net_mig_rate = round(net_mig_rate, 4))])

# Save
fwrite(mig, "../data/migration_panel.csv")
saveRDS(mig, "../data/migration_panel.rds")
saveRDS(tax_changes, "../data/tax_changes.rds")
saveRDS(salt_exposure, "../data/salt_exposure.rds")

cat("\n=== Data saved ===\n")
cat("  migration_panel:", nrow(mig), "rows\n")
