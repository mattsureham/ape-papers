source("code/00_packages.R")

ensure_dir("data/derived")

load_exposure <- function(path) {
  raw <- read_excel(path, sheet = "Data tables", col_names = FALSE)

  raw[26:38, 1:4] |>
    setNames(c("region_fca", "loan_count", "adult_population", "loans_per_1000")) |>
    filter(!is.na(region_fca), region_fca != "Unknown") |>
    mutate(
      loan_count = suppressWarnings(as.numeric(loan_count)),
      adult_population = suppressWarnings(as.numeric(adult_population)),
      loans_per_1000 = suppressWarnings(as.numeric(loans_per_1000)),
      region = recode(
        region_fca,
        "Greater London" = "London",
        "Yorkshire and The Humber" = "Yorkshire and the Humber"
      )
    ) |>
    select(region, loan_count, adult_population, loans_per_1000)
}

load_moj_claims <- function(path) {
  read_csv(path, show_col_types = FALSE) |>
    mutate(
      region = str_trim(region),
      region = recode(region, "Yorkshire and The Humber" = "Yorkshire and the Humber")
    ) |>
    filter(
      !la_code %in% c("1000", NA_character_),
      possession_action == "Claims",
      year >= 2003,
      year <= 2019
    )
}

exposure <- load_exposure("data/raw/fca_hcstc_underlying_2019.xlsx")
moj <- load_moj_claims("data/raw/moj_zip/LA CSV.csv")

private_panel <- moj |>
  filter(possession_type %in% c("Private_Landlord", "Accelerated_Landlord")) |>
  group_by(year, quarter, la_code, local_authority, county_ua, region) |>
  summarise(private_claims = sum(value), .groups = "drop")

mortgage_panel <- moj |>
  filter(possession_type == "Mortgage") |>
  group_by(year, quarter, la_code, local_authority, county_ua, region) |>
  summarise(mortgage_claims = sum(value), .groups = "drop")

analysis_panel <- full_join(
  private_panel,
  mortgage_panel,
  by = c("year", "quarter", "la_code", "local_authority", "county_ua", "region")
) |>
  mutate(
    private_claims = coalesce(private_claims, 0),
    mortgage_claims = coalesce(mortgage_claims, 0)
  ) |>
  left_join(exposure, by = "region") |>
  filter(!is.na(loans_per_1000)) |>
  mutate(
    quarter_num = as.integer(str_remove(quarter, "Q")),
    time_index = (year - min(year)) * 4 + quarter_num,
    quarter_id = factor(paste0(year, quarter)),
    rel_year = year - 2014,
    post = as.integer(year >= 2015),
    log_private = log1p(private_claims),
    log_mortgage = log1p(mortgage_claims),
    diff_y = log_private - log_mortgage
  ) |>
  arrange(la_code, year, quarter_num)

baseline_split <- analysis_panel |>
  filter(post == 0) |>
  group_by(la_code) |>
  summarise(baseline_private = mean(private_claims, na.rm = TRUE), .groups = "drop")

split_cut <- median(baseline_split$baseline_private, na.rm = TRUE)

analysis_panel <- analysis_panel |>
  left_join(baseline_split, by = "la_code") |>
  mutate(high_baseline = as.integer(baseline_private >= split_cut))

stacked_panel <- analysis_panel |>
  select(year, quarter, quarter_id, rel_year, la_code, local_authority, county_ua, region,
         loans_per_1000, loan_count, adult_population, post, high_baseline,
         private_claims, mortgage_claims, log_private, log_mortgage, diff_y) |>
  pivot_longer(
    cols = c(private_claims, mortgage_claims),
    names_to = "outcome_type",
    values_to = "claims"
  ) |>
  mutate(
    outcome_type = recode(
      outcome_type,
      private_claims = "private",
      mortgage_claims = "mortgage"
    ),
    y = log1p(claims)
  )

summary_stats <- tibble(
  metric = c(
    "Local authorities",
    "Regions",
    "Quarters",
    "Pre-treatment quarters",
    "Mean private claims (pre)",
    "Mean mortgage claims (pre)",
    "Mean exposure (loans per 1,000 adults)",
    "SD exposure (loans per 1,000 adults)"
  ),
  value = c(
    n_distinct(analysis_panel$la_code),
    n_distinct(analysis_panel$region),
    n_distinct(analysis_panel$quarter_id),
    n_distinct(analysis_panel$quarter_id[analysis_panel$post == 0]),
    mean(analysis_panel$private_claims[analysis_panel$post == 0], na.rm = TRUE),
    mean(analysis_panel$mortgage_claims[analysis_panel$post == 0], na.rm = TRUE),
    mean(distinct(analysis_panel, region, loans_per_1000)$loans_per_1000, na.rm = TRUE),
    sd(distinct(analysis_panel, region, loans_per_1000)$loans_per_1000, na.rm = TRUE)
  )
)

write_csv(exposure, "data/derived/exposure_by_region.csv")
write_csv(analysis_panel, "data/derived/analysis_panel.csv")
write_csv(stacked_panel, "data/derived/stacked_panel.csv")
write_csv(summary_stats, "data/derived/summary_stats.csv")

cat("Cleaned panel written to data/derived/analysis_panel.csv\n")
