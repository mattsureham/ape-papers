# 02_clean_data.R — Build bilateral panel from BIS LBS data
# APEP Paper apep_1292: Sunshine Through the Alps

source("00_packages.R")

data_dir <- "../data"

# ============================================================
# 1. Load BIS Liechtenstein data and AEOI dates
# ============================================================
bis_li <- fread(file.path(data_dir, "bis_lbs_li.csv"))
aeoi_dates <- fread(file.path(data_dir, "aeoi_treatment_dates.csv"))

cat("BIS LI rows:", nrow(bis_li), "\n")
cat("Unique reporting countries:", uniqueN(bis_li$L_REP_CTY), "\n")

# ============================================================
# 2. Filter for key series: stocks, all instruments, all currencies
# ============================================================
bis_stocks <- bis_li[L_MEASURE == "S"]
bis_filt <- bis_stocks[L_INSTR == "A"]
bis_filt <- bis_filt[L_DENOM == "TO1"]
bis_filt <- bis_filt[L_POS_TYPE == "N"]

# Keep BOTH claims (C) and liabilities (L)
cat("\nPositions available:\n")
print(bis_filt[, .N, by = .(L_POSITION, `Balance sheet position`)])

# Individual reporter countries only
bis_filt <- bis_filt[nchar(L_REP_CTY) == 2 & L_REP_CTY != "5A"]

# All sectors (A) for main analysis
bis_filt <- bis_filt[L_CP_SECTOR == "A"]
cat("Individual countries, all sectors:", nrow(bis_filt), "\n")

# ============================================================
# 3. Reshape wide to long
# ============================================================
qtr_cols <- grep("^[0-9]{4}-Q[1-4]$", names(bis_filt), value = TRUE)
cat("\nQuarter columns:", length(qtr_cols), "\n")

id_cols <- c("L_REP_CTY", "Reporting country", "L_POSITION",
             "Balance sheet position")

panel_long <- melt(
  bis_filt,
  id.vars = id_cols,
  measure.vars = qtr_cols,
  variable.name = "quarter",
  value.name = "value_usd",
  variable.factor = FALSE
)

panel_long[, quarter := as.character(quarter)]
panel_long[, year := as.integer(substr(quarter, 1, 4))]
panel_long[, qtr_num := as.integer(substr(quarter, 7, 7))]
panel_long[, time_num := year + (qtr_num - 1) / 4]

# Drop missing values
panel_long <- panel_long[!is.na(value_usd)]
cat("Non-missing observations:", format(nrow(panel_long), big.mark = ","), "\n")

# ============================================================
# 4. Merge AEOI treatment dates
# ============================================================
aeoi_dates[, aeoi_year := as.integer(substr(aeoi_quarter, 1, 4))]
aeoi_dates[, aeoi_qtr := as.integer(substr(aeoi_quarter, 7, 7))]
aeoi_dates[, aeoi_time := aeoi_year + (aeoi_qtr - 1) / 4]

panel <- merge(
  panel_long,
  aeoi_dates[, .(country_code, aeoi_quarter, aeoi_group, aeoi_time,
                 aeoi_year, aeoi_qtr)],
  by.x = "L_REP_CTY",
  by.y = "country_code",
  all.x = TRUE
)

# Drop countries without AEOI dates (not in CRS network)
panel <- panel[!is.na(aeoi_time)]
panel[is.na(aeoi_group), aeoi_group := "never_treated"]

cat("\nCountries by treatment group and position:\n")
coverage <- panel[, .(n_obs = .N,
                      min_q = min(quarter),
                      max_q = max(quarter)),
                  by = .(L_REP_CTY, `Reporting country`, aeoi_group, L_POSITION)]
print(coverage[order(aeoi_group, L_POSITION, -n_obs)])

# ============================================================
# 5. Restrict to 2010-2023
# ============================================================
panel <- panel[year >= 2010 & year <= 2023]

# Drop negative values (BIS adjustments)
cat("\nNegative values:", sum(panel$value_usd < 0, na.rm = TRUE), "\n")
panel <- panel[value_usd >= 0 | is.na(value_usd)]

# Log outcome
panel[, log_position := log(value_usd + 1)]

# Treatment variable
panel[, treated := as.integer(!is.na(aeoi_time) & time_num >= aeoi_time)]

# Time period (integer)
panel[, time_period := as.integer((year - 2000) * 4 + qtr_num)]

# Event time
panel[, event_time := ifelse(is.na(aeoi_time), NA_integer_,
                              as.integer(round((time_num - aeoi_time) * 4)))]

# Sun-Abraham cohort
panel[, first_treat_sa := fcase(
  aeoi_group %in% c("EU_2017", "CRS_2017"), 71L,
  aeoi_group == "CRS_2018", 75L,
  aeoi_group == "CRS_2020", 83L,
  default = 10000L
)]

# ============================================================
# 6. Filter for countries with sufficient coverage PER POSITION
# ============================================================
# Need >= 4 pre and >= 4 post quarters for at least one position type
sufficiency <- panel[, .(
  n_pre = sum(treated == 0),
  n_post = sum(treated == 1),
  n_total = .N
), by = .(L_REP_CTY, L_POSITION)]

# A country is included if it has sufficient data for at least one position
good_ctry_pos <- sufficiency[n_pre >= 4 & n_post >= 4]
cat("\nCountry-position pairs with sufficient data:\n")
print(good_ctry_pos[order(L_POSITION, -n_total)])

# Keep only good country-position pairs
panel_main <- merge(panel, good_ctry_pos[, .(L_REP_CTY, L_POSITION)],
                    by = c("L_REP_CTY", "L_POSITION"))

# Unit ID: country × position
panel_main[, unit_id := paste0(L_REP_CTY, "_", L_POSITION)]
panel_main[, country_id := as.integer(factor(L_REP_CTY))]
panel_main[, is_claims := as.integer(L_POSITION == "C")]

cat("\n=== Final Main Panel ===\n")
cat("Observations:", nrow(panel_main), "\n")
cat("Unique countries:", uniqueN(panel_main$L_REP_CTY), "\n")
cat("Country-position pairs:", uniqueN(panel_main$unit_id), "\n")
cat("Claims pairs:", uniqueN(panel_main[L_POSITION == "C"]$L_REP_CTY), "\n")
cat("Liabilities pairs:", uniqueN(panel_main[L_POSITION == "L"]$L_REP_CTY), "\n")
cat("Treated observations:", sum(panel_main$treated), "\n")
cat("Control observations:", sum(panel_main$treated == 0), "\n")

# Country-level summary
cat("\nCountry panel summary:\n")
summ <- panel_main[, .(
  n_obs = .N,
  n_pre = sum(treated == 0),
  n_post = sum(treated == 1),
  positions = paste(sort(unique(L_POSITION)), collapse = "+"),
  mean_value = mean(value_usd, na.rm = TRUE),
  sd_value = sd(value_usd, na.rm = TRUE),
  aeoi_group = first(aeoi_group)
), by = .(L_REP_CTY, `Reporting country`)]
print(summ[order(aeoi_group, -n_obs)])

# ============================================================
# 7. Also save claims-only panel for comparison
# ============================================================
panel_claims <- panel_main[L_POSITION == "C"]
cat("\nClaims-only panel:", nrow(panel_claims), "obs,",
    uniqueN(panel_claims$L_REP_CTY), "countries\n")

# ============================================================
# 8. Save datasets
# ============================================================
fwrite(panel_main, file.path(data_dir, "panel_main.csv"))
fwrite(panel_claims, file.path(data_dir, "panel_claims.csv"))

# Save country list for reference
fwrite(summ, file.path(data_dir, "country_summary.csv"))

# Also keep full panel for sector-level robustness
panel_all_sect <- panel_long[year >= 2010 & year <= 2023]
fwrite(panel_all_sect, file.path(data_dir, "panel_all_positions.csv"))

cat("\n=== Data cleaning complete ===\n")
