# ==============================================================================
# 02_clean_data.R — Clean and merge all datasets
# apep_0535: Gas Tax Hikes and Macroeconomic Beliefs
# ==============================================================================

source("00_packages.R")

data_dir <- "../data"

# ==============================================================================
# 1. LOAD RAW DATA
# ==============================================================================

gas_tax <- fread(file.path(data_dir, "gas_tax_changes.csv"))
ces_raw <- readRDS(file.path(data_dir, "ces_cumulative.rds"))
state_unemp <- fread(file.path(data_dir, "state_unemployment.csv"))
state_income <- fread(file.path(data_dir, "state_personal_income.csv"))

# ==============================================================================
# 2. BUILD STATE-LEVEL TREATMENT PANEL
# ==============================================================================

# For states with multiple gas tax changes, use the FIRST discrete increase
# in the sample window as the treatment date (for CS-DiD cohort definition)
first_treatment <- gas_tax %>%
  group_by(state_abbr) %>%
  arrange(effective_date) %>%
  slice(1) %>%
  ungroup() %>%
  select(state_abbr, fips, treat_year, increase_cpg)

cat("First treatment by state:\n")
print(first_treatment %>% arrange(treat_year), n = 30)

# All 50 states + DC
all_states <- tibble(
  state_abbr = c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA",
                 "HI","ID","IL","IN","IA","KS","KY","LA","ME","MD",
                 "MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
                 "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC",
                 "SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC"),
  fips = c(1,2,4,5,6,8,9,10,12,13,15,16,17,18,19,20,21,22,23,24,
           25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,
           46,47,48,49,50,51,53,54,55,56,11)
)

# Merge treatment status onto all states
state_panel <- all_states %>%
  left_join(first_treatment %>% select(state_abbr, treat_year, increase_cpg),
            by = "state_abbr") %>%
  mutate(
    # For CS-DiD: never-treated states get first_treat = 0
    first_treat = replace_na(treat_year, 0),
    ever_treated = !is.na(treat_year)
  )

cat("\nTreatment summary:\n")
cat("  Treated states:", sum(state_panel$ever_treated), "\n")
cat("  Never-treated states:", sum(!state_panel$ever_treated), "\n")
cat("  Treatment cohorts:\n")
print(table(state_panel$treat_year[state_panel$ever_treated]))

# ==============================================================================
# 3. CLEAN CES DATA
# ==============================================================================

cat("\nCleaning CES data...\n")

# Identify the economy retrospection variable
if ("economy_retro" %in% names(ces_raw)) {
  econ_var <- "economy_retro"
} else {
  econ_vars <- grep("econom|retro", names(ces_raw), value = TRUE, ignore.case = TRUE)
  cat("  Available economy vars:", paste(econ_vars, collapse = ", "), "\n")
  econ_var <- econ_vars[1]
}

ces_clean <- ces_raw %>%
  as_tibble() %>%
  select(
    year,
    state_abbr = st,
    economy_retro = all_of(econ_var),
    any_of(c("county_fips", "gender", "race", "educ", "faminc_new",
             "pid3", "pid7", "birthyr", "age", "marstat", "ideo5",
             "newsint"))
  ) %>%
  filter(
    year >= 2006,
    !is.na(economy_retro),
    !is.na(state_abbr),
    nchar(as.character(state_abbr)) > 0
  ) %>%
  mutate(
    # Ensure economy_retro is numeric
    economy_retro = as.numeric(economy_retro)
  ) %>%
  # Drop category 6 ("Don't know" / "Not sure") — only valid responses 1-5
  filter(economy_retro >= 1, economy_retro <= 5) %>%
  mutate(
    # Standard CES coding: 1=much better, 2=somewhat better, 3=same, 4=somewhat worse, 5=much worse
    pessimism = economy_retro,
    # Binary: pessimistic (4 or 5) vs not
    pessimistic = as.integer(economy_retro >= 4),
    # State abbreviation as character
    state_abbr = as.character(state_abbr)
  )

# Add demographics where available
if ("birthyr" %in% names(ces_clean)) {
  ces_clean <- ces_clean %>%
    mutate(age = year - as.numeric(birthyr))
}

# Create age cohort (for Malmendier-Nagel experience hypothesis)
if ("age" %in% names(ces_clean)) {
  ces_clean <- ces_clean %>%
    mutate(
      age_group = case_when(
        age < 30 ~ "18-29",
        age < 45 ~ "30-44",
        age < 60 ~ "45-59",
        age >= 60 ~ "60+",
        TRUE ~ NA_character_
      ),
      experienced_70s = as.integer(age >= 55)  # born before ~1970, experienced oil crises
    )
}

# Party ID (simplified)
if ("pid3" %in% names(ces_clean)) {
  ces_clean <- ces_clean %>%
    mutate(
      party = case_when(
        as.numeric(pid3) == 1 ~ "Democrat",
        as.numeric(pid3) == 2 ~ "Republican",
        as.numeric(pid3) == 3 ~ "Independent",
        TRUE ~ "Other"
      )
    )
}

# Education (simplified)
if ("educ" %in% names(ces_clean)) {
  ces_clean <- ces_clean %>%
    mutate(
      college = as.integer(as.numeric(educ) >= 5)  # BA or higher
    )
}

# Income (simplified)
if ("faminc_new" %in% names(ces_clean)) {
  ces_clean <- ces_clean %>%
    mutate(
      low_income = as.integer(as.numeric(faminc_new) <= 4)  # below ~$40K
    )
}

cat("CES cleaned:", nrow(ces_clean), "observations\n")
cat("  Years:", min(ces_clean$year), "-", max(ces_clean$year), "\n")
cat("  States:", n_distinct(ces_clean$state_abbr), "\n")
cat("  Economy retro distribution:\n")
print(table(ces_clean$economy_retro, useNA = "ifany"))

# ==============================================================================
# 4. MERGE CES WITH TREATMENT AND CONTROLS
# ==============================================================================

# Annual state unemployment (average over months Sept-Nov to match CES timing)
annual_unemp <- state_unemp %>%
  filter(month %in% 9:11) %>%
  group_by(state_abbr, year) %>%
  summarize(unemp_rate = mean(unemp_rate, na.rm = TRUE), .groups = "drop")

# Annual state personal income growth
income_growth <- state_income %>%
  arrange(fips, year) %>%
  group_by(fips) %>%
  mutate(income_growth = (personal_income - lag(personal_income)) / lag(personal_income) * 100) %>%
  ungroup() %>%
  left_join(all_states, by = "fips") %>%
  select(state_abbr, year, income_growth)

# Merge everything
ces_analysis <- ces_clean %>%
  left_join(state_panel %>% select(state_abbr, first_treat, ever_treated, increase_cpg),
            by = "state_abbr") %>%
  left_join(annual_unemp, by = c("state_abbr", "year")) %>%
  left_join(income_growth, by = c("state_abbr", "year")) %>%
  mutate(
    # Post-treatment indicator
    post = as.integer(year >= first_treat & first_treat > 0),
    # Relative time to treatment (for event study)
    rel_time = ifelse(first_treat > 0, year - first_treat, NA_integer_),
    # State numeric ID for fixest
    state_id = as.integer(factor(state_abbr))
  )

cat("\nMerged analysis dataset:\n")
cat("  Observations:", nrow(ces_analysis), "\n")
cat("  Treated obs (post):", sum(ces_analysis$post, na.rm = TRUE), "\n")
cat("  Control obs:", sum(ces_analysis$post == 0, na.rm = TRUE), "\n")
cat("  States with unemployment data:", sum(!is.na(ces_analysis$unemp_rate)) / nrow(ces_analysis) * 100, "%\n")
cat("  States with income data:", sum(!is.na(ces_analysis$income_growth)) / nrow(ces_analysis) * 100, "%\n")

# ==============================================================================
# 5. BUILD GOOGLE TRENDS STATE-YEAR PANEL
# ==============================================================================

cat("\nBuilding Google Trends panel...\n")

gtrends_inflation_file <- file.path(data_dir, "gtrends_state_inflation.csv")
gtrends_recession_file <- file.path(data_dir, "gtrends_state_recession.csv")

if (file.exists(gtrends_inflation_file)) {
  gt_inflation <- fread(gtrends_inflation_file)

  # State name to abbreviation crosswalk
  state_xwalk <- tibble(
    state_name = state.name,
    state_abbr = state.abb
  ) %>% add_row(state_name = "District of Columbia", state_abbr = "DC")

  gt_panel <- gt_inflation %>%
    left_join(state_xwalk, by = c("location" = "state_name")) %>%
    filter(!is.na(state_abbr)) %>%
    mutate(hits = as.numeric(hits)) %>%
    select(state_abbr, year, inflation_search = hits) %>%
    left_join(state_panel %>% select(state_abbr, first_treat, ever_treated),
              by = "state_abbr") %>%
    left_join(annual_unemp, by = c("state_abbr", "year")) %>%
    mutate(
      post = as.integer(year >= first_treat & first_treat > 0),
      rel_time = ifelse(first_treat > 0, year - first_treat, NA_integer_),
      state_id = as.integer(factor(state_abbr))
    )

  cat("Google Trends panel:", nrow(gt_panel), "state-years\n")
  fwrite(gt_panel, file.path(data_dir, "gtrends_analysis.csv"))
}

# Add recession searches if available
if (file.exists(gtrends_recession_file)) {
  gt_recession <- fread(gtrends_recession_file) %>%
    left_join(state_xwalk, by = c("location" = "state_name")) %>%
    filter(!is.na(state_abbr)) %>%
    mutate(recession_search = as.numeric(hits)) %>%
    select(state_abbr, year, recession_search)

  if (exists("gt_panel")) {
    gt_panel <- gt_panel %>%
      left_join(gt_recession, by = c("state_abbr", "year"))
    fwrite(gt_panel, file.path(data_dir, "gtrends_analysis.csv"))
  }
}

# ==============================================================================
# 6. BUILD FIRST-STAGE DATA (EIA SEDS)
# ==============================================================================

eia_file <- file.path(data_dir, "eia_seds_gas_prices.csv")
if (file.exists(eia_file)) {
  eia <- fread(eia_file) %>%
    left_join(state_panel %>% select(state_abbr, first_treat, ever_treated),
              by = "state_abbr") %>%
    mutate(
      post = as.integer(year >= first_treat & first_treat > 0),
      rel_time = ifelse(first_treat > 0, year - first_treat, NA_integer_),
      state_id = as.integer(factor(state_abbr))
    )
  fwrite(eia, file.path(data_dir, "eia_analysis.csv"))
  cat("EIA first-stage panel:", nrow(eia), "state-years\n")
}

# ==============================================================================
# 7. SAVE MAIN ANALYSIS DATASET
# ==============================================================================

fwrite(ces_analysis, file.path(data_dir, "ces_analysis.csv"))
cat("\n=== ANALYSIS DATA SAVED ===\n")

# Summary statistics
cat("\n=== SUMMARY STATISTICS ===\n")
cat("CES economy_retro (1=much better ... 5=much worse):\n")
cat("  Mean:", round(mean(ces_analysis$pessimism, na.rm = TRUE), 3), "\n")
cat("  SD:", round(sd(ces_analysis$pessimism, na.rm = TRUE), 3), "\n")
cat("  % pessimistic (4 or 5):", round(mean(ces_analysis$pessimistic, na.rm = TRUE) * 100, 1), "%\n")
cat("\nBy treatment status:\n")
ces_analysis %>%
  group_by(ever_treated) %>%
  summarize(
    n = n(),
    mean_pessimism = round(mean(pessimism, na.rm = TRUE), 3),
    pct_pessimistic = round(mean(pessimistic, na.rm = TRUE) * 100, 1)
  ) %>%
  print()
