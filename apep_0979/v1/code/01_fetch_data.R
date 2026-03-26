# =============================================================================
# 01_fetch_data.R — Load QWI data (fetched by 01_fetch_data.py) and prepare
# =============================================================================
source("00_packages.R")

# --- ULR adoption dates (comprehensive ULR laws) ---
ulr_states <- tribble(
  ~state_fips, ~state_abbr, ~ulr_year, ~ulr_quarter,
  "04", "AZ", 2019, 1,
  "42", "PA", 2019, 3,
  "16", "ID", 2020, 3,
  "30", "MT", 2020, 3,
  "34", "NJ", 2021, 1,
  "39", "OH", 2021, 1,
  "49", "UT", 2021, 1,
  "08", "CO", 2021, 3,
  "51", "VA", 2021, 3,
  "55", "WI", 2021, 2,
  "18", "IN", 2021, 3
)

ulr_states <- ulr_states %>%
  mutate(first_treat_q = ulr_year + (ulr_quarter - 1) / 4)

cat("ULR adoption states:\n")
print(ulr_states)

# --- Load QWI data from CSV (fetched by Python) ---
df_raw <- read_csv("../data/qwi_main.csv", show_col_types = FALSE)
cat(sprintf("\nRows loaded: %s\n", format(nrow(df_raw), big.mark = ",")))

# Validate
stopifnot("No data loaded" = nrow(df_raw) > 0)
stopifnot("Need both industries" = length(unique(df_raw$industry)) == 2)
stopifnot("Need both race groups" = length(unique(df_raw$race)) == 2)

# Race labels: A1 = White Alone, A2 = Black or African American Alone
df_raw <- df_raw %>%
  mutate(
    race_label = case_when(
      race == "A2" ~ "Black",
      race == "A1" ~ "White",
      TRUE ~ race
    ),
    industry_label = case_when(
      industry == "62" ~ "Healthcare",
      industry == "31-33" ~ "Manufacturing",
      TRUE ~ industry
    ),
    # EarnS = average monthly earnings of stable jobs (already per-worker)
    avg_monthly_earn = ifelse(!is.na(EarnS) & EarnS > 0, EarnS, NA_real_)
  )

cat("\nEarnings summary by race x industry:\n")
df_raw %>%
  group_by(race_label, industry_label) %>%
  summarize(
    mean_earn = mean(avg_monthly_earn, na.rm = TRUE),
    mean_emp = mean(Emp, na.rm = TRUE),
    n_obs = n(),
    .groups = "drop"
  ) %>%
  print()

saveRDS(df_raw, "../data/qwi_raw.rds")
write_csv(ulr_states, "../data/ulr_states.csv")
cat("\nData saved.\n")
