# ==============================================================================
# 02_clean_data.R — Construct analysis panel
# Paper: The Racial Dividend of the Warehouse Boom (apep_1300)
# ==============================================================================

source("00_packages.R")

# Load data
treatment <- readRDS("../data/treatment_timing.rds")
qwi <- readRDS("../data/qwi_warehousing_race.rds")
qwi_placebo <- readRDS("../data/qwi_placebo_race.rds")

cat("Treatment counties:", nrow(treatment), "\n")
cat("QWI rows:", nrow(qwi), "\n")

# ---------- Clean QWI ---------------------------------------------------------

# Pad county FIPS to 5 digits
qwi <- qwi %>%
  mutate(county_fips = sprintf("%05d", as.integer(county_fips)))

qwi_placebo <- qwi_placebo %>%
  mutate(county_fips = sprintf("%05d", as.integer(county_fips)))

treatment <- treatment %>%
  mutate(county_fips = sprintf("%05d", as.integer(county_fips)))

# Map race codes to labels
# QWI race codes: A0 = All, A1 = White, A2 = Black, A3 = AIAN,
#                 A4 = Asian, A5 = NHPI, A7 = Not Available
race_labels <- c(
  "A0" = "All", "A1" = "White Alone", "A2" = "Black Alone",
  "A3" = "AIAN", "A4" = "Asian Alone", "A5" = "NHPI",
  "A7" = "Not Available"
)

qwi <- qwi %>%
  mutate(race_label = race_labels[race])

# Focus on main racial groups for analysis
qwi_main <- qwi %>%
  filter(race %in% c("A0", "A1", "A2", "A4")) %>%
  mutate(
    race_group = case_when(
      race == "A0" ~ "All",
      race == "A1" ~ "White",
      race == "A2" ~ "Black",
      race == "A4" ~ "Asian"
    )
  )

qwi_placebo_main <- qwi_placebo %>%
  filter(race %in% c("A0", "A1", "A2")) %>%
  mutate(
    race_group = case_when(
      race == "A0" ~ "All",
      race == "A1" ~ "White",
      race == "A2" ~ "Black"
    )
  )

# Aggregate to annual level for Callaway-Sant'Anna
# (CS `did` package works best with annual data)
qwi_annual <- qwi_main %>%
  group_by(county_fips, year, race_group) %>%
  summarise(
    employment = mean(employment, na.rm = TRUE),
    avg_earnings = mean(avg_earnings, na.rm = TRUE),
    hires_all = mean(hires_all, na.rm = TRUE),
    hires_new = mean(hires_new, na.rm = TRUE),
    separations = mean(separations, na.rm = TRUE),
    turnover = mean(turnover, na.rm = TRUE),
    .groups = "drop"
  )

qwi_placebo_annual <- qwi_placebo_main %>%
  group_by(county_fips, year, race_group) %>%
  summarise(
    employment = mean(employment, na.rm = TRUE),
    avg_earnings = mean(avg_earnings, na.rm = TRUE),
    .groups = "drop"
  )

# ---------- Merge treatment into panel ----------------------------------------

# Create first_treat variable (0 for never-treated)
panel <- qwi_annual %>%
  left_join(treatment %>% select(county_fips, first_fc_year, n_fcs), by = "county_fips") %>%
  mutate(
    treated_county = !is.na(first_fc_year),
    # For CS DiD: first_treat = 0 means never treated
    first_treat = ifelse(is.na(first_fc_year), 0, first_fc_year),
    # Post indicator
    post = ifelse(treated_county & year >= first_fc_year, 1, 0),
    # Log outcomes (handle zeros)
    log_emp = log(pmax(employment, 1)),
    log_earn = log(pmax(avg_earnings, 1)),
    log_hires = log(pmax(hires_all, 1))
  )

# Placebo panel
panel_placebo <- qwi_placebo_annual %>%
  left_join(treatment %>% select(county_fips, first_fc_year), by = "county_fips") %>%
  mutate(
    first_treat = ifelse(is.na(first_fc_year), 0, first_fc_year),
    log_emp = log(pmax(employment, 1))
  )

# ---------- Summary statistics ------------------------------------------------

cat("\n=== Panel Summary ===\n")
cat("Total county-year-race obs:", nrow(panel), "\n")
cat("Unique counties:", n_distinct(panel$county_fips), "\n")
cat("Year range:", min(panel$year), "-", max(panel$year), "\n")
cat("Treated counties:", sum(panel$treated_county & panel$race_group == "All" & panel$year == 2010), "\n")
cat("Control counties:", sum(!panel$treated_county & panel$race_group == "All" & panel$year == 2010), "\n")

# Treatment cohort distribution
cat("\nTreatment cohort sizes:\n")
cohort_table <- panel %>%
  filter(race_group == "All", year == 2010) %>%
  filter(first_treat > 0) %>%
  count(first_treat)
print(cohort_table)

# Pre-treatment means by race and treatment status
cat("\nPre-treatment means (2001-2007):\n")
pre_means <- panel %>%
  filter(year <= 2007) %>%
  group_by(race_group, treated_county) %>%
  summarise(
    mean_emp = mean(employment, na.rm = TRUE),
    mean_earn = mean(avg_earnings, na.rm = TRUE),
    mean_hires = mean(hires_all, na.rm = TRUE),
    n_counties = n_distinct(county_fips),
    .groups = "drop"
  )
print(pre_means)

# Compute pre-treatment SD of outcomes for SDE calculation later
pre_sd <- panel %>%
  filter(year < first_treat | first_treat == 0, year <= 2009) %>%
  group_by(race_group) %>%
  summarise(
    sd_log_emp = sd(log_emp, na.rm = TRUE),
    sd_log_earn = sd(log_earn, na.rm = TRUE),
    sd_log_hires = sd(log_hires, na.rm = TRUE),
    .groups = "drop"
  )
cat("\nPre-treatment SDs (for SDE calculation):\n")
print(pre_sd)

# ---------- Save analysis datasets --------------------------------------------

saveRDS(panel, "../data/analysis_panel.rds")
saveRDS(panel_placebo, "../data/analysis_panel_placebo.rds")
saveRDS(pre_sd, "../data/pre_treatment_sd.rds")
saveRDS(pre_means, "../data/pre_treatment_means.rds")

cat("\nAnalysis panel saved.\n")
