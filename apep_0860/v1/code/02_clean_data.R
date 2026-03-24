# 02_clean_data.R — Merge datasets and construct analysis variables

library(tidyverse)

data_dir <- file.path(dirname(getwd()), "data")
load(file.path(data_dir, "loaded_data.RData"))

# --- State FIPS crosswalk ---
state_fips <- tibble(
  state_fips = c("01","02","04","05","06","08","09","10","11","12",
                 "13","15","16","17","18","19","20","21","22","23",
                 "24","25","26","27","28","29","30","31","32","33",
                 "34","35","36","37","38","39","40","41","42","44",
                 "45","46","47","48","49","50","51","53","54","55","56"),
  state_abb = c("AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL",
                "GA","HI","ID","IL","IN","IA","KS","KY","LA","ME",
                "MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
                "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI",
                "SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")
)

# --- Ensure state_fips is zero-padded string ---
scrap <- scrap %>%
  mutate(state_fips = str_pad(as.character(state_fips), 2, pad = "0"))

auto_repair <- auto_repair %>%
  mutate(state_fips = str_pad(as.character(state_fips), 2, pad = "0"))

auto_parts <- auto_parts %>%
  mutate(state_fips = str_pad(as.character(state_fips), 2, pad = "0"))

laws <- laws %>%
  mutate(state_fips = str_pad(as.character(state_fips), 2, pad = "0"))

# --- Determine treatment year ---
# Treatment onset = first full calendar year after enactment
# If law enacted in first half (month <= 6), treatment year = same year
# If enacted in second half (month >= 7), treatment year = next year
laws <- laws %>%
  mutate(treat_year = if_else(law_month <= 6, law_year, law_year + 1L))

cat("Treatment timing:\n")
print(table(laws$treat_year))

# --- Build analysis panel: scrap dealers ---
panel <- scrap %>%
  select(year, state_fips, estab, emp, payann) %>%
  left_join(state_fips, by = "state_fips") %>%
  left_join(laws %>% select(state_fips, treat_year, law_type), by = "state_fips") %>%
  left_join(palladium %>% select(year, avg_palladium), by = "year") %>%
  mutate(
    # Treatment indicator
    treated = !is.na(treat_year),
    post = if_else(treated, as.integer(year >= treat_year), 0L),
    # For CS-DiD: first_treat = treat_year for treated, 0 for never-treated
    first_treat = if_else(treated, treat_year, 0L),
    # Outcome variables (numeric)
    estab = as.numeric(estab),
    emp = as.numeric(emp),
    payann = as.numeric(payann),
    # Log outcomes (add 1 to handle zeros)
    log_estab = log(estab + 1),
    log_emp = log(emp + 1),
    # State numeric ID for DiD
    state_id = as.numeric(factor(state_fips)),
    # Standardized palladium price
    pd_std = (avg_palladium - mean(avg_palladium, na.rm = TRUE)) / sd(avg_palladium, na.rm = TRUE)
  )

# Drop DC (FIPS 11) - not a state, may have different dynamics
panel <- panel %>% filter(state_fips != "11")

# --- Build control industry panels ---
auto_repair_panel <- auto_repair %>%
  select(year, state_fips, estab, emp) %>%
  left_join(laws %>% select(state_fips, treat_year), by = "state_fips") %>%
  mutate(
    estab = as.numeric(estab),
    emp = as.numeric(emp),
    treated = !is.na(treat_year),
    post = if_else(treated, as.integer(year >= treat_year), 0L),
    first_treat = if_else(treated, treat_year, 0L),
    log_estab = log(estab + 1),
    state_id = as.numeric(factor(state_fips))
  ) %>%
  filter(state_fips != "11")

auto_parts_panel <- auto_parts %>%
  select(year, state_fips, estab, emp) %>%
  left_join(laws %>% select(state_fips, treat_year), by = "state_fips") %>%
  mutate(
    estab = as.numeric(estab),
    emp = as.numeric(emp),
    treated = !is.na(treat_year),
    post = if_else(treated, as.integer(year >= treat_year), 0L),
    first_treat = if_else(treated, treat_year, 0L),
    log_estab = log(estab + 1),
    state_id = as.numeric(factor(state_fips))
  ) %>%
  filter(state_fips != "11")

# --- Summary statistics ---
cat("\n--- Panel Summary ---\n")
cat("States:", n_distinct(panel$state_fips), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Treated states:", sum(panel$treated & panel$year == 2023), "\n")
cat("Never-treated states:", sum(!panel$treated & panel$year == 2023), "\n")
cat("Total obs:", nrow(panel), "\n")
cat("\nEstablishments (scrap dealers):\n")
cat("  Mean:", round(mean(panel$estab, na.rm = TRUE), 1), "\n")
cat("  SD:", round(sd(panel$estab, na.rm = TRUE), 1), "\n")
cat("  Min:", min(panel$estab, na.rm = TRUE), "Max:", max(panel$estab, na.rm = TRUE), "\n")

# --- Save ---
save(panel, auto_repair_panel, auto_parts_panel, palladium,
     file = file.path(data_dir, "analysis_panel.RData"))
cat("\nAnalysis panel saved.\n")
