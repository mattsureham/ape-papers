# =============================================================================
# 02_clean_data.R — Clean QWI data and construct treatment variables
# =============================================================================

source("00_packages.R")

cat("Loading raw QWI data...\n")
qwi <- arrow::read_parquet("../data/qwi_raw.parquet")

# -------------------------------------------------------------------------
# State lactation accommodation law treatment dates
# Source: NCSL compilation + idea manifest idea_1635
# -------------------------------------------------------------------------
treatment_laws <- tribble(
  ~state_fips, ~state_abbr, ~treat_year,
  4,  "AZ", NA_integer_,   # Arizona — no state law
  6,  "CA", 2001L,
  8,  "CO", 2008L,
  9,  "CT", 2001L,
  10, "DE", NA_integer_,
  12, "FL", NA_integer_,
  13, "GA", 1999L,
  15, "HI", 1999L,
  16, "ID", NA_integer_,
  17, "IL", 2001L,
  18, "IN", 2008L,
  19, "IA", NA_integer_,
  20, "KS", 2015L,
  21, "KY", NA_integer_,
  22, "LA", 2001L,
  23, "ME", 2009L,
  24, "MD", 2013L,
  25, "MA", NA_integer_,
  26, "MI", 2018L,
  27, "MN", 1998L,
  28, "MS", 2006L,
  29, "MO", NA_integer_,
  30, "MT", 2007L,
  31, "NE", NA_integer_,
  32, "NV", 2019L,
  33, "NH", NA_integer_,
  34, "NJ", 2019L,
  35, "NM", 2007L,
  36, "NY", 2007L,
  37, "NC", NA_integer_,
  38, "ND", 2009L,
  39, "OH", NA_integer_,
  40, "OK", 2006L,
  41, "OR", 2007L,
  42, "PA", NA_integer_,
  44, "RI", 2003L,
  45, "SC", 2014L,
  46, "SD", NA_integer_,
  47, "TN", 2006L,
  48, "TX", 1995L,
  49, "UT", 1995L,
  50, "VT", 2008L,
  51, "VA", 2005L,
  53, "WA", 2009L,
  54, "WV", 2021L,
  55, "WI", NA_integer_,
  56, "WY", 2003L,
  1,  "AL", NA_integer_,
  2,  "AK", 2016L,
  5,  "AR", 2009L,
  11, "DC", NA_integer_,
  # States with no law by end of sample are never-treated
)

# State FIPS to abbreviation mapping (for all 50 states + DC)
state_lookup <- tribble(
  ~state_fips, ~state_name,
  1, "Alabama", 2, "Alaska", 4, "Arizona", 5, "Arkansas", 6, "California",
  8, "Colorado", 9, "Connecticut", 10, "Delaware", 11, "District of Columbia",
  12, "Florida", 13, "Georgia", 15, "Hawaii", 16, "Idaho", 17, "Illinois",
  18, "Indiana", 19, "Iowa", 20, "Kansas", 21, "Kentucky", 22, "Louisiana",
  23, "Maine", 24, "Maryland", 25, "Massachusetts", 26, "Michigan",
  27, "Minnesota", 28, "Mississippi", 29, "Missouri", 30, "Montana",
  31, "Nebraska", 32, "Nevada", 33, "New Hampshire", 34, "New Jersey",
  35, "New Mexico", 36, "New York", 37, "North Carolina", 38, "North Dakota",
  39, "Ohio", 40, "Oklahoma", 41, "Oregon", 42, "Pennsylvania",
  44, "Rhode Island", 45, "South Carolina", 46, "South Dakota",
  47, "Tennessee", 48, "Texas", 49, "Utah", 50, "Vermont",
  51, "Virginia", 53, "Washington", 54, "West Virginia", 55, "Wisconsin",
  56, "Wyoming"
)

# -------------------------------------------------------------------------
# Merge treatment assignment with QWI data
# -------------------------------------------------------------------------
cat("Merging treatment assignment...\n")

# Keep only states we have treatment info for
panel <- qwi %>%
  inner_join(treatment_laws, by = "state_fips") %>%
  left_join(state_lookup, by = "state_fips")

cat("Panel rows after merge:", nrow(panel), "\n")
cat("Unique states:", length(unique(panel$state_fips)), "\n")

# -------------------------------------------------------------------------
# Construct variables
# -------------------------------------------------------------------------
cat("Constructing analysis variables...\n")

panel <- panel %>%
  mutate(
    # Time variable: year-quarter integer for FE
    t_int = (year - 2000L) * 4L + quarter,
    # Calendar quarter for labeling
    yq = paste0(year, "Q", quarter),

    # Demographic indicators
    female = as.integer(sex == 2),
    young = as.integer(agegrp == "A04"),  # 25-34 = childbearing age

    # Treatment indicators
    ever_treated = as.integer(!is.na(treat_year)),
    post_treat = case_when(
      is.na(treat_year) ~ 0L,  # never-treated
      year >= treat_year ~ 1L,  # post-treatment
      TRUE ~ 0L                 # pre-treatment in treated state
    ),

    # DDD interaction
    ddd = female * young * post_treat,

    # DD interactions (for decomposition)
    female_post = female * post_treat,
    young_post = young * post_treat,
    female_young = female * young,

    # Outcome variables
    sep_rate = Sep / Emp,
    hire_rate = HirA / Emp,
    log_emp = log(Emp),
    log_earn = log(EarnS),

    # For CS estimator: first treatment period (0 for never-treated)
    g = ifelse(is.na(treat_year), 0L, as.integer(treat_year))
  ) %>%
  # Drop rows with missing or zero employment (suppressed cells)
  filter(!is.na(Emp), Emp > 0, !is.na(Sep), !is.na(HirA))

cat("Panel rows after cleaning:", nrow(panel), "\n")

# -------------------------------------------------------------------------
# Summary statistics
# -------------------------------------------------------------------------
cat("\n--- Panel Structure ---\n")
cat("States:", length(unique(panel$state_fips)), "\n")
cat("Quarters:", length(unique(panel$t_int)), "\n")
cat("Sex groups:", length(unique(panel$sex)), "\n")
cat("Age groups:", length(unique(panel$agegrp)), "\n")
cat("Total N:", nrow(panel), "\n")
cat("Treated states:", sum(unique(panel$state_fips) %in%
  treatment_laws$state_fips[!is.na(treatment_laws$treat_year)]), "\n")
cat("Never-treated states:", sum(unique(panel$state_fips) %in%
  treatment_laws$state_fips[is.na(treatment_laws$treat_year)]), "\n")

cat("\n--- Outcome Summary ---\n")
panel %>%
  summarise(
    across(c(sep_rate, hire_rate, log_emp, log_earn),
           list(mean = ~mean(., na.rm = TRUE),
                sd = ~sd(., na.rm = TRUE),
                min = ~min(., na.rm = TRUE),
                max = ~max(., na.rm = TRUE)))
  ) %>%
  pivot_longer(everything()) %>%
  print(n = 20)

cat("\n--- Treatment Cohort Summary ---\n")
treatment_laws %>%
  filter(!is.na(treat_year)) %>%
  count(treat_year, name = "n_states") %>%
  arrange(treat_year) %>%
  print(n = 30)

# Save cleaned panel
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nSaved analysis_panel.rds\n")

# Also save treatment laws for reference
saveRDS(treatment_laws, "../data/treatment_laws.rds")
cat("Saved treatment_laws.rds\n")
cat("Done.\n")
