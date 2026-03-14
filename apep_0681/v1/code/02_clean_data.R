# 02_clean_data.R — Construct analysis panel
# apep_0681: IR35 Off-Payroll Reforms

source("00_packages.R")

raw <- read_csv("../data/nomis_business_counts_raw.csv", show_col_types = FALSE)
cat(sprintf("Raw data: %d rows\n", nrow(raw)))

# ---- Extract year ----
raw <- raw |>
  mutate(year = as.integer(DATE_NAME)) |>
  filter(year >= 2016, year <= 2024)  # Drop 2025 (zeros — not yet published)

# ---- Define treatment/control sectors ----
treated_sics  <- c(62, 70, 71, 78)
control_sics  <- c(47, 56, 69, 46)

raw <- raw |>
  mutate(
    treated = as.integer(sic_code %in% treated_sics),
    sector_label = case_when(
      sic_code == 62 ~ "IT consulting",
      sic_code == 70 ~ "Management consulting",
      sic_code == 71 ~ "Architecture/engineering",
      sic_code == 78 ~ "Employment agencies",
      sic_code == 47 ~ "Retail trade",
      sic_code == 56 ~ "Food/beverage service",
      sic_code == 69 ~ "Legal/accounting",
      sic_code == 46 ~ "Wholesale trade"
    )
  )

# ---- Create panels by legal status ----

# Panel A: Companies only (main outcome — PSC dissolution)
companies <- raw |>
  filter(LEGAL_STATUS == 1) |>  # "Company (including building society)"
  select(year, la_code = GEOGRAPHY_CODE, la_name = GEOGRAPHY_NAME,
         sic_code, sector_label, treated, companies = OBS_VALUE)

# Panel B: Sole proprietors (substitution channel)
sole_props <- raw |>
  filter(LEGAL_STATUS == 3) |>  # "Sole proprietor"
  select(year, la_code = GEOGRAPHY_CODE, sic_code, sole_props = OBS_VALUE)

# Panel C: Total enterprises (net effect)
total <- raw |>
  filter(LEGAL_STATUS == 0) |>  # "Total"
  select(year, la_code = GEOGRAPHY_CODE, sic_code, total_ents = OBS_VALUE)

# Panel D: Partnerships
partnerships <- raw |>
  filter(LEGAL_STATUS == 2) |>
  select(year, la_code = GEOGRAPHY_CODE, sic_code, partnerships = OBS_VALUE)

# ---- Merge all legal status panels ----
panel <- companies |>
  left_join(sole_props, by = c("year", "la_code", "sic_code")) |>
  left_join(total, by = c("year", "la_code", "sic_code")) |>
  left_join(partnerships, by = c("year", "la_code", "sic_code"))

# ---- Create log outcomes and treatment indicators ----
panel <- panel |>
  mutate(
    # Log outcomes (add 1 for zeros)
    log_companies  = log(companies + 1),
    log_sole_props = log(sole_props + 1),
    log_total      = log(total_ents + 1),
    # Treatment timing
    post_2017 = as.integer(year >= 2017),  # Public sector reform
    post_2021 = as.integer(year >= 2021),  # Private sector reform
    # DiD interaction terms
    treat_post2017 = treated * post_2017,
    treat_post2021 = treated * post_2021,
    # Company share (composition measure)
    company_share = ifelse(total_ents > 0, companies / total_ents, NA),
    # Unit ID for panel
    unit_id = paste(la_code, sic_code, sep = "_")
  )

# ---- Validate panel structure ----
cat(sprintf("\nPanel: %d rows\n", nrow(panel)))
cat(sprintf("LAs: %d\n", n_distinct(panel$la_code)))
cat(sprintf("Sectors: %d\n", n_distinct(panel$sic_code)))
cat(sprintf("Years: %s\n", paste(sort(unique(panel$year)), collapse = ", ")))
cat(sprintf("Treated sector-LAs: %d\n", n_distinct(panel$unit_id[panel$treated == 1])))
cat(sprintf("Control sector-LAs: %d\n", n_distinct(panel$unit_id[panel$treated == 0])))

# Balanced panel check
units_per_year <- panel |> count(year) |> pull(n)
cat(sprintf("Balanced: %s (units/year: %s)\n",
            ifelse(length(unique(units_per_year)) == 1, "YES", "NO"),
            paste(unique(units_per_year), collapse = ", ")))

# ---- National aggregates for descriptive table ----
national <- panel |>
  group_by(year, sic_code, sector_label, treated) |>
  summarise(
    companies  = sum(companies, na.rm = TRUE),
    sole_props = sum(sole_props, na.rm = TRUE),
    total_ents = sum(total_ents, na.rm = TRUE),
    partnerships = sum(partnerships, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(company_share = companies / total_ents)

cat("\n--- National company counts by sector ---\n")
national |>
  filter(year %in% c(2016, 2019, 2021, 2024)) |>
  select(year, sector_label, companies, total_ents, company_share) |>
  arrange(sector_label, year) |>
  print(n = 40)

# ---- Save ----
write_csv(panel, "../data/analysis_panel.csv")
write_csv(national, "../data/national_aggregates.csv")
cat("\nSaved: data/analysis_panel.csv, data/national_aggregates.csv\n")
