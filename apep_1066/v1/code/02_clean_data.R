## 02_clean_data.R — Clean and construct analysis panel for CROWN Act
## apep_1066 v1

source("00_packages.R")
load("../data/raw_acs.RData")

## ---- Clean earnings data ----
clean_earnings <- function(df, race_label) {
  df %>%
    transmute(
      state_fips = state,
      state_name = NAME,
      year = as.integer(year),
      race = race_label,
      earn_total = as.numeric(get(grep("_001E$", names(.), value = TRUE))),
      earn_male = as.numeric(get(grep("_002E$", names(.), value = TRUE))),
      earn_female = as.numeric(get(grep("_005E$", names(.), value = TRUE)))
    ) %>%
    filter(!is.na(earn_total), earn_total > 0)
}

earn_black <- clean_earnings(black_earn, "Black")
earn_white <- clean_earnings(white_earn, "White")
earnings <- bind_rows(earn_black, earn_white)

## ---- Clean employment data ----
clean_employment <- function(df, race_label) {
  df %>%
    transmute(
      state_fips = state,
      state_name = NAME,
      year = as.integer(year),
      race = race_label,
      pop_total = as.numeric(get(grep("_001E$", names(.), value = TRUE))),
      male_pop_1664 = as.numeric(get(grep("_003E$", names(.), value = TRUE))),
      male_employed = as.numeric(get(grep("_006E$", names(.), value = TRUE))),
      female_pop_1664 = as.numeric(get(grep("_016E$", names(.), value = TRUE))),
      female_employed = as.numeric(get(grep("_019E$", names(.), value = TRUE)))
    ) %>%
    mutate(
      emp_rate_male = ifelse(male_pop_1664 > 0, male_employed / male_pop_1664, NA_real_),
      emp_rate_female = ifelse(female_pop_1664 > 0, female_employed / female_pop_1664, NA_real_)
    ) %>%
    ## Drop states with tiny populations where rates are unreliable
    filter(!is.na(pop_total), pop_total > 100) %>%
    ## Cap rates at 1 (rounding/sampling can push above)
    mutate(
      emp_rate_male = pmin(emp_rate_male, 1, na.rm = TRUE),
      emp_rate_female = pmin(emp_rate_female, 1, na.rm = TRUE)
    )
}

emp_black <- clean_employment(black_emp, "Black")
emp_white <- clean_employment(white_emp, "White")
employment <- bind_rows(emp_black, emp_white)

## ---- Merge treatment assignment ----
## All states — those not in crown_states are never-treated (crown_year = Inf for CS)
all_states <- earnings %>%
  distinct(state_fips, state_name) %>%
  left_join(crown_states %>% select(state_fips, crown_year), by = "state_fips") %>%
  mutate(
    crown_year = replace_na(crown_year, 0),  # 0 = never-treated for CS
    ever_treated = crown_year > 0
  )

## ---- Build long panel: state × year × race × sex ----
## Earnings panel (long by sex)
earn_long <- earnings %>%
  pivot_longer(
    cols = c(earn_male, earn_female),
    names_to = "sex",
    values_to = "median_earnings",
    names_prefix = "earn_"
  ) %>%
  select(state_fips, state_name, year, race, sex, median_earnings) %>%
  filter(!is.na(median_earnings), median_earnings > 0)

## Employment panel (long by sex)
emp_long <- employment %>%
  select(state_fips, state_name, year, race,
         emp_rate_male, emp_rate_female) %>%
  pivot_longer(
    cols = c(emp_rate_male, emp_rate_female),
    names_to = "sex",
    values_to = "emp_rate",
    names_prefix = "emp_rate_"
  ) %>%
  filter(!is.na(emp_rate))

## Merge earnings and employment
panel <- earn_long %>%
  left_join(emp_long, by = c("state_fips", "state_name", "year", "race", "sex")) %>%
  left_join(all_states %>% select(state_fips, crown_year, ever_treated),
            by = "state_fips")

## ---- Construct key variables ----
panel <- panel %>%
  mutate(
    ## Numeric identifiers for FE
    state_id = as.numeric(factor(state_fips)),
    ## Black indicator
    black = as.integer(race == "Black"),
    ## Female indicator
    female = as.integer(sex == "female"),
    ## Treatment active: state adopted CROWN Act in or before this year
    crown_active = as.integer(crown_year > 0 & year >= crown_year),
    ## DDD interaction: CROWN × Black
    crown_black = crown_active * black,
    ## Full DDD: CROWN × Black × Female
    crown_black_female = crown_active * black * female,
    ## Log earnings
    log_earn = log(median_earnings),
    ## Group variable for CS: first_treat (0 for never-treated)
    first_treat = crown_year,
    ## Demographic group ID (for CS panel)
    demo_group = paste(race, sex, sep = "_"),
    demo_id = as.numeric(factor(demo_group)),
    ## Panel unit: state × demographic group
    unit_id = state_id * 10 + demo_id
  )

## ---- Summary statistics ----
cat("\n=== Panel Summary ===\n")
cat(sprintf("Total observations: %d\n", nrow(panel)))
cat(sprintf("States: %d\n", n_distinct(panel$state_fips)))
cat(sprintf("Years: %s\n", paste(sort(unique(panel$year)), collapse = ", ")))
cat(sprintf("Treated states: %d\n", sum(all_states$ever_treated)))
cat(sprintf("Never-treated states: %d\n", sum(!all_states$ever_treated)))
cat(sprintf("Race groups: %s\n", paste(unique(panel$race), collapse = ", ")))
cat(sprintf("Sex groups: %s\n", paste(unique(panel$sex), collapse = ", ")))

## Verify treatment counts
cat("\n=== Treatment cohort sizes ===\n")
all_states %>%
  filter(ever_treated) %>%
  count(crown_year) %>%
  print()

## ---- Save clean panel ----
save(panel, all_states, file = "../data/analysis_panel.RData")
cat("\nClean panel saved to data/analysis_panel.RData\n")
