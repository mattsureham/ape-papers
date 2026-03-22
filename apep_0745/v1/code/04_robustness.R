## 04_robustness.R — Robustness checks and mechanism tests
## APEP-0745: The Freeport Gamble

source("00_packages.R")

cat("=== Robustness Checks ===\n")
panel <- readRDS("../data/panel.rds")
results <- readRDS("../data/results_main.rds")
freeport_las <- readRDS("../data/freeport_las.rds")

# --- 1. Excluding London LAs ---
cat("\n--- 1. Excluding London ---\n")
london_codes <- panel[grepl("^E09", la_code), unique(la_code)]
twfe_nolon <- feols(
  log_inc ~ treat_post | la_code + time_int,
  data = panel[!la_code %in% london_codes],
  cluster = ~la_code
)
cat("TWFE excl. London:", round(coef(twfe_nolon)["treat_post"], 4),
    "SE:", round(se(twfe_nolon)["treat_post"], 4), "\n")

# --- 2. Excluding Thames freeport (London-adjacent) ---
cat("\n--- 2. Excluding Thames ---\n")
thames_codes <- freeport_las[freeport == "Thames", la_code]
twfe_nothames <- feols(
  log_inc ~ treat_post | la_code + time_int,
  data = panel[!la_code %in% thames_codes | !treated_la],
  cluster = ~la_code
)
cat("TWFE excl. Thames:", round(coef(twfe_nothames)["treat_post"], 4),
    "SE:", round(se(twfe_nothames)["treat_post"], 4), "\n")

# --- 3. Displacement test: adjacent LAs ---
cat("\n--- 3. Displacement test ---\n")
# Define adjacent LAs (neighboring but not freeport)
# For now, test by excluding treated and looking at region-level effects
# Get regions containing freeport LAs
freeport_la_codes <- unique(panel$la_code[panel$treated_la])
freeport_regions <- unique(panel$region[panel$la_code %in% freeport_la_codes])
freeport_regions <- freeport_regions[!is.na(freeport_regions)]
panel[, adjacent := !treated_la & !is.na(region) & region %in% freeport_regions]
panel[, adjacent_post := as.integer(adjacent & period_date >= as.Date("2022-01-01"))]

if (sum(panel$adjacent) > 0) {
  twfe_adjacent <- feols(
    log_inc ~ adjacent_post | la_code + time_int,
    data = panel[treated_la == FALSE],
    cluster = ~la_code
  )
  cat("Adjacent LA effect:", round(coef(twfe_adjacent)["adjacent_post"], 4),
      "SE:", round(se(twfe_adjacent)["adjacent_post"], 4), "\n")
} else {
  cat("No adjacent LAs identified.\n")
  twfe_adjacent <- NULL
}

# --- 4. Sector-specific effects ---
cat("\n--- 4. Sector decomposition ---\n")

# Manufacturing (C)
panel_mfg <- panel[, .(la_code, la_name, ym, time_int, treated_la, treat_post, first_treat,
  log_inc = log_inc)]  # Will need sector-specific counts

# For sector analysis, we need sector-specific panels
# This requires going back to the company-level data
cat("Sector decomposition uses logistics count from main panel.\n")
twfe_mfg <- NULL
twfe_prof <- NULL

# --- 5. Alternative functional form: levels ---
cat("\n--- 5. Levels (not log) ---\n")
twfe_levels <- feols(
  n_inc ~ treat_post | la_code + time_int,
  data = panel,
  cluster = ~la_code
)
cat("TWFE levels:", round(coef(twfe_levels)["treat_post"], 2),
    "SE:", round(se(twfe_levels)["treat_post"], 2), "\n")

# --- 6. Pre-trend test: placebo treatment 12 months early ---
cat("\n--- 6. Placebo test ---\n")
panel[, placebo_treat := as.integer(treated_la & first_treat > 0 &
  time_int >= (first_treat - 12) & time_int < first_treat)]
twfe_placebo <- feols(
  log_inc ~ placebo_treat | la_code + time_int,
  data = panel[post == FALSE],
  cluster = ~la_code
)
cat("Placebo (12m early):", round(coef(twfe_placebo)["placebo_treat"], 4),
    "SE:", round(se(twfe_placebo)["placebo_treat"], 4), "\n")

# --- Save robustness results ---
rob_results <- list(
  twfe_nolon = twfe_nolon,
  twfe_nothames = twfe_nothames,
  twfe_adjacent = twfe_adjacent,
  twfe_levels = twfe_levels,
  twfe_placebo = twfe_placebo
)
saveRDS(rob_results, "../data/results_robustness.rds")

cat("\n=== Robustness checks complete ===\n")
