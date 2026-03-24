# 01_fetch_data.R — Fetch Eurostat ICT security survey + NIS2 transposition data
# apep_0871: NIS2 Cybersecurity Regulation and Enterprise Security Investment

source("00_packages.R")

# ===========================================================================
# 1. Fetch Eurostat ICT Security Survey (isoc_cisce_ra)
# ===========================================================================
message("Fetching Eurostat ICT security survey (isoc_cisce_ra)...")

ict_raw <- get_eurostat("isoc_cisce_ra", cache = FALSE)
ict_raw <- as.data.table(ict_raw)

message(sprintf("Raw ICT security data: %d rows, %d columns", nrow(ict_raw), ncol(ict_raw)))

# Extract year from TIME_PERIOD (Date format)
ict_raw[, year := as.integer(format(TIME_PERIOD, "%Y"))]

# Validate data
stopifnot(nrow(ict_raw) > 0)
stopifnot(all(c("size_emp", "indic_is", "geo", "values", "year") %in% names(ict_raw)))

message(sprintf("Years: %s", paste(sort(unique(ict_raw$year)), collapse = ", ")))
message(sprintf("Size classes: %s", paste(sort(unique(ict_raw$size_emp)), collapse = ", ")))
message(sprintf("Indicators: %d unique", length(unique(ict_raw$indic_is))))
message(sprintf("Non-null values: %d of %d", sum(!is.na(ict_raw$values)), nrow(ict_raw)))

# Save raw data
saveRDS(ict_raw, "../data/ict_security_raw.rds")
message("Saved ict_security_raw.rds")

# ===========================================================================
# 2. NIS2 Transposition Status
# ===========================================================================
# NIS2 Directive: 2022/2555, transposition deadline: October 17, 2024
# Classification based on European Commission NIS Cooperation Group and
# official EU tracking (https://digital-strategy.ec.europa.eu/en/policies/nis2-transposition)
# As of Dec 2024: Only Belgium, Croatia, Hungary, Italy, Latvia, Lithuania
# had fully transposed. Most member states were late.

message("\nConstructing NIS2 transposition panel...")

nis2_transposition <- data.table(
  geo = c("AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR",
          "DE", "EL", "HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL",
          "PL", "PT", "RO", "SK", "SI", "ES", "SE"),
  country_name = c("Austria", "Belgium", "Bulgaria", "Croatia", "Cyprus",
                   "Czechia", "Denmark", "Estonia", "Finland", "France",
                   "Germany", "Greece", "Hungary", "Ireland", "Italy",
                   "Latvia", "Lithuania", "Luxembourg", "Malta", "Netherlands",
                   "Poland", "Portugal", "Romania", "Slovakia", "Slovenia",
                   "Spain", "Sweden"),
  # Early transposers: transposed NIS2 by or before the Oct 2024 deadline
  transposed_by_deadline = c(
    FALSE, # Austria - late
    TRUE,  # Belgium - Oct 2024
    FALSE, # Bulgaria - late
    TRUE,  # Croatia - early (Jul 2024)
    FALSE, # Cyprus - late
    FALSE, # Czechia - late
    FALSE, # Denmark - late
    FALSE, # Estonia - late
    FALSE, # Finland - late
    FALSE, # France - late
    FALSE, # Germany - late
    FALSE, # Greece - late
    TRUE,  # Hungary - Oct 2024
    FALSE, # Ireland - late
    TRUE,  # Italy - Oct 2024
    TRUE,  # Latvia - Sep 2024
    TRUE,  # Lithuania - Oct 2024
    FALSE, # Luxembourg - late
    FALSE, # Malta - late
    FALSE, # Netherlands - late
    FALSE, # Poland - late
    FALSE, # Portugal - late
    FALSE, # Romania - late
    FALSE, # Slovakia - late
    FALSE, # Slovenia - late
    FALSE, # Spain - late
    FALSE  # Sweden - late
  )
)

n_transposed <- sum(nis2_transposition$transposed_by_deadline)
message(sprintf("Countries transposed by deadline: %d of %d",
                n_transposed, nrow(nis2_transposition)))
message(sprintf("Early transposers: %s",
                paste(nis2_transposition[transposed_by_deadline == TRUE, geo],
                      collapse = ", ")))

saveRDS(nis2_transposition, "../data/nis2_transposition.rds")

message("\nData fetch complete.")
