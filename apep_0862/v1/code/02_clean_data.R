## 02_clean_data.R — Construct analysis panels
## apep_0862: Civilian Service Expansion and Healthcare Employment in Switzerland

source("00_packages.R")

# ==============================================================================
# 1. Clean BESTA quarterly panel (national, sector-level)
# ==============================================================================
cat("=== Cleaning BESTA quarterly panel ===\n")

besta <- read_csv("../data/besta_quarterly.csv", show_col_types = FALSE)

# Focus on FTE (Vollzeitäquivalente) for main analysis
# Also keep total employment (Beschäftigte) for robustness
besta_clean <- besta |>
  filter(gender == "TOT") |>
  # Exclude aggregate sectors (86-88, 45-96, 5-96) from regressions
  filter(!sector %in% c("86-88", "45-96", "5-96")) |>
  # Create sector groups for analysis
  mutate(
    sector_group = case_when(
      sector %in% c("86", "87", "88") ~ "Health & Social Care",
      sector == "85" ~ "Education",
      sector == "84" ~ "Public Administration",
      sector %in% c("55-56") ~ "Hospitality",
      sector %in% c("69-75") ~ "Professional Services",
      sector %in% c("77-82") ~ "Business Services",
      sector == "47" ~ "Retail",
      sector == "68" ~ "Real Estate",
      sector %in% c("90-93") ~ "Arts & Recreation",
      sector %in% c("94-96") ~ "Other Services",
      TRUE ~ "Other"
    ),
    # Numeric sector ID for fixed effects
    sector_id = as.integer(factor(sector)),
    # Time variable
    date = as.Date(paste0(year, "-", (qtr - 1) * 3 + 1, "-01")),
    # Log employment
    log_emp = log(employment)
  ) |>
  # Pivot wider: one row per sector-quarter with both measures
  pivot_wider(
    id_cols = c(sector, sector_label, sector_group, sector_id, quarter, year, qtr,
                time_idx, treated, post, partial_reversal, date),
    names_from = emptype,
    values_from = c(employment, log_emp),
    names_glue = "{.value}_{emptype}"
  ) |>
  rename(
    emp_total = employment_TOT,
    emp_fte = `employment_4`,
    log_emp_total = log_emp_TOT,
    log_emp_fte = `log_emp_4`
  )

cat(sprintf("Clean BESTA: %d sector-quarters, %d sectors, %d quarters\n",
            nrow(besta_clean), n_distinct(besta_clean$sector), n_distinct(besta_clean$quarter)))

# Summary stats by treatment status
cat("\n--- Summary by treatment group ---\n")
besta_clean |>
  group_by(treated, post) |>
  summarise(
    n_obs = n(),
    mean_fte = mean(emp_fte, na.rm = TRUE),
    sd_fte = sd(emp_fte, na.rm = TRUE),
    .groups = "drop"
  ) |>
  print()

# ==============================================================================
# 2. Clean STATENT annual panel (canton x sector)
# ==============================================================================
cat("\n=== Cleaning STATENT annual panel ===\n")

statent <- read_csv("../data/statent_annual.csv", show_col_types = FALSE)

statent_clean <- statent |>
  # Exclude Switzerland total
  filter(canton != "999") |>
  # Exclude sector total
  filter(sector != "999") |>
  # Pivot wider by measure
  pivot_wider(
    id_cols = c(year, canton, canton_label, sector, sector_label, treated),
    names_from = measure,
    values_from = value,
    names_glue = "measure_{measure}"
  ) |>
  rename(
    emp_headcount = measure_2,
    emp_fte = measure_5
  ) |>
  mutate(
    canton_id = as.integer(canton),
    sector_id = as.integer(factor(sector)),
    log_fte = log(pmax(emp_fte, 1)),
    log_headcount = log(pmax(emp_headcount, 1))
  )

cat(sprintf("Clean STATENT: %d canton-sector-years\n", nrow(statent_clean)))
cat(sprintf("  Cantons: %d, Sectors: %d, Years: %d\n",
            n_distinct(statent_clean$canton), n_distinct(statent_clean$sector),
            n_distinct(statent_clean$year)))

# ==============================================================================
# 3. Merge ZIVI treatment intensity
# ==============================================================================
cat("\n=== Merging ZIVI treatment intensity ===\n")

zivi <- read_csv("../data/zivi_combined.csv", show_col_types = FALSE)
zivi_adm <- read_csv("../data/zivi_admissions.csv", show_col_types = FALSE)

# Create year-level treatment intensity for BESTA panel
zivi_intensity <- zivi |>
  select(year, total_days, health_social_days, health_social_fte)

besta_final <- besta_clean |>
  left_join(zivi_intensity, by = "year") |>
  mutate(
    # Continuous treatment: ZIVI FTE in health/social / total FTE in health sectors
    zivi_fte = ifelse(is.na(health_social_fte), 0, health_social_fte),
    # Treatment intensity interaction
    treated_x_zivi = treated * zivi_fte
  )

# ==============================================================================
# 4. Save analysis-ready datasets
# ==============================================================================
write_csv(besta_final, "../data/analysis_besta.csv")
write_csv(statent_clean, "../data/analysis_statent.csv")

cat("\n=== Analysis datasets saved ===\n")
cat(sprintf("BESTA: %d rows → data/analysis_besta.csv\n", nrow(besta_final)))
cat(sprintf("STATENT: %d rows → data/analysis_statent.csv\n", nrow(statent_clean)))

# Quick visual check: employment trends
cat("\n--- FTE by treatment group (selected quarters) ---\n")
besta_final |>
  group_by(treated, quarter) |>
  summarise(total_fte = sum(emp_fte, na.rm = TRUE), .groups = "drop") |>
  filter(quarter %in% c("2003Q1", "2005Q1", "2007Q1", "2008Q4",
                         "2009Q2", "2010Q1", "2012Q1", "2014Q1", "2016Q1")) |>
  arrange(treated, quarter) |>
  print(n = 20)
