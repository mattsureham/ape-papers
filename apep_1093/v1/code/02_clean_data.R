# 02_clean_data.R — Clean and construct analysis variables
# Pay Transparency Laws and the Racial New-Hire Earnings Gap

source("00_packages.R")

# ---- Load data ----
df_raw <- readRDS("../data/qwi_raw.rds")
treatment_states <- read.csv("../data/treatment_states.csv", colClasses = c(state_fips = "character"))

cat(sprintf("Raw data: %s rows\n", format(nrow(df_raw), big.mark = ",")))

# ---- Construct identifiers ----
df <- df_raw %>%
  mutate(
    state_fips = substr(sprintf("%05d", as.integer(geography)), 1, 2),
    county_fips = sprintf("%05d", as.integer(geography)),
    yq = year * 10L + as.integer(quarter),
    # Numeric time index (quarters since 2018Q1)
    time_index = (year - 2018L) * 4L + as.integer(quarter),
    # Race labels
    race = case_when(
      race == "A1" ~ "White",
      race == "A2" ~ "Black",
      TRUE ~ NA_character_
    ),
    # Industry classification for DDD
    high_dispersion = as.integer(industry %in% c("541", "522", "511")),
    industry_label = case_when(
      industry == "541" ~ "Professional Services",
      industry == "522" ~ "Credit Intermediation",
      industry == "511" ~ "Publishing/Info",
      industry == "722" ~ "Food Services",
      industry == "445" ~ "Food/Beverage Stores",
      industry == "721" ~ "Accommodation",
      industry == "611" ~ "Education",
      industry == "621" ~ "Healthcare",
      industry == "238" ~ "Specialty Contractors",
      industry == "423" ~ "Wholesale Durable",
      industry == "561" ~ "Admin/Support",
      industry == "812" ~ "Personal Services",
      TRUE ~ as.character(industry)
    )
  ) %>%
  filter(!is.na(race))

# ---- Merge treatment status ----
df <- df %>%
  left_join(
    treatment_states %>% select(state_fips, adopt_yq, state_abbr),
    by = "state_fips"
  ) %>%
  mutate(
    # Treatment indicator
    treated_state = as.integer(!is.na(adopt_yq)),
    # Post-treatment indicator (state-specific timing)
    post = as.integer(!is.na(adopt_yq) & yq >= adopt_yq),
    # For CS-DiD: first_treat as time_index of adoption
    first_treat = case_when(
      is.na(adopt_yq) ~ 0L,  # never-treated
      TRUE ~ {
        adopt_yr <- adopt_yq %/% 10
        adopt_qt <- adopt_yq %% 10
        (adopt_yr - 2018L) * 4L + adopt_qt
      }
    )
  )

# ---- Drop suppressed cells ----
# QWI flags: 's' in status columns means suppressed
# Remove rows where earnings are NA or zero (suppressed)
n_before <- nrow(df)
df <- df %>%
  filter(
    !is.na(EarnHirAS) & EarnHirAS > 0,
    !is.na(HirA) & HirA > 0
  )
cat(sprintf("Dropped %s suppressed/zero rows (%.1f%%)\n",
    format(n_before - nrow(df), big.mark = ","),
    100 * (n_before - nrow(df)) / n_before))

# ---- Construct outcome variables ----
df <- df %>%
  mutate(
    ln_earn_hire = log(EarnHirAS),
    ln_hires = log(HirA),
    ln_sep = ifelse(Sep > 0, log(Sep), NA_real_),
    ln_emp = ifelse(Emp > 0, log(Emp), NA_real_)
  )

# ---- Create county-industry-race panel identifier ----
df <- df %>%
  mutate(
    panel_id = paste(county_fips, industry, race, sep = "_")
  )

# ---- Construct B-W earnings gap at county-industry-quarter level ----
df_gap <- df %>%
  select(county_fips, state_fips, industry, high_dispersion, year, quarter,
         time_index, yq, race, EarnHirAS, HirA, treated_state, post,
         first_treat, adopt_yq, state_abbr) %>%
  pivot_wider(
    id_cols = c(county_fips, state_fips, industry, high_dispersion, year,
                quarter, time_index, yq, treated_state, post, first_treat,
                adopt_yq, state_abbr),
    names_from = race,
    values_from = c(EarnHirAS, HirA),
    names_sep = "_"
  ) %>%
  filter(
    !is.na(EarnHirAS_Black) & !is.na(EarnHirAS_White) &
    EarnHirAS_Black > 0 & EarnHirAS_White > 0
  ) %>%
  mutate(
    bw_gap = log(EarnHirAS_Black) - log(EarnHirAS_White),
    bw_ratio = EarnHirAS_Black / EarnHirAS_White,
    total_hires = coalesce(HirA_Black, 0L) + coalesce(HirA_White, 0L)
  )

# ---- Create county-industry panel ID for gap analysis ----
df_gap <- df_gap %>%
  mutate(panel_id = paste(county_fips, industry, sep = "_"))

# ---- Summary statistics ----
cat("\n=== Panel summary ===\n")
cat(sprintf("County-industry-race cells: %s\n", format(nrow(df), big.mark = ",")))
cat(sprintf("County-industry gap obs: %s\n", format(nrow(df_gap), big.mark = ",")))
cat(sprintf("Unique counties: %d\n", n_distinct(df_gap$county_fips)))
cat(sprintf("Treated states: %d\n", n_distinct(df_gap$state_fips[df_gap$treated_state == 1])))
cat(sprintf("Control states: %d\n", n_distinct(df_gap$state_fips[df_gap$treated_state == 0])))
cat(sprintf("Industries: %s\n", paste(sort(unique(df_gap$industry)), collapse = ", ")))
cat(sprintf("Time span: %d-%d (Q%d to Q%d)\n",
    min(df_gap$year), max(df_gap$year),
    min(df_gap$quarter[df_gap$year == min(df_gap$year)]),
    max(df_gap$quarter[df_gap$year == max(df_gap$year)])))

cat("\nMean B-W earnings gap (log points) by treatment status:\n")
df_gap %>%
  group_by(treated_state, post) %>%
  summarise(
    mean_gap = mean(bw_gap, na.rm = TRUE),
    median_gap = median(bw_gap, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  print()

cat("\nMean B-W gap by high vs low dispersion industry:\n")
df_gap %>%
  group_by(high_dispersion, treated_state, post) %>%
  summarise(
    mean_gap = mean(bw_gap, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  print()

# ---- Save cleaned data ----
saveRDS(df, "../data/qwi_clean.rds")
saveRDS(df_gap, "../data/qwi_gap.rds")

cat("\nCleaned data saved.\n")
