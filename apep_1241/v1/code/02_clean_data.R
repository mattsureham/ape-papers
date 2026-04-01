## 02_clean_data.R — Clean and construct analysis variables
## apep_1241: Animal Welfare Havens

source("00_packages.R")

# --- Load data ---
trade_panel <- read_csv("../data/trade_panel.csv", show_col_types = FALSE)
trade_bilateral <- read_csv("../data/trade_bilateral.csv", show_col_types = FALSE)

cat("Panel rows:", nrow(trade_panel), "\n")
cat("Bilateral rows:", nrow(trade_bilateral), "\n")

# --- Treatment dates (fur farming bans) ---
ban_dates <- tribble(
  ~reporter, ~ban_year, ~ban_type,    ~country_name,
  "gbr",     2003,      "phase_out",  "United Kingdom",     # Completed 2003
 "aut",     2005,      "immediate",  "Austria",             # Effective ~2005
  "nld",     2013,      "phase_out",  "Netherlands",         # Enacted 2013, completed 2021
  "bel",     2019,      "phase_out",  "Belgium",
  "cze",     2019,      "phase_out",  "Czech Republic",
  "hun",     2020,      "immediate",  "Hungary",
  "irl",     2022,      "immediate",  "Ireland",
  "lva",     2022,      "immediate",  "Latvia",
  "ltu",     2023,      "immediate",  "Lithuania",
  "nor",     2025,      "phase_out",  "Norway",              # Phase-out by 2025
  "dnk",     2020,      "covid_cull", "Denmark"              # COVID mink cull
)

# Never-banned controls
control_countries <- tribble(
  ~reporter, ~country_name,
  "fin",     "Finland",
  "pol",     "Poland",
  "grc",     "Greece"
)

# Other countries (no domestic fur farming or minor)
other_eu <- tribble(
  ~reporter, ~country_name,
  "deu",     "Germany",
  "fra",     "France",
  "ita",     "Italy",
  "esp",     "Spain",
  "swe",     "Sweden",
  "rou",     "Romania",
  "bgr",     "Bulgaria",
  "hrv",     "Croatia",
  "svn",     "Slovenia",
  "svk",     "Slovakia"
)

global <- tribble(
  ~reporter, ~country_name,
  "chn",     "China",
  "usa",     "United States",
  "can",     "Canada",
  "kor",     "South Korea",
  "jpn",     "Japan",
  "tur",     "Turkey",
  "rus",     "Russia"
)

# Country lookup
all_countries <- bind_rows(
  ban_dates |> select(reporter, country_name),
  control_countries,
  other_eu,
  global
)

# --- Merge treatment into panel ---
# Focus on mink furskins (430110) as primary, 4301 as broader
mink_panel <- trade_panel |>
  filter(commodity == "430110") |>
  left_join(ban_dates |> select(reporter, ban_year, ban_type), by = "reporter") |>
  left_join(all_countries, by = "reporter") |>
  mutate(
    # Treatment indicator
    banned = case_when(
      is.na(ban_year) ~ 0L,
      year >= ban_year ~ 1L,
      TRUE ~ 0L
    ),
    # Country groups
    country_group = case_when(
      reporter %in% ban_dates$reporter ~ "ban",
      reporter %in% control_countries$reporter ~ "control_eu",
      reporter %in% other_eu$reporter ~ "other_eu",
      reporter %in% global$reporter ~ "global",
      TRUE ~ "other"
    ),
    # First treatment year for CS estimator (0 = never treated)
    first_treat = ifelse(is.na(ban_year), 0L, as.integer(ban_year)),
    # Log exports (adding 1 for zeros)
    log_exports = log(export_value + 1),
    # Numeric country ID for panel estimators
    country_id = as.integer(factor(reporter))
  )

cat("\nMink panel summary:\n")
cat("  Observations:", nrow(mink_panel), "\n")
cat("  Countries:", n_distinct(mink_panel$reporter), "\n")
cat("  Years:", paste(range(mink_panel$year), collapse = "-"), "\n")
cat("  Banned obs:", sum(mink_panel$banned), "\n")

# --- Also create broader HS 4301 panel ---
fur_panel <- trade_panel |>
  filter(commodity == "4301") |>
  left_join(ban_dates |> select(reporter, ban_year, ban_type), by = "reporter") |>
  left_join(all_countries, by = "reporter") |>
  mutate(
    banned = case_when(
      is.na(ban_year) ~ 0L,
      year >= ban_year ~ 1L,
      TRUE ~ 0L
    ),
    country_group = case_when(
      reporter %in% ban_dates$reporter ~ "ban",
      reporter %in% control_countries$reporter ~ "control_eu",
      reporter %in% other_eu$reporter ~ "other_eu",
      reporter %in% global$reporter ~ "global",
      TRUE ~ "other"
    ),
    first_treat = ifelse(is.na(ban_year), 0L, as.integer(ban_year)),
    log_exports = log(export_value + 1),
    country_id = as.integer(factor(reporter))
  )

# --- Placebo commodity panels ---
bovine_panel <- trade_panel |>
  filter(commodity == "4101") |>
  left_join(ban_dates |> select(reporter, ban_year, ban_type), by = "reporter") |>
  left_join(all_countries, by = "reporter") |>
  mutate(
    banned = case_when(
      is.na(ban_year) ~ 0L,
      year >= ban_year ~ 1L,
      TRUE ~ 0L
    ),
    first_treat = ifelse(is.na(ban_year), 0L, as.integer(ban_year)),
    log_exports = log(export_value + 1),
    country_id = as.integer(factor(reporter))
  )

wool_panel <- trade_panel |>
  filter(commodity == "5101") |>
  left_join(ban_dates |> select(reporter, ban_year, ban_type), by = "reporter") |>
  left_join(all_countries, by = "reporter") |>
  mutate(
    banned = case_when(
      is.na(ban_year) ~ 0L,
      year >= ban_year ~ 1L,
      TRUE ~ 0L
    ),
    first_treat = ifelse(is.na(ban_year), 0L, as.integer(ban_year)),
    log_exports = log(export_value + 1),
    country_id = as.integer(factor(reporter))
  )

# --- Balance the panel ---
# Create a balanced panel with all country × year combinations
all_years <- min(mink_panel$year):max(mink_panel$year)
all_reporters <- unique(mink_panel$reporter)

balanced_grid <- expand_grid(reporter = all_reporters, year = all_years)

mink_balanced <- balanced_grid |>
  left_join(mink_panel, by = c("reporter", "year")) |>
  left_join(ban_dates |> select(reporter, ban_year, ban_type), by = "reporter",
            suffix = c("", ".y")) |>
  left_join(all_countries, by = "reporter", suffix = c("", ".y")) |>
  mutate(
    ban_year = coalesce(ban_year, ban_year.y),
    ban_type = coalesce(ban_type, ban_type.y),
    country_name = coalesce(country_name, country_name.y),
    export_value = replace_na(export_value, 0),
    log_exports = log(export_value + 1),
    banned = case_when(
      is.na(ban_year) ~ 0L,
      year >= ban_year ~ 1L,
      TRUE ~ 0L
    ),
    country_group = case_when(
      reporter %in% ban_dates$reporter ~ "ban",
      reporter %in% control_countries$reporter ~ "control_eu",
      reporter %in% other_eu$reporter ~ "other_eu",
      reporter %in% global$reporter ~ "global",
      TRUE ~ "other"
    ),
    first_treat = ifelse(is.na(ban_year), 0L, as.integer(ban_year)),
    country_id = as.integer(factor(reporter))
  ) |>
  select(-ends_with(".y"))

cat("\nBalanced mink panel:", nrow(mink_balanced), "obs\n")

# --- Trade diversion panel ---
# For each ban event, track non-banning EU producers' exports
diversion_panel <- mink_balanced |>
  filter(country_group %in% c("control_eu", "ban")) |>
  mutate(
    # Neighbor banned: did a geographic neighbor ban fur farming?
    neighbor_banned = case_when(
      reporter == "pol" & year >= 2013 ~ 1L,  # NLD ban affects neighbors
      reporter == "fin" & year >= 2020 ~ 1L,  # DNK cull, NOR ban
      TRUE ~ 0L
    )
  )

# --- Save ---
write_csv(mink_balanced, "../data/mink_panel_balanced.csv")
write_csv(fur_panel, "../data/fur_panel.csv")
write_csv(bovine_panel, "../data/bovine_panel.csv")
write_csv(wool_panel, "../data/wool_panel.csv")
write_csv(diversion_panel, "../data/diversion_panel.csv")

cat("\nAll clean data saved.\n")

# --- Summary statistics ---
cat("\n=== Summary Statistics ===\n")
mink_balanced |>
  group_by(country_group) |>
  summarise(
    n_countries = n_distinct(reporter),
    mean_exports = mean(export_value, na.rm = TRUE),
    sd_exports = sd(export_value, na.rm = TRUE),
    .groups = "drop"
  ) |>
  print()

# Show pre-treatment means for ban countries
cat("\nPre-treatment mink exports for ban countries:\n")
mink_balanced |>
  filter(country_group == "ban", banned == 0) |>
  group_by(country_name) |>
  summarise(
    mean_exports = mean(export_value, na.rm = TRUE),
    max_exports = max(export_value, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(max_exports)) |>
  print()
