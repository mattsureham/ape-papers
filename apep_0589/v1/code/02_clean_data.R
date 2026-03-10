## ============================================================
## 02_clean_data.R — Construct analysis panel
## ERDF Treatment Withdrawal RDD
## ============================================================

source("00_packages.R")

data_dir <- "../data/"

cat("=== CLEANING DATA ===\n\n")

## ---------------------------------------------------------
## 1. Load raw data
## ---------------------------------------------------------
gdp_pct  <- fread(paste0(data_dir, "gdp_pct_eu27.csv"))  # tgs00006 (2013+)
gdp_eur  <- fread(paste0(data_dir, "gdp_eur.csv"))        # nama_10r_2gdp
emp_rate <- fread(paste0(data_dir, "emp_rate.csv"))
gva      <- fread(paste0(data_dir, "gva_sector.csv"))
coe      <- fread(paste0(data_dir, "compensation.csv"))
pop      <- fread(paste0(data_dir, "population.csv"))
erdf     <- fread(paste0(data_dir, "erdf_payments.csv"))

## ---------------------------------------------------------
## 2. Build the full GDP per capita panel (2000-2024)
## ---------------------------------------------------------
cat("Building GDP per capita panel from nama_10r_2gdp...\n")

# nama_10r_2gdp has PPS_HAB_EU27_2020 = PPS per inhabitant as % of EU27
# This goes back to 2000, unlike tgs00006 which starts at 2013
gdp_full_raw <- get_eurostat("nama_10r_2gdp", time_format = "num")
gdp_full_raw <- as.data.table(gdp_full_raw)
if ("TIME_PERIOD" %in% names(gdp_full_raw)) setnames(gdp_full_raw, "TIME_PERIOD", "time")

# PPS per inhabitant as % of EU27 average — this is the running variable
gdp_full <- gdp_full_raw[nchar(geo) == 4 & unit == "PPS_HAB_EU27_2020"]
gdp_full <- gdp_full[, .(geo, time, values)]

cat("  Full GDP panel:", nrow(gdp_full), "obs,",
    uniqueN(gdp_full$geo), "regions,",
    paste(range(gdp_full$time, na.rm = TRUE), collapse = "-"), "\n")

fwrite(gdp_full, paste0(data_dir, "gdp_pps_full.csv"))

## ---------------------------------------------------------
## 3. Construct running variable
## ---------------------------------------------------------
cat("\nConstructing running variable...\n")

# For 2014-2020 period, eligibility was based on ~2008-2010 averages
# (Regulation 1303/2013 used 2008-2010 GDP data)
gdp_rv <- gdp_full[time %in% 2008:2010,
  .(running_var = mean(values, na.rm = TRUE)),
  by = .(geo)]

# For 2007-2013 period, based on ~2002-2004
gdp_rv_prev <- gdp_full[time %in% 2002:2004,
  .(running_var_0713 = mean(values, na.rm = TRUE)),
  by = .(geo)]

rv <- merge(gdp_rv, gdp_rv_prev, by = "geo", all = TRUE)

cat("Running variable computed for", nrow(rv), "NUTS2 regions\n")
cat("  Near threshold (65-85%):", sum(rv$running_var >= 65 & rv$running_var <= 85, na.rm = TRUE), "\n")

## ---------------------------------------------------------
## 4. Classify regions
## ---------------------------------------------------------
rv[, `:=`(
  category_2014 = fcase(
    running_var < 75,  "less_developed",
    running_var >= 75 & running_var < 90, "transition",
    running_var >= 90, "more_developed",
    default = NA_character_
  ),
  category_0713 = fcase(
    running_var_0713 < 75,  "convergence",
    running_var_0713 >= 75, "competitiveness",
    default = NA_character_
  ),
  graduated = as.integer(running_var >= 75),
  rv_centered = running_var - 75
)]

# Key: regions below 75% in 2007-2013 but above in 2014-2020
rv[, graduated_from_convergence := as.integer(
  running_var_0713 < 75 & running_var >= 75
)]

cat("\nCategory distribution (2014-2020):\n")
print(rv[!is.na(category_2014), .N, by = category_2014][order(category_2014)])

cat("\nGraduation status:\n")
print(rv[!is.na(graduated_from_convergence),
  .N, by = .(below_75_0713 = running_var_0713 < 75,
             above_75_1420 = running_var >= 75)])

n_graduated <- rv[graduated_from_convergence == 1, .N]
cat("Regions graduating from Convergence:", n_graduated, "\n")

## ---------------------------------------------------------
## 5. ERDF intensity by region and period
## ---------------------------------------------------------
cat("\nConstructing ERDF intensity...\n")

erdf_clean <- erdf[!is.na(nuts2_id) & nuts2_id != ""]

# Identify programming periods
erdf_clean[, period := fcase(
  grepl("2007|07.13", programming_period), "2007_2013",
  grepl("2014|14.20", programming_period), "2014_2020",
  grepl("2000|00.06", programming_period), "2000_2006",
  default = "other"
)]

erdf_by_period <- erdf_clean[period %in% c("2007_2013", "2014_2020"), .(
  erdf_total = sum(eu_payment_annual, na.rm = TRUE)
), by = .(nuts2_id, period)]

erdf_wide <- dcast(erdf_by_period, nuts2_id ~ period,
  value.var = "erdf_total", fill = 0)
setnames(erdf_wide, c("nuts2_id", "erdf_0713", "erdf_1420"))

# Population for per-capita
pop_avg <- pop[time %in% 2010:2013,
  .(pop_avg = mean(values, na.rm = TRUE)),
  by = .(geo)]

erdf_wide <- merge(erdf_wide, pop_avg, by.x = "nuts2_id", by.y = "geo", all.x = TRUE)
erdf_wide[, `:=`(
  erdf_0713_pc = erdf_0713 / pop_avg * 1e6,
  erdf_1420_pc = erdf_1420 / pop_avg * 1e6,
  delta_erdf_pc = (erdf_1420 - erdf_0713) / pop_avg * 1e6
)]

rv <- merge(rv, erdf_wide[, .(nuts2_id, erdf_0713_pc, erdf_1420_pc, delta_erdf_pc, pop_avg)],
  by.x = "geo", by.y = "nuts2_id", all.x = TRUE)

cat("ERDF merged for", sum(!is.na(rv$erdf_0713_pc)), "regions\n")

## ---------------------------------------------------------
## 6. Outcome variables
## ---------------------------------------------------------
cat("\nConstructing outcomes...\n")

# GDP growth: pre (2007-2013) vs post (2014-2020)
gdp_growth <- gdp_full[, .(
  gdp_pct_pre = mean(values[time %in% 2007:2013], na.rm = TRUE),
  gdp_pct_post = mean(values[time %in% 2014:2020], na.rm = TRUE),
  gdp_pct_2007 = values[time == 2007][1],
  gdp_pct_2013 = values[time == 2013][1],
  gdp_pct_2019 = values[time == 2019][1],
  gdp_pct_2020 = values[time == 2020][1]
), by = .(geo)]
gdp_growth[, delta_gdp := gdp_pct_post - gdp_pct_pre]

# Employment
emp_panel <- emp_rate[, .(
  emp_pre = mean(values[time %in% 2007:2013], na.rm = TRUE),
  emp_post = mean(values[time %in% 2014:2020], na.rm = TRUE)
), by = .(geo)]
emp_panel[, delta_emp := emp_post - emp_pre]

# Manufacturing GVA share
gva_mfg <- gva[nace_r2 == "C",
  .(gva_mfg_pre = mean(values[time %in% 2007:2013], na.rm = TRUE),
    gva_mfg_post = mean(values[time %in% 2014:2020], na.rm = TRUE)),
  by = .(geo)]

gva_total <- gva[nace_r2 == "TOTAL",
  .(gva_tot_pre = mean(values[time %in% 2007:2013], na.rm = TRUE),
    gva_tot_post = mean(values[time %in% 2014:2020], na.rm = TRUE)),
  by = .(geo)]

gva_share <- merge(gva_mfg, gva_total, by = "geo")
gva_share[, `:=`(
  mfg_share_pre = gva_mfg_pre / gva_tot_pre,
  mfg_share_post = gva_mfg_post / gva_tot_post,
  delta_mfg_share = gva_mfg_post / gva_tot_post - gva_mfg_pre / gva_tot_pre
)]

# Compensation
coe_panel <- coe[nace_r2 == "TOTAL",
  .(coe_pre = mean(values[time %in% 2007:2013], na.rm = TRUE),
    coe_post = mean(values[time %in% 2014:2020], na.rm = TRUE)),
  by = .(geo)]
coe_panel[, delta_coe := (coe_post - coe_pre) / coe_pre * 100]  # % change

## ---------------------------------------------------------
## 7. Merge analysis dataset
## ---------------------------------------------------------
analysis <- rv[!is.na(running_var)]
analysis[, country := substr(geo, 1, 2)]

analysis <- merge(analysis, gdp_growth, by = "geo", all.x = TRUE)
analysis <- merge(analysis, emp_panel, by = "geo", all.x = TRUE)
analysis <- merge(analysis, gva_share, by = "geo", all.x = TRUE)
analysis <- merge(analysis, coe_panel, by = "geo", all.x = TRUE)

cat("\n=== ANALYSIS DATASET ===\n")
cat("Total regions:", nrow(analysis), "\n")
cat("With GDP outcome:", sum(!is.na(analysis$delta_gdp)), "\n")
cat("With employment:", sum(!is.na(analysis$delta_emp)), "\n")
cat("Near threshold (65-85%):", sum(analysis$running_var >= 65 & analysis$running_var <= 85, na.rm = TRUE), "\n")
cat("Graduated:", sum(analysis$graduated_from_convergence == 1, na.rm = TRUE), "\n")

## ---------------------------------------------------------
## 8. Annual panel for event study
## ---------------------------------------------------------
cat("\nBuilding annual panel...\n")

annual_panel <- gdp_full[time >= 2000 & time <= 2024]
setnames(annual_panel, c("values"), c("gdp_pct"))

annual_panel <- merge(annual_panel,
  rv[, .(geo, running_var, rv_centered, graduated, category_2014,
         category_0713, graduated_from_convergence)],
  by = "geo", all.x = TRUE)

annual_panel[, country := substr(geo, 1, 2)]

# Add employment
emp_annual <- emp_rate[, .(geo, year = time, emp_rate = values)]
setnames(annual_panel, "time", "year")
annual_panel <- merge(annual_panel, emp_annual, by = c("geo", "year"), all.x = TRUE)

cat("Annual panel:", nrow(annual_panel), "obs,",
    uniqueN(annual_panel$geo), "regions,",
    paste(range(annual_panel$year), collapse = "-"), "\n")

## ---------------------------------------------------------
## 9. Save
## ---------------------------------------------------------
fwrite(analysis, paste0(data_dir, "analysis.csv"))
fwrite(annual_panel, paste0(data_dir, "annual_panel.csv"))

cat("\n=== CLEANING COMPLETE ===\n")
