# 02_clean_data.R — Construct analysis panel
# apep_0871: NIS2 Cybersecurity Regulation and Enterprise Security Investment

source("00_packages.R")

# ===========================================================================
# 1. Load raw data
# ===========================================================================
ict_raw <- readRDS("../data/ict_security_raw.rds")
nis2 <- readRDS("../data/nis2_transposition.rds")

# ===========================================================================
# 2. Filter to analysis sample
# ===========================================================================

# EU-27 country codes
eu27 <- nis2$geo

# Size classes for DiD: control (10-49), treated (50-249), dosage (GE250)
size_classes <- c("10-49", "50-249", "GE250")

# Years: 2019, 2022 (pre), 2024 (post)
# Also keep 2015 for extended pre-trend if available
analysis_years <- c(2015, 2019, 2022, 2024)

ict_raw[, year := as.integer(format(TIME_PERIOD, "%Y"))]

panel <- ict_raw[
  geo %in% eu27 &
  size_emp %in% size_classes &
  year %in% analysis_years &
  !is.na(values)
]

message(sprintf("Analysis panel: %d observations", nrow(panel)))
message(sprintf("Countries: %d", length(unique(panel$geo))))
message(sprintf("Years: %s", paste(sort(unique(panel$year)), collapse = ", ")))

# ===========================================================================
# 3. Identify indicators available in 2019, 2022, and 2024
# ===========================================================================

# For the core DiD we need indicators present in all 3 main years
# for both 10-49 and 50-249 size classes
core_coverage <- panel[
  size_emp %in% c("10-49", "50-249") & year %in% c(2019, 2022, 2024),
  .(n_cells = .N, n_countries = uniqueN(geo)),
  by = .(indic_is, size_emp, year)
]

# Indicator must have >=20 countries in each year-size cell
well_covered <- core_coverage[n_countries >= 20]
core_indics <- well_covered[, .(n_cells = .N), by = indic_is]
# Must appear in all 6 cells (2 sizes x 3 years)
core_indics <- core_indics[n_cells == 6, indic_is]

message(sprintf("\nCore indicators (available 2019-2024 for both sizes): %d",
                length(core_indics)))
message(paste(" ", core_indics, collapse = "\n"))

# ===========================================================================
# 4. Classify indicators into categories
# ===========================================================================

# Security measure categories based on NIS2 requirements
indicator_labels <- data.table(
  indic_is = c(
    # Compliance/documentation measures
    "E_SECPOL2",     # Has documented ICT security policy
    "E_SECMRASS",    # Risk assessment carried out
    "E_SECMOSBU",    # Off-site data backup
    # Technical security measures
    "E_SECMDENC",    # Data or email encryption
    "E_SECMVPN",     # VPN (virtual private network)
    "E_SECMLOG",     # Log files for analysis after security incidents
    "E_SECMUIBM",    # User identification via biometric methods
    "E_SECMNAC",     # Network access control
    "E_SECMSPSW",    # Strong password/authentication methods
    "E_SECMTST",     # ICT security tests
    # Training/awareness measures
    "E_SECAWANY",    # Any ICT security awareness activities
    "E_SECAWCTP",    # Staff cybersecurity training provided
    "E_SECAWCONT",   # Mandatory ICT security training/contractual obligation
    "E_SECAWVTGI",   # Voluntary training/guidelines/info available
    "E_SECAWNONE",   # No security awareness measures
    "E_SECAWANY_POL2" # Awareness + documented policy
  ),
  label = c(
    "Security policy documented",
    "Risk assessment",
    "Off-site backup",
    "Encryption",
    "VPN usage",
    "Log file maintenance",
    "Biometric authentication",
    "Network access control",
    "Strong password methods",
    "Security testing",
    "Any awareness activities",
    "Staff training provided",
    "Mandatory training",
    "Voluntary training/info",
    "No awareness measures",
    "Awareness + policy"
  ),
  category = c(
    "compliance", "compliance", "compliance",
    "technical", "technical", "technical", "technical",
    "technical", "technical", "technical",
    "training", "training", "training", "training",
    "training", "training"
  )
)

# Filter to core indicators that are in our classification
indicator_labels <- indicator_labels[indic_is %in% core_indics]
message(sprintf("\nClassified indicators in core set: %d", nrow(indicator_labels)))

# ===========================================================================
# 5. Construct analysis variables
# ===========================================================================

panel_clean <- panel[indic_is %in% indicator_labels$indic_is]

# Merge indicator labels
panel_clean <- merge(panel_clean, indicator_labels, by = "indic_is", all.x = TRUE)

# Merge transposition status
panel_clean <- merge(panel_clean, nis2[, .(geo, transposed_by_deadline)],
                     by = "geo", all.x = TRUE)

# Treatment variables
panel_clean[, `:=`(
  # Medium firm (newly NIS2-covered) vs small firm (exempt)
  medium_firm = as.integer(size_emp == "50-249"),
  large_firm = as.integer(size_emp == "GE250"),
  small_firm = as.integer(size_emp == "10-49"),
  # Post-NIS2 period
  post = as.integer(year >= 2024),
  # DiD interaction
  treat_post = as.integer(size_emp == "50-249" & year >= 2024),
  # DDD: transposed x medium x post
  transposed = as.integer(transposed_by_deadline),
  # Country-size fixed effect
  geo_size = paste0(geo, "_", size_emp),
  # Country-year fixed effect
  geo_year = paste0(geo, "_", year),
  # Size-year fixed effect
  size_year = paste0(size_emp, "_", year)
)]

# DDD interaction
panel_clean[, treat_post_transposed := as.integer(
  size_emp == "50-249" & year >= 2024 & transposed_by_deadline == TRUE
)]

# ===========================================================================
# 6. Construct composite security index
# ===========================================================================

# Average across all classified measures (excl. "no awareness" which is inverted)
positive_measures <- indicator_labels[indic_is != "E_SECAWNONE", indic_is]

idx_data <- panel_clean[indic_is %in% positive_measures,
  .(security_index = mean(values, na.rm = TRUE),
    n_measures = sum(!is.na(values))),
  by = .(geo, size_emp, year, transposed_by_deadline, medium_firm,
         large_firm, small_firm, post, treat_post, transposed,
         geo_size, geo_year, size_year, treat_post_transposed)
]

# Category-level indices
for (cat in c("compliance", "technical", "training")) {
  cat_indics <- indicator_labels[category == cat & indic_is != "E_SECAWNONE", indic_is]
  cat_idx <- panel_clean[indic_is %in% cat_indics,
    .(cat_value = mean(values, na.rm = TRUE)),
    by = .(geo, size_emp, year)
  ]
  setnames(cat_idx, "cat_value", paste0(cat, "_index"))
  idx_data <- merge(idx_data, cat_idx, by = c("geo", "size_emp", "year"), all.x = TRUE)
}

message(sprintf("\nComposite index panel: %d observations", nrow(idx_data)))
message(sprintf("  Countries: %d", uniqueN(idx_data$geo)))
message(sprintf("  Size classes: %s", paste(unique(idx_data$size_emp), collapse = ", ")))
message(sprintf("  Years: %s", paste(sort(unique(idx_data$year)), collapse = ", ")))

# ===========================================================================
# 7. Save clean data
# ===========================================================================

saveRDS(panel_clean, "../data/panel_clean.rds")
saveRDS(idx_data, "../data/index_panel.rds")
saveRDS(indicator_labels, "../data/indicator_labels.rds")

message("\nClean data saved.")

# ===========================================================================
# 8. Summary statistics
# ===========================================================================

message("\n--- Summary Statistics ---")

# By size class and year (security index)
summ <- idx_data[, .(
  mean_security = round(mean(security_index, na.rm = TRUE), 1),
  sd_security = round(sd(security_index, na.rm = TRUE), 1),
  n = .N
), by = .(size_emp, year)]
setorder(summ, size_emp, year)
print(summ)

# Check parallel trends: change from 2019 to 2022 (pre-period)
message("\n--- Pre-trend check (2019 to 2022 change) ---")
pre_trend <- idx_data[year %in% c(2019, 2022),
  .(mean_idx = mean(security_index, na.rm = TRUE)),
  by = .(size_emp, year)]
pre_trend_wide <- dcast(pre_trend, size_emp ~ year, value.var = "mean_idx")
pre_trend_wide[, change_19_22 := `2022` - `2019`]
print(pre_trend_wide)
