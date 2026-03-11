## 02_clean_data.R — Parse and construct analysis variables
## apep_0594: Spain's 2022 Temporary Contract Ban

source("00_packages.R")

cat("=== Cleaning and constructing analysis data ===\n")

# =============================================================================
# 1. Parse Table 65328: Region x Contract Type
# =============================================================================

dt_raw <- fread(file.path(data_dir, "ine_epa_65328_raw.csv"))

# Parse series_name structure:
# "Wage-earners: Total. Both genders. [REGION]. [CONTRACT_TYPE]. [UNIT]."
# Contract types include: Total, Of indefinite duration: Permanent over time,
# Time frame: Temporary due to production circumstances

# Extract region
regions <- c(
  "National Total", "Andaluc\u00eda", "Arag\u00f3n",
  "Asturias, Principado de", "Balears, Illes",
  "Canarias", "Cantabria", "Castilla y Le\u00f3n",
  "Castilla - La Mancha", "Catalu\u00f1a",
  "Comunitat Valenciana", "Extremadura",
  "Galicia", "Madrid, Comunidad de",
  "Murcia, Regi\u00f3n de", "Navarra, Comunidad Foral de",
  "Pa\u00eds Vasco", "Rioja, La", "Ceuta", "Melilla"
)

# Build regex pattern
region_pattern <- paste0("(", paste(gsub("([()])", "\\\\\\1", regions), collapse = "|"), ")")

dt_raw[, region := str_extract(series_name, region_pattern)]
dt_raw[, region := str_trim(region)]

# Extract contract type
dt_raw[, contract_type := case_when(
  str_detect(series_name, "Of indefinite duration") ~ "permanent",
  str_detect(series_name, "Time frame|Temporary|temporary") ~ "temporary",
  str_detect(series_name, "Total\\.\\s*(Persons|Percentage)") ~ "total",
  TRUE ~ "other"
)]

# Extract unit (Persons vs Percentage)
dt_raw[, unit := ifelse(str_detect(series_name, "Persons"), "persons", "pct")]

# Extract sex
dt_raw[, sex := case_when(
  str_detect(series_name, "Both genders") ~ "both",
  str_detect(series_name, "Males") ~ "male",
  str_detect(series_name, "Females") ~ "female",
  TRUE ~ "both"
)]

cat("Parsed regions:", length(unique(dt_raw$region[!is.na(dt_raw$region)])), "\n")
cat("Contract types:", paste(unique(dt_raw$contract_type), collapse = ", "), "\n")

# Filter to: Both genders, Persons (thousands), exclude National Total
dt_region <- dt_raw[
  sex == "both" &
  unit == "persons" &
  !is.na(region) &
  region != "National Total" &
  contract_type %in% c("total", "permanent", "temporary")
]

# Pivot wide: one row per region x quarter
dt_wide <- dcast(
  dt_region,
  region + year + quarter + yq ~ contract_type,
  value.var = "value",
  fun.aggregate = mean
)

# Rename
setnames(dt_wide, c("total", "permanent", "temporary"),
         c("wage_earners_total", "wage_earners_perm", "wage_earners_temp"),
         skip_absent = TRUE)

# Compute temporary share
dt_wide[, temp_share := wage_earners_temp / wage_earners_total]
dt_wide[, perm_share := wage_earners_perm / wage_earners_total]

cat("Region panel:", nrow(dt_wide), "obs,", length(unique(dt_wide$region)), "regions,",
    length(unique(dt_wide$yq)), "quarters\n")

# =============================================================================
# 2. Construct treatment intensity
# =============================================================================

# Pre-reform temporary share (2021Q4 = last pre-reform quarter)
# The reform became effective March 30, 2022, so 2022Q1 is transitional
# Use average of 2021Q1-Q4 for robustness
pre_reform <- dt_wide[year == 2021, .(
  pre_temp_share = mean(temp_share, na.rm = TRUE),
  pre_total = mean(wage_earners_total, na.rm = TRUE)
), by = region]

cat("\nPre-reform temporary shares:\n")
print(pre_reform[order(-pre_temp_share)], nrows = 20)

# Merge treatment intensity
dt_panel <- merge(dt_wide, pre_reform, by = "region", all.x = TRUE)

# Post-reform indicator (reform effective 2022Q2 onwards — March 30 is end of Q1)
dt_panel[, post := as.integer(year > 2022 | (year == 2022 & quarter >= 2))]

# Treatment variable: interaction
dt_panel[, treat := pre_temp_share * post]

# Time variable (numeric for event study)
dt_panel[, time_num := (year - 2010) * 4 + quarter]
reform_time <- (2022 - 2010) * 4 + 2  # 2022Q2
dt_panel[, event_time := time_num - reform_time]

# Region ID (numeric for fixest)
dt_panel[, region_id := as.integer(as.factor(region))]

# =============================================================================
# 3. Parse Table 65133: National sector-level data
# =============================================================================

dt_sector_raw <- fread(file.path(data_dir, "ine_epa_65133_raw.csv"))

# Extract sector
dt_sector_raw[, sector := case_when(
  str_detect(series_name, "Agriculture") ~ "Agriculture",
  str_detect(series_name, "Industry") ~ "Industry",
  str_detect(series_name, "Construction") ~ "Construction",
  str_detect(series_name, "Services") ~ "Services",
  str_detect(series_name, "CNAE total") ~ "Total",
  TRUE ~ "Other"
)]

# Extract contract type
dt_sector_raw[, contract_type := case_when(
  str_detect(series_name, "indefinite") ~ "permanent",
  str_detect(series_name, "temporary") ~ "temporary",
  str_detect(series_name, "Total wage") ~ "total_wage",
  str_detect(series_name, "Non wage") ~ "non_wage",
  str_detect(series_name, "Non-classifiable") ~ "nonclass",
  str_detect(series_name, "\\. Total\\.") ~ "total_employed",
  TRUE ~ "other"
)]

dt_sector_raw[, unit := ifelse(str_detect(series_name, "Persons"), "persons", "pct")]
dt_sector_raw[, sex := case_when(
  str_detect(series_name, "Both genders") ~ "both",
  str_detect(series_name, "Males") ~ "male",
  str_detect(series_name, "Females") ~ "female",
  TRUE ~ "both"
)]

# Filter: both genders, persons, key categories
dt_sector <- dt_sector_raw[
  sex == "both" &
  unit == "persons" &
  sector != "Other" &
  contract_type %in% c("total_wage", "permanent", "temporary")
]

# Pivot
dt_sector_wide <- dcast(
  dt_sector,
  sector + year + quarter + yq ~ contract_type,
  value.var = "value",
  fun.aggregate = mean
)

setnames(dt_sector_wide,
         c("total_wage", "permanent", "temporary"),
         c("sector_total", "sector_perm", "sector_temp"),
         skip_absent = TRUE)

dt_sector_wide[, sector_temp_share := sector_temp / sector_total]
dt_sector_wide[, sector_perm_share := sector_perm / sector_total]

cat("\nSector panel:", nrow(dt_sector_wide), "obs,",
    length(unique(dt_sector_wide$sector)), "sectors\n")

# =============================================================================
# 4. Parse Table 4076: unemployment rates by region (if available)
# =============================================================================

rates_file <- file.path(data_dir, "ine_epa_4076_raw.csv")
if (file.exists(rates_file)) {
  dt_rates_raw <- fread(rates_file)
  # This table has activity/unemployment/employment rates by region
  # We want unemployment rate for additional analysis
  dt_rates_raw[, region := str_extract(series_name, region_pattern)]
  dt_rates_raw[, rate_type := case_when(
    str_detect(series_name, "Unemployment") ~ "unemployment",
    str_detect(series_name, "Employment") ~ "employment",
    str_detect(series_name, "Activity") ~ "activity",
    TRUE ~ "other"
  )]
  dt_rates_raw[, sex := case_when(
    str_detect(series_name, "Both genders") ~ "both",
    str_detect(series_name, "Males") ~ "male",
    str_detect(series_name, "Females") ~ "female",
    TRUE ~ "both"
  )]

  # Wide format for rates
  dt_rates <- dt_rates_raw[
    sex == "both" & !is.na(region) & region != "National Total" &
    rate_type %in% c("unemployment", "employment", "activity")
  ]
  dt_rates_wide <- dcast(
    dt_rates,
    region + year + quarter + yq ~ rate_type,
    value.var = "value",
    fun.aggregate = mean
  )

  # Merge with main panel
  dt_panel <- merge(dt_panel, dt_rates_wide,
                    by = c("region", "year", "quarter", "yq"),
                    all.x = TRUE)
  cat("Merged unemployment/employment rates\n")
}

# =============================================================================
# 5. Also compute national aggregates for descriptive figures
# =============================================================================

dt_national_raw <- dt_raw[
  sex == "both" &
  unit == "persons" &
  region == "National Total" &
  contract_type %in% c("total", "permanent", "temporary")
]

dt_national <- dcast(
  dt_national_raw,
  year + quarter + yq ~ contract_type,
  value.var = "value",
  fun.aggregate = mean
)

setnames(dt_national, c("total", "permanent", "temporary"),
         c("nat_total", "nat_perm", "nat_temp"),
         skip_absent = TRUE)

dt_national[, nat_temp_share := nat_temp / nat_total]
dt_national[, nat_perm_share := nat_perm / nat_total]

# =============================================================================
# 6. Save analysis datasets
# =============================================================================

fwrite(dt_panel, file.path(data_dir, "analysis_panel.csv"))
fwrite(dt_sector_wide, file.path(data_dir, "sector_panel.csv"))
fwrite(dt_national, file.path(data_dir, "national_aggregates.csv"))
fwrite(pre_reform, file.path(data_dir, "pre_reform_treatment.csv"))

cat("\n=== Saved analysis datasets ===\n")
cat("  analysis_panel.csv:", nrow(dt_panel), "rows\n")
cat("  sector_panel.csv:", nrow(dt_sector_wide), "rows\n")
cat("  national_aggregates.csv:", nrow(dt_national), "rows\n")
cat("  pre_reform_treatment.csv:", nrow(pre_reform), "rows\n")

# Summary statistics
cat("\n=== SUMMARY STATISTICS ===\n")
cat("Regions:", length(unique(dt_panel$region)), "\n")
cat("Quarters:", length(unique(dt_panel$yq)), "\n")
cat("Years:", paste(range(dt_panel$year), collapse = "-"), "\n")
cat("Pre-reform temp share: mean =", round(mean(pre_reform$pre_temp_share), 3),
    ", SD =", round(sd(pre_reform$pre_temp_share), 3),
    ", range =", paste(round(range(pre_reform$pre_temp_share), 3), collapse = " to "), "\n")
