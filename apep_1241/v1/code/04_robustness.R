## 04_robustness.R — Robustness checks and placebo tests
## apep_1241: Animal Welfare Havens

source("00_packages.R")

# --- Load data ---
mink <- read_csv("../data/mink_panel_balanced.csv", show_col_types = FALSE)
bovine <- read_csv("../data/bovine_panel.csv", show_col_types = FALSE)
wool <- read_csv("../data/wool_panel.csv", show_col_types = FALSE)

# EU panel excl Denmark
eu_nodnk <- mink |>
  filter(country_group %in% c("ban", "control_eu"),
         reporter != "dnk")

# ============================================================
# ROBUSTNESS 1: Exclude COVID years (2020-2021)
# ============================================================

eu_nocovid <- eu_nodnk |> filter(!(year %in% c(2020, 2021)))

r1 <- feols(log_exports ~ banned | country_id + year,
            data = eu_nocovid,
            cluster = ~reporter)

cat("=== Robustness 1: Excl. COVID years ===\n")
summary(r1)

# ============================================================
# ROBUSTNESS 2: Include global producers as controls
# ============================================================

global_panel <- mink |>
  filter(country_group %in% c("ban", "control_eu", "global"),
         reporter != "dnk")

r2 <- feols(log_exports ~ banned | country_id + year,
            data = global_panel,
            cluster = ~reporter)

cat("\n=== Robustness 2: Global controls ===\n")
summary(r2)

# ============================================================
# ROBUSTNESS 3: Levels instead of logs
# ============================================================

r3 <- feols(export_value ~ banned | country_id + year,
            data = eu_nodnk,
            cluster = ~reporter)

cat("\n=== Robustness 3: Levels ===\n")
summary(r3)

# ============================================================
# ROBUSTNESS 4: Denmark as separate event (COVID cull)
# ============================================================

# Denmark-only event study
dnk_panel <- mink |>
  filter(reporter %in% c("dnk", "fin", "pol", "grc"),
         country_group %in% c("ban", "control_eu"))

dnk_panel <- dnk_panel |>
  mutate(
    event_time = year - 2020,
    is_dnk = as.integer(reporter == "dnk")
  )

r4_es <- feols(log_exports ~ i(event_time, is_dnk, ref = -1) | country_id + year,
               data = dnk_panel,
               cluster = ~reporter)

cat("\n=== Robustness 4: Denmark event study ===\n")
summary(r4_es)

# ============================================================
# PLACEBO 1: Raw bovine hides (HS 4101) — not subject to fur bans
# ============================================================

# Merge treatment into bovine panel
bovine_eu <- bovine |>
  filter(reporter %in% unique(eu_nodnk$reporter)) |>
  mutate(
    country_group = case_when(
      reporter %in% c("fin", "pol", "grc") ~ "control_eu",
      TRUE ~ "ban"
    ),
    banned = case_when(
      country_group == "control_eu" ~ 0L,
      TRUE ~ {
        ban_dates <- c(gbr = 2003, aut = 2005, nld = 2013, bel = 2019,
                       cze = 2019, hun = 2020, irl = 2022, lva = 2022,
                       ltu = 2023, nor = 2025)
        ifelse(year >= ban_dates[reporter], 1L, 0L)
      }
    ),
    country_id = as.integer(factor(reporter))
  )

# ============================================================
# PLACEBO TESTS: Bovine hides (HS 410120) and Wool (HS 510111)
# ============================================================

ban_df <- tibble(
  reporter = c("gbr", "aut", "nld", "bel", "cze", "hun", "irl", "lva", "ltu", "nor"),
  ban_year_p = c(2003, 2005, 2013, 2019, 2019, 2020, 2022, 2022, 2023, 2025)
)

placebo_file <- "../data/placebo_panel.csv"

p1 <- NULL
p2 <- NULL

if (file.exists(placebo_file)) {
  placebo <- read_csv(placebo_file, show_col_types = FALSE)
  cat("Placebo data loaded:", nrow(placebo), "rows\n")

  # Bovine hides (HS 410120)
  bovine_eu <- placebo |>
    filter(commodity == "410120",
           reporter %in% unique(eu_nodnk$reporter)) |>
    left_join(ban_df, by = "reporter") |>
    mutate(
      banned = ifelse(!is.na(ban_year_p) & year >= ban_year_p, 1L, 0L),
      country_id = as.integer(factor(reporter))
    )

  if (nrow(bovine_eu) > 20) {
    p1 <- feols(log_exports ~ banned | country_id + year,
                data = bovine_eu,
                cluster = ~reporter)
    cat("\n=== Placebo 1: Bovine hides (HS 410120) ===\n")
    summary(p1)
  } else {
    cat("Insufficient bovine hide data for placebo test\n")
  }

  # Wool (HS 510111)
  wool_eu <- placebo |>
    filter(commodity == "510111",
           reporter %in% unique(eu_nodnk$reporter)) |>
    left_join(ban_df, by = "reporter") |>
    mutate(
      banned = ifelse(!is.na(ban_year_p) & year >= ban_year_p, 1L, 0L),
      country_id = as.integer(factor(reporter))
    )

  if (nrow(wool_eu) > 20) {
    p2 <- feols(log_exports ~ banned | country_id + year,
                data = wool_eu,
                cluster = ~reporter)
    cat("\n=== Placebo 2: Wool (HS 510111) ===\n")
    summary(p2)
  } else {
    cat("Insufficient wool data for placebo test\n")
  }
} else {
  cat("Placebo data file not found. Skipping placebo tests.\n")
}

# ============================================================
# SAVE RESULTS
# ============================================================

saveRDS(list(
  r1_nocovid = r1,
  r2_global = r2,
  r3_levels = r3,
  r4_dnk_es = r4_es,
  p1_bovine = p1,
  p2_wool = p2
), "../data/robustness_models.rds")

cat("\n=== Robustness checks complete ===\n")
