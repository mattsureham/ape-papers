## ============================================================
## 02_clean_data.R — Construct analysis-ready panel
## apep_0580: Civil Asset Forfeiture Reform and Police Reallocation
## ============================================================

source("00_packages.R")

data_dir <- "../data"

cat("=== Loading raw data ===\n")

# Reform coding
reform <- fread(file.path(data_dir, "reform_coding.csv"))
cat("  Reform coding:", nrow(reform), "states\n")

# Population
pop <- fread(file.path(data_dir, "state_population.csv"))
cat("  Population:", nrow(pop), "state-years\n")

# Forfeiture intensity
forfeiture <- fread(file.path(data_dir, "forfeiture_intensity.csv"))
cat("  Forfeiture intensity:", nrow(forfeiture), "states\n")

# CDC drug overdose data (Source A: NCHS 2004-2015)
drug_raw <- fread(file.path(data_dir, "cdc_drug_overdose_raw.csv"))
cat("  Drug overdose raw (NCHS):", nrow(drug_raw), "rows\n")
cat("  Columns:", paste(names(drug_raw), collapse = ", "), "\n")

# VSRR data (Source B: 2016-2020) if available
vsrr_file <- file.path(data_dir, "vsrr_drug_overdose_raw.csv")
has_vsrr <- file.exists(vsrr_file) && file.size(vsrr_file) > 100
if (has_vsrr) {
  vsrr_raw <- fread(vsrr_file)
  cat("  VSRR drug overdose:", nrow(vsrr_raw), "rows\n")
}

# ============================================================
# Clean CDC Drug Overdose Data
# ============================================================

cat("\n=== Cleaning drug overdose data ===\n")

# The NCHS Drug Poisoning dataset (jx6g-fdh6) contains:
# state, year, sex, age_group, race_and_hispanic_origin, deaths, population,
# crude_death_rate, standard_error, low_confidence_limit, upper_confidence_limit

# Standardize column names (may vary by Socrata format)
drug <- drug_raw %>%
  mutate(
    year = as.integer(year),
    state_name = as.character(state)
  )

# Check available columns and adapt
cat("  Drug data columns:", paste(names(drug), collapse = ", "), "\n")
cat("  Years:", paste(sort(unique(drug$year)), collapse = ", "), "\n")
cat("  Sample states:", paste(head(unique(drug$state_name), 5), collapse = ", "), "\n")

# Get the death rate column (may be named differently)
rate_cols <- grep("rate|deaths", names(drug), value = TRUE, ignore.case = TRUE)
cat("  Rate/death columns:", paste(rate_cols, collapse = ", "), "\n")

# Create state abbreviation mapping
state_name_to_abbr <- data.frame(
  state_name = c(state.name, "District of Columbia"),
  state_abbr = c(state.abb, "DC"),
  stringsAsFactors = FALSE
)

# Aggregate to state-year level (in case there are demographic breakdowns)
# Use the overall rate (all demographics)
if ("sex" %in% names(drug)) {
  # Filter to total (both sexes) if available
  drug_total <- drug %>%
    filter(tolower(sex) %in% c("both sexes", "total", "both", "all"))
} else {
  drug_total <- drug
}

if ("age_group" %in% names(drug_total)) {
  drug_total <- drug_total %>%
    filter(tolower(age_group) %in% c("all ages", "total", "all"))
}

if ("race_and_hispanic_origin" %in% names(drug_total)) {
  drug_total <- drug_total %>%
    filter(tolower(race_and_hispanic_origin) %in% c("all races", "total", "all races and origins"))
}

cat("  After filtering to totals:", nrow(drug_total), "rows\n")

# Extract the death rate
if ("crude_death_rate" %in% names(drug_total)) {
  drug_clean <- drug_total %>%
    select(state_name, year,
           drug_death_rate = crude_death_rate) %>%
    mutate(drug_death_rate = as.numeric(drug_death_rate))
} else if ("model_based_death_rate" %in% names(drug_total)) {
  drug_clean <- drug_total %>%
    select(state_name, year,
           drug_death_rate = model_based_death_rate) %>%
    mutate(drug_death_rate = as.numeric(drug_death_rate))
} else {
  # Use whatever rate column is available
  drug_clean <- drug_total %>%
    mutate(drug_death_rate = as.numeric(get(rate_cols[1]))) %>%
    select(state_name, year, drug_death_rate)
}

# Add state abbreviations
drug_clean <- drug_clean %>%
  left_join(state_name_to_abbr, by = "state_name") %>%
  filter(!is.na(state_abbr), year >= 2004, year <= 2020) %>%
  select(state_abbr, year, drug_death_rate)

cat("  Clean NCHS drug data:", nrow(drug_clean), "state-years\n")
cat("  NCHS years:", paste(sort(unique(drug_clean$year)), collapse=", "), "\n")

# Append VSRR data for 2016-2020 (compute rate from counts + population)
if (has_vsrr) {
  cat("  Processing VSRR data for 2016-2020...\n")
  vsrr_clean <- vsrr_raw %>%
    filter(!is.na(data_value), data_value != "") %>%
    mutate(
      year = as.integer(year),
      deaths = as.numeric(data_value),
      state_name = state_name
    ) %>%
    left_join(state_name_to_abbr, by = "state_name") %>%
    filter(!is.na(state_abbr), year >= 2016, year <= 2020) %>%
    select(state_abbr, year, deaths)

  # Merge with population to compute rate per 100K
  state_fips_map <- reform %>% select(state_abbr, state_fips)

  vsrr_rates <- vsrr_clean %>%
    left_join(state_fips_map, by = "state_abbr") %>%
    left_join(pop, by = c("state_fips", "year")) %>%
    filter(!is.na(population), population > 0) %>%
    mutate(drug_death_rate = (deaths / population) * 100000) %>%
    select(state_abbr, year, drug_death_rate)

  cat("  VSRR rates computed:", nrow(vsrr_rates), "state-years\n")

  # Combine: use NCHS for 2004-2015, VSRR for 2016-2020
  drug_clean <- bind_rows(
    drug_clean %>% filter(year <= 2015),
    vsrr_rates %>% filter(year >= 2016)
  )
  cat("  Combined drug data:", nrow(drug_clean), "state-years\n")
  cat("  Combined years:", paste(sort(unique(drug_clean$year)), collapse=", "), "\n")
}

# ============================================================
# Clean Homicide Data (if available)
# ============================================================

cat("\n=== Cleaning homicide data ===\n")

homicide_clean <- NULL

if (file.exists(file.path(data_dir, "cdc_homicide_raw.csv"))) {
  hom_raw <- fread(file.path(data_dir, "cdc_homicide_raw.csv"))
  cat("  Homicide raw:", nrow(hom_raw), "rows\n")
  cat("  Columns:", paste(names(hom_raw), collapse = ", "), "\n")

  # Process similarly to drug data
  # The injury mortality dataset has columns like:
  # year, sex, race, age_group, injury_mechanism, injury_intent, deaths, population, age_adjusted_rate

  if ("injury_intent" %in% names(hom_raw)) {
    hom_data <- hom_raw %>%
      filter(tolower(injury_intent) == "homicide") %>%
      mutate(year = as.integer(year))
  } else {
    hom_data <- hom_raw
  }

  # Get state-level rates
  if ("state" %in% names(hom_data)) {
    hom_rate_col <- intersect(c("age_adjusted_rate", "crude_rate", "death_rate"),
                               names(hom_data))
    if (length(hom_rate_col) > 0) {
      homicide_clean <- hom_data %>%
        mutate(
          state_name = state,
          homicide_rate = as.numeric(get(hom_rate_col[1])),
          year = as.integer(year)
        ) %>%
        left_join(state_name_to_abbr, by = "state_name") %>%
        filter(!is.na(state_abbr), year >= 2004, year <= 2020) %>%
        group_by(state_abbr, year) %>%
        summarize(homicide_rate = mean(homicide_rate, na.rm = TRUE), .groups = "drop")

      cat("  Clean homicide data:", nrow(homicide_clean), "state-years\n")
    }
  }
}

if (is.null(homicide_clean)) {
  cat("  No homicide-specific data. Extracting from leading causes if available.\n")

  if (file.exists(file.path(data_dir, "cdc_leading_causes_raw.csv"))) {
    lc <- fread(file.path(data_dir, "cdc_leading_causes_raw.csv"))
    cat("  Leading causes:", nrow(lc), "rows\n")

    # Find assault/homicide
    assault_causes <- lc %>%
      filter(grepl("assault|homicide", cause_name, ignore.case = TRUE))

    if (nrow(assault_causes) > 0) {
      homicide_clean <- assault_causes %>%
        mutate(
          year = as.integer(year),
          state_name = state,
          deaths = as.numeric(deaths),
          homicide_rate = as.numeric(age_adjusted_death_rate)
        ) %>%
        left_join(state_name_to_abbr, by = "state_name") %>%
        filter(!is.na(state_abbr), year >= 2004, year <= 2020) %>%
        select(state_abbr, year, homicide_rate, deaths) %>%
        rename(homicide_deaths = deaths)

      cat("  Extracted homicide data:", nrow(homicide_clean), "state-years\n")
    }
  }
}

# ============================================================
# Construct Analysis Panel
# ============================================================

cat("\n=== Building analysis panel ===\n")

# Base panel: all states × years
panel <- expand.grid(
  state_abbr = unique(reform$state_abbr),
  year = 2004:2020,
  stringsAsFactors = FALSE
) %>%
  # Add reform information
  left_join(reform %>% select(state_abbr, state_fips, reform_year, reform_type,
                               ever_reformed, first_treat),
            by = "state_abbr") %>%
  # Add population
  left_join(pop, by = c("state_fips", "year")) %>%
  # Add forfeiture intensity
  left_join(forfeiture, by = "state_abbr") %>%
  # Add drug death rates
  left_join(drug_clean, by = c("state_abbr", "year"))

# Add homicide data if available
if (!is.null(homicide_clean)) {
  panel <- panel %>%
    left_join(homicide_clean %>% select(state_abbr, year, homicide_rate),
              by = c("state_abbr", "year"))
}

# Construct treatment variables
panel <- panel %>%
  mutate(
    # Treatment indicators
    treated = ever_reformed & year >= reform_year,
    post = ifelse(reform_year > 0, year >= reform_year, FALSE),
    rel_time = ifelse(reform_year > 0, year - reform_year, NA_real_),

    # Reform intensity (for dose-response)
    reform_intensity = case_when(
      reform_type == 3 ~ "Abolition",
      reform_type == 2 ~ "Conviction required",
      reform_type == 1 ~ "Transparency",
      TRUE ~ "No reform"
    ),
    reform_intensity = factor(reform_intensity,
                               levels = c("No reform", "Transparency",
                                          "Conviction required", "Abolition")),

    # Log outcomes
    log_drug_death_rate = log(drug_death_rate + 0.1),

    # High forfeiture indicator (above median)
    high_forfeiture = eq_sharing_per_capita > median(eq_sharing_per_capita, na.rm = TRUE),

    # Region (Census divisions)
    region = case_when(
      state_abbr %in% c("CT","ME","MA","NH","RI","VT") ~ "New England",
      state_abbr %in% c("NJ","NY","PA") ~ "Mid-Atlantic",
      state_abbr %in% c("IL","IN","MI","OH","WI") ~ "East North Central",
      state_abbr %in% c("IA","KS","MN","MO","NE","ND","SD") ~ "West North Central",
      state_abbr %in% c("DE","FL","GA","MD","NC","SC","VA","WV","DC") ~ "South Atlantic",
      state_abbr %in% c("AL","KY","MS","TN") ~ "East South Central",
      state_abbr %in% c("AR","LA","OK","TX") ~ "West South Central",
      state_abbr %in% c("AZ","CO","ID","MT","NV","NM","UT","WY") ~ "Mountain",
      state_abbr %in% c("AK","CA","HI","OR","WA") ~ "Pacific",
      TRUE ~ "Other"
    )
  )

# Add homicide rate if available
if ("homicide_rate" %in% names(panel)) {
  panel <- panel %>%
    mutate(log_homicide_rate = log(homicide_rate + 0.1))
}

cat("  Panel:", nrow(panel), "state-years\n")
cat("  States:", n_distinct(panel$state_abbr), "\n")
cat("  Years:", min(panel$year), "-", max(panel$year), "\n")
cat("  Treated obs:", sum(panel$treated, na.rm=TRUE), "\n")
cat("  Drug death rate: mean=", round(mean(panel$drug_death_rate, na.rm=TRUE), 1),
    " sd=", round(sd(panel$drug_death_rate, na.rm=TRUE), 1), "\n")

# Summary by reform status
cat("\n  By reform status:\n")
panel %>%
  group_by(ever_reformed) %>%
  summarize(
    n_states = n_distinct(state_abbr),
    mean_drug_rate = mean(drug_death_rate, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  print()

# Save
fwrite(panel, file.path(data_dir, "analysis_panel.csv"))
cat("\n  Saved: analysis_panel.csv\n")

# ============================================================
# Summary Statistics
# ============================================================

cat("\n=== Summary Statistics ===\n")

summ <- panel %>%
  filter(year >= 2004, year <= 2020) %>%
  group_by(ever_reformed) %>%
  summarize(
    n_states = n_distinct(state_abbr),
    n_obs = n(),
    mean_drug_death_rate = round(mean(drug_death_rate, na.rm = TRUE), 2),
    sd_drug_death_rate = round(sd(drug_death_rate, na.rm = TRUE), 2),
    mean_eq_sharing = round(mean(eq_sharing_per_capita, na.rm = TRUE), 2),
    mean_population = round(mean(population, na.rm = TRUE) / 1e6, 2),
    .groups = "drop"
  )

print(summ)

# Save summary stats
fwrite(summ, file.path(data_dir, "summary_stats.csv"))

cat("\n=== DATA CLEANING COMPLETE ===\n")
