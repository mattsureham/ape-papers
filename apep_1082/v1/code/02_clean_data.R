##############################################################################
# 02_clean_data.R — Construct analysis dataset
# APEP-1082: The Lottery Channel
##############################################################################

source("00_packages.R")

data_dir <- "../data"

# ===========================================================================
# Load ACS microdata
# ===========================================================================

acs <- read_csv(file.path(data_dir, "acs_microdata.csv"),
                show_col_types = FALSE)

cat(sprintf("Loaded ACS microdata: %d records\n", nrow(acs)))

# Load eligibility timeline
eligibility <- read_csv(file.path(data_dir, "dv_eligibility.csv"),
                        show_col_types = FALSE)

# ===========================================================================
# Variable construction
# ===========================================================================

# Merge country info
acs <- acs %>%
  left_join(eligibility, by = c("POBP" = "pobp_code"))

if (sum(is.na(acs$country)) > 0) {
  cat(sprintf("WARNING: %d records with unmatched POBP codes\n",
              sum(is.na(acs$country))))
  acs <- acs %>% filter(!is.na(country))
}

# Education variables (SCHL codes)
# 16 = Regular high school diploma
# 20 = Associate's degree
# 21 = Bachelor's degree
# 22 = Master's degree
# 23 = Professional degree
# 24 = Doctorate degree
acs <- acs %>%
  mutate(
    college = as.integer(SCHL >= 21),  # BA or above
    grad_degree = as.integer(SCHL >= 22),  # MA or above
    hs_diploma = as.integer(SCHL >= 16),
    ln_wage = ifelse(WAGP > 0, log(WAGP), NA),
    working_age = as.integer(AGEP >= 25 & AGEP <= 64),
    female = as.integer(SEX == 2)
  )

# Treatment assignment
# A country is treated after it loses DV eligibility
acs <- acs %>%
  mutate(
    treated_country = as.integer(!is.na(ineligible_from_dv_year)),
    post = case_when(
      is.na(ineligible_from_dv_year) ~ 0L,  # control: always 0
      survey_year >= ineligible_from_dv_year ~ 1L,
      TRUE ~ 0L
    ),
    # First treatment year for CS estimator (0 = never-treated)
    first_treat = ifelse(!is.na(ineligible_from_dv_year),
                         ineligible_from_dv_year, 0)
  )

# Filter to working-age adults
acs_wa <- acs %>% filter(working_age == 1)

cat(sprintf("Working-age sample: %d records\n", nrow(acs_wa)))

# ===========================================================================
# Collapse to country-year cells
# ===========================================================================

# Primary analysis dataset: country x year cells
# Weighted by PWGTP (person weight)
country_year <- acs_wa %>%
  group_by(country, POBP, survey_year, region, ineligible_from_dv_year,
           treated_country, first_treat) %>%
  summarise(
    pct_college = weighted.mean(college, w = PWGTP, na.rm = TRUE) * 100,
    pct_grad = weighted.mean(grad_degree, w = PWGTP, na.rm = TRUE) * 100,
    pct_hs = weighted.mean(hs_diploma, w = PWGTP, na.rm = TRUE) * 100,
    mean_ln_wage = weighted.mean(ln_wage, w = PWGTP, na.rm = TRUE),
    mean_age = weighted.mean(AGEP, w = PWGTP, na.rm = TRUE),
    pct_female = weighted.mean(female, w = PWGTP, na.rm = TRUE) * 100,
    n_obs = n(),
    total_weight = sum(PWGTP),
    .groups = "drop"
  ) %>%
  mutate(
    post = case_when(
      is.na(ineligible_from_dv_year) ~ 0L,
      survey_year >= ineligible_from_dv_year ~ 1L,
      TRUE ~ 0L
    )
  )

cat(sprintf("Country-year panel: %d cells, %d countries, %d years\n",
            nrow(country_year),
            n_distinct(country_year$country),
            n_distinct(country_year$survey_year)))

# Check cell sizes
cat("\nCountry-year cell sizes:\n")
country_year %>%
  group_by(country) %>%
  summarise(
    years = n(),
    min_n = min(n_obs),
    median_n = median(n_obs),
    max_n = max(n_obs),
    mean_college = mean(pct_college, na.rm = TRUE)
  ) %>%
  arrange(desc(median_n)) %>%
  print(n = 25)

# ===========================================================================
# Create "recent arrivals" panel (entered within last 5 years)
# ===========================================================================

# This isolates the flow margin — people who actually entered recently
# YOEP gives year of entry; we keep those who arrived in the last 5 years

if ("YOEP" %in% names(acs_wa)) {
  recent <- acs_wa %>%
    filter(!is.na(YOEP), YOEP >= survey_year - 5, YOEP <= survey_year)

  recent_cy <- recent %>%
    group_by(country, POBP, survey_year, region, ineligible_from_dv_year,
             treated_country, first_treat) %>%
    summarise(
      pct_college = weighted.mean(college, w = PWGTP, na.rm = TRUE) * 100,
      pct_grad = weighted.mean(grad_degree, w = PWGTP, na.rm = TRUE) * 100,
      pct_hs = weighted.mean(hs_diploma, w = PWGTP, na.rm = TRUE) * 100,
      mean_ln_wage = weighted.mean(ln_wage, w = PWGTP, na.rm = TRUE),
      mean_age = weighted.mean(AGEP, w = PWGTP, na.rm = TRUE),
      pct_female = weighted.mean(female, w = PWGTP, na.rm = TRUE) * 100,
      n_obs = n(),
      total_weight = sum(PWGTP),
      .groups = "drop"
    ) %>%
    mutate(
      post = case_when(
        is.na(ineligible_from_dv_year) ~ 0L,
        survey_year >= ineligible_from_dv_year ~ 1L,
        TRUE ~ 0L
      )
    )

  cat(sprintf("\nRecent arrivals panel: %d cells\n", nrow(recent_cy)))

  # Cell sizes for recent arrivals
  cat("\nRecent arrivals cell sizes:\n")
  recent_cy %>%
    group_by(country) %>%
    summarise(
      years = n(),
      min_n = min(n_obs),
      median_n = median(n_obs),
      mean_college = mean(pct_college, na.rm = TRUE)
    ) %>%
    arrange(desc(median_n)) %>%
    print(n = 25)

  write_csv(recent_cy, file.path(data_dir, "recent_arrivals_panel.csv"))
} else {
  cat("WARNING: YOEP not available. Recent arrivals panel skipped.\n")
  recent_cy <- NULL
}

# ===========================================================================
# Save
# ===========================================================================

write_csv(country_year, file.path(data_dir, "country_year_panel.csv"))
write_csv(acs_wa, file.path(data_dir, "acs_working_age.csv"))

cat("\n=== Clean data complete ===\n")
cat(sprintf("  country_year_panel.csv: %d rows\n", nrow(country_year)))
if (!is.null(recent_cy)) {
  cat(sprintf("  recent_arrivals_panel.csv: %d rows\n", nrow(recent_cy)))
}
