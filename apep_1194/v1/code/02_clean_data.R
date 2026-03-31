# 02_clean_data.R — Clean data and construct treatment/outcome variables
# APEP-1194: Positive Train Control and Railroad Accident Prevention

source("00_packages.R")

raw_df <- readRDS("../data/fra_form54_raw.rds")
cat(sprintf("Loaded %d raw records\n", nrow(raw_df)))

# ---- Parse date and year ----
raw_df <- raw_df %>%
  mutate(
    accident_date = as.Date(substr(date, 1, 10)),
    accident_year = as.integer(format(accident_date, "%Y"))
  )

cat("Year range:", min(raw_df$accident_year, na.rm = TRUE), "-",
    max(raw_df$accident_year, na.rm = TRUE), "\n")

# ---- Identify PTC presence in each accident record ----
# PTC appears in adjunctname1, adjunctname2, or adjunctname3
raw_df <- raw_df %>%
  mutate(
    ptc_present = grepl("PTC|Positive Train Control", adjunctname1, ignore.case = TRUE) |
                  grepl("PTC|Positive Train Control", adjunctname2, ignore.case = TRUE) |
                  grepl("PTC|Positive Train Control", adjunctname3, ignore.case = TRUE)
  )

cat(sprintf("\nPTC-flagged accident records: %d (%.1f%%)\n",
            sum(raw_df$ptc_present), 100 * mean(raw_df$ptc_present)))

# ---- Classify accident cause categories ----
# H-prefix = Human Factors (PTC-preventable)
# T-prefix = Track/Roadbed/Structures
# E-prefix = Mechanical/Electrical (equipment)
# S-prefix = Signal/Communication
# M-prefix = Miscellaneous
raw_df <- raw_df %>%
  mutate(
    cause_prefix = toupper(substr(accidentcausecode, 1, 1)),
    cause_category = case_when(
      cause_prefix == "H" ~ "Human Factor",
      cause_prefix == "T" ~ "Track Defect",
      cause_prefix == "E" ~ "Equipment Failure",
      cause_prefix == "S" ~ "Signal/Communication",
      cause_prefix == "M" ~ "Miscellaneous",
      TRUE ~ "Other/Unknown"
    ),
    # Binary: is this a PTC-preventable cause?
    ptc_preventable = cause_prefix == "H"
  )

cat("\nAccident cause distribution:\n")
raw_df %>%
  count(cause_category, sort = TRUE) %>%
  mutate(pct = round(100 * n / sum(n), 1)) %>%
  print()

# ---- Numeric conversions ----
raw_df <- raw_df %>%
  mutate(
    killed = as.numeric(totalpersonskilled),
    injured = as.numeric(totalpersonsinjured),
    damage_cost = as.numeric(totaldamagecost),
    train_speed = as.numeric(trainspeed)
  )

# Replace NA with 0 for count variables
raw_df <- raw_df %>%
  mutate(
    killed = replace_na(killed, 0),
    injured = replace_na(injured, 0),
    damage_cost = replace_na(damage_cost, 0)
  )

# ---- Identify PTC adoption year per railroad ----
# First year a railroad has ANY PTC-flagged accident record
ptc_adoption <- raw_df %>%
  filter(ptc_present) %>%
  group_by(reportingrailroadcode) %>%
  summarise(
    ptc_first_year = min(accident_year),
    ptc_record_count = n(),
    .groups = "drop"
  ) %>%
  arrange(ptc_first_year)

cat(sprintf("\nRailroads with PTC: %d\n", nrow(ptc_adoption)))
cat("\nPTC adoption timing:\n")
ptc_adoption %>%
  count(ptc_first_year) %>%
  print(n = 30)

# ---- Build railroad-by-year panel ----
# Filter to years with substantial data coverage
# and railroads with at least some activity
panel_years <- 2000:2025  # Focus on 2000+ for panel balance

# Count accidents per railroad-year
rr_year_panel <- raw_df %>%
  filter(accident_year %in% panel_years) %>%
  group_by(reportingrailroadcode, accident_year) %>%
  summarise(
    total_accidents = n(),
    human_factor_accidents = sum(ptc_preventable),
    non_human_accidents = sum(!ptc_preventable),
    track_accidents = sum(cause_prefix == "T"),
    equipment_accidents = sum(cause_prefix == "E"),
    signal_accidents = sum(cause_prefix == "S"),
    total_killed = sum(killed),
    total_injured = sum(injured),
    total_damage = sum(damage_cost),
    human_killed = sum(killed[ptc_preventable]),
    human_injured = sum(injured[ptc_preventable]),
    ptc_accident_count = sum(ptc_present),
    .groups = "drop"
  ) %>%
  rename(year = accident_year, railroad = reportingrailroadcode)

# ---- Merge PTC adoption info ----
rr_year_panel <- rr_year_panel %>%
  left_join(
    ptc_adoption %>%
      select(reportingrailroadcode, ptc_first_year) %>%
      rename(railroad = reportingrailroadcode),
    by = "railroad"
  ) %>%
  mutate(
    # Never-treated railroads get first_treat = 0 (did package convention)
    first_treat = replace_na(ptc_first_year, 0),
    # Post-treatment indicator
    post_ptc = ifelse(first_treat > 0 & year >= first_treat, 1, 0)
  )

cat(sprintf("\nPanel dimensions: %d railroad-years, %d railroads, %d years\n",
            nrow(rr_year_panel),
            n_distinct(rr_year_panel$railroad),
            n_distinct(rr_year_panel$year)))

# ---- Filter to railroads with sufficient data ----
# Require at least 5 years of accident records to be in the panel
rr_activity <- rr_year_panel %>%
  group_by(railroad) %>%
  summarise(
    n_years = n(),
    total_acc = sum(total_accidents),
    .groups = "drop"
  )

# Keep railroads with at least 10 years of data and at least 20 total accidents
active_railroads <- rr_activity %>%
  filter(n_years >= 10, total_acc >= 20) %>%
  pull(railroad)

cat(sprintf("\nRailroads with ≥10 years and ≥20 accidents: %d\n",
            length(active_railroads)))

panel_clean <- rr_year_panel %>%
  filter(railroad %in% active_railroads)

# ---- Summary statistics ----
cat("\n=== Panel Summary ===\n")
cat(sprintf("Railroad-years: %d\n", nrow(panel_clean)))
cat(sprintf("Unique railroads: %d\n", n_distinct(panel_clean$railroad)))
cat(sprintf("  Treated (ever-PTC): %d\n",
            n_distinct(panel_clean$railroad[panel_clean$first_treat > 0])))
cat(sprintf("  Never-treated: %d\n",
            n_distinct(panel_clean$railroad[panel_clean$first_treat == 0])))
cat(sprintf("Year range: %d-%d\n", min(panel_clean$year), max(panel_clean$year)))

cat("\nPTC adoption cohorts (in analysis sample):\n")
panel_clean %>%
  filter(first_treat > 0) %>%
  distinct(railroad, first_treat) %>%
  count(first_treat) %>%
  print(n = 30)

cat("\nOutcome summary statistics:\n")
panel_clean %>%
  summarise(
    across(c(total_accidents, human_factor_accidents, non_human_accidents,
             total_killed, total_injured, total_damage),
           list(mean = ~mean(.), sd = ~sd(.), min = ~min(.), max = ~max(.)))
  ) %>%
  pivot_longer(everything()) %>%
  print(n = 30)

# ---- Create numeric railroad ID for did package ----
panel_clean <- panel_clean %>%
  mutate(railroad_id = as.numeric(as.factor(railroad)))

# ---- Save cleaned panel ----
saveRDS(panel_clean, "../data/panel_clean.rds")
cat(sprintf("\nSaved cleaned panel: %d rows\n", nrow(panel_clean)))

# ---- Also save a summary of adoption timing for the paper ----
adoption_summary <- panel_clean %>%
  filter(first_treat > 0) %>%
  distinct(railroad, first_treat) %>%
  left_join(
    panel_clean %>%
      group_by(railroad) %>%
      summarise(total_acc = sum(total_accidents), .groups = "drop"),
    by = "railroad"
  ) %>%
  arrange(first_treat, railroad)

saveRDS(adoption_summary, "../data/adoption_summary.rds")
cat(sprintf("Saved adoption summary: %d treated railroads\n", nrow(adoption_summary)))
