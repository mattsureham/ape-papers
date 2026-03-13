## 02_clean_data.R — Build force×year panel with officers, crimes, and outcomes
## apep_0616: Police Austerity and Criminal Justice Quality

suppressPackageStartupMessages({
  library(tidyverse)
  library(readODS)
  library(readxl)
  library(data.table)
  library(janitor)
})

data_dir <- "data"

# ============================================================================
# 1. Police Workforce Panel (officer headcount by force × year)
# ============================================================================
cat("=== 1. Building Workforce Panel ===\n")

wf_raw <- read_ods(file.path(data_dir, "police_workforce.ods"), sheet = "Data") |>
  clean_names()

# Filter to Police Officers, aggregate to force × year
officers <- wf_raw |>
  filter(worker_type == "Police Officer") |>
  mutate(
    year = as.integer(as_at_31_march),
    headcount = as.numeric(total_headcount),
    fte = as.numeric(gsub(",", "", total_fte))  # fte is character with commas
  ) |>
  group_by(year, force_name, geocode, region) |>
  summarise(
    officers_headcount = sum(headcount, na.rm = TRUE),
    officers_fte = sum(fte, na.rm = TRUE),
    .groups = "drop"
  )

cat("  Officer panel:", nrow(officers), "rows\n")
cat("  Year range:", range(officers$year), "\n")
cat("  Forces:", length(unique(officers$force_name)), "\n")

# Sample: Met Police over time
cat("\n  Metropolitan Police officer FTE over time:\n")
officers |> filter(force_name == "Metropolitan Police") |>
  select(year, officers_fte) |> print(n = 20)

# ============================================================================
# 2. Crime Outcomes: Parse historical (2005-2014) + annual (2015-2022)
# ============================================================================
cat("\n=== 2. Building Crime Outcomes Panel ===\n")

# --- 2a. Historical 2005-2014 (ODS format, no quarterly breakdown) ---
cat("  Parsing 2005-2014 outcomes (ODS)...\n")
hist_raw <- read_ods(file.path(data_dir, "outcomes_2006_2014.ods"),
                     sheet = "Outcomes_Open_Data") |> clean_names()

cat("    Rows:", nrow(hist_raw), " Cols:", paste(names(hist_raw), collapse = ", "), "\n")

# Historical data uses text labels: "Charge/Summons", "Cautions", "Other", "PNDs", "TICs"
# Annual data (2015+) uses numeric outcome_type: 1 = Charged/Summonsed
# Map text to numeric for consistency
hist_outcomes <- hist_raw |>
  rename(outcome_count = number_of_outcomes_recorded) |>
  mutate(
    outcome_count = as.numeric(outcome_count),
    # Map text outcome types to numeric (1 = Charge/Summons)
    outcome_type_num = case_when(
      str_detect(outcome_type, "(?i)charge") ~ 1L,
      str_detect(outcome_type, "(?i)caution") ~ 2L,
      str_detect(outcome_type, "(?i)pnd")     ~ 3L,
      str_detect(outcome_type, "(?i)tic")     ~ 4L,
      str_detect(outcome_type, "(?i)cannabis") ~ 5L,
      TRUE ~ 99L
    ),
    financial_quarter = NA_real_
  ) |>
  select(financial_year, financial_quarter, force_name,
         offence_group, outcome_type = outcome_type_num, outcome_count) |>
  filter(!is.na(outcome_count))

cat("    Historical outcomes:", nrow(hist_outcomes), "rows\n")
cat("    Years:", paste(sort(unique(hist_outcomes$financial_year)), collapse = ", "), "\n")

# --- 2b. Annual files 2015-2022 (Excel format, quarterly) ---
cat("  Parsing 2015-2022 outcomes...\n")
annual_list <- list()

for (yr in 2015:2022) {
  fpath <- file.path(data_dir, sprintf("outcomes_%d.xlsx", yr))
  if (!file.exists(fpath)) next

  sheets <- excel_sheets(fpath)
  data_sheet <- sheets[grepl("Outcomes.open.data|Outcomes_open_data", sheets, ignore.case = TRUE)]
  if (length(data_sheet) == 0) next

  cat(sprintf("    Reading %d...\n", yr))
  df <- read_excel(fpath, sheet = data_sheet[1]) |> clean_names()

  std <- df |>
    rename(outcome_count = outcomes_for_offences_that_were_recorded_in_the_quarter) |>
    mutate(
      outcome_count = as.numeric(outcome_count),
      outcome_type = as.numeric(outcome_type)
    ) |>
    select(financial_year, financial_quarter, force_name,
           offence_group, outcome_type, outcome_count) |>
    filter(!is.na(outcome_count))

  annual_list[[as.character(yr)]] <- std
}

annual_outcomes <- bind_rows(annual_list)
cat("    Annual outcomes:", nrow(annual_outcomes), "rows\n")

# --- 2c. Combine ---
all_outcomes <- bind_rows(hist_outcomes, annual_outcomes)
cat("  Total outcomes:", nrow(all_outcomes), "rows\n")
cat("  Financial years:", paste(sort(unique(all_outcomes$financial_year)), collapse = ", "), "\n")

# ============================================================================
# 3. Aggregate outcomes to force × year level
# ============================================================================
cat("\n=== 3. Aggregating to Force × Year ===\n")

# Outcome type 1 = Charged/Summonsed
force_year <- all_outcomes |>
  mutate(fy_start = as.integer(substr(financial_year, 1, 4))) |>
  group_by(fy_start, force_name) |>
  summarise(
    total_outcomes = sum(outcome_count, na.rm = TRUE),
    charged = sum(outcome_count[outcome_type == 1], na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(charge_rate = charged / total_outcomes)

cat("  Force × year panel:", nrow(force_year), "rows\n")
cat("  Years:", range(force_year$fy_start), "\n")

# National aggregate trend
cat("\n  National charge rate trend:\n")
force_year |>
  group_by(fy_start) |>
  summarise(
    n_forces = n(),
    total_charged = sum(charged),
    total_outcomes = sum(total_outcomes),
    national_rate = total_charged / total_outcomes
  ) |>
  print(n = 20)

# ============================================================================
# 4. By offense group
# ============================================================================
cat("\n=== 4. Offense Group Heterogeneity ===\n")

offgroup <- all_outcomes |>
  mutate(fy_start = as.integer(substr(financial_year, 1, 4))) |>
  group_by(fy_start, force_name, offence_group) |>
  summarise(
    total_outcomes = sum(outcome_count, na.rm = TRUE),
    charged = sum(outcome_count[outcome_type == 1], na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(charge_rate = charged / total_outcomes)

# Show offense group charge rates in 2015 (mid-austerity)
cat("  Offense group charge rates in 2015/16:\n")
offgroup |>
  filter(fy_start == 2015) |>
  group_by(offence_group) |>
  summarise(mean_rate = mean(charge_rate, na.rm = TRUE)) |>
  arrange(desc(mean_rate)) |>
  print(n = 15)

# ============================================================================
# 5. Merge workforce + outcomes
# ============================================================================
cat("\n=== 5. Merging Datasets ===\n")

# Standardize force names
std_force <- function(x) str_trim(str_to_lower(x))

wf_std <- officers |> mutate(force_std = std_force(force_name))
out_std <- force_year |> mutate(force_std = std_force(force_name), year = fy_start)

# Check overlap
cat("  Workforce forces:", n_distinct(wf_std$force_std), "\n")
cat("  Outcomes forces:", n_distinct(out_std$force_std), "\n")
cat("  Overlap:", length(intersect(unique(wf_std$force_std), unique(out_std$force_std))), "\n")

# Exclude national aggregates and non-territorial forces
exclude <- c("england and wales", "action fraud", "british transport police")

panel <- wf_std |>
  filter(!force_std %in% exclude) |>
  inner_join(out_std |> filter(!force_std %in% exclude),
             by = c("force_std", "year")) |>
  select(year, force_name = force_name.x, geocode, region,
         officers_fte, officers_headcount,
         total_outcomes, charged, charge_rate) |>
  arrange(force_name, year)

cat("  Merged panel:", nrow(panel), "rows\n")
cat("  Year range:", range(panel$year), "\n")
cat("  Forces:", n_distinct(panel$force_name), "\n")

# Key panel stats
cat("\n  Panel balance check (obs per year):\n")
panel |> count(year) |> print(n = 20)

# ============================================================================
# 6. Construct treatment variable
# ============================================================================
cat("\n=== 6. Constructing Treatment Variables ===\n")

# Treatment: % change in officers from 2010 (peak) to 2015 (trough)
treatment <- panel |>
  filter(year %in% c(2010, 2015)) |>
  select(force_name, year, officers_fte) |>
  pivot_wider(names_from = year, values_from = officers_fte, names_prefix = "fte_") |>
  mutate(
    pct_officer_cut = (fte_2015 - fte_2010) / fte_2010 * 100,
    officer_cut_tercile = ntile(pct_officer_cut, 3)
  )

cat("  Treatment intensity (% officer change 2010-2015):\n")
treatment |>
  select(force_name, fte_2010, fte_2015, pct_officer_cut) |>
  arrange(pct_officer_cut) |>
  print(n = 15)

cat("\n  Tercile summary:\n")
treatment |>
  group_by(officer_cut_tercile) |>
  summarise(
    n = n(),
    mean_cut = mean(pct_officer_cut),
    min_cut = min(pct_officer_cut),
    max_cut = max(pct_officer_cut)
  ) |> print()

# Merge treatment into panel
panel <- panel |>
  left_join(treatment |> select(force_name, pct_officer_cut, officer_cut_tercile),
            by = "force_name") |>
  mutate(post_austerity = as.integer(year >= 2010))

# ============================================================================
# 7. Save
# ============================================================================
cat("\n=== 7. Saving ===\n")

saveRDS(officers, file.path(data_dir, "officers_panel.rds"))
saveRDS(force_year, file.path(data_dir, "outcomes_force_year.rds"))
saveRDS(offgroup, file.path(data_dir, "offgroup_outcomes.rds"))
saveRDS(panel, file.path(data_dir, "analysis_panel.rds"))
write_csv(panel, file.path(data_dir, "analysis_panel.csv"))

# Diagnostics for validator
jsonlite::write_json(list(
  n_treated = n_distinct(panel$force_name[!is.na(panel$pct_officer_cut)]),
  n_pre = sum(unique(panel$year) < 2010),
  n_obs = nrow(panel)
), file.path(data_dir, "diagnostics.json"), auto_unbox = TRUE)

cat("  All data saved.\nDone.\n")
