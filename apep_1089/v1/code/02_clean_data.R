## 02_clean_data.R — Clean and construct analysis dataset
## apep_1089: NIS2 Cybersecurity Regulation and Firm Security Investment

source("code/00_packages.R")

cat("=== Cleaning ICT Security Data ===\n")

# ----------------------------------------------------------------
# 1. Load raw data
# ----------------------------------------------------------------

raw <- readRDS("data/ict_security_raw.rds")
stopifnot("Raw data is empty" = nrow(raw) > 0)

# ----------------------------------------------------------------
# 2. Define EU27 member states and key size classes
# ----------------------------------------------------------------

eu27 <- c("AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
          "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
          "NL", "PL", "PT", "RO", "SE", "SI", "SK")

# NIS2 transposition status as of October 2024
# Source: EUR-Lex national transposition measures database
# Transposed = national law adopted and notified to Commission by Oct 2024
transposed_countries <- c("BE", "CZ", "DE", "DK", "EE", "EL", "HR", "IT", "CY",
                          "HU", "LT", "LV")
# Remaining EU27: AT, BG, ES, FI, FR, IE, LU, MT, NL, PL, PT, RO, SE, SI, SK

# ----------------------------------------------------------------
# 3. Filter to analysis sample
# ----------------------------------------------------------------

df <- raw %>%
  filter(
    size_emp %in% c("10-49", "50-249", "GE250"),
    geo %in% eu27,
    unit == "PC_ENT",
    TIME_PERIOD %in% c(2019, 2022, 2024)
  ) %>%
  rename(
    country = geo,
    year = TIME_PERIOD,
    indicator = indic_is,
    size_class = size_emp,
    value = values
  ) %>%
  select(country, year, size_class, indicator, value) %>%
  filter(!is.na(value))

cat(sprintf("Analysis sample: %d observations\n", nrow(df)))
cat(sprintf("Countries: %d\n", n_distinct(df$country)))
cat(sprintf("Years: %s\n", paste(sort(unique(df$year)), collapse = ", ")))
cat(sprintf("Size classes: %s\n", paste(sort(unique(df$size_class)), collapse = ", ")))
cat(sprintf("Indicators: %d\n", n_distinct(df$indicator)))

# ----------------------------------------------------------------
# 4. Classify indicators into Technical vs Formal
# ----------------------------------------------------------------

# Technical security measures (substantive investment)
technical_indicators <- c(
  "E_SECMDENC",   # Data encryption
  "E_SECMLOG",    # Log file maintenance
  "E_SECMNAC",    # Network access control
  "E_SECMOSBU",   # Off-site data backup
  "E_SECMSPSW",   # Strong password authentication
  "E_SECMTST",    # ICT security testing/auditing
  "E_SECMUIBM",   # User identification by biometric methods
  "E_SECMVPN"     # VPN for data transmission
)

# Formal compliance measures (documentation/process)
formal_indicators <- c(
  "E_SECPOL2",    # Formally defined ICT security policy
  "E_SECMRASS",   # ICT risk assessment carried out
  "E_SECAWANY",   # Any ICT security awareness activity
  "E_SECAWCTP",   # Compulsory ICT security training/courses
  "E_SECAWVTGI",  # Voluntary training, guides, information
  "E_SECAWCONT"   # Contractual obligations on ICT security
)

# Awareness-only subset (most "paperwork-like")
awareness_indicators <- c("E_SECAWANY", "E_SECAWCTP", "E_SECAWVTGI", "E_SECAWCONT")

df <- df %>%
  mutate(
    measure_type = case_when(
      indicator %in% technical_indicators ~ "technical",
      indicator %in% formal_indicators ~ "formal",
      TRUE ~ "other"
    )
  )

cat(sprintf("\nTechnical indicators: %d\n", length(technical_indicators)))
cat(sprintf("Formal indicators: %d\n", length(formal_indicators)))

# ----------------------------------------------------------------
# 5. Create treatment variables
# ----------------------------------------------------------------

df <- df %>%
  mutate(
    # DiD treatment: 50-249 newly covered by NIS2
    treated = as.integer(size_class == "50-249"),
    post = as.integer(year == 2024),
    treat_post = treated * post,

    # Transposition status
    transposed = as.integer(country %in% transposed_countries),
    treat_post_trans = treated * post * transposed,

    # Size class factor (for FE)
    size_factor = factor(size_class, levels = c("10-49", "50-249", "GE250")),

    # Country-year ID for clustering
    country_year = paste0(country, "_", year)
  )

# ----------------------------------------------------------------
# 6. Construct indices (average adoption rates)
# ----------------------------------------------------------------

# Wide format: one row per country × size_class × year
# with index values computed as mean across indicator types

indices <- df %>%
  filter(measure_type %in% c("technical", "formal")) %>%
  group_by(country, year, size_class, measure_type) %>%
  summarize(
    index = mean(value, na.rm = TRUE),
    n_indicators = sum(!is.na(value)),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = measure_type,
    values_from = c(index, n_indicators),
    names_sep = "_"
  ) %>%
  mutate(
    # Treatment variables
    treated = as.integer(size_class == "50-249"),
    post = as.integer(year == 2024),
    treat_post = treated * post,
    transposed = as.integer(country %in% transposed_countries),
    treat_post_trans = treated * post * transposed,
    size_factor = factor(size_class, levels = c("10-49", "50-249", "GE250")),

    # Compliance theater gap: formal minus technical
    compliance_gap = index_formal - index_technical
  )

cat(sprintf("\nIndex dataset: %d rows (country × size × year)\n", nrow(indices)))

# ----------------------------------------------------------------
# 7. Create indicator-level panel (long format for indicator FE)
# ----------------------------------------------------------------

indicator_panel <- df %>%
  filter(measure_type %in% c("technical", "formal")) %>%
  mutate(
    indicator_id = paste0(country, "_", size_class, "_", indicator),
    country_size = paste0(country, "_", size_class)
  )

cat(sprintf("Indicator panel: %d rows\n", nrow(indicator_panel)))

# ----------------------------------------------------------------
# 8. Summary statistics
# ----------------------------------------------------------------

cat("\n=== Summary Statistics ===\n")

# By size class and period
summary_stats <- indices %>%
  group_by(size_class, year) %>%
  summarize(
    mean_technical = mean(index_technical, na.rm = TRUE),
    sd_technical = sd(index_technical, na.rm = TRUE),
    mean_formal = mean(index_formal, na.rm = TRUE),
    sd_formal = sd(index_formal, na.rm = TRUE),
    mean_gap = mean(compliance_gap, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )

print(summary_stats)

# ----------------------------------------------------------------
# 9. Save cleaned data
# ----------------------------------------------------------------

saveRDS(df, "data/ict_security_clean.rds")
saveRDS(indices, "data/indices.rds")
saveRDS(indicator_panel, "data/indicator_panel.rds")

# Save summary stats for tables
saveRDS(summary_stats, "data/summary_stats.rds")

cat("\n=== Clean data saved ===\n")
cat(sprintf("  ict_security_clean.rds: %d rows\n", nrow(df)))
cat(sprintf("  indices.rds: %d rows\n", nrow(indices)))
cat(sprintf("  indicator_panel.rds: %d rows\n", nrow(indicator_panel)))
