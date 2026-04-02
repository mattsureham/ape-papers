## 02_clean_data.R — Build analysis panel for zoning preemption DiD
source("00_packages.R")

cat("=== Building analysis panel ===\n")

raw_df <- readRDS("../data/bps_county_raw.rds")

# --- Treatment assignment ---
# Effective dates (when compliance required / law took effect):
# Oregon HB 2001: compliance June 2022 → treat_year = 2022
# California SB 9: effective Jan 2022 → treat_year = 2022
# Maine LD 2003: effective Apr 2022 → treat_year = 2022
# Montana SB 382: effective Oct 2023 → treat_year = 2023
# Washington HB 1110: compliance Jun 2025 → treat_year = 2025 (not yet treated in data)
# NOTE: Washington passed in 2023 but compliance not required until 2025

treatment_map <- tibble(
  state_fips = c("41", "06", "23", "30"),
  state_name = c("Oregon", "California", "Maine", "Montana"),
  treat_year = c(2022, 2022, 2022, 2023)
)

# --- Build county-year panel ---
panel <- raw_df %>%
  mutate(
    # Construct outcomes
    total_units = units1_units + units2_units + units34_units + units5p_units,
    mm_units = units2_units + units34_units,
    mm_share = ifelse(total_units > 0, mm_units / total_units, 0),
    log_total = log(total_units + 1),
    log_mm = log(mm_units + 1),
    log_1unit = log(units1_units + 1),
    log_5plus = log(units5p_units + 1),
    has_mm = as.integer(mm_units > 0)
  ) %>%
  left_join(treatment_map, by = "state_fips") %>%
  mutate(
    treat_year = replace_na(treat_year, 0),  # 0 = never treated (for did package)
    treated = as.integer(treat_year > 0),
    post = as.integer(year >= treat_year & treat_year > 0),
    state_name = case_when(
      !is.na(state_name) ~ state_name,
      state_fips == "53" ~ "Washington",
      TRUE ~ "Control"
    )
  )

# --- Summary statistics ---
cat("\n=== Panel Summary ===\n")
cat(sprintf("Counties: %d\n", n_distinct(panel$fips)))
cat(sprintf("Years: %d-%d\n", min(panel$year), max(panel$year)))
cat(sprintf("County-years: %d\n", nrow(panel)))

cat("\nTreated states:\n")
panel %>%
  filter(treated == 1) %>%
  group_by(state_name, treat_year) %>%
  summarise(n_counties = n_distinct(fips), .groups = "drop") %>%
  print()

cat("\nControl counties:", n_distinct(panel$fips[panel$treated == 0]), "\n")

# --- Pre/Post means ---
cat("\n=== DiD Preview: Missing Middle Share ===\n")
preview <- panel %>%
  filter(year >= 2015) %>%
  mutate(period = case_when(
    year < 2022 ~ "Pre (2015-2021)",
    year >= 2022 ~ "Post (2022-2024)"
  )) %>%
  group_by(treated, period) %>%
  summarise(
    mean_mm_share = mean(mm_share, na.rm = TRUE) * 100,
    mean_mm_units = mean(mm_units, na.rm = TRUE),
    mean_total = mean(total_units, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  )
print(as.data.frame(preview), row.names = FALSE)

# 2x2 DiD
pre_t <- preview %>% filter(treated == 1, period == "Pre (2015-2021)") %>% pull(mean_mm_share)
post_t <- preview %>% filter(treated == 1, period == "Post (2022-2024)") %>% pull(mean_mm_share)
pre_c <- preview %>% filter(treated == 0, period == "Pre (2015-2021)") %>% pull(mean_mm_share)
post_c <- preview %>% filter(treated == 0, period == "Post (2022-2024)") %>% pull(mean_mm_share)

did_est <- (post_t - pre_t) - (post_c - pre_c)
cat(sprintf("\nRaw 2x2 DiD estimate: %.3f pp\n", did_est))

# --- Year-by-year means for treated vs control ---
cat("\n=== Year-by-Year Missing Middle Share (%) ===\n")
yearly <- panel %>%
  group_by(year, treated) %>%
  summarise(
    mm_share_pct = mean(mm_share, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  pivot_wider(names_from = treated, values_from = mm_share_pct,
              names_prefix = "treated_")
print(as.data.frame(yearly), row.names = FALSE)

# --- Save ---
saveRDS(panel, "../data/analysis_panel.rds")
cat("\nAnalysis panel saved.\n")
