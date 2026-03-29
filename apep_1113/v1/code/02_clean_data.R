# ==============================================================================
# 02_clean_data.R — Construct analysis dataset
# Paper: The Admissions Illusion (apep_1113)
# ==============================================================================

source("00_packages.R")

enroll <- readRDS("../data/enroll_raw.rds")
admit  <- readRDS("../data/admit_raw.rds")
hd     <- readRDS("../data/hd_raw.rds")

# --- 1. Compute pre-SFFA average selectivity (treatment intensity) ---
# Use 2019-2022 average admit rate (pre-SFFA decision June 2023)
intensity <- admit %>%
  filter(year >= 2019, year <= 2022) %>%
  group_by(unitid) %>%
  summarise(
    avg_admit_rate = mean(admit_rate_pct, na.rm = TRUE),
    n_years_admit = n(),
    .groups = "drop"
  ) %>%
  filter(!is.na(avg_admit_rate), n_years_admit >= 2) %>%
  mutate(
    # Treatment intensity: 1 - admit_rate (higher = more selective = more likely to use race-conscious)
    intensity = 1 - avg_admit_rate / 100,
    # Selectivity quartiles
    selectivity_q = ntile(intensity, 4),
    selectivity_tier = case_when(
      avg_admit_rate < 25  ~ "Highly selective (<25%)",
      avg_admit_rate < 50  ~ "Selective (25-50%)",
      avg_admit_rate < 75  ~ "Moderate (50-75%)",
      TRUE                 ~ "Open access (75%+)"
    ),
    selectivity_tier = factor(selectivity_tier,
      levels = c("Highly selective (<25%)", "Selective (25-50%)",
                 "Moderate (50-75%)", "Open access (75%+)"))
  )

cat(sprintf("Institutions with selectivity measure: %d\n", nrow(intensity)))
cat("Selectivity distribution:\n")
print(table(intensity$selectivity_tier))

# --- 2. Prior-ban states (banned race-conscious admissions before SFFA) ---
prior_ban_states <- c("CA", "WA", "FL", "MI", "NE", "AZ", "NH", "OK", "ID")

# --- 3. Merge and construct panel ---
df <- enroll %>%
  inner_join(intensity, by = "unitid") %>%
  inner_join(hd %>% select(unitid, institution_name, state, sector, control, hbcu),
             by = "unitid") %>%
  filter(
    total_enroll >= 100  # Drop tiny institutions (unstable shares)
  ) %>%
  mutate(
    # Racial shares
    black_share = black_enroll / total_enroll * 100,
    hispanic_share = hispanic_enroll / total_enroll * 100,
    asian_share = asian_enroll / total_enroll * 100,
    white_share = white_enroll / total_enroll * 100,
    urm_share = (black_enroll + hispanic_enroll) / total_enroll * 100,
    # Post indicator (SFFA decision: June 2023; first full cohort: Fall 2024)
    # 2024 = first full post-SFFA enrollment year
    post = as.integer(year >= 2024),
    # Interaction: intensity × post
    intensity_x_post = intensity * post,
    # Prior ban indicator
    prior_ban = as.integer(state %in% prior_ban_states),
    # HBCU indicator
    is_hbcu = as.integer(hbcu == 1),
    # Public vs private
    is_public = as.integer(control == 1),
    # Log enrollment
    log_total = log(total_enroll)
  )

# --- 4. Balanced panel check ---
panel_balance <- df %>%
  group_by(unitid) %>%
  summarise(n_years = n(), .groups = "drop")

cat(sprintf("\nPanel: %d institution-years, %d institutions\n",
    nrow(df), n_distinct(df$unitid)))
cat(sprintf("Balanced (all 8 years 2017-2024): %d institutions\n",
    sum(panel_balance$n_years == 8)))
cat(sprintf("HBCU institutions: %d\n", sum(df$is_hbcu == 1 & df$year == 2024)))
cat(sprintf("Prior-ban state institutions: %d\n",
    sum(df$prior_ban == 1 & df$year == 2024)))

# --- 5. Summary statistics by selectivity tier (pre-SFFA) ---
summ <- df %>%
  filter(year >= 2019, year <= 2022) %>%
  group_by(selectivity_tier) %>%
  summarise(
    n_inst = n_distinct(unitid),
    mean_total = mean(total_enroll),
    mean_black_share = mean(black_share, na.rm = TRUE),
    mean_hispanic_share = mean(hispanic_share, na.rm = TRUE),
    mean_asian_share = mean(asian_share, na.rm = TRUE),
    mean_white_share = mean(white_share, na.rm = TRUE),
    mean_urm_share = mean(urm_share, na.rm = TRUE),
    .groups = "drop"
  )

cat("\nPre-SFFA summary by selectivity tier:\n")
print(summ, width = 120)

# Save analysis dataset
saveRDS(df, "../data/analysis_panel.rds")
saveRDS(summ, "../data/summary_stats.rds")

cat("\nAnalysis dataset saved.\n")
