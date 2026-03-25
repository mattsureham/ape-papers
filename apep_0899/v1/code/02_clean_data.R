## 02_clean_data.R — Clean and construct analysis datasets
## apep_0899: Finland compulsory education extension

source("00_packages.R")

## ============================================================
## Dataset 1: School-to-work transitions (region × sector × year)
## ============================================================
trans_raw <- read_csv("../data/transitions_raw.csv", show_col_types = FALSE)
cat("Raw transitions:", nrow(trans_raw), "rows\n")
cat("Columns:", paste(names(trans_raw), collapse = ", "), "\n\n")

# Inspect unique values
cat("Education levels:", paste(unique(trans_raw$Koulutusaste), collapse = ", "), "\n")
cat("Regions:", paste(unique(trans_raw$Asuinmaakunta), collapse = "; "), "\n")
cat("Years:", paste(sort(unique(trans_raw$Vuosi)), collapse = ", "), "\n")
cat("Outcomes:", paste(unique(trans_raw$Tiedot), collapse = ", "), "\n\n")

# Rename and reshape
trans <- trans_raw %>%
  rename(
    year = Vuosi,
    edu_level = Koulutusaste,
    region = Asuinmaakunta,
    outcome_var = Tiedot
  ) %>%
  # Remove total region (SS) for analysis; keep it for descriptives
  filter(region != "Total") %>%
  # Create clean outcome names
  mutate(
    outcome_name = case_when(
      outcome_var == "Completers of qualifications total, one year before the statistical year (number)" ~ "completers",
      str_detect(outcome_var, "Employed persons total.*one year.*\\(%\\)") ~ "employed_pct",
      str_detect(outcome_var, "Full time employed.*one year.*\\(%\\)") ~ "ft_employed_pct",
      str_detect(outcome_var, "Full-time students.*one year.*\\(%\\)") ~ "student_pct",
      str_detect(outcome_var, "Unemployed.*one year.*\\(%\\)") ~ "unemployed_pct",
      str_detect(outcome_var, "Employed persons total.*one year.*\\(number\\)") ~ "employed_n",
      str_detect(outcome_var, "Unemployed.*one year.*\\(number\\)") ~ "unemployed_n",
      str_detect(outcome_var, "Full-time students.*one year.*\\(number\\)") ~ "student_n",
      str_detect(outcome_var, "Employed students.*one year.*\\(%\\)") ~ "emp_student_pct",
      str_detect(outcome_var, "Others.*one year.*\\(%\\)") ~ "other_pct",
      TRUE ~ "other"
    ),
    # Clean education label
    sector = case_when(
      str_detect(edu_level, "General") ~ "general",
      str_detect(edu_level, "Vocational") ~ "vocational",
      TRUE ~ NA_character_
    ),
    # Clean region name
    region_name = str_trim(region),
    year = as.integer(year)
  ) %>%
  filter(!is.na(sector)) %>%
  select(year, region_name, sector, outcome_name, value) %>%
  # Pivot to wide format (one row per region-sector-year)
  pivot_wider(names_from = outcome_name, values_from = value,
              values_fn = first)

cat("Cleaned transitions panel:", nrow(trans), "obs\n")
cat("Years:", range(trans$year), "\n")
cat("Regions:", n_distinct(trans$region_name), "\n")

## ============================================================
## Dataset 2: Discontinuation by region (2018-2024)
## ============================================================
drop_reg <- read_csv("../data/dropout_regional_raw.csv", show_col_types = FALSE)
cat("\nRaw regional dropout:", nrow(drop_reg), "rows\n")
cat("Columns:", paste(names(drop_reg), collapse = ", "), "\n")

# Inspect
dim_names <- names(drop_reg)
cat("Dim1 unique:", paste(head(unique(drop_reg[[1]]), 5), collapse = ", "), "\n")
cat("Dim2 unique:", paste(head(unique(drop_reg[[2]]), 5), collapse = ", "), "\n")
cat("Dim3 unique:", paste(head(unique(drop_reg[[3]]), 5), collapse = ", "), "\n")
cat("Dim4 unique:", paste(head(unique(drop_reg[[4]]), 5), collapse = ", "), "\n")

# Rename based on the table structure: Year, Sector, Region, Info
names(drop_reg) <- c("year_raw", "sector_raw", "region_raw", "info_raw", "value")

drop_reg_clean <- drop_reg %>%
  mutate(
    year = as.integer(str_extract(year_raw, "\\d{4}")),
    sector = case_when(
      str_detect(sector_raw, "(?i)general|lukio") ~ "general",
      str_detect(sector_raw, "(?i)vocational|ammatillinen") ~ "vocational",
      str_detect(sector_raw, "(?i)total") ~ "total",
      TRUE ~ "other"
    ),
    region_name = str_trim(region_raw),
    info = case_when(
      str_detect(info_raw, "(?i)discontin.*rate|share|%") ~ "dropout_rate",
      str_detect(info_raw, "(?i)discontin.*number|who disc") ~ "dropout_n",
      str_detect(info_raw, "(?i)student.*number|new student") ~ "student_n",
      TRUE ~ info_raw
    )
  ) %>%
  filter(region_name != "Total", region_name != "WHOLE COUNTRY") %>%
  select(year, region_name, sector, info, value)

cat("Cleaned regional dropout:", nrow(drop_reg_clean), "\n")

## ============================================================
## Dataset 3: National discontinuation (2000-2024)
## ============================================================
drop_nat <- read_csv("../data/dropout_national_raw.csv", show_col_types = FALSE)
cat("\nRaw national dropout:", nrow(drop_nat), "rows\n")

names(drop_nat) <- c("year_raw", "sector_raw", "value")

drop_nat_clean <- drop_nat %>%
  mutate(
    year = as.integer(str_extract(year_raw, "\\d{4}")),
    sector = case_when(
      str_detect(sector_raw, "(?i)general") ~ "general",
      str_detect(sector_raw, "(?i)vocational|initial vocational") ~ "vocational",
      str_detect(sector_raw, "(?i)applied") ~ "applied_sciences",
      str_detect(sector_raw, "(?i)university") ~ "university",
      TRUE ~ sector_raw
    )
  ) %>%
  select(year, sector, dropout_rate = value)

cat("National dropout series:", nrow(drop_nat_clean), "obs\n")
cat("Years:", range(drop_nat_clean$year), "\n")
cat("Sectors:", paste(unique(drop_nat_clean$sector), collapse = ", "), "\n\n")

# Show the key pattern: vocational dropout before/after reform
cat("=== National vocational dropout rates ===\n")
drop_nat_clean %>%
  filter(sector == "vocational") %>%
  arrange(year) %>%
  print(n = 30)

cat("\n=== National general dropout rates ===\n")
drop_nat_clean %>%
  filter(sector == "general") %>%
  arrange(year) %>%
  print(n = 30)

## ============================================================
## Construct analysis panel: transitions data
## ============================================================

# Treatment intensity: pre-reform average unemployment rate in each region
# for vocational graduates (proxy for mandate bite — higher unemployed = harder transition)
pre_reform <- trans %>%
  filter(year <= 2020, sector == "vocational") %>%
  group_by(region_name) %>%
  summarize(
    pre_unemployed_pct = mean(unemployed_pct, na.rm = TRUE),
    pre_employed_pct = mean(employed_pct, na.rm = TRUE),
    pre_student_pct = mean(student_pct, na.rm = TRUE),
    .groups = "drop"
  )

cat("\n=== Pre-reform regional variation (vocational) ===\n")
pre_reform %>% arrange(desc(pre_unemployed_pct)) %>% print(n = 25)

# Merge intensity back to panel
panel <- trans %>%
  left_join(pre_reform, by = "region_name") %>%
  mutate(
    post = as.integer(year >= 2021),
    vocational = as.integer(sector == "vocational"),
    intensity = pre_unemployed_pct,  # continuous treatment intensity
    high_intensity = as.integer(pre_unemployed_pct > median(pre_reform$pre_unemployed_pct)),
    region_id = as.integer(factor(region_name)),
    # Event time
    event_time = year - 2021
  )

cat("\n=== Panel summary ===\n")
cat("Total obs:", nrow(panel), "\n")
cat("Regions:", n_distinct(panel$region_name), "\n")
cat("Years:", paste(range(panel$year), collapse = "-"), "\n")
cat("Sectors:", paste(unique(panel$sector), collapse = ", "), "\n")
cat("Pre-reform obs:", sum(panel$post == 0), "\n")
cat("Post-reform obs:", sum(panel$post == 1), "\n")

## Save
write_csv(panel, "../data/analysis_panel.csv")
write_csv(pre_reform, "../data/pre_reform_intensity.csv")
write_csv(drop_nat_clean, "../data/dropout_national_clean.csv")
write_csv(drop_reg_clean, "../data/dropout_regional_clean.csv")

cat("\nAll cleaned data saved.\n")
