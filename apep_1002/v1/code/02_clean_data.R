# 02_clean_data.R — Clean and construct analysis panel
# apep_1002: Czech EET Abolition and Formalization Hysteresis

source("00_packages.R")

cat("=== Loading raw data ===\n")
sts_raw <- readRDS("../data/sts_rb_q_raw.rds")

# Inspect structure
cat("Columns:", paste(names(sts_raw), collapse = ", "), "\n")
cat("Unique indicators:", paste(unique(sts_raw$indic_bt), collapse = ", "), "\n")
cat("Unique s_adj:", paste(unique(sts_raw$s_adj), collapse = ", "), "\n")
cat("Unique NACE sectors:", paste(sort(unique(sts_raw$nace_r2)), collapse = ", "), "\n")

# Filter to our analysis sample
countries <- c("CZ", "HU", "HR", "IT", "PL", "SE")

panel <- sts_raw %>%
  filter(
    geo %in% countries,
    # Business registrations (not bankruptcies)
    indic_bt == "REG",
    # Use whatever seasonal adjustment is available (NSA preferred, then SCA, then CA)
    s_adj %in% c("NSA", "SCA", "CA")
  ) %>%
  # Prefer NSA > SCA > CA
  group_by(geo, nace_r2, TIME_PERIOD) %>%
  arrange(match(s_adj, c("NSA", "SCA", "CA"))) %>%
  slice(1) %>%
  ungroup()

cat("\nAfter filtering:\n")
cat("  Rows:", nrow(panel), "\n")
cat("  Countries:", paste(sort(unique(panel$geo)), collapse = ", "), "\n")
cat("  Sectors:", length(unique(panel$nace_r2)), "\n")
cat("  Time range:", as.character(min(panel$TIME_PERIOD)), "to",
    as.character(max(panel$TIME_PERIOD)), "\n")

# If NSA not available, check what s_adj values we got
if (nrow(panel) == 0) {
  cat("WARNING: No NSA/CA data found. Checking all s_adj values...\n")
  panel <- sts_raw %>%
    filter(geo %in% countries, indic_bt == "RG") %>%
    group_by(geo, nace_r2, TIME_PERIOD) %>%
    slice(1) %>%
    ungroup()
  cat("  Rows with any s_adj:", nrow(panel), "\n")
}

stopifnot("Panel is empty after filtering" = nrow(panel) > 0)

# Construct time variables
panel <- panel %>%
  mutate(
    year = as.integer(format(TIME_PERIOD, "%Y")),
    quarter = as.integer(format(TIME_PERIOD, "%m")) %/% 3,
    # Ensure quarter is 1-4
    quarter = ifelse(quarter == 0, 4, quarter),
    # Year-quarter numeric for event study
    yq = year + (quarter - 1) / 4,
    # Treatment variables
    czech = as.integer(geo == "CZ"),
    post = as.integer(TIME_PERIOD >= as.Date("2023-01-01")),
    treat = czech * post,
    # Country-sector ID
    cs_id = paste(geo, nace_r2, sep = "_"),
    # Registration value
    reg_index = as.numeric(values)
  ) %>%
  filter(
    # Keep Q1 2015 through latest available
    year >= 2015,
    !is.na(reg_index)
  )

# EET phase mapping for Czech sectors
# Phase 1 (Dec 2016): I55+I56 (Accommodation + Food service)
# Phase 2 (Mar 2017): G (Wholesale/retail trade)
# Phase 3 (Mar 2018): various professional services
# Phase 4 (Jun 2018): C (Manufacturing), F (Construction)
eet_phases <- tibble(
  nace_r2 = c("I", "G", "M", "N", "H", "C", "F"),
  eet_phase = c(1, 2, 3, 3, 3, 4, 4),
  eet_start = as.Date(c("2016-12-01", "2017-03-01", "2018-03-01",
                          "2018-03-01", "2018-03-01", "2018-06-01", "2018-06-01")),
  cash_intensive = c(TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE)
)

panel <- panel %>%
  left_join(eet_phases, by = "nace_r2") %>%
  mutate(
    eet_phase = replace_na(eet_phase, 0),  # 0 = not explicitly covered by EET
    cash_intensive = replace_na(cash_intensive, FALSE)
  )

# Summary
cat("\n=== Panel Summary ===\n")
cat("Observations:", nrow(panel), "\n")
cat("Country-sector units:", n_distinct(panel$cs_id), "\n")
cat("Countries:", paste(sort(unique(panel$geo)), collapse = ", "), "\n")
cat("Quarters:", n_distinct(panel$TIME_PERIOD), "\n")
cat("NACE sectors:", paste(sort(unique(panel$nace_r2)), collapse = ", "), "\n")

cat("\nObservations by country:\n")
panel %>% count(geo) %>% print()

cat("\nCzech EET phase coverage:\n")
panel %>%
  filter(geo == "CZ") %>%
  distinct(nace_r2, eet_phase, cash_intensive) %>%
  arrange(eet_phase) %>%
  print()

# Save analysis panel
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nSaved analysis_panel.rds\n")

# Also save a CSV for replication
write_csv(panel %>% select(geo, nace_r2, TIME_PERIOD, year, quarter, yq,
                            reg_index, czech, post, treat, eet_phase, cash_intensive, cs_id),
          "../data/analysis_panel.csv")
cat("Saved analysis_panel.csv\n")
