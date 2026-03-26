## 02_clean_data.R — Construct balanced CoC panel with treatment coding
## apep_1028: Right-to-Counsel and Community-Level Homelessness

source("00_packages.R")

cat("=== Building CoC-Year Panel ===\n")

pit_list <- readRDS("../data/pit_raw.rds")
rtc <- readRDS("../data/rtc_treatment.rds")

# --- Extract key variables from each year ---
# Columns present across all years: CoC Number, Overall Homeless,
# Sheltered Total Homeless, Unsheltered Homeless
# From 2007: Overall Homeless Individuals, Overall Homeless People in Families

years <- 2007:2024

extract_year <- function(df, yr) {
  # Standardize column names
  names(df) <- trimws(names(df))

  # Find CoC identifier
  coc_col <- grep("CoC Number", names(df), value = TRUE)[1]
  if (is.na(coc_col)) {
    cat("WARNING: No CoC Number column in year", yr, "\n")
    return(NULL)
  }

  # Core variables (present in all years)
  out <- tibble(
    coc_code = as.character(df[[coc_col]]),
    year = yr,
    total_homeless = as.numeric(df[["Overall Homeless"]]),
    sheltered = as.numeric(df[["Sheltered Total Homeless"]]),
    unsheltered = as.numeric(df[["Unsheltered Homeless"]])
  )

  # Individuals vs families (present from 2007)
  if ("Overall Homeless Individuals" %in% names(df)) {
    out$homeless_indiv <- as.numeric(df[["Overall Homeless Individuals"]])
  }
  if ("Overall Homeless People in Families" %in% names(df)) {
    out$homeless_family <- as.numeric(df[["Overall Homeless People in Families"]])
  }

  # Remove header rows and NAs

  out <- out |>
    filter(!is.na(coc_code), !is.na(total_homeless),
           !grepl("^Total|^CoC", coc_code, ignore.case = TRUE))

  out
}

panel_list <- list()
for (yr in years) {
  sheet_name <- as.character(yr)
  if (sheet_name %in% names(pit_list)) {
    panel_list[[sheet_name]] <- extract_year(pit_list[[sheet_name]], yr)
    cat("Year", yr, ":", nrow(panel_list[[sheet_name]]), "CoCs\n")
  }
}

panel <- bind_rows(panel_list)
cat("\nRaw panel:", nrow(panel), "rows,", n_distinct(panel$coc_code), "unique CoCs\n")

# --- Handle CoC mergers ---
# Some CoCs merged over time. Read the merger sheet to track.
merger_df <- pit_list[["CoC Mergers"]]
if (!is.null(merger_df)) {
  names(merger_df) <- trimws(names(merger_df))
  cat("\nCoC mergers:", nrow(merger_df), "records\n")
}

# --- Merge treatment status ---
panel <- panel |>
  left_join(rtc |> select(coc_code, adopt_year), by = "coc_code") |>
  mutate(
    # Never-treated CoCs get adopt_year = 0 (convention for CS DiD)
    first_treat = ifelse(is.na(adopt_year), 0L, adopt_year),
    # Binary treatment indicator
    treated = as.integer(!is.na(adopt_year) & year >= adopt_year),
    # Event time
    event_time = ifelse(first_treat > 0, year - first_treat, NA_integer_)
  )

cat("\nTreatment status:\n")
cat("  Treated CoCs:", n_distinct(panel$coc_code[panel$first_treat > 0]), "\n")
cat("  Control CoCs:", n_distinct(panel$coc_code[panel$first_treat == 0]), "\n")

# --- Create log outcomes ---
panel <- panel |>
  mutate(
    log_total = log(total_homeless + 1),
    log_sheltered = log(sheltered + 1),
    log_unsheltered = log(unsheltered + 1),
    log_family = log(ifelse(is.na(homeless_family), NA, homeless_family + 1)),
    log_indiv = log(ifelse(is.na(homeless_indiv), NA, homeless_indiv + 1))
  )

# --- Create balanced panel (CoCs present in ALL years) ---
coc_year_counts <- panel |>
  group_by(coc_code) |>
  summarise(n_years = n_distinct(year), .groups = "drop")

balanced_cocs <- coc_year_counts |>
  filter(n_years >= 16) |>  # Present in at least 16 of 18 years
  pull(coc_code)

panel_balanced <- panel |> filter(coc_code %in% balanced_cocs)

cat("\nBalanced panel (>=16 years):", nrow(panel_balanced), "rows,",
    n_distinct(panel_balanced$coc_code), "CoCs\n")
cat("  Treated:", n_distinct(panel_balanced$coc_code[panel_balanced$first_treat > 0]), "\n")
cat("  Control:", n_distinct(panel_balanced$coc_code[panel_balanced$first_treat == 0]), "\n")

# --- Summary statistics by treatment status ---
cat("\n=== Pre-treatment means (2007-2016) ===\n")
pre_means <- panel_balanced |>
  filter(year <= 2016) |>
  group_by(treated_ever = first_treat > 0) |>
  summarise(
    mean_total = mean(total_homeless, na.rm = TRUE),
    sd_total = sd(total_homeless, na.rm = TRUE),
    mean_sheltered = mean(sheltered, na.rm = TRUE),
    mean_unsheltered = mean(unsheltered, na.rm = TRUE),
    n_cocs = n_distinct(coc_code),
    .groups = "drop"
  )
print(pre_means)

# --- Save panel ---
saveRDS(panel_balanced, "../data/panel.rds")
write_csv(panel_balanced, "../data/panel.csv")
cat("\nPanel saved:", nrow(panel_balanced), "observations\n")

# --- CoC mergers check: are any treated CoCs affected? ---
if (!is.null(merger_df)) {
  pre_col <- grep("Pre", names(merger_df), value = TRUE)[1]
  post_col <- grep("Post", names(merger_df), value = TRUE)[1]
  if (!is.na(pre_col) && !is.na(post_col)) {
    merger_treated <- merger_df |>
      filter(as.character(merger_df[[pre_col]]) %in% rtc$coc_code |
             as.character(merger_df[[post_col]]) %in% rtc$coc_code)
    if (nrow(merger_treated) > 0) {
      cat("\nWARNING: Treated CoCs involved in mergers:\n")
      print(merger_treated)
    } else {
      cat("\nNo treated CoCs involved in mergers.\n")
    }
  }
}

cat("\n=== Panel construction complete ===\n")
