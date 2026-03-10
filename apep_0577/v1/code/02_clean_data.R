#' 02_clean_data.R — Clean and construct analysis variables
#' REACH 2018 Deadline and Chemical Industry Restructuring

source("00_packages.R")

data_dir <- "../data/"

# ===========================================================================
# 1. Load raw data
# ===========================================================================
sbs <- fread(paste0(data_dir, "sbs_data.csv"))
sc <- fread(paste0(data_dir, "sbs_size_class.csv"))
bd <- fread(paste0(data_dir, "bd_data.csv"))

# ===========================================================================
# 2. Construct micro-firm share (treatment intensity)
# ===========================================================================
cat("Constructing micro-firm shares...\n")

# Micro-firms = LT10 (fewer than 10 employees)
sc_wide <- dcast(sc[indic_sb == "V11110"],
                 geo + nace_r2 + year ~ size_emp,
                 value.var = "values")

# Calculate micro-firm share
# Eurostat size_emp codes: "0-9", "10-19", "20-49", "50-249", "GE250", "TOTAL"
# After dcast, hyphenated names become backtick-quoted columns
avail_cols <- names(sc_wide)
cat("Size class columns available:", paste(avail_cols, collapse = ", "), "\n")

# Find the micro-firm column (0-9 employees)
micro_col <- grep("^0.9$|^0-9$", avail_cols, value = TRUE)
total_col <- grep("^TOTAL$", avail_cols, value = TRUE)

if (length(micro_col) > 0 && length(total_col) > 0) {
  sc_wide[, micro_share := get(micro_col[1]) / get(total_col[1])]
} else {
  stop("Cannot construct micro_share: columns not found. Available: ",
       paste(avail_cols, collapse = ", "))
}

# Pre-treatment average (2014-2017) for C20 chemicals — main analysis
micro_intensity <- sc_wide[nace_r2 == "C20" & year %in% 2014:2017 &
                           !is.na(micro_share) & is.finite(micro_share),
                           .(micro_share_pre = mean(micro_share, na.rm = TRUE)),
                           by = geo]

# Pre-2013 average (2008-2012) for 2013 placebo — avoids post-treatment contamination
micro_intensity_early <- sc_wide[nace_r2 == "C20" & year %in% 2008:2012 &
                                  !is.na(micro_share) & is.finite(micro_share),
                                  .(micro_share_pre2013 = mean(micro_share, na.rm = TRUE)),
                                  by = geo]

micro_intensity <- merge(micro_intensity, micro_intensity_early, by = "geo", all.x = TRUE)

# 2008-only micro-share — earliest available, clearly pre-REACH
micro_intensity_2008 <- sc_wide[nace_r2 == "C20" & year == 2008 &
                                 !is.na(micro_share) & is.finite(micro_share),
                                 .(micro_share_2008 = micro_share),
                                 by = geo]
micro_intensity <- merge(micro_intensity, micro_intensity_2008, by = "geo", all.x = TRUE)

cat("Micro-firm shares computed for", nrow(micro_intensity), "countries\n")
cat("Range (2014-2017):", round(min(micro_intensity$micro_share_pre, na.rm = TRUE), 3),
    "to", round(max(micro_intensity$micro_share_pre, na.rm = TRUE), 3), "\n")
cat("Range (2008-2012):", round(min(micro_intensity$micro_share_pre2013, na.rm = TRUE), 3),
    "to", round(max(micro_intensity$micro_share_pre2013, na.rm = TRUE), 3), "\n")
cat("Correlation between periods:", round(cor(micro_intensity$micro_share_pre,
    micro_intensity$micro_share_pre2013, use = "complete"), 3), "\n")

fwrite(micro_intensity, paste0(data_dir, "micro_intensity.csv"))

# ===========================================================================
# 3. Build main analysis panel
# ===========================================================================
cat("\nBuilding main analysis panel...\n")

# Merge SBS with micro-firm intensity
panel <- merge(sbs, micro_intensity, by = "geo", all.x = TRUE)

# Drop countries without micro-firm share data
panel <- panel[!is.na(micro_share_pre)]

# Treatment indicators
panel[, `:=`(
  # Sector treatment
  chem = as.integer(nace_r2 == "C20"),
  # Time treatment (post May 2018)
  post2018 = as.integer(year >= 2018),
  # 2013 placebo period
  post2013 = as.integer(year >= 2013 & year < 2018),
  # Triple-diff interactions
  chem_post2018 = as.integer(nace_r2 == "C20" & year >= 2018),
  # DDD variable: chem × post2018 × micro_share_pre
  ddd_2018 = as.integer(nace_r2 == "C20" & year >= 2018) * micro_share_pre,
  # Placebo DDD: chem × post2013 × micro_share_pre2013 (uses pre-2013 measure)
  ddd_2013 = as.integer(nace_r2 == "C20" & year >= 2013 & year < 2018) * micro_share_pre2013,
  # DDD with 2008 micro-share (pre-REACH measure)
  ddd_2018_early = as.integer(nace_r2 == "C20" & year >= 2018) * micro_share_2008,
  # Log outcomes
  ln_enterprises = log(enterprises + 1),
  ln_employment = log(employment + 1),
  ln_turnover = log(turnover + 1)
)]

# Centered year for trend-adjusted specifications
panel[, year_c := year - 2013]  # Center on midpoint of sample
# Trend interaction: chem × micro_share × linear year
panel[, chem_micro_trend := chem * micro_share_pre * year_c]

# Binary high/low micro-firm intensity (above/below median)
med_micro <- median(micro_intensity$micro_share_pre, na.rm = TRUE)
panel[, high_micro := as.integer(micro_share_pre > med_micro)]

# Country-sector, country-year, sector-year identifiers
panel[, `:=`(
  cs_id = paste0(geo, "_", nace_r2),
  cy_id = paste0(geo, "_", year),
  sy_id = paste0(nace_r2, "_", year)
)]

cat("Main panel:", nrow(panel), "rows,",
    uniqueN(panel$geo), "countries,",
    uniqueN(panel$nace_r2), "sectors,",
    uniqueN(panel$year), "years\n")

fwrite(panel, paste0(data_dir, "analysis_panel.csv"))

# ===========================================================================
# 4. Build size-class panel (for heterogeneity by firm size)
# ===========================================================================
cat("\nBuilding size-class panel...\n")

sc_panel <- sc[indic_sb == "V11110"]
sc_panel[, year := as.integer(year)]
sc_panel <- merge(sc_panel, micro_intensity, by = "geo", all.x = TRUE)
sc_panel <- sc_panel[!is.na(micro_share_pre)]
sc_panel[, `:=`(
  chem = as.integer(nace_r2 == "C20"),
  post2018 = as.integer(year >= 2018),
  ln_enterprises = log(values + 1)
)]

fwrite(sc_panel, paste0(data_dir, "size_class_panel.csv"))

# ===========================================================================
# 5. Business demography panel
# ===========================================================================
cat("\nBuilding business demography panel...\n")

bd[, year := as.integer(year)]
bd_panel <- merge(bd, micro_intensity, by = "geo", all.x = TRUE)
bd_panel <- bd_panel[!is.na(micro_share_pre)]
bd_panel[, `:=`(
  chem = as.integer(nace_r2 == "C20"),
  post2018 = as.integer(year >= 2018),
  ddd_2018 = as.integer(nace_r2 == "C20" & year >= 2018) * micro_share_pre
)]

fwrite(bd_panel, paste0(data_dir, "bd_panel.csv"))

# ===========================================================================
# 6. Summary statistics
# ===========================================================================
cat("\nComputing summary statistics...\n")

# Separate treated (C20) and control (C22-C25)
sumstats <- panel[, .(
  mean_enterprises = mean(enterprises, na.rm = TRUE),
  sd_enterprises = sd(enterprises, na.rm = TRUE),
  mean_employment = mean(employment, na.rm = TRUE),
  sd_employment = sd(employment, na.rm = TRUE),
  mean_turnover = mean(turnover, na.rm = TRUE),
  sd_turnover = sd(turnover, na.rm = TRUE),
  mean_ln_enterprises = mean(ln_enterprises, na.rm = TRUE),
  sd_ln_enterprises = sd(ln_enterprises, na.rm = TRUE),
  mean_ln_employment = mean(ln_employment, na.rm = TRUE),
  sd_ln_employment = sd(ln_employment, na.rm = TRUE),
  mean_ln_turnover = mean(ln_turnover, na.rm = TRUE),
  sd_ln_turnover = sd(ln_turnover, na.rm = TRUE),
  N = .N
), by = .(sector = ifelse(nace_r2 == "C20", "Chemicals (C20)", "Controls (C22-C25)"))]

fwrite(sumstats, paste0(data_dir, "summary_stats.csv"))

# Overall summary
overall <- panel[, .(
  mean_val = mean(enterprises, na.rm = TRUE),
  sd_val = sd(enterprises, na.rm = TRUE),
  min_val = min(enterprises, na.rm = TRUE),
  max_val = max(enterprises, na.rm = TRUE),
  N = .N
)]

# Micro-share summary
micro_summ <- micro_intensity[, .(
  mean_micro = mean(micro_share_pre),
  sd_micro = sd(micro_share_pre),
  min_micro = min(micro_share_pre),
  max_micro = max(micro_share_pre),
  N = .N
)]

cat("Summary statistics:\n")
print(sumstats)
cat("\nMicro-firm share distribution:\n")
print(micro_summ)

cat("\nData cleaning complete.\n")
